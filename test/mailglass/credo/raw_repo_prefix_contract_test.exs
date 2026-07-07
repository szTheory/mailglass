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

  test "flags raw repo alias touching a mailglass schema without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadRepoAliasRead do
      import Ecto.Query
      alias Mailglass.Events.Event
      alias MyApp.Repo

      def fetch do
        Repo.one(from(event in Event, limit: 1))
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_repo_alias_read.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "Repo.one"
  end

  test "flags raw repo read through local query helper return without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadQueryFunctionReturn do
      import Ecto.Query
      alias Mailglass.Events.Event

      def fetch(repo), do: repo.one(event_query())

      defp event_query, do: from(event in Event, limit: 1)
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_query_function_return.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "flags assigned local query helper return without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadAssignedQueryFunctionReturn do
      import Ecto.Query
      alias Mailglass.Events.Event

      def fetch(repo) do
        query = event_query()
        repo.one(query)
      end

      defp event_query, do: from(event in Event, limit: 1)
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_assigned_query_function_return.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "flags same-module remote query helper return without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadRemoteModuleHelperReturn do
      import Ecto.Query
      alias Mailglass.Events.Event

      def fetch(repo), do: repo.one(__MODULE__.event_query())

      def event_query, do: from(event in Event, limit: 1)
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_remote_module_helper_return.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "flags literal same-module query helper return without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadLiteralModuleHelperReturn do
      import Ecto.Query
      alias Mailglass.Events.Event

      def fetch(repo) do
        repo.one(Mailglass.Webhook.BadLiteralModuleHelperReturn.event_query())
      end

      def event_query, do: from(event in Event, limit: 1)
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_literal_module_helper_return.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "flags same-module alias query helper return without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadAliasModuleHelperReturn do
      import Ecto.Query
      alias Mailglass.Events.Event
      alias Mailglass.Webhook.BadAliasModuleHelperReturn, as: ThisModule

      def fetch(repo), do: repo.one(ThisModule.event_query())

      def event_query, do: from(event in Event, limit: 1)
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_alias_module_helper_return.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "flags transitive same-module alias query helper return without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadTransitiveModuleAliasHelperReturn do
      import Ecto.Query
      alias Mailglass.Events.Event
      alias Mailglass.Webhook.BadTransitiveModuleAliasHelperReturn, as: ThisModule
      alias ThisModule, as: Here

      def fetch(repo), do: repo.one(Here.event_query())

      def event_query, do: from(event in Event, limit: 1)
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_transitive_module_alias_helper_return.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "flags renamed core schema alias without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadAliasAsRead do
      import Ecto.Query
      alias Mailglass.Events.Event, as: MailEvent

      def fetch(repo), do: repo.one(from(event in MailEvent, limit: 1))
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_alias_as_read.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "flags schema alias defined through prior alias without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadAliasViaAliasRead do
      import Ecto.Query
      alias Mailglass.Events
      alias Events.Event, as: Ev

      def fetch(repo), do: repo.one(from(event in Ev, limit: 1))
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_alias_via_alias_read.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "allows unrelated schema with same tail alias" do
    source = """
    defmodule Mailglass.Webhook.UnrelatedEventRead do
      import Ecto.Query
      alias Other.Event

      def fetch(repo), do: repo.one(from(event in Event, limit: 1))
    end
    """

    assert run_check(source, "lib/mailglass/webhook/unrelated_event_read.ex") == []
  end

  test "flags wrong prefix helper when another same-file module has matching helper name" do
    source = """
    defmodule MailglassInbound.Internal.GoodInboundPrefixHelper do
      defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]
    end

    defmodule MailglassInbound.Internal.BadWrongPrefixHelper do
      import Ecto.Query
      alias MailglassInbound.InboundRecords.InboundRecord

      def fetch(repo) do
        repo.one(from(record in InboundRecord, limit: 1), schema_opts())
      end

      defp schema_opts, do: [prefix: Mailglass.Config.schema()]
    end
    """

    issues =
      run_check(
        source,
        "mailglass_inbound/lib/mailglass_inbound/internal/bad_wrong_prefix_helper.ex"
      )

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "flags variant prefix helper clause that returns the wrong owner" do
    source = """
    defmodule MailglassInbound.Internal.BadLiteralHelperArgBypass do
      import Ecto.Query
      alias MailglassInbound.InboundRecords.InboundRecord

      def fetch(repo) do
        repo.one(from(record in InboundRecord, limit: 1), schema_opts(:core))
      end

      defp schema_opts(:core), do: [prefix: Mailglass.Config.schema()]
      defp schema_opts(:inbound), do: [prefix: MailglassInbound.Config.schema()]
    end
    """

    issues =
      run_check(
        source,
        "mailglass_inbound/lib/mailglass_inbound/internal/bad_literal_helper_arg_bypass.ex"
      )

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "does not leak schema aliases between same-file modules" do
    source = """
    defmodule Mailglass.Webhook.MailglassEventAliasHolder do
      alias Mailglass.Events.Event

      def unused, do: Event
    end

    defmodule Mailglass.Webhook.UnrelatedEventSameFileRead do
      import Ecto.Query
      alias Other.Event

      def fetch(repo), do: repo.one(from(event in Event, limit: 1))
    end
    """

    assert run_check(source, "lib/mailglass/webhook/unrelated_event_same_file_read.ex") == []
  end

  test "flags renamed inbound schema alias without prefix opts" do
    source = """
    defmodule MailglassInbound.Internal.BadInboundAliasAsRead do
      import Ecto.Query
      alias MailglassInbound.InboundRecords.InboundRecord, as: Record

      def fetch(repo), do: repo.one(from(record in Record, limit: 1))
    end
    """

    issues =
      run_check(
        source,
        "mailglass_inbound/lib/mailglass_inbound/internal/bad_inbound_alias_as_read.ex"
      )

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "flags module attribute schema without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadModuleAttributeSchemaRead do
      import Ecto.Query

      @event_schema Mailglass.Events.Event

      def fetch(repo), do: repo.one(from(event in @event_schema, limit: 1))
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_module_attribute_schema_read.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
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

  test "flags aliased Multi insert without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadMultiAliasInsert do
      alias Ecto.Multi, as: EMulti
      alias Mailglass.Events.Event

      def build(attrs) do
        changeset = Event.changeset(%Event{}, attrs)

        EMulti.new()
        |> EMulti.insert(:event, changeset)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_multi_alias_insert.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "EMulti.insert"
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

  test "allows Mailglass.Repo facade alias reads" do
    source = """
    defmodule Mailglass.Webhook.GoodFacadeAliasRead do
      import Ecto.Query
      alias Mailglass.Events.Event
      alias Mailglass.Repo

      def fetch do
        Repo.one(from(event in Event, limit: 1))
      end
    end
    """

    assert run_check(source, "lib/mailglass/webhook/good_facade_alias_read.ex") == []
  end

  test "allows MailglassInbound.Repo facade alias reads" do
    source = """
    defmodule MailglassInbound.Internal.GoodInboundFacadeAliasRead do
      import Ecto.Query
      alias MailglassInbound.InboundRecords.InboundRecord
      alias MailglassInbound.Repo

      def fetch do
        Repo.one(from(record in InboundRecord, limit: 1))
      end
    end
    """

    assert run_check(
             source,
             "mailglass_inbound/lib/mailglass_inbound/internal/good_inbound_facade_alias_read.ex"
           ) == []
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

  test "allows helper that returns Repo.multi_opts" do
    source = """
    defmodule Mailglass.Webhook.GoodRepoMultiOptsHelper do
      import Ecto.Query
      alias Mailglass.Events.Event
      alias Mailglass.Repo

      def fetch(repo) do
        query = from(event in Event, limit: 1)
        repo.one(query, schema_opts())
      end

      defp schema_opts, do: Repo.multi_opts()
    end
    """

    assert run_check(source, "lib/mailglass/webhook/good_repo_multi_opts_helper.ex") == []
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

  test "flags schema values introduced by body pattern matches" do
    source = """
    defmodule Mailglass.Webhook.BadBodyPatternTaint do
      alias Mailglass.Events.Event

      def delete(repo, raw) do
        %Event{} = event = raw
        repo.delete(event)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_body_pattern_taint.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.delete"
  end

  test "flags schema values introduced by with pattern matches" do
    source = """
    defmodule Mailglass.Webhook.BadWithPatternTaint do
      alias Mailglass.Events.Event

      def delete(repo, fetcher) do
        with %Event{} = event <- fetcher.() do
          repo.delete(event)
        end
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_with_pattern_taint.ex")

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

  test "deletes prefix option trust after unsafe rebinding" do
    source = """
    defmodule Mailglass.Webhook.BadOptsRebind do
      import Ecto.Query
      alias Mailglass.Events.Event
      alias Mailglass.Repo

      def fetch(repo) do
        query = from(event in Event, limit: 1)
        opts = Repo.multi_opts()
        opts = []
        repo.one(query, opts)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_opts_rebind.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "propagates trusted prefix option variables" do
    source = """
    defmodule Mailglass.Webhook.GoodOptsAlias do
      import Ecto.Query
      alias Mailglass.Events.Event
      alias Mailglass.Repo

      def fetch(repo) do
        query = from(event in Event, limit: 1)
        opts = Repo.multi_opts()
        alias_opts = opts
        repo.one(query, alias_opts)
      end
    end
    """

    assert run_check(source, "lib/mailglass/webhook/good_opts_alias.ex") == []
  end

  test "flags earlier schema query before later non-schema rebind" do
    source = """
    defmodule Mailglass.Webhook.BadQueryRebindAfterCall do
      import Ecto.Query
      alias Mailglass.Events.Event

      def fetch(repo) do
        query = from(event in Event, limit: 1)
        repo.one(query)
        query = from(other in Other.Schema, limit: 1)
        query
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_query_rebind_after_call.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "flags earlier unsafe opts before later trusted opts rebind" do
    source = """
    defmodule Mailglass.Webhook.BadOptsTrustedAfterCall do
      import Ecto.Query
      alias Mailglass.Events.Event
      alias Mailglass.Repo

      def fetch(repo) do
        query = from(event in Event, limit: 1)
        opts = []
        repo.one(query, opts)
        opts = Repo.multi_opts()
        opts
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_opts_trusted_after_call.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "rejects inbound config prefix for core schema reads" do
    source = """
    defmodule Mailglass.Webhook.BadInboundPrefixForCoreRead do
      import Ecto.Query
      alias Mailglass.Events.Event

      def fetch(repo) do
        repo.one(from(event in Event, limit: 1), prefix: MailglassInbound.Config.schema())
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_inbound_prefix_for_core_read.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "rejects Repo.multi_opts with inbound prefix override for core schema reads" do
    source = """
    defmodule Mailglass.Webhook.BadInboundMultiOptsPrefixForCoreRead do
      import Ecto.Query
      alias Mailglass.Events.Event
      alias Mailglass.Repo

      def fetch(repo) do
        repo.one(
          from(event in Event, limit: 1),
          Repo.multi_opts(prefix: MailglassInbound.Config.schema())
        )
      end
    end
    """

    issues =
      run_check(source, "lib/mailglass/webhook/bad_inbound_multi_opts_prefix_for_core_read.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "rejects Repo.multi_opts with literal prefix override for core schema reads" do
    source = """
    defmodule Mailglass.Webhook.BadLiteralMultiOptsPrefixForCoreRead do
      import Ecto.Query
      alias Mailglass.Events.Event
      alias Mailglass.Repo

      def fetch(repo) do
        repo.one(from(event in Event, limit: 1), Repo.multi_opts(prefix: "public"))
      end
    end
    """

    issues =
      run_check(source, "lib/mailglass/webhook/bad_literal_multi_opts_prefix_for_core_read.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "rejects core config prefix for inbound schema reads" do
    source = """
    defmodule MailglassInbound.Internal.BadCorePrefixForInboundRead do
      import Ecto.Query
      alias MailglassInbound.InboundRecords.InboundRecord

      def fetch(repo) do
        repo.one(from(record in InboundRecord, limit: 1), prefix: Mailglass.Config.schema())
      end
    end
    """

    issues =
      run_check(
        source,
        "mailglass_inbound/lib/mailglass_inbound/internal/bad_core_prefix_for_inbound_read.ex"
      )

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "rejects Repo.multi_opts with core prefix override for inbound schema reads" do
    source = """
    defmodule MailglassInbound.Internal.BadCoreMultiOptsPrefixForInboundRead do
      import Ecto.Query
      alias Mailglass.Repo
      alias MailglassInbound.InboundRecords.InboundRecord

      def fetch(repo) do
        repo.one(
          from(record in InboundRecord, limit: 1),
          Repo.multi_opts(prefix: Mailglass.Config.schema())
        )
      end
    end
    """

    issues =
      run_check(
        source,
        "mailglass_inbound/lib/mailglass_inbound/internal/bad_core_multi_opts_prefix_for_inbound_read.ex"
      )

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "does not leak trusted opts binding out of anonymous function scope" do
    source = """
    defmodule Mailglass.Webhook.BadFnScopeOptsLeak do
      import Ecto.Query
      alias Mailglass.Events.Event
      alias Mailglass.Repo

      def fetch(repo) do
        query = from(event in Event, limit: 1)
        opts = []

        _ =
          fn ->
            opts = Repo.multi_opts()
            opts
          end

        repo.one(query, opts)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_fn_scope_opts_leak.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "flags string table query source without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadStringSourceRead do
      import Ecto.Query

      def fetch(repo) do
        repo.one(from(event in "mailglass_events", limit: 1))
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_string_source_read.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.one"
  end

  test "flags raw insert_all string table source without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadStringSourceInsertAll do
      def insert(repo, rows) do
        repo.insert_all("mailglass_events", rows)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_string_source_insert_all.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "repo.insert_all"
  end

  test "flags Multi insert_all string table source without prefix opts" do
    source = """
    defmodule Mailglass.Webhook.BadStringSourceMultiInsertAll do
      def build(rows) do
        Ecto.Multi.new()
        |> Ecto.Multi.insert_all(:events, "mailglass_events", rows)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_string_source_multi_insert_all.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "Ecto.Multi.insert_all"
  end

  test "allows string table sources with matching prefix opts" do
    source = """
    defmodule Mailglass.Webhook.GoodStringSources do
      import Ecto.Query
      alias Mailglass.Repo

      def fetch(repo) do
        repo.one(from(event in "mailglass_events", limit: 1), prefix: Mailglass.Config.schema())
      end

      def insert(repo, rows) do
        repo.insert_all("mailglass_events", rows, Repo.multi_opts())
      end

      def build(rows) do
        Ecto.Multi.new()
        |> Ecto.Multi.insert_all(:events, "mailglass_events", rows, Repo.multi_opts())
      end
    end
    """

    assert run_check(source, "lib/mailglass/webhook/good_string_sources.ex") == []
  end

  test "allows Repo.multi_opts from grouped Mailglass alias" do
    source = """
    defmodule Mailglass.Webhook.GoodGroupedAliasOpts do
      import Ecto.Query
      alias Mailglass.{Events, Repo}

      def fetch(repo) do
        query = from(event in Events.Event, limit: 1)
        repo.one(query, Repo.multi_opts())
      end
    end
    """

    assert run_check(source, "lib/mailglass/webhook/good_grouped_alias_opts.ex") == []
  end

  test "allows piped Multi insert_all with grouped alias Repo.multi_opts" do
    source = """
    defmodule Mailglass.Webhook.GoodGroupedAliasMultiInsertAll do
      alias Mailglass.{Events, Repo}

      def build(rows) do
        Ecto.Multi.new()
        |> Ecto.Multi.insert_all(:events, Events.Event, rows, Repo.multi_opts(on_conflict: :nothing))
      end
    end
    """

    assert run_check(source, "lib/mailglass/webhook/good_grouped_alias_multi_insert_all.ex") == []
  end

  test "allows piped Multi insert_all with multiline grouped Mailglass alias" do
    source = """
    defmodule Mailglass.Outbound.GoodMultilineGroupedAliasMultiInsertAll do
      alias Mailglass.{
        Config,
        Events,
        Repo
      }

      alias Mailglass.Outbound.Delivery

      def build(rows) do
        Ecto.Multi.new()
        |> Ecto.Multi.insert_all(
          :deliveries,
          Delivery,
          rows,
          Repo.multi_opts(
            on_conflict: :nothing,
            returning: true
          )
        )
      end
    end
    """

    assert run_check(
             source,
             "lib/mailglass/outbound/good_multiline_grouped_alias_multi_insert_all.ex"
           ) == []
  end

  test "allows piped Multi insert_all when later function body queries same schema" do
    source = """
    defmodule Mailglass.Outbound.GoodMultiInsertAllWithLaterQuery do
      import Ecto.Query

      alias Mailglass.{
        Message,
        Repo
      }

      alias Mailglass.Outbound.Delivery

      def build(messages_with_refs) do
        rows =
          Enum.map(messages_with_refs, fn {%Message{} = message, adapter_ref} ->
            %{id: adapter_ref, message: message}
          end)

        result =
          Ecto.Multi.new()
          |> Ecto.Multi.insert_all(
            :deliveries,
            Delivery,
            rows,
            Repo.multi_opts(on_conflict: :nothing, returning: true)
          )

        case result do
          {:ok, _} ->
            query = from(delivery in Delivery, where: delivery.id in ^Enum.map(rows, & &1.id))
            Repo.all(query)
        end
      end
    end
    """

    assert run_check(source, "lib/mailglass/outbound/good_multi_insert_all_with_later_query.ex") ==
             []
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
