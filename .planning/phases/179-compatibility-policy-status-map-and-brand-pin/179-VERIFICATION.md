---
phase: 179-compatibility-policy-status-map-and-brand-pin
verified: 2026-11-17T20:38:33Z
status: gaps_found
score: 12/13 must-haves verified
covered_files:
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-01-PLAN.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-01-SUMMARY.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-02-PLAN.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-02-SUMMARY.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-03-PLAN.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-03-SUMMARY.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-04-PLAN.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-04-SUMMARY.md
  - .planning/phases/183-docs-packaging-and-launch-prep/183-CONTEXT.md
  - .planning/research/brand-v2-adoption/TRADEMARK-SEARCH.md
  - .planning/research/brand-v2-adoption/trademark-search.json
  - brandbook/.gitignore
  - brandbook/brand.pin.json
  - brandbook/status-marks.json
  - brandbook/v2/OFL-AtkinsonHyperlegibleMono.txt
  - brandbook/v2/OFL-AtkinsonHyperlegibleNext.txt
  - brandbook/v2/OFL-FunnelDisplay.txt
  - brandbook/v2/avatar-512-dark.png
  - brandbook/v2/avatar-512-light.png
  - brandbook/v2/brand.json
  - brandbook/v2/favicon-16-dark.png
  - brandbook/v2/favicon-16-light.png
  - brandbook/v2/favicon-32-dark.png
  - brandbook/v2/favicon-32-light.png
  - brandbook/v2/favicon.ico
  - brandbook/v2/favicon.svg
  - brandbook/v2/mailglass-lockup-dark.svg
  - brandbook/v2/mailglass-lockup-light.svg
  - brandbook/v2/mailglass-mark-dark.svg
  - brandbook/v2/mailglass-mark-light.svg
  - brandbook/v2/social-card-1280x640.png
  - docs/api_stability.md
  - docs/brand-v2-compatibility.md
  - lib/mailglass/events/event.ex
  - lib/mailglass/operator/deliveries.ex
  - lib/mailglass/outbound.ex
  - lib/mailglass/outbound/delivery.ex
  - lib/mailglass/outbound/persistence.ex
  - lib/mailglass/outbound/preflight.ex
  - lib/mailglass/suppression.ex
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/copy.ex
  - mailglass_admin/lib/mailglass_admin/status_map.ex
  - mailglass_admin/priv/static/fonts/OFL-AtkinsonHyperlegibleMono.txt
  - mailglass_admin/priv/static/fonts/OFL-AtkinsonHyperlegibleNext.txt
  - mailglass_admin/priv/static/fonts/OFL-FunnelDisplay.txt
  - mailglass_admin/priv/static/fonts/a-display-600.woff2
  - mailglass_admin/priv/static/fonts/a-mono-400.woff2
  - mailglass_admin/priv/static/fonts/a-mono-600.woff2
  - mailglass_admin/priv/static/fonts/ui-400.woff2
  - mailglass_admin/priv/static/fonts/ui-400i.woff2
  - mailglass_admin/priv/static/fonts/ui-600.woff2
  - mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs
  - mailglass_admin/test/mailglass_admin/copy_contract_test.exs
  - mailglass_admin/test/mailglass_admin/status_map_test.exs
  - scripts/brand_pin.exs
  - scripts/brand_trademark_gate.exs
  - test/mailglass/operator/deliveries_projection_test.exs
  - test/mailglass/outbound/suppressed_not_persisted_test.exs
  - test/scripts/brand_pin_test.exs
  - test/scripts/brand_trademark_gate_test.exs
