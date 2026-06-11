# Phase 77: Motion and Microinteraction Polish - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Apply the **existing** six-motion vocabulary consistently and correctly across the
three `mailglass_admin` operator surfaces, per the frozen Phase 74 UI-SPEC Motion
Assignment Matrix. Concretely: entrance animations fire exactly **once per record
selection** (not on every filter/pagination patch), all motion respects
`prefers-reduced-motion`, and no animation uses layout-thrashing properties or
exceeds 300ms.

**This is application, not authorship.** The CSS motion vocabulary (`mg-reveal`,
`motion-timeline`, `motion-tab-swap`, `motion-overlay`, `row-state`, flash) is
already built and spec-conformant in `app.css`. The phase wires two missing
id-keys and adds verification.

**Out of scope:** new motions, new CSS keyframes, brand-book amendment, new deps,
GAP-21 a11y work (already landed in Phases 75/76), any router-macro / stable-seam
change. New visual loudness is explicitly forbidden (Fork B lock).

**Anti-churn gate:** every build task cites a Phase 74 gap-register row at
severity ≥ 3 — here that is **GAP-19 (sev 3)**.
</domain>

<decisions>
## Implementation Decisions

### Motion-Reveal Re-Fire Fix (MOTION-01 / GAP-19)
- **D-01:** Add `id={"delivery-detail-#{@selected_delivery.id}"}` to the bare
  `motion-reveal` div at `operator_live.ex:442`. LiveView then replaces (not
  patches) the element on delivery-selection change, re-firing the entrance
  animation exactly once per selection. This is the literal GAP-19 fix.
- **D-02:** Apply the parallel id-key to the **identical latent twin** at
  `inbound_live.ex:341`: `id={"inbound-detail-#{@selected_record.id}"}`. Same bug,
  not named in GAP-19, but it rides the same fix and excluding it leaves the
  inbound detail reveal silently broken for Phase 79 to re-discover. Folded into
  scope under the GAP-19 citation. `@selected_record.id` is non-nil in the
  selected branch.
- **D-03:** No CSS changes for the re-fire fix. The pattern reference is the
  already-working id-keyed `motion-tab-swap` at `preview/tabs.ex:84`.

### Vocabulary Conformance & Layout-Thrashing (MOTION-02 / GAP-20, GAP-21)
- **D-04:** Treat GAP-20 (timeline stagger) and the layout-thrashing sweep as
  **verification-only** — no code changes. The thrash sweep is already clean
  (zero `transition-height/max-height/padding/all`, zero `duration-300+`, zero
  `ease-in/ease-linear/ease-in-out` in `lib/`; all durations ≤ 220ms; keyframes
  animate opacity/transform only). Timeline stagger is correctly capped at 8
  nth-child steps (`app.css:263-270`) and stops re-firing once its parent reveal
  div is id-keyed (D-01).
- **D-05:** GAP-21 a11y attributes are **out of scope — already satisfied** by
  Phases 75/76 (`aria-current` in `shell.ex`, `aria-selected` in the lists,
  `role="dialog"`+`aria-modal` in both `replay_modal.ex` files). Planning may do a
  one-line confirmation grep but must not re-build these.

### Verification & Closeout (self-verified, no human UAT)
- **D-06:** Author a **new dedicated** `scripts/check_*.sh` motion-conformance grep
  gate (modeled on the existing `scripts/check_*.sh` pattern, e.g.
  `check_credo_suppressions.sh`). It greps `lib/` + `app.css` for the banned set
  (`transition-height`, `transition-max-height`, `transition-padding`,
  `transition-all`, `duration-300`/higher, `ease-in-out`, `ease-linear`) and exits
  nonzero on any hit. Do **not** add the grep inside `ui-audit.sh` — that file is
  policy-banned from CI. This gate is reused/extended at Phase 79.
- **D-07:** Extend `e2e/operator.spec.js` with a reduced-motion test using
  `page.emulateMedia({ reducedMotion: "reduce" })` plus an **id-presence assertion**
  on `#delivery-detail-<id>` (and the inbound twin). The id regression is invisible
  to ExUnit substring tests — the heroicons-inline lesson — so it must be asserted
  at the DOM/e2e layer.
- **D-08:** Rebuild the admin asset bundle (vendored `tailwind-macos-arm64` via the
  admin assets build) and commit `priv/static/` in the **same PR** as any HEEx/CSS
  change. The `git diff --exit-code priv/static/` gate (mix.exs `verify.preview`
  alias) goes red otherwise. Note: this phase's HEEx changes (id attributes) do not
  alter Tailwind class usage, so the bundle may be a no-op rebuild — verify, don't
  assume.

