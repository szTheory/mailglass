defmodule Mailglass.ComplianceTest do
  use ExUnit.Case, async: true
  @moduletag :skip

  describe "add_rfc_required_headers/1" do
    test "adds Date, Message-ID, MIME-Version when absent (COMP-01)" do
      # Implemented in Plan 06.
      flunk("not yet implemented")
    end

    test "does not overwrite existing headers (COMP-01)" do
      flunk("not yet implemented")
    end

    test "Mailglass-Mailable header has correct format (COMP-02)" do
      flunk("not yet implemented")
    end
  end
end