covered_digest: "v4:sha256:bdf18ec1b5d0c1a1da84c3ec3595f43c693520d2f3adb98e7bfe0054d7e55a8a"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The brand pin test passes against zip sha256 ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b as required by Phase 179 SC4 and BRPOL-04."
    status: failed
    reason: "The current manifest and test-owned expected hash both pin 3bd4369e0668f89c48bc0755ec3e06be2f1aacf07446dc568b2a248d4c9d0a56 (brand v2.0.1), not the required ed96bb... (v2.0). Phase 183 documents an owner-approved favicon correction, so the current pin is internally consistent, but the roadmap and requirement still specify the old digest."
    artifacts:
      - path: "brandbook/brand.pin.json"
        issue: "sha256 is 3bd4369e0668f89c48bc0755ec3e06be2f1aacf07446dc568b2a248d4c9d0a56."
      - path: "test/scripts/brand_pin_test.exs"
        issue: "@expected_zip_sha256 asserts the new 3bd436... value."
      - path: ".planning/REQUIREMENTS.md"
        issue: "BRPOL-04 still requires the old ed96bb... digest."
      - path: ".planning/ROADMAP.md"
        issue: "Success criterion 4 still requires the old ed96bb... digest."
    missing:
      - "Reconcile BRPOL-04 and Phase 179 SC4 with the owner-approved current pin hash, or restore the original pinned archive and test expectation."
---

# Phase 179: Compatibility Policy, Status Map and Brand Pin Verification Report

**Phase Goal:** Every later phase works from one tested source of truth: which public names stay, what each status and renamed word says on screen, and which brand book (by hash) is canonical. The trademark search result is on record before anything depends on it.
**Verified:** 2026-11-17T20:38:33Z
**Status:** gaps_found
**Re-verification:** No (the existing Nov 14 report had no `gaps:` section; this is a fresh goal-backward pass)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The compatibility policy lists the required public names and says words are glossed, never renamed. | ✓ VERIFIED | `docs/brand-v2-compatibility.md` has the marker-delimited stays table, all required module/macro/function/enum/schema/topic/telemetry/router names, a separate gloss table, and cites the relevant tests. `BrandV2CompatPolicyTest` parses the live table and checks each row against loaded code or its proof file. |
| 2 | The status map covers all 26 atoms once, maps each to one of the six defined classes, rejects unmapped values, and records the inbound same-atom boundary. | ✓ VERIFIED | `StatusMap` table has 26 keys and no catch-all `classify/1`; `status_map_test.exs` derives the universe from source and the component status attribute, checks both directions, exact class values/counts, nil and synthetic-key failure, and inbound overlap. Current shared focused UI evidence: 303 tests passed, 0 failures (302 excluded). |
| 3 | “Not sent” is a pre-send suppression block, not a persisted suppressed delivery row. | ✓ VERIFIED | The compatibility doc and source comment state the result; suppression is checked in `Preflight` before persistence; the DB-backed test exercises all three send entry points with a non-suppressed positive control. The current shared Core result was 82 passing tests. |
| 4 | `Copy` is the owner of status labels, icons and classes, with render and copy-contract checks that detect drift. | ✓ VERIFIED | `Components` delegates to `Copy`; `Copy` compile-time keys equal `StatusMap.atoms() -- [:subscribed]`; contract tests render badges and compare exact visible text to the copy table, with closed-set phrase checks. Current shared focused UI evidence: 303 tests passed, 0 failures (302 excluded). |
| 5 | Phase 179’s status-table extraction preserved the prior badge wording; later planned phases can then change copy through `Copy`. | ✓ VERIFIED | The Nov 14 phase report recorded a 25/25 label/icon/class baseline comparison. Current Phase 182 changes are later, scoped copy work; current contract checks are green in the shared focused UI run. This row describes the Phase 179 change, not a ban on later planned work. |
| 6 | The brand pin test passes against the required archive SHA-256 `ed96bb...`. | ✗ FAILED | Current pin and test-owned expected hash are both `3bd436...` (v2.0.1), not the literal Phase 179/BRPOL-04 value. Phase 183 documents the owner-approved favicon correction and reports the new pin test passing, but no accepted update to the Phase 179 hash contract is recorded. See the structured gap above. |
| 7 | Tampering with the recorded hash, shipped assets, path list, or copied bytes fails with a specific cause. | ✓ VERIFIED | Current `BrandPinTest` owns the expected archive hash and contains named cases for zip-hash mismatch, shipped-member tampering, missing/unlisted assets and unsafe paths. The current shared Core result is 82 passing tests; Phase 183’s summary records the updated pin suite passing against the new digest. |
| 8 | The full brand book stays out of the repository; only manifest-listed shipped assets are in the owned directories. | ✓ VERIFIED | `brandbook/.gitignore` excludes the book directories; current pin ownership names `brandbook/v2` and Admin fonts, and the test checks exact owned-directory contents and forbidden book paths. The book itself is not in the manifest-owned tree. |
| 9 | The dated trademark/name-search record is committed at the path consumed by the gate, and honestly records unsearched registers/image search. | ✓ VERIFIED | The JSON has date 2026-11-13, classes 9/38/42, sources with URL/outcome/tier/retrieved/note, `overall: caution`, `register_checked: false`, and `owner_override: null`; the Markdown runbook identifies USPTO/TMview/WIPO/image search as `not_checked`. The gate reads this record by default. |
| 10 | The announcement gate fails closed and does not imply clearance while sources remain unsearched. | ✓ VERIFIED | `announcement_allowed?/1` delegates to the injected-date pure check; current record is `caution` and `register_checked: false`, so the path denies. Tests cover malformed/missing/expired records, unsupported clear/register claims and the blocked announcement path. |
| 11 | Status precedence handles engagement, failure, delivery and suppression correctly; the former three-field projection limitation is resolved. | ✓ VERIFIED | Current `delivery_class/1` tests cover late engagement, durable failure, dormant suppression and delivery precedence. The production query in `lib/mailglass/operator/deliveries.ex` now projects lifecycle fields; `deliveries_projection_test.exs` checks bounce-then-open evidence reaches both list/detail rows. This closes the Phase 179 hand-off via Phase 182. |
| 12 | The policy parser/verifier links its table to live symbols and catches missing, duplicate, malformed or omitted names. | ✓ VERIFIED | Policy rows are parsed from the doc itself, verified by kind, checked in reverse for every `Mailglass.Operator.*` module, and guarded by required-name, marker, row-order and duplicate tests. The API stability doc links to the policy. |
| 13 | While the committed trademark record denies an announcement, no unsupported ™/® claim appears in the covered markdown. | ✓ VERIFIED | The trademark gate test scans README, CHANGELOG, docs, guides and brandbook markdown, with planted-symbol coverage. Current gate code retains the denial and the shared Core result is 82 passing tests. |

