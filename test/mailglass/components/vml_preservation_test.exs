defmodule Mailglass.Components.VmlPreservationTest do
  @moduledoc """
  MANDATORY golden-fixture test for Premailex VML conditional-comment preservation.

  D-14: Premailex must preserve MSO conditional comments
  (`<!--[if mso]>...<![endif]-->`) after CSS inlining. This test guards against
  Premailex version regressions by diffing rendered output against a committed
  golden fixture.

  The golden fixture is a rendered email with VML button + ghost-table row/column
  components. After `Premailex.to_inline_css/2` runs, every conditional comment
  must survive byte-for-byte.
  """

  use ExUnit.Case, async: true
  # Remove :skip when Plan 05 lands Components + the golden fixture.
  @moduletag :skip

  test "Premailex preserves <!--[if mso]> conditional comments after CSS inlining" do
    # Implemented in Plan 05 — AUTHOR-02.
    flunk("not yet implemented")
  end

  test "VML button v:roundrect survives Premailex inlining" do
    flunk("not yet implemented")
  end
end
