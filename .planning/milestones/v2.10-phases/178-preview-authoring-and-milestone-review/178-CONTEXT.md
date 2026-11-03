# Phase 178: Preview Authoring and Milestone Review - Context

**Gathered:** 2026-10-29 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Final phase of v2.10. Repair Preview author controls (restore-defaults action, sample-value guidance, readable scenario selector) and close the milestone's evidence: feedback ledger, retained stories, fidelity/zoom receipts, measured upkeep cost, and a documented working preview on an identified candidate with required CI green.

Requirements: PRVUX-05, PRVUX-06, PRVUX-07, STORY-07, UIQ-04, UIQ-06, UIQ-07, UIQ-08.

This phase reconciles evidence started in 174–177; it is not the first scenario, axe, projection or cost measurement. Keep the existing Preview rendering. Unrelated iframe/connect and persistent-disclosure backlog items stay out unless they block admitted acceptance. No merge, release, publication or deployment is authorized.
</domain>

<decisions>
## Implementation Decisions

### Restore action and sample-value guidance (PRVUX-05, PRVUX-06)
- **D-01:** Rename "Reset assigns" to **"Restore defaults"**. Use the existing bordered secondary-action style (`btn btn-ghost min-h-11 px-md border border-base-300`, precedent `inbound/evidence_card.ex:84`), full width on narrow screens, end-aligned from `sm:` (`w-full sm:ml-auto sm:w-auto`). `phx-click="reset_assigns"` and its handler (`preview_live.ex:262-280`: reload defaults, clear drafts/errors, re-render) stay unchanged. Update the pins at `voice_test.exs:114-115`, `preview_live_test.exs:1062` and `e2e/flows.spec.js:734` in the same change, keeping voice_test's "verb + noun, not bare Reset" rule.
- **D-02:** Remove the generic per-field helpers from `help_text_for/1` (`assigns_form.ex:304-316`: "Text value.", "Whole number.", "Decimal number.", "Date.", "Toggle on or off."). Keep the specific parse/validation errors (`preview_live.ex:1038-1042`) and the `(atom)`/`(map)`/struct type badges. Replace per-field read-only lines with **one** form-level read-only note, shown only when read-only fields exist. `described_by/2` must reference only ids that are rendered; no dangling `aria-describedby`.
- **D-03:** Final microcopy goes through the ux-writing skill within D-01/D-02. Brand voice: direct and specific.

### Readable scenario selector (PRVUX-07)
- **D-04:** The primary label is the humanized scenario name, from the same sentence-case `humanize/1` AssignsForm uses. The Mailable is secondary context; drop the `·` join (`sidebar.ex:129-132`). The exact technical identity (`inspect(module)` + scenario atom) is **visible** secondary monospace text that wraps, not truncated and not `title`-only. This honors the existing Phase 171 assertion (`preview_live_test.exs` ~508-520) and 200% zoom wrapping. Options stop showing raw atoms with `truncate` (`sidebar.ex:216`).
- **D-05:** URLs keep raw atoms. `scenario_path/6` (`sidebar.ex:419`) and the Phase 177 `return_surface`/`return_tenant_id` threading are unchanged.
- **D-06:** Disambiguation is a pure, ExUnit-tested label builder over the whole discovered set. It covers (a) scenarios in one Mailable whose humanized forms collide (including `__` collapsing) and (b) Mailables whose leaf name is the same across namespaces (`module_parts/1`, `sidebar.ex:369-374`). On collision, fall back to the raw atom or the shortest distinguishing namespace segment. Collapse double spaces from `__`. Add the collision fixture at scenario level inside an existing fixture, not as a new module, to avoid shifting discovery counts and preview-capture fixture restrictions (Phase 173 remote-CI lesson). If a module-level leaf collision needs a new module, check the discovery tests and Preview Capture Advisory first.

