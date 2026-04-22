defmodule Mailglass.ErrorTest do
  use ExUnit.Case, async: true
  # Remove :skip as each test lands with its implementing plan (Plan 02).
  @moduletag :skip

  describe "error hierarchy" do
    test "six error structs are raisable and pattern-matchable by struct" do
      # Implemented in Plan 02 — CORE-01
      flunk("not yet implemented")
    end

    test "__types__/0 matches api_stability.md documented sets" do
      # CORE-01, D-07 — each error module's __types__/0 must match CONTEXT.md D-07.
      flunk("not yet implemented")
    end

    test "Jason.Encoder on errors excludes :cause (T-PII-002)" do
      # D-06 — :cause must not appear in Jason.encode! output on any error struct.
      flunk("not yet implemented")
    end
  end
end
