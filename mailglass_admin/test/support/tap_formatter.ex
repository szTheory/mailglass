defmodule MailglassAdmin.TestSupport.TapFormatter do
  @moduledoc false

  use GenServer

  @impl GenServer
  def init(_options), do: {:ok, []}

  @impl GenServer
  def handle_cast({:test_finished, %ExUnit.Test{} = test}, tests) do
    {:noreply, [test | tests]}
  end

  def handle_cast({:suite_finished, _times}, tests) do
    IO.write(report(Enum.reverse(tests)))
    {:noreply, tests}
  end

  def handle_cast(_event, tests), do: {:noreply, tests}

  defp report(tests) do
    assertions =
      tests
      |> Enum.with_index(1)
      |> Enum.map(fn {test, index} -> assertion(test, index) end)

    ["TAP version 13\n", "1..#{length(tests)}\n", assertions]
  end

  defp assertion(%ExUnit.Test{state: nil} = test, index) do
    "ok #{index} - #{test_name(test)}\n"
  end

  defp assertion(%ExUnit.Test{state: {:skipped, reason}} = test, index) do
    "ok #{index} - #{test_name(test)} # SKIP #{single_line(reason)}\n"
  end

  defp assertion(%ExUnit.Test{state: {:excluded, reason}} = test, index) do
    "ok #{index} - #{test_name(test)} # SKIP excluded: #{single_line(reason)}\n"
  end

  defp assertion(%ExUnit.Test{state: state} = test, index) do
    ["not ok #{index} - #{test_name(test)}\n", diagnostics(state, test)]
  end

  defp diagnostics({:failed, failures}, test) do
    Enum.map(failures, fn {kind, reason, stacktrace} ->
      reason_type = if is_map(reason), do: Map.get(reason, :__struct__, :map), else: :unknown

      [
        "# failure: #{inspect(kind)} #{inspect(reason_type)}\n",
        location(stacktrace, test)
      ]
    end)
  end

  defp diagnostics({:invalid, _module}, test) do
    ["# setup_all failed before test body\n", location([], test)]
  end

  defp diagnostics(_state, test) do
    ["# incomplete or unknown test state: #{inspect(test.state)}\n", location([], test)]
  end

  defp location(stacktrace, test) do
    case Enum.find(stacktrace, fn frame -> is_list(frame) and Keyword.has_key?(frame, :file) end) do
      frame when is_list(frame) ->
        file = Keyword.fetch!(frame, :file) |> to_string() |> Path.basename()
        line = Keyword.get(frame, :line, test.tags[:line])
        "# location: #{file}:#{line}\n"

      _ ->
        "# location: #{Path.basename(test.tags[:file])}:#{test.tags[:line]}\n"
    end
  end

  defp test_name(test) do
    "#{inspect(test.module)} > #{test.name}"
    |> single_line()
  end

  defp single_line(value) do
    value
    |> to_string()
    |> String.replace(~r/[\r\n\t]+/u, " ")
  end
end
