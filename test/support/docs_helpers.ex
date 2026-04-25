defmodule Mailglass.DocsHelpers do
  @moduledoc false

  @doc """
  Extracts fenced code blocks from a markdown file.
  """
  def extract_code_blocks(path) do
    content = File.read!(path)

    Regex.scan(~r/```(?:elixir|bash|sql)\n(.*?)\n```/s, content)
    |> Enum.map(fn [_, code] -> code end)
  end

  @doc """
  Extracts a specific fenced code block following a heading.
  """
  def extract_block_after_heading(path, heading) do
    content = File.read!(path)
    pattern = ~r/##\s+#{Regex.escape(heading)}\n.*?```(?:elixir|bash)\n(.*?)\n```/s

    case Regex.run(pattern, content) do
      [_, code] -> code
      nil -> nil
    end
  end
end
