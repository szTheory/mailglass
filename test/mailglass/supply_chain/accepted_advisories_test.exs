defmodule Mailglass.SupplyChain.AcceptedAdvisoriesTest do
  use ExUnit.Case, async: true

  alias Mailglass.SupplyChain.AcceptedAdvisories

  # Guards the shared accepted-advisory allowlist that both
  # `mix mailglass.publish.check` and `mix mailglass.audit` read (Phase
  # 142/VULN-05, VULN-06). The allowlist exists ONLY for advisories with no
  # upstream fix in any release; every fixable advisory must still hard-block,
  # and retired packages must never be accepted.
  #
  # The real allowlist is empty (EEF-CVE-2026-43966 was retired 2026-11-13 when
  # cowlib 2.22.0 stopped reporting it), so the matching/alias/expiry/unused
  # logic is exercised against a FIXTURE entry passed through the optional
  # trailing `entries` argument. The fixture mirrors the retired entry's shape.

  @fixture_entry %{
    id: "EEF-CVE-2026-43966",
    aliases: ["GHSA-w4f7-4cxr-rv3c"],
    package: "cowlib",
    severity: "MEDIUM",
    reason: "Fixture: unfixable upstream advisory used to exercise the allowlist logic.",
    accepted_on: ~D[2026-07-28],
    recheck_by: ~D[2027-03-17]
  }
  @entries [@fixture_entry]

  describe "real allowlist" do
    test "entries/0 is empty; it must only grow with a sourced, falsifiable reason" do
      # EEF-CVE-2026-43966 was retired 2026-11-13 (cowlib 2.22.0 no longer
      # reports it). Adding an entry back requires upstream evidence plus a
      # named re-check; do not weaken this assertion to make a gate pass.
      assert AcceptedAdvisories.entries() == []
    end

    test "any advisory finding is reported unaccepted, including the retired cowlib id" do
      output = """
      Advisories:
        cowlib 2.20.0 - EEF-CVE-2026-43966 (MEDIUM)
        plug 1.19.2 - EEF-CVE-2026-54892 (HIGH)
      """

      assert AcceptedAdvisories.unaccepted_audit_findings(output) == [
               "cowlib EEF-CVE-2026-43966",
               "plug EEF-CVE-2026-54892"
             ]
    end

    test "a deps.audit finding for the retired GHSA alias is reported unaccepted" do
      output = """
      Name: cowlib
      Version: 2.20.0
      URL: https://github.com/advisories/GHSA-w4f7-4cxr-rv3c
      Title: HTTP Response Splitting via Non-VCHAR Bytes
      """

      assert AcceptedAdvisories.unaccepted_deps_audit_findings(output) == [
               "cowlib GHSA-w4f7-4cxr-rv3c"
             ]
    end

    test "nothing matches the real allowlist, so nothing is marked used" do
      output = "  cowlib 2.20.0 - EEF-CVE-2026-43966 (MEDIUM)\n"

      assert AcceptedAdvisories.matched_hex_audit_ids(output) == MapSet.new()
    end
  end

  describe "unaccepted_audit_findings/1" do
    test "returns [] when the only findings are accepted (unfixable cowlib) advisories" do
      output = """
      Found packages with security advisories
      Advisories:
        cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)
          aka: CVE-2026-43966
          HTTP Response Splitting via Non-VCHAR Bytes
      """

      assert AcceptedAdvisories.unaccepted_audit_findings(output, @entries) == []
    end

    test "blocks EEF-CVE-2026-43969 now that cowlib 2.21.0 fixed it and its entry was retired" do
      output = """
      Advisories:
        cowlib 2.20.0 - EEF-CVE-2026-43966 (MEDIUM)
        cowlib 2.20.0 - EEF-CVE-2026-43969 (LOW)
      """

      assert AcceptedAdvisories.unaccepted_audit_findings(output, @entries) == [
               "cowlib EEF-CVE-2026-43969"
             ]
    end

    test "still blocks on a FIXABLE advisory even alongside accepted ones (negative control)" do
      output = """
      Advisories:
        cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)
        plug 1.19.2 - EEF-CVE-2026-54892 (HIGH)
      """

      assert AcceptedAdvisories.unaccepted_audit_findings(output, @entries) == [
               "plug EEF-CVE-2026-54892"
             ]
    end

    test "never accepts retired packages" do
      output = "Found retired packages:\n  some_pkg 1.0.0 - retired"
      refute AcceptedAdvisories.unaccepted_audit_findings(output, @entries) == []
    end

    test "treats a fully clean audit as no findings" do
      assert AcceptedAdvisories.unaccepted_audit_findings("No retired packages found", @entries) ==
               []
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

      assert AcceptedAdvisories.unaccepted_audit_findings(output, @entries) == [
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
      URL: https://github.com/advisories/GHSA-w4f7-4cxr-rv3c
      Title: HTTP Response Splitting via Non-VCHAR Bytes

      Vulnerabilities found!
      """

      assert AcceptedAdvisories.unaccepted_deps_audit_findings(output, @entries) == []
    end

    test "a non-aliased GHSA id is still correctly NOT suppressed (negative control)" do
      output = """
      Name: cowlib
      Version: 2.19.0
      URL: https://github.com/advisories/GHSA-notaccepted-xxxx-yyyy
      Title: cowlib demo

      Vulnerabilities found!
      """

      assert AcceptedAdvisories.unaccepted_deps_audit_findings(output, @entries) == [
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

      assert AcceptedAdvisories.unaccepted_deps_audit_findings(output, @entries) == [
               "altcha GHSA-6gvq-jcmp-8959",
               "some_pkg GHSA-aaaa-bbbb-cccc"
             ]
    end

    test "a clean deps.audit scan returns []" do
      assert AcceptedAdvisories.unaccepted_deps_audit_findings(
               "No vulnerabilities found.",
               @entries
             ) == []
    end
  end

  describe "matched_hex_audit_ids/1" do
    test "returns the entry's canonical :id when a finding matches by primary id" do
      output = "  cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)\n"

      assert AcceptedAdvisories.matched_hex_audit_ids(output, @entries) ==
               MapSet.new(["EEF-CVE-2026-43966"])
    end

    test "aggregates only allowlisted ids across a multi-finding hex.audit output" do
      output = """
      Advisories:
        cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)
        cowlib 2.19.0 - EEF-CVE-2026-43969 (LOW)
      """

      assert AcceptedAdvisories.matched_hex_audit_ids(output, @entries) ==
               MapSet.new(["EEF-CVE-2026-43966"])
    end

    test "returns an empty set when nothing in the output matches any entry" do
      output = "  pkg_a 1.0.0 - EEF-CVE-9999-00001 (HIGH)\n"

      assert AcceptedAdvisories.matched_hex_audit_ids(output, @entries) == MapSet.new()
    end
  end

  describe "matched_deps_audit_ids/2" do
    test "a GHSA alias hit contributes the entry's canonical :id" do
      output = """
      Name: cowlib
      Version: 2.19.0
      URL: https://github.com/advisories/GHSA-w4f7-4cxr-rv3c
      """

      assert AcceptedAdvisories.matched_deps_audit_ids(output, @entries) ==
               MapSet.new(["EEF-CVE-2026-43966"])
    end
  end

  describe "expired_entries/1" do
    # The fixture entry carries recheck_by 2027-03-17 (CTRL-04, D-30: a
    # 6-month extension on the permanent-refusal framing — see its :reason).
    # The strictly-after semantics are pinned on both sides of the boundary.
    test "an entry whose recheck_by is exactly today is NOT flagged (strictly-after semantics)" do
      assert AcceptedAdvisories.expired_entries(~D[2027-03-17], @entries) == []
    end

    test "an entry whose recheck_by was yesterday IS flagged" do
      result = AcceptedAdvisories.expired_entries(~D[2027-03-18], @entries)

      assert Enum.map(result, & &1.id) == ["EEF-CVE-2026-43966"]
    end

    test "no entries are flagged at the old (superseded) 2026-12-01 boundary" do
      assert AcceptedAdvisories.expired_entries(~D[2026-12-01], @entries) == []
    end

    test "no entries are flagged before recheck_by has arrived" do
      assert AcceptedAdvisories.expired_entries(~D[2026-07-28], @entries) == []
    end
  end

  describe "unused_entries/1" do
    test "returns [] when every entry matched a current finding" do
      matched = MapSet.new(["EEF-CVE-2026-43966"])

      assert AcceptedAdvisories.unused_entries(matched, @entries) == []
    end

    test "with an empty matched_ids set, all entries are reported unused, in " <>
           "entries/0's declared order (anti-vacuity + ordering)" do
      result = AcceptedAdvisories.unused_entries(MapSet.new(), @entries)

      assert Enum.map(result, & &1.id) == ["EEF-CVE-2026-43966"]
    end

    test "a matched id that is not an entry does not mark any entry used" do
      matched = MapSet.new(["EEF-CVE-2026-43969"])

      assert Enum.map(AcceptedAdvisories.unused_entries(matched, @entries), & &1.id) == [
               "EEF-CVE-2026-43966"
             ]
    end
  end

  describe "entry shape (fixture mirrors the allowlist contract)" do
    test "all entries carry the required allowlist fields" do
      for entry <- @entries do
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
