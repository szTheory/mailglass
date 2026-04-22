defmodule Mailglass.Components.VmlPreservationTest do
  @moduledoc """
  MANDATORY golden-fixture test for Premailex VML conditional-comment preservation.

  D-14: Premailex must preserve MSO conditional comments
  (`<!--[if mso]>...<![endif]-->`) after CSS inlining. Premailex 0.3.20 preserves
  these by default (PR #37, June 2019). This test guards against regressions from
  Premailex version bumps.

  The golden fixture is a representative email with:
    * An `<!--[if gte mso 9]>` OfficeDocumentSettings block in the head
    * Ghost-table `<!--[if mso]>` openers for a two-column row
    * A VML `<v:roundrect>` bulletproof button
    * An `<!--[if !mso]><!-->` HTML fallback <a>
  """

  use ExUnit.Case, async: true

  @golden_fixture_path Path.join([__DIR__, "..", "..", "fixtures", "vml_golden.html"])

  defp golden_html do
    case File.read(@golden_fixture_path) do
      {:ok, content} ->
        content

      {:error, reason} ->
        flunk("Cannot read golden fixture at #{@golden_fixture_path}: #{inspect(reason)}")
    end
  end

  test "Premailex preserves <!--[if mso]> conditional comments after CSS inlining" do
    html = golden_html()
    inlined = Premailex.to_inline_css(html)

    assert String.contains?(inlined, "<!--[if mso]>"),
           "<!--[if mso]> comment lost after Premailex inlining"

    assert String.contains?(inlined, "<![endif]-->"),
           "<![endif]--> lost after Premailex inlining"

    assert String.contains?(inlined, "<!--[if gte mso 9]>"),
           "<!--[if gte mso 9]> comment lost after Premailex inlining"

    assert String.contains?(inlined, "<!--[if !mso]><!-->"),
           "<!--[if !mso]><!--> lost after Premailex inlining"

    assert String.contains?(inlined, "<!--<![endif]-->"),
           "<!--<![endif]--> closing lost after Premailex inlining"
  end

  test "VML button v:roundrect survives Premailex CSS inlining" do
    html = golden_html()
    inlined = Premailex.to_inline_css(html)

    assert String.contains?(inlined, "v:roundrect"),
           "VML v:roundrect element lost after Premailex inlining (D-14 regression)"

    assert String.contains?(inlined, "<w:anchorlock"),
           "w:anchorlock element lost after Premailex inlining"
  end

  test "Premailex inlines CSS class styles into style attributes" do
    html = golden_html()
    inlined = Premailex.to_inline_css(html)

    # Body margin rule from the <style> block should be inlined.
    assert String.contains?(inlined, "margin:") or String.contains?(inlined, "margin: "),
           "CSS inlining failed — margin property not emitted"

    # The .btn class should produce display:inline-block on the <a>.
    assert String.contains?(inlined, "display:inline-block") or
             String.contains?(inlined, "display: inline-block"),
           "CSS inlining failed — .btn display:inline-block not inlined"
  end

  test "OfficeDocumentSettings XML block is preserved" do
    html = golden_html()
    inlined = Premailex.to_inline_css(html)

    assert String.contains?(inlined, "o:OfficeDocumentSettings"),
           "MSO OfficeDocumentSettings XML block lost after Premailex inlining"

    assert String.contains?(inlined, "o:PixelsPerInch"),
           "o:PixelsPerInch lost after Premailex inlining"
  end
end
