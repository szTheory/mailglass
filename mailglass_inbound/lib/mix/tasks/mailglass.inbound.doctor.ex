defmodule Mix.Tasks.Mailglass.Inbound.Doctor do
  # NOTE: no `use Boundary, classify_to:` here. `mailglass_inbound` does not run
  # the `:boundary` compiler (only `mailglass` core does), so the annotation would
  # not compile. The boundary LAW (inbound depends on core, never the reverse) is
  # still honored — this omits only the compile-time annotation (deliberate
  # deviation from the design contract's literal wording, orchestrator-resolved in 49-03).
  use Mix.Task

  alias MailglassInbound.Internal.Doctor
  alias MailglassInbound.Operator.Formatter

  @shortdoc "Run DNS-free inbound config checks (routes, mailboxes, signing keys, MIME)"

  @moduledoc since: "0.2.0"
  @moduledoc """
  Run DNS-free pre-deploy configuration checks for inbound mail.

  Mirrors `mix mail.doctor` but is entirely offline: it reflects your configured
  inbound router and validates routes (compile + don't conflict), mailboxes (exist
  + implement `process/1`), provider signing-key PRESENCE (never verifies a
  signature), and MIME-backend availability.

  ## Usage

      mix mailglass.inbound.doctor
      mix mailglass.inbound.doctor --strict
      mix mailglass.inbound.doctor --format json
      mix mailglass.inbound.doctor --verbose

  Reads `config :mailglass_inbound, router: MyApp.InboundRouter`.

  ## Exit codes (three-state — Credo's model)

    * `0` — all checks pass (or pass+warn without `--strict`)
    * `1` — at least one failure (or any warning under `--strict`) — the CI signal
    * `2` — cannot diagnose (no router configured / router does not compile)
  """

  @impl Mix.Task
  @spec run([String.t()]) :: no_return()
  def run(argv) do
    {opts, rest, invalid} =
      OptionParser.parse(argv,
        # WR-02: `no_start` must be declared in the strict spec (matching the
        # replay/prune tasks), or the `--no-start` flag the run/1 body branches on
        # below is rejected as an unknown option and the escape hatch is dead.
        strict: [format: :string, strict: :boolean, verbose: :boolean, no_start: :boolean]
      )

    validate_cli!(opts, rest, invalid)

    unless Keyword.get(opts, :no_start, false) do
      Mix.Task.run("app.start")
    end

    result = Doctor.run([])

    result
    |> render_output(opts)
    |> Mix.shell().info()

    exit({:shutdown, exit_code(result.summary, opts)})
  end

  # Mix.raise is reserved for CLI MISUSE only (bad flags / positional / format).
  # Check FINDINGS are surfaced via the three-state exit code, never Mix.raise
  # (Pitfall 6 — otherwise exit 2 is unreachable).
  defp validate_cli!(opts, rest, invalid) do
    if rest != [] do
      Mix.raise("Inbound doctor blocked: unexpected positional arguments #{Enum.join(rest, " ")}")
    end

    if invalid != [] do
      invalid_flags = invalid |> Enum.map(fn {key, _value} -> "--#{key}" end) |> Enum.join(", ")
      Mix.raise("Inbound doctor blocked: unknown option(s) #{invalid_flags}")
    end

    format = Keyword.get(opts, :format, "human")

    unless format in ["human", "json"] do
      Mix.raise("Inbound doctor blocked: --format must be human or json, got #{inspect(format)}")
    end

    :ok
  end

  defp render_output(result, opts) do
    case Keyword.get(opts, :format, "human") do
      "json" -> Formatter.render_json(result)
      "human" -> Formatter.render_human(result, verbose?: opts[:verbose] == true)
    end
  end

  # 2 = cannot-diagnose (no router / boot failure) — checked FIRST.
  # 1 = >= 1 fail, OR any warn under --strict.
  # 0 = otherwise.
  defp exit_code(summary, opts) do
    strict? = Keyword.get(opts, :strict, false)

    cond do
      Map.get(summary, :cannot_diagnose, 0) > 0 -> 2
      Map.get(summary, :fail, 0) > 0 -> 1
      strict? and Map.get(summary, :warn, 0) > 0 -> 1
      true -> 0
    end
  end
end
