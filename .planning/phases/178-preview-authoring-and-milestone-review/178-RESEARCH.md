# Phase 178: Preview Authoring and Milestone Review - Research

**Researched:** 2026-10-29
**Domain:** Phoenix LiveView admin UI repair (Preview authoring form + scenario selector), retained Storybook scenarios, feedback-ledger reconciliation, real-browser-zoom fidelity evidence, hosted CI cost measurement, reviewable-candidate delivery
**Confidence:** HIGH on in-repo mechanics (every cited file was opened this session); MEDIUM on hosted-run behaviour (PR vs dispatch identity, cost outcome); the copy is deliberately not decided here (ux-writing owns it, D-03)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Restore action and sample-value guidance (PRVUX-05, PRVUX-06)**
- **D-01:** Rename "Reset assigns" to **"Restore defaults"**. Use the existing bordered secondary-action style (`btn btn-ghost min-h-11 px-md border border-base-300`, precedent `inbound/evidence_card.ex:84`), full width on narrow screens, end-aligned from `sm:` (`w-full sm:ml-auto sm:w-auto`). `phx-click="reset_assigns"` and its handler (`preview_live.ex:262-280`: reload defaults, clear drafts/errors, re-render) stay unchanged. Update the pins at `voice_test.exs:114-115`, `preview_live_test.exs:1062` and `e2e/flows.spec.js:734` in the same change, keeping voice_test's "verb + noun, not bare Reset" rule.
- **D-02:** Remove the generic per-field helpers from `help_text_for/1` (`assigns_form.ex:304-316`: "Text value.", "Whole number.", "Decimal number.", "Date.", "Toggle on or off."). Keep the specific parse/validation errors (`preview_live.ex:1038-1042`) and the `(atom)`/`(map)`/struct type badges. Replace per-field read-only lines with **one** form-level read-only note, shown only when read-only fields exist. `described_by/2` must reference only ids that are rendered; no dangling `aria-describedby`.
- **D-03:** Final microcopy goes through the ux-writing skill within D-01/D-02. Brand voice: direct and specific.

**Readable scenario selector (PRVUX-07)**
- **D-04:** The primary label is the humanized scenario name, from the same sentence-case `humanize/1` AssignsForm uses. The Mailable is secondary context; drop the `·` join (`sidebar.ex:129-132`). The exact technical identity (`inspect(module)` + scenario atom) is **visible** secondary monospace text that wraps, not truncated and not `title`-only. This honors the existing Phase 171 assertion (`preview_live_test.exs` ~508-520) and 200% zoom wrapping. Options stop showing raw atoms with `truncate` (`sidebar.ex:216`).
- **D-05:** URLs keep raw atoms. `scenario_path/6` (`sidebar.ex:419`) and the Phase 177 `return_surface`/`return_tenant_id` threading are unchanged.
- **D-06:** Disambiguation is a pure, ExUnit-tested label builder over the whole discovered set. It covers (a) scenarios in one Mailable whose humanized forms collide (including `__` collapsing) and (b) Mailables whose leaf name is the same across namespaces (`module_parts/1`, `sidebar.ex:369-374`). On collision, fall back to the raw atom or the shortest distinguishing namespace segment. Collapse double spaces from `__`. Add the collision fixture at scenario level inside an existing fixture, not as a new module, to avoid shifting discovery counts and preview-capture fixture restrictions (Phase 173 remote-CI lesson). If a module-level leaf collision needs a new module, check the discovery tests and Preview Capture Advisory first.

**Final reconciliation (UIQ-04, STORY-07, UIQ-06)**
- **D-07:** UIQ-04 is a correction pass on the existing ledger in `reference/persona_spec/quick_view_scenarios.json`, with no new tracking structure. Close the stale Phase 176 rows (`fb-auto-apply-filters`, `fb-raw-source-hierarchy`, `fb-inbound-addresses`): add current dispositions, scenario ids (link `inbound-evidence-*` scenarios back via `feedback_ids`) and evidence anchors from 176-VERIFICATION.md and the 176 specs. Phase 176 has no AUTOMATION.md. Resolve `fb-storybook-fidelity` (partial: stat_card font-role receipt plus real zoom), `fb-preview-reset` and `fb-preview-identity`. At phase close, no row is `pending` or `partial`.
- **D-08:** Replace the phase-bound assertion at `reference/demo_app/assets/e2e/quick-views.spec.js:300-303` (it still requires 176–178 rows to be `pending` and fails the advisory Demo job today) with a phase-independent rule in a **merge-blocking ExUnit** test in the admin lane, which already loads `MailglassDemo.QuickViewScenarios`. The rule: every non-pending row has non-empty `scenario_ids` or an explicit `connected-real-route-only` boundary, and an `evidence_pointer` that resolves to a real file/anchor. Write this as a mutation-proven check.
- **D-09:** STORY-07 adds one Preview authoring story set built from production `AssignsForm.assigns_form` and `Sidebar.menu`, following `reference/demo_app/storybook/preview_chrome.story.exs`. Its builder goes in `quick_view_scenarios.ex` beside `preview_chrome/1`, with JSON rows: typed values, no editable values, field error, long/Unicode identity, duplicate label. The final STORY-07 accounting lists each repair's story, or an explicit boundary: filters (FILTER-01..04) are connected-only, citing `e2e/phase176-filters.spec.js`; Preview is pure-only, with no fabricated projection-agreement check. Make sure every missing, failed or zero-story case is counted and visible.
- **D-10:** Real zoom uses the existing Chromium extension (`mailglass_admin/e2e/support/browser-zoom-extension/`, `chrome.tabs.setZoom`). Fill the gaps: Phase 174 quick views (`storybook-fidelity.spec.js:139` defers to 178), Phase 177 Health and Account control, and the new selector and restore action (extend the Phase 171 case at `e2e/structural.spec.js:1790`). Move the Phase 176 CSS `style.zoom` cases (`phase176-filters.spec.js:599-652`) to real zoom, or relabel them honestly as CSS zoom. CSS zoom never counts as real-zoom evidence.
- **D-11:** Align the replay command in `mailglass_admin/docs/phase174-review.md:20` to the installed toolchain (`ASDF_ERLANG_VERSION=27.3.4.15`, `ASDF_ELIXIR_VERSION=1.18.4-otp-27`) so receipts are reproducible. Do not change `.tool-versions`.

**Cost and the reviewable candidate (UIQ-07, UIQ-08)**
- **D-12:** Reconcile the existing pilot; don't start a new one. Run `scripts/run_demo_browser_evidence.sh --phase174 --phase175 --pilot` (the CI invocation, `ci.yml:1062`) hosted on the final candidate, and compare against the same-profile baseline (run 40414024714 / job 121891818059). Also measure Phase 176–178 growth in Operator Browser Gate (`ci.yml:954`, advisory, outside `CI Green`), taking that job's baseline from the same baseline run, with expected and executed counts. The prior hosted figure (174, rev `18c6cf32`) was +5.233 runner-minutes and 14s wall over the 5-minute budget. Record the honest disposition of any overage: remove duplication or justify placement. Never weaken a gate or hide an omission. Validate with `check_phase174_evidence.cjs --require-ci`, or an equivalent hosted-identity check.
- **D-13:** The candidate is branch `gsd/v2.10-ui-repairs-storybook` at its final SHA, presented as a **draft PR to main that is never merged**. A PR is required because `Guard Release Trigger` (required) runs only on `pull_request` or push to main (`guard-release-trigger.yml:3-12`); `workflow_dispatch` cannot prove both required contexts. Pushing and opening the PR are remote actions: the plan includes **one** explicit owner-approval checkpoint before push/PR, and Claude runs them after approval. The approval covers only that push and PR.
- **D-14:** The working preview is an isolated detached-worktree Compose demo launched from the exact candidate SHA, reusing `scripts/check_phase173_candidate.sh` and the `173-DELIVERY.md` runbook format. That means full URLs (operator, Preview `/dev/mail`, Storybook), source SHA, built and served CSS identity, and teardown with explicit dispositions for temporary services and artifacts. Every URL in the runbook is verified to render before hand-off.
- **D-15:** D-52 applies. Machine-observable acceptance closes as `source: automated`. Author must-NOT items as `verification: test` in a `phase178_prohibition_contract_test.exs` (template: `phase175_prohibition_contract_test.exs`). Candidates: no generic per-field type helper strings; no dangling describedby; no `title`-only identity; no raw-atom-only primary label; reset handler behavior unchanged; no ledger row left pending or partial; CSS zoom never labelled as real zoom. Owner hand-off is limited to the push/PR approval and ship/no-ship review of the preview.

### Claude's Discretion
- Exact class tokens and layout details within D-01/D-04, and final wording via ux-writing.
- Collision fallback formatting (raw atom vs namespace segment) per case in D-06.
- Whether the Phase 176 CSS-zoom cases are migrated or relabelled (D-10), based on cost.
- Plan and wave structure.

