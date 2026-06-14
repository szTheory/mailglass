# Phase 97: Cross-Surface Component Layer - Context

**Gathered:** 2026-06-14 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Level-1 uplift of the **SHARED** admin components (`components.ex`: icon, logo, flash, badge,
status_badge; `operator/shell.ex`: shell, orientation_strip, nav_link, nav_pill, theme_toggle,
tenant_chip; shared modal + timeline patterns) so each is on-brand in light + dark across
color/type/spacing/radius/shadow and renders the full locked interaction-state matrix — PLUS
standing up the dev-only component gallery LiveView (`/dev/mail/gallery`, dev `live_session`
only, never `/ops`, no DB) as the exhaustive audit + visual-regression capture surface.
UI-SPEC before, UI-REVIEW after.

**In scope:** COMP-01, COMP-02, COMP-03, GALLERY-01, GALLERY-02.

**Out of scope (later phases):** per-surface group/page/IA/responsive/flow uplift of Operator
(98), Inbound (99), Preview (100); global microcopy pass (101); global motion pass (102).
This phase implements the *components*; the surfaces that compose them are uplifted downstream.
This phase does NOT re-decide any design choice already locked in
`.planning/research/v1.11/SUMMARY.md` (69 LD decisions) — it implements them.
</domain>

<decisions>
## Implementation Decisions

### Gallery LiveView Architecture

- **D-01:** Ship a new `MailglassAdmin.GalleryLive` (`:index` action). Mount it by adding ONE
  line — `live "/gallery", MailglassAdmin.GalleryLive, :index` — INSIDE the existing dev
  preview `live_session :mailglass_admin_preview` block in the `mailglass_admin_routes/2`
  macro body (`router.ex:219-225`), so the route resolves to `/dev/mail/gallery` and inherits
  the adopter's `if dev_routes` wrapping (`router.ex:66-71`) for dev-only enforcement for free.
  Do NOT give the gallery its own `live_session` or scope; do NOT mount it in the operator
  session (auth-gated, `/ops` — forbidden by GALLERY-01). Add `MailglassAdmin.GalleryLive` to
  the `@compile {:no_warn_undefined, ...}` list (`router.ex:87-95`) to stay warnings-clean.
- **D-02:** The gallery enumerates an **in-code specimen list** — a module attribute / function
  returning `[{component, state_label, assigns}]` tuples derived directly from the STATE-LD
  matrix in SUMMARY.md. **No DB access, no mailable scan.** It must NOT touch
  `__preview_session__`'s `mailables` assign.
- **D-03:** Render **both themes side-by-side** on one page: wrap each specimen cell in twin
  `data-theme="mailglass-light"` / `data-theme="mailglass-dark"` containers (the established
  theming mechanism — `shell.ex:119`, `preview_live.ex:225`). NOT a theme toggle — side-by-side
  so a single PNG capture covers both themes per cell and the ratchet's per-cell `data-theme`
  scoping holds.
