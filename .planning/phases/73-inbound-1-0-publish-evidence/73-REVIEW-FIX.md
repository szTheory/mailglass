---
phase: 73-inbound-1-0-publish-evidence
fixed_at: 2026-06-02T00:00:00Z
review_path: .planning/phases/73-inbound-1-0-publish-evidence/73-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 73: Code Review Fix Report

**Fixed at:** 2026-06-02T00:00:00Z
**Source review:** .planning/phases/73-inbound-1-0-publish-evidence/73-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3 (WR-01, WR-02, WR-03; IN-02 folded into WR-02 per review)
- Fixed: 3
- Skipped: 0

All fixes are confined to the single in-scope source file
`mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`. The test suite
remains green deterministically: `mix test test/mailglass_inbound/docs_contract_test.exs --seed 0`
reports 23 tests, 0 failures after each fix. The release record still carries the
staged-posture marker today, so WR-01's gated asserts continue to run and pass in
the current prepare-and-stage posture.

## Fixed Issues

### WR-01: Test asserts `pending`/`not run` presence, which inverts once the record is filled in

**Files modified:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`
**Commit:** cfcf055c
**Applied fix:** Gated the `record =~ "not run"` and `record =~ "pending"` asserts
behind a `record_staged?` check that detects the
`Tag: mailglass_inbound-v1.0.0 (staged, not cut)` marker, mirroring the existing
`## [Unreleased]` over-claim gating pattern earlier in the file. The markers are
asserted only while the record is in prepare-and-stage posture; once the
maintainer cuts the tag and fills in the post-publish fields, the staged marker
disappears and the asserts correctly stand down rather than blocking the
release-evidence update they are meant to certify. Behavior preserved today: the
record still carries the staged marker, so both asserts run and pass.

### WR-02: Field-header asserts use bare substrings that do not bind to the REL-03 headers

**Files modified:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`
**Commit:** cfaae1da
**Applied fix:** Replaced the loose substring list
(`"Tag"`, `"Fallback"`, `"Hex index"`, `"HexDocs"`, `"smoke"`, `"60-minute"`) with
the exact REL-03 field labels (trailing colon included) as they appear in
`73-01-RELEASE-RECORD.md`: `"Tag:"`, `"Publish workflow run URL:"`,
`"Fallback path used:"`, `"Hex index confirmation:"`, `"HexDocs URLs:"`,
`"Post-publish smoke run URL:"`, `"60-minute outcome:"`. The guard now fails if a
field is renamed or dropped, and the failure message says "field label" so the
loop variable `header` accurately describes what is checked. This also resolves
IN-02 (the comment/intent mismatch on `"Fallback"`/`"smoke"`), which the review
explicitly folded into this fix.

### WR-03: Inbound package unit test hard-reads a repo-root `.planning/` artifact excluded from the package

**Files modified:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`
**Commit:** adaa0d77
**Applied fix:** Took review option (b): resolved the release-record path into a
`record_path` variable and added an explicit `File.exists?/1` guard that `flunk`s
with a readable message instead of letting a raw `File.read!` raise an opaque
`File.Error` when phase 73 is archived/moved. The flunk message names the embedded
phase-dir path and instructs the maintainer to update `record_path` (and keep the
guard) — mirroring the adjacent `.planning/phases/38-` stale-path regression guard
this same failure mode would otherwise reintroduce.

---

_Fixed: 2026-06-02T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
