---
phase: 179-compatibility-policy-status-map-and-brand-pin
verified: 2026-11-17T23:40:41Z
status: passed
score: 13/13 must-haves verified
covered_files:
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-01-PLAN.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-01-SUMMARY.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-02-PLAN.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-02-SUMMARY.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-03-PLAN.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-03-SUMMARY.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-04-PLAN.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-04-SUMMARY.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-05-PLAN.md
  - .planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-05-SUMMARY.md
  - .planning/phases/183-docs-packaging-and-launch-prep/183-CONTEXT.md
  - .planning/research/brand-v2-adoption/BRPOL-04-PIN-CLOSURE.md
  - .planning/research/brand-v2-adoption/BRPOL-04-PIN-DECISION.md
  - .planning/research/brand-v2-adoption/TRADEMARK-SEARCH.md
  - .planning/research/brand-v2-adoption/trademark-search.json
  - brandbook/.gitignore
  - brandbook/brand.pin.json
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
  - mailglass_admin/priv/static/favicon.svg
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
covered_digest: "v4:sha256:fd07323d7dfb93343f63520cab552e0a4deff4f7b5c784026a6e6770a270b4d0"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 12/13
  gaps_closed:
    - "The active BRPOL-04 and Phase 179 SC4 now agree on the owner-approved v2.0.1 archive SHA-256 3bd4369e0668f89c48bc0755ec3e06be2f1aacf07446dc568b2a248d4c9d0a56."
  gaps_remaining: []
  regressions: []
decision_coverage:
  honored: 26
  total: 26
  not_honored: []
human_verification: []
---

# Phase 179: Compatibility Policy, Status Map and Brand Pin Verification Report

**Phase Goal:** Every later phase works from one tested source of truth: which public names stay, what each status and renamed word says on screen, and which brand book (by hash) is canonical. The trademark search result is on record before anything depends on it.

**Verified:** 2026-11-17T23:40:41Z
**Status:** passed
**Re-verification:** Yes — after the BRPOL-04 pin gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The compatibility policy lists the required public names and says words are glossed, never renamed. | VERIFIED | The compatibility document contains the marker-delimited stays table and gloss rule; its active test parses the live table and checks listed names against source or proof files. |
| 2 | The status map covers all 26 atoms once, maps each to one of six defined classes, rejects unmapped values, and records the inbound same-atom boundary. | VERIFIED | StatusMap has the closed 26-atom table and no catch-all classifier; the source-derived test checks the atom universe, class membership, and unknown values. The previous focused UI audit recorded 303 passing tests. |
| 3 | “Not sent” is a pre-send suppression block, not a persisted suppressed delivery row. | VERIFIED | Preflight checks suppression before persistence; the DB-backed test covers send/2, deliver_later/2, and deliver_many/2 with a non-suppressed positive control. The previous Core audit recorded 82 passing tests. |
| 4 | Copy owns status labels, icons and classes, and a screen-string change without updating Copy fails the copy contract. | VERIFIED | Components delegates status helpers to Copy. The current contract has independent golden, render, and source-scan layers. The recorded M1, M2a, M2b, M3a, and M3b mutation run in 179-01-SUMMARY includes red outputs and green post-restore results. |
| 5 | Phase 179’s status-table extraction preserved prior badge wording; later planned phases can change copy through Copy. | VERIFIED | The Phase 179 baseline comparison recorded 25/25 matching label, icon, and class entries. Later copy changes are routed through Copy and covered by the current copy contract. |
| 6 | The brand pin test passes against the currently approved archive SHA-256 3bd4369e0668f89c48bc0755ec3e06be2f1aacf07446dc568b2a248d4c9d0a56 (v2.0.1). | VERIFIED | Current BRPOL-04, Phase 179 SC4, pin manifest, independent test constant, and source/Admin-served favicon bytes match. The exact focused run exited 0: 76 tests, 0 failures, 0 skipped, 2.4s. Preserved log SHA-256: 1ab9f52c32a0524b413bd94c08bb199a677464c4de7e9338e0e2c0b0db26971b. |
| 7 | Tampering with the recorded hash, shipped assets, path list, or copied bytes fails with a specific cause. | VERIFIED | The offline test contains named hash mismatch, asset tampering, missing/unlisted asset, and unsafe-path cases; the current focused run passed all 76 tests. |
| 8 | The full brand book stays out of the repository; only manifest-listed shipped assets are in the owned directories. | VERIFIED | The pin contract checks exact owned-directory contents and forbidden book paths; the focused run passed. The manifest lists shipped assets only. |
| 9 | The dated trademark/name-search record is at the gate’s consumed path and honestly records unsearched registers and image search. | VERIFIED | The JSON and runbook record the date, sources, outcomes, and not_checked items; the gate loads this record by default. |
| 10 | The announcement gate fails closed and does not imply clearance while sources remain unsearched. | VERIFIED | The current record is caution with register_checked false; gate logic denies announcements and tests cover malformed, missing, expired, and unsupported-clearance cases. |
| 11 | Status precedence handles engagement, failure, delivery, and suppression; the former projection limitation is resolved. | VERIFIED | Current delivery classification tests cover precedence cases. The production query projects lifecycle fields, and the projection test checks bounce-then-open evidence in list and detail rows. |
| 12 | The policy parser/verifier links its table to live symbols and catches missing, duplicate, malformed, or omitted names. | VERIFIED | The test parses the policy table, checks entries by kind, performs a reverse check for Mailglass.Operator modules, and rejects duplicate or malformed rows. |
| 13 | While the committed trademark record denies an announcement, no unsupported ™/® claim appears in covered Markdown. | VERIFIED | The trademark gate scans README, CHANGELOG, docs, guides, and brandbook Markdown; its active test includes planted-symbol coverage. The gate continues to deny claims under the current caution record. |

