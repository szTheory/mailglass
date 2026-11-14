---
phase: 179-compatibility-policy-status-map-and-brand-pin
verified: 2026-11-14T01:10:00Z
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
  - .planning/research/brand-v2-adoption/TRADEMARK-SEARCH.md
  - .planning/research/brand-v2-adoption/trademark-search.json
  - brandbook/.gitignore
  - brandbook/brand.pin.json
  - brandbook/v2/OFL-AtkinsonHyperlegibleMono.txt
  - brandbook/v2/OFL-AtkinsonHyperlegibleNext.txt
  - brandbook/v2/OFL-FunnelDisplay.txt
  - brandbook/v2/brand.json
  - docs/api_stability.md
  - docs/brand-v2-compatibility.md
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/copy.ex
  - mailglass_admin/lib/mailglass_admin/status_map.ex
  - mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs
  - mailglass_admin/test/mailglass_admin/copy_contract_test.exs
  - mailglass_admin/test/mailglass_admin/status_map_test.exs
  - scripts/brand_pin.exs
  - scripts/brand_trademark_gate.exs
  - test/mailglass/outbound/suppressed_not_persisted_test.exs
  - test/scripts/brand_pin_test.exs
  - test/scripts/brand_trademark_gate_test.exs
covered_digest: "v4:sha256:adc17f6f1a2cba8db647eb43c436c07c2521905a9ac3fa4f5a99bf0e63bba142"
behavior_unverified: 0
overrides_applied: 0
deferred:
  - truth: "A bounce followed by an open reads Sent on the operator Deliveries row (the projection lacks bounced_at and terminal)"
    addressed_in: "Phase 182"
    evidence: "ROADMAP.md line 149, 'Hand-off from Phase 179': add bounced_at and terminal to Mailglass.Operator.Deliveries.delivery_projection/1 before showing a StatusMap.delivery_class/1 verdict, or show the limitation on screen"
---

# Phase 179: Compatibility Policy, Status Map and Brand Pin Verification Report

**Phase Goal:** Every later phase works from one tested source of truth: which public names stay, what each status and renamed word says on screen, and which brand book (by hash) is canonical. The trademark search result is on record before anything depends on it.
**Verified:** 2026-11-14
**Status:** passed
**Re-verification:** No, initial verification

