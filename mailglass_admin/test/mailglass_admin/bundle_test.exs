defmodule MailglassAdmin.BundleTest do
  @moduledoc """
  RED-by-default coverage for PREV-06 bundle size budget: `priv/static/app.css`
  exists under 150KB, `priv/static/fonts/` contains exactly the six brand v2
  woff2 files (Funnel Display 600, Atkinson Hyperlegible Next 400/600/400
  italic, Atkinson Hyperlegible Mono 400/600) plus the three OFL license
  texts that must ship beside them, the logo is committed, and the total
  `priv/static/` tree is under 800KB (CONTEXT D-23 budget).

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

    test "contains generated Heroicon rules for shared surface navigation" do
      css = File.read!(@css_path)

      for icon <- ~w(hero-check-circle hero-eye hero-paper-airplane hero-inbox-arrow-down) do
        assert css =~ icon,
               "app.css is missing #{icon}; run mix mailglass_admin.assets.build after nav icon changes"
      end
    end
  end

  describe "priv/static/fonts/" do
    test "contains exactly the six brand v2 woff2 files" do
      actual =
        @fonts_dir
        |> File.ls!()
        |> Enum.filter(&String.ends_with?(&1, ".woff2"))
        |> Enum.sort()

      expected = [
        "a-display-600.woff2",
        "a-mono-400.woff2",
        "a-mono-600.woff2",
        "ui-400.woff2",
        "ui-400i.woff2",
        "ui-600.woff2"
      ]

      assert actual == expected,
             "fonts directory must contain exactly the six brand v2 faces (Funnel Display 600, Atkinson Hyperlegible Next 400/600/400 italic, Atkinson Hyperlegible Mono 400/600); got #{inspect(actual)}"
    end

    test "ships the three OFL license texts beside the fonts" do
      actual =
        @fonts_dir
        |> File.ls!()
        |> Enum.filter(&String.starts_with?(&1, "OFL-"))
        |> Enum.sort()

      expected = [
        "OFL-AtkinsonHyperlegibleMono.txt",
        "OFL-AtkinsonHyperlegibleNext.txt",
        "OFL-FunnelDisplay.txt"
      ]

      assert actual == expected,
             "the SIL OFL 1.1 license texts must ship with the fonts; got #{inspect(actual)}"
    end

    test "holds nothing but those nine files" do
      assert @fonts_dir |> File.ls!() |> length() == 9
    end
  end

  describe "priv/static/mailglass-logo.svg" do
    test "exists and is under 20KB" do
      %{size: size} = File.stat!(@logo_path)
      assert size > 0
      assert size < 20_000, "logo.svg is #{size} bytes; budget is <20KB"
    end

    test "is an outlined lockup with no live text or font dependency" do
      logo = File.read!(@logo_path)

      refute logo =~ "<text"
      refute logo =~ "font-family"
      refute logo =~ "letter-spacing"
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
