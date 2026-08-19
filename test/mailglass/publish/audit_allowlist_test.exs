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
        cowlib 2.19.0 - EEF-CVE-2026-43971 (MEDIUM)
          aka: CVE-2026-43971
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

  # SUPPLY-01: the `mix deps.audit` gate (Step 14). mix_audit 2.1.5 uses the
  # mirego/elixir-security-advisories DB, which keys advisories by GHSA id and
  # emits a multi-line human block per vulnerability:
  #
  #     Name: <pkg>
  #     Version: <ver>
  #     Lockfile: mix.lock
  #     URL: https://github.com/advisories/<GHSA-id>
  #     Title: <title>
  #     ...
  #
  # unaccepted_deps_audit_findings/1 now matches by :id OR any :aliases entry
  # (Mailglass.SupplyChain.AcceptedAdvisories, Phase 142/VULN-05), so a
  # deps.audit finding IS suppressed when its GHSA id is a registered alias
  # (e.g. GHSA-g2wm-735q-3f56 for EEF-CVE-2026-43969's cowlib entry); a GHSA id
  # with no matching alias still surfaces. See the SUMMARY (A4) for the format
  # provenance.
  describe "unaccepted_deps_audit_findings/1" do
    test "a non-allowlisted GHSA finding in deps.audit human format returns a non-empty list" do
      output = """
      Name: altcha
      Version: 0.9.0
      Lockfile: mix.lock
      URL: https://github.com/advisories/GHSA-6gvq-jcmp-8959
      Title: ALTCHA Proof-of-Work Vulnerable to Challenge Splicing and Replay
      Severity: moderate
      Vulnerable versions: < 1.0.0
      First patched versions: 1.0.0

      Vulnerabilities found!
      """

      assert Check.unaccepted_deps_audit_findings(output) == [
               "altcha GHSA-6gvq-jcmp-8959"
             ]
    end

    test "reports every vulnerable package block, not just the first" do
      output = """
      Name: altcha
      Version: 0.9.0
      URL: https://github.com/advisories/GHSA-6gvq-jcmp-8959
      Title: A

      Name: some_pkg
      Version: 1.2.3
      URL: https://github.com/advisories/GHSA-aaaa-bbbb-cccc
      Title: B

      Vulnerabilities found!
      """

      assert Check.unaccepted_deps_audit_findings(output) == [
               "altcha GHSA-6gvq-jcmp-8959",
               "some_pkg GHSA-aaaa-bbbb-cccc"
             ]
    end

    test "a clean deps.audit scan returns []" do
      assert Check.unaccepted_deps_audit_findings("No vulnerabilities found.") == []
    end

    test "a non-aliased GHSA id is still correctly NOT suppressed (negative control)" do
      # This GHSA id is NOT a registered alias of either accepted cowlib entry,
      # so it must still surface. The real positive alias-suppression proof
      # (a GHSA id that IS a registered alias, e.g. GHSA-g2wm-735q-3f56) lives
      # in test/mailglass/supply_chain/accepted_advisories_test.exs (F2).
      output = """
      Name: cowlib
      Version: 2.17.1
      URL: https://github.com/advisories/GHSA-notaccepted-xxxx-yyyy
      Title: cowlib demo

      Vulnerabilities found!
      """

      assert Check.unaccepted_deps_audit_findings(output) == [
               "cowlib GHSA-notaccepted-xxxx-yyyy"
             ]
    end
  end

  # SUPPLY-03: the OSV-staleness forcing function. classify_osv_response/2 is the
  # pure decode+classify core of check_osv_advisory_staleness/0, extracted so the
  # stale/active/parse-error branches are unit-testable without live HTTP. The
  # network fail-open path (osv_get/1 -> {:error, _}) is exercised separately below.
  describe "classify_osv_response/2 (OSV staleness classification)" do
    test "a body with a \"withdrawn\" key classifies as stale" do
      body = ~s({"id":"EEF-CVE-2026-43966","withdrawn":"2026-08-01T00:00:00Z"})

      assert Check.classify_osv_response("EEF-CVE-2026-43966", body) ==
               {:stale, "EEF-CVE-2026-43966", "2026-08-01T00:00:00Z"}
    end

    test "a body without a \"withdrawn\" key classifies as active" do
      body = ~s({"id":"EEF-CVE-2026-43966","summary":"still live"})

      assert Check.classify_osv_response("EEF-CVE-2026-43966", body) ==
               {:active, "EEF-CVE-2026-43966"}
    end

    test "malformed JSON classifies as an error (fail-open, never blocks)" do
      assert {:error, "EEF-CVE-2026-43966", :parse_error} =
               Check.classify_osv_response("EEF-CVE-2026-43966", "{not json")
    end
  end

  describe "osv_get/1 (fail-open network contract)" do
    test "an unresolvable host returns an {:error, _} tuple rather than raising" do
      # A DNS name that cannot resolve exercises the try/rescue fail-open path.
      # The contract: osv_get/1 NEVER raises and NEVER blocks — it returns
      # {:error, reason} so check_osv_advisory_staleness/0 can log-and-continue.
      assert {:error, _reason} =
               Check.osv_get("https://osv-does-not-exist.invalid/v1/vulns/EEF-CVE-2026-43966")
    end
  end
end
