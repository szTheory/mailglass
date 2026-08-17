defmodule MailglassInbound.RepoPrefixTest do
  @moduledoc """
  Schema-isolation assertions for the MailglassInbound.Repo facade (INB-01) and
  the prune batched DELETE (D-02 load-bearing fix).

  Three deterministic checks that no facade-only smoke test covers:

    (A) Facade default — `Repo.insert/2` / `all/2` / `one/2` / `get/3` with no
        explicit `:prefix` inject `prefix: Config.schema()`.

    (A) Explicit-prefix precedence — a caller-supplied `prefix: "override"` is
        preserved by `Keyword.put_new` semantics.

    (B) Prune DELETE schema target (D-02) — `delete_batched/3` DELETEs against
        the configured schema, not a hardcoded `"public"`. Fails RED if the
        `prefix: MailglassInbound.Config.schema()` in `prune.ex` is removed: the
        DELETE would then fall back to Postgres's default resolution (usually
        `"public"` or the connection's `search_path`), hitting the wrong schema
        and leaving rows in place.

  `async: false` — tests mutate global :mailglass_inbound app env and
  :persistent_term for Config.schema/0.
  """

  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias MailglassInbound.Config
  alias MailglassInbound.Internal.Prune
  alias MailglassInbound.TestRepo

  @schema_key {MailglassInbound.Config, :schema}

  # ---- shared env/cache reset -----------------------------------------------

  setup do
    prior_schema = Application.fetch_env(:mailglass_inbound, :schema)

    on_exit(fn ->
      :persistent_term.erase(@schema_key)

      case prior_schema do
        {:ok, value} -> Application.put_env(:mailglass_inbound, :schema, value)
        :error -> Application.delete_env(:mailglass_inbound, :schema)
      end
    end)

    :ok
  end

  # ===========================================================================
  # (A) Facade default prefix + explicit-prefix precedence
  #
  # Uses an inline process-capturing fake repo so no real DB connection is
  # needed. The fake records the opts each call receives; assertions below
  # inspect those opts to verify prefix injection semantics.
  # ===========================================================================

  defmodule CaptureRepo do
    @moduledoc false
    # Captures the opts for the last call so tests can assert prefix behaviour.
    def insert(_changeset_or_struct, opts) do
      Process.put(:captured_opts, opts)
      {:ok, %{}}
    end

    def one(_queryable, opts) do
      Process.put(:captured_opts, opts)
      nil
    end

    def all(_queryable, opts) do
      Process.put(:captured_opts, opts)
      []
    end

    def get(_queryable, _id, opts) do
      Process.put(:captured_opts, opts)
      nil
    end

    def transaction(_multi_or_fun, opts) do
      Process.put(:captured_opts, opts)
      {:ok, %{}}
    end

    def transact(fun, opts) when is_function(fun, 0) do
      Process.put(:captured_opts, opts)
      {:ok, nil}
    end
  end

  # Wire the capture repo for facade tests and restore afterwards.
  defp with_capture_repo(schema, fun) do
    prior_repo = Application.fetch_env(:mailglass_inbound, :repo)
    Application.put_env(:mailglass_inbound, :repo, CaptureRepo)
    Application.put_env(:mailglass_inbound, :schema, schema)
    :persistent_term.erase(@schema_key)

    try do
      fun.()
    after
      case prior_repo do
        {:ok, mod} -> Application.put_env(:mailglass_inbound, :repo, mod)
        :error -> Application.delete_env(:mailglass_inbound, :repo)
      end
    end
  end

  describe "(A) facade prefix injection" do
    test "insert/2 with no opts injects prefix: Config.schema()" do
      with_capture_repo("mg_test", fn ->
        MailglassInbound.Repo.insert(%{}, [])
        opts = Process.get(:captured_opts)
        assert Keyword.get(opts, :prefix) == Config.schema()
        assert Config.schema() == "mg_test"
      end)
    end

    test "one/2 with no opts injects prefix: Config.schema()" do
      with_capture_repo("mg_test", fn ->
        MailglassInbound.Repo.one(nil, [])
        opts = Process.get(:captured_opts)
        assert Keyword.get(opts, :prefix) == Config.schema()
      end)
    end

    test "all/2 with no opts injects prefix: Config.schema()" do
      with_capture_repo("mg_test", fn ->
        MailglassInbound.Repo.all(nil, [])
        opts = Process.get(:captured_opts)
        assert Keyword.get(opts, :prefix) == Config.schema()
      end)
    end

    test "get/3 with no opts injects prefix: Config.schema()" do
      with_capture_repo("mg_test", fn ->
        MailglassInbound.Repo.get(nil, "some-id", [])
        opts = Process.get(:captured_opts)
        assert Keyword.get(opts, :prefix) == Config.schema()
      end)
    end

    test "explicit caller :prefix wins over the injected default (Keyword.put_new semantics)" do
      with_capture_repo("mg_test", fn ->
        MailglassInbound.Repo.insert(%{}, prefix: "override")
        opts = Process.get(:captured_opts)
        # The explicit override must survive — put_new does not clobber existing keys.
        assert Keyword.get(opts, :prefix) == "override"
      end)
    end

    test "transact/2 does NOT inject a prefix" do
      with_capture_repo("mg_test", fn ->
        MailglassInbound.Repo.transact(fn -> {:ok, nil} end, [])
        opts = Process.get(:captured_opts)
        # transact must not inject prefix — inner insert/one/all/get carry it.
        refute Keyword.has_key?(opts, :prefix)
      end)
    end

    test "multi/2 does NOT inject a prefix" do
      with_capture_repo("mg_test", fn ->
        MailglassInbound.Repo.multi(Ecto.Multi.new(), [])
        opts = Process.get(:captured_opts)
        # multi must not inject prefix — no Multi builders in inbound today (D-03).
        refute Keyword.has_key?(opts, :prefix)
      end)
    end
  end

  # ===========================================================================
  # (B) Prune DELETE schema target — D-02 load-bearing regression test
  #
  # Proof strategy (no second schema creation required):
  #
  #   1. Insert aged rows in "public" (where TestRepo migrations ran).
  #   2. Override Config.schema() to a nonexistent schema name ("mg_iso_test").
  #   3. Run Prune.prune/0 — its `delete_batched/3` issues DELETE with
  #      `prefix: Config.schema()` = "mg_iso_test", hitting a schema that does
  #      not exist or has no rows. Rows in "public" SURVIVE.
  #   4. Verify the rows still exist in "public".
  #
  # RED condition: if the `prefix:` is removed from prune.ex, the DELETE falls
  # back to Postgres's default schema resolution (typically "public" via
  # search_path), finds the aged rows in "public", and deletes them — making
  # step (4) fail with "row unexpectedly gone."
  #
  # Uses `sandbox: false` (real commits) because the prune sweep's batched loop
  # is NOT one transaction and advisory locks are session-scoped (mirrors
  # prune_test.exs setup rationale).
  # ===========================================================================

  describe "(B) prune DELETE schema target" do
    setup do
      # Real shared connection — prune commits between batches.
      :ok = Sandbox.checkout(TestRepo, sandbox: false)
      Sandbox.mode(TestRepo, {:shared, self()})

      prior_retention = Application.get_env(:mailglass_inbound, :retention)

      on_exit(fn ->
        case prior_retention do
          nil -> Application.delete_env(:mailglass_inbound, :retention)
          val -> Application.put_env(:mailglass_inbound, :retention, val)
        end

        # Truncate committed rows so subsequent test modules see a clean DB.
        :ok = Sandbox.checkout(TestRepo, sandbox: false)
        truncate_tables()
        Sandbox.checkin(TestRepo)
      end)

      truncate_tables()
      :ok
    end

    test "prune DELETE targets the configured schema — rows in public survive when schema is overridden" do
      # 1. Insert an aged record in "public" (current test DB schema).
      #    Use short windows so ALL the rows are over-window.
      Application.put_env(:mailglass_inbound, :retention,
        records_days: 1,
        evidence_days: 1,
        execution_runs_days: 1,
        replay_runs_days: 1
      )

      old_inserted_at = ~U[2020-01-01 00:00:00Z]
      record = insert_raw_record("prefix-tenant", old_inserted_at)

      # Sanity: the row exists in public before prune.
      assert TestRepo.get(MailglassInbound.InboundRecords.InboundRecord, record.id)

      # 2. Override Config.schema() to a nonexistent schema — prune will try to
      #    DELETE from "mg_iso_test"."mailglass_inbound_*" tables which either do
      #    not exist or have no rows. The DELETE must not touch "public".
      Application.put_env(:mailglass_inbound, :schema, "mg_iso_test")
      :persistent_term.erase(@schema_key)

      assert Config.schema() == "mg_iso_test"

      # 3. Run prune — the DELETE targets "mg_iso_test" (nonexistent) so Ecto will
      #    encounter an undefined_table error. We rescue that to distinguish it from
      #    an unrelated error, confirming the prefix was applied.
      result =
        try do
          Prune.prune()
        rescue
          e in Postgrex.Error -> {:schema_error, e}
        end

      # The expected outcome is a Postgrex schema/table error (undefined_table /
      # invalid_schema_name) because "mg_iso_test" does not exist — proving the
      # DELETE was correctly directed at a non-public schema via the inline prefix.
      # If the prefix were absent, the DELETE would silently succeed against "public"
      # and the aged row would be deleted — which the next assertion would catch.
      case result do
        {:schema_error, %Postgrex.Error{postgres: %{code: code}}}
        when code in [:undefined_table, :invalid_schema_name] ->
          # Expected: prefix was applied, hit the nonexistent schema.
          :ok

        {:ok, counts} ->
          # Prune ran but deleted 0 rows — acceptable if Ecto treated the unknown
          # schema gracefully. Verify the "public" row was NOT deleted.
          assert counts.records_deleted == 0,
                 "Expected 0 rows deleted (wrong schema) but got: #{inspect(counts)}"

        other ->
          flunk("Unexpected prune result: #{inspect(other)}")
      end

      # 4. The row in "public" must still exist — prune did NOT touch public.
      #    Reset the schema to "public" so TestRepo.get can find it without prefix.
      Application.put_env(:mailglass_inbound, :schema, "public")
      :persistent_term.erase(@schema_key)

      assert TestRepo.get(MailglassInbound.InboundRecords.InboundRecord, record.id),
             "Row in public was deleted — this means the prune DELETE was NOT using the configured prefix " <>
               "(it fell back to public). The inline prefix: in delete_batched/3 is missing or wrong."
    end
  end

  # ---- helpers ---------------------------------------------------------------

  # Insert directly via TestRepo (bypassing the facade) to land rows in "public"
  # regardless of the current Config.schema() override. Sets inserted_at to a
  # past timestamp so the row is over-window for 1-day retention.
  # Uses TestRepo.insert_all with a raw string table name so the facade's put_prefix/1
  # is not involved — the row lands in "public" regardless of Config.schema().
  defp insert_raw_record(tenant_id, inserted_at) do
    {:ok, id_binary} = Ecto.UUID.dump(Ecto.UUID.generate())
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    inserted_at_naive = DateTime.to_naive(inserted_at) |> NaiveDateTime.truncate(:second)

    {1, _} =
      TestRepo.insert_all(
        "mailglass_inbound_records",
        [
          %{
            id: id_binary,
            tenant_id: tenant_id,
            provider: "postmark",
            provider_message_id: "prefix-pmid-#{System.unique_integer([:positive])}",
            envelope_recipient: "test@example.com",
            received_at: inserted_at,
            suppression_flagged: false,
            from: [],
            to: [],
            cc: [],
            bcc: [],
            reply_to: [],
            headers: %{},
            attachments: [],
            inserted_at: inserted_at_naive,
            updated_at: now
          }
        ]
      )

    {:ok, id_str} = Ecto.UUID.load(id_binary)
    TestRepo.get!(MailglassInbound.InboundRecords.InboundRecord, id_str)
  end

  defp truncate_tables do
    TestRepo.query!(
      "TRUNCATE mailglass_inbound_replay_runs, mailglass_inbound_evidence, mailglass_inbound_records CASCADE"
    )
  end
end
