defmodule Mix.Tasks.Mailglass.Docs.Check do
  use Boundary, classify_to: Mailglass

  @shortdoc "Grep guides/*.md for leaked internal IDs (D-NN, LINT-NN)"

  @moduledoc """
  Fail the build if any internal decision ID (`D-NN`) or lint code
  (`LINT-NN`) appears in a published guide. Internal IDs belong in
  `.planning/`, not in HexDocs.

  ## Usage

      mix mailglass.docs.check
      mix mailglass.docs.check --path "guides/**/*.md"

  Exits 0 if clean. Raises with `Delivery blocked: ...` brand-voice
  message if any internal ID is found.
  """

  use Mix.Task

  @banned_patterns [~r/\bD-\d{2,3}\b/, ~r/\bLINT-\d{2}\b/]

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} = OptionParser.parse(argv, strict: [path: :string])
    validate_cli!(rest, invalid)

    paths = Path.wildcard(opts[:path] || "guides/**/*.md")

    leaks =
      Enum.flat_map(paths, fn path ->
        content = File.read!(path)

        Enum.flat_map(@banned_patterns, fn re ->
          re |> Regex.scan(content) |> Enum.map(&{path, hd(&1)})
        end)
      end)

    if leaks == [] do
      Mix.shell().info("[mailglass.docs.check] OK — no internal IDs leaked into public guides.")
      :ok
    else
      Enum.each(leaks, fn {path, token} ->
        Mix.shell().error("[mailglass.docs.check] internal ID #{inspect(token)} found in #{path}")
      end)

      Mix.raise("Delivery blocked: #{length(leaks)} internal ID(s) leaked into guides/*.md")
    end
  end

  defp validate_cli!([], []), do: :ok

  defp validate_cli!(rest, invalid) do
    cond do
      rest != [] ->
        Mix.raise("Delivery blocked: unexpected argument(s) #{inspect(rest)}.")

      invalid != [] ->
        Mix.raise("Delivery blocked: invalid flag(s) #{inspect(invalid)}.")
    end
  end
end
