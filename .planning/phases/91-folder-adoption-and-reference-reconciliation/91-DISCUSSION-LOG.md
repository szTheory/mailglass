# Phase 91: Folder Adoption and Reference Reconciliation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution
> agents. Decisions captured in CONTEXT.md are authoritative.

**Date:** 2026-06-12
**Phase:** 91-folder-adoption-and-reference-reconciliation
**Mode:** assumptions with explicit subagent research
**Areas analyzed:** folder adoption mechanics, reference reconciliation, gate
adaptation, surface boundary, release safety, whole-phase assumptions

## Assumptions Presented

### Initial Synthesis

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Replace old tracked `brandbook/` with tracked `brandbook-fable/` via `git mv`; ignored `.DS_Store` stays out. | Likely | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `git ls-files brandbook brandbook-fable`, `.gitignore` |
| Update active brand pointers in `CLAUDE.md` and `mailglass_admin/docs/design-system.md`; treat `.planning` references as workflow memory unless closeout updates them. | Likely | `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md`, `CLAUDE.md`, `mailglass_admin/docs/design-system.md` |
| Adapt the Phase 90 gate to target `brandbook/`, keeping checks 1-8 and replacing frozen-baseline check 9 with post-adoption scope checks. | Confident | `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/gate.sh`, FOLD-03 |
| Keep README/OG/admin wordmark/ex_doc work out of Phase 91. | Confident | `.planning/ROADMAP.md` Phases 91-93 sequencing |
| Use only non-release commit types (`chore:`/`docs:`). | Confident | `.planning/REQUIREMENTS.md`, `release-please-config.json`, Release Please docs |

## Maintainer Direction

The maintainer asked to research each assumption with subagents and produce a
cohesive recommendation set that accounts for:

- pros, cons, and tradeoffs;
- Elixir/Phoenix/Plug/Ecto ecosystem idioms where relevant;
- lessons from successful libraries and frameworks, including other languages;
- developer ergonomics, least surprise, release/DX, and maintainer burden;
- UI/UX and graphic-design implications where applicable;
- project prompt research under `prompts/`.

## Subagent Research Applied

### Folder adoption mechanics

Recommendation: remove tracked codex `brandbook/`, clear verified ignored
leftovers, then `git mv brandbook-fable brandbook`. Do not keep codex in-tree,
copy manually, or preserve both folders.

Key footguns:
- `git mv brandbook-fable brandbook` while `brandbook/` exists may move fable
  inside the existing directory.
- Ignored `.DS_Store` files exist and must not be committed or allowed to block
  the destination path.
- Codex should be retrieved from history (`09a84dd4`) if needed, not retained
  as an active folder.

### Reference reconciliation

Recommendation: perform an active-repo reference sweep, update active pointers
and live `.planning` memory, preserve historical/provenance records unchanged.

Key refinement:
- `mailglass_admin/assets/css/app.css` is an active tracked source file with a
  stale `prompts/mailglass-brand-book.md` comment and must be included.

### Gate adaptation

Recommendation: create a Phase 91 phase-local adapted gate. Keep checks 1-8,
replace check 9 with adoption-scope/reference checks, and avoid promoting a
permanent brand gate unless later phases need it.

Key footguns:
- The old "frozen brandbook/ unchanged since 09a84dd4" check is obsolete after
  adoption.
- Browser screenshots are not needed unless rendered content changes.

### Surface boundary and design implications

Recommendation: keep Phase 91 FOLD-only. README, OG, admin wordmark, and
HexDocs wiring should stay in Phases 92/93 because they each require
surface-specific design verification.

Design constraints carried forward:
- primary lockup only on light grounds;
- mono/dark expression for dark surfaces;
- favicon adapts by OS color scheme;
- no background plates except square social avatars;
- outlined SVGs only;
- contrast and token discipline remain binding.

### Release safety

Recommendation: use only `chore:`/`docs:` in Phase 91 and defer path-aware
release hardening to Phase 93.

Key footguns:
- Root package path `"."` means releasable commits touching brand/planning
  paths can be attributed to core.
- Core/admin linked versions and inbound exact-pin behavior make accidental
  releases expensive.
- `pr-title.yml` allows `feat:`/`fix:`; it does not prevent those types on
  brand paths.

## Corrections Made

No content correction was requested after the final synthesis. The final
maintainer response was: `proceed`.

The final decisions differ from the initial synthesis in two ways:

- Live `.planning` memory should be updated deliberately where it guides future
  agents, while historical/provenance records remain allowed.
- `mailglass_admin/assets/css/app.css` is an active pointer target and must be
  included with `CLAUDE.md` and `mailglass_admin/docs/design-system.md`.

## External Research

- Git `git mv` docs: `git mv` moves/renames files or directories and updates
  the index, but the change still must be committed.
- Release Please docs: release PRs are created from releasable conventional
  commit units; `feat:` and `fix:` are release-relevant, while `chore:` is not
  a release unit by default.
- Conventional Commits: `fix:` maps to PATCH, `feat:` maps to MINOR, breaking
  indicators map to MAJOR; other types are allowed and do not imply SemVer
  changes by themselves.

## Sources Considered

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/PROJECT.md`
- `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md`
- `.planning/milestones/v1.9-phases/87-logo-tournament/87-decision-record.md`
- `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/gate.sh`
- `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/90-gate-evidence.md`
- `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/90-VERIFICATION.md`
- `brandbook-fable/README.md`
- `brandbook-fable/brand-book.md`
- `CLAUDE.md`
- `mailglass_admin/docs/design-system.md`
- `mailglass_admin/assets/css/app.css`
- `release-please-config.json`
- `.github/workflows/pr-title.yml`
- `.github/workflows/ci.yml`
- `mailglass_inbound/mix.exs`
- `prompts/mailglass-brand-book.md`
- `prompts/mailglass-engineering-dna-from-prior-libs.md`
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`
- `.planning/research/v1.9-brandbook-fable/SUMMARY.md`
- `.planning/research/v1.9-brandbook-fable/PITFALLS-PORTABILITY.md`
