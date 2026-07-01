---
phase: 118-method-audit-storybook-stand-up
plan: 03
subsystem: testing
tags: [playwright, persona-critic, screenshot-seam, defect-register, ia, method-inversion, evidence]

# Dependency graph
requires:
  - phase: 118-01
    provides: "git-ignored screenshot evidence cache (.planning/research/**/.cache/) + the dev-only /dev/storybook review surface + retained /dev/mail/gallery"
  - phase: 116-bucket-a-ratchet-arm
    provides: "the seeded persona cohort (northstar/fjordline-aps/helios-void) via make demo -> DemoData.reset! -> Personas.seed!"
provides:
  - "reference/demo_app/assets/e2e/persona-screenshots.spec.js — a reusable screenshot SEAM (not a new harness, not a pixel-diff baseline) reusing @playwright/test to drive the running make demo across a prioritized 66-cell persona/viewport/theme/state sample into the git-ignored cache"
  - ".planning/research/v1.14/DEFECT-REGISTER.md — the MILESTONE-scoped, prioritized, severity-ranked, screenshot-backed hit-list that drives every Phase 119-122 surface redesign"
affects: [119-shell-nav-overview-redesign, 120-deliveries, 121-inbound, 122-preview, 123-cross-surface-coherence-ratchet-rearm]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Screenshot seam pattern: reuse the existing demo @playwright/test runner + playwright.config.cjs baseURL/DEMO_BASE_URL/PORT resolution; emit page.screenshot() per cell into a git-ignored evidence cache; NEVER a pixel-diff baseline"
    - "Prioritized cell sampling: anchor square (surface x persona x {375,1440} x {light,dark}) + targeted per-persona state cells + #1/#2 system/320/768 spot-checks — ~66 evidence shots, not the ~1,620-cell Cartesian sweep"
    - "Persona auth via the human /demo/login?return_to= path (Pitfall 5) + the existing /demo/evidence/reset cohort seam (no new seed path, D-03)"

key-files:
  created:
    - reference/demo_app/assets/e2e/persona-screenshots.spec.js
    - .planning/research/v1.14/DEFECT-REGISTER.md
  modified: []

key-decisions:
  - "Login path resolved (Pitfall 5): the seam authenticates operator surfaces via /demo/login?return_to= (the human path cohort.spec.js uses against the demo), NOT the /ops/browser-* helper routes; dev-only review surfaces (/dev/storybook, /dev/mail, gallery) are shot open (not session-gated)."
  - "Base URL resolved (Pitfall 4): the seam MUST run with DEMO_BASE_URL set so playwright.config.cjs treats the running Docker demo as an external server; with only PORT set the config tries to boot its own mix phx.server (which fails on the demo mix.lock drift)."
  - "Register lives at MILESTONE scope (.planning/research/v1.14/DEFECT-REGISTER.md, D-05), severity-ranked, every finding citing surface/persona/viewport/theme/state + screenshot path; the five hats + three personas are fixed traceable vocabulary."
  - "Headline defects named at precise sites (Pitfall 3): D-NAV-ACTIVE at operator_live.ex:349 (the SHELL is correct — the caller literal active={:deliveries} is the bug); D-NAV-DUP at operator_live.ex:416-448. operator.spec.js:352-368 (VERIF-02) flagged as a Phase-119 update target (Pitfall 2)."

patterns-established:
  - "Persona-critic evidence loop: drive make demo via the seam -> read PNGs back through the five hats -> author the severity-ranked register citing exact cells -> downstream phases re-shoot the same cells to prove only-forward improvement."

requirements-completed: [METHOD-01]

