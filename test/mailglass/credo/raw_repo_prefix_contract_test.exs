defmodule Mailglass.Credo.RawRepoPrefixContractTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.RawRepoPrefixContract

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags raw callback update touching a mailglass projection without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadProjection do
      alias Mailglass.Outbound.Projector

      def apply(repo, delivery, event) do
        changeset = Projector.update_projections(delivery, event)
        repo.update(changeset)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_projection.ex")

    assert length(issues) == 1
    assert hd(issues).message =~ "explicit schema prefix opts"
  end

  test "flags raw callback read touching a mailglass table without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadRead do
      import Ecto.Query
      alias Mailglass.Events.Event

      def fetch(repo, delivery) do
        query = from(event in Event, where: event.delivery_id == ^delivery.id, limit: 1)
        repo.one(query)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_read.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "flags raw callback calls when the repo variable has a different name" do
    source = """
    defmodule Mailglass.Webhook.BadProjectionWithNamedRepo do
      alias Mailglass.Outbound.Projector

      def apply(db, delivery, event) do
        changeset = Projector.update_projections(delivery, event)
        db.update(changeset)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_projection_with_named_repo.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "db.update"
  end

  test "flags projection Multi update without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadMultiProjection do
      alias Ecto.Multi
      alias Mailglass.Events
      alias Mailglass.Outbound.Projector

      def build(delivery, event_attrs) do
        Multi.new()
        |> Events.append_multi(:event, event_attrs)
        |> Multi.update(:projection, fn %{event: event} ->
          Projector.update_projections(delivery, event)
        end)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_multi_projection.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "Multi.update"
  end

  test "flags raw repo table access through common Ecto APIs without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadRepoApis do
      import Ecto.Query
      alias Mailglass.Events.Event

      def count(repo), do: repo.aggregate(from(event in Event), :count)
      def update_all(repo), do: repo.update_all(from(event in Event), set: [metadata: %{}])
      def insert_all(repo, rows), do: repo.insert_all(Event, rows)
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_repo_apis.ex")

    assert length(issues) == 3

    assert Enum.map(issues, & &1.trigger) == [
             "repo.aggregate",
             "repo.update_all",
             "repo.insert_all"
           ]
  end

  test "flags projection Multi insert without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadMultiInsert do
      alias Ecto.Multi
      alias Mailglass.Events.Event

      def build(attrs) do
        changeset = Event.changeset(%Event{}, attrs)

        Multi.new()
        |> Multi.insert(:event, changeset)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_multi_insert.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "Multi.insert"
  end

  test "allows raw callback update with Repo.multi_opts" do
    source = """
    defmodule Mailglass.Webhook.GoodProjection do
      alias Mailglass.Outbound.Projector
      alias Mailglass.Repo

      def apply(repo, delivery, event) do
        changeset = Projector.update_projections(delivery, event)
        repo.update(changeset, Repo.multi_opts())
      end
    end
    """

    assert run_check(source, "lib/mailglass/webhook/good_projection.ex") == []
  end

  test "allows raw callback update with fully qualified Mailglass.Repo.multi_opts" do
    source = """
    defmodule Mailglass.Webhook.GoodProjectionFullyQualified do
      alias Mailglass.Outbound.Projector

      def apply(repo, delivery, event) do
        changeset = Projector.update_projections(delivery, event)
        repo.update(changeset, Mailglass.Repo.multi_opts())
      end
    end
    """

    assert run_check(source, "lib/mailglass/webhook/good_projection_fully_qualified.ex") == []
  end

  test "rejects literal prefix opts that are not configured schema prefixes" do
    source = """
    defmodule Mailglass.Webhook.BadLiteralPrefixRead do
      import Ecto.Query
      alias Mailglass.Events.Event

      def nil_prefix(repo), do: repo.one(from(event in Event), prefix: nil)
      def public_prefix(repo), do: repo.one(from(event in Event), prefix: "public")
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_literal_prefix_read.ex")

    assert length(issues) == 2
    assert Enum.map(issues, & &1.trigger) == ["repo.one", "repo.one"]
  end

  test "allows configured prefix through Mailglass.Config alias" do
    source = """
    defmodule Mailglass.Webhook.GoodConfigAliasPrefixRead do
      import Ecto.Query
      alias Mailglass.Config
      alias Mailglass.Events.Event

      def fetch(repo), do: repo.one(from(event in Event), prefix: Config.schema())
    end
    """

    assert run_check(source, "lib/mailglass/webhook/good_config_alias_prefix_read.ex") == []
  end

  test "rejects prefix helper names that do not return prefix opts" do
    source = """
    defmodule MailglassInbound.Internal.BadReplayRead do
      import Ecto.Query
      alias MailglassInbound.InboundRecords.InboundRecord

      def load(repo, id) do
        query = from(record in InboundRecord, where: record.id == ^id, limit: 1)
        repo.one(query, schema_opts())
      end

      defp schema_opts, do: []
    end
    """

    issues =
      run_check(source, "mailglass_inbound/lib/mailglass_inbound/internal/bad_replay_read.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "rejects helpers that discard configured prefix before returning opts" do
    source = """
    defmodule MailglassInbound.Internal.BadDiscardedPrefixHelper do
      import Ecto.Query
      alias MailglassInbound.InboundRecords.InboundRecord

      def load(repo, id) do
        query = from(record in InboundRecord, where: record.id == ^id, limit: 1)
        repo.one(query, schema_opts())
      end

      defp schema_opts do
        _ = [prefix: MailglassInbound.Config.schema()]
        []
      end
    end
    """

    issues =
      run_check(
        source,
        "mailglass_inbound/lib/mailglass_inbound/internal/bad_discarded_prefix_helper.ex"
      )

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "rejects multi_opts calls from non-Mailglass repos" do
    source = """
    defmodule Mailglass.Webhook.BadProjectionWrongRepo do
      alias Mailglass.Outbound.Projector

      def apply(repo, delivery, event) do
        changeset = Projector.update_projections(delivery, event)
        repo.update(changeset, Other.Repo.multi_opts())
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_projection_wrong_repo.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.update"
  end

  test "allows projection Multi update with Repo.multi_opts" do
    source = """
    defmodule Mailglass.Webhook.GoodMultiProjection do
      alias Ecto.Multi
      alias Mailglass.Events
      alias Mailglass.Outbound.Projector
      alias Mailglass.Repo

      def build(delivery, event_attrs) do
        Multi.new()
        |> Events.append_multi(:event, event_attrs)
        |> Multi.update(
          :projection,
          fn %{event: event} ->
            Projector.update_projections(delivery, event)
          end,
          Repo.multi_opts()
        )
      end
    end
    """

    assert run_check(source, "lib/mailglass/webhook/good_multi_projection.ex") == []
  end

  test "allows inbound raw repo read with local schema_opts" do
    source = """
    defmodule MailglassInbound.Internal.GoodReplayRead do
      import Ecto.Query
      alias MailglassInbound.InboundRecords.InboundRecord

      def load(repo, id) do
        query = from(record in InboundRecord, where: record.id == ^id, limit: 1)
        repo.one(query, schema_opts())
      end

      defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]
    end
    """

    assert run_check(source, "mailglass_inbound/lib/mailglass_inbound/internal/good_replay_read.ex") ==
             []
  end

  test "allows prefixed zero arity helper when another arity is unprefixed" do
    source = """
    defmodule MailglassInbound.Internal.GoodReplayReadWithOverload do
      import Ecto.Query
      alias MailglassInbound.InboundRecords.InboundRecord

      def load(repo, id) do
        query = from(record in InboundRecord, where: record.id == ^id, limit: 1)
        repo.one(query, schema_opts())
      end

      defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]
      defp schema_opts(:raw), do: []
    end
    """

    assert run_check(
             source,
             "mailglass_inbound/lib/mailglass_inbound/internal/good_replay_read_with_overload.ex"
           ) == []
  end

  test "flags schema values introduced by function head patterns" do
    source = """
    defmodule Mailglass.Webhook.BadHeadTaint do
      alias Mailglass.Events.Event

      def delete(repo, %Event{} = event), do: repo.delete(event)
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_head_taint.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.delete"
  end

  test "propagates taint through assigned aliases" do
    source = """
    defmodule Mailglass.Webhook.BadAliasTaint do
      import Ecto.Query
      alias Mailglass.Events.Event

      def fetch(repo) do
        query = from(event in Event, limit: 1)
        alias_query = query
        repo.one(alias_query)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_alias_taint.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "allows facade-routed repo calls" do
    source = """
    defmodule Mailglass.Webhook.FacadeRead do
      import Ecto.Query
      alias Mailglass.Outbound.Delivery

      def load(id) do
        Mailglass.Repo.one(from(delivery in Delivery, where: delivery.id == ^id))
      end
    end
    """

    assert run_check(source, "lib/mailglass/webhook/facade_read.ex") == []
  end

  test "ignores files outside configured production path prefixes" do
    source = """
    defmodule Mailglass.TestFixture.BadRawRepo do
      import Ecto.Query
      alias Mailglass.Events.Event

      def fetch(repo) do
        repo.one(from(event in Event, limit: 1))
      end
    end
    """

    assert run_check(source, "test/support/raw_repo_prefix_fixture.exs") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> RawRepoPrefixContract.run([])
  end
end
