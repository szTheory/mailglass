defmodule Mailglass.Components.ImgNoAltTest do
  @moduledoc """
  Wave 0 compile-time failure fixture for AUTHOR-02's required `:alt` attribute.

  This file exists as a stub; the real compile-error verification happens in
  Plan 05. Once `Mailglass.Components` is defined with
  `attr :alt, :string, required: true`, attempting to render `<.img>` without
  `:alt` will produce a compile error. Plan 05 Task 2b verifies this by
  compiling this file in isolation.

  Do NOT remove `@moduletag :skip` until Plan 05 is complete.
  """

  use ExUnit.Case, async: true
  @moduletag :skip

  test "img_no_alt is a compile-time failure fixture (AUTHOR-02)" do
    # This test body never runs under normal CI (guarded by @moduletag :skip).
    # Plan 05 verifies the compile error by compiling this file directly.
    flunk("fixture — not a runnable test")
  end
end
