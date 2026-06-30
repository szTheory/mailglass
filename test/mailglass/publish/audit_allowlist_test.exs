defmodule Mailglass.Publish.AuditAllowlistTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Mailglass.Publish.Check

  # Guards the Step-13 hex.audit accepted-advisory allowlist (see
  # @accepted_advisories in mailglass.publish.check.ex). The allowlist exists ONLY
  # for advisories with no upstream fix in any release; every fixable advisory must
  # still hard-block delivery, and retired packages must never be accepted.

  describe "unaccepted_audit_findings/1" do
    test "returns [] when the only findings are accepted (unfixable cowlib) advisories" do
      output = """
      Found packages with security advisories
      Advisories:
        cowlib 2.17.1 - EEF-CVE-2026-43966 (MEDIUM)
          aka: CVE-2026-43966
          HTTP Response Splitting via Non-VCHAR Bytes
        cowlib 2.17.1 - EEF-CVE-2026-43969 (LOW)
          aka: CVE-2026-43969, GHSA-g2wm-735q-3f56
      """

      assert Check.unaccepted_audit_findings(output) == []
    end

    test "still blocks on a FIXABLE advisory even alongside accepted ones" do
      output = """
      Advisories:
        cowlib 2.17.1 - EEF-CVE-2026-43966 (MEDIUM)
        plug 1.19.2 - EEF-CVE-2026-54892 (HIGH)
      """

      assert Check.unaccepted_audit_findings(output) == ["plug EEF-CVE-2026-54892"]
    end

    test "never accepts retired packages" do
      output = "Found retired packages:\n  some_pkg 1.0.0 - retired"
      refute Check.unaccepted_audit_findings(output) == []
    end

    test "treats a fully clean audit as no findings" do
      assert Check.unaccepted_audit_findings("No retired packages found") == []
    end
  end
end
