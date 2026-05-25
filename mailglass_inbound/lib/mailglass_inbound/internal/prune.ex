defmodule MailglassInbound.Internal.Prune do
  @moduledoc """
  Oban-independent batched retention sweep for inbound tables (IOPS-03,
  D-49-25..30). This is the workhorse: `mix mailglass.inbound.prune` and the
  optional `MailglassInbound.Prune.Worker` cron both call `prune/0`.

  Mirrors `Mailglass.Webhook.Pruner`'s STRUCTURE (`:infinity` disables a class,
  per-table telemetry) but UPGRADES the unbounded `delete_all` to a batched idiom
  (D-49-27): each table deletes `LIMIT 1000` rows at a time
  (`FOR UPDATE SKIP LOCKED`), looping until a batch deletes `< 1000`. The whole
  sweep is serialized by a session `pg_try_advisory_lock` — a concurrent second
  run returns `{:ok, :locked_out}` and deletes nothing.

  ## Window split (D-49-25) — three physical tables, four windows

    * `mailglass_inbound_replay_runs` WHERE `source = :replay` AND age > replay_runs_days (30d)
    * `mailglass_inbound_replay_runs` WHERE `source = :fresh`  AND age > execution_runs_days (90d)
    * `mailglass_inbound_evidence` WHERE age > evidence_days (30d)
    * `mailglass_inbound_records` WHERE age > records_days (90d)

  Deletes run child-first (D-49-26): replay_runs (both source filters) -> evidence
  -> records. FKs are `on_delete: :nothing`, so a mis-ordered delete fails loudly
  on the FK (the designed safety net — do NOT switch to CASCADE).

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
    replay_days = Keyword.get(retention, :replay_runs_days, 30)
    fresh_days = Keyword.get(retention, :execution_runs_days, 90)
    evidence_days = Keyword.get(retention, :evidence_days, 30)
    records_days = Keyword.get(retention, :records_days, 90)

    # Child-first order (D-49-26): replay_runs (both source filters) -> evidence
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

  defp with_advisory_lock(repo, fun) do
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
  # is NOT one transaction — each delete_all commits on its own (D-49-27).
  defp delete_batched(repo, schema, window) do
    Stream.repeatedly(fn ->
      inner =
        schema
        |> window.()
        |> select([r], r.id)
        |> limit(^@batch_size)
        |> lock("FOR UPDATE SKIP LOCKED")

      {count, _} =
        repo.delete_all(from(r in schema, where: r.id in subquery(inner)))

      count
    end)
    |> Enum.reduce_while({0, 0}, fn count, {total, batches} ->
      acc = {total + count, batches + 1}
      if count < @batch_size, do: {:halt, acc}, else: {:cont, acc}
    end)
  end

  defp cutoff(days), do: DateTime.add(DateTime.utc_now(), -days * 86_400, :second)

  # ---- telemetry (per-table counts only, no PII — D-49-29) ------------------

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