coverage:
  - id: D1
    description: "A screenshot seam reusing the existing demo @playwright/test infra drives the running make demo, capturing page.screenshot() per prioritized cell into the git-ignored cache"
    requirement: METHOD-01
    verification:
      - kind: e2e
        ref: "npx playwright test e2e/persona-screenshots.spec.js --list enumerates 66 prioritized cells (not the full Cartesian product)"
        status: pass
      - kind: e2e
        ref: "DEMO_BASE_URL=http://127.0.0.1:4015 DEMO_EVIDENCE_RESET_TOKEN=<token> npx playwright test e2e/persona-screenshots.spec.js --workers=1 => 66 passed; 66 PNGs land in .cache/screenshots/"
        status: pass
    human_judgment: false
  - id: D2
    description: "Screenshots land ONLY in the git-ignored cache; none are committed"
    requirement: METHOD-01
    verification:
      - kind: integration
        ref: "git check-ignore -v .planning/research/v1.14/.cache/screenshots/x.png (exit 0, .gitignore:45); git status --porcelain .planning/research/v1.14/.cache/ empty (no PNG tracked)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The milestone-scoped DEFECT-REGISTER.md is prioritized + severity-ranked, every finding citing its exact cell + screenshot path, judged against the binding STRESS-TEST-PROMPT.md rubric; the five hats + three personas are the traceable vocabulary; the known headline defects are registered with precise sites and operator.spec.js:352-368 is flagged for Phase 119"
    requirement: METHOD-01
    verification:
      - kind: integration
        ref: "grep -ciE 'severity|critical|high|medium|low' => 27; grep -c 'screenshots/' => 13; all five hats + three personas present; operator_live.ex:349 / :416-448 / operator.spec.js:352-368 all cited"
        status: pass
    human_judgment: true
    rationale: "Whether the register's findings genuinely capture the IA/redundancy problems at the right severity (vs missing some or over-flagging) is a judgment property — the maintainer reviews the register at the phase-boundary checkpoint (MILESTONE-SEED decision 2) before Phase 119 consumes it."
  - id: D4
    description: "No catalogued bug is fixed this phase (cataloguing only)"
    requirement: METHOD-01
    verification:
      - kind: other
        ref: "git status --porcelain operator_live.ex operator/shell.ex operator.spec.js => empty (no fix applied)"
        status: pass
    human_judgment: false

# Metrics
duration: 33min
completed: 2026-06-26
status: complete
---

# Phase 118 Plan 03: Persona-Critic Harness + DEFECT-REGISTER Summary

**A reusable screenshot seam (reusing the existing demo @playwright/test infra, NOT a new harness) drives the running `make demo` across a prioritized 66-cell persona/viewport/theme/state sample into the git-ignored cache, and a five-hat persona-critic walkthrough of that evidence produced the milestone-scoped, severity-ranked DEFECT-REGISTER.md — the hit-list that drives every Phase 119-122 surface redesign.**

## Performance

- **Duration:** ~33 min
- **Started:** 2026-06-26T16:33:00Z
- **Completed:** 2026-06-26T17:06:00Z
- **Tasks:** 2
- **Files created:** 2 (1 spec seam, 1 register) + 66 git-ignored evidence PNGs

## Accomplishments