**Score:** 13/13 truths verified (0 present, behavior-unverified; 0 overrides).

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| mailglass_admin/lib/mailglass_admin/status_map.ex | 26-atom class table and delivery-row classification | VERIFIED | Substantive table, compile-time class validation, and no catch-all classifier. |
| mailglass_admin/lib/mailglass_admin/copy.ex | Status labels/icons/classes and renamed-word map | VERIFIED | Table and vocabulary are present; compile-time checks bind status keys and classes. |
| mailglass_admin/test/mailglass_admin/status_map_test.exs | Source-derived atom universe and precedence checks | VERIFIED | Present and substantive. |
| mailglass_admin/test/mailglass_admin/copy_contract_test.exs | Render and drift contract | VERIFIED | Present; independent golden, render, and closed-set phrase checks are wired. |
| test/mailglass/outbound/suppressed_not_persisted_test.exs | Pre-send suppression persistence proof | VERIFIED | Present; exercises all three send entry points and a positive control. |
| docs/brand-v2-compatibility.md | Public-name inventory and gloss rule | VERIFIED | Live table and marker-delimited gloss section. |
| mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs | Parsed live-code policy proof | VERIFIED | Reads and verifies the policy file. |
| docs/api_stability.md | Link to the compatibility policy | VERIFIED | Current API stability inventory links to the policy. |
| scripts/brand_pin.exs | Immutable archive pin verifier/update script | VERIFIED | Substantive script loaded by the offline test. |
| brandbook/brand.pin.json | Approved archive identity and shipped asset manifest | VERIFIED | Matches the live requirement, roadmap SC4, and independent test oracle. |
| brandbook/v2/brand.json | Shipped contrast and brand data | VERIFIED | Present and included in the tested manifest. |
| test/scripts/brand_pin_test.exs | Offline pin and tamper contract | VERIFIED | Test query and focused execution both pass. |
| scripts/brand_trademark_gate.exs | Fail-closed announcement gate | VERIFIED | Loads the committed search record and denies under caution. |
| .planning/research/brand-v2-adoption/trademark-search.json | Machine-readable search state | VERIFIED | Present and consumed by the gate. |
| .planning/research/brand-v2-adoption/TRADEMARK-SEARCH.md | Search record and remaining-work runbook | VERIFIED | Present; unsearched registers/image search remain explicitly unclaimed. |
| test/scripts/brand_trademark_gate_test.exs | Gate behavior and planted-claim checks | VERIFIED | Present and substantive. |
| .planning/research/brand-v2-adoption/BRPOL-04-PIN-CLOSURE.md | Current pin reconciliation and fresh offline result | VERIFIED | Records the source comparison, protected inventory, exact test command and preserved log digest. |

The five plan artifact queries passed 19/19 checks; duplicate manifest/test artifacts were checked in both applicable plans.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Components status helpers | Copy | Helper delegation | WIRED | status_class/1, status_icon/1, and status_label/1 delegate to Copy readers. |
| Copy | StatusMap | Compile-time key/class checks | WIRED | Copy’s keys and classes are checked against StatusMap. |
| StatusMap test | Components | Source-derived status attr | WIRED | Test reads the live status_badge component metadata. |
| Policy test | Compatibility policy | Marker-delimited parsing | WIRED | Test reads and parses the live document. |
| Core API stability doc | Compatibility policy | Documentation link | WIRED | Current inventory links to the policy. |
| Pin test | Pin verifier script | Code.require_file and function calls | WIRED | Test loads the script and invokes verification against the real tree and tampered copies. |
| Pin manifest | Shipped assets and Admin fonts | Hash and size entries | WIRED | Test verifies owned-directory equality and each listed file’s bytes. |
| Trademark gate | Search JSON | Default path and loader | WIRED | Gate reads the committed record and returns deny for its caution state. |

