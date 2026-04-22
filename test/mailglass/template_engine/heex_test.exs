defmodule Mailglass.TemplateEngine.HEExTest do
  use ExUnit.Case, async: true
  @moduletag :skip

  test "render/2 with missing assign returns {:error, %TemplateError{type: :missing_assign}}" do
    # Implemented in Plan 06 — AUTHOR-05.
    flunk("not yet implemented")
  end
end
