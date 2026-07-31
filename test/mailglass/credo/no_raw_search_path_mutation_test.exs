defmodule Mailglass.Credo.NoRawSearchPathMutationTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoRawSearchPathMutation

  # D-31 Class A: the PREVENTION half of the two-layer recurrence guard for the
  # `search_path` pool-poisoning defect (the detection half is
  # `Mailglass.TestSupport.SandboxOwnership.with_search_path!/3`'s verified,
  # same-connection restore). Detection shipped alone once already, and the
  # class recurred; this check is the fail-closed layer.
  #
  # This module is one of the check's three allowlisted modules (see `.credo.exs`
  # for the per-entry justification). It has to be: the positive cases below must
  # spell the banned statements verbatim — including the multi-statement
  # `...; SET search_path ...` evasion — and there is no way to write that
  # fixture without a statement-initial literal in this file's own source. The
  # alternative, splitting the literals apart so the check cannot see them, would
  # teach precisely the evasion this guard exists to prevent. The exemption is
  # zero-risk: this is a pure `async: true` Credo unit test that opens no
  # database connection. Do not "clean up" the literals below.

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  # Every banned spelling, with the reason it is banned recorded next to it.
  # `SET LOCAL` is included on purpose: it is transaction-scoped and therefore
  # cannot poison the pool, but it survives to the end of the transaction and
  # breaks Ecto's own `schema_migrations` bookkeeping INSERT (observed live: 4
  # tests / 4 failures in shipped_migration_divergence_test.exs on the mailglass
  # axis). "Safer than the worst form" is not the same as safe.
  @banned_call_sites [
    {~s|TestRepo.query!("SET search_path TO public", [])|,
     "session-level write — poisons the pooled connection"},
    {~s|TestRepo.query!("SET SESSION search_path TO public", [])|,
     "explicit spelling of the same session write"},
    {~s|TestRepo.query!("set search_path to public", [])|,
     "lower-case spelling of the same session write"},
    {~s|TestRepo.query!("SET LOCAL search_path TO mailglass, public", [])|,
     "transaction-scoped, but breaks Ecto's schema_migrations bookkeeping INSERT"},
    {~s|TestRepo.query!("RESET search_path", [])|,
     "lands on an arbitrary pooled connection — heals nothing observable"},
    {~s|TestRepo.query!("SELECT set_config('search_path', 'public', false)", [])|,
     "the function-call spelling of a session-level SET"}
  ]

  for {call_site, reason} <- @banned_call_sites do
    test "flags `#{call_site}` (#{reason})" do
      issues = run_check(fixture(unquote(call_site)), "test/mailglass/some_test.exs")

      assert length(issues) == 1,
             "expected exactly one issue for #{unquote(call_site)}, got #{length(issues)}"

      assert hd(issues).message =~ "42P01"
      assert hd(issues).message =~ "with_search_path!"
    end
  end

  # Anti-vacuity floor across the whole banned corpus at once, in the
  # `no_raw_sandbox_ownership_test.exs:50-67` shape: if an AST-shape change ever
  # made the traversal silently stop matching, each positive case above would
  # drop to zero issues one at a time. This pins all of them together, named to
  # the check, so a systemic regression is caught even if a single test's own
  # assertion were ever weakened.
  test "the banned call-site corpus produces exactly one issue per fixture" do
    total_issues =
      Enum.reduce(@banned_call_sites, 0, fn {call_site, _reason}, acc ->
        acc + length(run_check(fixture(call_site), "test/mailglass/some_test.exs"))
      end)

    assert total_issues == length(@banned_call_sites),
           "Mailglass.Credo.NoRawSearchPathMutation fired #{total_issues} issue(s) across " <>
             "#{length(@banned_call_sites)} banned call-site fixtures — expected exactly one per fixture"
  end

  # The single most likely re-typing of the defect is an INTERPOLATED override
  # (`SET search_path TO #{schema}`). A check that only matched plain binaries
  # would miss it and be effectively vacuous against real code.
  test "flags an interpolated override, not just a plain binary" do
    source = ~S"""
    defmodule Mailglass.SomeTest do
      def run(schema) do
        TestRepo.query!("SET search_path TO #{schema}, public", [])
      end
    end
    """

    issues = run_check(source, "test/mailglass/some_test.exs")

    assert length(issues) == 1
    assert hd(issues).trigger =~ "search_path"
  end

  test "flags a sigil-spelled override" do
    source = ~S"""
    defmodule Mailglass.SomeTest do
      def run do
        TestRepo.query!(~s|SET search_path TO public|, [])
      end
    end
    """

    assert length(run_check(source, "test/mailglass/some_test.exs")) == 1
  end

  # A multi-statement string hides the mutation behind a leading statement.
  # Statement-initial position is defined as "start of the literal, or right
  # after a `;`" precisely so this cannot slip through.
  test "flags a mutation that follows another statement after a semicolon" do
    source = """
    defmodule Mailglass.SomeTest do
      def run do
        TestRepo.query!("CREATE SCHEMA IF NOT EXISTS scratch; SET search_path TO scratch", [])
      end
    end
    """

    assert length(run_check(source, "test/mailglass/some_test.exs")) == 1
  end

  # Not tied to Repo.query/2: an `execute/1` inside an inline migration is the
  # exact shape the obsolete `SET LOCAL` migration pins had.
  test "flags a mutation issued from a migration execute/1 call" do
    source = """
    defmodule Mailglass.SomeTest.WrapperMigration do
      use Ecto.Migration

      def up do
        execute("SET LOCAL search_path TO scratch, public")
      end
    end
    """

    assert length(run_check(source, "test/mailglass/some_test.exs")) == 1
  end

  test "flags a mutation in the inbound sibling package's test tree" do
    source = """
    defmodule MailglassInbound.SomeTest do
      def run do
        TestRepo.query!("SET search_path TO public", [])
      end
    end
    """

    assert length(run_check(source, "mailglass_inbound/test/some_test.exs")) == 1
  end

  # ── Negative cases: the safe forms, none of which needs an allowlist entry ──

  test "does not flag a read-only SHOW search_path" do
    source = """
    defmodule Mailglass.SomeTest do
      def run do
        TestRepo.query!("SHOW search_path", [])
      end
    end
    """

    assert run_check(source, "test/mailglass/some_test.exs") == []
  end

  # `CREATE FUNCTION ... SET search_path = ''` is a function ATTRIBUTE clause
  # that hardens the function body against search-path injection — a different
  # construct from a session write, and the one v01.ex deliberately emits. It is
  # never statement-initial inside the CREATE statement, which is what keeps it
  # out of scope with no allowlist entry.
  test "does not flag a SET search_path = '' function-attribute clause" do
    source = ~S"""
    defmodule Mailglass.SomeTest do
      def run do
        TestRepo.query!(
          "CREATE OR REPLACE FUNCTION f() RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$ BEGIN RETURN NULL; END; $$",
          []
        )
      end
    end
    """

    assert run_check(source, "test/mailglass/some_test.exs") == []
  end

  # The literal in `assert body =~ "SET search_path = ''"` IS statement-initial,
  # but it is compared, never executed — it cannot poison anything. Exempting it
  # positionally (rather than by allowlisting the file) is what stops this check
  # from teaching maintainers to split string literals to dodge it.
  test "does not flag an assertion match target" do
    source = ~S"""
    defmodule Mailglass.SomeTest do
      def run(body) do
        assert body =~ "SET search_path = ''"
        assert String.contains?(body, "SET search_path TO public")
      end
    end
    """

    assert run_check(source, "test/mailglass/some_test.exs") == []
  end

  test "does not flag the Postgrex :parameters connection option" do
    source = ~S"""
    defmodule Mailglass.SomeTest do
      def run(schema, parameters) do
        Keyword.put(parameters, :search_path, "#{schema}, public")
      end
    end
    """

    assert run_check(source, "test/mailglass/some_test.exs") == []
  end

  test "ignores a file whose path is outside the linted test trees" do
    source = """
    defmodule Mailglass.SomeLibModule do
      def run do
        TestRepo.query!("SET search_path TO public", [])
      end
    end
    """

    assert run_check(source, "lib/mailglass/some_lib_module.ex") == []
  end

  # ── The allowlist: exactly two entries, both structural ──

  test "allows the statement from inside Mailglass.TestSupport.SandboxOwnership" do
    source = ~S"""
    defmodule Mailglass.TestSupport.SandboxOwnership do
      def with_search_path!(search_path, fun, opts) do
        repo = Keyword.get(opts, :repo)
        repo.query!("SET search_path TO #{search_path}", [])
        fun.()
      end
    end
    """

    assert run_check(source, "test/support/sandbox_ownership.ex") == []
  end

  test "allows the statement from inside Mailglass.TestSupport.SandboxOwnershipTest" do
    source = """
    defmodule Mailglass.TestSupport.SandboxOwnershipTest do
      use ExUnit.Case

      test "the seam restores the connection" do
        Mailglass.TestRepo.query!("SET search_path TO public", [])
      end
    end
    """

    assert run_check(source, "test/mailglass/test_support/sandbox_ownership_test.exs") == []
  end

  test "the allowlist does not leak to a sibling module in the same file" do
    source = """
    defmodule Mailglass.TestSupport.SandboxOwnership.SomeHelper do
      def run do
        TestRepo.query!("SET search_path TO public", [])
      end
    end
    """

    assert length(run_check(source, "test/support/sandbox_ownership.ex")) == 1
  end

  # ── Fail-closed: non-observation is a failure, never a green ──

  # A file this check is responsible for but cannot parse must NOT report clean.
  # Credo hands `run/2` an EMPTY ast with `status: :invalid` in that case, and an
  # empty AST traverses to zero issues — a silent, confident green over a file
  # whose contents were never read. That is the exact "reported success without
  # observing its subject" failure this milestone exists to eliminate.
  test "reports an issue for an unparsable in-scope file rather than reporting clean" do
    issues = run_check("defmodule Broken do def run do end", "test/mailglass/broken_test.exs")

    assert length(issues) == 1
    assert hd(issues).message =~ "could not observe"
    assert hd(issues).trigger == "unparsable-source"
  end

  test "an unparsable file OUTSIDE the linted trees stays out of scope" do
    assert run_check("defmodule Broken do def run do end", "lib/mailglass/broken.ex") == []
  end

  defp fixture(call_site) do
    """
    defmodule Mailglass.SomeTest do
      def run do
        #{call_site}
      end
    end
    """
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoRawSearchPathMutation.run([])
  end
end
