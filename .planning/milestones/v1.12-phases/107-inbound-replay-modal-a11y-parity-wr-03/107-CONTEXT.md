# Phase 107: Inbound Replay-Modal A11y Parity (WR-03) - Context

**Gathered:** 2026-06-17 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Bring the admin **inbound** replay modal to operator-modal accessibility parity —
focus-on-open + return-focus-on-close + Escape-to-close — matching the existing
operator replay modal, with a structural Playwright assertion and a clean committed
`priv/static/` bundle. Requirement A11Y-01 (folded-in ex-v1.11 WR-03).

This is a **parity port**, not net-new work. The operator replay modal already
demonstrates the target behavior; the inbound modal must match its intent. No new
features, no changes to the inbound contract, no custom client-side JS.
</domain>

<decisions>
## Implementation Decisions

### A11y Mechanism — Pure LiveView JS Commands (No Custom JS Hook)
- **D-01:** Implement the parity using two pure Phoenix LiveView mechanisms with **no new
  `phx-hook` and no new JS asset**, mirroring the operator modal exactly:
  - **Escape-to-close:** add `phx-key="Escape"` + `phx-window-keydown="close_replay"` to the
    inbound dialog `<div>` (`mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex:27-33`),
    mirroring operator `replay_modal.ex:28-29`. The `close_replay` handler already exists on
    inbound (`inbound_live.ex:179-180`), so Escape wires to a live handler with no new event.
  - **Focus management:** add a sibling
    `<span :if={@replay_modal_open?} phx-mounted={JS.focus_first(to: "#inbound-replay-modal")} phx-remove={JS.focus(to: "#inbound-replay-open-btn")} />`
    in `inbound_live.ex` immediately before the `<ReplayModal.replay_modal .../>` call
    (~line 416), mirroring `operator_live.ex:499-503`.
- **D-02:** Keeps the no-Node/no-esbuild posture intact (`mix.exs:98` — "No :esbuild at v0.1,
  pure LiveView, no custom JS"). Reaching for a JS focus-trap hook is explicitly **rejected** —
  it would introduce the first custom JS asset in the package and inflate scope beyond a parity port.

### Focus Fix — Add a Real `id` (Fix Inbound's Target, Inbound Only)
- **D-03:** Give the inbound dialog a genuine `id="inbound-replay-modal"` and the trigger button
  a genuine `id="inbound-replay-open-btn"` (`inbound/detail_header.ex:86-94`, which currently
  carries only `data-testid`). This is required so `JS.focus_first(to: "#inbound-replay-modal")`
  and the `phx-remove` return-focus selector actually resolve.
- **D-04:** **Why this diverges from a verbatim copy:** the operator reference modal's
  `JS.focus_first(to: "#operator-replay-modal")` targets an id that does **not exist** (it is only
  a `data-testid` on the dialog div, no `id=` — `operator/replay_modal.ex:23-32`), so the
  operator focus-move is a latent no-op. The inbound port matches the operator's **intent** (focus
  must actually enter the modal), not its buggy literal — this is what the "modal traps focus"
  success criterion requires.
- **D-05:** Scope is **inbound only.** Do NOT fix the operator modal's latent id bug in this phase
  (see Deferred Ideas). This phase touches the inbound modal + inbound_live + a Playwright test only.

### Scope & Honest Framing — Focus Management Parity, Not WCAG Conformance
- **D-06:** Deliver and describe exactly: **focus-on-open + return-focus-on-close + Escape-to-close**,
  parity with the operator replay modal. Do NOT implement a true cyclic Tab focus trap (Tab wrapping
  at modal boundaries) — that requires net-new custom JS, is against the no-JS posture, and exceeds
  a parity port. The operator reference does not do it either.
- **D-07:** Honest Surface Area lens: frame the plan, test descriptions, and commit/docs copy as
  "focus management parity with the operator modal," **never** as WCAG dialog conformance or full
  focus containment. `JS.focus_first` only sets initial focus; nothing prevents Tab from leaving.

### Asset / CSS Bundle — No `priv/static` Change Expected; Rebuild-and-Diff to Confirm
- **D-08:** The change is HEEx attributes + one sibling `<span>` + two `id` attributes — no new
  Tailwind utility classes and no new `hero-*` icon — so `priv/static/app.css` should be unchanged.
  Existing `:focus-visible` focus-ring styling already exists in `app.css`
  (asserted at `e2e/structural.spec.js:804-851`); no new focus styling is needed.
- **D-09:** Run the existing Elixir `:tailwind` build alias (`mailglass_admin.assets.build`,
  `mix.exs:186`; `:tailwind` wrapper `mix.exs:99`) and confirm `git diff --exit-code priv/static/`
  stays clean. If the bundle does change, commit the regenerated bundle alongside the source
  (never hand-edit `priv/static/`; CI gates it via `git diff --exit-code`).

