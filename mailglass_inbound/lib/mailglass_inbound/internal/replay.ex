defmodule MailglassInbound.Internal.Replay do
  @moduledoc false

  import Ecto.Query

  alias Mailglass.Tenancy
  alias MailglassInbound.Execution
  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Ingress.{Request, VerifiedRequest}
  alias MailglassInbound.Router.Matcher

  @matched_outcomes [:accept, :ignore, :reject, :bounce]

  defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]

  # T-49-17 cross-tenant replay guard. Every load (record, evidence, execution
  # runs) is scoped by tenant via an explicit `tenant_id` where-clause AND
  # `Mailglass.Tenancy.scope/2` — the same defence-in-depth pattern as
  # `Internal.Operator.Records` (T-48-01). `:tenant_id` is REQUIRED; a missing or
  # blank tenant is a programmer error and raises (fail-loud, mirroring
  # `Mailglass.Tenancy.tenant_id!/0`). Callers — the replay mix task and the admin
  # replay gateway — MUST supply the tenant that owns the record. A foreign-tenant
  # id resolves to nil → `{:error, :not_found}`, never a cross-tenant replay.
  @spec replay(Ecto.UUID.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def replay(inbound_record_id, opts \\ []) when is_binary(inbound_record_id) and is_list(opts) do
    repo = Keyword.get(opts, :repo, MailglassInbound.Repo)
    execution = Keyword.get(opts, :execution, Execution)
    tenant_id = require_tenant!(opts)

    with %InboundRecord{} = record <- load_record(repo, inbound_record_id, tenant_id),
         %InboundEvidence{} = evidence <- load_evidence(repo, inbound_record_id, tenant_id),
         {:ok, {record, evidence}} <- recover_terminal(record, evidence, repo, opts),
         {:ok, mailbox} <- resolve_mailbox(repo, inbound_record_id, tenant_id, evidence),
         payload = replay_payload(record, evidence, mailbox),
         {:ok, result} <- execution.execute(payload, source: :replay) do
      {:ok, result}
    else
      nil -> {:error, :not_found}
      {:error, _reason} = error -> error
    end
  end

  # A committed terminal row represents an authenticated request whose content
  # could not be fetched permanently at receipt time. Replay is the recovery
  # path: reconstruct the exact verified request, refetch and normalize it, then
  # fill the placeholder canonical/evidence rows in one transaction before the
  # existing replay execution path runs.
  defp recover_terminal(
         %InboundRecord{} = record,
         %InboundEvidence{terminal_failure_class: "s3_fetch_failed"} = evidence,
         repo,
         opts
       ) do
    with {:ok, request} <- terminal_request(evidence),
         {:ok, provider} <- terminal_provider(evidence.provider),
         {:ok, normalized} <- resolve_and_normalize(provider, request, evidence, opts),
         message <- normalized_message(normalized.message, record.tenant_id, provider),
         {:ok, route} <- route_recovered(message, opts),
         {:ok, recovered} <-
           persist_recovered(repo, record, evidence, message, normalized.evidence, route, opts) do
      {:ok, recovered}
    end
  end

  defp recover_terminal(record, evidence, _repo, _opts), do: {:ok, {record, evidence}}

  defp terminal_request(%InboundEvidence{raw_signed_request: raw, raw_headers: headers})
       when is_binary(raw) do
    decoded_headers = decode_headers(headers)

    {:ok,
     %Request{
       provider: :ses,
       raw_body: raw,
       headers: decoded_headers,
       params: %{},
       content_type: header_value(decoded_headers, "content-type")
     }}
  end

  defp terminal_request(_evidence), do: {:error, :terminal_request_missing}

  defp terminal_provider("ses"), do: {:ok, :ses}
  defp terminal_provider(_provider), do: {:error, :terminal_provider_unsupported}

  defp resolve_and_normalize(:ses, request, evidence, opts) do
    provider = Keyword.get(opts, :provider_module, MailglassInbound.Ingress.Providers.SES)
    config = terminal_provider_config(opts)

    verified = %VerifiedRequest{
      request: request,
      raw_body: request.raw_body,
      envelope: evidence.raw_payload || %{},
      verification_facts: evidence.verification_facts || %{},
      warnings: evidence.parse_warnings || %{}
    }

    resolved = provider.resolve_content!(verified, config)
    {:ok, provider.normalize(resolved)}
  rescue
    error in MailglassInbound.S3FetchError -> {:error, error.type}
  end

  defp terminal_provider_config(opts) do
    case Keyword.get(opts, :provider_config) do
      %{} = config -> config
      config when is_list(config) -> Map.new(config)
      nil -> :mailglass_inbound |> Application.get_env(:ses, []) |> Map.new()
    end
  end

  defp normalized_message(%InboundMessage{} = message, tenant_id, provider) do
    %{message | tenant_id: tenant_id, provider: provider}
  end

  defp route_recovered(message, opts) do
    routes =
      cond do
        Keyword.has_key?(opts, :routes) ->
          Keyword.fetch!(opts, :routes)

        router = Keyword.get(opts, :router, Application.get_env(:mailglass_inbound, :router)) ->
          router.__mailglass_inbound_routes__()

        true ->
          []
      end

    case Matcher.match(routes, message) do
      {:ok, route} -> {:ok, %{status: :matched, mailbox: route.mailbox}}
      :no_match -> {:ok, %{status: :no_match}}
    end
  end

  defp persist_recovered(repo, record, evidence, message, normalized_evidence, route, opts) do
    repo.transact(fn ->
      with {:ok, updated_record} <-
             repo.update(recovered_record_changeset(record, message), schema_opts()),
           {:ok, updated_evidence} <-
             repo.update(
               recovered_evidence_changeset(evidence, normalized_evidence, route, opts),
               schema_opts()
             ) do
        {:ok, {updated_record, updated_evidence}}
      end
    end)
  end

  @record_recovery_fields [
    :provider_message_id,
    :message_id,
    :envelope_recipient,
    :from,
    :to,
    :cc,
    :bcc,
    :reply_to,
    :subject,
    :headers,
    :sent_at,
    :received_at,
    :text_body,
    :html_body,
    :attachments
  ]

  defp recovered_record_changeset(record, message) do
    attrs = message |> Map.from_struct() |> Map.take(@record_recovery_fields)
    Ecto.Changeset.change(record, attrs)
  end

  defp recovered_evidence_changeset(evidence, normalized, route, opts) do
    raw_mime = Map.get(normalized, :raw_mime)

    facts =
      evidence.verification_facts
      |> Kernel.||(%{})
      |> Map.merge(Map.get(normalized, :verification_facts, %{}))
      |> Map.put("mailglass_execution_route", route_binding(route, opts))

    context =
      evidence.terminal_context
      |> Kernel.||(%{})
      |> Map.put("recovered", true)

    Ecto.Changeset.change(evidence, %{
      raw_mime: raw_mime,
      raw_mime_sha256: sha256(raw_mime),
      verification_facts: facts,
      parse_warnings: Map.get(normalized, :parse_warnings, %{}),
      attachment_blobs: Map.get(normalized, :attachment_blobs, %{}),
      terminal_failure_class: nil,
      terminal_context: context
    })
  end

  defp route_binding(%{status: :no_match}, _opts), do: %{"status" => "no_match"}

  defp route_binding(%{status: :matched, mailbox: mailbox}, opts) do
    binding = %{"status" => "matched", "mailbox" => Atom.to_string(mailbox)}

    case Keyword.get(opts, :router, Application.get_env(:mailglass_inbound, :router)) do
      router when is_atom(router) and not is_nil(router) ->
        Map.put(binding, "router", Atom.to_string(router))

      _ ->
        binding
    end
  end

  defp sha256(raw) when is_binary(raw) and raw != "", do: :crypto.hash(:sha256, raw)
  defp sha256(_raw), do: nil

  defp decode_headers(%{} = headers) do
    Enum.flat_map(headers, fn
      {name, values} when is_binary(name) and is_list(values) ->
        for value <- values, is_binary(value), do: {String.downcase(name), value}

      {name, value} when is_binary(name) and is_binary(value) ->
        [{String.downcase(name), value}]

      _ ->
        []
    end)
  end

  defp decode_headers(_headers), do: []

  defp header_value(headers, wanted) do
    Enum.find_value(headers, fn
      {^wanted, value} -> value
      _ -> nil
    end)
  end

  defp require_tenant!(opts) do
    case Keyword.get(opts, :tenant_id) do
      tenant_id when is_binary(tenant_id) and tenant_id != "" ->
        tenant_id

      _ ->
        raise ArgumentError,
              "MailglassInbound.Internal.Replay.replay/2 requires a non-empty :tenant_id " <>
                "option — replay loads are tenant-scoped to prevent cross-tenant replay (T-49-17)."
    end
  end

  defp load_record(repo, inbound_record_id, tenant_id) do
    from(record in InboundRecord,
      where: record.id == ^inbound_record_id and record.tenant_id == ^tenant_id,
      limit: 1
    )
    |> Tenancy.scope(tenant_id)
    |> repo.one(schema_opts())
  end

  defp load_evidence(repo, inbound_record_id, tenant_id) do
    from(evidence in InboundEvidence,
      where:
        evidence.inbound_record_id == ^inbound_record_id and
          evidence.tenant_id == ^tenant_id,
      limit: 1
    )
    |> Tenancy.scope(tenant_id)
    |> repo.one(schema_opts())
  end

  defp resolve_mailbox(repo, inbound_record_id, tenant_id, evidence) do
    case Execution.route_from_evidence(evidence) do
      {:ok, %{status: :matched, mailbox: mailbox}} ->
        {:ok, mailbox}

      {:ok, %{status: :no_match}} ->
        {:error, {:replay_mailbox_missing, %{reason: :no_prior_match}}}

      {:error, _reason} ->
        legacy_replay_mailbox_error(repo, inbound_record_id, tenant_id)
    end
  end

  defp legacy_replay_mailbox_error(repo, inbound_record_id, tenant_id) do
    case latest_matched_fresh_run(repo, inbound_record_id, tenant_id) do
      %ExecutionRun{mailbox: mailbox} when is_binary(mailbox) and mailbox != "" ->
        # Pre-binding rows cannot safely resolve a persisted module name.
        {:error, {:replay_mailbox_missing, %{reason: :invalid_mailbox}}}

      nil ->
        case latest_fresh_run(repo, inbound_record_id, tenant_id) do
          %ExecutionRun{outcome: :no_match} ->
            {:error, {:replay_mailbox_missing, %{reason: :no_prior_match}}}

          nil ->
            {:error, {:replay_mailbox_missing, %{reason: :execution_history_missing}}}

          _other ->
            {:error, {:replay_mailbox_missing, %{reason: :no_prior_match}}}
        end
    end
  end

  defp latest_matched_fresh_run(repo, inbound_record_id, tenant_id) do
    from(run in ExecutionRun,
      where:
        run.inbound_record_id == ^inbound_record_id and
          run.tenant_id == ^tenant_id and
          run.source == :fresh and
          not is_nil(run.mailbox) and
          run.outcome in ^@matched_outcomes,
      order_by: [desc: run.inserted_at],
      limit: 1
    )
    |> Tenancy.scope(tenant_id)
    |> repo.one(schema_opts())
  end

  defp latest_fresh_run(repo, inbound_record_id, tenant_id) do
    from(run in ExecutionRun,
      where:
        run.inbound_record_id == ^inbound_record_id and
          run.tenant_id == ^tenant_id and
          run.source == :fresh,
      order_by: [desc: run.inserted_at],
      limit: 1
    )
    |> Tenancy.scope(tenant_id)
    |> repo.one(schema_opts())
  end

  defp replay_payload(record, evidence, mailbox) do
    message = Execution.message_from_record(record)

    %{
      status: :inserted,
      message: message,
      inbound_record: record,
      inbound_evidence: evidence,
      route: %{status: :matched, mailbox: mailbox}
    }
  end
end
