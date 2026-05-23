defmodule Mailglass.Credo.NoBareOptionalDepReferenceTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoBareOptionalDepReference

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags direct optional dependency call outside gateway module" do
    source = """
    defmodule Mailglass.Outbound.BadCall do
      def run(job) do
        Oban.insert(job)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/outbound/no_bare_optional_dep_reference_bad.ex")

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "Mailglass.OptionalDeps.Oban")
  end

  test "does not flag calls inside the configured gateway module" do
    source = """
    defmodule Mailglass.OptionalDeps.Oban do
      def run(job) do
        Oban.insert(job)
      end
    end
    """

    assert run_check(source, "lib/mailglass/optional_deps/oban.ex") == []
  end

  test "does not flag non-gated module calls" do
    source = """
    defmodule Mailglass.Outbound.GoodCall do
      def run(job) do
        Phoenix.PubSub.broadcast(job, "mailglass:events", :ok)
      end
    end
    """

    assert run_check(source, "lib/mailglass/outbound/no_bare_optional_dep_reference_good.ex") == []
  end

  test "ignores files outside lib/mailglass path scope" do
    source = """
    defmodule Mailglass.Support.BadCall do
      def run(job) do
        Oban.insert(job)
      end
    end
    """

    assert run_check(source, "test/support/no_bare_optional_dep_reference_fixture.ex") == []
  end

  # CR-01 regression: gen_smtp is an Erlang library with no `GenSmtp` Elixir
  # module — it is reached via the bare call-site atoms `:mimemail` and
  # `:gen_smtp_client`. These cases thread the explicit atom-keyed `gated_modules`
  # param so the test pins the ATOM-KEY behavior independent of `.credo.exs` drift
  # (45-09's config sentinel pins the config; this test pins the check behavior).
  @gen_smtp_atom_gates %{
    :mimemail => Mailglass.OptionalDeps.GenSmtp,
    :gen_smtp_client => Mailglass.OptionalDeps.GenSmtp
  }

  test "flags bare :mimemail.decode outside the gateway when keyed on the Erlang atom" do
    source = """
    defmodule Mailglass.Inbound.BadMime do
      def parse(raw) do
        :mimemail.decode(raw)
      end
    end
    """

    issues =
      run_check(source, "lib/mailglass/inbound_bad_mime.ex", gated_modules: @gen_smtp_atom_gates)

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "Mailglass.OptionalDeps.GenSmtp")
  end

  test "does not flag :mimemail.decode inside the sanctioned GenSmtp gateway" do
    source = """
    defmodule Mailglass.OptionalDeps.GenSmtp do
      def decode(raw) do
        :mimemail.decode(raw)
      end
    end
    """

    assert run_check(
             source,
             "lib/mailglass/optional_deps/gen_smtp.ex",
             gated_modules: @gen_smtp_atom_gates
           ) == []
  end

  test "flags bare :gen_smtp_client.send outside the gateway when keyed on the Erlang atom" do
    source = """
    defmodule Mailglass.Inbound.BadSmtp do
      def send(x) do
        :gen_smtp_client.send(x)
      end
    end
    """

    issues =
      run_check(source, "lib/mailglass/inbound_bad_smtp.ex", gated_modules: @gen_smtp_atom_gates)

    assert length(issues) == 1
  end

  test "negative control: default params (no :mimemail key) do not flag the bare atom call" do
    source = """
    defmodule Mailglass.Inbound.BadMime do
      def parse(raw) do
        :mimemail.decode(raw)
      end
    end
    """

    # Same source/filename as the positive case, but run via the default-params
    # run_check/2 whose default gated_modules has no `:mimemail` key. Proves the
    # atom-key param — not a default that happens to pass — is what activates the
    # catch.
    assert run_check(source, "lib/mailglass/inbound_bad_mime.ex") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoBareOptionalDepReference.run([])
  end

  defp run_check(source, filename, params) do
    source
    |> SourceFile.parse(filename)
    |> NoBareOptionalDepReference.run(params)
  end
end
