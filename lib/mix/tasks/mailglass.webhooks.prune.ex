defmodule Mix.Tasks.Mailglass.Webhooks.Prune do
  use Boundary, classify_to: Mailglass

  @shortdoc "Run the webhook event retention sweep on demand"

  @moduledoc """
  Manually trigger the same retention sweep that
  `Mailglass.Webhook.Pruner` runs on its Oban cron schedule.

  Intended for:

    * Adopters without Oban in their deps (the Application boot
      warning directs them here — see CONTEXT D-20).
    * Ops engineers who want to run a prune sweep out-of-band.
    * System-cron invocation in Oban-less environments
      (e.g. `0 3 * * * cd /app && mix mailglass.webhooks.prune`).

  ## Usage

      mix mailglass.webhooks.prune

  Reads `Mailglass.Config :webhook_retention` for the three retention
  knobs (`:succeeded_days`, `:dead_days`, `:failed_days`). Each may be
  a positive integer or `:infinity` to disable.

  Emits `[:mailglass, :webhook, :prune, :stop]` telemetry with
  `%{succeeded_deleted: n, dead_deleted: m}` measurements and
  `%{status: :ok}` metadata per CONTEXT D-22 + D-23 whitelist.

  Exits with status 1 when `Mailglass.Webhook.Pruner` is not compiled
  (Oban absent from deps).
  """

  use Mix.Task

  # Pruner.prune/0 is only defined when Oban is loaded (the module is
  # conditionally compiled at file top level). Guarded by `available?()`.
  @compile {:no_warn_undefined, {Mailglass.Webhook.Pruner, :prune, 0}}

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("app.start")

    if Mailglass.Webhook.Pruner.available?() do
      {:ok, %{succeeded: s, dead: d}} = Mailglass.Webhook.Pruner.prune()

      Mix.shell().info("Webhook prune complete: succeeded_deleted=#{s} dead_deleted=#{d}")
    else
      Mix.shell().error(
        "Mailglass.Webhook.Pruner is not compiled (Oban not available). " <>
          "Add {:oban, \"~> 2.21\"} to your deps to enable scheduled pruning."
      )

      exit({:shutdown, 1})
    end
  end
end
