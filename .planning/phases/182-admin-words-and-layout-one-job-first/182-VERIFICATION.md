---
phase: 182-admin-words-and-layout-one-job-first
verified: 2026-11-16T01:30:47Z
status: passed
score: 7/7 must-haves verified
covered_files: [".planning/phases/182-admin-words-and-layout-one-job-first/182-01-PLAN.md", ".planning/phases/182-admin-words-and-layout-one-job-first/182-01-SUMMARY.md", ".planning/phases/182-admin-words-and-layout-one-job-first/182-02-PLAN.md", ".planning/phases/182-admin-words-and-layout-one-job-first/182-02-SUMMARY.md", ".planning/phases/182-admin-words-and-layout-one-job-first/182-03-PLAN.md", ".planning/phases/182-admin-words-and-layout-one-job-first/182-03-SUMMARY.md", ".planning/phases/182-admin-words-and-layout-one-job-first/182-04-PLAN.md", ".planning/phases/182-admin-words-and-layout-one-job-first/182-04-SUMMARY.md", ".planning/phases/182-admin-words-and-layout-one-job-first/182-05-PLAN.md", ".planning/phases/182-admin-words-and-layout-one-job-first/182-05-SUMMARY.md", ".planning/phases/182-admin-words-and-layout-one-job-first/182-06-PLAN.md", ".planning/phases/182-admin-words-and-layout-one-job-first/182-06-SUMMARY.md", ".planning/research/brand-v2-adoption/after-catalog/after-1a0b741-20261116T004020Z/manifest.json", ".planning/research/brand-v2-adoption/after-catalog/after-1a0b741-20261116T004020Z/review/review-manifest.json", "brandbook/status-marks.json", "docs/api_stability.md", "lib/mailglass/operator/deliveries.ex", "mailglass_admin/docs/api_stability.md", "mailglass_admin/lib/mailglass_admin/components.ex", "mailglass_admin/lib/mailglass_admin/controllers/assets.ex", "mailglass_admin/lib/mailglass_admin/copy.ex", "mailglass_admin/lib/mailglass_admin/gallery_live.ex", "mailglass_admin/lib/mailglass_admin/inbound/destructive_action.ex", "mailglass_admin/lib/mailglass_admin/inbound/records_list.ex", "mailglass_admin/lib/mailglass_admin/inbound_live.ex", "mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex", "mailglass_admin/lib/mailglass_admin/operator/detail_header.ex", "mailglass_admin/lib/mailglass_admin/operator/filters_form.ex", "mailglass_admin/lib/mailglass_admin/operator/health_overview.ex", "mailglass_admin/lib/mailglass_admin/operator/mailer_name.ex", "mailglass_admin/lib/mailglass_admin/operator/orphan_count.ex", "mailglass_admin/lib/mailglass_admin/operator/quick_view.ex", "mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex", "mailglass_admin/lib/mailglass_admin/operator/results_status.ex", "mailglass_admin/lib/mailglass_admin/operator/shell.ex", "mailglass_admin/lib/mailglass_admin/operator/support_cards.ex", "mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex", "mailglass_admin/lib/mailglass_admin/operator/timeline.ex", "mailglass_admin/lib/mailglass_admin/operator_live.ex", "mailglass_admin/lib/mailglass_admin/preview/return_context.ex", "mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex", "mailglass_admin/lib/mailglass_admin/preview_live.ex", "mailglass_admin/lib/mailglass_admin/status_map.ex", "mailglass_admin/lib/mailglass_admin/surface_nav.ex", "mailglass_admin/test/mailglass_admin/after_catalog_manifest_test.exs", "mailglass_admin/test/mailglass_admin/operator/mailer_name_test.exs", "mailglass_admin/test/mailglass_admin/phase182_cause_contract_test.exs", "mailglass_admin/test/mailglass_admin/phase182_journey_test.exs", "mailglass_admin/test/mailglass_admin/phase182_review_words_test.exs", "mailglass_admin/test/mailglass_admin/phase182_status_marks_test.exs", "mailglass_admin/test/mailglass_admin/phase182_time_status_contract_test.exs", "mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs", "mailglass_admin/test/support/catalog_validators.ex", "mailglass_admin/test/support/review_gate.ex", "mailglass_admin/test/support/screen_registry.ex", "reference/demo_app/assets/catalog/capture-before-catalog.cjs", "reference/demo_app/assets/catalog/phase182-journey.spec.js", "reference/demo_app/assets/catalog/phase182-rubric.md", "reference/demo_app/lib/mailglass_demo/journey_seed.ex", "scripts/brand_status_marks.exs", "test/mailglass/operator/deliveries_projection_test.exs"]
covered_digest: "v4:sha256:52dab8ba1dad6324ac0cdee6582f62993b89b44313aa6082246fe9e19f730797"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 182: Admin Words and Layout, One Job First Verification Report

