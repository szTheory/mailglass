defmodule Mix.Tasks.Mailglass.Preflight do
  use Boundary, classify_to: Mailglass

  use Mix.Task

  @shortdoc "Check a host's Mailglass production readiness"

  @moduledoc """
  Runs the explicit, secret-safe Mailglass production readiness check.

      mix mailglass.preflight

  The task starts the host application so it can observe the configured Repo
  and live Oban queue. It exits nonzero when any prerequisite fails and does
  not alter normal application boot behavior.
  """

  @impl Mix.Task
  def run(argv) do
    if argv != [], do: Mix.raise("mailglass.preflight does not accept arguments")

    Mix.Task.run("app.start")
    result = Mailglass.ProductionPreflight.run()

    Enum.each(result.checks, fn check ->
      label = if(check.status == :passed, do: "pass", else: "fail")
      line = "[#{label}] #{check.id}"

      Mix.shell().info(
        if(check.status == :passed, do: line, else: line <> " — " <> check.remediation)
      )
    end)

    if result.status == :ready, do: :ok, else: exit({:shutdown, 1})
  end
end
