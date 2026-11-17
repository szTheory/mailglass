---
phase: 179-compatibility-policy-status-map-and-brand-pin
reviewed: 2026-11-17T18:40:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/status_map.ex
  - mailglass_admin/lib/mailglass_admin/copy.ex
  - mailglass_admin/lib/mailglass_admin/components.ex
  - scripts/brand_pin.exs
  - scripts/brand_trademark_gate.exs
  - mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs
  - mailglass_admin/test/mailglass_admin/copy_contract_test.exs
  - mailglass_admin/test/mailglass_admin/status_map_test.exs
  - test/mailglass/outbound/suppressed_not_persisted_test.exs
  - test/scripts/brand_pin_test.exs
  - test/scripts/brand_trademark_gate_test.exs
  - brandbook/brand.pin.json
  - docs/brand-v2-compatibility.md
  - docs/api_stability.md
findings:
  critical: 1
  warning: 5
  info: 0
  total: 6
  necessity: 0
status: issues_found
---

# Phase 179: Code Review Report

**Reviewed:** 2026-11-17T18:40:00Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Reviewed the Phase 179 status and copy contracts, compatibility policy, brand pin tooling,
trademark gate, and their related tests. The trademark scanner has a fail-open case for
semicolonless HTML character references. Other findings concern status precedence, contract
proofs that accept documentation text as code, conflicting compatibility promises, partial
asset writes, and a CLI test that can mutate the real brand tree if its hash guard regresses.
No tests were run as part of this read-only review. The configured agent-skills query returned
no project skills; `necessity-review.md` was read and no necessity finding met its evidence
threshold.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Semicolonless HTML character references bypass the trademark claim gate

**Severity:** BLOCKER
**File:** `scripts/brand_trademark_gate.exs:737`
**Issue:** The scanner recognizes `&#` as a possible claim marker, but the decoder and the
registered/unregistered mark patterns only accept HTML references ending in `;`. HTML accepts
numeric character references without a semicolon, so text such as `<p>mailglass &#174 </p>`
renders as a registered-mark claim but remains unchanged through `decode_claim_encodings/1`.
`line_claims/1` then returns no mark, and `scan_public_claims/3` reaches its `:no_claims` allow
branch. The same gap applies to semicolonless `&#8482` claims. This bypasses the gate that is
meant to deny registered-mark claims and require a current record for unregistered-mark claims.
**Fix:** Decode HTML references with an HTML tokenizer/parser or handle the HTML-defined
semicolonless forms and their boundaries; add cases such as `&#174 ` and `&#8482 ` to the claim
gate tests and assert they are detected.

## Warnings

### WR-01: A suppressed row with a terminal latch is classified as Failed

**Severity:** WARNING
**File:** `mailglass_admin/lib/mailglass_admin/status_map.ex:132`
**Issue:** `durable_failure?/2` treats `terminal: true` as a failure when there is no
`suppressed_at`, while the following suppression clause also recognizes `status: :suppressed`
and `last_event_type: :suppressed`. Thus a row like `%{status: :suppressed, terminal: true}`
matches the failure clause first and is labelled Failed, contradicting the status map's
`:suppressed -> :not_sent` mapping. The function's documented map contract says omitted keys are
read as `nil`, so this shape is accepted rather than rejected.
**Fix:** Compute suppression from status, last event, and `suppressed_at` before testing the
terminal failure latch, and exclude suppressed rows from durable failure detection. Add a
terminal-latch suppressed row to the precedence tests.

### WR-02: `grep` compatibility proofs pass when the implementation is removed

**Severity:** WARNING
**File:** `mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs:251`
**Issue:** A `grep` row passes if its token occurs anywhere in the proof file. The three router
rows for `deliveries_path`, `live_session_name`, and `account_labels` all occur in the router's
moduledoc, so deleting the corresponding NimbleOptions keys while leaving the documentation
would keep those compatibility checks green. The test therefore does not prove the implementation
exists as its module documentation and policy claim.
**Fix:** Check the parsed router option schemas or remove documentation/comments before matching;
add a planted test where a token appears only in a docstring and must fail.

### WR-03: Compatibility policy contradicts the published stability inventory

**Severity:** WARNING
**File:** `docs/brand-v2-compatibility.md:31` and `docs/api_stability.md:120`
**Issue:** The compatibility table describes its rows as public names protected by the
deprecation and major-version policy, but it includes `Mailglass.Operator.SupportSummary` and
`read_orphan_backlog/1`, which the stability inventory explicitly classifies as sibling-package
only and outside the general adopter promise. The table also includes `Mailglass.Operator.Tenants`,
which is outside the inventory's documented stable operator subset. The reverse test requires a
row for every `Mailglass.Operator.*` module, extending the contradiction to future internal
modules. Readers and maintainers cannot tell which stability promise governs these names.
**Fix:** Reconcile the two documents: limit the major-version promise and reverse check to the
documented stable subset, or explicitly distinguish first-party coordination names from public
adopter commitments.

### WR-04: Brand pin writes assets in place before the manifest, leaving partial updates on error

**Severity:** WARNING
**File:** `scripts/brand_pin.exs:817`
**Issue:** `write_all/3` writes each shipped asset directly to its final path and only then
atomically renames the pin. If a later asset write, the pin write, or the process itself fails,
earlier assets have already replaced their old versions while the old pin remains. The resulting
tree fails verification and may contain a mix of brand versions; writing the pin atomically does
not make the asset set atomic.
**Fix:** Stage all assets and the new pin before replacing live files, then use a rollback or
same-filesystem swap strategy so any failed update restores the previous tree.

### WR-05: The CLI update test can overwrite the repository's real brand assets

**Severity:** WARNING
**File:** `test/scripts/brand_pin_test.exs:1113`
**Issue:** The test invokes `cli` with `update` against the real pin and passes synthetic archive
bytes with an intentionally wrong hash. The CLI has no target-directory option, so if the hash
guard regresses, `update` writes to the repository tree. This contradicts the test file's claim
that mutations stay under each ExUnit `tmp_dir` and makes a failing regression test capable of
corrupting its own fixture/repository state.
**Fix:** Add an injectable target directory to the CLI test seam and pass a temporary tree, or
remove this real-tree mutation case and exercise the update refusal using the existing temporary
tree API.

---

_Reviewed: 2026-11-17T18:40:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