### Deferred Ideas (OUT OF SCOPE)
- `.planning/todos/2026-10-25-details-open-reset-on-liveview-patch.md`: disclosure state reset on patch. It touches the Preview menu `<details>` but is out of scope unless it blocks admitted acceptance.
- Unrelated iframe/connect backlog items.
- Deeper whole-job scenarios and new profiles (REQUIREMENTS "Future requirements").
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PRVUX-05 | Author restores scenario defaults through an intentionally aligned secondary action with clear wording and the existing reset behavior | Pin inventory (Section "Pin Inventory"), D-01 class precedent verified at `evidence_card.ex:84`, all required classes already in the committed bundle (verified) |
| PRVUX-06 | Useful parsing/validation/read-only guidance without repetitive generic type helpers | `help_text_for/1` and `described_by/2` read verbatim; `parse_error/1` strings read; pin list for describedby/help ids |
| PRVUX-07 | Readable scenario with secondary module context, accessible exact technical identity, disambiguated duplicates | Sidebar read in full; conflicting trigger pins identified (6); pure `ScenarioLabel` design; fixture-collision impact enumerated |
| STORY-07 | Retained pattern/area/job scenarios per repair, incl. Delivery path; no hidden missing/failed/zero | Ledger/manifest shape verified; `preview_chrome` builder + story template read; accounting rule + only zero-story row (filters) identified |
| UIQ-04 | Trace each feedback item to disposition, requirement, scenario, behavior evidence | 12 rows enumerated with status; 6 not closed; `evidence_pointer` shapes + slug resolver proven against current rows |
| UIQ-06 | Reproducible fidelity/connected receipts across theme/width/keyboard/zoom/reduced motion | Real-zoom mechanics + 7 existing copies, gaps, checker coupling (`/Phase 178/i` limit, exact case-set equality) |
| UIQ-07 | Measured cold/warm wall+runner cost, coverage, placement, no weakened gates | Baseline per-job table captured from run 40414024714; `playwright --list` expected counts; critical-path analysis |
| UIQ-08 | Owner reviews repaired milestone in documented working preview on identified candidate with required CI | Branch/PR facts, `check_phase173_candidate.sh` is NOT directly reusable (verified), PR-vs-dispatch identity trap |
</phase_requirements>

## Summary

Phase 178 is two jobs: (1) a small, well-bounded UI repair in two files (`preview/assigns_form.ex`, `preview/sidebar.ex`) plus one new pure module, and (2) a large evidence-closing job (ledger, stories, real zoom, cost, candidate). The UI repair is cheap but has a wide **pin blast radius**: 8 ExUnit and 9 Playwright assertions encode the old strings, the per-field `-help` ids, the raw-atom trigger text and the "concise Mailable name, no namespace" rule. These must be rewritten deliberately in the same change, not discovered by failing CI. The evidence job has four non-obvious traps that CONTEXT does not mention and that would each burn a hosted run if found late.

**Four findings that change the plan (all verified this session):**

1. **`scripts/check_phase173_candidate.sh` cannot be reused as-is (D-14).** It hard-requires committed summaries for phases 168-172 under `.planning/phases/` (`for mapping in 168:10 169:5 170:8 171:4 172:3`), plan files under `.planning/phases/173-...`, the six `assets/baselines/phase173` PNGs, a `plan_head_before:` line in `173-01-SUMMARY.md`, and it always ends `FINAL_STATUS="incomplete"` because `OWNER_ACCEPTANCE_STATUS="unverified"` is hard-wired. Phases 168-172 now live in `.planning/milestones/v2.9-phases/` (`ls .planning/phases` shows only 174-178), so it fails at its first loop. It is also not executable (`-rw-r--r--`) and hard-codes `ASDF_ERLANG_VERSION=27.3.4.13`. D-14 should be read as "reuse its mechanics and the 173-DELIVERY format": write a slim `check_phase178_candidate.sh` (detached worktree, clean check, demo-lock restore, unique Compose project + free ports, route probes, source/built/served CSS digests, exact-SHA `gh` check, teardown record).
2. **`--require-ci` cannot pass on a `pull_request` run (D-12 + D-13 interaction).** On `pull_request`, `GITHUB_SHA` is the merge commit and `actions/checkout` checks out the merge ref [CITED: docs.github.com events-that-trigger-workflows]. `run_demo_browser_evidence.sh` binds `source_revision` to `git rev-parse HEAD` (the merge SHA) while `validateCiJob` requires `ciJob.head_sha === execution.source_revision && github.sha === execution.source_revision` and `ciJob.head_sha` is the PR head. Phase 174 got its hosted proof from a **`workflow_dispatch` on the candidate branch** (run 40498413906). Phase 178 therefore needs BOTH: a draft PR (for `Guard Release Trigger` + `CI Green` as required contexts) AND one `workflow_dispatch` of `ci.yml` on the same branch SHA (for the identity-bound cost/fidelity proof). D-13's approval text says "covers only that push and PR"; the dispatch is a third remote action and must be named in the single checkpoint.
3. **The Demo suite gate is whole-suite.** The pilot's demo condition runs `npm run test:e2e` (all 109 demo tests, `validateDemoReport` rejects any non-passing case). The stale phase-bound assertion in `quick-views.spec.js:300-303` therefore blocks the D-12 pilot, not only the ledger. It must be fixed (keeping the test title, which `REQUIRED_PHASE174_TESTS` pins) before the candidate SHA is cut.
4. **Local `main` is 301 commits ahead of `origin/main`; the remote branch `gsd/v2.10-ui-repairs-storybook` is at `25dc21cf`, two commits behind local `main`.** `origin/main` is an ancestor of `main` and of the remote branch. The push is a plain fast-forward `git push origin <candidate-sha>:refs/heads/gsd/v2.10-ui-repairs-storybook` (no force, never `main`). No CI run exists on that branch yet (`gh run list --branch ...` returned `[]`; CI triggers are `push: [main]`, `pull_request`, `workflow_dispatch`).

**Primary recommendation:** Execute tracer-first in this order: (a) `AssignsForm` slice (restore button + helper removal + all its pins) green end-to-end; (b) pure `ScenarioLabel` module with ExUnit, then the `Sidebar.menu` change + colliding-scenario fixture + trigger-pin rewrite; (c) manifest scenarios + story + ledger correction + merge-blocking ledger test + `quick-views.spec.js` fix; (d) real-zoom gaps; (e) prohibition contract with mutation proofs; (f) freeze source, run full local gates and code review, THEN the single owner checkpoint (push + PR + dispatch), hosted measurement, candidate runbook. Never cut the candidate until (a)-(e) are committed: every later source commit invalidates the hosted identity and costs another ~20-minute run.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Restore-defaults control + handler | Frontend Server (LiveView `PreviewLive` event) | Browser (button geometry) | Handler `reset_assigns` already owns reload-defaults/clear/re-render; only copy/class change (D-01) |
| Sample-value parsing and validation errors | Frontend Server (`parse_assigns/3`, `parse_error/1`) | — | Unchanged; errors are server-rendered, associated by id |
| Read-only guidance (form-level note, describedby ids) | Frontend Server (HEEx in `AssignsForm`) | Browser (a11y tree) | Pure function component; ids must be self-consistent |
| Scenario label humanize + disambiguation | Pure Elixir module (no tier I/O) | Frontend Server (`Sidebar.menu`) | D-06: pure, ExUnit-tested over the whole discovered set |
| Technical identity visibility / wrapping | Browser (CSS wrap, zoom) | Frontend Server (markup) | Proven only in a real browser (width, real zoom) |
| URLs with raw atoms, Phase 177 return threading | Frontend Server (`scenario_path/6`, `ReturnContext`) | — | D-05: unchanged |
| Retained authoring stories | Storybook (demo app) rendering production components | Pure builder in `quick_view_scenarios.ex` | Stories prove rendering only; no persistence in Preview (D-09) |
| Ledger rule (UIQ-04) | ExUnit in admin lane (merge-blocking) | Playwright (structural fields only) | D-08: phase-independent, mutation-proven |
| Real zoom evidence | Browser (Chromium `tabs.setZoom` via extension) | ExUnit/Node checkers for receipts | CSS `zoom` does not count |
| Cost measurement | CI (GitHub-hosted job timestamps) | Node checker `--require-ci` | Only hosted timestamps establish runner cost |
| Reviewable candidate | Git/GitHub (branch, draft PR, dispatch) + local Docker Compose | Shell script (`check_phase178_candidate.sh`) | Required contexts only run on PR/main push |

## Standard Stack

No new packages. Reuse what is installed (Package Legitimacy Gate not triggered; no `npm install`/`mix deps` change is recommended).

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix.Component / LiveView (via `mailglass_admin` lockfile) | repo lock | `AssignsForm`, `Sidebar` function components | Existing components; no framework change |
| ExUnit + Floki + `Phoenix.LiveViewTest` | repo lock | Component render tests, ledger/prohibition tests | Existing pattern (`phase175/176/177_prohibition_contract_test.exs`) |
| Playwright (`@playwright/test` ^1.59.1) + `@axe-core/playwright` ^4.11.2 | `mailglass_admin/package.json` | Operator browser gate cases, real zoom | Existing; `playwright --list` reports 300 tests in 17 files [VERIFIED: ran it] |
| Demo Playwright (^1.59.1 range, runs 1.60.0 per Phase 174 record) | `reference/demo_app/assets` | Storybook inventory spec | `playwright --list` reports 109 tests in 13 files [VERIFIED: ran it] |
| Chromium zoom extension | `mailglass_admin/e2e/support/browser-zoom-extension/` | Real 200% tab zoom | `chrome.tabs.setZoom(tab.id, 2)`; manifest permission `"tabs"` [VERIFIED: read manifest.json] |
| `gh` CLI | authenticated as `szTheory` [VERIFIED: `gh auth status`] | Run/job metadata, PR, dispatch | Used by Phase 173/174 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New `check_phase178_candidate.sh` | Parameterize `check_phase173_candidate.sh` by profile | The 173 script is 571 lines of 173-specific proof plus a 39 KB self-test (`test_check_phase173_candidate.sh`); parameterizing it risks the 173 test. A slim sibling is safer and smaller. |
| New `check_phase178_evidence.cjs` mirroring 174/175 | Record Phase 178 real-zoom in Playwright results + `178-AUTOMATION.md` table | A third 600-750 line checker is heavy; the 174 checker's exact-set equality makes ANY new `appendFidelityEvidence` case id a checker edit. Use the new checker only for the Storybook quick-view zoom case, if at all (see Pitfall 6). |
| Shared real-zoom helper | Seventh copy-paste of the 12-line setup | One small helper (`e2e/support/real-zoom.cjs`) used by NEW cases only; do not refactor the six existing copies. |