- **Task 1 — screenshot seam.** Added `reference/demo_app/assets/e2e/persona-screenshots.spec.js`: an
  evidence producer that REUSES `@playwright/test` + the demo's `playwright.config.cjs`
  (baseURL/`DEMO_BASE_URL`/`PORT` resolution) — no new harness, no pixel-diff baseline (D-01/D-02). It
  drives a **prioritized 66-cell sample** (anchor square = each surface × the three personas ×
  {375,1440} × {light,dark}, plus system/320/768 spot-checks on the #1/#2 surfaces) — NOT the
  ~1,620-cell Cartesian sweep. PNGs land only in `.planning/research/v1.14/.cache/screenshots/`
  (confirmed git-ignored before the first run). Verified: `--list` enumerates exactly 66 cells; the live
  run produced **66 passed / 66 PNGs**.
- **Task 2 — DEFECT-REGISTER.** Ran the five-hat persona-critic walkthrough by reading the captured
  PNGs back and authored `.planning/research/v1.14/DEFECT-REGISTER.md` at MILESTONE scope (D-05):
  prioritized + severity-ranked, every finding citing surface/persona/viewport/theme/state + its
  screenshot path, judged against the binding `STRESS-TEST-PROMPT.md` rubric (Apple-like deliberate IA,
  not just WCAG nits). Registered the headline defects with precise sites and flagged the Phase-119 test
  contradiction.

## The hit-list (what Phase 119+ consume)

| Tag | Severity | Site | Phase |
|-----|----------|------|-------|
| D-NAV-ACTIVE | Critical | `operator_live.ex:349` (caller literal; **shell correct** per Pitfall 3) | 119 |
| D-NAV-DUP | High | `operator_live.ex:416-448` (`operator-overview-nav`) | 119 (+ VERIF-02 test update) |
| D-ORIENT-REDUNDANT | High | `operator/shell.ex:361-424` orientation strip | 119 set / 120 apply |
| D-OVERVIEW-SIGNPOST | High | overview branch | 119 |
| D-FILTERS-ON-EMPTY | High | Deliveries empty state | 120 |
| D-LABEL-TRIPLING | Medium | Deliveries | 120 |
| D-MOBILE-INFODUMP | Medium | Overview @ 375 | 119 |
| D-THEME-PARITY | Medium | (positive — hold-the-floor guardrail) | all |
| D-STORYBOOK-BRAND | Low | storybook explorer chrome | 123 (optional) |
| D-STORYBOOK-STALE-BOOT | Low | env caveat (fresh demo boot) | docs |

Evidence confirmed the maintainer's root-cause thesis directly: on the Overview route the sidebar
**always highlights Deliveries** (no Overview identity), and three independent redundancy paths
(sidebar nav · orientation card · "Navigate" card) all lead to Deliveries. The all-clear state
(fjordline/helios) makes the info-dump worst — nothing needs attention, yet the operator scrolls past
6 cards + a duplicate nav block.

## Pitfalls resolved (documented in the seam header + register)

- **Pitfall 1 (gitignore):** already in effect from Plan 01 (`.gitignore:45 /.planning/research/**/.cache/`) — verified exit-0 before the first shot.
- **Pitfall 2 (VERIF-02 contradiction):** flagged in the register 4× — `operator.spec.js:352-368` asserts `operator-overview-nav` IS visible; Phase 119 MUST update it when deleting the card.
- **Pitfall 3 (shell vs caller):** D-NAV-ACTIVE explicitly names the shell as correct and `operator_live.ex:349` as the sole bug site.
- **Pitfall 4 (Docker base URL):** the seam runs against the live Docker demo via `DEMO_BASE_URL`; documented in the spec header (with only `PORT`, the config boots its own server and fails on the demo lock drift).
- **Pitfall 5 (persona auth):** resolved to `/demo/login?return_to=` (the human path cohort.spec.js uses), documented in the seam header.

## Task Commits

1. **Task 1: persona-critic screenshot seam** — `95eef768` (feat)
2. **Task 2: prioritized screenshot-backed DEFECT-REGISTER** — `15c3a570` (docs)

**Plan metadata:** _(final docs commit — this SUMMARY + STATE/ROADMAP)_

## Files Created/Modified

- `reference/demo_app/assets/e2e/persona-screenshots.spec.js` (NEW) — the screenshot seam; reuses `@playwright/test`, routes personas via `/ops/mail?tenant_id=<persona>`, authenticates via `/demo/login`, themes via `?theme=` + `emulateMedia`, writes only to the git-ignored cache.
- `.planning/research/v1.14/DEFECT-REGISTER.md` (NEW) — the milestone-scoped, prioritized, severity-ranked, screenshot-backed hit-list (D-05).
- `.planning/research/v1.14/.cache/screenshots/*.png` (66 PNGs) — git-ignored evidence; NOT committed, NOT a pixel-diff baseline (D-02).

## Decisions Made

- **Login = `/demo/login?return_to=` (Pitfall 5).** The operator surfaces are session-gated; the seam uses the human login path (matching `cohort.spec.js`) rather than `/ops/browser-*`. Dev-only review surfaces are shot open.
- **`DEMO_BASE_URL` is mandatory for the live run (Pitfall 4).** `playwright.config.cjs` only treats the demo as external when `DEMO_BASE_URL` is set; otherwise it boots its own `mix phx.server`, which fails on the demo `mix.lock` drift. The seam adds no base-URL logic of its own (config-owned).
- **Register at milestone scope, five hats + three personas as fixed vocabulary (D-04/D-05).** Findings are traceable to a hat and a persona so 119-123 can consume them without ambiguity.

## Deviations from Plan

**None — plan executed exactly as written.** One blocking-issue auto-fix (Rule 3) was required to get
the live evidence run green; documented below.

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Stale demo container could not hot-reload Plan 01's storybook router change**
- **Found during:** Task 1 (first live screenshot run).
- **Issue:** The running `make demo` Docker container (`mailglass-demo-demo-1`) was booted **before**
  Plan 01 added `live_storybook` + `import PhoenixStorybook.Router` to the demo router and added
  `{:phoenix_storybook, "~> 1.2"}` to the demo deps. Its deps/`_build` volumes had not run
  `mix deps.get` since, so `MailglassDemoWeb.Router` failed to hot-recompile (`UndefinedFunctionError:
  MailglassDemoWeb.Router is not available`) and `POST /demo/evidence/reset` returned 500 — no
  evidence could be produced.
- **Fix:** ran `mix deps.get` + `mix compile` **inside the container** to sync deps (fetched
  phoenix_storybook + transitive closure), then `docker restart` for a clean boot so the
  `live_storybook` macro loaded. After the restart: operator surfaces hot-reload fine, `/demo/evidence/reset`
  returns 200, `/dev/storybook` returns 302 (renders the explorer), and the full 66-cell run passed.
- **Lock hygiene:** the in-container `mix deps.get` wrote through to the **host-mounted**
  `reference/demo_app/mix.lock`, re-bumping plug/plug_cowboy/premailex/swoosh (the documented demo_app
  transitive drift). Per the project's mix.lock-integration policy, that drift was **reverted on the
  host** (`git checkout -- reference/demo_app/mix.lock`) — it is NOT part of this plan's files and is not
  committed. The container keeps its fetched deps; the host lock stays at the committed baseline.
- **Files modified:** none committed (container-runtime + host-lock-revert only).
- **Commit:** n/a (no source change — the seam + register are the deliverables).

## Issues Encountered

- **`/dev/storybook` 500 under hot-reload (D-STORYBOOK-STALE-BOOT, Low).** Registered as a Low
  environment caveat: a demo container that predates Plan 01's router change cannot hot-load
  `live_storybook` and 500s until a fresh `make demo`/`docker restart`. After a clean boot the explorer
  renders correctly (re-shot — the current `storybook-any-*` evidence shows the working explorer). This
  confirms Plan 01's pending **D2 human_judgment** item ("load `/dev/storybook` against a running
  `make demo`") — storybook renders **after a clean boot**.
- **Storybook explorer chrome is off-brand (D-STORYBOOK-BRAND, Low).** The explorer header uses
  phoenix_storybook's default indigo, not the mailglass palette; the *sandbox* correctly uses the
  committed admin bundle (Plan 01 D-07). Dev-only review surface — cosmetic; optional token pass in 123.

## User Setup Required

None for the deliverables. To **re-run the seam** against a fresh demo:
```
make demo   # or docker restart mailglass-demo-demo-1 (clean boot so /dev/storybook loads)
cd reference/demo_app/assets
DEMO_BASE_URL=http://127.0.0.1:4015 DEMO_EVIDENCE_RESET_TOKEN=<demo-token> \
  npx playwright test e2e/persona-screenshots.spec.js --workers=1
```
(The reset token is the value `make demo` was launched with — readable via
`docker exec mailglass-demo-demo-1 printenv DEMO_EVIDENCE_RESET_TOKEN`.)

## Next Phase Readiness

- **Phase 119 (keystone) is unblocked:** the prioritized hit-list is authored at milestone scope. 119
  owns D-NAV-ACTIVE (`operator_live.ex:349`), D-NAV-DUP (`operator_live.ex:416-448`),
  D-OVERVIEW-SIGNPOST, D-MOBILE-INFODUMP, and sets the empty-pane-only orientation pattern. It MUST
  update `operator.spec.js:352-368` (VERIF-02) when deleting the Navigate card, and flip the drafted
  `judgment.spec.js` gates `test.fixme`→`test` once the bug is fixed.
- **Re-shootable evidence:** the seam is rerunnable, so 119-122 can re-capture the same cells after each
  redesign to prove only-forward improvement (the D-THEME-PARITY floor must not regress).
- **Maintainer checkpoint:** per MILESTONE-SEED decision 2, the maintainer reviews this register at the
  phase boundary before 119 consumes it.

## Self-Check: PASSED

- FOUND: `reference/demo_app/assets/e2e/persona-screenshots.spec.js`
- FOUND: `.planning/research/v1.14/DEFECT-REGISTER.md`
- FOUND commit: `95eef768` (feat: screenshot seam)
- FOUND commit: `15c3a570` (docs: DEFECT-REGISTER)
- 66 evidence PNGs in `.cache/screenshots/`, none tracked (`git status --porcelain .cache/` empty)
- No catalogued bug fixed (operator_live.ex / shell.ex / operator.spec.js all clean)

---
*Phase: 118-method-audit-storybook-stand-up*
*Completed: 2026-06-26*
