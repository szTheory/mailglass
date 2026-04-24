if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Webhook.Pruner do
    @moduledoc """
    Oban cron worker that prunes `mailglass_webhook_events` rows by
    status + age (CONTEXT D-16).

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
    lands with Plan 04-09 guides/webhooks.md).

    ## Optional-dep gating

    The entire module is conditionally compiled at file top level behind
    `if Code.ensure_loaded?(Oban.Worker)`. When Oban is absent, a stub
    module is defined that exposes `available?/0 → false`;
    `Mailglass.Application` emits a consolidated `Logger.warning` at boot
    (D-20) directing operators to run `mix mailglass.webhooks.prune` from
    their own cron infrastructure.

    ## GDPR erasure

    Targeted DELETE on `mailglass_webhook_events.raw_payload->>'to' = ?`
    is the GDPR path (D-15) — handled by adopter ad-hoc via
    `Mailglass.Repo.delete_all/2`, NOT this Pruner. The Pruner's
    DELETEs are retention-policy-driven (status + age), not identity-driven.

    ## Telemetry

    Emits `[:mailglass, :webhook, :prune, :stop]` with measurements
    `%{succeeded_deleted: n, dead_deleted: m}` and metadata
    `%{status: :ok}` per CONTEXT D-22 + D-23 whitelist.
    """

    use Oban.Worker, queue: :mailglass_maintenance

    import Ecto.Query

    alias Mailglass.{Clock, Repo}
    alias Mailglass.Webhook.WebhookEvent

    @doc """
    Returns `true` when the Pruner module is fully compiled (Oban
    available). Used by `mix mailglass.webhooks.prune` and the
    Application boot-warning.
    """
    @doc since: "0.1.0"
    @spec available?() :: boolean()
    def available?, do: true

    @impl Oban.Worker
    def perform(_job) do
      {:ok, %{succeeded: succeeded, dead: dead}} = prune()
      :ok = emit_telemetry(succeeded, dead)
      :ok
    end

    @doc """
    Run the prune sweep. Returns `{:ok, %{succeeded: n, dead: m}}`.

    Exposed as a public function so `mix mailglass.webhooks.prune`
    invokes the same code path, and so ops engineers can trigger an
    out-of-band prune without waiting for the next cron tick.
    """
    @spec prune() :: {:ok, %{succeeded: non_neg_integer(), dead: non_neg_integer()}}
    def prune do
      retention = Application.get_env(:mailglass, :webhook_retention, [])
      succeeded_days = Keyword.get(retention, :succeeded_days, 14)
      dead_days = Keyword.get(retention, :dead_days, 90)

      {:ok, succeeded_count} = prune_status(:succeeded, succeeded_days)
      {:ok, dead_count} = prune_status(:dead, dead_days)

      {:ok, %{succeeded: succeeded_count, dead: dead_count}}
    end

    defp prune_status(_status, :infinity), do: {:ok, 0}

    defp prune_status(status, days)
         when is_atom(status) and is_integer(days) and days > 0 do
      cutoff = DateTime.add(Clock.utc_now(), -days * 86_400, :second)

      {count, _} =
        Repo.delete_all(
          from(w in WebhookEvent,
            where: w.status == ^status and w.inserted_at < ^cutoff
          )
        )

      {:ok, count}
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
