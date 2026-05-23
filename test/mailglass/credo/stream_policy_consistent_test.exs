defmodule Mailglass.Credo.StreamPolicyConsistentTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.StreamPolicyConsistent

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags a tracking-enabled mailable with no explicit stream" do
    source = """
    defmodule Mailglass.Mailers.TrackedNoStream do
      use Mailglass.Mailable, tracking: true
    end
    """

    issues = run_check(source)

    assert length(issues) == 1
    message = hd(issues).message
    assert String.contains?(message, ":bulk") or String.contains?(message, ":operational")
  end

  test "does not flag tracking paired with an explicit :bulk stream" do
    source = """
    defmodule Mailglass.Mailers.TrackedBulk do
      use Mailglass.Mailable, tracking: true, stream: :bulk
    end
    """

    assert run_check(source) == []
  end

  test "does not flag a mailable with tracking disabled and no stream" do
    source = """
    defmodule Mailglass.Mailers.NoTracking do
      use Mailglass.Mailable, tracking: false
    end
    """

    assert run_check(source) == []
  end

  defp run_check(source) do
    source
    |> SourceFile.parse("test/mailglass/credo/stream_policy_consistent_fixture.ex")
    |> StreamPolicyConsistent.run([])
  end
end
