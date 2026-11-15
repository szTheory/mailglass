# Requirements: mailglass v2.11 Brand v2.0 Adoption

**Defined:** 2026-11-13
**Core Value:** Email you can see, audit, and trust before it ships.
**Scope source:** `.planning/research/brand-v2-adoption/MILESTONE-PROPOSAL.md` (owner-approved 2026-11-13)
**Stop line:** No new data capture or backend features. Cap: 5 phases, 20 plans or fewer, one open PR at a time.

## v1 Requirements

### Policy and Pin (BRPOL)

- [x] **BRPOL-01**: A compatibility policy file lists every name that stays (`Mailglass.Operator.*`, `mailglass_operator_routes`, `:operator_access`, `tenant_id`, `:orphan_backlog`, telemetry names, `Delivery.status` enum) and states that on-screen and docs words are glossed, not renamed.
- [x] **BRPOL-02**: A pure, unit-tested status map classifies all 26 status/event atoms as Sent, Delivered, Delayed, Failed, Not sent, or "not a delivery status"; the open question of whether "Not sent" is ever a persisted `Delivery.status :suppressed` row is answered from code and recorded.
- [x] **BRPOL-03**: `MailglassAdmin.Copy` holds the status-label and renamed-word map, and a copy contract test fails when a screen string drifts from it.
- [x] **BRPOL-04**: The brand book is pinned by zip sha256 (`ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b`) with a tamper test; the full book stays out of the repo and only shipped assets are copied in.
- [x] **BRPOL-05**: Trademark, image and register search results for the name and mark are recorded in the repo.

### Pipeline and Catalog (BRPIPE)

- [x] **BRPIPE-01**: The admin bundle is reproducible from a committed generator, with a `--check` drift gate that a required CI lane actually runs.
- [x] **BRPIPE-02**: The theme attribute is owned by `<html>` only, and the nested `data-theme` shadowing defect is fixed.
- [x] **BRPIPE-03**: A catalog of current admin screens on realistic fixtures (Northstar, Fjordline, Helios plus the delivery cases from the UX lens) is captured as before-screenshots at unique paths, before any token swap.

### Tokens, Fonts, Logo (BRTOK)

- [ ] **BRTOK-01**: Brand v2 tokens and an explicit role map for all 36 admin theme slots (solid, on-solid, sunken, input border and the rest) are adopted for light and dark.
- [ ] **BRTOK-02**: A static contrast test checks every declared foreground/background pair per theme against the book's ratios, with no new dependency.
- [ ] **BRTOK-03**: The seven woff2 font files (about 52 KB, no CDN) ship with OFL texts in `priv/static/fonts`, with `@external_resource`, `@allowed_fonts` and the weight-600 mapping for Funnel Display.
- [ ] **BRTOK-04**: The logo and favicon files replace the current ones, and the `←` glyph is replaced.
- [ ] **BRTOK-05**: `brand_test`, `token_parity_test` and `accessibility_test` are updated, and the axe baseline is regenerated once, last.
- [ ] **BRTOK-06**: Core email defaults (`config.ex`, `theme.ex`, button colors, VML goldens) are unchanged, proven by existing tests passing without edits.

### Admin Words and Layout (BRADM)

- [ ] **BRADM-01**: An operator can search by email, find the delivery under Needs attention, and read a timeline with a verdict, "sent is not delivered", and a next step, through the real LiveView in light, dark and 375px.
- [ ] **BRADM-02**: Every time shown in the admin states its zone, and every status is a pane mark plus a word.
- [ ] **BRADM-03**: The Deliveries screen is labeled "Activity" in screen text only, with `deliveries_path` unchanged.
- [ ] **BRADM-04**: "Admin" replaces "Operator" and "Account" replaces "Tenant" in on-screen copy; modules and public names stay.
- [ ] **BRADM-05**: The orphan-events count reads "N provider reports match no email", and the mailer shows its plain name with an accessible tooltip.
- [ ] **BRADM-06**: Cause sentences appear only where `reject_reason` or the suppression reason exists, with a fixed honest fallback otherwise; "next try at…", "will retry", and cause text with a nil reason are never rendered, enforced by a contract test.
- [ ] **BRADM-07**: A separate agent reviews each scenario against the book with a rejection gate, and evidence is stored at unique paths with the served SHA recorded after a server restart.

