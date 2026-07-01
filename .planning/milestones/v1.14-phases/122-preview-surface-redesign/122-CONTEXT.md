# Phase 122: Preview surface redesign - Context

**Gathered:** 2026-06-28 (assumptions mode + 3-area research synthesis)
**Status:** Ready for planning

<domain>
## Phase Boundary

Redesign the **Preview** admin surface (`/dev/mail`, `MailglassAdmin.PreviewLive`) consistent with
the established cross-surface patterns from Phases 119 (app-shell/nav/overview), 120 (Deliveries),
121 (Inbound) — streamlined, non-info-dump, least-surprise IA; spacing/hierarchy/microcopy/motion
coherence — **while keeping the previewed email's own independent dark/light toggle distinct from
the admin chrome theme.** Preview is surface **#4 of 4 (last)** in the v1.14 biggest-impact-first
order (119 → 120 → 121 → **122**). Requirements: PREV-01.

**The central scoping truth: Preview is the CLEANEST of the four surfaces going in.** Its
orientation strip is **already empty-pane-only** (`preview_live.ex:362`, the sole `orientation_strip`
call, inside the `@mailables == []` branch) — the exact thing 120 D-05 / 121 D-04 had to *fix* on
Deliveries/Inbound. The DEFECT-REGISTER records Preview as "no net-new headline defect — 122 applies
established cleanup" (`.planning/research/v1.14/DEFECT-REGISTER.md:289,305`). **This phase is an
alignment-and-polish pass, NOT a structural rebuild.**

**Preview is a structurally DIFFERENT beast from the operator surfaces.** It is a **dev-only
email-preview explorer**: a sidebar of zero-config auto-discovered **Mailables** → scenarios, a main
pane with a logo+"PREVIEW" eyebrow header + a device-width frame + two theme toggles + tabs
(HTML/Text/Raw/Headers) + a type-inferred assigns/props form. It has **no records table, no filters,
no tenant scope, no replay, no PII, no pagination**. Therefore the Deliveries/Inbound
"no-data-vs-no-match filter split, withhold-filters-on-empty, `data_state` loading/permission/stale
primitive, replay-modal, PII-reveal" decisions **DO NOT port** — those machineries have nothing to
act on here. Cross-surface coherence is achieved through **shared chrome vocabulary** (spacing scale,
eyebrow+logo pattern, motion tokens, brand voice, empty-pane-only orientation, single-h1 hierarchy)
— **not shared structure**. Cross-tool convergence (Storybook tree+canvas+args, react-email
zero-config discovery + sidebar + mobile preview, Mailpit HTML/text/headers/raw tabs) validates that
Preview's existing explorer structure is correct; 122 only makes its voice and tokens match the
now-cleaned operator surfaces.

**In scope (PREV-01 + cross-cutting matrix):** the `preview_live.ex` render header + the two theme
toggles (`:302-360`), the empty-mailables onboarding pane (`:361-402`), the render-error card
(`:284-301`), the `preview/sidebar.ex` dead-attr removal, heading/spacing-token normalization vs the
operator shell, brandbook-canonical microcopy, the paired Playwright/ExUnit/`voice_test.exs` updates,
and the persona re-shoot. Full matrix applies: 320→wide responsive, light/dark/system admin chrome at
parity, happy/empty/error/start/boundary states, WCAG 2.2 AA + APG (keyboard-complete,
visible/restored focus, never color-alone, 44×44, labeled controls), Emil-Kowalski-grade motion on
**existing** tokens (`motion-reveal`/`motion-tab-swap`, no new keyframes — within v1.13 MOTION locks),
on-brand recovery-oriented microcopy.

