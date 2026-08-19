defmodule MailglassInbound.Ingress.Persist do
  @moduledoc false

  import Ecto.Query

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Ports
  alias MailglassInbound.Router.Matcher

  @route_binding_key "mailglass_execution_route"

  # Returns the schema-prefix option that must be passed to all direct repo
  # calls (insert, one, all) so they route to the configured Postgres schema
  # This mirrors what `MailglassInbound.Repo.put_prefix/1`
  # does for facade calls — callers that pass an explicit `:prefix` override
  # this via Ecto's `Keyword.put_new` / option-merge semantics (caller wins).
  defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]

  @type handoff_t :: %{
          required(:tenant_id) => String.t(),
          required(:provider) => atom() | String.t(),
          required(:message) => InboundMessage.t(),
          required(:evidence) => map()
        }

  @spec persist(handoff_t(), keyword()) :: {:ok, map()} | {:error, term()}
  def persist(
        %{tenant_id: tenant_id, provider: provider, message: %InboundMessage{} = message} = handoff,
        opts
      )
      when is_binary(tenant_id) and is_list(opts) do
    repo = Keyword.get(opts, :repo, MailglassInbound.Repo)
    provider = normalize_provider(provider)
    route_result = route_compatibility(message, opts)
    evidence = put_route_binding(handoff.evidence, route_result, opts)

    # WR-03: compute the diagnostic suppression flag BEFORE the write transaction.
    # The lookup hits the CORE suppression store (a different repo / connection
    # pool than the inbound `repo`); running it inside `repo.transact` would hold
    # a second pooled connection open for the duration of the inbound write — a
    # pool-exhaustion / deadlock surface on the ingress hot path. It needs only
    # `tenant_id` + the message's first `from` address, none of which require the
    # transaction. The span + degrade-open semantics are preserved (the design contract).
    suppression_flagged = compute_suppression_flag(tenant_id, provider, message)

    result =
      MailglassInbound.Telemetry.persist_span(
        %{tenant_id: tenant_id, provider: provider, record_type: "inbound_record"},
        fn ->
          transact_result =
            repo.transact(fn ->
              persist_in_transaction(
                repo,
                tenant_id,
                provider,
                message,
                evidence,
                suppression_flagged
              )
            end)
            |> resolve_fingerprint_race(repo, tenant_id, provider, message, evidence)

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
        {:ok,
         payload
         |> Map.put(:route, route_result)
         |> Map.put(:message, message)}

      other ->
        other
    end
  end

  @doc false
  @spec persist_terminal_failure(String.t(), atom(), map(), map(), atom(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def persist_terminal_failure(
        tenant_id,
        :ses = provider,
        request,
        verified,
        :s3_fetch_failed,
        opts
      )
      when is_binary(tenant_id) and is_map(request) and is_map(verified) and is_list(opts) do
    with raw_signed_request when is_binary(raw_signed_request) <- Map.get(request, :raw_body),
         %{} = envelope <- Map.get(verified, :envelope) do
      do_persist_terminal_failure(
        tenant_id,
        provider,
        request,
        verified,
        envelope,
        raw_signed_request,
        opts
      )
    else
      _ -> {:error, :terminal_evidence_incomplete}
    end
  end

  def persist_terminal_failure(_tenant_id, _provider, _request, _verified, _failure_class, _opts),
    do: {:error, :terminal_failure_class_not_persistable}

  defp do_persist_terminal_failure(
         tenant_id,
         provider,
         request,
         verified,
         envelope,
         raw_signed_request,
         opts
       ) do
    handoff = %{
      tenant_id: tenant_id,
      provider: provider,
      message: %InboundMessage{
        tenant_id: tenant_id,
        provider: provider,
        provider_message_id: terminal_provider_message_id(verified),
        received_at: DateTime.utc_now()
      },
      evidence: %{
        raw_payload: envelope,
        raw_headers: headers_to_map(Map.get(request, :headers, [])),
        raw_signed_request: raw_signed_request,
        verification_facts: Map.get(verified, :verification_facts, %{}),
        parse_warnings: Map.get(verified, :warnings, %{}),
        attachment_blobs: %{},
        terminal_failure_class: "s3_fetch_failed",
        terminal_context: %{
          "provider" => Atom.to_string(provider),
          "replayable" => true,
          "schema_version" => 1
        }
      }
    }

    persist(handoff, opts)
  end

  defp persist_in_transaction(repo, tenant_id, provider, message, evidence, suppression_flagged) do
    case load_duplicate(repo, tenant_id, provider, message, evidence) do
      %InboundRecord{} = record ->
        {:ok,
         %{
           status: :duplicate,
           inbound_record: record,
           inbound_evidence: nil
         }}

      nil ->
        with {:ok, record} <-
               insert_record(repo, tenant_id, provider, message, suppression_flagged),
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
  defp resolve_fingerprint_race(
         {:error, %Ecto.Changeset{} = changeset} = error,
         repo,
         tenant_id,
         provider,
         message,
         evidence
       ) do
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

  defp resolve_fingerprint_race(result, _repo, _tenant_id, _provider, _message, _evidence),
    do: result

  defp persist_operation({:ok, %{status: :inserted}}), do: :insert
  defp persist_operation({:ok, %{status: :duplicate}}), do: :dedup_skip
  defp persist_operation(_other), do: :error

  defp load_duplicate(repo, tenant_id, "sendgrid", _message, evidence) do
    case evidence_raw_mime_fingerprint(evidence) do
      nil ->
        nil

      fingerprint ->
        sha256 = evidence_raw_mime_sha256(evidence)

        query =
          from(record in InboundRecord,
            join: inbound_evidence in InboundEvidence,
            on: inbound_evidence.inbound_record_id == record.id,
            where:
              record.tenant_id == ^tenant_id and
                record.provider == ^"sendgrid" and
                inbound_evidence.provider == ^"sendgrid" and
                (inbound_evidence.raw_mime_sha256 == ^sha256 or
                   (is_nil(inbound_evidence.raw_mime_sha256) and
                      inbound_evidence.raw_mime_fingerprint == ^fingerprint)),
            limit: 1
          )

        repo.one(query, schema_opts())
    end
  end

  # Mailgun dedupes on the RFC Message-Id when present (generic anchor), and
  # falls back to the MD5(raw_mime) fingerprint when absent (the design contract). A Mailgun
  # row WITH a Message-Id resolves through the same `(tenant_id, provider,
  # provider_message_id)` query the generic clause uses; a row WITHOUT one uses
  # the new `mailglass_inbound_records_mailgun_fingerprint_idx` (DRIFT #3).
  defp load_duplicate(
         repo,
         tenant_id,
         "mailgun",
         %InboundMessage{provider_message_id: provider_message_id},
         _evidence
       )
       when is_binary(provider_message_id) do
    load_by_provider_message_id(repo, tenant_id, "mailgun", provider_message_id)
  end

  defp load_duplicate(
         repo,
         tenant_id,
         "mailgun",
         %InboundMessage{provider_message_id: nil},
         evidence
       ) do
    case evidence_raw_mime_fingerprint(evidence) do
      nil ->
        nil

      fingerprint ->
        sha256 = evidence_raw_mime_sha256(evidence)

        query =
          from(record in InboundRecord,
            join: inbound_evidence in InboundEvidence,
            on: inbound_evidence.inbound_record_id == record.id,
            where:
              record.tenant_id == ^tenant_id and
                record.provider == ^"mailgun" and
                inbound_evidence.provider == ^"mailgun" and
                (inbound_evidence.raw_mime_sha256 == ^sha256 or
                   (is_nil(inbound_evidence.raw_mime_sha256) and
                      inbound_evidence.raw_mime_fingerprint == ^fingerprint)),
            limit: 1
          )

        repo.one(query, schema_opts())
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
  defp load_duplicate(
         repo,
         tenant_id,
         "ses",
         %InboundMessage{provider_message_id: provider_message_id},
         _evidence
       )
       when is_binary(provider_message_id) do
    load_by_provider_message_id(repo, tenant_id, "ses", provider_message_id)
  end

  defp load_duplicate(repo, tenant_id, "ses", %InboundMessage{provider_message_id: nil}, evidence) do
    case evidence_raw_mime_fingerprint(evidence) do
      nil ->
        nil

      fingerprint ->
        sha256 = evidence_raw_mime_sha256(evidence)

        query =
          from(record in InboundRecord,
            join: inbound_evidence in InboundEvidence,
            on: inbound_evidence.inbound_record_id == record.id,
            where:
              record.tenant_id == ^tenant_id and
                record.provider == ^"ses" and
                inbound_evidence.provider == ^"ses" and
                (inbound_evidence.raw_mime_sha256 == ^sha256 or
                   (is_nil(inbound_evidence.raw_mime_sha256) and
                      inbound_evidence.raw_mime_fingerprint == ^fingerprint)),
            limit: 1
          )

        repo.one(query, schema_opts())
    end
  end

  defp load_duplicate(
         _repo,
         _tenant_id,
         _provider,
         %InboundMessage{provider_message_id: nil},
         _evidence
       ),
       do: nil

  defp load_duplicate(
         repo,
         tenant_id,
         provider,
         %InboundMessage{provider_message_id: provider_message_id},
         _evidence
       ) do
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

    repo.one(query, schema_opts())
  end

  defp insert_record(repo, tenant_id, provider, message, suppression_flagged) do
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
      attachments: message.attachments,
      # WR-03: precomputed BEFORE the transaction (see persist/2) so the cross-repo
      # suppression-store lookup never holds a second connection inside the write.
      suppression_flagged: suppression_flagged
    }

    changeset = InboundRecords.change_inbound_record(attrs)

    case repo.insert(changeset, schema_opts()) do
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

  # IOPS-05 (the design contract/23): compute the diagnostic suppression flag once, BEFORE the
  # write transaction (WR-03 — the cross-repo lookup must not hold a second
  # connection inside the inbound write). The flag is NOT a gate — it degrades
  # OPEN so a store hiccup, a malformed key, or an empty `from` can never block
  # legitimate inbound mail. A `true` flag triggers no auto-bounce and no
  # auto-suppression; the message is preserved and the adopter's mailbox decides
  # reject/process. We call the CONFIGURED store's `check/2` directly (NOT the
  # outbound `Mailglass.Suppression` send-preflight facade, which reads swoosh
  # `:to` and emits OUTBOUND telemetry). The whole compute runs inside the inbound
  # `:suppression_flag` span; its stop metadata is `%{flagged, tenant_id,
  # provider}` only — never the address (the design contract).
  defp compute_suppression_flag(tenant_id, provider, message) do
    MailglassInbound.Telemetry.suppression_flag(
      %{tenant_id: tenant_id, provider: normalize_provider(provider)},
      fn ->
        flag = suppressed_sender?(tenant_id, message)

        {flag, %{tenant_id: tenant_id, provider: normalize_provider(provider), flagged: flag}}
      end
    )
  end

  defp suppressed_sender?(tenant_id, %InboundMessage{from: from}) do
    case first_from_address(from) do
      nil ->
        # Empty/missing from → nothing to look up → degrade OPEN.
        false

      address ->
        Ports.Core.suppressed_sender?(tenant_id, address)
    end
  end

  defp first_from_address([%{address: address} | _rest]) when is_binary(address) and address != "",
    do: address

  defp first_from_address([%{"address" => address} | _rest])
       when is_binary(address) and address != "",
       do: address

  defp first_from_address(_from), do: nil

  defp insert_evidence(repo, tenant_id, provider, record, evidence) do
    raw_mime_fingerprint = evidence_raw_mime_fingerprint(evidence)
    raw_mime_sha256 = evidence_raw_mime_sha256(evidence)

    attrs = %{
      tenant_id: tenant_id,
      provider: normalize_provider(provider),
      inbound_record_id: record.id,
      raw_payload: Map.get(evidence, :raw_payload, %{}),
      raw_headers: Map.get(evidence, :raw_headers, %{}),
      raw_mime: Map.get(evidence, :raw_mime),
      raw_mime_sha256: raw_mime_sha256,
      raw_signed_request: Map.get(evidence, :raw_signed_request),
      verification_facts:
        evidence
        |> Map.get(:verification_facts, %{})
        |> maybe_put_fingerprint(raw_mime_fingerprint),
      parse_warnings: Map.get(evidence, :parse_warnings, %{}),
      attachment_blobs: Map.get(evidence, :attachment_blobs, %{})
    }

    attrs =
      if Map.has_key?(evidence, :terminal_failure_class) do
        attrs
        |> Map.put(:terminal_failure_class, Map.get(evidence, :terminal_failure_class))
        |> Map.put(:terminal_context, Map.get(evidence, :terminal_context, %{}))
      else
        attrs
      end

    attrs
    |> InboundRecords.change_inbound_evidence()
    |> repo.insert(schema_opts())
  end

  defp route_compatibility(message, opts) do
    routes =
      cond do
        Keyword.has_key?(opts, :routes) ->
          Keyword.fetch!(opts, :routes)

        Keyword.has_key?(opts, :router) ->
          Keyword.fetch!(opts, :router).__mailglass_inbound_routes__()

        true ->
          []
      end

    case Matcher.match(routes, message) do
      {:ok, route} -> %{status: :matched, mailbox: route.mailbox}
      :no_match -> %{status: :no_match}
    end
  end

  # This binding is written with the canonical record and raw evidence in the
  # same transaction. It is execution authority, not provider-supplied data.
  # The worker rehydrates it from evidence and only uses job values as a
  # mismatch check, never as a mailbox selector.
  defp put_route_binding(evidence, %{status: :no_match}, _opts) do
    Map.update(
      evidence,
      :verification_facts,
      %{@route_binding_key => %{"status" => "no_match"}},
      fn facts ->
        Map.put(facts || %{}, @route_binding_key, %{"status" => "no_match"})
      end
    )
  end

  defp put_route_binding(evidence, %{status: :matched, mailbox: mailbox}, opts)
       when is_atom(mailbox) do
    router = Keyword.get(opts, :router)

    binding =
      case router_name(router) do
        nil ->
          %{"status" => "matched", "mailbox" => Atom.to_string(mailbox)}

        router_name ->
          %{"status" => "matched", "mailbox" => Atom.to_string(mailbox), "router" => router_name}
      end

    Map.update(evidence, :verification_facts, %{@route_binding_key => binding}, fn facts ->
      Map.put(facts || %{}, @route_binding_key, binding)
    end)
  end

  defp router_name(router) when is_atom(router) and not is_nil(router), do: Atom.to_string(router)
  defp router_name(_router), do: nil

  defp duplicate_constraint?(changeset) do
    Enum.any?(changeset.errors, fn
      {:provider_message_id, {_msg, opts}} ->
        opts[:constraint_name] == "mailglass_inbound_records_postmark_idempotency_idx"

      _ ->
        false
    end)
  end

  @fingerprint_constraints [
    "mailglass_inbound_records_mailgun_fingerprint_idx",
    "mailglass_inbound_records_sendgrid_fingerprint_idx",
    "mailglass_inbound_records_ses_fingerprint_idx",
    "mailglass_inbound_evidence_sha256_idx"
  ]

  # CR-01: recognize an evidence-level fingerprint partial-unique-index violation
  # translated by `InboundEvidence.changeset/1`'s `unique_constraint/3`. The error
  # is attached to `:raw_mime_fingerprint`; match the constraint name to avoid
  # confusing it with any other future unique constraint on the same field.
  defp fingerprint_constraint?(changeset) do
    Enum.any?(changeset.errors, fn
      {field, {_msg, opts}} when field in [:raw_mime_fingerprint, :raw_mime_sha256] ->
        opts[:constraint_name] in @fingerprint_constraints

      _ ->
        false
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

  defp evidence_raw_mime_sha256(evidence) when is_map(evidence) do
    case Map.get(evidence, :raw_mime) do
      raw_mime when is_binary(raw_mime) and raw_mime != "" -> :crypto.hash(:sha256, raw_mime)
      _ -> nil
    end
  end

  @doc false
  @spec backfill_sha256(keyword()) ::
          {:ok,
           %{
             count: non_neg_integer(),
             next_cursor: Ecto.UUID.t() | nil,
             done?: boolean()
           }}
          | {:error, term()}
  def backfill_sha256(opts \\ []) do
    repo = Keyword.get(opts, :repo, MailglassInbound.Repo)
    prefix = Keyword.get(opts, :prefix, MailglassInbound.Config.schema())
    limit = Keyword.get(opts, :limit, 500)
    after_id = Keyword.get(opts, :after_id)

    Mailglass.Identifier.validate!(prefix, :prefix)

    unless is_integer(limit) and limit > 0 and limit <= 5_000 do
      raise ArgumentError, ":limit must be an integer between 1 and 5000"
    end

    unless is_nil(after_id) or match?({:ok, _uuid}, Ecto.UUID.cast(after_id)) do
      raise ArgumentError, ":after_id must be a UUID string or nil"
    end

    repo.transact(fn -> backfill_sha256_batch(repo, prefix, limit, after_id) end)
  end

  defp backfill_sha256_batch(repo, prefix, limit, after_id) do
    lock_key = "mailglass_inbound:sha256_backfill:#{prefix}"

    with {:ok, %{rows: [[true]]}} <-
           repo.query("SELECT pg_try_advisory_xact_lock(hashtext($1))", [lock_key], log: false),
         {:ok, %{rows: rows, num_rows: count}} <-
           run_sha256_batch(repo, prefix, limit, after_id) do
      next_cursor = max_row_id(rows)
      remaining_after = next_cursor || after_id

      with {:ok, done?} <- backfill_done?(repo, prefix, remaining_after) do
        {:ok, %{count: count, next_cursor: next_cursor, done?: done?}}
      end
    else
      {:ok, %{rows: [[false]]}} -> {:error, :backfill_locked}
      {:error, reason} -> {:error, reason}
      _unexpected -> {:error, :backfill_lock_failed}
    end
  end

  defp run_sha256_batch(repo, prefix, limit, after_id) do
    {cursor_sql, params, limit_param} =
      if is_binary(after_id) do
        {" AND id > $1", [dump_uuid!(after_id), limit], "$2"}
      else
        {"", [limit], "$1"}
      end

    sql =
      "WITH batch AS (" <>
        "SELECT id FROM #{inspect(prefix)}.mailglass_inbound_evidence " <>
        "WHERE raw_mime_sha256 IS NULL AND raw_mime IS NOT NULL#{cursor_sql} " <>
        "ORDER BY id LIMIT #{limit_param} FOR UPDATE" <>
        ") UPDATE #{inspect(prefix)}.mailglass_inbound_evidence AS evidence " <>
        "SET raw_mime_sha256 = sha256(evidence.raw_mime) FROM batch " <>
        "WHERE evidence.id = batch.id AND evidence.raw_mime_sha256 IS NULL " <>
        "RETURNING evidence.id"

    repo.query(sql, params, log: false)
  end

  defp backfill_done?(repo, prefix, after_id) do
    {cursor_sql, params} =
      if is_binary(after_id), do: {" AND id > $1", [dump_uuid!(after_id)]}, else: {"", []}

    sql =
      "SELECT EXISTS(SELECT 1 FROM #{inspect(prefix)}.mailglass_inbound_evidence " <>
        "WHERE raw_mime_sha256 IS NULL AND raw_mime IS NOT NULL#{cursor_sql})"

    case repo.query(sql, params, log: false) do
      {:ok, %{rows: [[remaining?]]}} when is_boolean(remaining?) -> {:ok, not remaining?}
      {:error, reason} -> {:error, reason}
      _unexpected -> {:error, :backfill_remaining_check_failed}
    end
  end

  defp max_row_id([]), do: nil

  defp max_row_id(rows) do
    id = rows |> Enum.map(&hd/1) |> Enum.max()

    case Ecto.UUID.load(id) do
      {:ok, uuid} -> uuid
      :error -> id
    end
  end

  defp dump_uuid!(uuid) do
    {:ok, binary} = Ecto.UUID.dump(uuid)
    binary
  end

  defp headers_to_map(headers) when is_list(headers) do
    Enum.reduce(headers, %{}, fn
      {name, value}, acc when is_binary(name) and is_binary(value) ->
        Map.update(acc, String.downcase(name), [value], &(&1 ++ [value]))

      _malformed, acc ->
        acc
    end)
  end

  defp headers_to_map(%{} = headers), do: headers
  defp headers_to_map(_headers), do: %{}

  defp terminal_provider_message_id(verified) do
    envelope = Map.get(verified, :envelope, %{})

    inner_id =
      with message when is_binary(message) <- Map.get(envelope, "Message"),
           {:ok, %{} = inner} <- Jason.decode(message) do
        get_in(inner, ["mail", "messageId"])
      else
        _ -> nil
      end

    inner_id || Map.get(envelope, "MessageId")
  end

  defp maybe_put_fingerprint(verification_facts, nil), do: verification_facts

  defp maybe_put_fingerprint(verification_facts, fingerprint) do
    Map.put_new(verification_facts, :raw_mime_fingerprint, fingerprint)
  end

  defp normalize_provider(provider) when is_atom(provider), do: Atom.to_string(provider)
  defp normalize_provider(provider) when is_binary(provider), do: provider
end