### Final reconciliation (UIQ-04, STORY-07, UIQ-06)
- **D-07:** UIQ-04 is a correction pass on the existing ledger in `reference/persona_spec/quick_view_scenarios.json`, with no new tracking structure. Close the stale Phase 176 rows (`fb-auto-apply-filters`, `fb-raw-source-hierarchy`, `fb-inbound-addresses`): add current dispositions, scenario ids (link `inbound-evidence-*` scenarios back via `feedback_ids`) and evidence anchors from 176-VERIFICATION.md and the 176 specs. Phase 176 has no AUTOMATION.md. Resolve `fb-storybook-fidelity` (partial: stat_card font-role receipt plus real zoom), `fb-preview-reset` and `fb-preview-identity`. At phase close, no row is `pending` or `partial`.
- **D-08:** Replace the phase-bound assertion at `reference/demo_app/assets/e2e/quick-views.spec.js:300-303` (it still requires 176–178 rows to be `pending` and fails the advisory Demo job today) with a phase-independent rule in a **merge-blocking ExUnit** test in the admin lane, which already loads `MailglassDemo.QuickViewScenarios`. The rule: every non-pending row has non-empty `scenario_ids` or an explicit `connected-real-route-only` boundary, and an `evidence_pointer` that resolves to a real file/anchor. Write this as a mutation-proven check.
- **D-09:** STORY-07 adds one Preview authoring story set built from production `AssignsForm.assigns_form` and `Sidebar.menu`, following `reference/demo_app/storybook/preview_chrome.story.exs`. Its builder goes in `quick_view_scenarios.ex` beside `preview_chrome/1`, with JSON rows: typed values, no editable values, field error, long/Unicode identity, duplicate label. The final STORY-07 accounting lists each repair's story, or an explicit boundary: filters (FILTER-01..04) are connected-only, citing `e2e/phase176-filters.spec.js`; Preview is pure-only, with no fabricated projection-agreement check. Make sure every missing, failed or zero-story case is counted and visible.
- **D-10:** Real zoom uses the existing Chromium extension (`mailglass_admin/e2e/support/browser-zoom-extension/`, `chrome.tabs.setZoom`). Fill the gaps: Phase 174 quick views (`storybook-fidelity.spec.js:139` defers to 178), Phase 177 Health and Account control, and the new selector and restore action (extend the Phase 171 case at `e2e/structural.spec.js:1790`). Move the Phase 176 CSS `style.zoom` cases (`phase176-filters.spec.js:599-652`) to real zoom, or relabel them honestly as CSS zoom. CSS zoom never counts as real-zoom evidence.
- **D-11:** Align the replay command in `mailglass_admin/docs/phase174-review.md:20` to the installed toolchain (`ASDF_ERLANG_VERSION=27.3.4.15`, `ASDF_ELIXIR_VERSION=1.18.4-otp-27`) so receipts are reproducible. Do not change `.tool-versions`.

### Cost and the reviewable candidate (UIQ-07, UIQ-08)
- **D-12:** Reconcile the existing pilot; don't start a new one. Run `scripts/run_demo_browser_evidence.sh --phase174 --phase175 --pilot` (the CI invocation, `ci.yml:1062`) hosted on the final candidate, and compare against the same-profile baseline (run 40414024714 / job 121891818059). Also measure Phase 176–178 growth in Operator Browser Gate (`ci.yml:954`, advisory, outside `CI Green`), taking that job's baseline from the same baseline run, with expected and executed counts. The prior hosted figure (174, rev `18c6cf32`) was +5.233 runner-minutes and 14s wall over the 5-minute budget. Record the honest disposition of any overage: remove duplication or justify placement. Never weaken a gate or hide an omission. Validate with `check_phase174_evidence.cjs --require-ci`, or an equivalent hosted-identity check.
- **D-13:** The candidate is branch `gsd/v2.10-ui-repairs-storybook` at its final SHA, presented as a **draft PR to main that is never merged**. A PR is required because `Guard Release Trigger` (required) runs only on `pull_request` or push to main (`guard-release-trigger.yml:3-12`); `workflow_dispatch` cannot prove both required contexts. Pushing and opening the PR are remote actions: the plan includes **one** explicit owner-approval checkpoint before push/PR, and Claude runs them after approval. The approval covers only that push and PR.
  - **D-13 clarification (2026-10-29, plan-phase):** The single D-13 owner approval also names exactly one `workflow_dispatch` of the CI workflow on the candidate branch at the exact candidate SHA, because `scripts/check_phase174_evidence.cjs --require-ci` cannot bind to a `pull_request` merge-ref run (178-RESEARCH finding 2 / Open Question 1). The approval therefore covers the push, the draft PR and that one dispatch, and nothing else. No rerun of any hosted job is pre-authorized; a rerun needs a new owner approval. Implemented by plan 178-09.
