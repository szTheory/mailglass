defmodule Mix.Tasks.Mailglass.Inbound.Replay do
  # NOTE: no `use Boundary, classify_to:` here. `mailglass_inbound` does not run
  # the `:boundary` compiler, so the annotation would not compile. The boundary
  # LAW (inbound depends on core, never the reverse) is still honored — this omits
  # only the compile-time annotation (deliberate deviation from the design contract, 49-03).
  use Mix.Task

  import Ecto.Query

  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Internal.Replay

  @shortdoc "Replay inbound records selected by --record-id/--since/--tenant"

  @moduledoc since: "0.2.0"
  @moduledoc """
  Replay previously-received inbound records through their mailboxes.

  `--tenant <id>` is **required** — it is the cross-tenant replay guard (T-49-17):
  every record is loaded scoped to that tenant, so a foreign-tenant `--record-id`
  resolves to nothing rather than replaying across the boundary. `--record-id` and
  `--since <iso8601>` further narrow the set WITHIN that tenant (AND-combinable).
  Matching records are iterated through the shipped single-record
  `MailglassInbound.Internal.Replay.replay/2`, which appends an `ExecutionRun` with
  `source: :replay` (append-only — no UPDATE).

  ## Usage

      mix mailglass.inbound.replay --tenant acme --record-id <uuid>
      mix mailglass.inbound.replay --tenant acme --since 2026-05-01T00:00:00Z
      mix mailglass.inbound.replay --tenant acme --dry-run
      mix mailglass.inbound.replay --tenant acme --yes

  In single-tenant deployments pass the resolver's tenant (`--tenant default` under
  `Mailglass.Tenancy.SingleTenant`). Replay is non-destructive (it appends lineage
  rows), so the confirmation tier is a simple `[y/N]` defaulting to **No**.
  `--yes`/`-y` skips the prompt; `--dry-run` reports the count + scope without
  replaying. Zero matches exits `0` with "nothing to replay."
  """

  @impl Mix.Task
  def run(argv, runtime_opts \\ []) do
    {opts, rest, invalid} =
      OptionParser.parse(argv,
        strict: [
          record_id: :string,
          since: :string,
          tenant: :string,
          dry_run: :boolean,
          yes: :boolean,
          no_start: :boolean
        ],
        aliases: [y: :yes]
      )

    validate_cli!(rest, invalid)
    tenant = require_tenant!(opts)

    unless Keyword.get(opts, :no_start, false) do
      Mix.Task.run("app.start")
    end

    repo = Keyword.get(runtime_opts, :repo, MailglassInbound.Repo)
    replay = Keyword.get(runtime_opts, :replay, Replay)

    selectors = parse_selectors!(opts)
    ids = resolve_ids(repo, selectors)

    cond do
      ids == [] ->
        Mix.shell().info("Inbound replay: nothing to replay (0 records matched the selectors).")
        exit({:shutdown, 0})

      Keyword.get(opts, :dry_run, false) ->
        Mix.shell().info("Inbound replay (dry run): #{length(ids)} record(s) would be replayed.")

      confirmed?(opts, length(ids)) ->
        replay_all(replay, ids, tenant)

      true ->
        Mix.shell().info("Inbound replay: aborted (no records replayed).")
    end
  end

  defp validate_cli!(rest, invalid) do
    if rest != [] do
      Mix.raise("Inbound replay blocked: unexpected positional arguments #{Enum.join(rest, " ")}")
    end

    if invalid != [] do
      invalid_flags = invalid |> Enum.map(fn {key, _value} -> "--#{key}" end) |> Enum.join(", ")
      Mix.raise("Inbound replay blocked: unknown option(s) #{invalid_flags}")
    end

    :ok
  end

  # --tenant is the cross-tenant replay guard (T-49-17): replay loads are scoped to
  # this tenant, so it must be supplied explicitly (use `--tenant default` under the
  # SingleTenant resolver). Blank/missing is a CLI misuse → Mix.raise.
  defp require_tenant!(opts) do
    case opts[:tenant] do
      tenant when is_binary(tenant) and tenant != "" ->
        tenant

      _ ->
        Mix.raise(
          "Inbound replay blocked: --tenant <id> is required (cross-tenant replay guard). " <>
            "Use --tenant default under the SingleTenant resolver."
        )
    end
  end

  defp parse_selectors!(opts) do
    %{
      record_id: opts[:record_id],
      tenant: opts[:tenant],
      since: parse_since!(opts[:since])
    }
  end

  defp parse_since!(nil), do: nil

  defp parse_since!(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        datetime

      {:error, _reason} ->
        Mix.raise(
          "Inbound replay blocked: --since must be an ISO 8601 datetime, got #{inspect(value)}"
        )
    end
  end

  # Build a parameterized query from the AND-combined selectors. Selectors are
  # never string-interpolated (T-49-11).
  defp resolve_ids(repo, selectors) do
    InboundRecord
    |> filter_record_id(selectors.record_id)
    |> filter_tenant(selectors.tenant)
    |> filter_since(selectors.since)
    |> select([r], r.id)
    |> repo.all()
  end

  defp filter_record_id(query, nil), do: query
  defp filter_record_id(query, id), do: from(r in query, where: r.id == ^id)

  defp filter_tenant(query, nil), do: query
  defp filter_tenant(query, tenant), do: from(r in query, where: r.tenant_id == ^tenant)

  defp filter_since(query, nil), do: query
  defp filter_since(query, since), do: from(r in query, where: r.received_at >= ^since)

  # [y/N] defaulting No (the design contract). `--yes`/`-y` skips the prompt entirely.
  defp confirmed?(opts, count) do
    if Keyword.get(opts, :yes, false) do
      true
    else
      Mix.shell().yes?("Replay #{count} inbound record(s)?")
    end
  end

  defp replay_all(replay, ids, tenant) do
    {ok, errors} =
      Enum.reduce(ids, {0, 0}, fn id, {ok, errors} ->
        case replay.replay(id, tenant_id: tenant) do
          {:ok, _result} ->
            {ok + 1, errors}

          {:error, reason} ->
            Mix.shell().error("  replay failed for #{id}: #{inspect(reason)}")
            {ok, errors + 1}
        end
      end)

    Mix.shell().info("Inbound replay complete: replayed=#{ok} failed=#{errors}")

    if errors > 0 do
      exit({:shutdown, 1})
    end
  end
end