All verification below was run by the verifier in its own processes. SUMMARY claims were treated as hypotheses, not evidence. Every mutation recorded in a SUMMARY that bears on a success criterion was re-run independently and restored (working tree clean afterward apart from the pre-existing `.planning/state.json` edit).

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1: the compatibility policy file lists every public name that stays (`Mailglass.Operator.*`, `mailglass_operator_routes`, `:operator_access`, `tenant_id`, `:orphan_backlog`, telemetry names, `Delivery.status`) plus the gloss-not-rename rule | VERIFIED | `docs/brand-v2-compatibility.md` read in full: 26-row marker-delimited table (7 Operator modules, `mailglass_operator_routes/1,2`, `read_orphan_backlog/1`, three enums, `tenant_id` on 3 schemas + router session key + mount URL param + topic, `:operator_access`, `:orphan_backlog`, 2 telemetry names, 3 router options). Line 7 states "On-screen and docs words are glossed, never renamed"; 4-row gloss table. `brand_v2_compat_policy_test.exs` parses the table (no second list): 28 tests, 0 failures. `docs/api_stability.md:9` links it by absolute URL. |
| 2 | SC2a: status map covers all 26 atoms, each in exactly one class; an unmapped atom fails | VERIFIED | `StatusMap.atoms()` returns 26; class counts measured `sent 3, delivered 1, delayed 1, failed 3, not_sent 1, not_a_delivery_status 17`. `classify/1` has no catch-all clause. `status_map_test.exs` 31 tests pass. Independent mutation M3a (delete `subscribed:` line): exit 2, 6 failures, message `Missing from the table: [:subscribed]`; restored, 31/0. |
| 3 | SC2b: "is Not sent ever a persisted `Delivery.status :suppressed` row?" is answered with the settling code path | VERIFIED | Answer: no, pre-send block only. Verifier grep of `lib/` found no writer of `status: :suppressed` (only the enum member at `delivery.ex:56`, the projector timestamp mapping, and `{:suppressed, entry}` check tuples). `Preflight.run/1` calls `Suppression.check_before_send/1` before any insert; `deliver_many` builds an uninserted `:failed` delivery via `Persistence.build_failed_delivery/2` (`outbound.ex:365`). Recorded in `status_map.ex` comment, policy doc "Not sent" section, and proven by `suppressed_not_persisted_test.exs` (DB-backed, 4 tests, positive control) which passed in the core run (89 tests, 0 failures). |
| 4 | SC3: changing a screen string owned by `Copy` without updating `Copy` fails the copy contract test; a recorded mutation run proves it | VERIFIED | Independent re-run. M1 (`"Delivered"` to `"Delivered!"` in `copy.ex`): exit 2, 2 failures, both layer 1. M2b (hardcode `defp status_label(:delivered), do: "Delivered!"` in `components.ex`): exit 2, 2 failures (layer 2 render, layer 3b phrase set). Each restored via `git checkout`, then 23/0. The SUMMARY mutation record (M1, M2a, M2b, M3a, M3b) matches what I observed. |
| 5 | Prohibition (BRPOL-03): no visible screen text changed; every badge label, icon and class equals the pre-phase value | VERIFIED | Verifier script compared the 25 `defp status_label/status_icon/status_class` clauses in pre-phase `components.ex` (`53f6d872`) to `Copy.statuses/0`: 25/25/25 clauses, `diffs: []`, `old-only atoms: []`. Neighbors green: components, voice, admin_shell, operator/shell, stability_contract, operator_trust_doc, brand, token_parity (183 tests, 0 failures). |
| 6 | SC4a: brand pin test passes against zip sha256 `ed96bb25...f87b` | VERIFIED | `brandbook/brand.pin.json` pins `szTheory/mailglass-brand` at commit `240bdd21...`, sha256 `ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b`, size 1943435; the test owns the same literal (`brand_pin_test.exs:15`). `mix run --no-start scripts/brand_pin.exs verify` prints `brand pin ok` (exit 0, dev and `MIX_ENV=test`). Advisory online check run by the verifier: `advisory check ok`, exit 0 (the real zip at the pinned commit hashes to the pinned value). |
| 7 | SC4b: the test fails when the recorded hash or a copied-in shipped asset is altered | VERIFIED | Independent real-tree mutations. P3 (append a byte to `brandbook/v2/OFL-FunnelDisplay.txt`): exit 2, 5 failures, `asset_size_mismatch`. P2 (flip top-level `sha256` in the pin): exit 2, 1 failure, `zip_hash_unexpected: "fd96bb25..."`. Both restored; `git status --porcelain brandbook` empty; suite 54 tests, 0 failures. |
| 8 | SC4c: the full book is not in the repository tree | VERIFIED | `git ls-files -co --exclude-standard` filtered for `brand/`, `*.zip`, `BRAND.md`, `mailglass-brand-book.html`, `mailglass-one-page.html`, `mailglass-brand/` returns no paths. `brandbook/.gitignore` holds `/brand/` and `/mailglass-brand/`. `brandbook/v2/` holds exactly the 4 shipped files. Tree-guard test is in the passing suite. |
| 9 | SC5a: trademark/image/register search result is committed with date, sources and outcome, where Phase 183 reads its gate | VERIFIED | `.planning/research/brand-v2-adoption/trademark-search.json`: date 2026-11-13, mark, variants, classes `[9,38,42]`, `overall: caution`, `register_checked: false`, `owner_override: null`, `expires: 2027-05-12`, 16 sources each with url/outcome/tier/retrieved. `uspto`, `tmview`, `wipo`, `image_search` honestly `not_checked`; `rdap_com`/`rdap_app` `caution`. `TRADEMARK-SEARCH.md` holds findings and a 7-step owner runbook with full URLs (34 `https://` references). Entry point `announcement_allowed?/1` exists for Phase 183. |
| 10 | SC5b: the gate is fail-closed and the record is honest (no agent-written `clear`) | VERIFIED | CLI under dev and under `MIX_ENV=test` both print `deny (not_clear): overall=caution register_checked=false expires=2027-05-12` and exit 1 (the critical review finding CR-01 is fixed: entrypoint now keys on `:script_library_mode`, not `Mix.env()`; subprocess regression tests added in `8c333f59`). 30-test gate suite passes in the core run. |
| 11 | Plan 01 ordering/edge truths: engagement never implies delivered or erases a confirmed delivery; a bounce is never hidden when durable fields are present; the three-field operator-row limitation is pinned and handed off | VERIFIED | Verifier calls: row with `bounced_at` and `last_event_type: :opened` reads `:failed`; the 3-field operator row `sent/opened` reads `:sent` (the pinned limitation). `status_map_test.exs` includes the table-driven precedence cases and the 29-divergence grid oracle (passing). `grep "Hand-off from Phase 179" .planning/ROADMAP.md` returns line 149 (count 1). See WR-07 below for a fixture-only edge. |
| 12 | Plan 02 truths: every row verified by kind; reverse check over `Mailglass.Operator.*`; false-green guards; policy cites existing proof files | VERIFIED | 28-test policy suite passes (parser, seven verifier kinds, reverse check, duplicate/required-name/cited-path guards, teeth). Seven `lib/mailglass/operator/*.ex` modules match the seven module rows. See WR-03 and WR-04 below. |
| 13 | Plan 04 prohibition: no trademark or registered-mark symbol appears in README, CHANGELOG, docs, guides or brandbook markdown while the record denies | VERIFIED | Verifier symbol scan of the repo (excluding vendored dirs and `.planning`) found only the test file itself and `brandbook/v2/brand.json:911` (vendored book text: "No trademark registration is claimed ... Use the TM sign, not the R-in-circle, only if the maintainers decide to claim the name"), which is a policy statement, not a claim, and is not markdown. Scan test passes. |

