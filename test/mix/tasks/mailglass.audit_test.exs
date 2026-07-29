defmodule Mix.Tasks.Mailglass.AuditTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Mailglass.Audit

  # D-15's required deterministic unit tests for the task's own
  # aggregation/exit-decision function (`evaluate/2`), tested against
  # synthetic multi-directory output — mirrors verify_audit/1's
  # case unaccepted_audit_findings(output) do [] -> ...; unaccepted -> ... end
  # branch shape from mailglass.publish.check.ex.

  describe "evaluate/2 (:hex)" do
    test "an unaccepted HIGH advisory with an available fix blocks" do
      dir_outputs = [
        {"", "No retired packages found", 0},
        {"mailglass_admin",
         """
         Advisories:
           plug 1.19.2 - EEF-CVE-2026-54892 (HIGH)
         """, 1},
        {"mailglass_inbound", "No retired packages found", 0}
      ]

      assert {:error, reasons} = Audit.evaluate(:hex, dir_outputs)
      assert Enum.any?(reasons, &(&1 =~ "plug EEF-CVE-2026-54892"))
    end

    test "an accepted-only cowlib finding, clean elsewhere, passes" do
      dir_outputs = [
        {"", "No retired packages found", 0},
        {"mailglass_admin",
         """
         Advisories:
           cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)
           cowlib 2.19.0 - EEF-CVE-2026-43969 (LOW)
         """, 1},
        {"mailglass_inbound", "No retired packages found", 0}
      ]

      assert {:ok, accepted} = Audit.evaluate(:hex, dir_outputs)
      assert Enum.any?(accepted, &(&1 =~ "EEF-CVE-2026-43966"))
      assert Enum.any?(accepted, &(&1 =~ "EEF-CVE-2026-43969"))
    end

    test "a clean scan everywhere except the still-accepted cowlib findings passes" do
      # A "fully clean" (zero findings anywhere) scenario is NOT the real-world
      # baseline: both allowlist entries are live cowlib findings in
      # mailglass_admin today, and their absence would correctly trip
      # unused_entries/1 (D-10). This test proves the actual steady-state:
      # accepted findings present + clean elsewhere passes with zero blocking.
      dir_outputs = [
        {"", "No retired packages found", 0},
        {"mailglass_admin",
         """
         Advisories:
           cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)
           cowlib 2.19.0 - EEF-CVE-2026-43969 (LOW)
         """, 1},
        {"mailglass_inbound", "No retired packages found", 0}
      ]

      assert {:ok, _accepted} = Audit.evaluate(:hex, dir_outputs)
    end

    test "a fully clean scan (no findings anywhere) blocks on unused_entries (D-10)" do
      dir_outputs = [
        {"", "No retired packages found", 0},
        {"mailglass_admin", "No retired packages found", 0},
        {"mailglass_inbound", "No retired packages found", 0}
      ]

      assert {:error, reasons} = Audit.evaluate(:hex, dir_outputs)
      assert Enum.any?(reasons, &(&1 =~ "matches no current finding"))
    end
  end

  describe "evaluate/2 (:deps)" do
    test "an unaccepted HIGH advisory with an available fix blocks" do
      dir_outputs = [
        {"", "No vulnerabilities found.", 0},
        {"mailglass_admin",
         """
         Name: altcha
         Version: 0.9.0
         URL: https://github.com/advisories/GHSA-6gvq-jcmp-8959
         Title: ALTCHA Proof-of-Work Vulnerable to Challenge Splicing and Replay

         Vulnerabilities found!
         """, 1},
        {"mailglass_inbound", "No vulnerabilities found.", 0}
      ]

      assert {:error, reasons} = Audit.evaluate(:deps, dir_outputs)
      assert Enum.any?(reasons, &(&1 =~ "altcha GHSA-6gvq-jcmp-8959"))
    end

    test "an accepted-only (alias-matched) finding, clean elsewhere, passes" do
      dir_outputs = [
        {"", "No vulnerabilities found.", 0},
        {"mailglass_admin",
         """
         Name: cowlib
         Version: 2.19.0
         URL: https://github.com/advisories/GHSA-g2wm-735q-3f56
         Title: Cookie Request Header Injection

         Vulnerabilities found!
         """, 1},
        {"mailglass_inbound", "No vulnerabilities found.", 0}
      ]

      assert {:ok, []} = Audit.evaluate(:deps, dir_outputs)
    end

    test "expired_entries/unused_entries are NOT applied to the :deps kind" do
      # Decision 2 (142-01-PLAN.md): --kind deps never appends
      # expired_entries/1 or unused_entries/1 findings, even though the real
      # allowlist entries are both permanently "unused" from a deps.audit
      # perspective (mix_audit doesn't natively detect them).
      dir_outputs = [
        {"", "No vulnerabilities found.", 0},
        {"mailglass_admin", "No vulnerabilities found.", 0},
        {"mailglass_inbound", "No vulnerabilities found.", 0}
      ]

      assert {:ok, []} = Audit.evaluate(:deps, dir_outputs)
    end
  end
end
