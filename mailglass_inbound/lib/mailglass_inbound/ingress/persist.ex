defmodule MailglassInbound.Ingress.Persist do
  @moduledoc false

  import Ecto.Query

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Router.Matcher

  @type handoff_t :: %{
          required(:tenant_id) => String.t(),
          required(:provider) => atom() | String.t(),
          required(:message) => InboundMessage.t(),
          required(:evidence) => map()
        }

  @spec persist(handoff_t(), keyword()) :: {:ok, map()} | {:error, term()}
  def persist(%{tenant_id: tenant_id, provider: provider, message: %InboundMessage{} = message} = handoff, opts)
      when is_binary(tenant_id) and is_list(opts) do
    repo = Keyword.get(opts, :repo, MailglassInbound.Repo)
    provider = normalize_provider(provider)

    result =
      MailglassInbound.Telemetry.persist_span(
        %{tenant_id: tenant_id, provider: provider, record_type: "inbound_record"},
        fn ->
          transact_result =
            repo.transact(fn ->
              persist_in_transaction(repo, tenant_id, provider, message, handoff.evidence)
            end)
            |> resolve_fingerprint_race(repo, tenant_id, provider, message, handoff.evidence)

          {transact_result,
           %{
             tenant_id: tenant_id,
             provider: provider,
             operation: persist_operation(transact_result),
             record_type: "inbound_record"
           }}
        end
      )

    case result do
      {:ok, payload} ->
        route_result = route_compatibility(message, opts)

        {:ok,
         payload
         |> Map.put(:route, route_result)
         |> Map.put(:message, message)}

      other ->
        other
    end
  end

  defp persist_in_transaction(repo, tenant_id, provider, message, evidence) do
    case load_duplicate(repo, tenant_id, provider, message, evidence) do
      %InboundRecord{} = record ->
        {:ok,
         %{
           status: :duplicate,
           inbound_record: record,
           inbound_evidence: nil
         }}

      nil ->
        with {:ok, record} <- insert_record(repo, tenant_id, provider, message),
             {:ok, evidence_row} <- insert_evidence(repo, tenant_id, provider, record, evidence) do
          {:ok,
           %{
             status: :inserted,
             inbound_record: record,
             inbound_evidence: evidence_row
           }}
        end
    end
  end

  # CR-01: A concurrent redelivery of the same no-Message-Id body can pass
  # `load_duplicate` (both see nil), both insert the canonical record, and the
  # second evidence insert violates the fingerprint partial unique index. With
  # the matching `unique_constraint/3` on the evidence changeset, that violation
  # now surfaces as `{:error, %Ecto.Changeset{}}` (rolling back this
  # transaction's just-inserted record) instead of a raw `Postgrex.Error`. We
  # recognize the fingerprint constraint and reload the surviving duplicate (the
  # row the winning transaction committed), collapsing the race to a clean
  # `:duplicate` rather than a 500.
  defp resolve_fingerprint_race({:error, %Ecto.Changeset{} = changeset} = error, repo, tenant_id, provider, message, evidence) do
    if fingerprint_constraint?(changeset) do
      case load_duplicate(repo, tenant_id, provider, message, evidence) do
        %InboundRecord{} = record ->
          {:ok, %{status: :duplicate, inbound_record: record, inbound_evidence: nil}}

        nil ->
          error
      end
    else
      error
    end
  end

  defp resolve_fingerprint_race(result, _repo, _tenant_id, _provider, _message, _evidence), do: result

  defp persist_operation({:ok, %{status: :inserted}}), do: :insert
  defp persist_operation({:ok, %{status: :duplicate}}), do: :dedup_skip
  defp persist_operation(_other), do: :error

  defp load_duplicate(repo, tenant_id, "sendgrid", _message, evidence) do
    case evidence_raw_mime_fingerprint(evidence) do
      nil ->
        nil

      fingerprint ->
        query =
          from(record in InboundRecord,
            join: inbound_evidence in InboundEvidence,
            on: inbound_evidence.inbound_record_id == record.id,
            where:
              record.tenant_id == ^tenant_id and
                record.provider == ^"sendgrid" and
                inbound_evidence.provider == ^"sendgrid" and
                fragment("md5(?)", inbound_evidence.raw_mime) == ^fingerprint,
            limit: 1
          )

        repo.one(query)
    end
  end

  # Mailgun dedupes on the RFC Message-Id when present (generic anchor), and
  # falls back to the MD5(raw_mime) fingerprint when absent (D-46-10). A Mailgun
  # row WITH a Message-Id resolves through the same `(tenant_id, provider,
  # provider_message_id)` query the generic clause uses; a row WITHOUT one uses
  # the new `mailglass_inbound_records_mailgun_fingerprint_idx` (DRIFT #3).
  defp load_duplicate(repo, tenant_id, "mailgun", %InboundMessage{provider_message_id: provider_message_id}, _evidence)
       when is_binary(provider_message_id) do
    load_by_provider_message_id(repo, tenant_id, "mailgun", provider_message_id)
  end

  defp load_duplicate(repo, tenant_id, "mailgun", %InboundMessage{provider_message_id: nil}, evidence) do
    case evidence_raw_mime_fingerprint(evidence) do
      nil ->
        nil

      fingerprint ->
        query =
          from(record in InboundRecord,
            join: inbound_evidence in InboundEvidence,
            on: inbound_evidence.inbound_record_id == record.id,
            where:
              record.tenant_id == ^tenant_id and
                record.provider == ^"mailgun" and
                inbound_evidence.provider == ^"mailgun" and
                fragment("md5(?)", inbound_evidence.raw_mime) == ^fingerprint,
            limit: 1
          )

        repo.one(query)
    end
  end

  # SES dedupes on `mail.messageId` (provider_message_id) when present, and falls
  # back to the MD5(raw_mime) fingerprint when absent (WR-02) — mirroring the
  # Mailgun split clause. Without this, an SES message whose inner JSON omits
  # `mail.messageId` (inline-content notifications, degraded payloads) would
  # always match the generic `provider_message_id: nil` clause and be treated as
  # new, so an SNS at-least-once redelivery inserts a duplicate InboundRecord and
  # re-dispatches the mailbox — defeating the idempotency the dedupe layer exists
  # to provide. Backed by the new `mailglass_inbound_records_ses_fingerprint_idx`.
  defp load_duplicate(repo, tenant_id, "ses", %InboundMessage{provider_message_id: provider_message_id}, _evidence)
       when is_binary(provider_message_id) do
    load_by_provider_message_id(repo, tenant_id, "ses", provider_message_id)
  end

  defp load_duplicate(repo, tenant_id, "ses", %InboundMessage{provider_message_id: nil}, evidence) do
    case evidence_raw_mime_fingerprint(evidence) do
      nil ->
        nil

      fingerprint ->
        query =
          from(record in InboundRecord,
            join: inbound_evidence in InboundEvidence,
            on: inbound_evidence.inbound_record_id == record.id,
            where:
              record.tenant_id == ^tenant_id and
                record.provider == ^"ses" and
                inbound_evidence.provider == ^"ses" and
                fragment("md5(?)", inbound_evidence.raw_mime) == ^fingerprint,
            limit: 1
          )

        repo.one(query)
    end
  end

  defp load_duplicate(_repo, _tenant_id, _provider, %InboundMessage{provider_message_id: nil}, _evidence), do: nil

  defp load_duplicate(repo, tenant_id, provider, %InboundMessage{provider_message_id: provider_message_id}, _evidence) do
    load_by_provider_message_id(repo, tenant_id, provider, provider_message_id)
  end

  defp load_by_provider_message_id(repo, tenant_id, provider, provider_message_id) do
    query =
      from(record in InboundRecord,
        where:
          record.tenant_id == ^tenant_id and
            record.provider == ^provider and
            record.provider_message_id == ^provider_message_id,
        limit: 1
      )

    repo.one(query)
  end

  defp insert_record(repo, tenant_id, provider, message) do
    attrs = %{
      tenant_id: tenant_id,
      provider: to_string(provider),
      provider_message_id: message.provider_message_id,
      message_id: message.message_id,
      envelope_recipient: message.envelope_recipient,
      from: message.from,
      to: message.to,
      cc: message.cc,
      bcc: message.bcc,
      reply_to: message.reply_to,
      subject: message.subject,
      headers: message.headers,
      sent_at: message.sent_at,
      received_at: message.received_at || DateTime.utc_now(),
      text_body: message.text_body,
      html_body: message.html_body,
      attachments: message.attachments
    }

    changeset = InboundRecords.change_inbound_record(attrs)

    case repo.insert(changeset) do
      {:ok, record} ->
        {:ok, record}

      {:error, changeset} = error ->
        if duplicate_constraint?(changeset) do
          case load_duplicate(repo, tenant_id, provider, message, %{}) do
            %InboundRecord{} = record -> {:ok, record}
            nil -> error
          end
        else
          error
        end
    end
  end

  defp insert_evidence(repo, tenant_id, provider, record, evidence) do
    raw_mime_fingerprint = evidence_raw_mime_fingerprint(evidence)

    attrs = %{
      tenant_id: tenant_id,
      provider: normalize_provider(provider),
      inbound_record_id: record.id,
      raw_payload: Map.get(evidence, :raw_payload, %{}),
      raw_headers: Map.get(evidence, :raw_headers, %{}),
      raw_mime: Map.get(evidence, :raw_mime),
      verification_facts:
        evidence
        |> Map.get(:verification_facts, %{})
        |> maybe_put_fingerprint(raw_mime_fingerprint),
      parse_warnings: Map.get(evidence, :parse_warnings, %{}),
      attachment_blobs: Map.get(evidence, :attachment_blobs, %{})
    }

    attrs
    |> InboundRecords.change_inbound_evidence()
    |> repo.insert()
  end

  defp route_compatibility(message, opts) do
    routes =
      cond do
        Keyword.has_key?(opts, :routes) -> Keyword.fetch!(opts, :routes)
        Keyword.has_key?(opts, :router) -> Keyword.fetch!(opts, :router).__mailglass_inbound_routes__()
        true -> []
      end

    case Matcher.match(routes, message) do
      {:ok, route} -> %{status: :matched, mailbox: route.mailbox}
      :no_match -> %{status: :no_match}
    end
  end

  defp duplicate_constraint?(changeset) do
    Enum.any?(changeset.errors, fn
      {:provider_message_id, {_msg, opts}} -> opts[:constraint_name] == "mailglass_inbound_records_postmark_idempotency_idx"
      _ -> false
    end)
  end

  @fingerprint_constraints [
    "mailglass_inbound_records_mailgun_fingerprint_idx",
    "mailglass_inbound_records_sendgrid_fingerprint_idx",
    "mailglass_inbound_records_ses_fingerprint_idx"
  ]

  # CR-01: recognize an evidence-level fingerprint partial-unique-index violation
  # translated by `InboundEvidence.changeset/1`'s `unique_constraint/3`. The error
  # is attached to `:raw_mime_fingerprint`; match the constraint name to avoid
  # confusing it with any other future unique constraint on the same field.
  defp fingerprint_constraint?(changeset) do
    Enum.any?(changeset.errors, fn
      {:raw_mime_fingerprint, {_msg, opts}} -> opts[:constraint_name] in @fingerprint_constraints
      _ -> false
    end)
  end

  defp evidence_raw_mime_fingerprint(evidence) when is_map(evidence) do
    case Map.get(evidence, :raw_mime) do
      raw_mime when is_binary(raw_mime) and raw_mime != "" ->
        :md5
        |> :crypto.hash(raw_mime)
        |> Base.encode16(case: :lower)

      _ ->
        nil
    end
  end

  defp maybe_put_fingerprint(verification_facts, nil), do: verification_facts

  defp maybe_put_fingerprint(verification_facts, fingerprint) do
    Map.put_new(verification_facts, :raw_mime_fingerprint, fingerprint)
  end

  defp normalize_provider(provider) when is_atom(provider), do: Atom.to_string(provider)
  defp normalize_provider(provider) when is_binary(provider), do: provider
end
