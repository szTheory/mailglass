defmodule Mailglass.Scripts.BrandDocsContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @checker Path.join(@repo_root, "scripts/brand_docs_check.exs")
  @trademark_gate Path.join(@repo_root, "scripts/brand_trademark_gate.exs")

  setup_all do
    Application.put_env(:mailglass, :script_library_mode, true)
    Code.require_file(@checker)
    Code.require_file(@trademark_gate)
    :ok
  end

  @tag :core
  test "real core generated output contains pinned media and native ExDoc behavior" do
    assert {:ok, %{package: "core"}} =
             docs_check(:verify_output, [Path.join(@repo_root, "doc"), "core"])
  end

  @tag :core
  @tag :tmp_dir
  test "a generated-output fixture passes without a server or network", %{tmp_dir: tmp_dir} do
    fixture_output!(tmp_dir)
    assert {:ok, _result} = docs_check(:verify_output, [Path.join(tmp_dir, "doc"), "core"])
  end

  @tag :core
  @tag :tmp_dir
  test "missing or pin-mismatched media is rejected", %{tmp_dir: tmp_dir} do
    fixture_output!(tmp_dir)
    File.rm!(Path.join(tmp_dir, "doc/assets/favicon.svg"))

    assert {:error, issues} = docs_check(:verify_output, [Path.join(tmp_dir, "doc"), "core"])
    assert {:missing_or_unreadable_asset, "assets/favicon.svg"} in issues
  end

  @tag :core
  test "custom CSS rejects layout, font, link, OS-scheme, and non-syntax changes" do
    assert [] =
             docs_check(:syntax_css_issues, [
               File.read!(Path.join(@repo_root, "brandbook/exdoc/code-colors.css"))
             ])

    for css <- [
          "body { color: red; }",
          ".makeup .k { font-family: serif; }",
          ".makeup .k { color: red; } @media (prefers-color-scheme: dark) { .makeup .k { color: blue; } }"
        ] do
      assert docs_check(:syntax_css_issues, [css]) != []
    end
  end

  @tag :core
  test "pinned image bytes reject corruption" do
    bytes = File.read!(Path.join(@repo_root, "brandbook/v2/mailglass-lockup-light.svg"))

    refute docs_check(:pinned_bytes_match?, [
             "brandbook/v2/mailglass-lockup-light.svg",
             binary_part(bytes, 0, byte_size(bytes) - 1)
           ])
  end

  defp fixture_output!(root) do
    docs = Path.join(root, "doc")
    assets = Path.join(docs, "assets")
    dist = Path.join(docs, "dist")
    File.mkdir_p!(assets)
    File.mkdir_p!(dist)

    copy_asset!("brandbook/v2/mailglass-mark-light.svg", Path.join(assets, "logo.svg"))

    copy_asset!(
      "brandbook/v2/mailglass-mark-dark.svg",
      Path.join(assets, "mailglass-mark-dark.svg")
    )

    copy_asset!("brandbook/v2/favicon.svg", Path.join(assets, "favicon.svg"))

    File.cp!(
      Path.join(@repo_root, "brandbook/exdoc/code-colors.css"),
      Path.join(assets, "code-colors.css")
    )

    File.cp!(
      Path.join(@repo_root, "brandbook/exdoc/theme-mark.js"),
      Path.join(assets, "theme-mark.js")
    )

    File.write!(
      Path.join(dist, "html-elixir-fixture.css"),
      "body { font-family: Lato; } body.dark .content-inner img[src*=\\\"#gh-light-mode-only\\\"] { display: none; } body:not(.dark) .content-inner img[src*=\\\"#gh-dark-mode-only\\\"] { display: none; }"
    )

    readme = File.read!(Path.join(@repo_root, "README.md"))
    image_tags = Regex.scan(~r/<img\b[^>]*>/i, readme) |> List.flatten() |> Enum.join("\n")

    File.write!(
      Path.join(docs, "README.html"),
      "<html><head><link rel=\"stylesheet\" href=\"assets/code-colors.css\"></head>" <>
        "<body><script defer src=\"assets/theme-mark.js\"></script><h1>mailglass</h1>#{image_tags}</body></html>"
    )
  end

  defp copy_asset!(source, destination) do
    File.cp!(Path.join(@repo_root, source), destination)
  end

  defp docs_check(function, args),
    do: apply(Module.concat(["Mailglass", "BrandDocsCheck"]), function, args)
end