**Score:** 13/13 truths verified (0 present, behavior-unverified; 0 overrides)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|--------------|----------|
| 1 | A bounce followed by an open reads Sent on the operator Deliveries row (projection lacks `bounced_at` and `terminal`) | Phase 182 | ROADMAP.md:149 "Hand-off from Phase 179": add the two fields to `delivery_projection/1` before showing a `delivery_class/1` verdict, or show the limitation on screen. Pinned by the named test `operator row limitation: a bounce overwritten by a later open reads sent`. (Review finding WR-08.) |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `mailglass_admin/lib/mailglass_admin/status_map.ex` | 26-atom table, `classify/1` no catch-all, `classify_or_unknown/1`, `delivery_class/1` | VERIFIED | 158 lines, compile-time class validation, behavior exercised (see above). |
| `mailglass_admin/lib/mailglass_admin/copy.ex` | single owner of status label/icon/class, strict + fallback readers, vocabulary, class labels | VERIFIED | 175 lines; compile-time assertion that keys equal `StatusMap.atoms() -- [:subscribed]` (M3b in SUMMARY shows the compile error). |
| `mailglass_admin/lib/mailglass_admin/components.ex` | status helpers delegate to `Copy` | VERIFIED | Three one-line delegates (`components.ex:1664-1666`); 86 lines of clauses removed; output identical to pre-phase. |
| `mailglass_admin/test/.../status_map_test.exs` | universe, table, teeth, precedence, grid | VERIFIED | 31 tests, 0 failures. |
| `mailglass_admin/test/.../copy_contract_test.exs` | three-layer contract | VERIFIED | 23 tests, 0 failures; mutation-proven. |
| `test/mailglass/outbound/suppressed_not_persisted_test.exs` | DB-backed zero-row proof | VERIFIED | 4 tests pass. |
| `docs/brand-v2-compatibility.md` | policy with stays table, gloss, Not sent | VERIFIED | Read in full. |
| `mailglass_admin/test/.../brand_v2_compat_policy_test.exs` | parser, verifier, reverse check | VERIFIED | 28 tests, `async: true`. |
| `docs/api_stability.md` | one pointer line | VERIFIED | Line 9, absolute URL. |
| `scripts/brand_pin.exs`, `brandbook/brand.pin.json`, `brandbook/v2/*` (4), `brandbook/.gitignore`, `test/scripts/brand_pin_test.exs` | pin, shipped assets, tamper suite | VERIFIED | 54 tests; `verify` ok; online check ok. |
| `scripts/brand_trademark_gate.exs`, `trademark-search.json`, `TRADEMARK-SEARCH.md`, `test/scripts/brand_trademark_gate_test.exs` | gate, record, runbook, tests | VERIFIED | 31 tests in core run (30 + 1 CR-01 regression). |
| `.planning/publish/mailglass_admin-files.expected` | lists `copy.ex` and `status_map.ex` | VERIFIED | Lines 21 and 73; `mix mailglass.publish.check --allowlist-only` `conflict=0`. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `components.ex` | `copy.ex` | `status_*` delegate to `Copy.status_*_or_unknown/1` | WIRED | Lines 1664-1666. |
| `copy.ex` | `status_map.ex` | compile-time key equality | WIRED | `copy.ex:120-128`. |
| `status_map_test.exs` | `components.ex` | `__components__().status_badge` attr values as independent oracle | WIRED | Test passes. |
| policy test | `docs/brand-v2-compatibility.md` | parsed between `compat-table` markers | WIRED | 28 tests parse the live file. |
| `api_stability.md` | policy | absolute GitHub URL | WIRED | Line 9. |
| `brand_pin_test.exs` | `brand_pin.exs` | `Code.require_file` in `setup_all` under library mode | WIRED | Passes; CLI subprocess test also passes. |
| `brand.pin.json` | `brandbook/v2/*` | `shipped[].to` with sha256 and bytes | WIRED | Tamper mutations P2/P3 reproduced. |
| gate script | `trademark-search.json` | `@default_path` read by `load/1` and `check` | WIRED | CLI reads and denies. |

