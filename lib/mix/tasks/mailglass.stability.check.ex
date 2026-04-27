defmodule Mix.Tasks.Mailglass.Stability.Check do
  use Boundary, classify_to: Mailglass

  @shortdoc "Checks for Swoosh type leaks in the public API"

  @moduledoc """
  Ensures that `Swoosh.Email.t()` types do not leak into the `Mailglass`
  public namespace, preventing downstream developers from accidentally coupling
  to our internal engine's types.

  Exemptions (escape hatches and internals):
  - `Mailglass.Message.update_swoosh/2` (official escape hatch)
  - `Mailglass.Message.new/2` (deprecated v0.1 API)
  - `Mailglass.Outbound.send/2` (deprecated v0.1 API)
  - `Mailglass.Compliance` (internal utility)
  - `Mailglass.Adapters.*` (internal implementations)
  """

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    if "--no-compile" not in argv do
      Mix.Task.run("compile", [])
    end

    files = Path.wildcard("lib/mailglass/**/*.ex") ++ ["lib/mailglass.ex"]

    leaks =
      for file <- files,
          content = File.read!(file),
          {line, index} <- Enum.with_index(String.split(content, "\n")),
          line_num = index + 1,
          String.match?(line, ~r/@(spec|type).*Swoosh\.Email\.t\(\)/),
          not exempt?(file, line) do
        {file, line_num, String.trim(line)}
      end

    if Enum.empty?(leaks) do
      Mix.shell().info("API Stability Check Passed: No Swoosh types leaked.")
      # Returning normally exits with 0
    else
      Mix.shell().error("API Stability Check Failed: Swoosh types leaked into public API.")
      for {file, line_num, line} <- leaks do
        Mix.shell().error("  #{file}:#{line_num} -> #{line}")
      end
      exit({:shutdown, 1})
    end
  end

  defp exempt?("lib/mailglass/message.ex", line) do
    String.contains?(line, "update_swoosh(") or String.contains?(line, "new(")
  end

  defp exempt?("lib/mailglass/outbound.ex", line) do
    String.contains?(line, "send(")
  end

  defp exempt?("lib/mailglass/compliance.ex", _line), do: true

  defp exempt?("lib/mailglass/adapters/" <> _, _line), do: true

  defp exempt?(_file, _line), do: false
end