**Installation:** none.

**Version verification:** n/a (no package changes). Toolchain proven this session: `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test ...` runs; baseline `preview_live_test + discovery_test + voice_test + quick_view_projection_test + phase177_prohibition_contract_test`: 141 tests, 0 failures, 1 excluded (`--seed 0`). Direct `npx playwright test` (no npm script, so no asset rebuild) ran 3 Preview cases green in 4.4 s, including the real-zoom case.

## Package Legitimacy Audit

No external packages are installed or upgraded by this phase. Audit not applicable. If a plan proposes any new dependency, it must run `gsd_run query package-legitimacy check` first and add a `checkpoint:human-verify` task; the milestone constraint ("no speculative dependencies", REQUIREMENTS Out of scope) says do not.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 AUTHORING (PRVUX-05/06/07)                      EVIDENCE (STORY-07, UIQ-04/06/07/08)
 ---------------------------                     ------------------------------------
 Discovery.discover/1 --> [{mod, [{scenario,defaults}]} | {mod,:no_previews} | {mod,{:error,_}}]
        |                                                   |
        v                                                   v
 ScenarioLabel.build(mailables)  (NEW, pure)      quick_view_scenarios.json (ledger + scenarios)
   - humanize/1 (collapse "__")                          |           |
   - scenario collisions -> raw atom                     |           +--> QuickViewScenarios.preview_authoring/1 (NEW builder)
   - leaf collisions -> shortest ns suffix               |                     |
        |                                                |                     v
        v                                                |            preview_authoring.story.exs (NEW)
 Sidebar.menu/1 --(label map)--> trigger/option markup   |            renders AssignsForm.assigns_form + Sidebar.menu
   primary: humanized | secondary: Mailable leaf         |                     |
   technical (mono, wraps): inspect(mod) + atom          v                     v
   URLs: scenario_path/6 (raw atoms, unchanged)   feedback_ledger_test.exs (NEW, merge-blocking)
        |                                          rule: scenario_ids != [] OR boundary;
 PreviewLive (unchanged handlers)                  evidence_pointer resolves (live OR archived path)
   assigns_changed -> parse_assigns -> errors              |
   reset_assigns   -> defaults (unchanged)                 v
        |                                          phase178_prohibition_contract_test.exs (NEW)
        v                                                  |
 AssignsForm.assigns_form/1                                v
   Restore defaults (bordered, aligned)            FREEZE SOURCE --> local gates --> code review
   field errors (specific) | one read-only note            |
                                                           v
                              [OWNER CHECKPOINT: push SHA + draft PR + workflow_dispatch]
                                         |                         |
                              PR run (required contexts)   dispatch run (identity-bound)
                              CI Green + Guard Release     Demo pilot + Operator gate + Preview capture
                                         |                         |
                                         v                         v
                              gh run view --json jobs  -->  cost/expected-executed tables
                                         |
                                         v
              check_phase178_candidate.sh (detached worktree @ SHA, Compose, route + CSS probes)
                                         |
                                         v
                    178-DELIVERY.md runbook (full URLs, dispositions, teardown)
```

### Recommended Project Structure
```
mailglass_admin/
├── lib/mailglass_admin/preview/
│   ├── assigns_form.ex          # EDIT: Restore defaults, drop help_text_for, form-level note
│   ├── sidebar.ex               # EDIT: menu trigger/options use label map; picker/1 unchanged (see Open Q3)
│   └── scenario_label.ex        # NEW: pure humanize/1 + build/1 (boundary: auto-classifies into MailglassAdmin root)
├── test/mailglass_admin/
│   ├── preview/scenario_label_test.exs      # NEW: pure builder
│   ├── feedback_ledger_test.exs             # NEW: D-08 rule + mutation teeth
│   ├── phase178_prohibition_contract_test.exs  # NEW: D-15
│   └── (edits) preview_live_test.exs voice_test.exs discovery_test.exs quick_view_projection_test.exs
├── test/support/fixtures/mailables.ex       # EDIT: +1 colliding scenario in HappyMailer
├── e2e/ (edits) structural.spec.js flows.spec.js phase176-filters.spec.js phase177-health.spec.js phase177-account.spec.js
├── e2e/support/real-zoom.cjs                # NEW (optional helper, new cases only)
└── docs/phase174-review.md                  # EDIT: D-11 command line only
reference/
├── persona_spec/quick_view_scenarios.{json,ex}   # EDIT: ledger rows + preview_authoring scenarios + builder
├── demo_app/storybook/preview_authoring.story.exs # NEW
├── demo_app/assets/e2e/{quick-views.spec.js (edit), phase178-stories.spec.js (new)}
scripts/check_phase178_candidate.sh               # NEW (derived, slim)
.planning/phases/178-.../178-AUTOMATION.md, 178-DELIVERY.md, 178-COST-DISPOSITION.json
```

### Pattern 1: Pure label builder (D-06)
**What:** One pure function over the whole discovered list returning a lookup of `{mod, scenario}` to `%{primary, technical}` and `mod` to a module label. `Sidebar.menu/1` calls it once per render with `@mailables`.
**When to use:** every place that shows a scenario name in the menu trigger or options.
**Rules (all derived from verified source):**
- humanize: split the atom string on `_`, **drop empty segments** (this collapses `__`), capitalize only the first segment, join with a space. Existing `AssignsForm.humanize/1` keeps empty segments, so `welcome_überraschung_東京__with_a_deliberately_long_name` currently yields a double space. Share one implementation; field labels like `:user_name` and `:admin?` ("User name", "Admin?") must not change (pinned by `structural.spec.js:2382,2389`).
- fallbacks: if humanizing yields an empty string (e.g. `:__error__`, `:_`), use the raw atom. `:__error__` is a real value (`preview_live.ex:146`) and today renders "render error" via `current_scenario_label(:__error__)` (`sidebar.ex:384`).
- scenario collision: group by `{mod, humanized}`; any group of size > 1 uses the raw atom string as primary for each member.
- module collision: leaf = last `.` segment of `inspect(mod)`; if two modules share a leaf, extend each colliding module's label with trailing namespace segments until unique (shortest distinguishing suffix); stub/error modules participate (they appear in the list).
- invariant to test: over `Discovery.discover(...)` of a set, `{module_label, primary}` pairs are unique.
**Example (shape only; copy is ux-writing's):**
```elixir
# Source: derived from sidebar.ex:369-374 (module_parts/1) and assigns_form.ex:335-338 (humanize/1)
def humanize(atom) when is_atom(atom) do
  case atom |> Atom.to_string() |> String.split("_", trim: true) do
    [] -> Atom.to_string(atom)
    [first | rest] -> Enum.join([String.capitalize(first) | rest], " ")
  end
end
```

### Pattern 2: Retained story from manifest facts (D-09)
Follow `reference/demo_app/storybook/preview_chrome.story.exs`: `use PhoenixStorybook.Story, :component`, `def container, do: :iframe`, a `template/0` with the theme fieldset (`data-theme-owner="preview-authoring-story"`, picker testid `preview-authoring-review-theme`, which must equal `owner <> "-review-theme"` per the Phase 177 shape test), `variations/0` built from a `QuickViewScenarios.preview_authoring/1` builder, `render_case/1` rendering production `AssignsForm.assigns_form/1` and `Sidebar.menu/1`. JSON rows need the full object shape asserted by `quick_view_projection_test.exs` (`id story_path theme_owner theme_picker_testid variation_id role_job source cohort state reason owning_requirements proof_boundary feedback_ids rendered projection`), with `proof_boundary: "story-render-only"`. Do NOT add them to `axe_selection` (stays 20; `phase177-stories.spec.js:66` pins 20 and the Storybook axe checker pins its case counts); the connected `/dev/mail` axe cell already scans Preview (`axe-baseline.spec.js:158-170`).
**Menu open state in a story:** `Sidebar.menu/1` has no `open` attribute (the panel is a closed `<details>`). To show options/collisions statically add `attr :open, :boolean, default: false` rendered as `open={@open}`; default output is byte-identical so no LiveView behaviour changes and the deferred disclosure-reset todo is untouched.

### Pattern 3: Merge-blocking ledger rule with mutation teeth (D-08)
Place `feedback_ledger_test.exs` in `mailglass_admin/test/mailglass_admin/` (NOT core `test/mailglass` or `mailglass_inbound/test`, which `scripts/check_test_exceptions.sh` scans for `@tag :skip`/sleeps with line-number keys). Load via `MailglassDemo.QuickViewScenarios.scenarios()`-style access; the module also needs the feedback rows, so add `feedback/0` to `quick_view_scenarios.ex` (the JSON is already compiled in via `@manifest`). Detector returns a violation list (`[]` clean); "teeth" tests feed violating fixtures; a clean-state test runs the detector on the real manifest. Path resolution must accept either `.planning/phases/<dir>/<file>` or `.planning/milestones/v*-phases/<dir>/<file>` (exactly one must exist): v2.9's phases already moved to `.planning/milestones/v2.9-phases/` and `test/mailglass/docs_contract_test.exs:5` documents the same dual-location pattern. Anchor resolution: GitHub-style slug of markdown headings (lowercase, strip punctuation except `-` and `_`, spaces to `-`); I verified this slug function resolves all 6 currently-structured pointers (e.g. `177-AUTOMATION.md#health-composition-outux-06`).
**Rule (D-08):** for every row whose `status` is not `"pending"`: `scenario_ids != []` OR `proof_boundary == "connected-real-route-only"` (the filters row needs this additive field; nothing else carries a boundary at feedback level), AND `evidence_pointer` resolves. Phase-close invariant: no row is `"pending"` or `"partial"` (D-15). Existing statuses in use: `automated`, `resolved`, `pending`, `partial`.