### Data-Flow Trace (Level 4)

Not applicable. This phase delivers pure maps, tables, scripts and docs; no component renders dynamic data from a query. The one render path (`status_badge`/`outcome_badge`) reads the static `Copy` table, and layer 2 of the contract test renders it for every atom.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Admin phase tests | `mix test status_map_test copy_contract_test brand_v2_compat_policy_test --seed 0` (in `mailglass_admin/`) | 82 tests, 0 failures | PASS |
| Core phase tests | `mix test brand_pin_test brand_trademark_gate_test suppressed_not_persisted_test --seed 0` | 89 tests, 0 failures | PASS |
| Admin regression neighbors | components, voice, admin_shell, operator/shell, stability_contract, operator_trust_doc, brand, token_parity | 183 tests, 0 failures, 1 excluded | PASS |
| Core docs contract | `mix test test/mailglass/docs_contract_test.exs --seed 0` | 61 tests, 0 failures, 1 skipped | PASS |
| Pin verify, both envs | `mix run --no-start scripts/brand_pin.exs verify` (dev, `MIX_ENV=test`) | `brand pin ok`, exit 0 | PASS |
| Gate CLI, both envs | `mix run --no-start scripts/brand_trademark_gate.exs check` | `deny (not_clear)...`, exit 1, non-empty in both envs | PASS |
| Advisory online pin check | `mix run --no-start scripts/brand_pin.exs check` | `advisory check ok`, exit 0 | PASS |
| Publish allowlist | `MIX_ENV=test mix mailglass.publish.check --allowlist-only` | `conflict=0` | PASS |
| Formatting | `mix format --check-formatted` on all phase `.ex/.exs` files (root and admin) | exit 0 | PASS |
| Lock files | `git diff 53f6d872 HEAD -- mix.lock mailglass_admin/mix.lock` | no diff | PASS |

### Probe Execution

