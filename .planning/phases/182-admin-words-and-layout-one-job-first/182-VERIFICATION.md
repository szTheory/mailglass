---
phase: 182-admin-words-and-layout-one-job-first
verified: 2026-11-18T00:49:12Z
status: gaps_found
score: 4/7 must-haves verified
covered_files:
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-01-PLAN.md"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-01-SUMMARY.md"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-02-PLAN.md"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-02-SUMMARY.md"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-03-PLAN.md"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-03-SUMMARY.md"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-04-PLAN.md"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-04-SUMMARY.md"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-05-PLAN.md"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-05-SUMMARY.md"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-06-PLAN.md"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-06-SUMMARY.md"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-07-EVIDENCE.json"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-07-PLAN.md"
  - ".planning/phases/182-admin-words-and-layout-one-job-first/182-UI-REVIEW.md"
  - ".planning/research/brand-v2-adoption/after-catalog/after-1a0b741-20261116T004020Z/manifest.json"
  - ".planning/research/brand-v2-adoption/after-catalog/after-1a0b741-20261116T004020Z/review/review-manifest.json"
  - ".planning/research/brand-v2-adoption/after-catalog/after-1a0b741-20261116T004020Z/superseded.json"
  - "brandbook/status-marks.json"
  - "docs/api_stability.md"
  - "lib/mailglass/operator/deliveries.ex"
  - "mailglass_admin/docs/api_stability.md"
  - "mailglass_admin/lib/mailglass_admin/components.ex"
  - "mailglass_admin/lib/mailglass_admin/controllers/assets.ex"
  - "mailglass_admin/lib/mailglass_admin/copy.ex"
  - "mailglass_admin/lib/mailglass_admin/gallery_live.ex"
  - "mailglass_admin/lib/mailglass_admin/inbound/destructive_action.ex"
  - "mailglass_admin/lib/mailglass_admin/inbound/records_list.ex"
  - "mailglass_admin/lib/mailglass_admin/inbound_live.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/detail_header.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/filters_form.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/health_overview.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/mailer_name.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/orphan_count.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/quick_view.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/results_status.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/shell.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/support_cards.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/timeline.ex"
  - "mailglass_admin/lib/mailglass_admin/operator_live.ex"
  - "mailglass_admin/lib/mailglass_admin/preview/return_context.ex"
  - "mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex"
  - "mailglass_admin/lib/mailglass_admin/preview_live.ex"
  - "mailglass_admin/lib/mailglass_admin/status_map.ex"
  - "mailglass_admin/lib/mailglass_admin/surface_nav.ex"
  - "mailglass_admin/priv/static/app.css"
  - "mailglass_admin/test/mailglass_admin/after_catalog_manifest_test.exs"
  - "mailglass_admin/test/mailglass_admin/operator/mailer_name_test.exs"
  - "mailglass_admin/test/mailglass_admin/phase182_cause_contract_test.exs"
  - "mailglass_admin/test/mailglass_admin/phase182_journey_test.exs"
  - "mailglass_admin/test/mailglass_admin/phase182_localizer_runtime_test.exs"
  - "mailglass_admin/test/mailglass_admin/phase182_review_words_test.exs"
  - "mailglass_admin/test/mailglass_admin/phase182_status_marks_test.exs"
  - "mailglass_admin/test/mailglass_admin/phase182_time_status_contract_test.exs"
  - "mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs"
  - "mailglass_admin/test/support/catalog_validators.ex"
  - "mailglass_admin/test/support/review_gate.ex"
  - "mailglass_admin/test/support/screen_registry.ex"
  - "reference/demo_app/assets/catalog/capture-before-catalog.cjs"
  - "reference/demo_app/assets/catalog/phase182-journey.spec.js"
  - "reference/demo_app/assets/catalog/phase182-rubric.md"
  - "reference/demo_app/lib/mailglass_demo/journey_seed.ex"
  - "scripts/brand_status_marks.exs"
  - "test/mailglass/operator/deliveries_projection_test.exs"
