defmodule MailglassAdmin.Operator.FilterCommitTest do
  use ExUnit.Case, async: true

  alias MailglassAdmin.Operator.FilterCommit

  @moduletag :phase176

  describe "history_kind/2" do
    test "Phase 176 search pushes the first commit of an edit and replaces later ones" do
      assert FilterCommit.history_kind(:search, :search) == :replace

      for last <- [nil, :select, :enter, :clear, :page] do
        assert FilterCommit.history_kind(:search, last) == :push,
               "a search commit after #{inspect(last)} starts a new history entry"
      end
    end

    test "Phase 176 Enter replaces only when it finalizes an in-flight search edit" do
      assert FilterCommit.history_kind(:enter, :search) == :replace
      assert FilterCommit.history_kind(:enter, nil) == :push
      assert FilterCommit.history_kind(:enter, :select) == :push
    end

    test "Phase 176 select, clear and page always push" do
      for kind <- [:select, :clear, :page],
          last <- [nil, :search, :select, :enter, :clear, :page, :recover, :canonicalize] do
        assert FilterCommit.history_kind(kind, last) == :push,
               "#{kind} after #{inspect(last)} must push"
      end
    end

    test "Phase 176 recover and canonicalize always replace" do
      for kind <- [:recover, :canonicalize],
          last <- [nil, :search, :select, :enter, :clear, :page, :recover, :canonicalize] do
        assert FilterCommit.history_kind(kind, last) == :replace,
               "#{kind} after #{inspect(last)} must replace"
      end
    end
  end

  describe "kind_for_target/1" do
    test "Phase 176 only the Search input commits as :search" do
      assert FilterCommit.kind_for_target(["filters", "search"]) == :search
      assert FilterCommit.kind_for_target(["filters", "event"]) == :select
      assert FilterCommit.kind_for_target(["filters", "window_hours"]) == :select
      assert FilterCommit.kind_for_target(nil) == :select
      assert FilterCommit.kind_for_target([]) == :select
    end
  end

  describe "commit_params/2" do
    test "Phase 176 the server-held Account overrides any payload tenant" do
      params =
        FilterCommit.commit_params(%{"tenant_id" => "foreign", "event" => "failed"}, "mine")

      assert params["tenant_id"] == "mine"
      assert params["event"] == "failed"

      assert FilterCommit.commit_params(%{"tenant_id" => "foreign"}, nil)["tenant_id"] == ""
      assert FilterCommit.commit_params(%{}, "mine")["tenant_id"] == "mine"
    end

    test "Phase 176 search is trimmed at commit time" do
      assert FilterCommit.commit_params(%{"search" => "foo "}, "t")["search"] == "foo"
      assert FilterCommit.commit_params(%{"search" => "  foo"}, "t")["search"] == "foo"
      assert FilterCommit.commit_params(%{"search" => "   "}, "t")["search"] == ""
    end

    test "Phase 176 page and selection keys are dropped" do
      params =
        FilterCommit.commit_params(
          %{
            "page" => "3",
            "delivery_id" => "d",
            "inbound_id" => "i",
            "full" => "1",
            "event" => "failed"
          },
          "t"
        )

      for key <- ["page", "delivery_id", "inbound_id", "full"] do
        refute Map.has_key?(params, key)
      end

      assert params["event"] == "failed"
    end

    test "Phase 176 a 500-character search survives a commit and its query round trip" do
      long = String.duplicate("a", 500)
      params = FilterCommit.commit_params(%{"search" => long}, "t")
      assert params["search"] == long

      assert params
             |> FilterCommit.encode_query()
             |> URI.decode_query()
             |> Map.fetch!("search") == long
    end
  end

  describe "encode_query/1" do
    test "Phase 176 drops blanks and page=1 but keeps window_hours=168" do
      query =
        FilterCommit.encode_query(%{
          "tenant_id" => "t",
          "event" => "",
          "provider" => nil,
          "page" => "1",
          "window_hours" => "168"
        })

      assert URI.decode_query(query) == %{"tenant_id" => "t", "window_hours" => "168"}
    end

    test "Phase 176 keeps page values above 1" do
      assert FilterCommit.encode_query(%{"page" => "2"}) == "page=2"
    end

    test "Phase 176 payload key order never changes the encoded query" do
      a = [{"window_hours", "168"}, {"event", "failed"}, {"tenant_id", "t"}]
      b = [{"tenant_id", "t"}, {"event", "failed"}, {"window_hours", "168"}]

      assert FilterCommit.encode_query(a) == FilterCommit.encode_query(b)
      assert FilterCommit.encode_query(a) == "event=failed&tenant_id=t&window_hours=168"
      assert FilterCommit.encode_query(Map.new(a)) == FilterCommit.encode_query(a)
    end
  end

  describe "canonical_current_query/1" do
    test "Phase 176 fills window_hours=168 when absent or blank" do
      assert FilterCommit.canonical_current_query(%{"tenant_id" => "t"}) ==
               "tenant_id=t&window_hours=168"

      assert FilterCommit.canonical_current_query(%{"tenant_id" => "t", "window_hours" => ""}) ==
               "tenant_id=t&window_hours=168"
    end

    test "Phase 176 keeps a chosen window and every other location key" do
      query =
        %{
          "tenant_id" => "t",
          "window_hours" => "720",
          "page" => "2",
          "delivery_id" => "d",
          "support_focus" => "failed_ingest"
        }
        |> FilterCommit.canonical_current_query()
        |> URI.decode_query()

      assert query == %{
               "tenant_id" => "t",
               "window_hours" => "720",
               "page" => "2",
               "delivery_id" => "d",
               "support_focus" => "failed_ingest"
             }
    end

    test "Phase 176 drops page=1 so leaving page 1 is not a location change" do
      refute %{"tenant_id" => "t", "page" => "1"}
             |> FilterCommit.canonical_current_query()
             |> URI.decode_query()
             |> Map.has_key?("page")
    end
  end
end
