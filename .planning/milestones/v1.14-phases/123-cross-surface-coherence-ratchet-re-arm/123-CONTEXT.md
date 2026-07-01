# Phase 123: Cross-surface coherence + ratchet re-arm - Context

**Gathered:** 2026-06-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the four redesigned surfaces (Overview/shell, Deliveries, Inbound, Preview) **cohere as one
deliberate, Apple-like system**; **finalize** the dev-only `phoenix_storybook` + `/dev/mail/gallery`
review surfaces; **re-score the 54-cell aesthetic ratchet only-forward** (meet-or-beat, zero
regressions); and **arm the two new judgment gates** (nav-active-correctness, no-nav-duplication)
into the permanent floor so the redesign's headline fixes cannot silently regress.

**This is a re-score-and-arm phase, NOT a redesign.** Phases 119-122 already redesigned all four
surfaces and HELD the ratchet floor green only-forward. Phase 123 is the explicit re-score + re-arm
phase: **purely test / doc / JSON edits — no surface HEEx change, no committed asset-bundle rebuild,
no new product capability.** It is the last surface-touching phase before the release cut (Phase 124).

Requirements: COH-01 (cross-surface coherence + storybook/gallery finalized & consistent),
COH-02 (ratchet baseline re-scored only-forward; all inherited gates + the two new judgment gates green).
</domain>

<decisions>
## Implementation Decisions

### Re-score mechanics (COH-02)
- **D-01:** **The re-score is a JSON-only promotion edit to `mailglass_admin/docs/ui-baseline-scores.json`.**
  Copy today's `current` block into `prior`, set `current.run_id` to a new distinct value
  (e.g. `2026-06-2x-phase-123`), run the LLM "D-07 procedure" scoring step to fill a fresh `current`
  block over the redesigned surfaces, and let `ratchet_baseline_test.exs` assert meet-or-beat
  (`compare_baselines/2`, only-forward, fails on any `current < prior`). The current JSON still reads
  `run_id: "2026-06-20-phase-116"` — 119-122 held the floor and never promoted, so the
  promotion + re-score is entirely Phase 123's job.
- **D-02:** **Only the 3 record-surfaces are scored: `deliveries`, `inbound`, `preview` × 6 pillars
  (Spacing/Radius/Color/Type/Elevation/Motion+A11y) × 3 themes (light/dark/system) = 54 cells.**
  `ratchet_baseline_test.exs:26` hardcodes `@surfaces ["deliveries","inbound","preview"]` — **Overview/shell
  is NOT a ratchet baseline surface.** Do NOT add an `overview` key (the fixed `@surfaces` list silently
  ignores it — wasted effort, zero gate coverage). Overview coherence rides on COH-01 (qualitative) + the
  structural/conformance/judgment gates, not the 54-cell aesthetic baseline.
- **D-03:** **The anti-vacuity guard is load-bearing.** `ratchet_baseline_test.exs:85-92` asserts
  `prior.run_id != current.run_id`; forgetting the run_id change fails loudly. Keep `schema_version: 3`
  (the test pins it). A re-scored cell that drops below prior (e.g. trading Motion for Spacing) blocks the
  release — surface any such regression rather than weakening the assertion.

### Arming the judgment gates (COH-02 / METHOD-02)
- **D-04:** **The two judgment gates are ALREADY executing and green in CI today — "arming" is a
  documentation/registration step, not a wiring step.** They were drafted `test.fixme` in 118, flipped to
  live `test(` in 119 (nav bug fixed). `playwright.config.cjs` `testDir:"./e2e"` globs the whole dir, so
  `judgment.spec.js` runs inside the *required* `operator_browser_gate` lane
  (`ci.yml:643-714` → `npm run test:operator-browser` → `playwright test`). A repo-wide grep finds the gate
  names in ZERO `.yml` and ZERO `.sh` files — there is nothing to wire.