**Phase Goal:** An operator handling "a customer says the password reset never arrived" gets a truthful answer in brand v2 words through the real dashboard. The same words, time zones and status marks then roll out across every admin screen, without rendering anything the product cannot honestly know.
**Verified:** 2026-11-16T01:30:47Z (HEAD `cabd412d`, the final tree after both code-review fix iterations)
**Status:** passed
**Re-verification:** No, initial verification

The starting hypothesis was that the tasks were done and the goal was missed, and the summaries were not used as evidence. The final tree was read, the required lane was run, and eight mutations were applied to the final tree to confirm the contract tests have teeth (each file was restored; `git status` shows only the owner's pre-existing `.planning/config.json`). No gap was found.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1 / BRADM-01: through the real LiveView, in light, dark and 375px, an operator searches by email, finds the delivery under Needs attention, and reads a verdict, "sent is not delivered" and a next step; a browser test against the demo fixtures covers the path | VERIFIED | `phase182_journey_test.exs` (48 tests, in the green lane) drives `live/2` -> `render_change` on `#operator-filters` -> `assert_patch` with `search=` -> row shows "Failed" with one `aria-hidden` mark -> summary `attention == 1` -> Quick view (`delivery-verdict-line`, no "Next step") -> Full detail (`#delivery-detail-verdict` precedes `operator-timeline` in DOM order, "Next step" present, every `<time>` ends in " UTC"). A Sent row asserts "sent is not delivered" plus provider and next step (`copy.ex` `sent_rule_default/0`, line 519). The theme dead render asserts exactly one `data-theme` owner on `<html>` for the `dark`, `light` and absent cookie. 44px (`min-h-11`) is asserted on the search input and every row open control, and a hidden-ancestor detector proves the search and verdict are never behind `hidden` or a closed `<details>`. The 375px and 1440px light/dark browser path is `reference/demo_app/assets/catalog/phase182-journey.spec.js` (advisory by design: 180 D-04). The required proof is the ExUnit file, not the browser spec |
| 2 | SC2 / BRADM-02: every time shows its zone, every status is a pane mark plus a word, and a contract test fails on a bare time or a mark-only status | VERIFIED | `Components.timestamp/1` renders `display_parts/1` ("Nov 15, 2026, 2:05 PM" plus zone "UTC") with no `title`; `phase182_time_status_contract_test.exs` (35 tests) enumerates routes via `Phoenix.Router.routes`, scans a 170-cell status grid plus Preview, Gallery, Operator, Quick view, Full detail, replay modal and Inbound, with a source scan and a static `FMT` check. Source scan of `lib/`: `strftime`/`to_iso8601`/`class="badge` appear only in `components.ex`, `copy.ex` and the named allow-list (`preview_live.ex:1184` Date header, three non-status chips). Mutation M1 (drop the zone from `display_parts/1`): 7 failures. M4 (remove `timeZoneName` from the localizer): 1 failure. M6 (drop `aria-hidden` from `status_mark/1`): 9 failures across the marks and contract tests. Marks: `brandbook/status-marks.json` carries zip sha256 `ed96bb25...` and the book member sha256; five pairwise-distinct shape lists (computed) |
| 3 | SC3 / BRADM-03, 04, 05: screen text says Activity / Admin / Account / "N provider reports match no email"; each mailer shows its plain name with an accessible tooltip; `deliveries_path`, module names and public names unchanged; existing route and API contract tests pass unedited | VERIFIED | `surface_nav.ex:15` label "Activity", `deliveries_list.ex:29,359`, `operator_live.ex:144` title "mailglass — Activity" / "mailglass — Admin", gloss line at `operator_live.ex:2814`. `OrphanCount.label/1` implements 1 / N / 0 forms. `MailerName.plain_name/1` is binary-only (no atom creation) and `DetailHeader` uses `Components.field_help` with the plain name as trigger, the stored identity as tooltip, and the identity also printed visibly (no `title`). `phase182_words_contract_test.exs` scans every registry state. Greps of `lib/` find no visible "Deliveries", "Operator" (outside API docs) or "Tenant" (only `data-testid`s and the `Copy.vocabulary` gloss entries). `git diff 78dcb7d0..HEAD` is empty for `stability_contract_test.exs`, `operator_trust_doc_test.exs`, core `docs_contract_test.exs` and `mailglass_inbound/test`; `router.ex`, every `mix.exs`, `release-target.json`, `release-please-config.json` and `.github` are untouched; scoped core run (`test/mailglass/operator`, `brand_status_marks_test`, `docs_contract_test`): 134 tests, 0 failures |
| 4 | SC4 / BRADM-06: a cause sentence appears only when `reject_reason` or the suppression reason exists, otherwise a fixed fallback; a contract test proves "next try at...", "will retry" and cause text with a nil reason never render | VERIFIED | `Copy.cause_sentence/1` is generated by comprehension over the enums with no nil clause (`copy.ex:280-286`); `cause_or_fallback/1` returns exactly "No reason was recorded for this email."; the delivery help tooltips no longer promise a reason (`components.ex:1843-1857`); the suppression card nil reason takes the fallback (`suppression_card.ex:135-141`). `lib/` grep for `next try|will retry|retry window|retrying|we'll try` finds only the allow-listed inbound "before retrying" (`inbound_live.ex:1231`, a read retry). Mutation M2 (nil reason renders a cause): 2 failures in `phase182_cause_contract_test.exs` (41 tests). M3 (add "The provider will retry." to the Delayed copy): 3 failures. After the review fixes, a provider-reported `:failed` event on a handed-off row reads the fallback, not the send-time sentence (`copy.ex:452-463`, `components.ex:1848`) |
| 5 | SC5 / BRADM-07: a separate review agent judges each scenario against the book and the before-catalog, its rejection gate passes, evidence is stored at unique paths with the served SHA recorded after a server restart | VERIFIED | Committed `.planning/research/brand-v2-adoption/after-catalog/after-1a0b741-20261116T004020Z/` (never overwritten; 3 iterations, 2 prior ids recorded in `prior_iterations`): 14 scenarios x 2 independent judges, 28 pass verdicts; calibration 5 before-as-after + 2 injected defects all rejected by both judges, 1 known-good passed (16 calibration verdicts). Manifest: clean tree, `server.started_at` 00:40:22.804Z later than `script_started_at` 00:40:20.688Z, container PID 94796, served css/js sha256 equal disk and git blob. I recomputed: `app.css` sha256 `fc2df1a7...` equals the current file and `git show 1a0b741:...app.css`; `git diff 1a0b741..HEAD` over `priv` and `layouts` is empty, so the binding is LIVE. Judge inputs are limited to PNG, aria sidecar, rubric and goal. `after_catalog_manifest_test.exs` (61 tests) is in the green lane. Mutations: M7 (flip a committed calibration verdict to pass): 1 failure; M8 (plant a hallucinated evidence quote): 1 failure |
| 6 | Phase 179 hand-off: the operator projection carries the lifecycle fields so a bounce followed by an open is never Sent or Delivered, and an admin against an older core degrades honestly | VERIFIED | Core change is isolated to `lib/mailglass/operator/deliveries.ex` plus a new test file (commit `6b1e8016`; no migration, no new query parameter, no `failed_at`/`rejected_at`/`last_error`/`reject_reason`). `delivery_projection/1` adds `bounced_at`, `terminal`, `delivered_at`, `complained_at`, `suppressed_at`; `outcome_groups` carries `true|nil` flags (never `false`). `deliveries_projection_test.exs`: 10 tests, 0 failures; M5a (drop `bounced_at`): 4 failures; M5b (drop `terminal`): 7 failures. `status_map.ex` limitation comment replaced; `api_stability.md` (root and admin) says read-model maps may gain keys. D-06: `delivery_verdict/2` and `delivery_badge/1` gate on `Map.has_key?(row, :bounced_at)` and render "Status cannot be fully determined with this mailglass version." with the Unknown badge; covered by journey tests |
| 7 | Stop line honored: no new capture or backend feature, brand-book example sentences ("will retry", "Next try at") not adopted, public names kept | VERIFIED | Core diff since phase start is `deliveries.ex` only; `priv/repo`, outbound and events untouched; `Mailglass.Operator.*`, router macros, `:operator_access`, `tenant_id`, `:orphan_backlog` and `deliveries_path` remain; `Copy` takes only the book's five status words |

**Score:** 7/7 truths verified (0 present, behavior-unverified; 0 overrides)

### Behavior-dependent truths

The one runtime-behavior claim not covered by a required-lane DOM test is that the browser localizer keeps a zone token after it rewrites a time. The required lane asserts `timeZoneName` and `"en-US"` statically. I also executed the localizer block extracted from `MailglassAdmin.Controllers.Assets.js_body/0` in Node against fake elements: UTC gives `Nov 15, 2026, 2:05 PM` + `UTC`; `America/New_York` gives `9:05 AM` + `EST`; `Pacific/Auckland` gives `Nov 16, ... 3:05 AM` + `GMT+13`. In all three the time element's `aria-label` is removed and the copy control's label contains the visible text (WCAG 2.5.3). The advisory Playwright run (7 passed, per the 182-06 summary) was not re-run here.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mailglass/operator/deliveries.ex` | five additive projection keys + `true|nil` outcome flags | VERIFIED | read; 17-line diff; credo `--strict` clean on the file |
| `test/mailglass/operator/deliveries_projection_test.exs` | DB-backed contract through the real projector | VERIFIED | 10 tests green; mutation-checked |
| `brandbook/status-marks.json`, `scripts/brand_status_marks.exs` | pinned geometry plus provenance | VERIFIED | zip sha `ed96bb25...` and member sha recorded; `brand_status_marks_test` green |
| `mailglass_admin/lib/mailglass_admin/copy.ex` | verdict, cause, fallback, wired vocabulary | VERIFIED | 566 lines; no catch-all cause clause; all vocabulary entries `wired: true` |
| `mailglass_admin/lib/mailglass_admin/components.ex` | `status_mark`, `status_badge` mark branch, `delivery_badge`, `delivery_verdict`, `timestamp`/`display_time` | VERIFIED | read in full for the touched regions |
| `operator/mailer_name.ex`, `operator/orphan_count.ex` | pure plain-name and orphan sentence | VERIFIED | read; no atom creation |
| `phase182_{journey,cause_contract,time_status_contract,words_contract,status_marks,review_words}_test.exs`, `operator/mailer_name_test.exs` | required-lane contracts | VERIFIED | all in the 1787-test lane, all mutation-checked where listed above |
| `after_catalog_manifest_test.exs`, `review_gate.ex`, `catalog_validators.ex`, `screen_registry.ex` | gate and validators | VERIFIED | 61 manifest tests green; gate/teeth exercised by M7 and M8 |
| `reference/demo_app/lib/mailglass_demo/journey_seed.ex` | six password-reset rows read back from stored rows | VERIFIED | `expect!/3` read-back before the `JOURNEY_CASES_JSON=` sentinel; `DemoData`, `personas.ex` and `catalog_seed.ex` untouched |
| `reference/demo_app/assets/catalog/phase182-journey.spec.js`, `capture-before-catalog.cjs`, `phase182-rubric.md` | after-mode capture and advisory journey | VERIFIED | present; manifest schema `mailglass.after_catalog.v1` |
| after-catalog `after-1a0b741-20261116T004020Z` | committed evidence | VERIFIED | see truth 5 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| core `deliveries.ex` | `StatusMap.delivery_class/1` | projection keys `bounced_at`/`terminal`/... | WIRED | read by `delivery_class/1` (`status_map.ex:127-159`); M5 shows the dependency |
| `operator_live.ex` `delivery_summary/1` | `StatusMap.delivery_class/1` | per outcome group | WIRED | `operator_live.ex:2777-2802`; journey tests |
| `Copy.delivery_verdict/2` | Quick view and Full detail | one verdict, two forms | WIRED | `quick_view.ex:129-133` (`:not_loaded`), `detail_header.ex` (timeline + suppression evidence) |
| `Copy` cause sentences | core enums | compile-time comprehension and equality raise | WIRED | `copy.ex:258-266`; suppression-reason parity held by the cause contract |
| `timeline.ex` provider time | `Components.timestamp/1` | parse, or labelled raw fallback | WIRED | `timeline.ex:306-336` |
| `detail_header.ex` | `MailerName` / `field_help` | plain-name trigger plus visible identity | WIRED | `detail_header.ex:62-82` |
| after-catalog manifest | current `app.css` and root layout | LIVE binding | WIRED | sha recomputed above |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| Activity rows, summary, verdict | operator row map (`bounced_at`, `terminal`, ...) | `Mailglass.Operator.Deliveries` Ecto select over `Delivery` columns | Yes (DB-backed core test and journey test through the real projector) | FLOWING |
| Full detail cause | timeline events (`reject_reason`) | `Mailglass.Operator.Timeline` | Yes | FLOWING |
| Suppression note and cause | suppression entry via `DetailHeader.suppression_evidence/2` | suppression read | Yes; `:no_entry` is distinct from a nil reason | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Required admin lane | `cd mailglass_admin && mix verify.support_contract.admin` | 1787 tests, 0 failures, 1 excluded (seed 681934); the `:skip` is pre-existing | PASS |
| Bundle reproducibility | `mix mailglass_admin.assets.build --check` | "Admin bundle matches a fresh build (138536 bytes)" | PASS |
| Format (admin and touched core files) | `mix format --check-formatted` | exit 0 | PASS |
| Test-exception registry | `scripts/check_test_exceptions.sh` | OK | PASS |
| Core projection and docs contract | `mix test test/mailglass/operator test/scripts/brand_status_marks_test.exs test/mailglass/docs_contract_test.exs --seed 0` | 134 tests, 0 failures, 1 skipped | PASS |
| Credo on the one core file | `mix credo --strict lib/mailglass/operator/deliveries.ex` | no issues | PASS |
| Mutations M1-M8 on the final tree | edit, run scoped contract, restore | all red as listed above; tree restored | PASS |
| Served localizer in 3 zones | Node execution of the extracted `js_body/0` block | zone token kept in UTC, EST, GMT+13 | PASS |

### Probe Execution

SKIPPED: the phase declares no `probe-*.sh` probes.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BRADM-01 | 182-01, 182-02, 182-06 | search by email, find under Needs attention, verdict with "sent is not delivered" and next step, light/dark/375px | SATISFIED | Truths 1 and 6 |
| BRADM-02 | 182-01, 182-02, 182-03 | every time states its zone; every status is a pane mark plus a word | SATISFIED | Truth 2 |
| BRADM-03 | 182-04, 182-05 | Deliveries screen labelled Activity, `deliveries_path` unchanged | SATISFIED | Truth 3 |
| BRADM-04 | 182-04, 182-05 | Admin for Operator, Account for Tenant, public names stay | SATISFIED | Truth 3 |
| BRADM-05 | 182-04, 182-05 | orphan count sentence; mailer plain name with accessible tooltip | SATISFIED | Truth 3 |
| BRADM-06 | 182-02 | cause only with a recorded reason, fixed fallback, contract test | SATISFIED | Truth 4 |
| BRADM-07 | 182-06 | separate reviewer, rejection gate, unique evidence paths, served SHA after restart | SATISFIED | Truth 5 |

All seven IDs appear in plan frontmatter and in `REQUIREMENTS.md` (marked complete, mapped to Phase 182). No orphaned requirement.

### Anti-Patterns Found

None. Scan over 86 changed files for `TBD|FIXME|XXX`, `TODO|HACK|PLACEHOLDER`, `console.log`, `return null` and empty handlers: no matches. Forbidden retry phrases: none outside the allow-listed read retries.

### Human Verification Required

None. Per owner policy D-52 every machine-observable must-have was closed by a test or command. The brand-fit judgments were made by the committed, gated two-judge review (D-21) and were not reopened because the final tree does not contradict them (see note 1).

### Gaps Summary

No gaps. Notes the orchestrator should know (informational, none blocking):

1. **Lib changed after the after-catalog capture.** Plan 06's backstop truth says nothing under `lib/` changes after capture, but the code-review fix pass (`a7f843a2`..`4417b105`) edited six `lib/` files. I checked that the catalog is still accurate: `app.css` and the root layout are byte-identical to the capture (`git diff 1a0b741..HEAD` over `priv` and `layouts` is empty), and each changed path needs data the 14 captured scenarios do not contain. No captured sidecar contains "Sending failed before", "handoff to the provider", "No current suppression entry" or "Nil". The seeded suppressed row has an entry, so it still reads the general Not sent clause (the sidecar shows that clause), and no seeded event is `:failed`. The Health cards, support banner and mailer-name paths are on screens that were not captured. The gate is therefore still faithful to the shipped UI for those scenarios. A fresh after-catalog is only needed if the owner wants evidence at HEAD.
2. **Reviewer rubric was clarified between iterations.** After iteration 1 the rubric was edited (`f2e8eeeb`) to state two locked decisions (the Queued qualifier, event names are not statuses) and that a scrolling list is not cut-off content. A real finding (the word "message") was fixed in product text instead. D-21 says the implementer rebuts only with a deterministic test; this was a rubric-gap clarification recorded in `prior_iterations` and re-judged by fresh judges, within the 3-iteration cap. Judgement call for the owner if they want it stricter.
3. **12 of 14 scenarios are judged `after_only`.** Only `deliveries__northstar__default__1440__light` and `delivery-detail__typo-bounce__default__375__light` have Phase 180 counterparts; the password-reset rows have no before capture. This is the plan's documented W2 decision and matches D-21 ("where one exists").
4. **Review-fix items left open by design.** WR-05 (compile-time `raise` over the core reject-reason enum) was skipped as a plan-mandated guard; the owner option is `IO.warn` instead of `raise`, or tightening admin's published core pin to `~> 2.8`. WR-06 (a necessity finding) was left. The Health "Delayed emails" link can open a wider list than the card counts in the confirmed-then-deferred case, because filtering by delivery class needs a core change that D-07 defers; the link now drops the event filter in that case rather than mislabel the list.
5. **Deferred items (out of scope, logged in `deferred-items.md`).** Inbound outcome help and some support-card help still say "message" (pinned by an evidence-bound persona file); demo Storybook nav specimens still carry the label "Deliveries"; three e2e specs write into archived `.planning/milestones` screenshot paths; the Failed webhook attempts card draws an empty card on a nil count (`nil > 0` is true in Elixir). Root core `Phase164RepositoryTruthTest` fails only because of an untracked local `.gsd/.gitignore` (known, environmental; not re-run).
6. **Marks are the book's pinned geometry, not CONTEXT D-10's draft list.** D-10 described "check, triangle, cross, slash-circle, outbound arrow"; the implementation uses the book's actual inline SVG geometry (frame, check, clock hand, crack, struck frame), extracted with provenance and shown pairwise distinct. This follows the plan's C-1/C-2 resolution and the book is the source of truth.
7. **Bookkeeping for the orchestrator.** `ROADMAP.md` still shows Phase 182 unchecked and "6/6 In Progress", and the plan count (6) is over the about-5 budget (disclosed in ROADMAP; milestone total 18 of 20). The advisory Playwright and axe results are as reported in the 182-06 summary and were not re-run here; they are not the required proof.

---

_Verified: 2026-11-16T01:30:47Z_
_Verifier: Claude (gsd-verifier)_
