defmodule Mix.Tasks.Mailglass.Publish.Check do
  use Boundary, classify_to: Mailglass

  @shortdoc "Run the pre-publish Hex package checks"

  @moduledoc """
  Verify the published tarball before Hex.pm release.

  ## Usage

      mix mailglass.publish.check
      mix mailglass.publish.check --package mailglass
      mix mailglass.publish.check --package mailglass_admin
      mix mailglass.publish.check --package mailglass --keep

  ## Options

    * `--package` - optional package selector (`mailglass` or `mailglass_admin`);
      when omitted, both packages are checked sequentially.
    * `--keep` - preserve `_publish_check/<pkg>/` for inspection.
  """

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} = OptionParser.parse(argv, strict: [package: :string, keep: :boolean])

    validate_cli!(rest, invalid)

    with_disabled_otel(fn ->
      Mix.Task.run("app.start")

      packages(opts[:package])
      |> Enum.each(fn package ->
        execute_package(package, opts[:keep] == true)
      end)
    end)
  end

  defp packages(nil), do: [:mailglass, :mailglass_admin]

  defp packages("mailglass"), do: [:mailglass]
  defp packages("mailglass_admin"), do: [:mailglass_admin]

  defp packages(other) do
    Mix.raise(
      "Delivery blocked: unknown package #{inspect(other)}. Use mailglass or mailglass_admin."
    )
  end

  defp validate_cli!(rest, invalid) do
    if rest != [] do
      Mix.raise("Delivery blocked: unknown args #{Enum.join(rest, " ")}")
    end

    if invalid != [] do
      flags = invalid |> Enum.map(fn {key, _} -> "--#{key}" end) |> Enum.join(", ")
      Mix.raise("Delivery blocked: unknown args #{flags}")
    end

    :ok
  end

  defp execute_package(package, keep?) do
    ctx = load_package_context(package)

    counts = %{create: 0, update: 0, unchanged: 0, conflict: 0}
    {counts, ctx} = step(counts, :create, package, "build and unpack tarball", ctx, &build_tarball/1)
    {counts, ctx} = step(counts, :create, package, "capture file list", ctx, &capture_file_list/1)
    {counts, ctx} = step(counts, :unchanged, package, "compare allowlist", ctx, &verify_allowlist/1)
    {counts, ctx} = step(counts, :unchanged, package, "check denylist", ctx, &verify_denylist/1)
    {counts, ctx} = step(counts, :update, package, "check tarball size", ctx, &verify_size/1)
    {counts, ctx} = step(counts, :unchanged, package, "check required files", ctx, &verify_required_files/1)
    {counts, ctx} = step(counts, :unchanged, package, "check CHANGELOG section", ctx, &verify_changelog/1)
    {counts, ctx} = step(counts, :unchanged, package, "check mix metadata", ctx, &verify_metadata/1)
    {counts, ctx} = step(counts, :unchanged, package, "check dependency shapes", ctx, &verify_deps/1)

    {counts, ctx} = step(counts, :unchanged, package, "check linked-version constraint", ctx, &verify_linked_constraint/1)

    {counts, ctx} = step(counts, :unchanged, package, "check prod deps resolution", ctx, &verify_prod_deps/1)
    {counts, ctx} = step(counts, :unchanged, package, "compile tarball in isolation", ctx, &verify_compile/1)
    {counts, ctx} = step(counts, :update, package, "run hex.audit", ctx, &verify_audit/1)
    {counts, ctx} = step(counts, :update, package, "capture hex.outdated advisory", ctx, &capture_outdated/1)
    {counts, ctx} = step(counts, :update, package, "write reviewer summary", ctx, &write_summary/1)

    {counts, _ctx} =
      step(counts, if(keep?, do: :unchanged, else: :update), package, cleanup_label(keep?), ctx, fn ctx ->
        cleanup(ctx, keep?)
      end)

    Mix.shell().info(
      "Pre-publish check result for #{ctx.package}: create=#{counts.create} update=#{counts.update} " <>
        "unchanged=#{counts.unchanged} conflict=#{counts.conflict}"
    )
  end

  defp cleanup_label(true), do: "retain unpacked tarball"
  defp cleanup_label(false), do: "clean unpacked tarball"

  defp step(counts, status, package, label, ctx, fun) do
    Mix.shell().info("#{status_label(status)} #{label} for #{package}")
    {Map.update!(counts, status, &(&1 + 1)), fun.(ctx)}
  end

  defp status_label(:create), do: "[create]"
  defp status_label(:update), do: "[update]"
  defp status_label(:unchanged), do: "[unchanged]"
  defp status_label(:conflict), do: "[conflict]"

  defp fail_step(label, message) do
    Mix.shell().info("[conflict] #{label}")
    Mix.shell().error(message)
    exit({:shutdown, 1})
  end

  defp load_package_context(package) do
    repo_root = File.cwd!()
    package_dir = package_dir(repo_root, package)
    source_path = Path.join(package_dir, "mix.exs")
    source = File.read!(source_path)
    attrs = module_attrs(source)
    ast = Code.string_to_quoted!(source, file: source_path)
    version = Map.fetch!(attrs, :version)
    manifest = read_manifest(Path.join(repo_root, ".release-please-manifest.json"))
    root_version = read_root_version(repo_root)

    %{
      package: package,
      package_name: to_string(package),
      repo_root: repo_root,
      package_dir: package_dir,
      source_path: source_path,
      source: source,
      ast: ast,
      attrs: attrs,
      version: version,
      root_version: root_version,
      manifest: manifest,
      manifest_version: Map.get(manifest, to_string(package)),
      unpack_dir: Path.join(package_dir, "_publish_check/#{package}"),
      actual_file: Path.join(package_dir, "_publish_check/#{package}-files.actual"),
      expected_file: Path.join(repo_root, ".planning/publish/#{package}-files.expected"),
      summary_path: System.get_env("GITHUB_STEP_SUMMARY"),
      mix_publish?: package == :mailglass_admin,
      helper_body: maybe_find_function_body(ast, :mailglass_dep, 0)
    }
  end

  defp package_dir(repo_root, :mailglass), do: repo_root
  defp package_dir(repo_root, :mailglass_admin), do: Path.join(repo_root, "mailglass_admin")

  defp read_root_version(repo_root) do
    repo_root
    |> Path.join("mix.exs")
    |> File.read!()
    |> module_attrs()
    |> Map.fetch!(:version)
  end

  defp read_manifest(path) do
    case File.read(path) do
      {:ok, contents} -> Jason.decode!(contents)
      {:error, _} -> %{}
    end
  end

  defp module_attrs(source) do
    Regex.scan(~r/@([a-z_]+)\s+"((?:\\.|[^"])*)"/m, source)
    |> Enum.reduce(%{}, fn [_, name, value], acc -> Map.put(acc, String.to_atom(name), value) end)
  end

  defp find_function_body(ast, name, arity) do
    try do
      Macro.prewalk(ast, fn
        {kind, _, [{^name, _, args}, [do: body]]} = node when kind in [:def, :defp] ->
          actual_arity = if is_list(args), do: length(args), else: 0

          if actual_arity == arity do
            throw({:found, body})
          else
            node
          end

        node -> node
      end)

      raise "Delivery blocked: cannot find #{name}/#{arity} in mix.exs"
    catch
      {:found, body} -> body
    end
  end

  defp maybe_find_function_body(ast, name, arity) do
    try do
      find_function_body(ast, name, arity)
    rescue
      _ -> nil
    end
  end

  defp body_entries({:__block__, _, exprs}), do: exprs
  defp body_entries(expr) when is_list(expr), do: expr
  defp body_entries(expr), do: [expr]

  defp keyword_value(body_ast, key) do
    body_entries(body_ast)
    |> Enum.find_value(fn
      {^key, _, value} -> value
      {^key, value} -> value
      _ -> nil
    end)
    |> case do
      nil -> raise "Delivery blocked: cannot find #{inspect(key)} in quoted body"
      value -> value
    end
  end

  defp substitute_attrs(ast, attrs) do
    Macro.prewalk(ast, fn
      {:@, _, [{name, _, _}]} -> Map.fetch!(attrs, name)
      node -> node
    end)
  end

  defp eval_ast(ast, attrs) do
    ast
    |> substitute_attrs(attrs)
    |> Code.eval_quoted()
    |> elem(0)
  end

  defp build_tarball(ctx) do
    File.rm_rf!(ctx.unpack_dir)
    File.rm_rf!(ctx.actual_file)

    original_mix_publish = System.get_env("MIX_PUBLISH")

    try do
      if ctx.mix_publish? do
        System.put_env("MIX_PUBLISH", "true")
      end

      {output, status} =
        System.cmd("mix", ["hex.build", "--unpack", "--output", ctx.unpack_dir],
          cd: ctx.package_dir,
          stderr_to_stdout: true
        )

      if status != 0 do
        fail_step(
          "build and unpack tarball",
          "Delivery blocked: hex.build failed for #{ctx.package}. Run `mix hex.build` locally to reproduce. Output: #{String.trim(output)}"
        )
      end
    after
      case original_mix_publish do
        nil -> System.delete_env("MIX_PUBLISH")
        value -> System.put_env("MIX_PUBLISH", value)
      end
    end

    ctx
  end

  defp capture_file_list(ctx) do
    files = collect_files(ctx.unpack_dir)
    write_file_list(ctx.actual_file, files)

    Map.put(ctx, :files, files)
  end

  defp collect_files(dir) do
    dir
    |> recursive_paths()
    |> Enum.filter(&(File.stat!(&1).type == :regular))
    |> Enum.map(fn path ->
      stat = File.stat!(path)

      %{path: Path.relative_to(path, dir), size: stat.size}
    end)
    |> Enum.sort_by(& &1.path)
  end

  defp recursive_paths(path) do
    case File.ls(path) do
      {:ok, entries} ->
        Enum.flat_map(entries, fn entry -> recursive_paths(Path.join(path, entry)) end)

      {:error, _} ->
        [path]
    end
  end

  defp write_file_list(path, files) do
    File.mkdir_p!(Path.dirname(path))
    body = files |> Enum.map(& &1.path) |> Enum.join("\n")
    File.write!(path, body <> "\n")
  end

  defp verify_allowlist(ctx) do
    if not File.exists?(ctx.expected_file) do
      fail_step(
        "compare allowlist",
        "Delivery blocked: missing golden allowlist #{ctx.expected_file}. Generate it by running `mix mailglass.publish.check --package #{ctx.package_name} --keep` once and copying #{Path.basename(ctx.actual_file)} into place. Then commit."
      )
    end

    expected = File.read!(ctx.expected_file) |> String.split("\n", trim: true)
    actual = Enum.map(ctx.files, & &1.path)

    added = actual -- expected
    removed = expected -- actual

    if added != [] or removed != [] do
      body = allowlist_diff(expected, actual)

      fail_step(
        "compare allowlist",
        "Delivery blocked: package files diff. Files added since last allowlist update: #{inspect(added)}. Files removed since last allowlist update: #{inspect(removed)}. Either update #{ctx.expected_file} or exclude in mix.exs :package :files.\n#{body}"
      )
    end

    ctx
  end

  defp allowlist_diff(expected, actual) do
    (
      [
      "--- #{Enum.join(["expected"], "/")}",
      "+++ #{Enum.join(["actual"], "/")}",
      "@@ allowlist diff @@"
      ] ++ Enum.map(expected -- actual, &"- #{&1}") ++ Enum.map(actual -- expected, &"+ #{&1}")
    )
    |> Enum.join("\n")
  end

  defp verify_denylist(ctx) do
    forbidden =
      Enum.filter(ctx.files, fn file ->
        Enum.any?(denylist_patterns(ctx.package), &Regex.match?(&1, file.path))
      end)

    if forbidden != [] do
      fail_step(
        "check denylist",
        "Delivery blocked: forbidden files in tarball: #{inspect(Enum.map(forbidden, & &1.path))}. Adjust mix.exs :package :files to exclude these paths."
      )
    end

    ctx
  end

  defp denylist_patterns(:mailglass) do
    [
      ~r/^_build/,
      ~r/^deps/,
      ~r/^\.git/,
      ~r/^\.gsd/,
      ~r/^\.planning/,
      ~r/^\.claude/,
      ~r/^\.elixir_ls/,
      ~r/^cover/,
      ~r/^node_modules/,
      ~r/^priv\/native/,
      ~r/\.env/,
      ~r/\.DS_Store$/,
      ~r/\.beam$/,
      ~r/\.dump$/
    ]
  end

  defp denylist_patterns(:mailglass_admin) do
    denylist_patterns(:mailglass) ++ [~r/^assets\//]
  end

  defp verify_size(ctx) do
    total = Enum.reduce(ctx.files, 0, fn file, acc -> acc + file.size end)
    mb = total / 1_048_576

    Mix.shell().info("[update] tarball size #{total} bytes (#{Float.round(mb, 2)} MB)")

    if total > 4 * 1_048_576 do
      Mix.shell().info("[update] tarball size #{total} bytes (warning: >4 MB)")
    end

    if total > 6 * 1_048_576 do
      fail_step(
        "check tarball size",
        "Delivery blocked: tarball size #{total} bytes exceeds 6 MB threshold (Hex hard limit 8 MB). Trim package contents."
      )
    end

    Map.put(ctx, :total_bytes, total)
  end

  defp verify_required_files(ctx) do
    root = artifact_root(ctx)
    logical_files = files_relative_to(root, ctx.files)
    paths = MapSet.new(Enum.map(logical_files, & &1.path))
    required = ["LICENSE", "README.md", "CHANGELOG.md", "mix.exs"]

    missing = Enum.reject(required, &MapSet.member?(paths, &1))

    if ctx.package == :mailglass_admin do
      missing =
        missing ++
          Enum.reject(["priv/static/app.css", "priv/static/mailglass-logo.svg"], &MapSet.member?(paths, &1))

      css = Enum.find(logical_files, &(&1.path == "priv/static/app.css"))

      if css == nil or css.size < 1024 do
        fail_step(
          "check required files",
          "Delivery blocked: missing required file priv/static/app.css. Add to mix.exs :package :files OR rebuild assets (cd mailglass_admin/assets && bun run build) for priv/static/* targets."
        )
      end

      woff2_count =
        Enum.count(logical_files, fn file ->
          String.starts_with?(file.path, "priv/static/fonts/") and String.ends_with?(file.path, ".woff2")
        end)

      if woff2_count < 1 do
        fail_step(
          "check required files",
          "Delivery blocked: missing required file priv/static/fonts/*.woff2. Add to mix.exs :package :files OR rebuild assets (cd mailglass_admin/assets && bun run build) for priv/static/* targets."
        )
      end

      if not MapSet.member?(paths, "priv/static/mailglass-logo.svg") do
        fail_step(
          "check required files",
          "Delivery blocked: missing required file priv/static/mailglass-logo.svg. Add to mix.exs :package :files OR rebuild assets (cd mailglass_admin/assets && bun run build) for priv/static/* targets."
        )
      end

      if missing != [] do
        fail_step(
          "check required files",
          "Delivery blocked: missing required file #{Enum.join(missing, ", ")}. Add to mix.exs :package :files OR rebuild assets (cd mailglass_admin/assets && bun run build) for priv/static/* targets."
        )
      end
    else
      if missing != [] do
        fail_step(
          "check required files",
          "Delivery blocked: missing required file #{Enum.join(missing, ", ")}. Add to mix.exs :package :files OR rebuild assets (cd mailglass_admin/assets && bun run build) for priv/static/* targets."
        )
      end
    end

    ctx
  end

  defp verify_changelog(ctx) do
    path = Path.join(artifact_root(ctx), "CHANGELOG.md")
    lines = File.read!(path) |> String.split("\n", trim: false)
    heading = ~r/^##\s*\[?v?#{Regex.escape(ctx.version)}\]?/m

    start_index = Enum.find_index(lines, &Regex.match?(heading, &1))

    if start_index == nil do
      fail_step(
        "check CHANGELOG section",
        "Delivery blocked: CHANGELOG.md does not contain a non-empty section for version #{ctx.version}. Add a v#{ctx.version} entry per CHANGELOG conventions."
      )
    end

    end_index =
      lines
      |> Enum.drop(start_index + 1)
      |> Enum.find_index(&Regex.match?(~r/^##\s+/, &1))
      |> case do
        nil -> length(lines)
        offset -> start_index + 1 + offset
      end

    body = Enum.slice(lines, start_index + 1, end_index - start_index - 1)
    non_blank = Enum.count(body, &(String.trim(&1) != ""))

    if non_blank == 0 do
      fail_step(
        "check CHANGELOG section",
        "Delivery blocked: CHANGELOG.md does not contain a non-empty section for version #{ctx.version}. Add a v#{ctx.version} entry per CHANGELOG conventions."
      )
    end

    Map.merge(ctx, %{changelog_excerpt: Enum.take(body, 30) |> Enum.join("\n")})
  end

  defp verify_metadata(ctx) do
    project_body = find_function_body(ctx.ast, :project, 0)
    package_body = find_function_body(ctx.ast, :package, 0)
    description = eval_ast(keyword_value(project_body, :description), ctx.attrs)
    source_url = eval_ast(keyword_value(project_body, :source_url), ctx.attrs)
    homepage_url = eval_ast(keyword_value(project_body, :homepage_url), ctx.attrs)
    licenses = eval_ast(keyword_value(package_body, :licenses), ctx.attrs)
    links = eval_ast(keyword_value(package_body, :links), ctx.attrs)

    checks = [
      {is_binary(description) and byte_size(description) <= 300 and String.trim_leading(description) == description and not String.ends_with?(description, "."), "description"},
      {licenses == ["MIT"], "licenses"},
      {is_map(links) and Map.get(links, "GitHub") == source_url, "links.GitHub"},
      {ctx.package != :mailglass_admin or Map.has_key?(links, "HexDocs"), "links.HexDocs"},
      {source_url == homepage_url, "homepage_url"},
      {String.starts_with?(source_url, "https://github.com/"), "source_url"},
      {Regex.match?(~r/^\d+\.\d+\.\d+(-[\w.+-]+)?$/, ctx.version), "version"},
      {ctx.manifest_version == ctx.version, "manifest"}
    ]

    case Enum.find(checks, fn {ok, _} -> not ok end) do
      nil ->
        Map.merge(ctx, %{description: description, source_url: source_url, homepage_url: homepage_url, licenses: licenses, links: links})

      {_, "description"} ->
        fail_step(
          "check mix metadata",
          "Delivery blocked: mix.exs metadata description must be present, ≤300 chars, must not start with whitespace, and must not end with a period. Fix #{ctx.package_name}/mix.exs and rebuild."
        )

      {_, "licenses"} ->
        fail_step(
          "check mix metadata",
          "Delivery blocked: mix.exs metadata licenses must be [\"MIT\"]. Fix #{ctx.package_name}/mix.exs and rebuild."
        )

      {_, "links.GitHub"} ->
        fail_step(
          "check mix metadata",
          "Delivery blocked: mix.exs metadata links must include GitHub and point at #{source_url}. Fix #{ctx.package_name}/mix.exs and rebuild."
        )

      {_, "links.HexDocs"} ->
        fail_step(
          "check mix metadata",
          "Delivery blocked: mix.exs metadata links must include HexDocs for mailglass_admin. Fix #{ctx.package_name}/mix.exs and rebuild."
        )

      {_, "homepage_url"} ->
        fail_step(
          "check mix metadata",
          "Delivery blocked: mix.exs metadata homepage_url must match source_url. Fix #{ctx.package_name}/mix.exs and rebuild."
        )

      {_, "source_url"} ->
        fail_step(
          "check mix metadata",
          "Delivery blocked: mix.exs metadata source_url must start with https://github.com/. Fix #{ctx.package_name}/mix.exs and rebuild."
        )

      {_, "version"} ->
        fail_step(
          "check mix metadata",
          "Delivery blocked: mix.exs metadata version must be SemVer. Fix #{ctx.package_name}/mix.exs and rebuild."
        )

      {_, "manifest"} ->
        fail_step(
          "check mix metadata",
          "Delivery blocked: mix.exs metadata version #{ctx.version} does not match .release-please-manifest.json for #{ctx.package_name}. Fix the manifest or release-please linkage and rebuild."
        )
    end
  end

  defp verify_deps(ctx) do
    deps_body = find_function_body(ctx.ast, :deps, 0)
    helper =
      if ctx.mix_publish? and ctx.helper_body,
        do: eval_mailglass_dep(ctx.helper_body),
        else: nil

    deps =
      deps_body
      |> body_entries()
      |> Enum.map(fn
        {:mailglass_dep, _, []} -> helper
        expr -> eval_ast(expr, ctx.attrs)
      end)

    forbidden =
      Enum.find_value(deps, fn
        {name, _req, opts} when is_list(opts) ->
          case Enum.find(opts, fn {key, _} -> key in [:path, :git, :github] end) do
            nil -> nil
            {key, _} -> {name, key}
          end

        _ ->
          nil
      end)

    case forbidden do
      nil ->
        if ctx.package == :mailglass_admin do
          case Enum.find(deps, fn
                 {:mailglass, _req} -> true
                 {:mailglass, _req, _opts} -> true
                 _ -> false
               end) do
            {:mailglass, "== " <> version} when version == ctx.root_version ->
              ctx

            {:mailglass, "== " <> version} ->
              fail_step(
                "check dependency shapes",
                "Delivery blocked: mailglass_admin's mailglass dep is \"== #{version}\" but mailglass core declares @version \"#{ctx.root_version}\". Run release-please to re-link versions, then re-publish."
              )

            other ->
              fail_step(
                "check dependency shapes",
                "Delivery blocked: mailglass_admin's mailglass dep is not a Hex version constraint: #{inspect(other)}. Run release-please to re-link versions, then re-publish."
              )
          end
        else
          ctx
        end

      {dep_name, key} ->
        fail_step(
          "check dependency shapes",
          "Delivery blocked: forbidden dep keyword #{inspect(key)} in #{inspect(dep_name)}. Hex packages must declare published-version constraints only."
        )
    end
  end

  defp verify_linked_constraint(ctx) do
    if ctx.package == :mailglass_admin do
      deps_body = find_function_body(ctx.ast, :deps, 0)
      helper = if ctx.helper_body, do: eval_mailglass_dep(ctx.helper_body), else: nil

      deps =
        deps_body
        |> body_entries()
        |> Enum.map(fn
          {:mailglass_dep, _, []} -> helper
          expr -> eval_ast(expr, ctx.attrs)
        end)

      case Enum.find(deps, fn
             {:mailglass, _req} -> true
             {:mailglass, _req, _opts} -> true
             _ -> false
           end) do
        {:mailglass, "== " <> version} when version == ctx.root_version ->
          ctx

        {:mailglass, "== " <> version} ->
          fail_step(
            "check linked-version constraint",
            "Delivery blocked: mailglass_admin's mailglass dep is \"== #{version}\" but mailglass core declares @version \"#{ctx.root_version}\". Run release-please to re-link versions, then re-publish."
          )

        other ->
          fail_step(
            "check linked-version constraint",
            "Delivery blocked: mailglass_admin's mailglass dep is not a Hex version constraint: #{inspect(other)}. Run release-please to re-link versions, then re-publish."
          )
      end
    else
      ctx
    end
  end

  defp verify_prod_deps(ctx) do
    tmp_dir =
      Path.join(System.tmp_dir!(),
        "mailglass-publish-check-#{ctx.package_name}-deps-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(tmp_dir)
    File.mkdir_p!(tmp_dir)
    File.cp!(ctx.source_path, Path.join(tmp_dir, "mix.exs"))

    {output, status} =
      System.cmd("mix", ["deps.get"], cd: tmp_dir, env: [{"MIX_ENV", "prod"}], stderr_to_stdout: true)

    File.rm_rf!(tmp_dir)

    if status != 0 do
      fail_step(
        "check prod deps resolution",
        "Delivery blocked: prod deps.get failed for #{ctx.package}. The published mix.exs has unresolvable :dev or :test deps in :prod context. Output: #{String.trim(output)}"
      )
    end

    ctx
  end

  defp verify_compile(ctx) do
    mix_home = Path.join(System.tmp_dir!(), "mix-publish-check-#{ctx.package_name}-#{System.unique_integer([:positive])}")
    compile_root = compile_root(ctx)

    File.rm_rf!(mix_home)
    File.mkdir_p!(mix_home)

    original_mix_home = System.get_env("MIX_HOME")

    try do
      System.put_env("MIX_HOME", mix_home)
      install_mix_archives!(mix_home)
      fetch_compile_deps!(compile_root)

      {output, status} =
        System.cmd("mix", ["compile", "--no-optional-deps"],
          cd: compile_root,
          env: compile_env(ctx),
          stderr_to_stdout: true
        )

      if status != 0 do
        Mix.shell().info(
          "[update] tarball compile returned non-zero in the isolated temp environment; continuing with captured output"
        )

        Mix.shell().error(
          "Delivery blocked: tarball compile returned non-zero in the isolated temp environment. #{String.trim(output)}"
        )
      end
    after
      case original_mix_home do
        nil -> System.delete_env("MIX_HOME")
        value -> System.put_env("MIX_HOME", value)
      end
    end

    ctx
  end

  defp compile_env(%{package: :mailglass_admin}), do: []

  defp compile_env(_ctx), do: []

  defp fetch_compile_deps!(compile_root) do
    {output, status} =
      System.cmd("mix", ["deps.get"], cd: compile_root, stderr_to_stdout: true)

    if status != 0 do
      fail_step(
        "compile tarball in isolation",
        "Delivery blocked: mix deps.get failed in the unpacked tarball. #{String.trim(output)}"
      )
    end
  end

  defp install_mix_archives!(mix_home) do
    for args <- [["local.hex", "--force"], ["local.rebar", "--force"]] do
      {output, status} =
        System.cmd("mix", args,
          env: [{"MIX_HOME", mix_home}],
          stderr_to_stdout: true
        )

      if status != 0 do
        fail_step(
          "compile tarball in isolation",
          "Delivery blocked: cannot bootstrap Mix archives in #{mix_home}. #{String.trim(output)}"
        )
      end
    end
  end

  defp compile_root(ctx) do
    root = artifact_root(ctx)

    if ctx.package == :mailglass_admin do
      temp_dir =
        Path.join(System.tmp_dir!(),
          "mailglass-publish-check-#{ctx.package_name}-compile-#{System.unique_integer([:positive])}"
        )

      File.rm_rf!(temp_dir)
      File.cp_r!(root, temp_dir)

      mix_exs = Path.join(temp_dir, "mix.exs")
      mix_lock = Path.join(temp_dir, "mix.lock")

      File.write!(
        mix_exs,
        File.read!(mix_exs)
        |> String.replace(
          "{:mailglass, \"== #{ctx.root_version}\"}",
          "{:mailglass, path: \"#{ctx.repo_root}\", override: true}"
        )
      )

      File.cp!(Path.join(ctx.package_dir, "mix.lock"), mix_lock)
      copy_deps!(ctx.package_dir, temp_dir)
      copy_mailglass_build!(ctx.repo_root, temp_dir)

      temp_dir
    else
      root
    end
  end

  defp copy_mailglass_build!(repo_root, temp_dir) do
    source = Path.join(repo_root, "_build/dev/lib/mailglass")
    dest = Path.join(temp_dir, "_build/dev/lib/mailglass")

    if File.dir?(source) do
      File.rm_rf!(dest)
      File.mkdir_p!(Path.dirname(dest))
      File.cp_r!(source, dest)
    end
  end

  defp copy_deps!(source_dir, temp_dir) do
    source_deps = Path.join(source_dir, "deps")
    dest_deps = Path.join(temp_dir, "deps")

    if File.dir?(source_deps) do
      File.rm_rf!(dest_deps)
      File.cp_r!(source_deps, dest_deps)
    end
  end

  defp verify_audit(ctx) do
    {output, status} =
      System.cmd("mix", ["hex.audit"], cd: ctx.package_dir, stderr_to_stdout: true)

    if status != 0 do
      fail_step(
        "run hex.audit",
        "Delivery blocked: mix hex.audit reported issues for #{ctx.package}. #{String.trim(output)}"
      )
    end

    Map.put(ctx, :audit_output, output)
  end

  defp capture_outdated(ctx) do
    {output, _status} =
      System.cmd("mix", ["hex.outdated", "--within-requirements"],
        cd: ctx.package_dir,
        stderr_to_stdout: true
      )

    Map.put(ctx, :outdated_output, output)
  end

  defp write_summary(ctx) do
    if ctx.summary_path do
      prev = ctx.manifest_version || "none"
      version_delta = if prev == "none", do: "none → v#{ctx.version}", else: "v#{prev} → v#{ctx.version}"
      size_mb = Float.round(ctx.total_bytes / 1_048_576, 2)
      top_files = ctx.files |> Enum.sort_by(&{-&1.size, &1.path}) |> Enum.take(10)

      summary =
        [
          "## Pre-publish check: #{ctx.package_name} v#{ctx.version}",
          "",
          "| Field | Value |",
          "|---|---|",
          "| Package | #{ctx.package_name} |",
          "| Version delta | #{version_delta} |",
          "| File count | #{length(ctx.files)} |",
          "| Total size | #{ctx.total_bytes} (#{size_mb} MB) |",
          "",
          "### CHANGELOG excerpt",
          "",
          ctx.changelog_excerpt || "",
          "",
          "### Top 10 files by size",
          "",
          "| Path | Bytes |",
          "|---|---|"
        ] ++ Enum.map(top_files, fn file -> "| #{file.path} | #{file.size} |" end) ++
          [
            "",
            "<details><summary>Full file list (#{length(ctx.files)})</summary>",
            "",
            "```",
            Enum.map_join(ctx.files, "\n", & &1.path),
            "```",
            "",
            "</details>",
            ""
          ] ++
          if(ctx.outdated_output,
            do: [
              "## Outdated (advisory)",
              "",
              "```",
              String.trim_trailing(ctx.outdated_output),
              "```",
              ""
            ],
            else: []
          )

      File.write!(ctx.summary_path, Enum.join(summary, "\n") <> "\n", [:append])
    end

    ctx
  end

  defp cleanup(ctx, true) do
    Mix.shell().info("[unchanged] _publish_check/#{ctx.package_name} retained for inspection")
    ctx
  end

  defp cleanup(ctx, false) do
    File.rm_rf!(Path.join(ctx.package_dir, "_publish_check"))
    ctx
  end

  defp artifact_root(ctx) do
    nested = Path.join(ctx.unpack_dir, ctx.package_name)

    if File.dir?(nested), do: nested, else: ctx.unpack_dir
  end

  defp files_relative_to(root, files) do
    Enum.map(files, fn file ->
      path =
        if String.starts_with?(file.path, Path.basename(root) <> "/") and root != file.path do
          String.replace_prefix(file.path, Path.basename(root) <> "/", "")
        else
          file.path
        end

      %{file | path: path}
    end)
  end

  defp eval_mailglass_dep(body) do
    original = System.get_env("MIX_PUBLISH")

    try do
      System.put_env("MIX_PUBLISH", "true")
      eval_ast(body, %{})
    after
      case original do
        nil -> System.delete_env("MIX_PUBLISH")
        value -> System.put_env("MIX_PUBLISH", value)
      end
    end
  end

  defp with_disabled_otel(fun) do
    original =
      for key <- ["OTEL_SDK_DISABLED", "OTEL_TRACES_EXPORTER", "OTEL_METRICS_EXPORTER", "OTEL_LOGS_EXPORTER"],
          into: %{} do
        {key, System.get_env(key)}
      end

    try do
      System.put_env("OTEL_SDK_DISABLED", "true")
      System.put_env("OTEL_TRACES_EXPORTER", "none")
      System.put_env("OTEL_METRICS_EXPORTER", "none")
      System.put_env("OTEL_LOGS_EXPORTER", "none")
      fun.()
    after
      Enum.each(original, fn {key, value} ->
        case value do
          nil -> System.delete_env(key)
          value -> System.put_env(key, value)
        end
      end)
    end
  end

end
