defmodule Mailglass.Application do
  @moduledoc "Supervision tree for the Mailglass framework."
  use Application
  require Logger

  @impl Application
  def start(_type, _args) do
    if Code.ensure_loaded?(Mailglass.Config) and
         function_exported?(Mailglass.Config, :validate_at_boot!, 0) do
      Mailglass.Config.validate_at_boot!()
    end

    maybe_warn_missing_oban()
    maybe_warn_missing_oban_for_webhook_workers()

    # Phase 3: PubSub first (Projector broadcasts depend on it), then Task.Supervisor
    # (Oban-absent async fallback). The three optional supervisors are gated via
    # Code.ensure_loaded?/1 so Plan 01 can land first without Plans 02 + 03 having
    # shipped yet — and so both later plans can avoid patching this file (I-08).
    children =
      [
        {Phoenix.PubSub, name: Mailglass.PubSub, adapter: Phoenix.PubSub.PG2},
        {Task.Supervisor, name: Mailglass.TaskSupervisor}
      ]
      |> maybe_add(Mailglass.Adapters.Fake.Supervisor, {Mailglass.Adapters.Fake.Supervisor, []})
      |> maybe_add(Mailglass.RateLimiter.Supervisor, {Mailglass.RateLimiter.Supervisor, []})
      |> maybe_add(
        Mailglass.SuppressionStore.ETS.Supervisor,
        {Mailglass.SuppressionStore.ETS.Supervisor, []}
      )

    Supervisor.start_link(children, strategy: :one_for_one, name: Mailglass.Supervisor)
  end

  # Adds `child_spec` to the children list iff `module` is compiled-and-loadable.
  # The truthy branch makes Plan 02 (Fake.Supervisor) and Plan 03 (RateLimiter +
  # SuppressionStore.ETS) land their children purely by creating their supervisor
  # module — no second patch to this file required.
  defp maybe_add(children, module, child_spec) do
    if Code.ensure_loaded?(module), do: children ++ [child_spec], else: children
  end

  # D-17: emit exactly once per BEAM node lifetime via :persistent_term gate.
  # Subsequent Application.start/2 calls (supervisor restart, test harness) do not re-emit.
  defp maybe_warn_missing_oban do
    configured = Application.get_env(:mailglass, :async_adapter)
    already_warned? = :persistent_term.get({:mailglass, :oban_warning_emitted}, false)

    cond do
      already_warned? ->
        :ok

      configured == :task_supervisor ->
        :ok

      Code.ensure_loaded?(Oban) ->
        :ok

      true ->
        Logger.warning("""
        [mailglass] Oban not loaded; deliver_later/2 will use Task.Supervisor (non-durable).
        Set `config :mailglass, async_adapter: :task_supervisor` to silence this warning,
        or add `{:oban, "~> 2.21"}` to your deps for durable async delivery.
        """)

        :persistent_term.put({:mailglass, :oban_warning_emitted}, true)
        :ok
    end
  end

  # Phase 4 D-20: Webhook Reconciler + Pruner are both Oban-backed cron workers.
  # Without Oban, orphan events accumulate until `mix mailglass.reconcile` runs
  # and succeeded/dead webhook_events rows accumulate until `mix
  # mailglass.webhooks.prune` runs. Per revision W2 option b: ONE consolidated
  # warning covers both workers (mentions both mix tasks) — reduces log noise
  # vs. two separate warnings that repeat the same operator action.
  #
  # :persistent_term gate (same pattern as maybe_warn_missing_oban/0) ensures
  # exactly one emission per BEAM node lifetime.
  defp maybe_warn_missing_oban_for_webhook_workers do
    already_warned? =
      :persistent_term.get({:mailglass, :oban_warning_webhook_workers}, false)

    cond do
      already_warned? ->
        :ok

      Code.ensure_loaded?(Oban.Worker) ->
        :ok

      true ->
        Logger.warning("""
        [mailglass] Webhook orphan reconciliation AND retention pruning require :oban.
        Without Oban: orphan events will accumulate until you run
        `mix mailglass.reconcile` (manually or via system cron), AND
        succeeded/dead webhook_events rows will accumulate until you run
        `mix mailglass.webhooks.prune` (also manually or via system cron).
        To enable scheduled background workers, add {:oban, "~> 2.21"} to your deps.
        """)

        :persistent_term.put({:mailglass, :oban_warning_webhook_workers}, true)
        :ok
    end
  end
end
