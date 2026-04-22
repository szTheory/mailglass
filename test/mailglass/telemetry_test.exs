defmodule Mailglass.TelemetryTest do
  use ExUnit.Case, async: false
  # ExUnitProperties is provided by :stream_data. Guarded `use` so compilation
  # succeeds even if StreamData is momentarily unavailable during early setup.
  if Code.ensure_loaded?(ExUnitProperties) do
    use ExUnitProperties
  end

  @moduletag :skip

  describe "metadata whitelist (D-33, T-PII-001)" do
    test "stop events contain only whitelisted metadata keys across 1000 renders" do
      # Implemented in Plan 03 — CORE-03. StreamData property test attaches a
      # handler to [:mailglass | _] and asserts every :stop event's metadata
      # keys are a subset of the D-31 whitelist.
      flunk("not yet implemented")
    end

    test "telemetry handler that raises does not crash the pipeline (T-HANDLER-001)" do
      # :telemetry.execute/3 already isolates handler exceptions; this test
      # guards against any mailglass-side wrapper that might break isolation.
      flunk("not yet implemented")
    end
  end
end