- **D-14:** The working preview is an isolated detached-worktree Compose demo launched from the exact candidate SHA, reusing `scripts/check_phase173_candidate.sh` and the `173-DELIVERY.md` runbook format. That means full URLs (operator, Preview `/dev/mail`, Storybook), source SHA, built and served CSS identity, and teardown with explicit dispositions for temporary services and artifacts. Every URL in the runbook is verified to render before hand-off.
  - **D-14 amendment (2026-10-29, plan-phase):** D-14 is honored by a slim sibling, `scripts/check_phase178_candidate.sh`, which reuses the mechanics of `scripts/check_phase173_candidate.sh` (detached worktree, port refusal, unique Compose project, route probes, source/built/served CSS triple, exact-SHA CI lookup, printed teardown) and the `173-DELIVERY.md` runbook format. The 173 script is not modified and is not invoked. Rationale: 178-RESEARCH finding 1 shows the 173 script cannot run for a non-173 candidate. It hard-requires committed phase 168-172 summaries under `.planning/phases/`, the 173 plan files, the six `assets/baselines/phase173` PNGs and a `plan_head_before:` line in `173-01-SUMMARY.md`, and it always ends with an unverified owner status. Everything else in D-14 (isolated detached worktree at the exact candidate SHA, full URLs, SHA and CSS identity, teardown dispositions, every URL verified before hand-off) is unchanged. Implemented by plan 178-03.