**Out of scope (later phases / locked):** Cross-surface coherence finalization + arming the new
judgment gates (nav-active-correctness, no-nav-duplication) into the permanent ratchet floor + the
54-cell pillar re-score (**Phase 123** — this phase HOLDS the inherited floor green only-forward; it
does NOT re-score). The optional `phoenix_storybook` explorer-chrome brand-token pass (D-STORYBOOK-BRAND
— Phase 123). No new product capability, providers, transports, or routes (D-23). No `data_state`
import (the states cannot fire here — see D-08). No new orientation/motion copy or keyframes (119
D-10/D-11 / v1.13 MOTION locks). No adopter no-Node *shipped* asset-pipeline change. Recipient-facing
email HEEx + `brandbook/` tokens are OUT (the brand book is the source of truth). The iframe
nonce/`phx-update="ignore"` re-render mechanism, the render-pipeline reuse (PREV-03), and the
device-frame/tabs/assigns-form internals are correct — do not disturb beyond the polish below.
</domain>

<decisions>
## Implementation Decisions

### Scope — light alignment-and-polish; NOT a structural port of operator machinery
- **D-01:** **Treat Phase 122 as an alignment-and-polish pass, not a rebuild.** Preview's four-branch
  render `cond` (`preview_live.ex:283-440`: render-error `:284`, populated-scenario `:302`,
  empty-mailables `:361`, start `:403`) already mirrors the cleaned 120/121 shape and the orientation
  strip is already empty-pane-only (`:362`). The work is: dual-theme toggle a11y (D-02..D-04), a TIGHT
  IA/DX polish list (D-05..D-07), state-coverage confirmation (D-08), microcopy (D-09..D-10), and the
  paired-test/persona/asset gates (D-11..D-13). **Do NOT** import the Deliveries/Inbound
  no-data/no-match split, filters-gating, `data_state` primitive, replay modal, or PII machinery —
  Preview has no records/filters/tenant-scope/async/auth for them to act on, so they would ship as
  dead, unreachable UI (the opposite of the "withhold controls that can't act" discipline).

### Dual-theme toggle UX + accessibility (the surface's distinctive control — the highest-judgment area)
- **D-02:** **Adopt the canonical `Components.theme_picker` for the admin-chrome theme; stop
  reinventing it per-surface.** The other three surfaces render
  `<Components.theme_picker selected={…} event="set_theme" />` via the operator shell (`shell.ex:282`);
  it is a native-radio `<fieldset>` + `<legend class="sr-only">Theme</legend>`, 44×44 segments,
  `mg-focus-ring-within`, **tri-state light/dark/system** — exactly Preview's real chrome state space.
  Preview today hand-rolls a **binary** sun/moon ghost button (`preview_live.ex:310-328`) that silently
  drops `:system` and diverges from the other surfaces. Replace it with `theme_picker`. This also makes
  the two theme controls **structurally distinct shapes** (a segmented 3-way picker vs a single button),
  which is the least-surprise way to keep "App theme" and "Email backdrop" from being confused —
  WCAG 1.4.1 satisfied by form-factor, not icon+word alone (the Storybook two-independent-controls
  lesson: separately-labeled named controls, never two duplicate icon buttons).
