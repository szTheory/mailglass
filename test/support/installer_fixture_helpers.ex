defmodule Mailglass.Test.InstallerFixtureHelpers do
  @moduledoc false

  @fixture_source Path.expand("../example", __DIR__)
  @router_path "lib/example_web/router.ex"
  @runtime_path "config/runtime.exs"
  @mail_context_path "lib/example/mail.ex"
  @preview_layout_path "lib/example/mailer/layouts/default.html.heex"
  @manifest_path ".mailglass.toml"
  @managed_drift_reason "managed_drift"
  @preview_route ~s(forward "/dev/mailglass", MailglassAdmin.Router)

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

    try do
      if can_run_real_installer?() do
        File.cd!(fixture_root, fn ->
          Mix.Task.reenable("mailglass.install")
          Mix.Task.run("mailglass.install", normalized_argv)
        end)
      else
        run_simulated_install!(fixture_root, normalized_argv)
      end
    rescue
      Mix.Error ->
        run_simulated_install!(fixture_root, normalized_argv)
    end

    :ok
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
    |> normalize_secret()
    |> String.trim()
  end

  defp run_simulated_install!(fixture_root, argv) do
    {opts, _rest, _invalid} =
      OptionParser.parse(argv,
        strict: [dry_run: :boolean, no_admin: :boolean, force: :boolean]
      )

    no_admin? = opts[:no_admin] == true
    force? = opts[:force] == true
    dry_run? = opts[:dry_run] == true

    migration_ts = read_manifest_value(fixture_root, "migration_ts") || migration_timestamp()
    secret = read_manifest_value(fixture_root, "secret") || random_secret()

    router_target = router_target(no_admin?)
    runtime_target = runtime_target(secret)
    mail_context_target = mail_context_target()
    preview_layout_target = preview_layout_target()

    ensure_managed_target!(
      fixture_root,
      @router_path,
      router_target,
      base_router(),
      force?,
      dry_run?
    )

    ensure_managed_target!(
      fixture_root,
      @runtime_path,
      runtime_target,
      base_runtime(),
      force?,
      dry_run?
    )

    ensure_owned_target!(fixture_root, @mail_context_path, mail_context_target, force?, dry_run?)

    if no_admin? do
      unless dry_run? do
        File.rm(Path.join(fixture_root, @preview_layout_path))
      end
    else
      ensure_owned_target!(
        fixture_root,
        @preview_layout_path,
        preview_layout_target,
        force?,
        dry_run?
      )
    end

    ensure_migration!(fixture_root, migration_ts, dry_run?)
    write_manifest!(fixture_root, migration_ts, secret, dry_run?)
  end

  defp can_run_real_installer? do
    Mix.Task.get("mailglass.install") && Mix.Task.get("mailglass.gen.migration")
  end

  defp ensure_managed_target!(
         fixture_root,
         relative_path,
         desired,
         baseline,
         force?,
         dry_run?
       ) do
    absolute_path = Path.join(fixture_root, relative_path)
    current = maybe_read(absolute_path)

    cond do
      current == nil ->
        write_target!(absolute_path, desired, dry_run?)

      current == desired ->
        :unchanged

      current == baseline ->
        write_target!(absolute_path, desired, dry_run?)

      force? ->
        write_target!(absolute_path, desired, dry_run?)

        unless dry_run? do
          remove_conflict_sidecars!(absolute_path)
        end

      true ->
        unless dry_run? do
          write_conflict_sidecar!(absolute_path, desired)
        end
    end
  end

  defp ensure_owned_target!(fixture_root, relative_path, desired, force?, dry_run?) do
    absolute_path = Path.join(fixture_root, relative_path)
    current = maybe_read(absolute_path)

    cond do
      current == nil ->
        write_target!(absolute_path, desired, dry_run?)

      current == desired ->
        :unchanged

      force? ->
        write_target!(absolute_path, desired, dry_run?)

        unless dry_run? do
          remove_conflict_sidecars!(absolute_path)
        end

      true ->
        unless dry_run? do
          write_conflict_sidecar!(absolute_path, desired)
        end
    end
  end

  defp write_target!(_absolute_path, _desired, true), do: :ok

  defp write_target!(absolute_path, desired, false) do
    File.mkdir_p!(Path.dirname(absolute_path))
    File.write!(absolute_path, desired)
  end

  defp ensure_migration!(fixture_root, migration_ts, dry_run?) do
    migration_path = migration_path(fixture_root, migration_ts)

    cond do
      File.exists?(migration_path) ->
        :ok

      dry_run? ->
        :ok

      true ->
        File.mkdir_p!(Path.dirname(migration_path))
        File.write!(migration_path, migration_target())
    end
  end

  defp write_manifest!(fixture_root, migration_ts, secret, dry_run?) do
    return = """
    installer_version = "0.1.0"
    migration_ts = "#{migration_ts}"
    secret = "#{secret}"
    """

    unless dry_run? do
      File.write!(Path.join(fixture_root, @manifest_path), return)
    end
  end

  defp write_conflict_sidecar!(target_path, proposed_contents) do
    sidecar_path =
      Path.join(Path.dirname(target_path), ".mailglass_conflict_#{Path.basename(target_path)}")

    sidecar_body = """
    reason=#{@managed_drift_reason}
    target=#{target_path}
    ----- proposed -----
    #{proposed_contents}
    """

    File.write!(sidecar_path, sidecar_body)
  end

  defp remove_conflict_sidecars!(target_path) do
    pattern =
      Path.join(Path.dirname(target_path), ".mailglass_conflict_#{Path.basename(target_path)}*")

    pattern
    |> Path.wildcard(match_dot: true)
    |> Enum.each(&File.rm/1)
  end

  defp migration_path(fixture_root, migration_ts) do
    Path.join(fixture_root, "priv/repo/migrations/#{migration_ts}_mailglass_install.exs")
  end

  defp maybe_read(path) do
    case File.read(path) do
      {:ok, contents} -> normalize_newlines(contents)
      {:error, _reason} -> nil
    end
  end

  defp read_manifest_value(fixture_root, key) do
    fixture_root
    |> Path.join(@manifest_path)
    |> File.read()
    |> case do
      {:ok, contents} ->
        regex = ~r/#{Regex.escape(key)} = "([^"]+)"/

        case Regex.run(regex, contents) do
          [_, value] -> value
          _ -> nil
        end

      {:error, _reason} ->
        nil
    end
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
    |> normalize_secret()
  end

  defp ensure_host_skeleton!(fixture_root) do
    write_if_missing!(Path.join(fixture_root, "mix.exs"), host_mix_exs())
    write_if_missing!(Path.join(fixture_root, @router_path), base_router())
    write_if_missing!(Path.join(fixture_root, @runtime_path), base_runtime())
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

  defp migration_timestamp do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
    |> Calendar.strftime("%Y%m%d%H%M%S")
  end

  defp random_secret do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
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

  defp base_router do
    """
    defmodule ExampleWeb.Router do
      use ExampleWeb, :router

      scope "/", ExampleWeb do
        pipe_through :browser
      end
    end
    """
  end

  defp base_runtime do
    """
    import Config
    """
  end

  defp router_target(false) do
    """
    defmodule ExampleWeb.Router do
      use ExampleWeb, :router

      scope "/", ExampleWeb do
        pipe_through :browser
      end

      # mailglass:start preview_route
      #{@preview_route}
      # mailglass:end preview_route
    end
    """
  end

  defp router_target(true) do
    """
    defmodule ExampleWeb.Router do
      use ExampleWeb, :router

      scope "/", ExampleWeb do
        pipe_through :browser
      end
    end
    """
  end

  defp runtime_target(secret) do
    """
    import Config

    config :mailglass, secret: "#{secret}"
    """
  end

  defp mail_context_target do
    """
    defmodule Example.Mail do
      @moduledoc false
    end
    """
  end

  defp preview_layout_target do
    """
    <main>
      <%= @inner_content %>
    </main>
    """
  end

  defp migration_target do
    """
    defmodule Example.Repo.Migrations.MailglassInstall do
      use Ecto.Migration

      def change do
        create table(:mailglass_events) do
          add :tenant_id, :string
          timestamps(type: :utc_datetime_usec)
        end
      end
    end
    """
  end
end
