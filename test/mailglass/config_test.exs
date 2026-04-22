defmodule Mailglass.ConfigTest do
  use ExUnit.Case, async: true
  @moduletag :skip

  describe "Config.new!/1" do
    test "validates required keys via NimbleOptions" do
      # Implemented in Plan 03 — CORE-02
      flunk("not yet implemented")
    end

    test "invalid config raises NimbleOptions.ValidationError" do
      flunk("not yet implemented")
    end
  end
end
