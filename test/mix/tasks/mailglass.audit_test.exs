defmodule Mix.Tasks.Mailglass.AuditTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Mailglass.Audit

  # D-15's required deterministic unit tests for the task's own
  # aggregation/exit-decision function (`evaluate/2`), tested against
  # synthetic multi-directory output — mirrors verify_audit/1's
  # case unaccepted_audit_findings(output) do [] -> ...; unaccepted -> ... end
  # branch shape from mailglass.publish.check.ex.
  #
  # The real allowlist is empty (EEF-CVE-2026-43966 retired 2026-11-13), so
  # tests that need an accepted entry inject a fixture through evaluate/3's
  # trailing `entries` argument. The fixture's recheck_by is far in the future
  # because evaluate/3 judges expiry against the real clock; a date near
  # today would turn these tests into time bombs.

  @fixture_entry %{
    id: "EEF-CVE-2026-43966",
    aliases: ["GHSA-w4f7-4cxr-rv3c"],
    package: "cowlib",
    severity: "MEDIUM",
    reason: "Fixture: unfixable upstream advisory used to exercise the allowlist logic.",
    accepted_on: ~D[2026-07-28],
    recheck_by: ~D[2999-01-01]
  }
  @entries [@fixture_entry]

  describe "evaluate/3 (:hex) with the real (empty) allowlist" do
    test "a clean scan passes: an empty allowlist has no unused entries" do
      dir_outputs = [
        {"", "No retired packages found", 0},
        {"mailglass_admin", "No retired packages found", 0},
        {"mailglass_inbound", "No retired packages found", 0}
      ]

      assert {:ok, []} = Audit.evaluate(:hex, dir_outputs)
    end

    test "the retired cowlib advisory now blocks instead of being accepted" do
      dir_outputs = [
        {"", "No retired packages found", 0},
        {"mailglass_admin",
         """
         Advisories:
           cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)
         """, 1},
        {"mailglass_inbound", "No retired packages found", 0}
      ]

      assert {:error, reasons} = Audit.evaluate(:hex, dir_outputs)
      assert Enum.any?(reasons, &(&1 =~ "cowlib EEF-CVE-2026-43966"))
    end
  end

  describe "evaluate/3 (:hex) with a fixture entry" do
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

      assert {:error, reasons} = Audit.evaluate(:hex, dir_outputs, @entries)
      assert Enum.any?(reasons, &(&1 =~ "plug EEF-CVE-2026-54892"))
    end

    test "an accepted-only cowlib finding, clean elsewhere, passes" do
      dir_outputs = [
        {"", "No retired packages found", 0},
        {"mailglass_admin",
         """
         Advisories:
           cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)
         """, 1},
        {"mailglass_inbound", "No retired packages found", 0}
      ]

      assert {:ok, accepted} = Audit.evaluate(:hex, dir_outputs, @entries)
      assert Enum.any?(accepted, &(&1 =~ "EEF-CVE-2026-43966"))
    end

    test "a clean scan everywhere except the still-accepted cowlib findings passes" do
      # With an entry present, a "fully clean" (zero findings anywhere)
      # scenario is NOT a pass: the entry is a live cowlib finding in
      # mailglass_admin, and its absence would correctly trip
      # unused_entries/2 (D-10). This test proves the steady-state with an
      # entry present: accepted findings present + clean elsewhere passes.
      dir_outputs = [
        {"", "No retired packages found", 0},
        {"mailglass_admin",
         """
         Advisories:
           cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)
         """, 1},
        {"mailglass_inbound", "No retired packages found", 0}
      ]

      assert {:ok, _accepted} = Audit.evaluate(:hex, dir_outputs, @entries)
    end

    test "a fully clean scan (no findings anywhere) blocks on unused_entries (D-10)" do
      dir_outputs = [
        {"", "No retired packages found", 0},
        {"mailglass_admin", "No retired packages found", 0},
        {"mailglass_inbound", "No retired packages found", 0}
      ]

      assert {:error, reasons} = Audit.evaluate(:hex, dir_outputs, @entries)
      assert Enum.any?(reasons, &(&1 =~ "matches no current finding"))
    end

    test "a nonzero unparseable result blocks even when another project has accepted findings" do
      dir_outputs = [
        {"",
         """
         Advisories:
           cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)
         """, 1},
        {"mailglass_admin", "registry unavailable", 1},
        {"mailglass_inbound", "No retired packages found", 0}
      ]

      assert {:error, reasons} = Audit.evaluate(:hex, dir_outputs, @entries)

      assert Enum.any?(reasons, fn reason ->
               reason =~ "mailglass_admin" and reason =~ "status 1" and
                 reason =~ "no recognized advisory"
             end)
    end
  end

  describe "evaluate/3 (:deps)" do
    test "with the real (empty) allowlist, the retired GHSA alias blocks" do
      dir_outputs = [
        {"", "No vulnerabilities found.", 0},
        {"mailglass_admin",
         """
         Name: cowlib
         Version: 2.19.0
         URL: https://github.com/advisories/GHSA-w4f7-4cxr-rv3c
         Title: HTTP Response Splitting via Non-VCHAR Bytes

         Vulnerabilities found!
         """, 1},
        {"mailglass_inbound", "No vulnerabilities found.", 0}
      ]

      assert {:error, reasons} = Audit.evaluate(:deps, dir_outputs)
      assert Enum.any?(reasons, &(&1 =~ "cowlib GHSA-w4f7-4cxr-rv3c"))
    end

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

      assert {:error, reasons} = Audit.evaluate(:deps, dir_outputs, @entries)
      assert Enum.any?(reasons, &(&1 =~ "altcha GHSA-6gvq-jcmp-8959"))
    end

    test "an accepted-only (alias-matched) finding, clean elsewhere, passes" do
      dir_outputs = [
        {"", "No vulnerabilities found.", 0},
        {"mailglass_admin",
         """
         Name: cowlib
         Version: 2.19.0
         URL: https://github.com/advisories/GHSA-w4f7-4cxr-rv3c
         Title: HTTP Response Splitting via Non-VCHAR Bytes

         Vulnerabilities found!
         """, 1},
        {"mailglass_inbound", "No vulnerabilities found.", 0}
      ]

      assert {:ok, []} = Audit.evaluate(:deps, dir_outputs, @entries)
    end

    test "expired_entries/unused_entries are NOT applied to the :deps kind" do
      # Decision 2 (142-01-PLAN.md): --kind deps never appends
      # expired_entries/1 or unused_entries/1 findings, even though an
      # allowlist entry is permanently "unused" from a deps.audit
      # perspective (mix_audit doesn't natively detect it).
      dir_outputs = [
        {"", "No vulnerabilities found.", 0},
        {"mailglass_admin", "No vulnerabilities found.", 0},
        {"mailglass_inbound", "No vulnerabilities found.", 0}
      ]

      assert {:ok, []} = Audit.evaluate(:deps, dir_outputs, @entries)
    end

    test "a nonzero unparseable result blocks instead of reporting a clean finding set" do
      dir_outputs = [
        {"", "No vulnerabilities found.", 0},
        {"mailglass_admin", "network unavailable", 1},
        {"mailglass_inbound", "No vulnerabilities found.", 0}
      ]

      assert {:error, reasons} = Audit.evaluate(:deps, dir_outputs, @entries)

      assert Enum.any?(reasons, fn reason ->
               reason =~ "mailglass_admin" and reason =~ "status 1" and
                 reason =~ "no recognized advisory"
             end)
    end
  end
end