### Claude's Discretion
- Exact filename/location of the new conformance grep script (D-06) and how much
  e2e coverage to add (D-07) are planner-resolvable; recommended approach is locked
  but the precise shape is left to planning.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/74-systematic-audit-and-ui-spec/74-UI-SPEC.md` — **FROZEN contract.**
  Sections: "Motion Assignment Matrix" (~line 347), "Motion Rules (non-negotiable)"
  (~line 360), "Motion-Reveal Re-Fire Fix (Phase 77 specification)" (~line 371).
  Defines the six named motions, durations, and where-to-apply / where-NOT-to-apply.
- `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md` — motion rows
  at lines 171-201 (GAP-19 sev 3 = the MOTION-01 anchor; GAP-20 sev 2; GAP-21 sev 3
  already satisfied; phase-target table at lines 200-201).
- `.planning/REQUIREMENTS.md` — MOTION-01, MOTION-02 (lines 35-36).
- `.planning/ROADMAP.md` — Phase 77 success criteria (4 criteria) and v1.7 scope locks.
- `mailglass_admin/assets/css/app.css` — built motion vocabulary (`mg-reveal` ~241-282,
  stagger cap ~263-270, `--duration-*` tokens, global `prefers-reduced-motion` block).
- `mailglass_admin/lib/mailglass_admin/preview/tabs.ex:84` — proven id-keyed motion
  pattern to mirror.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Complete motion CSS vocabulary** in `app.css` — `mg-reveal` (opacity + translateY
  6px, 220ms, ease-out), `motion-timeline` (staggered 40ms, cap 8), `motion-tab-swap`
  (crossfade 150ms), plus the global `@media (prefers-reduced-motion: reduce)` block
  and `--duration-fast`/`--duration-reveal` custom properties. All match the UI-SPEC
  matrix exactly. Nothing new to author.
- **id-keyed pattern** at `preview/tabs.ex:84` (`id={"preview-tab-" <> ...}` on
  `motion-tab-swap`) — the template for the D-01/D-02 fixes.
- **Existing `scripts/check_*.sh` shell-check pattern** — model for the new motion
  conformance gate (D-06).
- **Playwright harness** — `playwright.config.cjs` + `e2e/operator.spec.js` driving the
  reference operator browser server at `/ops/mail`; reduced-motion coverage is net-new
  and attaches via the standard `page.emulateMedia` API.
- **Bundle discipline** — `mix.exs` `verify.preview` alias runs assets build →
  `git diff --exit-code priv/static/`; vendored `tailwind-macos-arm64` binary present.

### Established Patterns
- Motion fires on element **insertion** (LiveView replace), not patch. Record-keyed
  ids are the mechanism that converts an in-place patch into a replace.
- Flash/toast reveals (`components.ex:78`, `shell.ex:287/295`) correctly use
  `motion-reveal` on appearance — these are action-triggered and do NOT need ids.
- No per-component `motion-reduce:` variants — the single global media block covers
  all six motions (UI-SPEC Motion Rules).

### Integration Points
- `operator_live.ex:442` (detail pane render), `inbound_live.ex:341` (inbound detail
  pane render) — the two sites receiving id-keys.
- `e2e/operator.spec.js` — reduced-motion + id-presence assertions.
- `scripts/` — new conformance grep gate (CI-runnable, NOT inside `ui-audit.sh`).
- `priv/static/` — committed bundle (same-PR rebuild gate).
</code_context>

<specifics>
## Specific Ideas

- Fix the inbound twin (`inbound_live.ex:341`) in the same change as the operator fix —
  do not leave it for Phase 79 to surface as a "new" gap.
- The conformance grep gate authored here is intended to be **reused at Phase 79** as
  the motion half of the conformance gates — build it to be CI-promotable from day one.
- Bundle rebuild may be a no-op (id attributes don't change Tailwind class set) — run
  the build and let `git diff --exit-code priv/static/` confirm; don't skip it.
</specifics>

<deferred>
## Deferred Ideas

- Promotion of the motion + token conformance grep gates into the full CI matrix and
  the before/after visual-regression diff — **Phase 79** (Verification and
  Visual-Regression Hardening).
- Deep-link unstyled-CSS bug — out of this phase entirely; carries its own
  in-scope/deferred decision tracked for Phase 79.

### Reviewed Todos (not folded)
None — `todo.match-phase` returned zero matches for Phase 77.
</deferred>
