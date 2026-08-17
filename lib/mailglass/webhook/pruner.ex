if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Webhook.Pruner do
    @moduledoc """
    Oban cron worker that prunes `mailglass_webhook_events` rows by
    status + age (CONTEXT ).

    Three retention knobs (per `Mailglass.Config :webhook_retention`):

      * `:succeeded_days` (default 14) — prune `:succeeded` rows older
        than N days
      * `:dead_days` (default 90) — prune `:dead` (terminal-after-retries)
        rows older than N days
      * `:failed_days` (default `:infinity`) — `:failed` rows are
        investigatable; never pruned by default

    Set any knob to `:infinity` to disable that prune class — the worker
    returns `{:ok, 0}` for that status WITHOUT issuing the DELETE.

    ## Cron cadence

    Daily is sufficient — retention is days-scale, so running hourly adds
    DB churn without changing outcomes. Adopters wire the cron in their
    own Oban config (`0 3 * * *` — 3 AM UTC is the recommended default;
    lands with -09 guides/webhooks.md).

    ## Optional-dep gating

    The entire module is conditionally compiled at file top level behind
    `if Code.ensure_loaded?(Oban.Worker)`. When Oban is absent, a stub
    module is defined that exposes `available?/0 → false`;
    `Mailglass.Application` emits a consolidated `Logger.warning` at boot
    directing operators to run `mix mailglass.webhooks.prune` from
    their own cron infrastructure.

    ## GDPR erasure

    Targeted DELETE on `mailglass_webhook_events.raw_payload->>'to' = ?`
    is the GDPR path — handled by adopter ad-hoc via
    `Mailglass.Repo.delete_all/2`, NOT this Pruner. The Pruner's
    DELETEs are retention-policy-driven (status + age), not identity-driven.

    ## Telemetry

    Emits `[:mailglass, :webhook, :prune, :stop]` with measurements
    `%{succeeded_deleted: n, dead_deleted: m}` and metadata
    `%{status: :ok}` per CONTEXT  +  whitelist.
    """

    use Oban.Worker, queue: :mailglass_maintenance

    import Ecto.Query

    alias Mailglass.Clock
    alias Mailglass.Webhook.WebhookEvent

    @doc """
    Returns `true` when the Pruner module is fully compiled (Oban
    available). Used by `mix mailglass.webhooks.prune` and the
    Application boot-warning.
    """
    @doc since: "0.1.0"
    @spec available?() :: true
    def available?, do: true

    @impl Oban.Worker
    def perform(_job) do
      {succeeded, dead} =
        case prune() do
          {:ok, %{succeeded: succeeded, dead: dead}} -> {succeeded, dead}
          # A concurrent sweep holds the advisory lock. Oban should treat this
          # as a successful no-op, with the same telemetry shape as an empty run.
          {:ok, :locked_out} -> {0, 0}
        end

      :ok = emit_telemetry(succeeded, dead)
      :ok
    end

    @doc """
    Run the prune sweep. Returns `{:ok, %{succeeded: n, dead: m}}`, or
    `{:ok, :locked_out}` when another sweep holds the advisory lock.

    Exposed as a public function so `mix mailglass.webhooks.prune`
    invokes the same code path, and so ops engineers can trigger an
    out-of-band prune without waiting for the next cron tick.
    """
    @doc since: "0.1.0"
    @spec prune() ::
            {:ok, %{succeeded: non_neg_integer(), dead: non_neg_integer()}} | {:ok, :locked_out}
    @batch_size 1_000
    @prune_lock_key 6_642_484_338_949_089_810

    @spec lock_key() :: integer()
    def lock_key, do: @prune_lock_key

    def prune do
      retention = Mailglass.Config.webhook_retention()
      succeeded_days = Keyword.get(retention, :succeeded_days, 14)
      dead_days = Keyword.get(retention, :dead_days, 90)

      with_advisory_lock(fn ->
        {:ok, succeeded_count} = prune_status(:succeeded, succeeded_days)
        {:ok, dead_count} = prune_status(:dead, dead_days)
        {:ok, %{succeeded: succeeded_count, dead: dead_count}}
      end)
    end

    defp prune_status(_status, :infinity), do: {:ok, 0}

    defp prune_status(status, days)
         when is_atom(status) and is_integer(days) and days > 0 do
      cutoff = DateTime.add(Clock.utc_now(), -days * 86_400, :second)

      {:ok, delete_batched(status, cutoff)}
    end

    defp with_advisory_lock(fun) do
      repo =
        Mailglass.Config.repo() || raise Mailglass.ConfigError.new(:missing, context: %{key: :repo})

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

    defp delete_batched(status, cutoff) do
      repo =
        Mailglass.Config.repo() || raise Mailglass.ConfigError.new(:missing, context: %{key: :repo})

      Stream.repeatedly(fn ->
        candidates =
          from(w in WebhookEvent,
            where: w.status == ^status and w.inserted_at < ^cutoff,
            order_by: [asc: w.inserted_at, asc: w.id],
            select: w.id,
            limit: ^@batch_size,
            lock: "FOR UPDATE SKIP LOCKED"
          )

        {count, _} =
          repo.delete_all(from(w in WebhookEvent, where: w.id in subquery(candidates)),
            prefix: Mailglass.Config.schema()
          )

        count
      end)
      |> Enum.reduce_while(0, fn count, total ->
        total = total + count
        if count < @batch_size, do: {:halt, total}, else: {:cont, total}
      end)
    end

    defp emit_telemetry(succeeded_deleted, dead_deleted) do
      :telemetry.execute(
        [:mailglass, :webhook, :prune, :stop],
        %{succeeded_deleted: succeeded_deleted, dead_deleted: dead_deleted},
        %{status: :ok}
      )

      :ok
    end
  end
else
  defmodule Mailglass.Webhook.Pruner do
    @moduledoc """
    Stub module — Oban is not loaded, so the Pruner worker is not compiled.

    `available?/0` returns `false`. `mix mailglass.webhooks.prune` reads
    this flag and exits with a non-zero status when invoked.
    """

    @doc since: "0.1.0"
    @spec available?() :: false
    def available?, do: false
  end
end
