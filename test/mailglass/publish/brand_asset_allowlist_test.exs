defmodule Mailglass.Publish.BrandAssetAllowlistTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../../..", __DIR__)
  @packages [
    {"mailglass", "", false},
    {"mailglass_admin", "mailglass_admin", true},
    {"mailglass_inbound", "mailglass_inbound", true}
  ]
  @font_files ~w(a-display-600.woff2 a-mono-400.woff2 a-mono-600.woff2 ui-400.woff2 ui-400i.woff2 ui-600.woff2)
  @ofl_files ~w(OFL-AtkinsonHyperlegibleMono.txt OFL-AtkinsonHyperlegibleNext.txt OFL-FunnelDisplay.txt)
  @forbidden_roots ~w(brandbook reference .planning catalog)
  @admin_brand_files MapSet.new(
                       Enum.map(@font_files, &"priv/static/fonts/#{&1}") ++
                         Enum.map(@ofl_files, &"priv/static/fonts/#{&1}") ++
                         ["priv/static/favicon.svg", "priv/static/mailglass-logo.svg"]
                     )

  setup_all do
    tmp_root =
      Path.join(System.tmp_dir!(), "mailglass-brand-payload-#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp_root)

    unpacked =
      Map.new(@packages, fn {package, dir, publish?} ->
        source_dir = Path.join(@repo_root, dir)
        output_dir = Path.join(tmp_root, package)
        env = if publish?, do: [{"MIX_PUBLISH", "true"}], else: []

        {output, status} =
          System.cmd("mix", ["hex.build", "--unpack", "--output", output_dir],
            cd: source_dir,
            env: env,
            stderr_to_stdout: true
          )

        if status != 0 do
          raise "could not build actual #{package} Hex payload (#{status}):\n#{output}"
        end

        {package, output_dir}
      end)

    on_exit(fn -> File.rm_rf!(tmp_root) end)
    {:ok, unpacked: unpacked}
  end

  test "actual tarballs match reviewed package goldens and every golden path is digest-covered", %{
    unpacked: unpacked
  } do
    for {package, _dir, _publish?} <- @packages do
      actual = package_files(Map.fetch!(unpacked, package))
      golden = read_golden(package)

      assert actual == golden,
             "#{package} actual unpacked Hex payload differs from .planning/publish/#{package}-files.expected"

      uncovered = Enum.reject(golden, &digest_covered?(package, &1))

      assert uncovered == [],
             "release content digest does not select #{package} paths: #{inspect(uncovered)}"

      assert Enum.filter(actual, &forbidden_path?/1) == [],
             "#{package} ships forbidden source/evidence paths"
    end
  end

  test "the actual Admin tarball contains exactly the pin-bound fonts, OFL texts, logo and favicon",
       %{unpacked: unpacked} do
    admin_root = Map.fetch!(unpacked, "mailglass_admin")
    actual = package_files(admin_root)
    actual_brand = Enum.filter(actual, &brand_class_path?/1) |> MapSet.new()
    pin = File.read!(Path.join(@repo_root, "brandbook/brand.pin.json")) |> Jason.decode!()

    pinned_font_rows =
      pin["shipped"]
      |> Enum.filter(&String.starts_with?(&1["to"], "mailglass_admin/priv/static/fonts/"))
      |> Enum.map(&String.replace_prefix(&1["to"], "mailglass_admin/", ""))
      |> MapSet.new()

    assert pinned_font_rows ==
             MapSet.new(Enum.map(@font_files ++ @ofl_files, &"priv/static/fonts/#{&1}"))

    assert actual_brand == @admin_brand_files
    assert Enum.count(actual, &String.ends_with?(&1, ".woff2")) == 6
    assert Enum.count(actual, &String.ends_with?(&1, ".txt")) == 3

    for row <-
          Enum.filter(
            pin["shipped"],
            &MapSet.member?(
              pinned_font_rows,
              String.replace_prefix(&1["to"], "mailglass_admin/", "")
            )
          ) do
      path = String.replace_prefix(row["to"], "mailglass_admin/", "")
      assert_pinned_bytes!(Path.join(admin_root, path), row)
    end

    assert_pin_copy!(admin_root, "priv/static/favicon.svg", pin, "brandbook/v2/favicon.svg")

    assert_pin_copy!(
      admin_root,
      "priv/static/mailglass-logo.svg",
      pin,
      "brandbook/v2/mailglass-lockup-light.svg"
    )
  end

  test "core and Inbound ship no brand fonts or source artwork", %{unpacked: unpacked} do
    for package <- ["mailglass", "mailglass_inbound"] do
      paths = package_files(Map.fetch!(unpacked, package))

      assert Enum.filter(paths, &brand_class_path?/1) == [],
             "#{package} unexpectedly contains brand runtime payload"
    end
  end

  test "brand payload validation rejects a missing OFL, a stray font, and source/evidence roots" do
    actual = MapSet.to_list(@admin_brand_files)

    refute valid_admin_brand_set?(actual -- ["priv/static/fonts/OFL-FunnelDisplay.txt"])
    refute valid_admin_brand_set?(actual ++ ["priv/static/fonts/Stray.woff2"])
    refute valid_admin_brand_set?(actual ++ ["brandbook/v2/index.html"])
    refute valid_admin_brand_set?(actual ++ ["priv/static/fonts/stray.ttf"])
    refute valid_admin_brand_set?(actual ++ [".planning/research/favicon-catalog/cell.png"])
  end

  defp package_files(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&Path.relative_to(&1, root))
    |> Enum.sort()
  end

  defp read_golden(package) do
    @repo_root
    |> Path.join(".planning/publish/#{package}-files.expected")
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.sort()
  end

  # Hex synthesizes this payload file from the package's tracked mix.exs. It is
  # not a Git tree entry, so the release digest covers its source declaration.
  defp digest_covered?(package, "hex_metadata.config") do
    "mix.exs" in read_golden(package) and digest_covered?(package, "mix.exs")
  end

  defp digest_covered?("mailglass", path) do
    String.starts_with?(path, ["lib/", "priv/gettext/", "guides/"]) or
      path in ~w(mix.exs LICENSE README.md CHANGELOG.md MAINTAINING.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md)
  end

  defp digest_covered?("mailglass_admin", path) do
    String.starts_with?(path, ["lib/", "priv/static/", "docs/"]) or
      path == ".formatter.exs" or
      String.starts_with?(path, ["mix.exs", "README", "CHANGELOG", "LICENSE"])
  end

  defp digest_covered?("mailglass_inbound", path) do
    String.starts_with?(path, ["lib/", "docs/"]) or
      path == ".formatter.exs" or
      String.starts_with?(path, ["mix.exs", "README", "CHANGELOG", "LICENSE"])
  end

  defp brand_class_path?(path) do
    String.starts_with?(path, "priv/static/fonts/") or
      path in ["priv/static/favicon.svg", "priv/static/mailglass-logo.svg"] or
      forbidden_path?(path)
  end

  defp forbidden_path?(path) do
    Enum.any?(@forbidden_roots, &(path == &1 or String.starts_with?(path, &1 <> "/"))) or
      String.ends_with?(String.downcase(path), [".zip", ".ttf", ".otf"])
  end

  defp valid_admin_brand_set?(paths),
    do: MapSet.new(Enum.filter(paths, &brand_class_path?/1)) == @admin_brand_files

  defp assert_pinned_bytes!(path, row) do
    bytes = File.read!(path)
    assert byte_size(bytes) == row["bytes"], "#{path} size differs from brand pin"
    assert sha256(bytes) == row["sha256"], "#{path} SHA-256 differs from brand pin"
  end

  defp assert_pin_copy!(package_root, package_path, pin, pin_path) do
    source = Path.join(@repo_root, pin_path)
    copy = Path.join(package_root, package_path)
    bytes = File.read!(source)
    row = Enum.find(pin["shipped"], &(&1["to"] == pin_path))

    assert row, "missing pin row for #{pin_path}"
    assert_pinned_bytes!(source, row)
    assert File.read!(copy) == bytes, "#{package_path} is not the byte-identical pinned copy"
  end

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
