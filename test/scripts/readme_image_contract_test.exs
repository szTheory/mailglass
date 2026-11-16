defmodule Mailglass.Scripts.ReadmeImageContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @readme Path.join(@repo_root, "README.md")
  @checker Path.join(@repo_root, "scripts/brand_docs_check.exs")

  setup_all do
    Application.put_env(:mailglass, :script_library_mode, true)
    Code.require_file(@checker)
    :ok
  end

  @tag :core
  test "core README has one lowercase heading, immutable theme lockups, and a separate tagline" do
    assert [] == docs_check(:readme_issues, [File.read!(@readme)])
  end

  @tag :core
  test "wrong image host, path, ref, and relative paths each fail the URL contract" do
    readme = File.read!(@readme)
    [light, dark] = theme_urls()

    for replacement <- [
          {"raw.githubusercontent.com", "example.com"},
          {"/7781b4b1ceeca940e5f892530b1cf05430b54d7c/", "/main/"},
          {"mailglass-lockup-light.svg", "mailglass-lockup-other.svg"},
          {light, "../brandbook/v2/mailglass-lockup-light.svg"},
          {dark, "../brandbook/v2/mailglass-lockup-dark.svg"}
        ] do
      changed = String.replace(readme, elem(replacement, 0), elem(replacement, 1), global: false)
      assert :wrong_or_misordered_theme_urls in docs_check(:readme_issues, [changed])
    end
  end

  @tag :core
  test "missing images, missing alt text, and unsupported picture markup fail with named reasons" do
    readme = File.read!(@readme)

    assert :wrong_image_count in docs_check(:readme_issues, [
             String.replace(readme, ~r/<img[^>]+>\s*/s, "", global: false)
           ])

    assert :wrong_or_missing_alt in docs_check(:readme_issues, [
             String.replace(readme, "alt=\"mailglass\"", "", global: false)
           ])

    assert :unsupported_picture_markup in docs_check(:readme_issues, [
             String.replace(readme, "<p align=\"center\">", "<picture>", global: false)
           ])
  end

  @tag :core
  test "distorted or too-small lockups fail the responsive geometry contract" do
    readme = File.read!(@readme)

    for replacement <- [
          {"width=\"580\"", "width=\"48\""},
          {"max-width:100%", "width:100%;object-fit:cover"},
          {"height:auto", "height:120px"}
        ] do
      changed = String.replace(readme, elem(replacement, 0), elem(replacement, 1), global: false)
      assert :invalid_image_dimensions in docs_check(:readme_issues, [changed])
    end
  end

  @tag :core
  test "the immutable asset commit blobs equal the current shipped pin bytes" do
    pin = File.read!(Path.join(@repo_root, "brandbook/brand.pin.json")) |> Jason.decode!()

    for path <- [
          "brandbook/v2/mailglass-lockup-light.svg",
          "brandbook/v2/mailglass-lockup-dark.svg"
        ] do
      entry = Enum.find(pin["shipped"], &(&1["to"] == path))

      {blob, 0} =
        System.cmd("git", ["show", "7781b4b1ceeca940e5f892530b1cf05430b54d7c:#{path}"],
          cd: @repo_root
        )

      assert byte_size(blob) == entry["bytes"]
      assert :crypto.hash(:sha256, blob) |> Base.encode16(case: :lower) == entry["sha256"]
      assert blob == File.read!(Path.join(@repo_root, path))
    end
  end

  defp theme_urls do
    [light, dark] =
      Regex.scan(~r/<img\b[^>]*\bsrc=["']([^"']+)["']/i, File.read!(@readme),
        capture: :all_but_first
      )
      |> Enum.map(&hd/1)

    [light, dark]
  end

  defp docs_check(function, args),
    do: apply(Module.concat(["Mailglass", "BrandDocsCheck"]), function, args)
end
