defmodule Mailglass.Test.InstallerFixtureHelpers do
  @moduledoc false

  @fixture_source Path.expand("../example", __DIR__)

  def new_fixture_root!(name) when is_binary(name) do
    fixture_root = temp_fixture_root(name)

    File.rm_rf!(fixture_root)
    File.mkdir_p!(Path.dirname(fixture_root))
    File.cp_r!(@fixture_source, fixture_root)
    ensure_host_skeleton!(fixture_root)

    fixture_root
  end

  def run_install!(fixture_root, argv) when is_binary(fixture_root) and is_list(argv) do
    normalized_argv = Enum.map(argv, &to_string/1)

    {opts, rest, invalid} =
      OptionParser.parse(normalized_argv,
        strict: [dry_run: :boolean, no_admin: :boolean, force: :boolean]
      )

    if rest != [] or invalid != [] do
      raise ArgumentError,
            "installer fixture: invalid argv #{inspect(normalized_argv)}; " <>
              "rest=#{inspect(rest)} invalid=#{inspect(invalid)}"
    end

    File.cd!(fixture_root, fn ->
      plan =
        Mailglass.Installer.Plan.build(opts, %{
          oban_available?: Mailglass.OptionalDeps.Oban.available?()
        })

      case Mailglass.Installer.Apply.run(plan, opts) do
        {:ok, _result} ->
          :ok

        {:error, reason} ->
          raise "installer fixture: Apply.run/2 failed with #{inspect(reason)}"
      end
    end)

    :ok
  end

  @doc """
  Compile-validates every generated/edited artifact in an installed fixture.

  The other installer tests only assert that snippets were inserted or that a
  golden hash matches — they never compile the output, which is how a corrupted
  `endpoint.ex` (anchor split mid-`use Phoenix.Endpoint, otp_app:`) and an
  escaped `<%%=` HEEx layout both shipped undetected. This walks the installed
  tree and fails loudly, naming the offending file:

    * `.ex` / `.exs` → parsed with `Code.string_to_quoted!/2` (syntax only;
      NOT full compile — host files expand `use Phoenix.Endpoint`/router macros
      that need the whole app, which is the PR-time host smoke's job).
    * `.heex` → run through the Phoenix HEEx tag engine so template-syntax
      errors raise.
  """
  def assert_generated_artifacts_compile!(fixture_root) when is_binary(fixture_root) do
    fixture_root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Enum.each(&assert_artifact_compiles!(&1, fixture_root))

    :ok
  end

  defp assert_artifact_compiles!(path, fixture_root) do
    case Path.extname(path) do
      ext when ext in [".ex", ".exs"] -> assert_elixir_parses!(path, fixture_root)
      ".heex" -> assert_heex_compiles!(path, fixture_root)
      _ -> :ok
    end
  end

  defp assert_elixir_parses!(path, fixture_root) do
    Code.string_to_quoted!(File.read!(path), file: path)
    :ok
  rescue
    error in [SyntaxError, TokenMissingError, MismatchedDelimiterError] ->
      reraise(
        """
        Generated Elixir artifact does not parse: #{Path.relative_to(path, fixture_root)}
        #{Exception.message(error)}
        """,
        __STACKTRACE__
      )
  end

  defp assert_heex_compiles!(path, fixture_root) do
    source = File.read!(path)

    EEx.compile_string(source,
      engine: Phoenix.LiveView.TagEngine,
      tag_handler: Phoenix.LiveView.HTMLEngine,
      file: path,
      line: 1,
      caller: __ENV__,
      source: source
    )

    :ok
  rescue
    error ->
      reraise(
        """
        Generated HEEx artifact does not compile: #{Path.relative_to(path, fixture_root)}
        #{Exception.message(error)}
        """,
        __STACKTRACE__
      )
  end

  def snapshot_tree!(fixture_root) when is_binary(fixture_root) do
    files =
      fixture_root
      |> Path.join("**/*")
      |> Path.wildcard(match_dot: true)
      |> Enum.filter(&File.regular?/1)
      |> Enum.reject(&(Path.relative_to(&1, fixture_root) == "README.md"))
      |> Enum.sort()

    tree_lines =
      Enum.map(files, fn path ->
        rel_path = Path.relative_to(path, fixture_root)
        digest = path |> File.read!() |> normalize_newlines() |> normalize_for_digest() |> sha256()
        "- #{rel_path} sha256:#{digest}"
      end)

    file_blocks =
      Enum.map(files, fn path ->
        rel_path = Path.relative_to(path, fixture_root)
        body = path |> File.read!() |> normalize_newlines()
        rendered_body = if body == "", do: "<EMPTY>", else: body
        "@@ #{rel_path}\n#{rendered_body}"
      end)

    [
      "# tree",
      Enum.join(tree_lines, "\n"),
      "",
      "# files",
      Enum.join(file_blocks, "\n\n")
    ]
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  def normalize_snapshot(snapshot) when is_binary(snapshot) do
    snapshot
    |> normalize_newlines()
    |> normalize_tmp_path()
    |> normalize_migration_ts()
    |> normalize_last_run_at()
    |> normalize_secret()
    |> normalize_installer_version()
    |> String.trim()
  end

  defp normalize_tmp_path(snapshot) do
    tmp_dir = Regex.escape(System.tmp_dir!())
    regex = ~r/#{tmp_dir}\/mailglass-installer-fixture-[^\/\s"]+/
    Regex.replace(regex, snapshot, "<TMP_PATH>")
  end

  defp normalize_migration_ts(snapshot) do
    snapshot =
      Regex.replace(~r/\b\d{14}(?=_mailglass_install\.exs)/, snapshot, "<MIGRATION_TS>")

    Regex.replace(~r/(migration_ts = ")\d{14}(")/, snapshot, "\\1<MIGRATION_TS>\\2")
  end

  defp normalize_secret(snapshot) do
    Regex.replace(~r/(secret\s*[:=]\s*")[^"]+(")/, snapshot, "\\1<SECRET>\\2")
  end

  defp normalize_for_digest(contents) do
    contents
    |> normalize_tmp_path()
    |> normalize_migration_ts()
    |> normalize_last_run_at()
    |> normalize_secret()
    |> normalize_installer_version()
  end

  defp normalize_last_run_at(snapshot) do
    Regex.replace(~r/(last_run_at = ")[^"]+(")/, snapshot, "\\1<LAST_RUN_AT>\\2")
  end

  defp normalize_installer_version(snapshot) do
    Regex.replace(
      ~r/(installer_version\s*=\s*")\d+\.\d+\.\d+[^"]*(")/,
      snapshot,
      "\\1<INSTALLER_VERSION>\\2"
    )
  end

  defp ensure_host_skeleton!(fixture_root) do
    write_if_missing!(Path.join(fixture_root, "mix.exs"), host_mix_exs())
    write_if_missing!(Path.join(fixture_root, "lib/example_web/router.ex"), host_router())
    write_if_missing!(Path.join(fixture_root, "lib/example_web/endpoint.ex"), host_endpoint())
    write_if_missing!(Path.join(fixture_root, "config/runtime.exs"), host_runtime())
  end

  defp write_if_missing!(path, contents) do
    unless File.exists?(path) do
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, contents)
    end
  end

  defp temp_fixture_root(name) do
    unique = "#{System.unique_integer([:positive])}"
    Path.join(System.tmp_dir!(), "mailglass-installer-fixture-#{name}-#{unique}")
  end

  defp sha256(contents) do
    :crypto.hash(:sha256, contents)
    |> Base.encode16(case: :lower)
  end

  defp normalize_newlines(contents) do
    String.replace(contents, "\r\n", "\n")
  end

  defp host_mix_exs do
    """
    defmodule Example.MixProject do
      use Mix.Project

      def project do
        [app: :example, version: "0.1.0", elixir: "~> 1.18"]
      end
    end
    """
  end

  defp host_router do
    # NOTE: Real Phoenix apps have `use MyAppWeb, :router` which expands to
    # `use Phoenix.Router` at compile time; the source file does NOT contain
    # `use Phoenix.Router` literally. The installer's `router_anchor/0`
    # currently looks for the literal expanded form, which is fragile for
    # real adopters but lets us seed the fixture deterministically here.
    # Tracked as a v0.1.1 polish: make the anchor match `:router` keyword.
    """
    defmodule ExampleWeb.Router do
      use Phoenix.Router
      use ExampleWeb, :router

      scope "/", ExampleWeb do
        pipe_through :browser
      end
    end
    """
  end

  defp host_endpoint do
    """
    defmodule ExampleWeb.Endpoint do
      use Phoenix.Endpoint, otp_app: :example
    end
    """
  end

  defp host_runtime do
    """
    import Config
    """
  end
end
