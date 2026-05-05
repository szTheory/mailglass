defmodule Mix.Tasks.Mailglass.Reconcile do
  use Boundary, classify_to: Mailglass

  @shortdoc "Run the webhook orphan reconciliation sweep on demand"

  @moduledoc """
  Manually trigger the same reconciliation sweep that
  `Mailglass.Webhook.Reconciler` runs on its Oban cron schedule.

  Intended for:

    * Adopters without Oban in their deps (the Application boot
      warning directs them here — see CONTEXT D-20).
    * Ops engineers who want to run a sweep without waiting for the
      next `*/5 * * * *` cron tick.
    * System-cron invocation in Oban-less environments (e.g.
      `0,5,10,15,... * * * * cd /app && mix mailglass.reconcile`).

  ## Usage

      mix mailglass.reconcile
      mix mailglass.reconcile --tenant-id customer_a --batch-size 500

  ## Options

    * `--tenant-id` — restrict to a single tenant (default: all tenants)
    * `--batch-size` — max orphans per sweep (default: 1000)

  Emits the same `[:mailglass, :webhook, :reconcile, :start | :stop |
  :exception]` telemetry span as the Oban worker (telemetry metadata
  stays whitelist-conformant per D-23).

  When Oban is absent, this task still performs the same reconcile
  sweep and serves as the maintenance fallback you can run manually or
  from system cron.
  """

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {opts, _rest, _invalid} =
      OptionParser.parse(argv,
        strict: [tenant_id: :string, batch_size: :integer]
      )

    Mix.Task.run("app.start")

    tenant_id = opts[:tenant_id]
    batch_size = opts[:batch_size] || 1000

    reconciler = reconciler_module()

    {:ok, %{scanned: scanned, linked: linked}} =
      reconciler.reconcile(tenant_id, batch_size)

    still_unmatched = max(scanned - linked, 0)

    scheduler_note =
      if reconciler.available?() do
        "Oban scheduling is available."
      else
        "Oban is not installed; run this task manually or from system cron for scheduled sweeps."
      end

    Mix.shell().info(
      "Reconcile complete: scanned=#{scanned} linked=#{linked} still_unmatched=#{still_unmatched}" <>
        if(tenant_id, do: " tenant=#{tenant_id}", else: "") <>
        " " <> scheduler_note
    )
  end

  defp reconciler_module do
    Application.get_env(:mailglass, :webhook_reconciler, Mailglass.Webhook.Reconciler)
  end
end