- **D-04:** `data-testid` scheme = `gallery-{component}-{state}` (e.g. `gallery-status_badge-delivered`,
  `gallery-nav_link-active`, `gallery-flash-error`). Theme is carried by the wrapping
  `[data-theme]` ancestor, NOT baked into the testid — one stable testid per cell, queried
  under either theme. Specimens must cover every state/atom the STATE-LD rows enumerate (e.g.
  STATE-LD-05's 22 status atoms; STATE-LD-07/15 "show both states"; STATE-LD-18 "all three states").

### Component Uplift, CSS Bundle & Hero Icons

- **D-05:** Uplift the shared components **in place** per the cited STATE-LD / DARK-LD / MOTION-LD
  decisions in SUMMARY.md — no new component modules. Notably: add the missing
  `focus-visible:ring-2 focus-visible:ring-primary` rings on nav_link/nav_pill (STATE-LD-06,
  currently absent at `shell.ex:206-213,230-237`) and resolve the theme_toggle `btn-sm`/`min-h-11`
  tension (STATE-LD-08, `shell.ex:266`). Focus rings use the semantic `ring-primary` token
  (dark resolution per DARK-LD-03) — never arbitrary values (the accent-allowlist structural
  assertion would flag them).
- **D-06:** After component edits, **rebuild and COMMIT `priv/static/app.css`** via the project
  asset build, gated by `cmd git diff --exit-code priv/static/` in `verify.preview`
  (`mix.exs:183-188`). An uncommitted bundle reds CI.
- **D-07:** **No new hero icon is required** — specimens reuse glyphs already embedded for these
  components (`status_icon/1` set at `components.ex:232-255`, shell icons). IF a specimen would
  surface a previously-unembedded `hero-*`, it renders invisible with NO compile/test failure
  (heroicons-inline plugin limitation) — so any such glyph must be embedded in
  `heroicons-inline.js` + bundle rebuilt as part of the same change. Prefer reusing existing glyphs.

### UI-SPEC / UI-REVIEW Gate & Ratchet Integration

- **D-08:** Generate the **UI-SPEC before** planning/implementation and run **UI-REVIEW after**
  (roadmap "UI hint: yes"). The UI-SPEC consumes SUMMARY.md LD-IDs as its design contract.
- **D-09:** Un-skip the reserved gallery block in `e2e/structural.spec.js:421-428` — replace
  `test.describe.skip` with real `getByTestId("gallery-{component}-{state}")` visibility/accent
  assertions, reached via a new no-auth `openGallery(page)` helper (mirroring `openPreview`'s
  no-login path, `structural.spec.js:38-42`). Flip **GAP-05 → fixed** in
  `RATCHET-GAP-REGISTER.md:138`.
- **D-10:** The gallery is the **visual-audit capture surface** for the EXISTING frozen 36-cell
  LLM-score baseline (3 surfaces × 6 pillars × 2 themes, `ratchet_baseline_test.exs:26-28,51-63`).
  Do NOT add a "gallery" entry to `@surfaces` / `ui-baseline-scores.json` — that breaks the
  36-cell assertion and Phase 103's only-forward `compare_baselines/2` hook. Gallery cells feed
  structural assertions (GALLERY-02), not new LLM-score baseline keys.

### Claude's Discretion

- Exact `GalleryLive` module file location under `mailglass_admin/lib/mailglass_admin/` (e.g.
  `gallery/gallery_live.ex` vs `gallery_live.ex`) and the internal shape of the specimen-list
  data structure — pick the idiom most consistent with existing LiveView modules.
- Page layout/grouping of specimens within the gallery (grouping by component, then state),
  provided every component × state × theme cell is present with its `data-testid`.

### Folded Todos

None folded into this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/v1.11/SUMMARY.md` — **PRIMARY.** The canonical locked research read: 69
  LD decisions (MOTION-LD, IA-LD, STATE-LD, DARK-LD, COPY-LD). Phase 97 cites LD-IDs from here;
  it never re-reads the dossier bodies. STATE-LD-01..22 and DARK-LD-01..08 define every shared
  component's state matrix + dark resolution; MOTION-LD-01..14 the motion spec.
- `.planning/phases/96-research-dossier/96-CONTEXT.md` — D-01..D-10 governing the dossier.
- `.planning/RATCHET-GAP-REGISTER.md` — GAP-05 (gallery route gap) is closed by this phase;
  flip to `fixed`.
- `.planning/STATE.md` — v1.11 "Hard design constraints" + "Scope Locks" blocks (binding).
- `mailglass_admin/docs/design-system.md` — motion vocabulary + per-component checklist.
- `brandbook/tokens.css` (token source of truth), `brandbook/brand-book.md` (voice/visual).
- `mailglass_admin/lib/mailglass_admin/router.ex` — preview `live_session` mount point (D-01).
- `mailglass_admin/lib/mailglass_admin/components.ex`, `operator/shell.ex` — shared components.
- `mailglass_admin/e2e/structural.spec.js`, `test/.../ratchet_baseline_test.exs` — ratchet layers.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **Shared components:** `components.ex` (icon, logo, flash, badge, status_badge incl.
  `status_icon/1` glyph set at lines 232-255) and `operator/shell.ex` (shell, orientation_strip,
  nav_link/nav_pill, theme_toggle, tenant_chip).
- **Dev preview `live_session`:** `:mailglass_admin_preview` in `router.ex:219-225` — the only
  non-auth-gated session; declares `live "/", PreviewLive, :index` and
  `live "/:mailable/:scenario", PreviewLive, :show`. `/gallery` (one segment) does not collide
  with `/:mailable/:scenario` (two segments).
- **No-auth e2e helper precedent:** `openPreview(page)` (`structural.spec.js:38-42`) — the
  pattern for the new `openGallery(page)` helper.
- **Theme mechanism:** `data-theme="mailglass-light|dark"` on a wrapper (`shell.ex:119`,
  `preview_live.ex:225`).

### Established Patterns

- **Bundle-clean gate:** `verify.preview` runs `cmd git diff --exit-code priv/static/`
  (`mix.exs:183-188`); rebuilt `app.css` must be committed.
- **Heroicons-inline plugin:** new `hero-*` glyphs need embedding in `heroicons-inline.js` +
  bundle rebuild, else they render invisibly with no test failure.
- **Structural ratchet:** `data-testid` + Playwright `getByTestId` assertions; existing testids
  are kebab `{surface}-{component}` (`structural.spec.js:29,41`; `shell.ex:320`).
- **Frozen LLM-score baseline:** 36 cells (3×6×2) hardcoded in `ratchet_baseline_test.exs:26-28`;
  Phase 103 only-forward `compare_baselines/2`.

### Integration Points

- Router macro body (`mailglass_admin_routes/2`, preview `live_session`) — gallery route + the
  `@compile {:no_warn_undefined, ...}` list.
- `e2e/structural.spec.js:421-428` reserved gallery block — un-skip here.
- `RATCHET-GAP-REGISTER.md:138` — GAP-05 flip.
</code_context>

<specifics>
## Specific Ideas

- Both themes side-by-side per cell (twin `data-theme` wrappers), not a toggle — so one PNG
  capture covers both themes and the ratchet anchors per `data-theme` ancestor.
- `data-testid` = `gallery-{component}-{state}`; theme on the ancestor, not in the testid.
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope.

### Reviewed Todos (not folded)

- **`2026-06-13-refresh-outbound-admin-ui-look-and-feel.md`** (match 0.9) — the outbound /
  operator surface refresh is **Phase 98 (Operator / Deliveries Surface)** scope, not the
  shared-component layer. Already folded at the v1.11 milestone level (milestone intent is the
  sanctioned realization of this todo, broadened to all three surfaces). Not folded into 97.
</deferred>
