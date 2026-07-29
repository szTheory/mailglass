defmodule Mailglass.SupplyChain.AcceptedAdvisoriesTest do
  use ExUnit.Case, async: true

  alias Mailglass.SupplyChain.AcceptedAdvisories

  # Guards the shared accepted-advisory allowlist that both
  # `mix mailglass.publish.check` and `mix mailglass.audit` read (Phase
  # 142/VULN-05, VULN-06). The allowlist exists ONLY for advisories with no
  # upstream fix in any release; every fixable advisory must still hard-block,
  # and retired packages must never be accepted.

  describe "unaccepted_audit_findings/1" do
    test "returns [] when the only findings are accepted (unfixable cowlib) advisories" do
      output = """
      Found packages with security advisories
      Advisories:
        cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)
          aka: CVE-2026-43966
          HTTP Response Splitting via Non-VCHAR Bytes
        cowlib 2.19.0 - EEF-CVE-2026-43969 (LOW)
          aka: CVE-2026-43969, GHSA-g2wm-735q-3f56
      """

      assert AcceptedAdvisories.unaccepted_audit_findings(output) == []
    end

    test "still blocks on a FIXABLE advisory even alongside accepted ones (negative control)" do
      output = """
      Advisories:
        cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)
        plug 1.19.2 - EEF-CVE-2026-54892 (HIGH)
      """

      assert AcceptedAdvisories.unaccepted_audit_findings(output) == ["plug EEF-CVE-2026-54892"]
    end

    test "never accepts retired packages" do
      output = "Found retired packages:\n  some_pkg 1.0.0 - retired"
      refute AcceptedAdvisories.unaccepted_audit_findings(output) == []
    end

    test "treats a fully clean audit as no findings" do
      assert AcceptedAdvisories.unaccepted_audit_findings("No retired packages found") == []
    end

    test "empty-allowlist edge: an output with no id matching any entry rejects nothing" do
      # None of these ids appear in @entries, so the allowlist filter is
      # effectively empty for this data — every raw finding must survive,
      # proving unaccepted_audit_findings/1 never rejects a finding it has no
      # matching entry for.
      output = """
      Advisories:
        pkg_a 1.0.0 - EEF-CVE-9999-00001 (HIGH)
        pkg_b 2.0.0 - EEF-CVE-9999-00002 (LOW)
      """

      assert AcceptedAdvisories.unaccepted_audit_findings(output) == [
               "pkg_a EEF-CVE-9999-00001",
               "pkg_b EEF-CVE-9999-00002"
             ]
    end
  end

  describe "unaccepted_deps_audit_findings/1" do
    test "suppresses a deps.audit finding whose GHSA id is a registered alias (F2)" do
      output = """
      Name: cowlib
      Version: 2.19.0
      URL: https://github.com/advisories/GHSA-g2wm-735q-3f56
      Title: Cookie Request Header Injection

      Vulnerabilities found!
      """

      assert AcceptedAdvisories.unaccepted_deps_audit_findings(output) == []
    end

    test "a non-aliased GHSA id is still correctly NOT suppressed (negative control)" do
      output = """
      Name: cowlib
      Version: 2.19.0
      URL: https://github.com/advisories/GHSA-notaccepted-xxxx-yyyy
      Title: cowlib demo

      Vulnerabilities found!
      """

      assert AcceptedAdvisories.unaccepted_deps_audit_findings(output) == [
               "cowlib GHSA-notaccepted-xxxx-yyyy"
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

      assert AcceptedAdvisories.unaccepted_deps_audit_findings(output) == [
               "altcha GHSA-6gvq-jcmp-8959",
               "some_pkg GHSA-aaaa-bbbb-cccc"
             ]
    end

    test "a clean deps.audit scan returns []" do
      assert AcceptedAdvisories.unaccepted_deps_audit_findings("No vulnerabilities found.") == []
    end
  end

  describe "matched_hex_audit_ids/1" do
    test "returns the entry's canonical :id when a finding matches by primary id" do
      output = "  cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)\n"

      assert AcceptedAdvisories.matched_hex_audit_ids(output) ==
               MapSet.new(["EEF-CVE-2026-43966"])
    end

    test "aggregates matches across a multi-finding hex.audit output" do
      output = """
      Advisories:
        cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)
        cowlib 2.19.0 - EEF-CVE-2026-43969 (LOW)
      """

      assert AcceptedAdvisories.matched_hex_audit_ids(output) ==
               MapSet.new(["EEF-CVE-2026-43966", "EEF-CVE-2026-43969"])
    end

    test "returns an empty set when nothing in the output matches any entry" do
      output = "  pkg_a 1.0.0 - EEF-CVE-9999-00001 (HIGH)\n"

      assert AcceptedAdvisories.matched_hex_audit_ids(output) == MapSet.new()
    end
  end

  describe "expired_entries/1" do
    test "an entry whose recheck_by is exactly today is NOT flagged (strictly-after semantics)" do
      assert AcceptedAdvisories.expired_entries(~D[2026-10-26]) == []
    end

    test "an entry whose recheck_by was yesterday IS flagged" do
      result = AcceptedAdvisories.expired_entries(~D[2026-10-27])

      assert length(result) == 2
      assert Enum.map(result, & &1.id) == ["EEF-CVE-2026-43966", "EEF-CVE-2026-43969"]
    end

    test "no entries are flagged before recheck_by has arrived" do
      assert AcceptedAdvisories.expired_entries(~D[2026-07-28]) == []
    end
  end

  describe "unused_entries/1" do
    test "returns [] when every entry matched a current finding" do
      matched = MapSet.new(["EEF-CVE-2026-43966", "EEF-CVE-2026-43969"])

      assert AcceptedAdvisories.unused_entries(matched) == []
    end

    test "with an empty matched_ids set, both entries are reported unused, in " <>
           "entries/0's declared order (anti-vacuity + ordering)" do
      result = AcceptedAdvisories.unused_entries(MapSet.new())

      assert Enum.map(result, & &1.id) == ["EEF-CVE-2026-43966", "EEF-CVE-2026-43969"]
    end

    test "reports only the entry that matched no finding" do
      matched = MapSet.new(["EEF-CVE-2026-43966"])

      assert Enum.map(AcceptedAdvisories.unused_entries(matched), & &1.id) == [
               "EEF-CVE-2026-43969"
             ]
    end
  end

  describe "entries/0" do
    test "both entries carry the required allowlist fields" do
      for entry <- AcceptedAdvisories.entries() do
        assert is_binary(entry.id)
        assert is_list(entry.aliases)
        assert entry.package == "cowlib"
        assert is_binary(entry.severity)
        assert is_binary(entry.reason)
        assert %Date{} = entry.accepted_on
        assert %Date{} = entry.recheck_by
      end
    end
  end
end
