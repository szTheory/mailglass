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

  Exits with status 1 when the `Mailglass.Webhook.Reconciler` module is
  not compiled (Oban absent from deps).
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

    if Mailglass.Webhook.Reconciler.available?() do
      {:ok, %{scanned: scanned, linked: linked}} =
        Mailglass.Webhook.Reconciler.reconcile(tenant_id, batch_size)

      Mix.shell().info(
        "Reconcile complete: scanned=#{scanned} linked=#{linked}" <>
          if(tenant_id, do: " tenant=#{tenant_id}", else: "")
      )
    else
      Mix.shell().error(
        "Mailglass.Webhook.Reconciler is not compiled (Oban not available). " <>
          "Add {:oban, \"~> 2.21\"} to your deps to enable reconciliation."
      )

      exit({:shutdown, 1})
    end
  end
end