No phase-declared `probe-*.sh` scripts and no `scripts/*/tests/probe-*.sh` apply. Step 7c: SKIPPED (none declared).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BRPOL-01 | 179-02 | Compatibility policy lists every name that stays and states words are glossed, not renamed | SATISFIED | Truths 1 and 12. |
| BRPOL-02 | 179-01 | Pure, unit-tested status map over 26 atoms; Not sent question answered from code | SATISFIED | Truths 2, 3, 11. REQUIREMENTS.md and ROADMAP SC2 both say 26. |
| BRPOL-03 | 179-01 | `Copy` holds the status-label and renamed-word map; contract test fails on drift | SATISFIED | Truths 4, 5. Status labels are enforced now; the renamed-word entries are data (`wired: false` except `:account`) and bind when Phase 182 flips them (see IN-04, WR-05, WR-06). |
| BRPOL-04 | 179-03 | Brand book pinned by zip sha256 with tamper test; full book out of repo | SATISFIED | Truths 6, 7, 8. |
| BRPOL-05 | 179-04 | Trademark, image and register search results recorded in the repo | SATISFIED | Truths 9, 10, 13. Register/image searches are recorded as `not_checked`, an owner hand-off per D-23. |

No orphaned requirements: `grep "Phase 179" .planning/REQUIREMENTS.md` maps exactly BRPOL-01..05, and all five appear in plan frontmatter (01: BRPOL-02/03, 02: BRPOL-01, 03: BRPOL-04, 04: BRPOL-05). REQUIREMENTS.md marks all five `[x]` / Complete.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (all 16 phase code/doc files) | n/a | `TBD`, `FIXME`, `XXX` markers | none found | Debt-marker gate clear. |
| `mailglass_admin/lib/mailglass_admin/components.ex` | 944 | the word `placeholder` | Info | An HTML attribute name in an `include:` list, not a stub. |
| `docs/api_stability.md` | 1462 | "not yet implemented" | Info | Pre-existing line about List-Unsubscribe, not touched by this phase. |

No stubs: `Copy.vocabulary/0` and `class_labels/0` `wired: false` entries are deliberate data for Phase 182; `delivery_class/1` and `classify_or_unknown/1` have no production caller yet by design (the plan and ROADMAP document the Phase 182 wiring).

### Review Finding Triage (179-REVIEW.md / 179-REVIEW-DISPOSITION.md)

Instruction was to decide whether any open finding defeats a must-have or success criterion. None does. Each finding was checked against the criteria, and the three most consequential were reproduced by the verifier.