The generic key-link query returned false negatives for StatusMap source links because it searched for file-path text. Direct source inspection confirms those aliases, delegates, and component metadata reads.

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Operator delivery badge/verdict | Delivery row and outcome groups | Tenant-scoped Repo query in Mailglass.Operator.Deliveries | Yes; projection carries lifecycle fields used by StatusMap | FLOWING |
| Status word and icon | Classified row class/atom | StatusMap then Copy | Yes; pure classification and checked copy table | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command or evidence | Result | Status |
|---|---|---|---|
| Approved archive hash and tamper contract | ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/scripts/brand_pin_test.exs --warnings-as-errors --seed 0 | Preserved run log: exit 0, 76 tests, 0 failures, 0 skipped, 2.4s; SHA-256 1ab9f52c32a0524b413bd94c08bb199a677464c4de7e9338e0e2c0b0db26971b | PASS |
| Copy and status mutation detection | 179-01-SUMMARY recorded mutation run | M1/M2a/M2b/M3a/M3b each show a failing assertion/compile result and green restored result; no mutations were run during this re-verification | PASS (recorded evidence) |
| Earlier focused status/copy and Core audit | Prior verification report | 303 focused UI tests and 82 Core tests were recorded passing; not rerun in this gap-closure pass | PASS (prior evidence) |
| Broad Admin regression | Prior verification report | 1,824 tests recorded with one known favicon producer-SHA mismatch unrelated to this phase; no recapture or alias rerun | Not attributed to Phase 179 |

### Probe Execution

No Phase 179 plan or success criterion declares a probe; no migration/tooling probe applies.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| BRPOL-01 | 179-02 | Public-name compatibility policy and gloss rule | SATISFIED | Policy and active source-verifier test. |
| BRPOL-02 | 179-01 | Source-derived status map and suppression answer | SATISFIED | 26-atom checks and DB-backed zero-row test. |
| BRPOL-03 | 179-01 | Copy ownership and drift contract | SATISFIED | Current delegation and contract; recorded five-mutation proof. |
| BRPOL-04 | 179-03, 179-05 | Approved canonical archive, shipped-only assets, and tamper proof | SATISFIED | Active BRPOL-04/SC4, manifest, independent oracle, and focused test agree on v2.0.1 SHA-256 3bd4369e0668f89c48bc0755ec3e06be2f1aacf07446dc568b2a248d4c9d0a56. |
| BRPOL-05 | 179-04 | Honest search record and fail-closed announcement gate | SATISFIED | Dated caution record and tests for denial/claims. |

No orphaned requirements: BRPOL-01 through BRPOL-05 are all mapped to Phase 179 and claimed by the plans.

### Decision Coverage

All 26 trackable CONTEXT.md decisions are honored by the shipped artifacts.

### Test Quality Audit

| Test File | Linked Requirement | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---|---|---|---|---|
| mailglass_admin/test/mailglass_admin/status_map_test.exs | BRPOL-02 | Yes | 0 | No | Value/behavior | PASS |
| mailglass_admin/test/mailglass_admin/copy_contract_test.exs | BRPOL-03 | Yes | 0 | No | Value/rendered output | PASS |
| test/mailglass/outbound/suppressed_not_persisted_test.exs | BRPOL-02 | Yes | 0 | No | DB behavior | PASS |
| mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs | BRPOL-01 | Yes | 0 | No | Value/source coverage | PASS |
| test/scripts/brand_pin_test.exs | BRPOL-04 | Yes | 0 | No | Value/tamper behavior | PASS |
| test/scripts/brand_trademark_gate_test.exs | BRPOL-05 | Yes | 0 | No | Gate behavior | PASS |
| test/mailglass/operator/deliveries_projection_test.exs | BRPOL-02 | Yes | 0 | No | DB projection behavior | PASS |

No disabled requirement-linked tests or circular expected-value generation were found. File writes are confined to synthetic temporary test fixtures; expected values are independent literals or source inputs.

### Advisory (New Scope, Unevidenced)

None.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| mailglass_admin/lib/mailglass_admin/components.ex | 1085 | HTML placeholder attribute name | Info | Input attribute vocabulary; not a placeholder component. |
| docs/api_stability.md | 1464 | “not yet implemented” | Info | Explicitly reserved v0.5 API hook; outside the Phase 179 goal. |

No unreferenced TBD/FIXME/XXX debt markers or empty implementation patterns were found in the scanned Phase 179 source and test files.

### Human Verification Required

N/A — the phase is a documentation and code-contract foundation with no user-facing flow to test. The trademark record continues to mark USPTO, TMview, WIPO, and image search as not_checked. The fail-closed gate enforces that caution; this report makes no clearance claim. The prior favicon recapture stop remains in effect.

### Gaps Summary

The prior BRPOL-04 gap is closed. The live requirement and roadmap criterion now specify the approved v2.0.1 archive SHA-256, and the manifest, independent test oracle, and source/Admin-served favicon agree with it. The focused offline tamper suite passes. The other Phase 179 truths remain satisfied, all 19 planned artifact checks pass, and no human verification items or remaining gaps were found.

---

_Verified: 2026-11-17T23:40:41Z_
_Verifier: the agent (gsd-verifier)_