- **D-05:** **Concretely, arming means:** (a) update the stale disclaimer comments in
  `mailglass_admin/e2e/judgment.spec.js` (`:16-18`, `:75`, `:102` — "NOT yet added to a required CI lane —
  arming is Phase 123") to reflect armed status; (b) record the two gates in the floor inventory / gate
  count (~26 → ~28) wherever the floor is documented (MILESTONE-SEED / DEFECT-REGISTER / any gate-count
  doc). **Do NOT edit `ci.yml`** (no lane to add — would risk double-running) and **do NOT add them to
  `check-conformance.sh`** (grep-based; cannot evaluate rendered active-nav state — D-11 deliberately chose
  rendered-DOM Playwright assertions). Check `gate-self-test.yml` for any gate-registry entry that should
  list them.

### Cross-surface coherence proof artifact (COH-01)
- **D-06:** **Coherence is proven by re-running the adversarial persona-critic harness across all four
  surfaces and recording the verdict in `.planning/research/v1.14/DEFECT-REGISTER.md`** — flip each
  catalogued defect's `Status:` from CATALOGUED to RESOLVED/FIXED with a maintainer sign-off note — backed
  by the green automated floor (conformance + 54-cell aesthetic + 9-cell axe + 24-item Bucket-A +
  persona-drift + the two judgment gates). **No new automated "coherence score" gate.** Coherence is a
  human-judgment property the MILESTONE-SEED explicitly says gates cannot express; the persona-critic
  verdict + maintainer sign-off + green floor is the auditable evidence trail Phase 124's milestone audit
  cites for COH-01. The DEFECT-REGISTER is the single traceable ledger (chosen over a fresh sibling
  `COHERENCE-AUDIT.md`).
- **D-07:** **The persona re-shoot is EVIDENCE for the coherence verdict, not a new ratchet cell.**
  Screenshots are gitignored working artifacts (118 D-02), never a committed pixel-diff baseline. Re-run
  the existing producer in one pass against `make demo`; the delta is the only-forward visual evidence.
  Do NOT add new persona cells and do NOT touch `MailglassDemo.Personas.spec/0` (the persona-drift-guard
  treats it as single source of truth — any change fails by triplication drift).

### Storybook + gallery finalization (COH-01)
- **D-08:** **`/dev/mail/gallery` (`gallery_live.ex`) stays byte-unchanged** — it remains the
  structural-contract/ratchet specimen surface (118 D-10). No drift-guard regression. Consolidation of
  gallery into storybook is deferred (out of scope per REQUIREMENTS Future Requirements).
- **D-09:** **D-STORYBOOK-BRAND: accept the indigo explorer chrome as-is (dev-only cosmetic).** The indigo
  is phoenix_storybook's prebuilt explorer-shell CSS shipped in the hex package
  (`priv/static/css/phoenix_storybook-*.css`, served by `storybook_assets()`) — distinct from the sandbox
  iframe, which we already style via `css_path`. The backend config's `css_path`/`sandbox_class` only style
  the sandbox, NOT the explorer shell. Theming it would mean editing the dep's CSS or adding a Node/esbuild
  `storybook.css` build — **both violate the zero-Node adopter guarantee and 118 D-07's hand-written-config
  decision.** Note it as accepted-cosmetic in the finalization record. (Non-blocking soft spot: whether
  v1.2 exposes any explorer-shell theme hook — accept-indigo is the right default regardless; if a clean
  config-only hook surfaces, the planner may use it, but do NOT build/edit CSS to chase it.)
- **D-10:** **D-STORYBOOK-STALE-BOOT: docs-only.** Add the caveat (the storybook live-route needs a fresh
  `make demo` after the dep was added) to the run-the-demo DX. No code change.
- **D-11:** **Story-inventory completeness check.** Verify the existing stories (foundations + the 5
  primitive stories: nav_link, tenant_chip, stat_card, nav_pill, theme_picker) are consistent with the
  shipped UI, and add stories for any primitive the 119-122 redesigns introduced or changed. Do NOT
  over-scope to every component — "finalized" means consistent with the redesign, not exhaustive.

### Asset / paired-test landmines
- **D-12:** **No committed asset-bundle rebuild.** A fresh `mix assets.build` emits raw-inline daisyUI
  5.5.19 theme blocks that BREAK `TokenParityTest` and fail `mix verify.preview`
  (`git diff --exit-code priv/static/`) — the recurring 120/121/122 landmine. CI's `test:operator-browser`
  rebuilds the bundle transiently but never commits it; the committed `priv/static/app.css` is canonical
  and stays untouched. Since this phase changes no HEEx/utility classes, a rebuild should be unnecessary.
- **D-13:** **Axe baseline needs NO re-shoot.** `docs/axe-baseline.json` `prior`/`current` run_ids are both
  `2026-06-21` (already re-shot during the 119-122 surface window) — axe is green-current. Hold it
  only-forward; do not re-run/commit a regressed axe cell.
- **D-14:** **Paired-test discipline still applies.** If the disclaimer-comment edits (D-05) or any doc-copy
  change touch a string that `voice_test.exs` or an e2e spec greps, update that assertion in the SAME phase
  (Pitfall-2 green-only-forward trap). This phase's surface area is small (JSON + comments + docs), so the
  trap is minimal — but verify before committing.

### Claude's Discretion
- Exact new `current.run_id` string for the re-score (must differ from prior; encode the phase, e.g.
  `2026-06-2x-phase-123`).
- The LLM scoring procedure detail for the 54-cell re-score (the "D-07 procedure" named in
  `ratchet_baseline_test.exs:14`) — planner/executor's call, must fill all 54 cells in `current`.
- Whether to record the coherence sign-off inline in DEFECT-REGISTER vs a short appended sign-off section
  (single-ledger preference per D-06, but format is open).
- Precise placement of the D-STORYBOOK-STALE-BOOT DX note (README/demo onboarding/storybook page) — pick
  the least-surprise home.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 123 goal/success-criteria (lines ~224-246) + the 118→…→124 sequencing.
- `.planning/REQUIREMENTS.md` — COH-01 / COH-02 + cross-cutting matrix + out-of-scope.
- `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` — the only-forward 54-cell gate
  (`@surfaces` `:26`; 54-cells-in-both-blocks `:46-62`; anti-vacuity run_id guard `:85-92`;
  `compare_baselines/2` meet-or-beat `:97-124`; `schema_version: 3` pin; the "D-07 procedure" moduledoc `:14`).
- `mailglass_admin/docs/ui-baseline-scores.json` — the baseline to promote+re-score (current `run_id`
  `2026-06-20-phase-116` `:35`; `prior` run_id `2026-06-16-phase-103`).
- `mailglass_admin/e2e/judgment.spec.js` — the two gates to arm (stale disclaimers `:16-18`, `:75`, `:102`;
  nav-active-correctness `:76-93`; no-nav-duplication `:103-113`).
- `mailglass_admin/playwright.config.cjs` (`testDir:"./e2e"` — globs judgment.spec) +
  `mailglass_admin/package.json:5` (`test:operator-browser`) + `.github/workflows/ci.yml:643-714` (the
  required `operator_browser_gate` lane that already runs the gates) + `.github/workflows/gate-self-test.yml`
  (gate-registry — check whether the two gates should be listed).
- `mailglass_admin/scripts/check-conformance.sh` — the ~26 grep-based conformance gates (the judgment gates
  do NOT belong here — rendered-DOM, not grep).
- `mailglass_admin/docs/axe-baseline.json` (run_ids both `2026-06-21` — already current; hold only-forward)
  + `axe_baseline_test.exs` + `mailglass_admin/e2e/axe-baseline.spec.js`.
- `mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs` (24-item Bucket-A manifest) +
  `persona_drift_guard_test.exs` + `persona_cohort_test.exs` (drift-guard; `MailglassDemo.Personas.spec/0`
  is single source of truth — do not touch).
- `.planning/research/v1.14/DEFECT-REGISTER.md` — the milestone defect ledger to close out (per-finding
  `Status:` field; Phase 123 consumption note; D-STORYBOOK-BRAND / D-STORYBOOK-STALE-BOOT entries) +
  `STRESS-TEST-PROMPT.md` (the binding Apple-deliberate-IA persona-critic rubric — do not dilute) +
  `MILESTONE-SEED.md` (maintainer-locked method: adversarial persona critics + maintainer sign-off catch
  what gates cannot).
- `reference/demo_app` storybook backend module (`storybook.ex`) + the dev-only router mount + the
  `storybook/*.story.exs` files (foundations + 5 primitive stories) — for D-09/D-11.
- `reference/demo_app/assets/e2e/persona-screenshots.spec.js` — the persona re-shoot producer (evidence
  only; no new cells — D-07).
- `.planning/phases/118-method-audit-storybook-stand-up/118-CONTEXT.md` (D-10..D-14: gate-arming intent,
  ratchet floor inventory, re-score-is-123 lock) + `.planning/phases/122-preview-surface-redesign/122-CONTEXT.md`
  (D-STORYBOOK-BRAND / D-STORYBOOK-STALE-BOOT deferral to 123; TokenParity landmine).
- `brandbook/brand-book.md` — brand source of truth (newest wins over `prompts/`).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **The whole ratchet apparatus already exists** — `ratchet_baseline_test.exs` (`compare_baselines/2`
  only-forward), `ui-baseline-scores.json` (prior+current blocks), `axe_baseline_test.exs`,
  `bucket_a_coverage_test.exs`, the persona drift-guard. Phase 123 promotes+re-scores; it builds nothing new.
- **The two judgment gates already run green in CI** — `judgment.spec.js` is live `test(`, globbed by
  `testDir:"./e2e"`, executed in the required `operator_browser_gate` lane. Arming = de-disclaim + document.
- **The persona-critic harness is rerunnable** — agent-orchestrated Playwright against `make demo` (118
  D-01), screenshots to a gitignored cache; the producer + persona-screenshots spec already exist.
- **Storybook is stood up** (118) — backend titled `mailglass admin`, sandbox styled via `css_path`,
  foundations + 5 primitive stories; gallery retained alongside.

### Established Patterns
- Re-score is only-forward, meet-or-beat, under distinct run-ids — promotion = copy current→prior, fresh
  current under a new run_id (anti-vacuity guard enforces the run_id change).
- Committed `priv/static/app.css` is canonical; a fresh `mix assets.build` trips TokenParityTest +
  `verify.preview` — never blindly rebuild+commit (120/121/122 landmine).
- Coherence/taste is a maintainer-judgment property the floor cannot express — the method's answer is the
  adversarial persona-critic + maintainer sign-off, recorded in the DEFECT-REGISTER ledger.
- Pitfall-2 green-only-forward: any grepped copy/comment string change is paired with its test update in
  the same phase.

### Integration Points
- `ui-baseline-scores.json` ← LLM re-score → `ratchet_baseline_test.exs` (only-forward gate).
- `judgment.spec.js` disclaimer comments + the floor gate-count doc (MILESTONE-SEED / DEFECT-REGISTER /
  `gate-self-test.yml` registry) — the arming seam.
- persona-critic harness re-run → `DEFECT-REGISTER.md` Status closures + maintainer sign-off — the COH-01
  evidence seam.
- storybook backend/config + run-the-demo DX docs — D-09/D-10/D-11 finalization seam.
</code_context>

<specifics>
## Specific Ideas

- **Apple-like, deliberate IA** is the bar coherence is judged against — frame the persona-critic re-run
  verdict against that, not just WCAG nits (118 specifics carried forward).
- The five adversarial hats (dev-evaluator, library-integrator, maintainer-debugging,
  operator/on-call-SRE-under-stress, security-reviewer) and three personas (northstar, fjordline-aps,
  helios-void) are fixed vocabulary — use them verbatim in the coherence sign-off so it is traceable.
- Phase 124 (release cut) consumes this phase's green floor + closed DEFECT-REGISTER as the
  COH-01/COH-02-satisfied evidence — produce an auditable trail, not a "looks coherent" claim.
</specifics>

<deferred>
## Deferred Ideas

- **Consolidating `/dev/mail/gallery` into `phoenix_storybook`** (migrate ratchet testids) — deferred per
  REQUIREMENTS "Future Requirements"; only if the two surfaces prove redundant. Both kept in v1.14.
- **Theming the phoenix_storybook explorer chrome off the default indigo** — rejected for v1.14 (D-09):
  would require editing the dep CSS or a Node build, both banned. Accepted as dev-only cosmetic.
- **Adding `overview`/shell as a 4th ratchet-baseline surface** — rejected (D-02): the 54-cell baseline is
  fixed to the 3 record-surfaces; overview coherence rides on COH-01 + structural/judgment gates.
- **The linked-version Hex release, D-13 inbound re-pin, consumer + post-publish smoke, milestone
  audit/archive** — Phase 124, not 123.

### Reviewed Todos (not folded)
None — `todo.match-phase 123` returned 0 matches.
</deferred>
