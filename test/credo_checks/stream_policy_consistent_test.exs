defmodule Mailglass.Credo.LegacyStreamPolicyConsistentTest do
  use Credo.Test.Case

  alias Mailglass.Credo.StreamPolicyConsistent

  setup_all do
    Application.ensure_all_started(:credo)
    :ok
  end

  test "reports violation when tracking is enabled but stream is not set" do
    """
    defmodule MyMailer do
      use Mailglass.Mailable, tracking: [opens: true]
    end
    """
    |> to_source_file("lib/mailglass/legacy_tracked_no_stream.ex")
    |> run_check(StreamPolicyConsistent)
    |> assert_issue()
  end

  test "reports violation when tracking is enabled and stream is :transactional" do
    """
    defmodule MyMailer do
      use Mailglass.Mailable, stream: :transactional, tracking: true
    end
    """
    |> to_source_file("lib/mailglass/legacy_tracked_transactional.ex")
    |> run_check(StreamPolicyConsistent)
    |> assert_issue()
  end

  test "does not report violation when tracking is enabled and stream is :bulk" do
    """
    defmodule MyMailer do
      use Mailglass.Mailable, stream: :bulk, tracking: true
    end
    """
    |> to_source_file()
    |> run_check(StreamPolicyConsistent)
    |> refute_issues()
  end

  test "does not report violation when tracking is enabled and stream is :operational" do
    """
    defmodule MyMailer do
      use Mailglass.Mailable, stream: :operational, tracking: true
    end
    """
    |> to_source_file()
    |> run_check(StreamPolicyConsistent)
    |> refute_issues()
  end

  test "does not report violation when tracking is false" do
    """
    defmodule MyMailer do
      use Mailglass.Mailable, stream: :transactional, tracking: false
    end
    """
    |> to_source_file()
    |> run_check(StreamPolicyConsistent)
    |> refute_issues()
  end

  test "does not report violation when tracking is not set" do
    """
    defmodule MyMailer do
      use Mailglass.Mailable, stream: :transactional
    end
    """
    |> to_source_file()
    |> run_check(StreamPolicyConsistent)
    |> refute_issues()
  end
end
