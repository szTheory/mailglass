defmodule Mix.Tasks.Mailglass.Audit do
  use Boundary, classify_to: Mailglass
  use Mix.Task

  @shortdoc "Audit Mailglass dependencies across all three Mix projects"

  # No `since:` tag — this task is deliberately NOT part of the stable
  # Mix-task contract (`docs/api_stability.md`). It lives under `dev/`, which
  # is on `elixirc_paths(:dev)`/`(:test)` only (mix.exs), so it compiles for
  # local/CI use but never ships in the Hex tarball.
  @moduledoc """
  Runs `mix hex.audit` or `mix deps.audit` across the root, `mailglass_admin`,
  and `mailglass_inbound` Mix projects, filtering findings through the shared
  `Mailglass.SupplyChain.AcceptedAdvisories` allowlist.

  ## Usage

      mix mailglass.audit --kind hex
      mix mailglass.audit --kind deps

  `--kind hex` also evaluates the allowlist's own health: an accepted entry
  whose `recheck_by` date has passed, or that matched no current finding
  across all three directories, blocks delivery even when every live finding
  is otherwise accepted (D-10, VULN-06). `--kind deps` applies alias-aware
  suppression only — it does not independently re-litigate entry health,
  because `mix deps.audit` does not natively detect these two entries (see
  `Mailglass.SupplyChain.AcceptedAdvisories`'s "Known limitation" moduledoc
  section).
  """

  alias Mailglass.SupplyChain.AcceptedAdvisories

  @scan_dirs ["", "mailglass_admin", "mailglass_inbound"]

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} = OptionParser.parse(argv, strict: [kind: :string])

    validate_cli!(opts, rest, invalid)

    kind = String.to_existing_atom(opts[:kind])

    case run_check(kind) do
      {:ok, accepted} ->
        Enum.each(accepted, fn line -> Mix.shell().info(line) end)
        Mix.shell().info("mix mailglass.audit --kind #{opts[:kind]}: all findings accepted.")

      {:error, blocking} ->
        Enum.each(blocking, fn line -> Mix.shell().error(line) end)
        exit({:shutdown, 1})
    end
  end

  defp validate_cli!(opts, rest, invalid) do
    if opts[:kind] not in ["hex", "deps"] do
      Mix.raise("Delivery blocked: --kind must be hex or deps.")
    end

    if rest != [] do
      Mix.raise("Delivery blocked: unknown args #{Enum.join(rest, " ")}")
    end

    if invalid != [] do
      flags = invalid |> Enum.map(fn {key, _} -> "--#{key}" end) |> Enum.join(", ")
      Mix.raise("Delivery blocked: unknown args #{flags}")
    end
  end

  @doc false
  def run_check(:hex) do
    dir_outputs =
      Enum.map(@scan_dirs, fn dir ->
        full_path = full_path(dir)

        {_deps_output, _deps_status} =
          System.cmd("mix", ["deps.get"], cd: full_path, stderr_to_stdout: true)

        {output, status} =
          System.cmd("mix", ["hex.audit"], cd: full_path, stderr_to_stdout: true)

        {dir, output, status}
      end)

    evaluate(:hex, dir_outputs)
  end

  def run_check(:deps) do
    dir_outputs =
      Enum.map(@scan_dirs, fn
        "" = dir ->
          {output, status} = System.cmd("mix", ["deps.audit"], stderr_to_stdout: true)
          {dir, output, status}

        dir ->
          {output, status} =
            System.cmd("mix", ["deps.audit", "--path", dir], stderr_to_stdout: true)

          {dir, output, status}
      end)

    evaluate(:deps, dir_outputs)
  end

  defp full_path(""), do: File.cwd!()
  defp full_path(dir), do: Path.join(File.cwd!(), dir)

  @doc false
  def evaluate(:hex, dir_outputs) do
    {blocking, accepted, matched_ids} =
      Enum.reduce(dir_outputs, {[], [], MapSet.new()}, fn {dir, output, status},
                                                          {blocking, accepted, matched} ->
        dir_matched = AcceptedAdvisories.matched_hex_audit_ids(output)

        blocking =
          if status != 0 do
            case AcceptedAdvisories.unaccepted_audit_findings(output) do
              [] -> blocking
              unaccepted -> blocking ++ Enum.map(unaccepted, &"#{directory_label(dir)}#{&1}")
            end
          else
            blocking
          end

        accepted =
          if status != 0 and MapSet.size(dir_matched) > 0 do
            accepted ++
              Enum.map(MapSet.to_list(dir_matched), fn id ->
                "#{directory_label(dir, "Accepted")}#{id} is an accepted-allowlist finding."
              end)
          else
            accepted
          end

        {blocking, accepted, MapSet.union(matched, dir_matched)}
      end)

    blocking =
      blocking ++
        Enum.map(AcceptedAdvisories.expired_entries(), fn entry ->
          "Delivery blocked: accepted advisory #{entry.id}'s recheck_by " <>
            "(#{entry.recheck_by}) has passed. Re-verify upstream status and update or " <>
            "remove the entry."
        end) ++
        Enum.map(AcceptedAdvisories.unused_entries(matched_ids), fn entry ->
          "Delivery blocked: allowlist entry #{entry.id} matches no current finding — remove it."
        end)

    if blocking == [], do: {:ok, accepted}, else: {:error, blocking}
  end

  def evaluate(:deps, dir_outputs) do
    blocking =
      Enum.reduce(dir_outputs, [], fn {dir, output, status}, blocking ->
        if status != 0 do
          case AcceptedAdvisories.unaccepted_deps_audit_findings(output) do
            [] -> blocking
            unaccepted -> blocking ++ Enum.map(unaccepted, &"#{directory_label(dir)}#{&1}")
          end
        else
          blocking
        end
      end)

    if blocking == [], do: {:ok, []}, else: {:error, blocking}
  end

  defp directory_label(dir, prefix \\ "Delivery blocked")
  defp directory_label("", prefix), do: "#{prefix}: "
  defp directory_label(dir, prefix), do: "#{prefix} (#{dir}): "
end
