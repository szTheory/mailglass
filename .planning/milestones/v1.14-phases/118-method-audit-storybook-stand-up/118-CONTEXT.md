# Phase 118: Method, Audit & Storybook stand-up - Context

**Gathered:** 2026-06-26 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Stand up the **inverted, judgment-level review method** for v1.14 — an adversarial
persona-critic harness that produces the prioritized, screenshot-backed **defect register**
(the hit-list) driving every later surface redesign — PLUS a dev-only `phoenix_storybook`
review surface, the new judgment-level regression gates (drafted), and the inherited v1.13
ratchet floor (kept green).

**This is a pure tooling/method phase. It redesigns NO surface.** The false-active-nav bug,
redundant nav cards, info-dump pages, etc. are *catalogued* here and *fixed* in Phases 119-123.
Producing the review apparatus + the hit-list is the entire deliverable.

Requirements: METHOD-01, METHOD-02, STORY-01, STORY-02.
Hard precondition for Phase 119 (the keystone shell redesign consumes the hit-list).
</domain>

<decisions>
## Implementation Decisions

### Persona-Critic Harness (METHOD-01)
- **D-01:** The harness runs as **agent-orchestrated Playwright walkthroughs** against the
  already-running `make demo` instance, reusing the existing Playwright infra
  (`reference/demo_app/assets/e2e/`, `reference/demo_app/assets/playwright.config.cjs`,
  `make demo-e2e`; plus `mailglass_admin/e2e/`). Critic agents invoke short `page.screenshot()`
  scripts per surface×viewport×theme×state cell, read the images back, and author findings.
  **No new screenshot harness is built** — it already exists.
- **D-02:** Screenshots are saved to a **gitignored working dir**
  (`.planning/research/v1.14/.cache/screenshots/`; `.planning/research/.cache/` is already
  gitignored) as **evidence attachments only**. They are explicitly **NOT** a pixel-diff
  visual-regression baseline (pixel-diff is out of scope per REQUIREMENTS.md).
- **D-03:** The three personas are **already seeded by `make demo`** —
  `DemoData.reset!/0` (`reference/demo_app/lib/mailglass_demo/demo_data.ex`) runs the northstar
  lifecycle then `MailglassDemo.Personas.seed!` materializes `fjordline-aps`, leaving
  `helios-void` intentionally absent (the zero-data state). They map directly to tenant ids
  reached via `/ops/mail?tenant_id=<persona>` (northstar = many/high-count/error,
  fjordline-aps = one/long-ID/non-ASCII/null, helios-void = zero-data). **No new seed path**;
  duplicating `Personas.seed!` would risk the persona drift-guard.
- **D-04:** The five adversarial hats are: **dev-evaluator, library-integrator,
  maintainer-debugging, operator/on-call-SRE-under-stress, security-reviewer**. They walk
  every admin surface (live `make demo` + the storybook/gallery review surfaces) across the
  full **320/375/768/1024/1440/wide × light/dark/system ×
  happy/empty/loading/error/permission-denied/boundary** matrix. The judgment rubric is the
  binding **STRESS-TEST-PROMPT.md** (redundancy/earns-its-place; IA clarity & least-surprise;
  nav-reflects-location; info-dump vs streamlined; crowding; hierarchy; microcopy;
  modal/scroll/focus footguns; semantic icons; cross-surface consistency) — must not be diluted.

### Defect Register (METHOD-01)
- **D-05:** The durable hit-list lives at **`.planning/research/v1.14/DEFECT-REGISTER.md`**
  (milestone-research scope, sibling to `MILESTONE-SEED.md` / `STRESS-TEST-PROMPT.md`),
  **prioritized + severity-ranked**, each finding citing its surface/persona/viewport/theme/state
  and its screenshot path. Milestone scope (not per-phase) so Phases 119-123 consume it without
  reaching into an archived phase dir. *(User-confirmed 2026-06-26.)*