### Docs, Packaging, Launch Prep (BRDOC)

- [ ] **BRDOC-01**: The README header uses `<picture>` with absolute `raw.githubusercontent.com` URLs pinned to a tag, so it renders on hex.pm.
- [ ] **BRDOC-02**: ExDoc CSS (code colors only, no OS dark-media query) and the "m" logo are set in all three `mix.exs`, verified by a real `mix docs` build per package.
- [ ] **BRDOC-03**: `design-system.md` and the `.impeccable` config exist, and CLAUDE.md/PRODUCT.md updates are drafted for owner sign-off.
- [ ] **BRDOC-04**: A lowercase-name lint passes, the Hex file allowlist is updated, and `mix mailglass.publish.check` passes.
- [ ] **BRDOC-05**: Favicon legibility is checked at 16, 24 and 32 px in three browsers, and a social card/avatar manual-upload checklist is written.
- [ ] **BRDOC-06**: The announcement and any ™ claim are gated on the BRPOL-05 result; code rollout is not gated.

## v2 Requirements (deferred to a later "insight" milestone)

- **INSIGHT-01**: Next-retry time shown on a delivery (needs retry-schedule data capture).
- **INSIGHT-02**: Provider reason text shown on a delivery (needs reason capture beyond `reject_reason`).
- **INSIGHT-03**: Per-mailer rollups.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Renaming `Operator`, `tenant_id`, telemetry names, `Delivery.status` | Public contract; gloss on screen only |
| Core email default colors, `theme.ex`, VML goldens | Host-owned emails and a public API |
| ExDoc font swap | ExDoc stays Lato; only code colors change |
| New backend data capture | Stop line; filed as INSIGHT-01..03 |
| Full brand book in the repo | Pinned by hash; only shipped assets copied |
| ™ claim or announcement before search result | Irreversible claims wait on BRPOL-05 |
| Delivery-absence signal (SEED-008), Storybook depth (SEED-009) | Next milestones per ROLLING-ROADMAP |

## Traceability

Updated during roadmap creation (2026-11-13).

| Requirement | Phase | Status |
|-------------|-------|--------|
| BRPOL-01 | Phase 179 | Complete |
| BRPOL-02 | Phase 179 | Complete |
| BRPOL-03 | Phase 179 | Complete |
| BRPOL-04 | Phase 179 | Complete |
| BRPOL-05 | Phase 179 | Complete |
| BRPIPE-01 | Phase 180 | Complete |
| BRPIPE-02 | Phase 180 | Complete |
| BRPIPE-03 | Phase 180 | Complete |
| BRTOK-01 | Phase 181 | Pending |
| BRTOK-02 | Phase 181 | Pending |
| BRTOK-03 | Phase 181 | Pending |
| BRTOK-04 | Phase 181 | Pending |
| BRTOK-05 | Phase 181 | Pending |
| BRTOK-06 | Phase 181 | Pending |
| BRADM-01 | Phase 182 | Pending |
| BRADM-02 | Phase 182 | Pending |
| BRADM-03 | Phase 182 | Pending |
| BRADM-04 | Phase 182 | Pending |
| BRADM-05 | Phase 182 | Pending |
| BRADM-06 | Phase 182 | Pending |
| BRADM-07 | Phase 182 | Pending |
| BRDOC-01 | Phase 183 | Pending |
| BRDOC-02 | Phase 183 | Pending |
| BRDOC-03 | Phase 183 | Pending |
| BRDOC-04 | Phase 183 | Pending |
| BRDOC-05 | Phase 183 | Pending |
| BRDOC-06 | Phase 183 | Pending |

**Coverage:**
- v1 requirements: 27 total
- Mapped to phases: 27
- Unmapped: 0

**Per phase:** Phase 179: 5 (BRPOL-01..05) · Phase 180: 3 (BRPIPE-01..03) · Phase 181: 6 (BRTOK-01..06) · Phase 182: 7 (BRADM-01..07) · Phase 183: 6 (BRDOC-01..06)

---
*Requirements defined: 2026-11-13*
*Traceability mapped: 2026-11-13 (roadmap v2.11, Phases 179-183)*
