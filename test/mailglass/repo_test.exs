defmodule Mailglass.RepoTest do
  use ExUnit.Case, async: false

  # CORE-04: `Mailglass.Repo.transact/1` delegates to the adopter-configured
  # Ecto.Repo resolved via `Application.get_env(:mailglass, :repo)`. Phase 1
  # lands only the facade (`transact/1` + `repo/0` resolver); the
  # SQLSTATE 45A01 immutability translation lands with the events ledger in
  # Phase 2.

  describe "transact/1 — :repo not configured" do
    setup do
      original = Application.get_env(:mailglass, :repo)
      Application.put_env(:mailglass, :repo, nil)
      on_exit(fn -> Application.put_env(:mailglass, :repo, original) end)
      :ok
    end

    test "raises ConfigError when :repo is not configured" do
      assert_raise Mailglass.ConfigError, fn ->
        Mailglass.Repo.transact(fn -> {:ok, :done} end)
      end
    end

    test "the raised ConfigError carries :missing type and :repo context" do
      err =
        try do
          Mailglass.Repo.transact(fn -> {:ok, :done} end)
        rescue
          e -> e
        end

      assert %Mailglass.ConfigError{type: :missing, context: %{key: :repo}} = err
    end
  end

  describe "transact/1 — :repo configured" do
    defmodule FakeRepo do
      @moduledoc false
      # Minimal in-memory stand-in for an Ecto.Repo. Phase 1 only exercises
      # the `transact/2` delegation contract; real transactions land in
      # Phase 2 against a live Postgres repo.
      def transact(fun, _opts) when is_function(fun, 0) do
        case fun.() do
          {:ok, _} = ok -> ok
          {:error, _} = err -> err
          other -> {:ok, other}
        end
      end
    end

    setup do
      original = Application.get_env(:mailglass, :repo)
      Application.put_env(:mailglass, :repo, __MODULE__.FakeRepo)
      on_exit(fn -> Application.put_env(:mailglass, :repo, original) end)
      :ok
    end

    test "delegates to the configured repo and returns its result" do
      assert {:ok, :done} = Mailglass.Repo.transact(fn -> {:ok, :done} end)
    end

    test "propagates {:error, reason} from the inner function" do
      assert {:error, :rolled_back} =
               Mailglass.Repo.transact(fn -> {:error, :rolled_back} end)
    end
  end

  # FACADE-01 (Phase 133): prefix injection tests.
  # All delegated read/write ops must inject prefix: Config.schema() via
  # Keyword.put_new. Explicit caller :prefix wins (put_new semantics).
  # Tests use a CapturingFakeRepo that records the opts it receives.
  describe "put_prefix injection — default Config.schema() injected into delegated ops" do
    defmodule CapturingFakeRepo do
      @moduledoc false
      # Records the opts each delegated op receives. Returns plausible
      # shapes so the facade doesn't crash on the return value.

      def insert(_struct_or_cs, opts) do
        send(self(), {:insert_opts, opts})
        {:ok, %{}}
      end

      def update(_changeset, opts) do
        send(self(), {:update_opts, opts})
        {:ok, %{}}
      end

      def delete(_struct_or_cs, opts) do
        send(self(), {:delete_opts, opts})
        {:ok, %{}}
      end

      def one(_queryable, opts) do
        send(self(), {:one_opts, opts})
        nil
      end

      def all(_queryable, opts) do
        send(self(), {:all_opts, opts})
        []
      end

      def delete_all(_queryable, opts) do
        send(self(), {:delete_all_opts, opts})
        {0, nil}
      end

      def get(_queryable, _id, opts) do
        send(self(), {:get_opts, opts})
        nil
      end

      def aggregate(_queryable, _agg, _field, opts) do
        send(self(), {:aggregate_opts, opts})
        nil
      end

      def transaction(_multi, opts) do
        send(self(), {:multi_opts, opts})
        {:ok, %{}}
      end

      def transact(_fun, opts) do
        send(self(), {:transact_opts, opts})
        {:ok, nil}
      end

      def query!(sql, _params) do
        send(self(), {:query_sql, sql})
        %{rows: []}
      end
    end

    setup do
      original = Application.get_env(:mailglass, :repo)
      Application.put_env(:mailglass, :repo, CapturingFakeRepo)
      on_exit(fn -> Application.put_env(:mailglass, :repo, original) end)

      # Reset the persistent_term cache so Config.schema/0 re-reads from env
      :persistent_term.erase({Mailglass.Config, :schema})
      # Set schema to "mailglass" for these tests
      Application.put_env(:mailglass, :schema, "mailglass")
      on_exit(fn ->
        Application.delete_env(:mailglass, :schema)
        :persistent_term.erase({Mailglass.Config, :schema})
      end)

      :ok
    end

    test "insert/2 injects prefix: Config.schema() when caller supplies none" do
      Mailglass.Repo.insert(%{}, [])
      assert_received {:insert_opts, opts}
      assert opts[:prefix] == "mailglass"
    end

    test "insert/2 preserves explicit caller :prefix over injected default" do
      Mailglass.Repo.insert(%{}, prefix: "custom")
      assert_received {:insert_opts, opts}
      assert opts[:prefix] == "custom"
    end

    test "update/2 injects prefix: Config.schema() when caller supplies none" do
      Mailglass.Repo.update(%Ecto.Changeset{}, [])
      assert_received {:update_opts, opts}
      assert opts[:prefix] == "mailglass"
    end

    test "update/2 preserves explicit caller :prefix" do
      Mailglass.Repo.update(%Ecto.Changeset{}, prefix: "custom")
      assert_received {:update_opts, opts}
      assert opts[:prefix] == "custom"
    end

    test "delete/2 injects prefix: Config.schema() when caller supplies none" do
      Mailglass.Repo.delete(%{}, [])
      assert_received {:delete_opts, opts}
      assert opts[:prefix] == "mailglass"
    end

    test "delete/2 preserves explicit caller :prefix" do
      Mailglass.Repo.delete(%{}, prefix: "custom")
      assert_received {:delete_opts, opts}
      assert opts[:prefix] == "custom"
    end

    test "one/2 injects prefix: Config.schema() when caller supplies none" do
      Mailglass.Repo.one(nil, [])
      assert_received {:one_opts, opts}
      assert opts[:prefix] == "mailglass"
    end

    test "one/2 preserves explicit caller :prefix" do
      Mailglass.Repo.one(nil, prefix: "custom")
      assert_received {:one_opts, opts}
      assert opts[:prefix] == "custom"
    end

    test "all/2 injects prefix: Config.schema() when caller supplies none" do
      Mailglass.Repo.all(nil, [])
      assert_received {:all_opts, opts}
      assert opts[:prefix] == "mailglass"
    end

    test "all/2 preserves explicit caller :prefix" do
      Mailglass.Repo.all(nil, prefix: "custom")
      assert_received {:all_opts, opts}
      assert opts[:prefix] == "custom"
    end

    test "delete_all/2 injects prefix: Config.schema() when caller supplies none" do
      Mailglass.Repo.delete_all(nil, [])
      assert_received {:delete_all_opts, opts}
      assert opts[:prefix] == "mailglass"
    end

    test "delete_all/2 preserves explicit caller :prefix" do
      Mailglass.Repo.delete_all(nil, prefix: "custom")
      assert_received {:delete_all_opts, opts}
      assert opts[:prefix] == "custom"
    end

    test "get/3 injects prefix: Config.schema() when caller supplies none" do
      Mailglass.Repo.get(nil, 1, [])
      assert_received {:get_opts, opts}
      assert opts[:prefix] == "mailglass"
    end

    test "get/3 preserves explicit caller :prefix" do
      Mailglass.Repo.get(nil, 1, prefix: "custom")
      assert_received {:get_opts, opts}
      assert opts[:prefix] == "custom"
    end

    test "aggregate/3 (3-arg form) injects prefix: Config.schema() via default opts" do
      Mailglass.Repo.aggregate(nil, :count, :id)
      assert_received {:aggregate_opts, opts}
      assert opts[:prefix] == "mailglass"
    end

    test "aggregate/4 (4-arg form) injects prefix when caller passes empty opts" do
      Mailglass.Repo.aggregate(nil, :count, :id, [])
      assert_received {:aggregate_opts, opts}
      assert opts[:prefix] == "mailglass"
    end

    test "aggregate/4 preserves explicit caller :prefix" do
      Mailglass.Repo.aggregate(nil, :count, :id, prefix: "custom")
      assert_received {:aggregate_opts, opts}
      assert opts[:prefix] == "custom"
    end

    test "transact/2 does NOT inject prefix (opts pass through unchanged)" do
      Mailglass.Repo.transact(fn -> {:ok, nil} end, [foo: :bar])
      assert_received {:transact_opts, opts}
      refute Keyword.has_key?(opts, :prefix)
      assert opts[:foo] == :bar
    end

    test "multi/2 does NOT inject prefix (opts pass through unchanged to executor)" do
      Mailglass.Repo.multi(Ecto.Multi.new(), [foo: :bar])
      assert_received {:multi_opts, opts}
      refute Keyword.has_key?(opts, :prefix)
      assert opts[:foo] == :bar
    end

    test "query!/2 does NOT inject prefix — raw SQL passthrough unchanged" do
      Mailglass.Repo.query!("SELECT 1", [])
      assert_received {:query_sql, sql}
      assert sql == "SELECT 1"
    end
  end

  describe "multi_opts/1 — per-step prefix injector for Multi builders" do
    setup do
      :persistent_term.erase({Mailglass.Config, :schema})
      Application.put_env(:mailglass, :schema, "mailglass")
      on_exit(fn ->
        Application.delete_env(:mailglass, :schema)
        :persistent_term.erase({Mailglass.Config, :schema})
      end)
      :ok
    end

    test "multi_opts/0 (zero-arg default) returns [prefix: Config.schema()]" do
      result = Mailglass.Repo.multi_opts()
      assert result[:prefix] == "mailglass"
    end

    test "multi_opts([]) returns [prefix: Config.schema()]" do
      result = Mailglass.Repo.multi_opts([])
      assert result[:prefix] == "mailglass"
    end

    test "multi_opts(prefix: 'x') preserves explicit :prefix" do
      result = Mailglass.Repo.multi_opts(prefix: "x")
      assert result[:prefix] == "x"
    end

    test "multi_opts/1 is a public function (not private)" do
      # If it were private, calling it would fail at the callsite;
      # we just assert it's exported by verifying it's accessible.
      assert function_exported?(Mailglass.Repo, :multi_opts, 0)
      assert function_exported?(Mailglass.Repo, :multi_opts, 1)
    end
  end
end