covered_digest: "v4:sha256:4036e4c88468f682cbe96dc9b50e8821b135fd652c600b262f709ca007a6f515"
behavior_unverified: 1
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/7
  gaps_closed: []
  gaps_remaining:
    - "Current light/dark 375px journey and independent review bound to the current served candidate"
  regressions: []
decision_coverage:
  honored: 25
  total: 25
  not_honored: []
gaps:
  - truth: "BRADM-01 and BRADM-07: the current served candidate has a current light/dark 375px browser journey and a fresh independent review bound to its served SHA."
    status: failed
    reason: "No current light/dark 375px browser journey or fresh independent review is bound to the current served candidate. The Phase 183 producer-provenance prerequisite now passes (183-VERIFICATION.md SHA-256 ce890ec8e1e4388cfc871e257210d059d486dd3c2de9afcb342b732ad8b71126), so it is no longer the blocker. The read-only Phase 182-07 preflight records a dirty worktree with 365 paths and no frozen candidate SHA; the checked local base 826962d6dc3d477c0fcc6bf67ff234f7e53d1fd3 has zero GitHub Actions runs and no combined commit statuses, and no exact-candidate cost disposition exists. Plan 182-07 forbids push or hosted CI solely to manufacture these gates, so preflight stopped before server, database, seed, or browser launch. The earlier current-candidate evidence remains explicitly superseded."
    artifacts:
      - path: "reference/demo_app/assets/catalog/phase182-journey.spec.js"
        issue: "The required browser journey is present, but preflight did not reach execution because no exact frozen candidate and hosted/cost gates are available."
      - path: ".planning/research/brand-v2-adoption/after-catalog/after-1a0b741-20261116T004020Z/manifest.json"
        issue: "This immutable review is tied to the prior served/source SHA."
      - path: ".planning/research/brand-v2-adoption/after-catalog/after-1a0b741-20261116T004020Z/superseded.json"
        issue: "It explicitly supersedes the prior catalog after the Admin CSS bundle changed."
      - path: "mailglass_admin/priv/static/app.css"
        issue: "Current served CSS differs from the CSS bound by the prior catalog."
      - path: ".planning/phases/182-admin-words-and-layout-one-job-first/182-07-EVIDENCE.json"
        issue: "The preflight-only record confirms the candidate and hosted/cost gates are missing; it does not establish current runtime behavior."
    missing:
      - "Obtain an owner decision to amend 182-07 for a scoped clean candidate freeze, then establish hosted and cost gates for that exact SHA. If those gates pass, use the plan's single conditional isolated preview to run the current journey and independent review; record a unique evidence path and served SHA after server restart. Do not push or run hosted CI solely to manufacture eligibility under the current plan."
behavior_unverified_items:
  - truth: "Verdict and cause rendering keep no process state, so concurrent LiveView renders cannot interleave copy."
    test: "Exercise overlapping LiveView renders for two deliveries with different event and cause inputs."
    expected: "Each rendered response contains only its own delivery's verdict and cause."
    why_human: "The current cause contract checks repeat-call idempotence, but no held-out or concurrent-render test directly proves this backstop invariant."
---

# Phase 182: Admin Words and Layout, One Job First Verification Report

**Phase Goal:** An operator handling “a customer says the password reset never arrived” gets a truthful answer in brand v2 words through the real dashboard. The same words, time zones and status marks then roll out across every admin screen, without rendering anything the product cannot honestly know.

**Verified:** 2026-11-18T00:49:12Z
**Status:** gaps_found
**Re-verification:** Yes — the prior `gaps_found` report's current journey/reviewer gap remains open. The Phase 183 provenance prerequisite now passes; Phase 182-07's exact-candidate preflight is blocked.