### Pattern 4: Real zoom, minimal receipt
Established recipe (6 existing copies): `chromium.launchPersistentContext("", {channel:"chromium", headless:true, viewport:{width:1440,height:900}, deviceScaleFactor:2, args:[--disable-extensions-except=…, --load-extension=…]})` → record `initial` DPR → `serviceWorker.evaluate(chrome.tabs.setZoom(tab.id,2))`, assert `getZoom == 2` → `expect.poll(innerWidth).toBe(720)` → `setViewportSize({width:640,...})` → `expect.poll(innerWidth).toBe(320)` → assert `effective DPR / initial DPR == 2`. Record `{tabZoom, initial, effective}` in the case. For authenticated routes reuse the `storageState` pattern from `phase170-journey.spec.js:~367` or log in on the zoom page itself like `phase175-inbound.spec.js` does. Add a lint-style assertion in the new prohibition contract: no test titled/labelled "real zoom" may use `style.zoom` (grep the spec sources).

### Anti-Patterns to Avoid
- **Rebuilding the CSS bundle blindly.** `npm run test:operator-browser` runs `mix mailglass_admin.assets.build` first; the token-parity landmine (memory: committed `app.css` is canonical, a fresh build emits raw-inline theme blocks that break `TokenParityTest`) means: for local browser runs call `npx playwright test --config=playwright.config.cjs …` directly (proven this session) and choose only classes already in `priv/static/app.css`. I verified present: `sm:ml-auto`, `sm:w-auto`, `[overflow-wrap:anywhere]`, `border-base-300`, `font-mono`, `text-label`, `text-secondary`, `min-h-11`, `whitespace-normal`, `break-words`, `break-all`, `gap-xs`, `flex-wrap`, `justify-end`, `items-start`, `space-y-sm`. **Absent:** `sm:flex-row`, `sm:justify-end`, `sm:items-center`, `wrap-anywhere`. If a plan needs an absent class it needs an asset rebuild + `git diff --exit-code priv/static/` + token-parity check, as a named task.
- **Putting the exact identity only in `title`.** Forbidden by D-04/D-15 and by `sidebar.ex:271` precedent being a title-only module hint; keep the group-label `title` (pinned at `structural.spec.js:1541`) but add visible text.
- **Truncating options.** `sidebar.ex:216` `truncate` goes; use `whitespace-normal [overflow-wrap:anywhere]` (already in bundle).
- **A new CI job for any of this.** `config/quality/ci_policy.exs` registers lanes and `ci_green` needs them; none of Phase 178's checks needs a new job.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Real browser zoom | CSS `zoom`, `transform: scale`, `devicePixelRatio` overrides | `browser-zoom-extension` + `chrome.tabs.setZoom` | CSS zoom never counts (D-10); the extension is already proven headless |
| Hosted job timing | Local `time` or wrapper-only elapsed | `gh run view <id> --json jobs` (`startedAt`/`completedAt`) + `check_phase174_evidence.cjs --require-ci` | Wrapper `runner_minutes_status` is `wrapper-condition-elapsed`; hosted timestamps are the cost truth |
| Expected test counts | Hand-counted totals | `npx playwright test --config=… --list` (`Total: N tests in M files`) | Deterministic, offline; executed counts come from the hosted job log/JSON |
| Markdown anchor resolution | New parser dependency | ~6-line slug function (verified) | Matches GitHub heading slugs for every current pointer |
| Candidate worktree + Compose | New orchestration | Derive from `check_phase173_candidate.sh` mechanics | Detached worktree, `restore_candidate_demo_lock`, free-port allocation, CSS triple-digest are proven |
| Humanize | A second implementation in Sidebar | One shared pure function | D-04 requires the same sentence-case rule as AssignsForm |
| Prohibition tests | Grep-only proofs | Detector + teeth + clean-state (`phase175/177` template) and a recorded mutation table | Memory: validate by running, not grepping |

**Key insight:** this phase's risk is not building things; it is the coupling between a copy/markup change and ~17 pinned assertions, and between "reuse the pilot" and identity checks written for a dispatch event.

## Pin Inventory (must change in the same commit as the code)

| Change | ExUnit pins | Playwright pins |
|--------|-------------|-----------------|
| "Reset assigns" to "Restore defaults" (D-01) | `voice_test.exs:114-115` (`assert html =~ "Reset assigns"` + message `'Reset assigns' (not bare 'Reset')`); `preview_live_test.exs:1062` | `flows.spec.js:734` (`getByRole("button", { name: "Reset assigns", exact: true })`) |
| Event name `reset_assigns` | `preview_live_test.exs:990` `render_click(view, "reset_assigns", %{})` - **unchanged** (D-01) | none |
| Generic helpers removed; per-field `-help` ids gone (D-02) | `preview_live_test.exs:1022` (`aria-describedby="assigns-#{key}-help assigns-#{key}-error"` becomes error-only), `:1071-1072`, `:1084-1085`, `:1095` (`aria-describedby="assigns-mode-help"`) | `structural.spec.js:2387` (`#assigns-user_name-help` visible), `:2392` (`[id="assigns-admin?-help"]`), `:2397` (`#assigns-plan-help`) |
| Read-only wording moves to one form note | `preview_live_test.exs:1034` and `:1120` (`"edit it in the Mailable scenario"`) | none direct; `structural.spec.js:2394-2396` keep `[data-readonly-display='true'][id='assigns-plan']` + `aria-readonly="true"` - **leave the element's attributes alone** (see A1) |
| Trigger shows humanized primary, no `·` (D-04) | `preview_live_test.exs:201` (`trigger_text =~ "welcome_default"`) and `:482`, `:512` (raw atom incl. `welcome_überraschung_東京__with_a_deliberately_long_name`) - satisfied if the raw atom stays in the visible technical line | `structural.spec.js:1518` (`menuTrigger toContainText("welcome_default")`), `:1651` (identity contains `welcome_default`), `:1824` (long raw atom) - same condition |
| **Conflict:** exact identity includes `inspect(module)` (D-04) vs "concise Mailable name" rule | `preview_live_test.exs:202`, `:481`, `:511` (`refute ... =~ "MailglassAdmin.Fixtures"` on the trigger) | `structural.spec.js:1520`, `:1590`, `:1698` (`identity not.toContainText("MailglassAdmin.Fixtures")`) |
| Panel must stay namespace-free (leaf group label + atom option) | `preview_live_test.exs:219` | `structural.spec.js:1538` |
| Colliding scenario added to `HappyMailer` | `discovery_test.exs:20-26` (exact `Keyword.keys` list incl. order), `preview_live_test.exs:118` (`assert html =~ "5 emails"` becomes `"6 emails"`) | none; `emails` counts elsewhere are `refute`s |
| `Phase 171 … 200% zoom` case extended | none | `structural.spec.js:1790-1862` (title is used by `gsd-regression-gate.sh` grep `Phase 171`; keep the prefix) |
| `fb-*` rows no longer pending | none today | `quick-views.spec.js:300-303` (the stale phase-bound assertion; keep test title `Phase174 delivery scenario manifest accounts for rendered and real-route-only cases`, it is in `REQUIRED_PHASE174_TESTS`) |
| Phase 174 real-zoom limit | `scripts/check_phase174_evidence.test.cjs:213` | `scripts/check_phase174_evidence.cjs:276` requires `evidenceLimits.some(/Phase 178/i)`; `storybook-fidelity.spec.js:139` writes `"Browser zoom reconciliation is owned by Phase 178."` |

**Resolution of the D-04 vs `MailglassAdmin.Fixtures` conflict (recommendation):** the six trigger refutes encode the earlier "hide the namespace" decision that D-04 supersedes for the *technical line*. Recommended structure inside `summary`'s `#preview-email-menu-active-identity` (which must keep: `whitespace-normal`, `[overflow-wrap:anywhere]`, no `truncate`, no `title`, id used by `aria-labelledby`): primary humanized scenario (bold) / secondary Mailable leaf (`text-secondary`) / monospace wrapping technical line `inspect(mod)` + raw atom. Rewrite the six trigger pins to the new contract ("leaf present as secondary; full module appears only in the technical line"). Keep the **panel** unchanged in this respect (group label = leaf with `title`, option technical line = raw atom only), so `:219` and `:1538` stay as written. Alternative if the planner wants zero trigger-pin churn: render the full module line *outside* `<summary>` but inside the menu root; costs a second identity location. Either is defensible; the UI-SPEC should decide (config `ui_phase: true`).

