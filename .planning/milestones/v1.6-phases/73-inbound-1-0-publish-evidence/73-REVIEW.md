---
phase: 73-inbound-1-0-publish-evidence
reviewed: 2026-06-02T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - MAINTAINING.md
  - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Phase 73: Code Review Report

**Reviewed:** 2026-06-02T00:00:00Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Phase 73 is a prepare-and-stage release-evidence phase touching two files: a
stale-path fix plus inbound-publish wording in `MAINTAINING.md`, and one new
field-presence/regression-guard test in `docs_contract_test.exs`.

The MAINTAINING.md content changes are correct and verified: the old
`.planning/phases/38-*` directory no longer exists, the new
`.planning/milestones/v1.0-phases/38-...` paths resolve, and the inbound-only
fallback wording is consistent with the documented publish fan-out gating. The
new test passes today (23 tests, 0 failures, seed 0).

The substantive concerns are in the new test. It is forward-fragile: it asserts
the release record stays in its `pending` / `not run` state, but the phase's own
summaries say a maintainer will later fill those fields in — at which point this
test breaks and blocks the publish it is meant to guard. Several assertions are
also looser than their stated intent (bare substring matches that don't bind to
field headers or to the right state), and the inbound package's unit suite now
hard-reads a repo-root `.planning/` artifact that is deliberately excluded from
the published package.

## Warnings

### WR-01: Test asserts `pending`/`not run` presence, which inverts once the record is filled in

**File:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:692-696`
**Issue:** The new test hard-asserts that the release record still contains the
unfinished-state markers:

```elixir
assert record =~ "not run", ...
assert record =~ "pending", ...
```

But this record is explicitly designed to be edited later. `73-01-SUMMARY.md`
line 19 lists "post-publish maintainer trigger (fills pending fields in
RELEASE-RECORD)" as a downstream consumer, and `73-02-SUMMARY.md` line 51 calls
the `pending` URL a placeholder "until the maintainer cuts the tag." When the
maintainer performs the actual `mailglass_inbound 1.0.0` publish and replaces
`Publish workflow run URL: pending` / `60-minute outcome: not run` with real
values, these two asserts will FAIL — and because this test runs in the
repo-root required `mix verify.stability_contract` lane (MAINTAINING.md:149), a
failing assertion would block merging the very release-evidence update it is
supposed to certify. The guard is correct for the prepare-and-stage moment but
mis-modeled as an invariant. It should assert "honest surface area" without
pinning the document to its empty state forever.

**Fix:** Gate the pending-marker asserts the same way the file already gates the
`## [Unreleased]` over-claim guard (lines 559-574): detect whether the record is
still in staged posture and only run the marker assertions then. For example:

```elixir
record_staged? = record =~ "Tag: mailglass_inbound-v1.0.0 (staged, not cut)"

if record_staged? do
  assert record =~ "not run", "..."
  assert record =~ "pending", "..."
end
```

Or assert on the structural intent ("every post-publish-only field carries an
explicit value, never blank") rather than on the literal `pending`/`not run`
strings, so the guard survives the record being completed.

### WR-02: Field-header asserts use bare substrings that do not bind to the REL-03 headers

**File:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:679-690`
**Issue:** The header check iterates `["Tag", "Publish workflow run URL",
"Fallback", "Hex index", "HexDocs", "smoke", "60-minute"]` with `record =~
header`. Several of these are too generic to prove the corresponding field is
present:
- `"smoke"` matches anywhere ("Post-publish smoke run URL", "smoke proof",
  prose). The actual field label is `Post-publish smoke run URL:`.
- `"Fallback"` matches the prose phrase "Fallback path used:" but also any other
  use of the word; the asserted token is not the full label.
- `"60-minute"` and `"Hex index"` are similarly loose.

A record that dropped the `60-minute outcome:` field but mentioned the
60-minute window in prose would still pass. The test claims to verify "REL-03
field headers" (per its own name and message) but actually verifies "these words
appear somewhere," which is a weaker guarantee than advertised.

**Fix:** Assert on the actual field labels as they appear in the record so the
test fails if a field is renamed or dropped:

```elixir
for header <- [
      "Tag:",
      "Publish workflow run URL:",
      "Fallback path used:",
      "Hex index confirmation:",
      "HexDocs URLs:",
      "Post-publish smoke run URL:",
      "60-minute outcome:"
    ] do
  assert record =~ header, "Expected REL-03 field label: #{inspect(header)}"
end
```

### WR-03: Inbound package unit test hard-reads a repo-root `.planning/` artifact excluded from the package

**File:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:671-677`
**Issue:** The test does `File.read!` on
`../../../.planning/phases/73-inbound-1-0-publish-evidence/73-01-RELEASE-RECORD.md`,
reaching three directories up out of the `mailglass_inbound` package into
repo-root planning artifacts. `.planning/` is not in the package `files:`
allowlist (`mailglass_inbound/mix.exs:128` ships only
`lib docs priv .formatter.exs mix.exs README* CHANGELOG* LICENSE*`), and neither
is `test/`, so this does not break the published tarball. But it couples the
sibling package's test suite to a single, dated planning file: the path embeds
the literal phase number `73-inbound-1-0-publish-evidence`. Once phase 73 is
archived/moved (the Phase 38 forms in this same diff were moved from
`.planning/phases/38-*` to `.planning/milestones/v1.0-phases/38-*` for exactly
this reason), this `File.read!` raises `File.Error` and the required
stability-contract lane goes red. This is the same stale-path failure mode the
adjacent `refute maintaining =~ ".planning/phases/38-"` guard exists to catch —
reintroduced one line below it.

**Fix:** Either (a) move this release-record assertion out of the inbound
package's `docs_contract_test.exs` into a repo-root test that legitimately owns
`.planning/` references, or (b) make the missing-file case an explicit, readable
skip/flunk rather than a raw `File.read!` crash, and add a regression guard that
the path stays in sync when the phase dir is archived (mirroring the existing
`.planning/phases/38-` guard).

## Info

### IN-01: Single test bundles three unrelated behaviors

**File:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:670-703`
**Issue:** The test "inbound release record exists, carries REL-03 field
headers, and reads pending honestly" asserts (1) REL-03 header presence in the
release record, (2) honest `pending`/`not run` markers, and (3) the unrelated
`MAINTAINING.md` stale-`.planning/phases/38-` regression guard. The MAINTAINING
stale-path check has nothing to do with the release record; bundling it means a
failure message points at the release-record test name while the actual fault is
a docs path regression. `73-02-SUMMARY.md:21` acknowledges this ("Single test
covers all three behaviors") as a deliberate choice, but it hurts diagnosability.
**Fix:** Split the `refute maintaining =~ ".planning/phases/38-"` guard into its
own test (e.g. "MAINTAINING.md carries no stale Phase 38 phases path") so a
failure names the right defect.

### IN-02: `record =~ "Fallback"` comment/intent mismatch

**File:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:679-690`
**Issue:** The loop variable is named `header` and the failure message says
"REL-03 header," but `"Fallback"` and `"smoke"` are not the record's headers
(the labels are `Fallback path used:` and `Post-publish smoke run URL:`). The
naming overstates what is checked. Folded into the WR-02 fix; noted separately
because even if WR-02 is deferred, tightening these two tokens is cheap.
**Fix:** Use the exact field labels (see WR-02) so the variable name `header`
is accurate.

---

_Reviewed: 2026-06-02T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