The current contract evidence from the prior report was reused; this re-verification did not rerun tests. The preflight-only record says no server, database seed, browser, preview, package install, push, or hosted CI ran. The preview allowance remains unused. No capture inputs or runtime resources were touched; the protected-path before/after comparison was not taken because preflight stopped before candidate/resource setup.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1 / BRADM-01: operator searches by email, finds the password-reset delivery under Needs attention, and reads a truthful verdict, “sent is not delivered,” and a next step through the LiveView in light/dark at 375px; the browser spec covers the full path | ✗ FAILED — current candidate journey absent | The existing LiveView contracts and browser spec are present, and prior focused UI evidence reports 303 passes. The prior catalog is superseded. The new preflight confirms there is no frozen candidate to run, no exact-SHA hosted/cost gate, and no current browser execution; it stopped before any runtime launch. |
| 2 | SC2 / BRADM-02: every admin time includes a zone and every status has a pane mark plus a word from the status map | ✓ VERIFIED | The retained time/status contract evidence enumerates Admin screens and status cases. phase182_localizer_runtime_test.exs executes the actual served localizer source from Assets.js_body/0 under UTC, America/New_York and Pacific/Auckland; prior focused UI evidence reports 303 passes. Current Components.status_badge/1 still maps :sm/:md to defined badge and mark sizes, and Components.status_mark/1 renders the decorative mark beside the visible word. |
| 3 | SC3 / BRADM-03/04/05: Activity/Admin/Account copy, exact orphan sentence and accessible plain mailer name are rendered while public paths and names stay unchanged | ✓ VERIFIED | phase182_words_contract_test.exs covers registered screen states, old-word absence, routes/IDs, orphan singular/plural/zero counts, mailer name derivation, visible stored identity, and no title-only disclosure. operator_live.ex renders SupportCards; support_cards.ex calls OrphanCount.label/1. |
| 4 | SC4 / BRADM-06: cause text appears only for recorded reasons, otherwise the fixed honest fallback is used; retry promises and exception text do not render | ✓ VERIFIED | Current Copy.cause_sentence/1 has only reason-enum clauses and cause_or_fallback/1 supplies the fixed fallback. The retained cause contract covers nil-reason cells, unloaded event history, and forbidden retry/error text; prior focused UI evidence reports 303 passes. |
| 5 | SC5 / BRADM-07: independent reviewers judge each scenario against the book and Phase 180 before-catalog, with rejection calibration and unique served-SHA evidence | ✗ FAILED — current review binding absent | The historical catalog remains valid only for its original candidate and is marked superseded after the CSS changed. No current journey screenshots, served SHA, or independent review exist. Phase 182-07 preflight stopped before runtime because no frozen candidate or exact-candidate hosted/cost gates were available. |
| 6 | Phase 179 hand-off: current core projection carries lifecycle evidence so a bounce followed by an open is not counted as Sent or Delivered | ✓ VERIFIED | lib/mailglass/operator/deliveries.ex selects stored lifecycle fields into both page and detail reads and groups unset flags as true | nil. deliveries_projection_test.exs covers both reads and bounce/open histories; prior core test evidence reports 82 passes. |
| 7 | Backstop: concurrent LiveView renders cannot interleave verdict/cause copy | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | The implementation uses pure copy functions and the cause contract checks idempotence, but no concurrent-render or held-out test directly exercises this invariant. See behavior_unverified_items. |

**Score:** 4/7 truths verified (1 present, behavior-unverified; 2 failed)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| lib/mailglass/operator/deliveries.ex | Additive lifecycle keys and truthy-or-absent outcome flags | VERIFIED | Substantive DB-backed projection; both list and detail readers call the real Ecto query. |
| mailglass_admin/lib/mailglass_admin/copy.ex and components.ex | Verdict, cause/fallback, visible mark/word and timestamp rendering | VERIFIED | Current source has structured branches; contract tests exercise rendered output. |
| operator/mailer_name.ex, operator/orphan_count.ex, operator/support_cards.ex | Derived plain mailer name, precise orphan sentence and screen wiring | VERIFIED | The helper is called for populated and zero counts through SupportCards. |
| phase182_*_test.exs, operator/mailer_name_test.exs | Current contract coverage for search, time/status, words and causes | VERIFIED | Active linked tests; no disabled-test directives found. |
| reference/demo_app/assets/catalog/phase182-journey.spec.js | Real browser path in responsive/theme cells | PRESENT — execution stale | Test exists and is wired to the capture driver. Current execution is blocked by the stop; no current browser result is claimed. |
| After-catalog manifest and review files | Independent review, calibration, restart and served-SHA binding | PRESENT — superseded | Historical binding is valid for its original candidate; current marker says the CSS changed afterward. |
| 182-07-EVIDENCE.json and 182-07-PLAN.md | Exact-candidate preflight and bounded current journey/review | BLOCKED — preflight only | Phase 183 provenance passed. The dirty worktree is not frozen into a candidate; local base `826962d6dc3d477c0fcc6bf67ff234f7e53d1fd3` has zero Actions runs and no combined statuses, and exact-candidate cost evidence is missing. The plan forbids push/hosted CI to manufacture those gates. |