### phoenix_storybook Integration (STORY-01, STORY-02)
- **D-06:** phoenix_storybook is added to **`reference/demo_app/mix.exs`** as
  `{:phoenix_storybook, "~> 1.2", only: :dev}` and mounted **dev-only in the demo router**
  (`reference/demo_app/lib/mailglass_demo_web/router.ex`). The backend module + `*.story.exs`
  files live **in the demo app**, **NOT** in the shipped `mailglass_admin/lib/`. Rationale:
  `mailglass_admin/mix.exs` `:files` ships the `lib` glob, so a `lib/mailglass_admin/storybook.ex`
  would be tarballed to adopters AND fail their compile (the dev-only dep is absent). The demo is
  already the dev host that mounts admin surfaces (`import MailglassAdmin.Router` +
  `mailglass_admin_routes("/mail", ...)`). **Load-bearing placement.**
- **D-07:** The storybook **sandbox stylesheet is wired via `css_path`** pointing at the
  already-served committed admin bundle route (the `MailglassAdmin.Controllers.Assets :css`
  route, served as `/mail/css-<md5>` via `__asset_routes__`). `css_path` is just a `<link>` URL
  string — **no new Tailwind/esbuild build of our component CSS**, and the committed
  `mailglass_admin/priv/static/app.css` is **unchanged** (STORY-01; zero-Node adopter guarantee
  intact). **Omit `js_path`** (stories are static markup) ⇒ no esbuild watcher needed in the
  demo's `dev.exs`. The storybook explorer's own UI assets ship prebuilt in the hex package and
  are served by the `storybook_assets()` router macro. **Do NOT run `mix phx.gen.storybook`
  unmodified** — it scaffolds a watcher + `storybook.css`/`storybook.js` build path we are
  deliberately avoiding; hand-write the config module instead.
- **D-08:** **Theme bridge.** phoenix_storybook applies CSS **classes** to the sandbox
  (`dark`/`light` via `color_mode`, or named-theme keys via `themes:`), but admin components key
  off `data-theme="mailglass-light|mailglass-dark"` (`operator/shell.ex` `mg-admin-root`). Bridge
  by having story templates set `data-theme` on the rendered root from the theme assign (or a
  **storybook-only** alias shim). **Never** edit the committed `app.css` to add the alias — that
  would trip `TokenParityTest` and the `priv/static` drift gate.
- **D-09:** `phoenix_storybook` v1.2 supports Phoenix 1.8 / LiveView 1.1 (repo pins
  `{:phoenix, "~> 1.8"}`, `{:phoenix_live_view, "~> 1.1"}`). Note the v1.0 rename: "Story" →
  "Variation", "StoryGroup" → "VariationGroup", files are `*.story.exs` — ignore pre-1.0
  tutorials.
- **D-10:** STORY-02: the existing **`/dev/mail/gallery`** (`gallery_live.ex`) is **retained
  unchanged** as the structural-contract/ratchet surface — no drift-guard regression. Storybook
  is added **alongside** as the interactive review surface (consolidation deferred to a future
  requirement, only if the two prove redundant).

### New Judgment Gates (METHOD-02)
- **D-11:** The two new gates are expressed as **Playwright rendered-DOM assertions** (a sibling
  of `mailglass_admin/e2e/structural.spec.js`), NOT conformance greps and NOT pure Floki ExUnit:
  - **nav-active-correctness** — on the Overview route the nav item for `:overview` renders
    active (`aria-current="page"`) and Deliveries renders inactive.
  - **no-nav-duplication** — the populated Overview does not render the redundant "Navigate" card
    block (`data-testid="operator-overview-nav"`).
  Active-state correctness is a *rendered* property a grep cannot evaluate (the bug is a hardcoded
  `active={:deliveries}` literal at `operator_live.ex:349`); the existing accent-allowlist
  Playwright infra already keys off `[aria-current='page']`.