- **D-03:** **Keep the email-backdrop control as a single binary button, but make it a correct toggle.**
  `preview_frame_dark_chrome` is genuinely binary (the email backdrop has no "system"). Keep the
  `<button>` with `phx-click="toggle_preview_frame_theme"` and `data-testid="preview-frame-theme-toggle"`
  **verbatim** (the `flows.spec.js:454-458` invariant), and add **`aria-pressed={@preview_frame_dark_chrome}`**
  for the missing state semantic. Pair the moon/sun icon with an always-visible **"Email backdrop"**
  text label (never icon/color-alone), keep the state-dependent `aria-label` ("Switch the email backdrop
  to dark/light"), `min-h-11`, `mg-focus-ring`. Precede the admin `theme_picker` with a small visible
  group caption **"App theme"** so the relationship of each control to what it governs is explicit.
- **D-04:** **Announce the remote-pane change via an `aria-live="polite" role="status" sr-only` region**
  (the 121 D-11 precedent). The backdrop toggle changes a visual region the user is NOT focused on, so
  `aria-pressed` alone (the button's own state) is insufficient — announce "Email backdrop: dark" /
  "Email backdrop: light" on toggle. Never the backdrop color alone (WCAG 1.4.1). No new keyframes;
  reuse existing focus-ring/motion tokens.

### THE LOAD-BEARING INVARIANT — the two-theme independence carry-through must not break (hard guardrail)
- **D-05:** **Preserve the `return_to` + `?frame=dark` carry-through exactly.** `admin_chrome_theme`
  persists via a **full controller redirect** through `/theme/<t>` that remounts the LiveView and would
  drop the in-memory `preview_frame_dark_chrome` — so the live frame boolean is smuggled through
  `return_to` as `frame=dark` (`preview_live.ex:589-638`: `preview_theme_path` → `put_frame_query` →
  restored by `frame_from_params` on remount). **When `theme_picker` adopts the `set_theme` event, its
  redirect MUST route through Preview's existing `preview_theme_path/2` (which calls `put_frame_query`),
  NOT the operator shell's `set_theme_path/2` (`shell.ex:102`), which has NO frame handling and would
  silently reset the email backdrop on every chrome-theme flip.** `flows.spec.js:454-458` locks this
  end-to-end (frame→dark flips `preview-pane` `data-preview-frame-theme="dark"` while `preview-shell`
  stays `data-theme="mailglass-light"`); it must stay green and must not be weakened. This is the single
  highest-risk item in the phase — call it out in the plan.

### IA / DX polish — TIGHT in-scope list (everything else is leave-alone)
- **D-06:** **Remove the dead `dark_chrome` attr from `preview/sidebar.ex`.** Declared at `:30` and `:72`,
  threaded through `sidebar/1` → `mailable_entry/1` (`:56`), but **never read** in any of the three
  `mailable_entry` clauses (`:78-125`) or `mailable_label/1`; `preview_live.ex` never even passes it
  (the mount passes `mailables`/`current_mailable`/`current_scenario`/`device_width`/`admin_chrome_theme`/
  `mount_path` only, `:258-280`). Confirmed dead — delete both declarations and the pass-throughs so a
  future maintainer can't wire it and collide with the real `admin_chrome_theme`/`preview_frame_dark_chrome`
  split.
- **D-07:** **Normalize heading-hierarchy + shell-chrome spacing tokens to the operator surfaces, and
  apply noun discipline — without adopting operator structure.** Preview already shares the operator's
  spacing scale (`px-md py-lg …`), the logo+eyebrow pattern (logo + "PREVIEW" eyebrow, `:248-251`),
  single-`h1` hierarchy (each `cond` arm has exactly one `h1`), and `motion-reveal`/`motion-tab-swap`
  on existing tokens — so this is normalization, not redesign: verify the eyebrow/header border + padding
  tokens match the operator shell exactly and fix any drift. Apply brandbook noun discipline (**Mailable**
  is the locked domain noun, `brand-book.md:69`): keep the sidebar collection heading "Mailables" (plural
  collection label is fine), and reconcile running prose toward the brandbook copy-table strings (D-09).
  **Do NOT** adopt the operator left-rail nav — Preview's sidebar-of-Mailables IS its content navigation,
  a different job (cf. Storybook component tree / react-email file tree). Leave the tabs strip, device-frame
  segmented control, and assigns form as-is (already APG-correct, already controls-above-canvas; match
  Mailpit/react-email/Storybook conventions).

### State coverage — confirm the four reachable states; do NOT import `data_state`
- **D-08:** **No new state UI; the four-branch `cond` covers every reachable state.** Preview renders
  **synchronously** (`rerender/1` calls `Mailglass.Renderer.render/1` in-process inside
  handle_params/handle_event, struct-matched `TemplateError` + rescue, `:720-748`) and is **dev-only with
  no tenant auth** — so `data_state`'s `:loading` (no async round-trip / no `spinner-for` seam),
  `:permission_denied` (no `Auth.authorize` on `/dev/mail`), and `:stale` (nothing polls/caches) **cannot
  fire**. Importing `Components.data_state` would ship three branches that never render. Confirmed
  state inventory: render-error (`:284`, incl. invalid assigns-form input which folds back through
  `rerender/1`, and `preview_props` raising → `:__error__` route `:120-132`), empty-mailables onboarding
  (`:361`), start/none-selected (`:403`), populated-happy (`:302`), discovery-time mailable failure
  (sidebar warning badge `sidebar.ex:113-125`, icon + `sr-only` text — correct non-color-alone cue),
  disconnected/reconnect (handled globally by LiveView `phx-disconnected`, not Preview-specific). Each
  has a correct home; the only work is microcopy (D-09/D-10) + focus/announce on transitions (D-08a).
- **D-08a:** **Focus / announce on the error transition.** When a template raises and the error card
  appears, move focus to it (or announce via `role="status"`/`aria-live="polite"`) so the developer
  isn't left re-scanning — mirror the D-04 live-region pattern. Apply `motion-reveal` (existing token) to
  error-card and onboarding-pane entry; honor the existing reduced-motion neutralizer; no new keyframes.

### Microcopy — adopt brandbook canonical strings; keep the dev-inline error affordance
- **D-09:** **Onboarding (empty-mailables `:361-402`) — adopt the brandbook canonical empty-state line and
  surface the generator as the PRIMARY next step.** Brandbook locks (`brandbook/copy/microcopy.md`,
  Mailable/Empty): **"No mailables discovered yet. Define one with `mix mailglass.gen.mailable` and it
  will appear here, ready to preview."** Use it as the headline + lead (the highest-DX-leverage first-run
  moment — a great dev empty state names the exact next action, per Storybook "no stories" / Vite-overlay
  convention). **Demote** the current module-marker troubleshooting (the `use Mailglass.Mailable`
  compiled-and-loaded check + the explicit `mailables:` router-list escape) to a **secondary** checklist
  — those are the recovery paths for "a Mailable exists but isn't found." Keep the "Read preview setup"
  HexDocs link. Verify the long router-snippet `<code>` block wraps/scrolls cleanly at 320px.
- **D-10:** **Error card (`:284-301`) — adapt the brandbook error VOICE but KEEP the inline exception
  `<pre>` (dev-only DX); do NOT send the developer to logs.** The brandbook recipient/operator-facing
  Error line ("…The error and stack trace are in your logs.") is wrong for a **dev preview tool** — the
  error is right there and inline display is the correct, convergent DX (Next 15.2 owner-stacks / Vite
  overlay: surface message + which component + a path to fix, inline). Generalize the too-narrow headline
  **"preview_props/0 raised an error"** → **"This Mailable raised while rendering"** (render-time template
  raises land here too, not just `preview_props/0`), name BOTH the Mailable (`inspect(@current_mailable)`)
  and the scenario (`@current_scenario`) as load-bearing debugging context, and use a recovery-oriented
  lead in the brandbook voice (e.g. "Fix it in {Mailable} and save to reload — the full error is below.").
  Keep the scrollable `<pre>` (`overflow-auto max-h-80 whitespace-pre-wrap`, contained at 320px). "Oops"
  stays banned (none present). Match the struct, never the message string (already correct, `:738-740`).

### Paired-test updates + persona re-shoot + asset/TokenParity landmine (inherit 120 D-10 / 121 D-15/D-17/D-18)
- **D-11:** **Mandatory same-phase paired-test updates (the green-only-forward / Pitfall-2 trap).** This
  phase's trap is SMALLER than 121's because the orientation strip is already empty-pane-only:
  `structural.spec.js:827-831` and `flows.spec.js:60-61,436` assert `preview-orientation` /
  `preview-empty-mailables` only on the *already-empty* `/ops/browser-preview-empty` route, so they stay
  green **as long as the strip stays in the `@mailables == []` branch — do NOT move it.** What MUST be
  updated in the same phase: (a) any copy-string assertion in `voice_test.exs` and the e2e specs that
  greps the empty-state/error microcopy changed by D-09/D-10; (b) add e2e assertions for the new toggle
  a11y — admin `theme_picker` present + tri-state, backdrop `aria-pressed` reflects state, the
  `aria-live` region announces — and re-confirm the `flows.spec.js:454-458` two-theme independence lock
  still passes against the `theme_picker` swap; (c) `assertSingleH1` coverage on the start branch if not
  already covered.
- **D-12:** **Persona re-shoot — no new cells (121 D-17 analogue).** `persona-screenshots.spec.js:70`
  already enumerates the single `preview` dev-open cell (persona-independent) across
  {northstar,fjordline-aps,helios-void} × {375,1440} × {light,dark} via `cellsFor` (`:98-109`). Re-run the
  producer in one pass — that delta IS the only-forward evidence. Adding new cells fires the persona
  drift-guard.
- **D-13:** **Asset / TokenParity landmine (120 D-13 / 121 D-18) + hold-the-floor only-forward.** This pass
  is **render-condition + copy + existing-class** edits (Deliveries/Inbound already ship the utility
  classes Preview reuses) — it should need **NO `mix assets.build`**. Only if a genuinely new utility class
  appears: rebuild, but **commit only a bundle that survives TokenParityTest** (a fresh build emits
  raw-inline daisyUI 5.5.19 theme blocks that BREAK the gate; the committed `priv/static/app.css` is
  canonical). Hold the full v1.13 ratchet floor + D-THEME-PARITY (light/dark/system) green **only-forward**
  — no pillar re-score (that is Phase 123).

### Claude's Discretion
- Exact visual placement/grouping of the "App theme" `theme_picker` + "Email backdrop" button in the
  header (stacked vs inline, caption position) — pick the least-surprise layout that keeps the two
  controls visually distinct and reads cleanly 320→wide; reuse existing spacing tokens.
- Precise wording of the recovery-oriented error lead and the onboarding secondary checklist phrasing
  within the brandbook voice (D-09/D-10) — planner's call; keep the brandbook Empty string verbatim
  (voice_test greps it) and reconcile the Error line to the dev-inline affordance.
- Exact `aria-live` region placement within the header subtree and whether the error-transition uses
  focus-move vs live-region announce (or both) — reuse existing primitives; mirror 121 D-11.

### Folded Todos
None — no pending todos matched Phase 122.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `mailglass_admin/lib/mailglass_admin/preview_live.ex` — the surface. Render `cond` `283-440`
  (render-error `284-301`, populated-scenario `302-360`, **empty-mailables w/ already-empty-pane-only
  `orientation_strip surface={:preview}` `361-402`**, start `403-439`); the two toggles
  `toggle_theme` `185-191` / `toggle_preview_frame_theme` `176-183`; the bespoke binary chrome button
  to REPLACE with `theme_picker` `310-328` + the backdrop button to harden `329-345`; **the
  load-bearing two-theme carry-through `589-638`** (`preview_theme_path` → `put_frame_query` →
  `frame_from_params`); synchronous render + struct-matched error `720-749`; `:__error__` scenario route
  `120-132`; live-reload re-discover `226-236`; `data-theme` root `245`.
- `mailglass_admin/lib/mailglass_admin/components.ex:326-360` — **the canonical `theme_picker`** to adopt
  for admin chrome (tri-state radio `<fieldset>`/`<legend sr-only>`, 44×44, `mg-focus-ring-within`,
  `event` attr).
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex:282` — how the OTHER three surfaces render
  `theme_picker` (`event="set_theme"`); `102-117` the operator `set_theme_path/2` that has **NO frame
  handling** (the trap — D-05: Preview must route through its own `preview_theme_path`, not this);
  `427-436` the byte-frozen `:preview` orientation copy (only the render condition may change — it's
  already correct).
- `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex:30,56,72` — the **dead `dark_chrome` attr**
  (declared+threaded, never read) to delete; `78-125` render paths; `113-125` the discovery-failure
  warning badge (icon + `sr-only` text — keep).
- `mailglass_admin/lib/mailglass_admin/preview/tabs.ex:98-104` — `data-preview-frame-theme` emission on
  `preview-pane` (the frame-toggle target — do not disturb); `role=tablist` a11y + `motion-tab-swap`.
- `mailglass_admin/lib/mailglass_admin/preview/` — `assigns_form.ex` (invalid input folds to render-error
  — no new state), `device_frame.ex` (segmented `aria-pressed` widths — leave), `discovery.ex` (graceful
  per-mailable failure → sidebar), `mount.ex`.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex:489-545` — the shipped 120 single-calm-pane shape
  for **spacing/hierarchy parity reference only** (do NOT port the filters/no-match/data_state machinery —
  Preview has none).
- `mailglass_admin/e2e/structural.spec.js:91-124,827-831` — preview structural + orientation assertions
  (already empty-pane-only aligned; keep green); `757-769` preview-pane theme invariants.
- `mailglass_admin/e2e/flows.spec.js:59-81,409-462` — preview happy/error/boundary/edge/advanced +
  `assertSingleH1`/overflow gates + **the two-theme independence lock `452-458`** (must stay green against
  the `theme_picker` swap — D-05).
- `mailglass_admin/test/.../voice_test.exs` — substring-greps exact microcopy; update in the SAME phase as
  any D-09/D-10 copy change (Pitfall-2 green-only-forward trap).
- `reference/demo_app/assets/e2e/persona-screenshots.spec.js:70,98-109,124-125` — the single `preview`
  dev-open cell; re-shoot no-new-cells across {northstar,fjordline-aps,helios-void}×{375,1440}×{light,dark}
  for only-forward proof (D-12).
- `.planning/phases/121-inbound-surface-redesign/121-CONTEXT.md` (D-04/D-08 empty-pane-only, D-11
  aria-live/disclosure a11y precedent, D-15 paired-test trap, D-17 persona no-new-cells, D-18 TokenParity
  landmine) + `.planning/phases/120-deliveries-surface-redesign/120-CONTEXT.md` (D-05/D-07/D-11/D-13) —
  inherited locks, do NOT re-decide.
- `.planning/research/v1.14/DEFECT-REGISTER.md` (Preview "no net-new headline defect" `289,305`;
  D-STORYBOOK-BRAND deferred to 123) + `STRESS-TEST-PROMPT.md` (the binding Apple-deliberate-IA judgment
  rubric — do not dilute).
- `brandbook/brand-book.md` (noun lock **Mailable** `:69`; thoughtful-maintainer voice; "Oops" banned) +
  `brandbook/copy/microcopy.md` (Mailable Empty/Error/Success/Warning canonical strings — adopt Empty
  verbatim, adapt Error to the dev-inline affordance per D-10). **Current brandbook is the source of
  truth — ignore any older brandbook referenced in `prompts/`.**
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Components.theme_picker` (`components.ex:326`) is the shipped, a11y-audited, tri-state
  (light/dark/system) theme control** already used by all three operator surfaces (`shell.ex:282`).
  Preview is the lone surface reinventing it as a bespoke binary button — adopt it (D-02), don't
  re-author.
- **Preview already shares the operator chrome vocabulary** — spacing scale (`px-md py-lg …`),
  logo+eyebrow pattern, single-h1 hierarchy, `motion-reveal`/`motion-tab-swap` on existing tokens,
  empty-pane-only orientation (`:362`). Coherence = close the last voice/token gaps, not restructure.
- **The two-theme carry-through (`preview_live.ex:589-638`) is correct and load-bearing** —
  `preview_theme_path`/`put_frame_query`/`frame_from_params` keep the email backdrop alive across the
  chrome-theme remount. Reuse it for the `theme_picker` adoption; do not bypass it.
- **The four-branch render `cond` covers every reachable state** — synchronous in-process render
  (`:720-748`) + dev-only-no-auth means `data_state`'s loading/permission/stale cannot fire. Verify,
  don't add.
- **Tabs (HTML/Text/Raw/Headers), device-frame segmented widths, and the type-inferred assigns form**
  are already APG-correct and match Mailpit/react-email/Storybook conventions — leave alone.

### Established Patterns
- The byte-frozen `orientation_strip` changes render *condition*, never copy (119 D-10 / 120 D-07);
  Preview's is already in the right (empty-only) condition — keep it there.
- Coherence = "one component, many surfaces": adopt the shared `theme_picker` identically rather than a
  per-surface toggle.
- Committed `priv/static/app.css` is canonical; a fresh `mix assets.build` regenerates raw-inline
  daisyUI theme blocks that trip TokenParityTest — only commit a rebuild that survives the gate (and this
  pass should need none).
- Paired-test trap (Pitfall-2): any copy/structure assertion (`voice_test.exs`, the preview e2e blocks)
  must be updated in the SAME phase as the change on a green-only-forward floor.
- "Oops" is banned; errors are specific + recovery-oriented; **Mailable** is the locked domain noun.

### Integration Points
- `preview_live.ex` header → `Components.theme_picker` (adopt for admin chrome) + the binary backdrop
  button (aria-pressed) + `aria-live` region — the dual-theme a11y seam.
- `theme_picker`'s `set_theme` event → Preview's existing `preview_theme_path/2` (NOT shell's
  `set_theme_path/2`) — the frame-carry-through guardrail (D-05).
- `preview_live.ex` → `preview/sidebar.ex` — dead `dark_chrome` attr removal seam.
- `preview_live.ex` render branches → brandbook microcopy (`microcopy.md`) — onboarding + error voice.
- redesign → `structural.spec.js` / `flows.spec.js` / `voice_test.exs` (paired updates incl. the
  two-theme independence lock) + `persona-screenshots.spec.js` (re-shoot the preview cell, no new cells).
</code_context>

<specifics>
## Specific Ideas

- **Admin chrome toggle:** adopt `Components.theme_picker selected={@admin_chrome_theme} event="…"`,
  preceded by a visible **"App theme"** caption; route its event through `preview_theme_path` (preserve
  `frame=dark`).
- **Email-backdrop toggle:** single button, `aria-pressed={@preview_frame_dark_chrome}`, visible
  **"Email backdrop"** label + state in `aria-label`, `min-h-11`, `mg-focus-ring`,
  `data-testid="preview-frame-theme-toggle"` + event verbatim.
- **`aria-live` announce:** "Email backdrop: dark" / "Email backdrop: light".
- **Onboarding (empty-mailables):** brandbook Empty string verbatim — "No mailables discovered yet.
  Define one with `mix mailglass.gen.mailable` and it will appear here, ready to preview." — generator as
  primary next step; module-marker/router-list checks demoted to secondary.
- **Error card:** headline "This Mailable raised while rendering"; name the Mailable + scenario;
  recovery-oriented brandbook-voice lead; keep the inline scrollable `<pre>` (dev-only — do NOT redirect
  to logs).
- All copy grounded in the CURRENT brandbook voice; existing correct copy kept verbatim.

### Cross-tool grounding (validates the scope)
- Storybook (tree+canvas+args; two independent toolbar controls kept as separately-labeled named
  controls), react-email (zero-config discovery + sidebar + mobile preview), Mailpit (HTML/text/headers/
  raw tabs, uncluttered chrome) all converge on exactly Preview's existing structure → honest scope is
  alignment-and-polish, not redesign. The footgun they warn against (cluttered chrome / info-dump /
  exposing backend guts) is already avoided here.
</specifics>

<deferred>
## Deferred Ideas

- **Cross-surface coherence finalization + arming the new judgment gates (nav-active-correctness,
  no-nav-duplication) into the permanent ratchet floor + the 54-cell aesthetic pillar re-score** —
  Phase 123. This phase HOLDS the inherited floor green only-forward; it does not re-score.
- **`phoenix_storybook` explorer-chrome brand-token pass (D-STORYBOOK-BRAND)** — the dev-only explorer
  header renders phoenix_storybook's default indigo, not the mailglass palette; cosmetic, dev-only,
  optional Phase 123 finalize item.
- **`/dev/storybook` stale-boot DX note (D-STORYBOOK-STALE-BOOT)** — a docs/onboarding caveat (storybook
  live-route needs a fresh `make demo` after the dep was added), not a surface-redesign item.
- **Importing `Components.data_state` into Preview** — explicitly rejected (D-08): loading/permission/stale
  cannot fire on a dev-only synchronous surface; it would be dead UI.
- **Adopting the operator left-rail nav onto Preview** — rejected (D-07): Preview's sidebar-of-Mailables IS
  its content navigation, a different job.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 122.
</deferred>
