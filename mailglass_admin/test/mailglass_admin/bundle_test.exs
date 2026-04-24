defmodule MailglassAdmin.BundleTest do
  @moduledoc """
  RED-by-default coverage for PREV-06 bundle size budget: `priv/static/app.css`
  exists under 150KB, `priv/static/fonts/` contains exactly the six locked
  woff2 files (Inter 400/700 + Inter Tight 400/700 + IBM Plex Mono 400/700
  per 05-UI-SPEC lines 71-79 — 2 weights per family, not 3), the logo is
  committed, and the total `priv/static/` tree is under 800KB (CONTEXT D-23
  budget).

  Plan 05 commits the compiled bundle and turns these RED tests green.
  """

  use ExUnit.Case, async: true

  @static_dir Path.join([Application.app_dir(:mailglass_admin, "priv"), "static"])
  @css_path Path.join([@static_dir, "app.css"])
  @fonts_dir Path.join([@static_dir, "fonts"])
  @logo_path Path.join([@static_dir, "mailglass-logo.svg"])

  describe "priv/static/app.css" do
    test "exists and is below the 150KB size budget" do
      %{size: size} = File.stat!(@css_path)
      assert size > 0, "app.css must not be empty"
      assert size < 150_000, "app.css is #{size} bytes; PREV-06 budget is <150KB"
    end
  end

  describe "priv/static/fonts/" do
    test "contains exactly six woff2 files — 2 weights per family" do
      actual =
        @fonts_dir
        |> File.ls!()
        |> Enum.sort()

      expected = [
        "ibm-plex-mono-400.woff2",
        "ibm-plex-mono-700.woff2",
        "inter-400.woff2",
        "inter-700.woff2",
        "inter-tight-400.woff2",
        "inter-tight-700.woff2"
      ]

      assert actual == expected,
             "fonts directory must contain exactly the six locked weights (Inter, Inter Tight, IBM Plex Mono × {400, 700}); got #{inspect(actual)}"
    end
  end

  describe "priv/static/mailglass-logo.svg" do
    test "exists and is under 20KB" do
      %{size: size} = File.stat!(@logo_path)
      assert size > 0
      assert size < 20_000, "logo.svg is #{size} bytes; budget is <20KB"
    end
  end

  describe "total priv/static/ size" do
    test "is under 800KB (CONTEXT D-23 Hex tarball budget)" do
      total = recursive_size(@static_dir)

      assert total < 800_000,
             "priv/static/ total is #{total} bytes; CONTEXT D-23 budget is <800KB"
    end
  end

  # Recursive byte-count sum of every regular file under dir.
  defp recursive_size(dir) do
    dir
    |> File.ls!()
    |> Enum.reduce(0, fn name, acc ->
      path = Path.join(dir, name)

      case File.stat!(path) do
        %{type: :directory} -> acc + recursive_size(path)
        %{size: size} -> acc + size
      end
    end)
  end
end
