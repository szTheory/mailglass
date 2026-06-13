# Requirements: mailglass v1.10 — Brand Adoption

**Defined:** 2026-06-12
**Core outcome:** The A/B-winning fable brand is the project's one canonical
identity everywhere it shows — folder, README, social preview, HexDocs — with
the release pipeline hardened so brand-artifact commits can never trigger a
release again.

**Scope locks (apply to every requirement):**

- No Hex release is cut by this milestone's commits: brand/docs commits use
  non-release-triggering types (`docs:`, `chore:`, `test:`); the HexDocs
  wiring ships with the next natural release.
- The sealed-flap usage rules and constraints C-15/C-16
  (`.planning/milestones/v1.9-phases/87-logo-tournament/87-decision-record.md`)
  are binding on every propagated surface.
- Binary additions limited to the single og-card PNG export.
- Planning archives (`.planning/milestones/`) are never edited.

## v1.10 Requirements

### FOLD — Folder Adoption

- [x] **FOLD-01**: The v1.9 fable brand book becomes canonical `brandbook/`
  via `git mv`; the codex book's files are removed in the same commit
  (history preserves them at the frozen baseline `09a84dd4`).
- [ ] **FOLD-02**: Every active tracked reference to the former fable staging
  path or to the old brandbook's contents is reconciled: CLAUDE.md (lines
  referencing the brandbook and the brand source-of-truth pointer, which now
  names `brandbook/brand-book.md`) and `mailglass_admin/docs/design-system.md:5`'s
  brand pointer. The v1.9 reference sweep found no other tracked consumers.
- [x] **FOLD-03**: The v1.9 quality gate (gate.sh, re-pathed) passes on the
  folder at its new location.

### SURF — Repo Surface Propagation

- [ ] **SURF-01**: The root README adopts the brand header
  (`brandbook/examples/readme-header.svg`), rendering correctly on GitHub
  light and dark themes.
- [ ] **SURF-02**: `brandbook/examples/og-card.png` (1200×630-class export
  at 2400×1260 via the verified Playwright command) is committed, with
  GitHub social-preview upload steps documented (Settings-UI-only — no API
  exists).
- [ ] **SURF-03**: The shipped admin wordmark
  (`mailglass_admin/priv/static/mailglass-logo.svg`, served via
  `controllers/assets.ex:85-87`) is explicitly dispositioned: replaced with
  the sealed-flap identity (with rebuilt committed bundle if required) or
  deferred with a recorded reason.

### HEXD — HexDocs Wiring

- [ ] **HEXD-01**: All three packages' `docs:` config gains `logo:` (and
  `favicon:` where supported) pointing at brand assets — with `width`/
  `height` attributes added to the referenced SVGs first (ex_doc 0.40.x
  requires them; the current assets are viewBox-only).
- [ ] **HEXD-02**: `mix docs` renders locally for all three packages with
  the logo/favicon visible and no new warnings; committed as
  non-release-triggering types.

### RELH — Release Hardening (incident follow-through, 2026-06-12)

- [ ] **RELH-01**: release-please can no longer cut a release from commits
  that touch only brand/planning paths: either the root package's `"."`
  path stops claiming `brandbook/`+`.planning/` (config mechanism researched
  and verified against release-please's manifest schema), or an equivalent
  enforced convention (commit-type lint for those paths) is added to CI.
- [ ] **RELH-02**: The 1.6.x release aftermath is reconciled: unpublished
  stale tags dispositioned (deleted or documented), the inbound exact-pin
  bumped to the released core version via the established `fix(inbound)`
  dance, and `.planning` release-state memory/docs updated to the final
  version truth.

## Future Requirements

- Propagating the brand into HexDocs extras/guides styling (beyond logo).
- Launch collateral usage (social posts using copy-blocks.md) when a real
  release warrants it.

## Out of Scope

- Redesigning anything inside the brand book — v1.9 closed it; this
  milestone only moves and propagates.
- Admin UI restyling beyond the single wordmark asset disposition (SURF-03).
- Forcing a Hex release to make HexDocs logos visible.
- Marketing-email features (permanent).

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| FOLD-01 | Phase 91 | Complete |
| FOLD-02 | Phase 91 | Pending |
| FOLD-03 | Phase 91 | Complete |
| SURF-01 | Phase 92 | Pending |
| SURF-02 | Phase 92 | Pending |
| SURF-03 | Phase 92 | Pending |
| HEXD-01 | Phase 93 | Pending |
| HEXD-02 | Phase 93 | Pending |
| RELH-01 | Phase 93 | Pending |
| RELH-02 | Phase 93 | Pending |

**Coverage:** 10/10 v1.10 requirements mapped (roadmap created 2026-06-12).