**Score:** 12/13 truths verified (0 present, behavior-unverified; 0 overrides).

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/status_map.ex` | 26-atom class table and delivery-row classification | VERIFIED | Substantive table, compile-time class validation, no catch-all classifier. |
| `mailglass_admin/lib/mailglass_admin/copy.ex` | Status labels/icons/classes and renamed-word map | VERIFIED | Table, vocabulary and class labels are present; compile-time key checks bind to StatusMap. |
| `mailglass_admin/test/mailglass_admin/status_map_test.exs` | Source-derived atom universe and edge/precedence checks | VERIFIED | Current test contains 26-atom, exact-class, unmapped and row-precedence assertions. |
| `mailglass_admin/test/mailglass_admin/copy_contract_test.exs` | Render and drift contract | VERIFIED | Active contract exercises badge rendering, exact copy and closed-set phrases. |
| `docs/brand-v2-compatibility.md` | Public-name inventory and gloss rule | VERIFIED | Live table and two parsed marker regions. |
| `mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs` | Parsed live-code policy proof | VERIFIED | Present and wired to the doc. |
| `scripts/brand_pin.exs`, `brandbook/brand.pin.json`, `test/scripts/brand_pin_test.exs` | Pinned archive with tamper proof | PARTIAL | Current v2.0.1 pin and test agree with each other; they do not satisfy the literal Phase 179/BRPOL-04 SHA. |
| `scripts/brand_trademark_gate.exs`, search JSON/Markdown, gate tests | Cautious record and fail-closed decision | VERIFIED | Gate loads the committed record; current record denies announcement. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `components.ex` | `copy.ex` | Status helper delegates | WIRED | `status_class/1`, `status_icon/1`, and `status_label/1` delegate to `Copy.*_or_unknown/1`. |
| `copy.ex` | `status_map.ex` | Compile-time key/class checks | WIRED | `Copy` aliases `StatusMap`; compile-time checks bind status keys and classes. |
| `status_map_test.exs` | `components.ex` | Status badge attr is source-derived oracle | WIRED | Test aliases `Components` and reads `Components.__components__().status_badge.attrs`. |
| Policy test | `docs/brand-v2-compatibility.md` | Marker-delimited parse | WIRED | The test reads and parses the live doc. |
| `docs/api_stability.md` | Policy | Absolute GitHub URL | WIRED | Current API stability inventory points to the compatibility policy. |
| `test/scripts/brand_pin_test.exs` | `scripts/brand_pin.exs` | `Code.require_file` and calls | WIRED | Test loads the script and checks real-tree verification plus tamper cases. |
| `brand.pin.json` | `brandbook/v2` and Admin fonts | Manifest hash/size entries | WIRED | The test compares owned directories with the shipped list and checks bytes against each digest. |
| Gate script | Search JSON | Default path and loader | WIRED | The CLI loads the committed record and returns deny for its current caution state. |

The generic key-link checker reported false negatives for the three StatusMap links because it searched source text for file paths. Direct source inspection confirms the module aliases, delegates and component metadata reads above.

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Operator delivery badge/verdict | delivery row and outcome groups | Tenant-scoped `Repo.all` query in `Mailglass.Operator.Deliveries` | Yes; DB projection carries the lifecycle fields read by StatusMap | FLOWING |
| Status word and icon | classified row class / atom | `StatusMap` then `Copy` | Yes; pure classification and checked copy table | FLOWING |

### Behavioral Spot-Checks

| Behavior | Evidence | Result | Status |
|---|---|---|---|
| Focused UI/status/copy checks | Shared current audit result | 303 tests passed, 0 failures; 302 excluded | PASS |
| Core checks | Shared current audit result | 82 tests passed | PASS |
| Broad Admin regression suite | Shared current audit result | 1,824 tests; one known `FaviconCatalogTest` producer-SHA mismatch against the current favicon | NOT ATTRIBUTED TO PHASE 179 |

The Admin failure is the known pre-existing favicon evidence mismatch and is not counted as a Phase 179 regression. The browser recapture and alias rerun remain prohibited; neither was attempted here. Phase summaries’ older individual test and mutation counts are historical evidence, not current reruns.

### Probe Execution

No phase-declared or conventional Phase 179 probe applies.

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|---|---|---|---|
| BRPOL-01 | 179-02 | SATISFIED | Compatibility table and active parser/verifier test. |
| BRPOL-02 | 179-01 | SATISFIED | 26-atom source-derived table, precedence and suppression tests. |
| BRPOL-03 | 179-01 | SATISFIED | Copy ownership and rendering contract tests. |
| BRPOL-04 | 179-03 | BLOCKED | Required literal hash is ed96bb...; current approved pin and test use 3bd436... . |
| BRPOL-05 | 179-04 | SATISFIED | Dated search record and fail-closed gate tests. |

No orphaned requirements: REQUIREMENTS.md maps BRPOL-01..05 to Phase 179, and all five appear in PLAN frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `mailglass_admin/lib/mailglass_admin/components.ex` | 1085 | `placeholder` HTML attribute name | Info | Input attribute vocabulary; not a stub or placeholder UI. |

No unreferenced TBD/FIXME/XXX debt markers were found in the phase implementation/test files scanned.

### Human Verification Required

N/A for Phase 179’s software acceptance criteria. The trademark record explicitly keeps USPTO, TMview, WIPO and image search at `not_checked`; the fail-closed gate denies announcements until owner/counsel resolves them. This phase records the caution state and makes it enforceable; it does not claim clearance.

### Gaps Summary

The compatibility policy, status map, copy contract, lifecycle projection, and cautious trademark gate are present and wired. One must-have remains unmet as written: the current canonical brand archive is v2.0.1 at SHA-256 `3bd436…`, while Phase 179 SC4 and BRPOL-04 still require v2.0 at `ed96bb…`. Phase 183 documents the owner-approved correction, but the Phase 179 contract has not been reconciled. The broad Admin run’s known favicon catalog mismatch is excluded from this verdict per the shared gate instruction.

---

_Verified: 2026-11-17T20:38:33Z_
_Verifier: the agent (gsd-verifier)_