## Runtime State Inventory

Not a rename/migration phase. The only string rename ("Reset assigns" to "Restore defaults") is copy; the `phx-click` event name and handler are unchanged, there is no persisted/registered state carrying the string. Verified by repo-wide grep (excluding `.planning`, `node_modules`, `_build`, `deps`): only the 4 test files, 1 e2e spec, `assigns_form.ex` and one ledger `disposition` sentence contain it; no docs/guides/README mention it. `mailglass_admin/README.md:224` describes the form generically ("Type-inferred assigns form") and needs no change. **Temporary-state inventory for UIQ-08 is real, see Environment Availability.**

## Common Pitfalls

### Pitfall 1: PR-run identity cannot satisfy `--require-ci`
**What goes wrong:** Hosted pilot on the PR event fails `validateCiJob` (`head_sha` is the PR head, `source_revision` is the merge commit).
**Why:** `GITHUB_SHA` = merge commit on `pull_request` [CITED]; the script binds revision to `git rev-parse HEAD`.
**How to avoid:** one `gh workflow run ci.yml --ref gsd/v2.10-ui-repairs-storybook` (Phase 174 precedent, run 40498413906 was `workflow_dispatch`) for cost/fidelity; PR run only for required contexts. Put the dispatch in the checkpoint text.
**Warning signs:** `--require-ci` fails with "actual CI repository/head SHA does not match candidate source".

### Pitfall 2: Cutting the candidate, then editing source
**What goes wrong:** Any later commit changes the head SHA; the hosted artifact's `source_revision`/`source_digest` no longer matches; re-run (~20 min wall, ~100 runner-minutes for the whole workflow).
**How to avoid:** freeze source; run the full local gate and code review first; commit evidence docs *after* the candidate and do not push them to the candidate branch (record candidate SHA in the docs). Baseline whole-workflow runner cost: 6041 s = 100.7 runner-minutes; wall 1241 s (20 m 41 s) to `CI Green` [VERIFIED: gh run view 40414024714].

### Pitfall 3: `check_phase173_candidate.sh` reuse
See finding 1. Also: demo `mix.lock` gets bumped by Compose runs (swoosh drift) - keep `restore_candidate_demo_lock`; local gate uses `.13` pin by default (`gsd-regression-gate.sh:8`).

### Pitfall 4: Preview Capture Advisory and the fixture scenario
Adding a `HappyMailer` scenario enlarges the capture matrix (CI runs `--mailables MailglassAdmin.Fixtures.HappyMailer` only; `check_preview_capture_checkpoint.sh` asserts `capture_count == len(captures) == png count`, not a fixed number, so no pin breaks). It is advisory and has a known cold-start readiness flake (90-iteration window failed once in run 40496672358 while the server compiled). Do not "fix" by editing the timeout; re-run unchanged. Prefer deriving the collision from the existing long/Unicode scenario (one added scenario, same fixture) over a new Mailable (which would need `--mailables` and `CI requires exactly --mailables …HappyMailer` handling).

### Pitfall 5: Ledger pointers that are prose
6 of 12 rows already use `path#anchor`; 6 use prose (`fb-preview-reset`, `fb-preview-identity`, `fb-auto-apply-filters`, `fb-raw-source-hierarchy`, `fb-inbound-addresses`, plus `fb-quiet-quick-view-arrows` and `fb-storybook-fidelity`, which are resolved/partial prose). Normalize every row to `path` or `path#anchor` and move prose into `disposition`. For the 176 rows point at `176-VERIFICATION.md` headings (e.g. `#observable-truths-roadmap-success-criteria`, `#requirements-coverage`) and the 176 specs; for rows closed in this phase create `178-AUTOMATION.md` headings and point there. The 11 `inbound-evidence-*` scenarios currently list only `fb-storybook-fidelity` in `feedback_ids`; add `fb-inbound-addresses` and `fb-raw-source-hierarchy` (INUX-05/06 are their `owning_requirements`).

### Pitfall 6: Phase 174 checker is exact-set coupled
`selectedCaseIds`/`executedCaseIds` are compared with `exactStringSet` against `fidelityCaseIds()` (26 ids), and `appendFidelityEvidence` auto-appends every `caseId` it receives. A new Phase 174-story real-zoom case routed through it fails the checker until `fidelityCaseIds()`, `collectFidelityCases`, the `.test.cjs` fixtures and the "148/148" expectations are updated together. Cheapest honest options: (a) put the quick-view real-zoom case into the Operator Browser Gate (connected `?id=` quick-view overlay, which is the Phase 174 real surface) and record it in `178-AUTOMATION.md`; keep the Storybook receipt limit but reword so `/Phase 178/i` still matches ("Real browser zoom for quick views is reconciled by Phase 178 case …"); or (b) extend the 174 checker deliberately with two ids. Prefer (a) unless the planner wants the Storybook rendering zoomed too.

### Pitfall 7: Operator Browser Gate headroom
Baseline job 121891818074 took 889 s (14 m 49 s) at the Phase 173/174 baseline, within a 30-minute timeout (`ci.yml` job `timeout-minutes: 30`). It now lists 300 tests (was 210 passed + 1 skipped at the Phase 173 remote run per `173-REMOTE-CI.md`). Each real-zoom case launches its own Chromium persistent context. Expect the hosted gate well above baseline; measure it, and treat approaching 30 minutes as a finding to disposition, not a reason to drop cases.

### Pitfall 8: `gsd-regression-gate.sh` only runs three browser specs
It runs `phase170-journey`, `flows`, `structural` with `--grep 'Phase 170|Phase 171|Preview:|Preview (happy|error|boundary|edge|advanced)'`. New Preview-authoring cases that should be in the local gate must live in `structural.spec.js`/`flows.spec.js` with a matching title prefix; a new spec file is not run by the gate unless the script's list is edited.

### Pitfall 9: Known pre-existing reds (do not chase, do not mask)
From the Phase 177 gate: 3 core failures (`state_md_contract_test.exs:38,52`, `phase_164_repository_truth_test.exs:261`), 10 unformatted files outside any phase scope, 3 `axe-baseline.spec.js` "scan deliveries" timeouts (logged in 177 `deferred-items.md`), `mix credo --strict` findings including `test/support/fixtures/mailables.ex:84`, `compile --no-optional-deps` pollution of the shared `_build` (never run it on the shared tree). Format and credo CI lanes are root-only (memory: admin/inbound drift is ungated): `mix format <touched admin files>` individually, never mass-format.

### Pitfall 10: ASDF toolchain
Export `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` on every `mix` call (proven working). `.tool-versions` says `erlang 27.3.4.13`; do not edit it (D-11).

## Code Examples

### Current reset button (what D-01 changes) 
```heex
<%!-- Source: mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex:62-66 [VERIFIED: read] --%>
<div class="flex flex-wrap gap-2">
  <button type="button" class="btn btn-ghost min-h-11 px-5" phx-click="reset_assigns">
    Reset assigns
  </button>
</div>
```
Precedent class string to mirror (verbatim, `inbound/evidence_card.ex:84`): `mg-focus-ring btn btn-ghost min-h-11 px-md border border-base-300 w-full sm:ml-auto sm:w-auto`.

### Current generic helpers (what D-02 deletes)
```elixir
# Source: assigns_form.ex:304-316 [VERIFIED: read]
defp help_text_for(value) do
  cond do
    is_boolean(value) -> "Toggle on or off."
    is_binary(value) -> "Text value."
    is_integer(value) -> "Whole number."
    is_float(value) -> "Decimal number."
    is_struct(value, DateTime) -> "Read-only; edit it in the Mailable scenario."
    is_struct(value, Date) -> "Date."
    is_struct(value) or is_map(value) -> "Read-only; edit it in the Mailable scenario."
    is_atom(value) -> "Read-only; edit it in the Mailable scenario."
    true -> "Read-only; edit it in the Mailable scenario."
  end
end
# described_by (assigns_form.ex:330-331):
defp described_by(key, nil), do: help_id(key)
defp described_by(key, _error), do: help_id(key) <> " " <> error_id(key)
```
Target shape for `described_by`: editable field with no error returns `nil` (so `aria-describedby={nil}` omits the attribute); with error returns only `error_id(key)`; read-only fields reference a single form-level note id that is rendered iff at least one read-only field exists. A detector for the contract: collect every id in every `aria-describedby`/`aria-labelledby` token and assert each exists in the same rendered fragment.

### Parse errors that stay (verbatim)
```elixir
# Source: preview_live.ex:1038-1042 [VERIFIED: read]
defp parse_error(default) when is_integer(default), do: "Enter a whole number."
defp parse_error(default) when is_float(default), do: "Enter a decimal number."
defp parse_error(%Date{}), do: "Enter a valid calendar date."
defp parse_error(default) when is_boolean(default), do: "Choose true or false."
defp parse_error(_), do: "Enter a valid value."
```

