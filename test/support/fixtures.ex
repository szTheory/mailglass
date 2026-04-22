defmodule Mailglass.Test.Fixtures do
  @moduledoc "Shared test fixtures for Phase 1."

  @doc "Returns a minimal HEEx assigns map for renderer tests."
  def minimal_assigns do
    %{tenant_id: "test_tenant", mailable: TestMailer}
  end

  @doc "Path to the golden VML fixture used by `vml_preservation_test.exs` (D-14)."
  def vml_golden_fixture_path do
    Path.join([__DIR__, "..", "fixtures", "vml_golden.html"])
  end
end
