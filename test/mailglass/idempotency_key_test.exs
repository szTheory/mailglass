defmodule Mailglass.IdempotencyKeyTest do
  use ExUnit.Case, async: true
  @moduletag :skip

  describe "for_webhook_event/2" do
    test "produces deterministic keys in format 'provider:event_id'" do
      # Implemented in Plan 03 — CORE-05.
      flunk("not yet implemented")
    end

    test "keys with control characters are sanitized (T-IDEMP-001)" do
      flunk("not yet implemented")
    end
  end
end
