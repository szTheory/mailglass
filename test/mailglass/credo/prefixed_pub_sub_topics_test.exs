defmodule Mailglass.Credo.PrefixedPubSubTopicsTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.PrefixedPubSubTopics

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags broadcast topic without mailglass prefix" do
    source = """
    defmodule Demo do
      def run(pubsub) do
        Phoenix.PubSub.broadcast(pubsub, "events:tenant-1", :ok)
      end
    end
    """

    issues = run_check(source)

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "mailglass:")
  end

  test "flags subscribe topic without mailglass prefix" do
    source = """
    defmodule Demo do
      def run(pubsub) do
        Phoenix.PubSub.subscribe(pubsub, "tenant:updates")
      end
    end
    """

    issues = run_check(source)

    assert length(issues) == 1
  end

  test "does not flag prefixed or dynamic topics" do
    source = """
    defmodule Demo do
      def good(pubsub) do
        Phoenix.PubSub.broadcast!(pubsub, "mailglass:events:tenant-1", :ok)
      end

      def dynamic(pubsub, topic) do
        Phoenix.PubSub.subscribe(pubsub, topic)
      end
    end
    """

    assert run_check(source) == []
  end

  defp run_check(source) do
    source
    |> SourceFile.parse("test/mailglass/credo/prefixed_pub_sub_topics_fixture.ex")
    |> PrefixedPubSubTopics.run([])
  end
end
