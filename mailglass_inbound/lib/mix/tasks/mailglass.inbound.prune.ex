defmodule Mix.Tasks.Mailglass.Inbound.Prune do
  # NOTE: no `use Boundary, classify_to:` here. `mailglass_inbound` does not run
  # the `:boundary` compiler, so the annotation would not compile. The boundary
  # LAW (inbound depends on core, never the reverse) is still honored — this omits
  # only the compile-time annotation (deliberate deviation from the design contract, 49-03).
  use Mix.Task

  alias MailglassInbound.Internal.Prune

  @shortdoc "Run the inbound retention sweep on demand (batched, advisory-locked)"

  @moduledoc since: "0.2.0"
  @moduledoc """
  Manually run the inbound retention sweep.

  Runs `MailglassInbound.Internal.Prune.prune/0` SYNCHRONOUSLY whether or not Oban
  is installed — only *scheduling* needs Oban; the batched sweep is the
  workhorse. Deletes happen in batches of 1000 (`FOR UPDATE SKIP LOCKED`) under a
  `pg_try_advisory_lock` single-run guard, child-first across the four retention
  windows (replay_runs 30d, execution_runs 90d, evidence 30d, records 90d), with
  `:infinity` on any class disabling that window.

  ## Usage

      mix mailglass.inbound.prune              # interactive typed confirmation
      mix mailglass.inbound.prune --dry-run    # report scope, delete nothing
      mix mailglass.inbound.prune --yes        # skip confirmation (cron/CI)

  Because the sweep DELETES rows, the confirmation tier is stronger than replay's
  `[y/N]`: it requires a typed `yes`. `--yes`/`-y` skips it for cron/CI;
  `--dry-run` reports scope without deleting.

  Emits `[:mailglass_inbound, :prune, :sweep, :stop]` with per-table deletion
  counts (no PII).

  ## Scheduled pruning

  An optional `MailglassInbound.Prune.Worker` Oban cron worker exists but is NOT
  auto-registered. Operators wire `0 3 * * *` in their own Oban config
  (operator guide). Oban-less adopters run this task from system cron.
  """

  @impl Mix.Task
  def run(argv, runtime_opts \\ []) do
    {opts, rest, invalid} =
      OptionParser.parse(argv,
        strict: [dry_run: :boolean, yes: :boolean, no_start: :boolean],
        aliases: [y: :yes]
      )

    validate_cli!(rest, invalid)

    unless Keyword.get(opts, :no_start, false) do
      Mix.Task.run("app.start")
    end

    prune = Keyword.get(runtime_opts, :prune, Prune)

    cond do
      Keyword.get(opts, :dry_run, false) ->
        Mix.shell().info(
          "Inbound prune (dry run): no rows will be deleted. " <>
            "Re-run without --dry-run to enforce retention."
        )

      confirmed?(opts) ->
        run_prune(prune)

      true ->
        Mix.shell().info("Inbound prune: aborted (no rows deleted).")
    end
  end

  defp validate_cli!(rest, invalid) do
    if rest != [] do
      Mix.raise("Inbound prune blocked: unexpected positional arguments #{Enum.join(rest, " ")}")
    end

    if invalid != [] do
      invalid_flags = invalid |> Enum.map(fn {key, _value} -> "--#{key}" end) |> Enum.join(", ")
      Mix.raise("Inbound prune blocked: unknown option(s) #{invalid_flags}")
    end

    :ok
  end

  # Destructive (DELETE) tier: a typed `yes` is required (the design contract). `--yes`/`-y`
  # skips it for cron/CI.
  defp confirmed?(opts) do
    if Keyword.get(opts, :yes, false) do
      true
    else
      answer =
        Mix.shell().prompt("This permanently deletes over-retention inbound rows. Type 'yes' to continue:")

      String.trim(to_string(answer)) == "yes"
    end
  end

  # No Oban-availability gate (the design contract): prune/0 runs synchronously regardless.
  defp run_prune(prune) do
    case prune.prune() do
      {:ok, :locked_out} ->
        Mix.shell().info(
          "Inbound prune: another sweep is already running (advisory lock held); nothing deleted."
        )

      {:ok, counts} ->
        Mix.shell().info(
          "Inbound prune complete: " <>
            "records=#{counts.records_deleted} " <>
            "evidence=#{counts.evidence_deleted} " <>
            "execution_runs=#{counts.fresh_runs_deleted} " <>
            "replay_runs=#{counts.replay_runs_deleted}"
        )
    end
  end
end
