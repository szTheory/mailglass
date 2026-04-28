defmodule Mailglass.Credo.MultiEventFirstInWebhookIngestTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.MultiEventFirstInWebhookIngest

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "accepts webhook ingest when event append stays before suppression" do
    source = """
    defmodule Mailglass.Webhook.Ingest do
      alias Ecto.Multi
      alias Mailglass.Events

      defp update_projections_for_each(multi, events) do
        events
        |> Enum.with_index()
        |> Enum.reduce(multi, fn {_event, idx}, acc ->
          acc
          |> Events.append_multi(event_step_name(idx), fn _changes -> %{} end)
          |> Multi.run({:projector_categorize, idx}, fn _repo, _changes -> {:ok, :matched} end)
          |> Multi.run({:projector_apply, idx}, fn _repo, _changes -> {:ok, :matched} end)
          |> Multi.run({:auto_suppress, idx}, fn _repo, _changes -> {:ok, :matched} end)
        end)
      end
    end
    """

    assert run_check(source) == []
  end

  test "flags webhook ingest when suppression is inserted before event append path" do
    source = """
    defmodule Mailglass.Webhook.Ingest do
      alias Ecto.Multi
      alias Mailglass.Events

      defp update_projections_for_each(multi, events) do
        events
        |> Enum.with_index()
        |> Enum.reduce(multi, fn {_event, idx}, acc ->
          acc
          |> Multi.run({:auto_suppress, idx}, fn _repo, _changes -> {:ok, :matched} end)
          |> Events.append_multi(event_step_name(idx), fn _changes -> %{} end)
          |> Multi.run({:projector_categorize, idx}, fn _repo, _changes -> {:ok, :matched} end)
          |> Multi.run({:projector_apply, idx}, fn _repo, _changes -> {:ok, :matched} end)
        end)
      end
    end
    """

    issues = run_check(source)

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "MultiEventFirstInWebhookIngest")
    assert String.contains?(hd(issues).message, "suppression writes must stay after")
  end

  defp run_check(source) do
    source
    |> SourceFile.parse("lib/mailglass/webhook/ingest.ex")
    |> MultiEventFirstInWebhookIngest.run([])
  end
end
