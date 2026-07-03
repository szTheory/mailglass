defmodule MailglassInbound.Internal.Prune do
  @moduledoc """
  Oban-independent batched retention sweep for inbound tables. This is the
  workhorse: `mix mailglass.inbound.prune` and the
  optional `MailglassInbound.Prune.Worker` cron both call `prune/0`.

  Mirrors `Mailglass.Webhook.Pruner`'s STRUCTURE (`:infinity` disables a class,
  per-table telemetry) but UPGRADES the unbounded `delete_all` to a batched idiom
  each table deletes `LIMIT 1000` rows at a time
  (`FOR UPDATE SKIP LOCKED`), looping until a batch deletes `< 1000`. The whole
  sweep is serialized by a session `pg_try_advisory_lock` — a concurrent second
  run returns `{:ok, :locked_out}` and deletes nothing.

  ## Schema qualification

  The prune sweep holds a direct reference to the raw host repo (not the
  `MailglassInbound.Repo` facade) because it needs `checkout/1` to pin one
  connection for the advisory lock session. The facade cannot rewrite this path,
  so any mailglass-table SQL issued from this module MUST carry an explicit
  `prefix: MailglassInbound.Config.schema()` inline for correctness.
  The single `repo.delete_all(...)` in `delete_batched/3` carries
  this prefix. The two advisory-lock `repo.query!` calls (`pg_try_advisory_lock` /
  `pg_advisory_unlock`) and `repo.checkout/1` are intentionally UNprefixed — they
  are session-scoped, schema-agnostic SQL that touch no mailglass table (mirrors the
  core `Mailglass.Repo.query!/2` SET LOCAL exemption). Any future raw mailglass-table
  SQL added to this module's direct-repo path MUST follow the same inline-prefix rule.

  ## Window split — three physical tables, four windows

    * `mailglass_inbound_replay_runs` WHERE `source = :replay` AND age > replay_runs_days (30d)
    * `mailglass_inbound_replay_runs` WHERE `source = :fresh`  AND age > execution_runs_days (90d)
    * `mailglass_inbound_evidence` WHERE age > evidence_days (90d)
    * `mailglass_inbound_records` WHERE age > records_days (90d)

  Deletes run child-first: replay_runs (both source filters) -> evidence
  -> records. FKs are `on_delete: :nothing`, so a mis-ordered delete fails loudly
  on the FK (the designed safety net — do NOT switch to CASCADE).
  Prune operations must remain tenant-scoped and operator-confirmed before destructive actions.

  Because the FKs are `:nothing`, a parent window can never be shorter than a child
  that references it, or the child-first sweep would leave a surviving child whose
  parent the next delete tries to remove — tripping a `foreign_key_violation`
  `MailglassInbound.Config.retention/0` enforces this by clamping
  `evidence_days >= max(execution_runs_days, replay_runs_days)` and
  `records_days >= evidence_days`, so the default windows (evidence 90d, not the
  former 30d) never invert against `:fresh` runs aged 30-90 days.

  `source` is filtered via `ExecutionRun` (which maps the `:source` column);
  NEVER `ReplayRun` (no `:source` field — Pitfall 4).
  """

  import Ecto.Query

  alias MailglassInbound.Config
  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord

  @batch_size 1000

  # Stable bigint advisory-lock key — a fixed constant so a cron tick and an ops
  # `mix` run serialize against each other. (Derived once from a hash of
  # "mailglass_inbound_prune", truncated into signed int8 range.)
  @prune_lock_key 6_318_741_290_553_217_001

  @doc """
  The session advisory-lock key the prune sweep acquires. Exposed so tests can
  acquire it from a separate connection to exercise the single-run guard.
  """
  @spec lock_key() :: integer()
  def lock_key, do: @prune_lock_key

  @doc """
  Run the retention sweep. Returns `{:ok, counts}` where `counts` carries the
  per-table deletion counts (+ per-table batch iteration counts) and `:status`,
  or `{:ok, :locked_out}` when another sweep holds the advisory lock.
  """
  @spec prune(keyword()) :: {:ok, map()} | {:ok, :locked_out}
  def prune(opts \\ []) when is_list(opts) do
    # The host repo (a real Ecto.Repo) — NOT the thin `MailglassInbound.Repo`
    # facade, which does not expose `query!/2` or `delete_all/2`. Batched deletes
    # and the advisory lock need the full SQL repo.
    repo = Keyword.get(opts, :repo, host_repo())
    retention = Keyword.get(opts, :retention, Config.retention())

    with_advisory_lock(repo, fn ->
      sweep(repo, retention)
    end)
  end

  defp host_repo do
    case Application.get_env(:mailglass_inbound, :repo) do
      nil ->
        raise RuntimeError,
              "mailglass_inbound requires config :mailglass_inbound, :repo to resolve its host repo"

      mod when is_atom(mod) ->
        mod
    end
  end

  defp sweep(repo, retention) do
    # Fallback defaults match Config's safe defaults (CR-02): evidence outlives the
    # run windows it is referenced by. When prune is driven by Config.retention/0
    # the windows are already clamped to respect the FK lineage; these fallbacks
    # only apply to a partial keyword list passed directly via the :retention opt.
    replay_days = Keyword.get(retention, :replay_runs_days, 30)
    fresh_days = Keyword.get(retention, :execution_runs_days, 90)
    evidence_days = Keyword.get(retention, :evidence_days, 90)
    records_days = Keyword.get(retention, :records_days, 90)

    # Child-first order (the design contract): replay_runs (both source filters) -> evidence
    # -> records. The window field is `inserted_at` (matches Webhook.Pruner).
    {replay_deleted, replay_batches} =
      delete_source_window(repo, :replay, replay_days)

    {fresh_deleted, fresh_batches} =
      delete_source_window(repo, :fresh, fresh_days)

    {evidence_deleted, evidence_batches} =
      delete_window(repo, InboundEvidence, evidence_days)

    {records_deleted, records_batches} =
      delete_window(repo, InboundRecord, records_days)

    counts = %{
      records_deleted: records_deleted,
      evidence_deleted: evidence_deleted,
      fresh_runs_deleted: fresh_deleted,
      replay_runs_deleted: replay_deleted,
      records_batches: records_batches,
      evidence_batches: evidence_batches,
      fresh_runs_batches: fresh_batches,
      replay_runs_batches: replay_batches,
      status: :ok
    }

    emit_telemetry(counts)

    {:ok, counts}
  end

  # ---- advisory lock --------------------------------------------------------

  # CR-01: PostgreSQL session-level advisory locks (the non-`_xact_`
  # `pg_try_advisory_lock` / `pg_advisory_unlock` variants) are bound to the
  # database SESSION (connection). Outside an explicit checkout, Ecto/DBConnection
  # hands each `query!` / `delete_all` a possibly-different pooled connection — so
  # the lock would be taken on one connection and released on another (where no
  # lock is held), leaking the lock on the original connection and letting two
  # concurrent sweeps interleave. `Repo.checkout/2` pins ONE connection for the
  # whole closure (across the separate per-batch transactions, preserving the
  # batched-commit design), so the acquire, the batched deletes, and the release
  # all share a single session.
  defp with_advisory_lock(repo, fun) do
    repo.checkout(fn ->
      case repo.query!("SELECT pg_try_advisory_lock($1)", [@prune_lock_key]) do
        %{rows: [[true]]} ->
          try do
            fun.()
          after
            repo.query!("SELECT pg_advisory_unlock($1)", [@prune_lock_key])
          end

        %{rows: [[false]]} ->
          {:ok, :locked_out}
      end
    end)
  end

  # ---- batched deletes ------------------------------------------------------

  # `source`-discriminated replay_runs window — filter via ExecutionRun (maps
  # :source), NEVER ReplayRun (Pitfall 4). `:infinity` disables WITHOUT a DELETE.
  defp delete_source_window(_repo, _source, :infinity), do: {0, 0}

  defp delete_source_window(repo, source, days)
       when is_atom(source) and is_integer(days) and days > 0 do
    cutoff = cutoff(days)

    filter = fn query ->
      from(r in query, where: r.source == ^source and r.inserted_at < ^cutoff)
    end

    delete_batched(repo, ExecutionRun, filter)
  end

  # Plain age window for evidence + records (no source discriminator).
  defp delete_window(_repo, _schema, :infinity), do: {0, 0}

  defp delete_window(repo, schema, days) when is_integer(days) and days > 0 do
    cutoff = cutoff(days)
    filter = fn query -> from(r in query, where: r.inserted_at < ^cutoff) end
    delete_batched(repo, schema, filter)
  end

  # DELETE ... WHERE id IN (SELECT id ... WHERE <window> LIMIT 1000
  # FOR UPDATE SKIP LOCKED), looped until a batch deletes < @batch_size. The loop
  # is NOT one transaction — each delete_all commits on its own (the design contract).
  defp delete_batched(repo, schema, window) do
    Stream.repeatedly(fn ->
      inner =
        schema
        |> window.()
        |> select([r], r.id)
        |> limit(^@batch_size)
        |> lock("FOR UPDATE SKIP LOCKED")

      {count, _} =
        repo.delete_all(from(r in schema, where: r.id in subquery(inner)),
          prefix: MailglassInbound.Config.schema()
        )

      count
    end)
    |> Enum.reduce_while({0, 0}, fn count, {total, batches} ->
      acc = {total + count, batches + 1}
      if count < @batch_size, do: {:halt, acc}, else: {:cont, acc}
    end)
  end

  defp cutoff(days), do: DateTime.add(DateTime.utc_now(), -days * 86_400, :second)

  # ---- telemetry (per-table counts only, no PII — the design contract) ------------------

  defp emit_telemetry(counts) do
    metadata = %{
      records_deleted: counts.records_deleted,
      evidence_deleted: counts.evidence_deleted,
      fresh_runs_deleted: counts.fresh_runs_deleted,
      replay_runs_deleted: counts.replay_runs_deleted,
      status: counts.status
    }

    MailglassInbound.Telemetry.prune(metadata, fn -> {:ok, metadata} end)
    :ok
  end
end