| ID | Severity | Verifier judgment | Defeats a must-have? |
|----|----------|-------------------|----------------------|
| CR-01 | critical (fixed) | Fix confirmed behaviorally: both CLIs print a verdict and the gate exits 1 under `MIX_ENV=test`; subprocess regression tests exist and pass. Entry guard now keys on `:script_library_mode`. | No (resolved) |
| WR-01 | warning | Reproduced: with `uspto: caution` and the other sources `clear`, `overall: clear`, `register_checked: true` validates and returns `{:allow, :clear}`. The plan truth only forbids `not_checked`, and the committed record denies. A hardening gap for when the owner records a result. | No. Harden before Phase 183 depends on it. |
| WR-02 | warning | Reproduced: a record dated 2030-01-01 with `expires: 2099-12-31` evaluated on 2026-11-20 returns `{:allow, :clear}`. The plan truth ("today before `expires`") is met literally; the 180-day refresh is a convention nothing enforces. | No. Same hand-off as WR-01. |
| WR-03 | warning | Confirmed: `api_stability.md` calls `read_orphan_backlog/1` sibling-only (lines 130-136) and `Operator.Mount` internal (line 262), while the policy lists both as must-not-move. BRPOL-01 and SC1 themselves name `Mailglass.Operator.*` and `:orphan_backlog`, so the policy matches the requirement; the inconsistency is a scope-precision problem that over-protects, never under-protects. | No |
| WR-04 | warning | Confirmed by reading the matcher (`String.contains?`) and the proof files: the `[:mailglass, :webhook, :orphan, :stop]` row also matches moduledoc lines 19/126 of `webhook/telemetry.ex`, and `deliveries_path`/`account_labels` match router moduledoc lines 49/66. Probe: renaming the `deliveries_path` option key left the policy test unable to run because test-support compilation broke (exit 1), so a real rename of a used option cannot pass silently. The policy doc and 179-02-SUMMARY both disclose "grep = literal found in the proof file". | No. Low practical severity. |
| WR-05 | warning | Confirmed (`copy_contract_test.exs:702` asserts all class labels `wired == false`, contradicting the "without a test edit" prose at lines 57-60). Documentation-vs-test inconsistency; no effect on SC3. | No |
| WR-06 | warning | Plausible design trap for Phase 182: Part B is atom-keyed, so wiring the `:failed` class label would demand outbound words on inbound `:rejected`/`:bounced` badges. Inert today (Part B iterates zero entries). | No. Carry into Phase 182 planning. |
| WR-07 | warning | Reproduced: `%{status: :suppressed, terminal: true}` (no `suppressed_at`) and `%{status: :sent, last_event_type: :suppressed, terminal: true}` classify `:failed`; with `suppressed_at` present the same row is `:not_sent`. Persisted rows always carry `suppressed_at` (projector), and the plan text states the terminal rule literally, so this is a fixture-only edge in an unconsumed function. | No. Fix before first consumer. |
| WR-08 | warning | Known, pinned and handed off (ROADMAP:149, Deferred Items above). | No (deferred to Phase 182) |
| WR-09 | warning | Real: the `update` CLI test targets `@repo_root`. The refusal works (verifier runs left `git status --porcelain brandbook` empty). Test hygiene only. | No |
| IN-01..IN-05 | info | Duplicated test helper, raw U+00A0 literal, TM scan scope is markdown (matches the plan's stated scope), `wired` binding is a substring check, minor script robustness. | No |

### Human Verification Required

None. Per D-52 every success criterion was closed with machine evidence (`source: automated`).

### Owner Hand-offs (non-blocking, recorded for the next phases)

These are not verification gaps for Phase 179. They are owner-only inputs a machine cannot produce, already documented as a hand-off by D-23 and ROADMAP.

1. **Trademark register searches (USPTO, TMview, WIPO), reverse image search and counsel yes/no.** Runbook with full URLs: `.planning/research/brand-v2-adoption/TRADEMARK-SEARCH.md` "Remaining for a human". The gate denies (`caution`, `register_checked: false`) until the owner records results, which is the designed state. Phase 183 (BRDOC-06) gates the announcement and any TM text on it; code rollout is not gated.
2. Classification note for the orchestrator: I did not list this under `human_verification` because the caller's brief and D-23 say it does not block the phase, and SC5 asks that the result be committed with its outcome (done, honestly `not_checked`). If you read SC5 as requiring the register outcome itself, change status to `human_needed`.

### Gaps Summary

No gaps. All five roadmap success criteria and the plan-level must-haves are achieved in the codebase, and the load-bearing claims (SC2 universe test, SC3 mutation proof, SC4 tamper behavior, the CR-01 fix, zero visible text change) were each re-proven independently rather than taken from SUMMARY.md.

Recommended follow-ups (non-blocking, none defeat a criterion):

- Before Phase 183 calls the gate, close WR-01 and WR-02 (require all three registers `clear` for `overall: clear`; deny `today < date`; cap the validity window; restrict `--today`/`--path` to tests).
- Carry WR-06 and WR-07 into Phase 182 planning alongside the existing WR-08 projection hand-off, since all three concern how `StatusMap`/`Copy` get wired to screens. WR-06 and WR-07 are tracked only in `179-REVIEW-DISPOSITION.md`, not in ROADMAP.
- Reconcile WR-03: decide whether the policy's "stays" table covers only the documented stable tier, or add a first-party-coupling tier.
- The same latent `Mix.env() != :test` entry guard remains in `scripts/reconcile_release_versions.exs:777` (outside phase scope; recorded open in the disposition).

---

_Verified: 2026-11-14_
_Verifier: Claude (gsd-verifier)_