- **D-12:** In Phase 118 the gates are **DRAFTED as pending/xfail** (documented, asserting the
  correct end-state) — **not armed green**. The bug they target is live and not fixed until
  Phase 119, so arming green now would force weakening the assertions to pass on buggy UI (baking
  the bug into the gate). They turn green in Phase 119 (when the bug is fixed) and are armed into
  the ratchet floor in Phase 123 (the roadmap's explicit re-arm phase). This reconciles
  METHOD-02's "armed, green, added to the floor" wording with the buggy-code reality.
  *(User-confirmed 2026-06-26: do NOT pull the 119 nav fix into 118.)*

### Ratchet Floor Inheritance (METHOD-02 success criterion 4)
- **D-13:** "Inherit green" in Phase 118 means a **verification run only** — prove the existing
  floor is green on clean main. **NO pillar re-score** (locked: re-score is Phase 123), **NO
  arming** the new judgment gates into the floor yet, and storybook is a review surface that is
  **never** a ratchet gate.
- **D-14:** The exact inherited floor artifacts to verify-green:
  1. ~26 conformance gates — `mailglass_admin/scripts/check-conformance.sh` (PRIMITIVE-DRIFT,
     FORM-DRIFT, STATCARD, ICON-EXISTS, BADGE, TYPE, BOLD, GAP, SPACE, GROUP, HEX, Z-INDEX,
     FOCUS-RING, SCOPE, TOKEN-SCOPE, PHASE112-SHELL, VOICE, RADIUS, SHADOW, BORDER, SIZE, MOTION,
     STATUS-BADGE, DATA-STATE, TABLE-OVERUSE).
  2. 54-cell aesthetic baseline — `docs/ui-baseline-scores.json` + `ratchet_baseline_test.exs`
     (`schema_version: 3`, 54 cells in both `prior` + `current` blocks).
  3. 9-cell axe baseline — `docs/axe-baseline.json` + `axe_baseline_test.exs` + the paired
     `mailglass_admin/e2e/axe-baseline.spec.js`.
  4. 24-item Bucket-A manifest — `bucket_a_coverage_test.exs` (coupled to `TABLE_FLOOR=3` at
     `check-conformance.sh`).
  5. Persona drift-guard — `persona_drift_guard_test.exs` + `persona_cohort_test.exs` (protects
     the same `MailglassDemo.Personas.spec/0` cohort the harness uses).

### Claude's Discretion
- Exact story-file inventory (which primitives/groups/pages get stories first) — planner's call,
  guided by the STRESS-TEST-PROMPT fractal scope (foundations → primitives → groups → pages).
- Whether to use `color_mode: true` vs `themes:` for the storybook theme toggle — pick whichever
  cleanly drives `data-theme` per D-08.
- Screenshot-cell sampling strategy (full Cartesian matrix vs prioritized representative cells per
  surface) — agent harness design detail.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/v1.14/STRESS-TEST-PROMPT.md` — **binding quality bar** (the persona-critic
  rubric + viewport/theme/state matrix; must not be diluted).
- `.planning/research/v1.14/MILESTONE-SEED.md` — maintainer-locked decisions + critical anchors.
- `.planning/REQUIREMENTS.md` — METHOD-01/02, STORY-01/02 + cross-cutting matrix + out-of-scope.
- `.planning/ROADMAP.md` — Phase 118 goal/success-criteria + the 118→119→…→124 sequencing.
- `reference/persona_spec/personas.ex` — northstar / fjordline-aps / helios-void cohort spec.
- `reference/demo_app/lib/mailglass_demo/demo_data.ex` — `reset!/0` seed path + `Personas.seed!`.
- `mailglass_admin/scripts/check-conformance.sh` — the ~26-gate conformance floor.
- `brandbook/brand-book.md` — brand source of truth (newest wins over prompt-era research).

**External (resolved this session):**
- phoenix_storybook docs — sandboxing (`css_path`), color_modes (class-not-data-theme),
  setup (`storybook_assets()` / `live_storybook`), v1.2.0 (Phoenix 1.8 / Tailwind v4 aligned):
  https://phoenix-storybook.hexdocs.pm/sandboxing.html ,
  https://phoenix-storybook.hexdocs.pm/color_modes.html ,
  https://phoenix-storybook.hexdocs.pm/setup.html
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Playwright harness already exists** — `reference/demo_app/assets/playwright.config.cjs`,
  `@playwright/test ^1.59.1`, `make demo-e2e` → `demo_e2e` compose service, plus
  `mailglass_admin/e2e/{operator,structural,axe-baseline}.spec.js`. Screenshotting is a
  `page.screenshot()` away.
- **Persona seed already wired** — `make demo` boots the cohort via `DemoData.reset!` →
  `MailglassDemo.Personas.seed!`; reachable at `/ops/mail?tenant_id=<persona>`.
- **Served admin CSS bundle** — built once by the standalone Tailwind binary
  (`mix mailglass_admin.assets.build`, `runtime: false {:tailwind, "~> 0.4"}`), committed at
  `mailglass_admin/priv/static/app.css`, served via `MailglassAdmin.Controllers.Assets :css`
  (`__asset_routes__`, referenced from `layouts/root.html.heex` as `css_url(assigns)`). This is
  the exact bundle `css_path` points at. The demo has **no** `assets/css/` of its own and **no**
  watcher in `dev.exs`.
- **`/dev/mail/gallery`** (`gallery_live.ex`) — existing structural-contract specimen surface.

### Established Patterns
- The demo app is the dev-only host that mounts admin surfaces (`import MailglassAdmin.Router` +
  `mailglass_admin_routes("/mail", ...)`) — the natural home for a dev-only storybook.
- `mailglass_admin/mix.exs` `:files` ships the `lib` glob ⇒ anything dev-only must stay OUT of
  `mailglass_admin/lib/` to avoid shipping unbuildable source to adopters.
- Bundle-clean gate: `mix verify.preview` runs `git diff --exit-code priv/static/` — any rebuild
  that mutates `app.css` fails CI (and would trip `TokenParityTest`).
- The accent-allowlist Playwright spec already keys off `[aria-current='page']` — the seam the
  nav-active-correctness gate plugs into.

### Integration Points
- **Bug sites (catalogued in 118, fixed in 119):** `operator_live.ex:349` hardcoded
  `active={:deliveries}`; redundant "Navigate" cards `operator_live.ex:416-448`
  (`data-testid="operator-overview-nav"`); shell nav `operator/shell.ex:216-244`; generic
  orientation strip `operator/shell.ex:361-424`.
- **Storybook mount:** demo router (dev-only scope) — `storybook_assets()` +
  `live_storybook "/storybook", backend_module: ...`.
- **Theme seam:** components read `data-theme` on `mg-admin-root` (`operator/shell.ex:219`);
  storybook gives a sandbox class ⇒ bridge per D-08.
</code_context>

<specifics>
## Specific Ideas

- **Apple-like, deliberate IA** is the north star for the redesign the hit-list will drive; the
  defect register should frame findings against that bar, not just enumerate WCAG nits.
- The five named hats (D-04) and the three named personas (D-03) are fixed vocabulary — use them
  verbatim in the register so findings are traceable.
</specifics>

<deferred>
## Deferred Ideas

- **Consolidating `/dev/mail/gallery` into `phoenix_storybook`** (migrate ratchet testids) —
  deferred per REQUIREMENTS.md "Future Requirements"; only if the two surfaces prove redundant
  after STORY-01 lands. Both are kept in v1.14.
- **Arming the new judgment gates into the floor + pillar re-score** — Phase 123, not 118 (D-12,
  D-13).
- **Fixing the false-active-nav bug + removing redundant nav cards** — Phase 119, not 118
  (user-confirmed: do not front-load the redesign into the method phase).

### Reviewed Todos (not folded)
None — `todo.match-phase 118` returned 0 matches.
</deferred>
