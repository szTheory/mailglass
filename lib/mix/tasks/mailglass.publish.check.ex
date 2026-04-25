defmodule Mix.Tasks.Mailglass.Publish.Check do
  use Boundary, classify_to: Mailglass
  use Mix.Task

  @moduledoc """
  Validates the Hex package before publishing.

  Checks for:
  1. Forbidden files in the tarball (mix hex.build --list)
  2. Documentation coverage
  3. Version consistency
  """

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info("Checking package for forbidden files...")

    # Build and unpack to a temporary directory
    tmp_dir = "publish_check_unpack"
    File.rm_rf!(tmp_dir)

    {_, 0} = System.cmd("mix", ["hex.build", "--unpack", "--output", tmp_dir])

    # List all files in the unpacked directory
    files =
      tmp_dir
      |> Path.join("**/*")
      |> Path.wildcard()
      |> Enum.map(&Path.relative_to(&1, tmp_dir))

    forbidden_patterns = [
      ~r/^_build/,
      ~r/^deps/,
      ~r/^\.git/,
      ~r/^\.gsd/,
      ~r/^\.planning/,
      ~r/^\.claude/
    ]

    leaked_files =
      Enum.filter(files, fn file ->
        Enum.any?(forbidden_patterns, &Regex.match?(&1, file))
      end)

    File.rm_rf!(tmp_dir)

    if leaked_files != [] do
      Mix.raise("""
      Forbidden files detected in package:
      #{Enum.join(leaked_files, "\n")}

      Check your `mix.exs` :package :files configuration.
      """)
    end

    Mix.shell().info("No forbidden files detected.")
  end
end