- **D-16 (2026-10-29, plan-phase):** state_md_contract_test positive assertions (live-gh pointers, permanent facts f733fc22/d65a1aa8/#222/#129 closed) re-homed from tool-managed .planning/STATE.md to the DOCS-01 entry of .planning/milestones/v2.8-REQUIREMENTS.md; STATE.md prohibitions retained; rationale: STATE.md is rewritten by the GSD state tool and must not be hand-edited (CLAUDE.md), so the positive assertions could never pass in CI (core_deterministic_suite); surfaced at ship/no-ship. Implemented by plan 178-12.
- **D-15:** D-52 applies. Machine-observable acceptance closes as `source: automated`. Author must-NOT items as `verification: test` in a `phase178_prohibition_contract_test.exs` (template: `phase175_prohibition_contract_test.exs`). Candidates: no generic per-field type helper strings; no dangling describedby; no `title`-only identity; no raw-atom-only primary label; reset handler behavior unchanged; no ledger row left pending or partial; CSS zoom never labelled as real zoom. Owner hand-off is limited to the push/PR approval and ship/no-ship review of the preview.

### Claude's Discretion
- Exact class tokens and layout details within D-01/D-04, and final wording via ux-writing.
- Collision fallback formatting (raw atom vs namespace segment) per case in D-06.
- Whether the Phase 176 CSS-zoom cases are migrated or relabelled (D-10), based on cost.
- Plan and wave structure.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 178 section and "Continuing delivery obligations"
- `.planning/REQUIREMENTS.md` — PRVUX-05..07, STORY-07, UIQ-04/06/07/08 and "Acceptance applying to every repair slice"
- `.planning/METHODOLOGY.md` — Shift-Left Verification (D-52)
- `.planning/phases/177-readable-health-and-coherent-account-navigation/177-CONTEXT.md` — Preview return context and no-Account-identity rules
- `.planning/phases/177-readable-health-and-coherent-account-navigation/177-AUTOMATION.md`
- `.planning/phases/176-direct-filters-and-useful-inbound-evidence/176-VERIFICATION.md`
- `.planning/phases/175-delivery-investigation-and-safe-replay/175-AUTOMATION.md`
- `.planning/phases/174-faithful-storybook-and-quiet-quick-views/174-COST-DISPOSITION.json`
- `mailglass_admin/docs/phase174-review.md`, `mailglass_admin/docs/phase175-review.md` — hosted cost and receipt records
- `.planning/todos/2026-10-26-owner-review-health-preview-controls.md` — owner feedback (Preview rows)
- `.planning/milestones/v2.9-phases/173-consistency-and-delivery-evidence/173-DELIVERY.md`, `173-REMOTE-CI.md` — working-preview runbook and remote-CI precedent
- `mailglass_admin/test/mailglass_admin/phase175_prohibition_contract_test.exs` — prohibition contract template
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex`: sample-value form; reset button (62-66), `help_text_for/1` (304-316), `described_by/2` (330-331), `humanize/1` (335-338)
- `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex`: `menu/1` trigger (129-132), options (216), group headings (263-276), `module_parts/1` (369-374), labels (383-385), `scenario_path/6` (419)
- `mailglass_admin/lib/mailglass_admin/preview_live.ex`: `reset_assigns` (262-280), parse errors (956-1042), form and menu placement (490-567)
- `mailglass_admin/test/support/fixtures/mailables.ex`: HappyMailer typed values (15-24), long/Unicode scenario (26)
- `reference/persona_spec/quick_view_scenarios.json` / `.ex`: ledger (12 feedback rows), 42 scenarios, 20 axe selections, builders
- `reference/demo_app/storybook/preview_chrome.story.exs`: story template
- `reference/demo_app/assets/e2e/storybook-fidelity.spec.js`: fidelity, font, theme and zoom receipt producer
- `mailglass_admin/e2e/support/browser-zoom-extension/`: real browser zoom
- `scripts/run_demo_browser_evidence.sh`, `scripts/check_phase174_evidence.cjs`, `scripts/check_phase175_evidence.cjs`, `scripts/check_phase173_candidate.sh`

### Established Patterns
- Stories render production components only; builders separate pure facts from persistence materializers. Real routes prove URL, history, auth and hooks.
- Axe: `mailglass_admin/docs/axe-baseline.json`, `storybook-axe-approved.json`, `e2e/axe-baseline.spec.js` (the `/dev/mail` route is already scanned at :164). Never quietly rebaseline.
- Admin tests are gated by `mix verify.support_contract.admin`; the ExUnit lane can load `MailglassDemo.QuickViewScenarios` (`quick_view_projection_test.exs:20`).
- Toolchain: export `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` locally.

### Integration Points
- CI: `.github/workflows/ci.yml` operator_browser_gate (954, advisory), demo_browser_evidence (1042), preview_capture_advisory (1072), ci_green (1428); `guard-release-trigger.yml`.
- Phase 177 return context: `e2e/phase177-return-navigation.spec.js` must stay green.
</code_context>

<specifics>
## Specific Ideas

- Owner feedback named the reset alignment/weight and the repetitive helpers. The demo `AccountMailer.invite_admin` shows "Text value." four times (`reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex:9-14`).
- The selector should read as a person-readable scenario first, with exact identity still available to keyboard and touch users.
</specifics>

<deferred>
## Deferred Ideas

- `.planning/todos/2026-10-25-details-open-reset-on-liveview-patch.md`: disclosure state reset on patch. It touches the Preview menu `<details>` but is out of scope unless it blocks admitted acceptance.
- Unrelated iframe/connect backlog items.
- Deeper whole-job scenarios and new profiles (REQUIREMENTS "Future requirements").

### Reviewed Todos (not folded)
None matched by `todo.match-phase`.
</deferred>