The prior artifact query passed 24/24 artifacts across plans 182-01 through 182-06; this re-verification did not rerun artifact or link queries. The prior key-link query passed 16 declared links automatically. The remaining pattern miss was traced directly: operator_live.ex renders SupportCards, which calls OrphanCount.label/1; the link is wired through that intermediate module. The Phase 182-07 evidence record is present but blocked and cannot establish current runtime behavior.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Core Deliveries projection | Admin StatusMap and summary | Stored lifecycle fields returned by the DB projection | WIRED | delivery_class/1 reads the lifecycle keys and delivery_summary/1 buckets by class. |
| Operator LiveView | Copy / verdict UI | Quick view and full detail components | WIRED | Current templates use the shared verdict contract. |
| Timeline and suppression evidence | Cause/fallback copy | Loaded event history and suppression state | WIRED | The full-detail path passes real evidence into Copy.delivery_verdict/2; Quick view uses :not_loaded. |
| operator_live.ex | OrphanCount.label/1 | SupportCards.support_cards intermediary | WIRED | Direct source trace confirmed both populated and zero-count call sites. |
| After-catalog manifest | Served CSS/JS and review gate | Recorded hashes, restart time and independent verdict inputs | HISTORICALLY WIRED | The manifest validates its original candidate; the superseded marker prevents treating it as current. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Activity rows and summary | delivery row / outcome groups | Ecto reads and grouped counts over Delivery | Yes | FLOWING |
| Search result set | normalized search term | Existing ilike filter on recipient and subject metadata | Yes | FLOWING |
| Full detail cause | timeline events and suppression evidence | Operator timeline and suppression reads | Yes | FLOWING |
| Orphan sentence | provider-report count | Loaded support_summary.orphan_backlog.count | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior / suite | Result in retained evidence | Status |
|---|---|---|
| Storybook/evidence/review | 42 passed | PASS |
| Core focused tests | 82 passed | PASS |
| Focused UI contracts | 303 passed | PASS |
| Inbound tests | 481 passed; 3 property exclusions | PASS |
| Admin suite | 1,824 tests; one known FaviconCatalogTest producer-script SHA mismatch (favicon bytes match) | WARNING — suite is not fully green; mismatch is separate from the BRADM contract assertions |
| Current browser/capture | Not run: 182-07 preflight stopped before resources because the current dirty Admin worktree is not bound to a frozen candidate, hosted gates are absent, and exact-candidate cost evidence is missing | BLOCKED — no current journey or review |

The passing suite totals above are reused from the prior verification evidence and were not rerun in this report-only re-verification. They do not establish current browser behavior or a fresh served-SHA review. Phase 183 provenance independently passed 25/25 truths at `183-VERIFICATION.md` SHA-256 `ce890ec8e1e4388cfc871e257210d059d486dd3c2de9afcb342b732ad8b71126`; that closes the provenance prerequisite only. Historical browser/capture results remain separate and are not counted as current evidence.

### Probe Execution