### Playwright Structural Assertion — New Test in `e2e/structural.spec.js`
- **D-10:** Add the structural assertion to `mailglass_admin/e2e/structural.spec.js`, inside the
  existing `"inbound state coverage, responsive grid, and contrast"` describe block (~line 483),
  using the repo's structural idiom (DOM attributes/roles/computed styles via `getByTestId`,
  `getAttribute`, `getByRole`). There is **no** existing operator-modal a11y test to mirror
  (`operator.spec.js:123-184` tests the replay outcome flow, not focus/Escape).
- **D-11:** The assertion opens the inbound modal via `getByTestId("inbound-replay-open").click()`,
  then asserts the DOM contract: `role="dialog"` / `aria-modal="true"`, the keydown attributes
  (`phx-window-keydown` === `"close_replay"`, `phx-key` === `"Escape"`), and Escape-closes behavior
  (`page.keyboard.press("Escape")` → modal hidden / count 0). Test description names the scope as
  focus management parity, not WCAG (per D-07).

### Claude's Discretion
- Exact `id` string spellings (`inbound-replay-modal` / `inbound-replay-open-btn`) provided as the
  default; adjust only if they collide with existing ids in the inbound LiveView.
- Exact placement of the new structural test within the inbound describe block.
- Whether the structural assertion also checks `phx-mounted`/focus-target presence in addition to
  the Escape attributes (nice-to-have, not required for the success criterion).

### Folded Todos
None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` — REFERENCE pattern (Escape wiring at lines 28-29; note the latent missing-`id` on the dialog div, lines 23-32)
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` (lines ~499-503) — REFERENCE focus-management `phx-mounted`/`phx-remove` span
- `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` (lines 27-33, 56) — TARGET dialog div + testids
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` (lines ~179-180 `close_replay`, ~416 modal mount) — TARGET event + mount point
- `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex` (lines 86-94) — TARGET trigger button (needs `id`)
- `mailglass_admin/e2e/structural.spec.js` (inbound describe ~line 483; focus-ring asserts 804-851) — structural-assertion idiom to extend
- `mailglass_admin/mix.exs` (lines 98-99, 186) — `:tailwind` build alias, no-Node posture
- `.planning/REQUIREMENTS.md` (A11Y-01, lines 73-76, 125) — requirement + success criteria
- `CLAUDE.md` — no-Node toolchain, `git diff --exit-code priv/static` gate, brand (no glassmorphism), heroicons-inline policy
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The operator replay modal (`operator/replay_modal.ex` + `operator_live.ex:499-503`) is the
  complete, working-in-intent reference: Escape-to-close via `phx-window-keydown`, focus via
  `phx-mounted={JS.focus_first}` / `phx-remove={JS.focus}`. Zero custom JS.
- Inbound `close_replay` handler already exists (`inbound_live.ex:179-180`) — Escape needs no new event.
- Inbound modal already exposes stable testids: `inbound-replay-modal`, `inbound-replay-open`,
  `inbound-replay-confirm` (`inbound/replay_modal.ex:28,56`, `inbound/detail_header.ex:89`).
- `:focus-visible` focus rings already in `priv/static/app.css` (no new CSS needed).

### Established Patterns
- A11y is achieved with pure LiveView JS commands — there is no `js/` dir and no `phx-hook` anywhere
  in `assets/` (only `css/app.css` + vendor). Custom JS would be a posture break.
- Structural assertions live in `e2e/structural.spec.js` and check DOM attributes/roles/computed
  styles — not pixel snapshots (brittle against the no-glassmorphism brand).
- `priv/static/app.css` is the committed bundle; CI runs `git diff --exit-code priv/static/`.

### Integration Points
- `inbound/replay_modal.ex` dialog `<div>` — add `phx-key`, `phx-window-keydown`, real `id`.
- `inbound_live.ex` — add the focus-management sibling `<span>` before the modal call.
- `inbound/detail_header.ex` — add real `id` to the trigger button for return-focus.
- `e2e/structural.spec.js` — add the structural a11y assertion in the inbound describe block.
</code_context>

<specifics>
## Specific Ideas

- Mirror the operator modal's exact attribute pattern; the only intentional divergence is adding
  real `id`s so focus actually resolves (the operator reference's latent no-op is not reproduced).
- Test description and commit copy must say "focus management parity," not "WCAG" / "focus trap
  containment."
</specifics>

<deferred>
## Deferred Ideas

- **Fix the operator modal's latent focus-first id bug** — `operator/replay_modal.ex` dialog div has
  only a `data-testid`, no `id`, so `operator_live.ex:501`'s `JS.focus_first(to: "#operator-replay-modal")`
  is a no-op. Out of scope for this inbound-parity phase (D-05). Worth a small follow-up so the
  operator modal's focus actually works and a structural assertion can cover it too.
- **True cyclic Tab focus trap (WCAG dialog containment)** — would need a custom JS hook, against the
  no-Node/no-custom-JS posture. Not this phase (D-06).

### Reviewed Todos (not folded)
None — no todos matched this phase.
</deferred>
