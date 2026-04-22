defmodule Mailglass.RendererTest do
  use ExUnit.Case, async: true
  @moduletag :skip

  describe "render/1" do
    test "returns {:ok, %Message{html_body: _, text_body: _}}" do
      # Implemented in Plan 06 — AUTHOR-03.
      flunk("not yet implemented")
    end

    test "plaintext excludes preheader text (D-15)" do
      flunk("not yet implemented")
    end

    test "plaintext for <.button> produces 'Label (url)' format (D-22)" do
      flunk("not yet implemented")
    end

    test "data-mg-* attributes stripped from final HTML wire (D-22)" do
      flunk("not yet implemented")
    end

    test "render completes in <50ms for 10-component template (AUTHOR-03)" do
      flunk("not yet implemented")
    end
  end
end
