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

    issues = run_check(source, "lib/mailglass/mailers/tracked_no_stream.ex")

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

    assert run_check(source, "lib/mailglass/mailers/tracked_bulk.ex") == []
  end

  test "does not flag a mailable with tracking disabled and no stream" do
    source = """
    defmodule Mailglass.Mailers.NoTracking do
      use Mailglass.Mailable, tracking: false
    end
    """

    assert run_check(source, "lib/mailglass/mailers/no_tracking.ex") == []
  end

  test "ignores files outside the production path scope (test fixtures may declare bad config)" do
    # A tracking-enabled mailable on :transactional is a deliberate test-fixture
    # shape (it exercises the runtime auth-stream guard). Linting test files would
    # be a false positive, so the check is path-scoped to production mailables.
    source = """
    defmodule Mailglass.Mailers.FixtureTrackedNoStream do
      use Mailglass.Mailable, stream: :transactional, tracking: [opens: true]
    end
    """

    assert run_check(source, "test/mailglass/core_send_integration_test.exs") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> StreamPolicyConsistent.run([])
  end
end