SKIPPED — no phase-declared or conventional probe-*.sh script was found in the phase plans/summaries.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| BRADM-01 | 182-01, 182-02, 182-06, 182-07 | Email search, Needs attention, truthful verdict/next step, real responsive/theme browser journey | PARTIAL | Reused LiveView contract evidence covers source behavior, but no current candidate browser journey exists. Preflight stopped on the missing frozen candidate and exact-SHA hosted/cost gates. |
| BRADM-02 | 182-01, 182-02, 182-03 | Zoned times and pane mark plus status word | SATISFIED | Current registry contracts and three-zone localizer runtime test. |
| BRADM-03 | 182-04, 182-05 | Activity label with deliveries_path unchanged | SATISFIED | Current words and route contract. |
| BRADM-04 | 182-04, 182-05 | Admin/Account copy, public names retained | SATISFIED | Current rendered-copy/identifier contract. |
| BRADM-05 | 182-04, 182-05 | Exact orphan count and accessible plain mailer name | SATISFIED | Current support-card and mailer contracts. |
| BRADM-06 | 182-02 | Reason-only cause, honest fallback and no retry promises | SATISFIED | Current cause matrix and forbidden-phrase contract. |
| BRADM-07 | 182-06, 182-07 | Independent review, rejection gate and unique served-SHA evidence | PARTIAL | Historical catalog is intact but explicitly superseded after CSS changed; current candidate, served SHA and independent review are absent. |

No requirement mapped to Phase 182 is orphaned. The later Phase 183 goal covers docs and packaging, not these current browser/review gaps; neither gap is deferred.

### Test Quality Audit

| Test group | Linked requirements | Active / skipped | Circular | Assertion level | Verdict |
|---|---|---|---|---|---|
| Projection tests | BRADM-01 | Active / 0 skipped | No | Value and multi-step behavior | PASS |
| Journey, time/status, words, cause and mailer contracts | BRADM-01–06 | Active; Node present, so localizer test skip branch is inactive | No | Rendered values and multi-step behavior | PASS |
| After-catalog validator and review gate | BRADM-07 | Active / 0 disabled directives found | No | Value, tamper rejection and calibration | PASS historically; current artifact binding is superseded |

The catalog validator tests write synthetic fixture files to exercise tamper cases; they do not generate expected values from the system under test. The 16 test-tier prohibitions declared across the six plans have linked contract tests. The current Admin run still has the separately noted favicon producer-script SHA mismatch.

### UI Review Findings

The 2026-11-17 UI review is explicitly source-only: it captured no screenshots or live interactions. It scored 18/24 and raised warnings that the Needs attention tile is second, the detail identity precedes the verdict, and missing subject/recipient copy falls back to “Message.” Its color-distribution and live interaction findings remain unobserved without a current render. These findings do not invalidate the focused word/cause contract evidence, but they reinforce that present-day visual ordering has not been certified.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| None | — | No unreferenced debt markers or production stubs found in the reviewed implementation paths. A return null appears only in the localizer test’s fake DOM selector. | INFO | No implementation stub found. |

### Human Verification Required

No owner UAT is requested for the blocked browser path: it is an automated check held behind the exact-candidate gate. The concurrent-render backstop remains listed in behavior_unverified_items; current idempotence/source checks do not prove concurrent execution.

### Gaps Summary

The source and reused focused contract evidence establish the lifecycle projection, status/time output, shared screen vocabulary, and honest cause/fallback behavior. The responsive browser journey and separate visual review still have only historical evidence tied to the previous served CSS. Phase 183's producer-provenance prerequisite now passes, but Phase 182-07's preflight found no frozen candidate binding the dirty Admin worktree, zero GitHub Actions runs and zero combined commit statuses for local base SHA `826962d6dc3d477c0fcc6bf67ff234f7e53d1fd3`, and no exact-candidate cost disposition. The plan forbids push or hosted CI solely to create those gates. It therefore stopped before starting a server, seeding, or launching a browser; no preview allowance was consumed. This preflight did not touch capture inputs or runtime resources, and it did not collect protected-path before/after hashes because no candidate resources were launched. The remaining gap is the current journey and reviewer binding. The next step is an owner decision to amend 182-07 for a narrowly scoped clean candidate freeze and exact-SHA hosted/cost gates; if those gates pass, use the plan's single conditional isolated preview. Until then, keep the gap open and preserve the separate no-recapture/alias stop.

### Advisory (New Scope, Unevidenced)

None. This re-verification found no new-scope finding with deterministic evidence that changes the phase verdict.

---

### Decision Coverage

All trackable CONTEXT.md decisions are honored by shipped artifacts. **25/25** decisions honored; none unhonored.

---

Verified: 2026-11-18T00:49:12Z
Verifier: the agent (gsd-verifier)