### Current trigger identity (what D-04 changes)
```heex
<%!-- Source: sidebar.ex:123-134 [VERIFIED: read] --%>
<span class="block min-w-0 flex-1 whitespace-normal [overflow-wrap:anywhere] text-body">
  <span class="font-bold text-base-content">{@current_mailable_label}</span>
  <span :if={@current_scenario_label} class="font-normal text-secondary">
    {" · "}{@current_scenario_label}
  </span>
</span>
```
Option row today: `<span class="min-w-0 flex-1 truncate">{Atom.to_string(scenario_name)}</span>` (`sidebar.ex:216`).

### Colliding fixture scenario (D-06) 
`HappyMailer.preview_props/0` already ends with `welcome_überraschung_東京__with_a_deliberately_long_name: %{user_name: "Ada", plan: :free, admin?: false}` (`mailables.ex:26-30`). Add `welcome_überraschung_東京_with_a_deliberately_long_name` (single underscore) with an identical function body shape: both humanize (with `__` collapse) to the same label, at long/Unicode width. Append at the end of the keyword list (order is asserted), and update `discovery_test.exs:20-26`.

### Real-zoom receipt shape to reuse
```js
// Source: mailglass_admin/e2e/phase175-inbound.spec.js:~262-285 [VERIFIED: read]
const tabZoom = await serviceWorker.evaluate(async () => {
  const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
  if (!tab?.id) throw new Error("Active Chromium tab is unavailable");
  await chrome.tabs.setZoom(tab.id, 2);
  return { tabId: tab.id, factor: await chrome.tabs.getZoom(tab.id) };
});
expect(tabZoom.factor).toBe(2);
await expect.poll(() => zoomPage.evaluate(() => window.innerWidth)).toBe(640);
await zoomPage.setViewportSize({ width: 640, height: 760 });
await expect.poll(() => zoomPage.evaluate(() => window.innerWidth)).toBe(320);
```

### Hosted per-job baseline (run 40414024714, event `push`, head `e326da4d…`)
| Job | Seconds | Role |
|-----|---------|------|
| Core Deterministic Suite | 894 | required, **critical path** |
| Operator Browser Gate | 889 | advisory |
| Support Contract Core | 687 | required |
| Inbound Test | 500 | required |
| Mix Task Tests | 363 | required |
| Support Contract Admin | 240 | required (touched by this phase's new ExUnit) |
| Demo Browser Evidence | 221 | advisory (D-12 pilot job; Phase 174 candidate 535 s = +314 s) |
| Preview Capture Advisory | 203 | advisory |
| CI Green | 14 | aggregate; run wall 1241 s |

Because `Support Contract Admin` (240 s) sits ~650 s below the critical path, added required-lane ExUnit time is invisible in required wall time until it grows by more than ~650 s; the honest report is the per-job delta plus the `CI Green` wall delta, not a single number.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ledger asserted per-phase in a Playwright test (`quick-views.spec.js:300-303`) | Phase-independent ExUnit rule, merge-blocking | this phase (D-08) | The advisory Demo job stops failing; the rule survives archive/phase renumbering |
| CSS `style.zoom` as zoom evidence (Phase 176 cases) | Chromium `tabs.setZoom` | Phase 170 onward | D-10: CSS zoom relabelled or migrated, never counted |
| Per-field "Text value." narration | Specific errors + one form-level note | this phase | Fewer redundant tab stops/announcements |

**Deprecated/outdated:** `check_phase173_candidate.sh` for any non-173 candidate; `evidenceLimits` "Browser zoom reconciliation is owned by Phase 178" after this phase delivers it.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The Preview `aria-allowed-attr: 1` axe baseline cell (`docs/axe-baseline.json`, `preview` light/dark/system) comes from `aria-readonly` on the `div#assigns-plan` read-only display (a `div` with no role). [ASSUMED] - `aria-readonly` is not a global attribute, `plan: :free` is the one read-only value on `welcome_default`, and the count is exactly 1; not run. | Pin Inventory, Pitfall/Anti-pattern | If wrong, keeping the read-only element's attributes unchanged is still safe; if right, changing them would silently alter a baseline cell (must be a deliberate `PERSIST_AXE_BASELINE=1` re-baseline, never quiet). Falsification probe for execution: run axe on `/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default` before and after the form change and compare the node target. |
| A2 | GitHub creates a distinct merge commit for `refs/pull/N/merge` even when the head is a fast-forward of base, so the PR-run `GITHUB_SHA` differs from the branch head. [ASSUMED]; docs say checkout uses the merge branch [CITED] | Finding 2 | If the merge ref equals head, `--require-ci` might pass on the PR run and the dispatch is redundant. Plan the dispatch anyway; it is cheap insurance and matches Phase 174. |
| A3 | `.planning/phases/174-178` will move to `.planning/milestones/v2.10-phases/` on milestone archive, as v2.9's did. [ASSUMED from v2.9 precedent] | Pattern 3 | If paths stay, the dual-location resolver is merely unneeded; if they move and the resolver is absent, the ledger test goes red at archive (58 tests broke this way in v2.7). |
| A4 | Hosted Operator Browser Gate will exceed its 889 s baseline materially and may approach the 30-minute job timeout. [ASSUMED; extrapolated from 300 listed tests vs ~211] | Pitfall 7 | If it times out, the run is red and cost evidence needs a re-run; the plan should budget for one. |
| A5 | The "owner approval" for the checkpoint is satisfied by the user's own message in the session, not by any agent message. [ASSUMED process reading of D-13] | Open Questions | Mis-reading could authorize a remote action without consent; the checkpoint must be `autonomous: false` and wait for a user-originated message. |
| A6 | Existing `mailglass-storybook-review-demo` Compose project (127.0.0.1:4015 / 5415, "2 days ago", healthy) is the owner's earlier feedback preview and should be left running. [ASSUMED from the 173-DELIVERY precedent "must remain available"] | Environment Availability | If the owner wants it stopped, runbook disposition changes; do not touch it without asking. |

## Open Questions

1. **Hosted-evidence event type and the single checkpoint wording**
   - Known: PR run cannot satisfy `--require-ci` (Finding 2); Phase 174 used `workflow_dispatch`.
   - Unclear: whether the owner considers `gh workflow run ci.yml --ref gsd/v2.10-ui-repairs-storybook` inside D-13's "push and PR" approval.
   - Recommendation: one checkpoint that explicitly lists the three actions (fast-forward push of the exact SHA, draft PR titled with a non-bumping type such as `chore(ui): …` and the body "review only, do not merge", one `workflow_dispatch`). `Guard Release Trigger` passes for non-bump types without inspecting files [VERIFIED: `guard_decision` returns 0 when type is not feat/fix/bang].
2. **Where the full technical identity lives (trigger vs outside `<summary>`)**: see Pin Inventory; decide in UI-SPEC. Default recommendation: inside the trigger's identity block with the six trigger pins rewritten.
3. **`Sidebar.picker/1` (directory variant)**: it also lists raw atoms (`sidebar.ex:314`) but is only reached via `Sidebar.sidebar/1` from `GalleryLive` specimens (`gallery_live.ex:431`) and ExUnit; `PreviewLive` uses only `menu/1`. Recommendation: leave `picker/1` untouched (Gallery matrix/axe pin its output) and say so in the ledger disposition; humanizing it is optional follow-up.
4. **What is "Phase 176-178 growth" in the pilot?** The pilot (`--phase174 --phase175`) runs the whole demo suite (109 tests) but only `Phase 175` Admin cases; Admin Phase 176/177/178 cases only exist in the Operator Browser Gate. Recommendation: report three job deltas (Demo pilot, Operator gate, Support Contract Admin) plus the workflow wall to `CI Green`, each with expected (`--list`) vs executed (hosted JSON/log) counts.
5. **Disposition if the 5-minute wall budget is exceeded again** (prior +14 s over): CONTEXT forbids weakening; candidate dispositions are "advisory lane, off the required critical path (Demo 535 s vs critical path 894 s at baseline)" and "optimize shared setup (two `npm ci`, two Chromium installs)". Decide after measuring; do not pre-commit.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP (asdf) | all ExUnit | yes | OTP 27.3.4.15 / Elixir 1.18.4-otp-27 via env override | none needed |
| PostgreSQL | LiveView/DB-backed ExUnit, operator browser server | yes | accepting connections on `/tmp:5432` | — |
| Node | Playwright, checkers | yes | v26.10.0 | — |
| Playwright Chromium | browser/zoom cases | yes | chromium 1200-1228 cached in `~/Library/Caches/ms-playwright` | — |
| Docker + Compose | candidate preview, demo pilot (local) | yes | Docker 29.5.2, Compose v5.1.3; daemon up | — |
| `gh` | run metadata, PR, dispatch | yes | authenticated `szTheory` | — |
| `compose.demo.yml` | candidate preview | yes (repo root) | — | — |

**Temporary services/artifacts present now (UIQ-08 disposition list must name them):**
- Running Compose project `mailglass-storybook-review-demo` on `127.0.0.1:4015` (demo) and `127.0.0.1:5415` (db), healthy, ~2 days old: older source, not the candidate. Runbook must state it is NOT the candidate and is left as-is (A6). The candidate script must allocate other ports (the 173 script refuses 4015/5415).
- Unrelated containers (`playstead-server-app-1`, `dreamy_pike`): never touch.
- Ignored evidence under `reference/demo_app/tmp/demo_browser_evidence/` (incl. `ci/40498413906-attempt-1` etc.): 14-day advisory retention; never commit.
- New this phase: candidate Compose project `mailglass-phase178-review-<sha8>-<suffix>`, detached worktree under `/tmp/mailglass-phase178.*`, remote branch, draft PR, hosted artifacts (14-day), local logs.

**Missing dependencies with no fallback:** none.

## Validation Architecture

> `workflow.nyquist_validation` is `true` in `.planning/config.json`.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (admin, `--warnings-as-errors`), Playwright 1.59.x (operator + demo), Node `node --test` (checkers) |
| Config file | `mailglass_admin/mix.exs` alias `verify.support_contract.admin` = `["test --warnings-as-errors"]` (runs the WHOLE admin suite, so new test files are merge-blocking automatically; no allow-list) [VERIFIED: mix.exs:213-215]; `mailglass_admin/playwright.config.cjs`; `reference/demo_app/assets/playwright.config.cjs` |
| Quick run command | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test <files> --seed 0` |
| Full suite command | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix verify.support_contract.admin --seed 0` (Phase 177 baseline 1082 tests, 0 failures, 1 excluded) |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PRVUX-05 | Button text "Restore defaults", bordered, `w-full sm:ml-auto sm:w-auto`, `phx-click="reset_assigns"`; handler restores defaults/clears drafts+errors | unit/LiveView | `mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs --seed 0` (edit pins) | exists, edit |
| PRVUX-05 | Geometry: end-aligned from 640px, full width below, 44px target, visible border and focus ring | browser | `cd mailglass_admin && CI=1 BROWSER_SERVER_PORT=4131 npx playwright test --config=playwright.config.cjs e2e/flows.spec.js e2e/structural.spec.js --grep "Preview happy\|Phase 178 restore" --workers=1` | new case in `structural.spec.js` (Wave 0) |
| PRVUX-06 | No generic helper strings; no `-help` ids on editable fields; exactly one read-only note iff read-only field exists; describedby ids all resolve; specific errors unchanged; forged events still rejected | unit | same ExUnit command (+ `assigns_form` rendering cases) | exists, edit (`preview_live_test.exs:1056-1125`) |
| PRVUX-06 | Real-browser a11y tree: error associated, read-only note reachable | browser | `npx playwright test … e2e/structural.spec.js --grep "Preview assigns and operator replay radios"` (rewrite `:2376`) | exists, edit |
| PRVUX-07 | Pure builder: humanize, `__` collapse, scenario collision, cross-namespace leaf collision, `:__error__`, unique pairs over a discovered set | unit (pure) | `mix test test/mailglass_admin/preview/scenario_label_test.exs --seed 0` | NEW (Wave 0) |
| PRVUX-07 | Trigger/options markup: primary humanized, secondary leaf, visible technical line, no `·`, no `truncate`, no `title`-only, hrefs keep raw atoms and Phase 177 return query | unit/LiveView | `mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/phase177_return_navigation_test.exs --seed 0` | exists, edit |
| PRVUX-07 | Narrow 320/390, long Unicode, duplicate labels, keyboard open/select, real 200% zoom | browser | `npx playwright test … e2e/structural.spec.js --grep "Phase 171\|Phase 178"` | extend `structural.spec.js:1688,1790` |
| STORY-07 | Manifest has the authoring scenarios with full shape; story file composes production components from the builder; each variation renders (typed values, no editable, field error, long/Unicode, duplicate label); live Preview renders the same facts equivalently | unit | `mix test test/mailglass_admin/quick_view_projection_test.exs --seed 0` (new `@tag :phase178` cases) | exists, add |
| STORY-07 | Story inventory/iframes/theme owner | browser (advisory, needs demo Storybook on :4015) | `npm --prefix reference/demo_app/assets run test:e2e -- phase178-stories.spec.js` | NEW |
| STORY-07 | Accounting: every feedback row is story-backed or has an explicit boundary; zero-story count visible | unit | `mix test test/mailglass_admin/feedback_ledger_test.exs --seed 0` | NEW |
| UIQ-04 | Rule + teeth (pending row, empty scenario_ids without boundary, unresolvable path, bad anchor, post-archive path) + phase-close invariant (no `pending`/`partial`) | unit | `mix test test/mailglass_admin/feedback_ledger_test.exs --seed 0` | NEW |
| UIQ-04 | Demo job no longer fails on stale assertion | browser (advisory) | `npm --prefix reference/demo_app/assets run test:e2e -- quick-views.spec.js -g "Phase174 delivery scenario manifest"` | exists, edit |
| UIQ-06 | Real zoom: Preview selector+restore, Health, Account control, quick-view overlay, Phase 176 filters (migrated); 320 CSS px, no overflow, targets >= 44px | browser | `npx playwright test … e2e/phase177-health.spec.js e2e/phase177-account.spec.js e2e/phase176-filters.spec.js e2e/structural.spec.js --grep "real zoom\|200%"` | extend / NEW cases |
| UIQ-06 | Receipt checkers still green after any case-id edit | node | `node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs` | exists |
| UIQ-06 | Reduced motion, keyboard/focus for new controls | browser | `npx playwright test … --grep "Phase 178"` with `page.emulateMedia({reducedMotion:"reduce"})` | NEW case |
| UIQ-07 | Expected counts | CLI | `cd mailglass_admin && npx playwright test --config=playwright.config.cjs --list \| tail -1` (now `Total: 300 tests in 17 files`); `cd reference/demo_app/assets && npx playwright test --config=playwright.config.cjs --list \| tail -1` (now `Total: 109 tests in 13 files`) | — |
| UIQ-07 | Hosted identity/cost | CLI | `node scripts/check_phase174_evidence.cjs --evidence-dir reference/demo_app/tmp/demo_browser_evidence/ci/<run>-attempt-1 --pilot --require-ci` on the **dispatch** run | needs dispatch run |
| UIQ-07 | Disposition record is consistent with raw GitHub metadata | node | a small `node --test` over `178-COST-DISPOSITION.json` vs saved raw run/jobs JSON (mirror 174's derivation) | NEW |
| UIQ-08 | Candidate record: exact SHA clean, 5+ routes 200, built CSS digest == served CSS digest, `CI Green` and `Guard Release Trigger` success for the SHA | shell | `bash scripts/check_phase178_candidate.sh` then `gh pr checks <n>` | NEW script |
| UIQ-08 / D-15 | Prohibition contract (each rule: teeth + clean state) | unit | `mix test test/mailglass_admin/phase178_prohibition_contract_test.exs --seed 0 --warnings-as-errors` | NEW |
| all | Design-system conformance | shell | `bash mailglass_admin/scripts/check-conformance.sh` (prints `OK: design-system conformance clean.` today) | exists |
| all | Bundle equals fresh build (only if CSS touched) | shell | `cd mailglass_admin && mix mailglass_admin.assets.build && git diff --exit-code priv/static/` | exists |

### Sampling Rate
- **Per task commit:** the touched ExUnit files with `--seed 0` plus `bash mailglass_admin/scripts/check-conformance.sh`.
- **Per wave merge:** `mix verify.support_contract.admin --seed 0`, the scoped Playwright greps above, and the `node --test` checker bundle.
- **Phase gate:** admin suite green; `cd reference/demo_app && MIX_ENV=test mix test --seed 0` (restore `mix.lock` swoosh drift after); operator browser run of the 13-spec set Phase 177 used; `bash scripts/gsd-regression-gate.sh` (heavy); then the hosted runs. Full suite green before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex` + `test/mailglass_admin/preview/scenario_label_test.exs`
- [ ] `mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs` (rule, teeth, dual-location resolver, slug)
- [ ] `mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs` (template `phase175_prohibition_contract_test.exs`, 457 lines; 177's is 1426)
- [ ] `reference/demo_app/storybook/preview_authoring.story.exs`, `preview_authoring/1` builder, `reference/demo_app/assets/e2e/phase178-stories.spec.js`
- [ ] `scripts/check_phase178_candidate.sh` (+ a bash self-test in the style of `scripts/test_check_phase173_candidate.sh` if the planner wants the script itself tested)
- [ ] Optional `mailglass_admin/e2e/support/real-zoom.cjs`
- [ ] Framework install: none.

## Security Domain

`security_enforcement` is not set to `false`, so this section applies.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (unchanged) | Existing host-owned auth seam; Phase 177 P8 forbids widening Preview sessions |
| V3 Session Management | no | Preview session whitelist must remain unwidened (`phase177_prohibition_contract_test.exs` P8 stays green) |
| V4 Access Control | yes (indirect) | Preview must not gain Account scoping; Account/return context only in hrefs (P2/P4) |
| V5 Input Validation | yes | `parse_assigns/3` + `parse_scalar/2` unchanged; forged event test (`preview_live_test.exs:1027`) must stay green; scenario atoms in URLs are server-resolved from discovered set |
| V6 Cryptography | no | none |
| V7/V8 Logging/data protection | yes | Telemetry unchanged (no new metadata); evidence uses synthetic data only; do not log assigns values |
| V10 Malicious code / supply chain | yes | Pushing 301 commits and opening a PR triggers workflows on a same-repo branch; secrets (`HEX_API_KEY`) are referenced only by publish steps; no publish workflow triggers on PR |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| HTML/Unicode-looking scenario or Mailable names rendered in the selector or story | Tampering/XSS | HEEx auto-escaping; tests with `<script>`-looking and RTL/emoji names (Health long-label precedent) |
| Dangling `aria-describedby` after removing ids | Spoofing of a11y semantics | Rendered-id-closure detector in the prohibition contract |
| Forged `assigns_changed` for read-only keys | Tampering | existing parse allow-list (`:read_only`), test stays |
| Unauthorized remote action (push/PR/dispatch/merge) | Elevation | One user-originated approval checkpoint (`autonomous: false`); never merge, never push `main`, no branch-protection change; PR title non-bumping and draft |
| Evidence leaking real data | Information disclosure | Synthetic fixtures only; evidence dir is git-ignored; never commit `reference/demo_app/tmp/` |
| CSS served differs from committed bundle | Tampering/integrity | Source/built/served SHA-256 triple (173 mechanic) |

## Project Constraints (from CLAUDE.md)

- **D-52 shift-left:** zero routine owner UAT. Close machine-observable acceptance as `source: automated` with the covering test; must-NOT prohibitions are `verification: test` (template `phase175_prohibition_contract_test.exs`); owner hand-off limited to ship/no-ship, brand/visual identity, secrets, `hex-publish`, physical devices, each with a full-URL runbook. No "reply yes if this matches" checkpoints for observable things.
- **Decision policy:** research first, decide, escalate rarely; the push/PR/dispatch checkpoint is an owner-hand-off item by D-13, not a research gap.
- **Things not to do:** no `Application.compile_env*` outside `Mailglass.Config`; no PII in telemetry; match errors by struct not string; do not write `mailglass_admin/priv/static/` without committing the rebuilt bundle (CI `git diff --exit-code`); no singletons via `name: __MODULE__` in library code.
- **Brand/voice:** errors/specific microcopy, direct word ("preview" not lifecycle jargon); no glassmorphism; copy decided via ux-writing (D-03).
- **Commit conventions:** Conventional Commits; PR title type must be one of feat/fix/docs/style/refactor/perf/test/build/ci/chore/revert (`pr-title.yml`); `docs(state):` for STATE-only; all third-party Actions SHA-pinned (do not edit workflows without keeping pins).
- **Release ledger:** do not touch `.planning/release-target.json`; no version bump, merge, publication or deployment (REQUIREMENTS "Automatic package version bump…" out of scope).
- **Memory-derived project facts that apply:** local toolchain env override; execute-phase worktrees are impractical (run sequentially on main); `gsd-sdk commit` stages all dirty `.planning/` paths (inspect `git show --stat HEAD`; `.planning/HANDOFF.json` is currently deleted and several `.planning/research/*`, `seeds/*` are modified in the working tree and `prompt.txt` is untracked, so use path-scoped commits); Mix build-lock stdout flake can red the next unrelated lane; `phase.complete` refuses when evidence is post-merge (do not manufacture it).

## Recommended Wave / Plan Decomposition

Tracer-first, source frozen before any remote action. File overlap means serial execution on `main` (memory: worktree isolation is impractical here).

| Wave | Plan | Scope | Reqs | Depends | Verifies |
|------|------|-------|------|---------|----------|
| 1 | 01 Restore + guidance tracer | `assigns_form.ex` button + D-02 helper removal + form note + describedby closure; update 9 pins (`voice_test`, `preview_live_test`, `flows.spec`, `structural.spec:2376`); one geometry browser case | PRVUX-05, PRVUX-06 | — | ExUnit files, scoped Playwright, conformance script |
| 1 | 02 Pure `ScenarioLabel` | module + exhaustive pure tests (no UI change) | PRVUX-07 | — | `scenario_label_test.exs` |
| 2 | 03 Selector UI | `Sidebar.menu` uses label map (+ `open` attr), colliding fixture scenario, `discovery_test`/`"6 emails"`/trigger-pin rewrites, narrow + collision + keyboard browser cases | PRVUX-07 | 02 (and 01 for shared test files) | ExUnit + scoped Playwright + Phase 177 return spec stays green |
| 3 | 04 Stories + ledger | `preview_authoring/1` builder, JSON rows, story, `quick_view_projection_test` cases, demo inventory spec; ledger corrections (6 rows + `feedback_ids` links + pointers); `feedback_ledger_test.exs`; fix `quick-views.spec.js:300-303` | STORY-07, UIQ-04 | 01, 03 | ExUnit; demo spec (advisory) |
| 3 | 05 Real-zoom gaps | helper; Preview selector+restore (extend `structural.spec:1790`), Health, Account, quick-view overlay, Phase 176 migrate-or-relabel, `phase174-review.md:20` (D-11), Phase 174 limit wording | UIQ-06 | 01, 03 | scoped Playwright, checker tests |
| 4 | 06 Prohibition contract | D-15 rules, teeth, clean-state, **recorded mutation table** (change source, see red, revert with path-specific `git checkout`) | all (D-15) | 01-05 | contract file at `--seed 0 --warnings-as-errors` |
| 5 | 07 Freeze + local gates | full admin suite, demo suite, operator browser 13-spec run, regression gate, code review, `178-AUTOMATION.md` (local-proof half) | — | 01-06 | all |
| 6 | 08 Checkpoint + hosted | **owner checkpoint (`autonomous: false`)**: fast-forward push of the exact SHA, draft PR, one dispatch; then `gh run view` capture, cost/expected-executed tables, `--require-ci` on the dispatch artifact, `178-COST-DISPOSITION.json` | UIQ-07 | 07 | hosted checks |
| 6 | 09 Candidate + runbook | `check_phase178_candidate.sh`, `178-DELIVERY.md` (full URLs, SHA, CSS identity, dispositions, teardown), every URL fetched 200 | UIQ-08 | 08 (SHA, CI) | script output + curl |

Review URLs to include in the runbook (all must be fetched before hand-off): `http://127.0.0.1:<port>/dev/mail`, `/dev/mail/MailglassAdmin...` is test-only, so use the demo route `/dev/mail/MailglassDemoWeb.Mailers.AccountMailer/invite_admin` (this scenario shows four identical "Text value." helpers today per CONTEXT specifics; after the repair it should show none), `/dev/storybook/preview_authoring`, `/dev/storybook/preview_chrome`, `/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar`, plus the PR and run URLs.

## Sources

### Primary (HIGH confidence)
- In-repo, opened and read this session: `assigns_form.ex`, `sidebar.ex`, `preview_live.ex` (190-300, 410-580, 1036-1042), `test/support/fixtures/mailables.ex`, `preview_live_test.exs` (20-260, 460-540, 960-1125), `voice_test.exs`, `discovery_test.exs`, `quick_view_projection_test.exs`, `phase175_prohibition_contract_test.exs` (head), `mix.exs`, `e2e/structural.spec.js` (1500-1862, 2340-2445), `e2e/flows.spec.js`, `e2e/phase176-filters.spec.js`, `e2e/phase175-inbound.spec.js`, `reference/persona_spec/quick_view_scenarios.{json,ex}`, `preview_chrome.story.exs`, `quick-views.spec.js`, `storybook-fidelity.spec.js`, `phase177-stories.spec.js`, `scripts/check_phase173_candidate.sh` (all 571 lines), `run_demo_browser_evidence.sh` (partial), `check_phase174_evidence.cjs` (partial), `gsd-regression-gate.sh`, `ci.yml` (jobs at 886/954/1042/1072/1428), `config/quality/ci_policy.exs`, `guard-release-trigger.yml`, `scripts/guard_release_trigger.sh`, `pr-title.yml`, `check-conformance.sh`, `173-DELIVERY.md`, `173-REMOTE-CI.md`, `174-COST-DISPOSITION.json`, `phase174-review.md`, `phase175-review.md`, `175-AUTOMATION.md`, `177-AUTOMATION.md`, `176-VERIFICATION.md`.
- Commands run: `gh run view 40414024714 --json jobs` (per-job durations), `playwright test --list` (300 / 109), `git rev-list`/`merge-base` (branch facts), `mix test` baseline (141 tests, 0 failures), scoped Playwright (3 passed), `check-conformance.sh` (clean), `docker ps`, `gh auth status`, `gh run list --branch …` (`[]`).
- GitHub Docs, events that trigger workflows (`pull_request`: `GITHUB_SHA` = last merge commit on `refs/pull/N/merge`; checkout uses the merge branch; use `github.event.pull_request.head.sha` for the head): https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows

### Secondary (MEDIUM confidence)
- Project memory notes (`MEMORY.md` entries on release gotchas, token-parity landmine, v2.7 archive coupling, test_exceptions line coupling) used as warnings, each re-checked against source where feasible.

### Tertiary (LOW confidence)
- None relied on without a tag; see Assumptions Log (A1-A6).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new packages; versions and counts measured.
- Architecture: HIGH - all touched components read in full; pins enumerated by grep and read.
- Pitfalls: HIGH for 1, 3, 5, 6, 8, 10 (read from source); MEDIUM for 2, 7 (hosted behaviour).
- Cost outcome: LOW/unknown by design - only a hosted run can measure it.

**Research date:** 2026-10-29
**Valid until:** 2026-11-05 for CI/branch facts (fast-moving: any push to `main` or the branch changes baselines); 30 days for component/pin facts, provided no one edits `assigns_form.ex`, `sidebar.ex` or the listed specs first.
