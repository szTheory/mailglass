# Phase 91: Folder Adoption and Reference Reconciliation - Context

**Gathered:** 2026-06-12 (assumptions mode, subagent-backed)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 91 makes the fable brand book the one canonical root `brandbook/`
folder. It removes the old codex brandbook from the active tree, moves the
tracked `brandbook-fable/` artifacts into `brandbook/`, reconciles active
source-of-truth pointers, and re-runs the v1.9 quality gate on the new path.

This phase does not propagate the brand into repo surfaces. README header,
OG PNG export, admin wordmark disposition, ex_doc logo/favicon wiring, and
release-pipeline hardening remain Phase 92/93 work.

</domain>

<decisions>
## Implementation Decisions

### Canonical folder adoption
- **D-01:** Use a clean tracked replacement: remove tracked old codex files
  under `brandbook/`, clear verified ignored leftovers, then `git mv
  brandbook-fable brandbook`. Do not copy files manually, keep both folders
  temporarily, or rename the codex book into an in-tree archive.
- **D-02:** Preflight ignored/untracked files before the move. Current known
  ignored files are `.DS_Store` entries under `brandbook/`,
  `brandbook/assets/`, and `brandbook-fable/`; they must not be committed and
  must not make `git mv` move fable inside an existing `brandbook/` directory.
- **D-03:** The old codex brandbook is preserved only by git history at the
  frozen baseline `09a84dd4`. Active code and docs should not retain a second
  codex/fable comparison tree.

### Reference reconciliation
- **D-04:** Move active brand source-of-truth pointers from
  `prompts/mailglass-brand-book.md` to `brandbook/brand-book.md`.
  Required active targets include `CLAUDE.md`,
  `mailglass_admin/docs/design-system.md`, and the active source comment in
  `mailglass_admin/assets/css/app.css`.
- **D-05:** Preserve `prompts/mailglass-brand-book.md` as prompt-era
  historical research. Do not delete or rewrite it; only active pointers move.
- **D-06:** Update live `.planning` memory where it guides future agents
  (`PROJECT.md`, `STATE.md`, current roadmap/requirements wording as needed),
  including superseding D-19 so the active brand source of truth is
  `brandbook/brand-book.md`.
- **D-07:** Do not rewrite `.planning/milestones/**`, historical research
  records, completed todos, vendored dependency baselines, or generated docs
  merely to make grep output clean. Phase 91's "no stale references" gate
  should distinguish active pointers from historical/provenance records with
  an explicit allowlist.

### Quality gate adaptation
- **D-08:** Copy/adapt the Phase 90 `gate.sh` into the Phase 91 phase
  directory. Keep the gate outside `brandbook/` so the canonical brand folder
  stays artifact-only.
- **D-09:** Keep Phase 90 checks 1-8 materially intact, with `BB="brandbook"`.
  These prove SVG parse/inventory, JSON parse, local reference integrity,
  process-vocabulary cleanliness, no live SVG text/fonts, no banned mark
  plates, size budgets, and favicon shape/viewBox constraints.
- **D-10:** Replace old Check 9. The previous frozen-codex assertion becomes
  intentionally false after adoption. New Check 9 should verify adoption
  scope: `brandbook-fable/` does not exist, `brandbook/brand-book.md` exists,
  active brand pointers point at `brandbook/brand-book.md`, old codex-only
  files are absent from canonical `brandbook/`, `.DS_Store` is untracked, and
  the phase diff is limited to the approved rename/reference/gate/planning
  evidence work.
- **D-11:** Do not rerun browser screenshots unless Phase 91 changes rendered
  brandbook content. A path-only adoption is sufficiently covered by the
  re-pathed gate plus reference checks; Phase 90 already captured browser
  evidence for the unchanged fable artifacts.

### Phase boundary for design surfaces
- **D-12:** Keep Phase 91 FOLD-only. README/OG/admin/HexDocs work must not
  ride along with the folder adoption because each surface has different
  sealed-flap usage, light/dark, accessibility, bundle, binary, or release
  verification requirements.
- **D-13:** Downstream notes are locked: Phase 92 owns README header,
  `og-card.png` export/upload instructions, and admin wordmark
  replace-or-defer disposition; Phase 93 owns SVG width/height prep,
  ex_doc logo/favicon config, local `mix docs` proof, and release hardening.

### Release safety and commit shape
- **D-14:** Use only non-release-triggering commit types for Phase 91:
  `chore:` for the canonical folder adoption/gate mechanics and `docs:` for
  pointer/reference/context updates. Do not use `feat:`, `fix:`, `deps:`, `!`,
  `BREAKING CHANGE`, or `Release-As`.
- **D-15:** Do not add the path-aware release-hardening lint in Phase 91.
  RELH-01 belongs to Phase 93. Phase 91 should rely on disciplined commit
  titles plus explicit verification that no Release Please PR was created.

### the agent's Discretion
- Exact wording of updated current-state prose in `CLAUDE.md` and live
  planning files, as long as the canonical source remains
  `brandbook/brand-book.md` and historical v1.8/v1.9 facts remain accurate.
- Exact structure of the Phase 91 gate evidence file, as long as it records
  the re-pathed gate output and reference-sweep commands clearly.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` - Phase 91 goal, dependencies, success criteria, and
  strict sequencing before Phases 92/93.
- `.planning/REQUIREMENTS.md` - FOLD-01..03 and milestone scope locks.
- `.planning/STATE.md` - v1.10 current position, pre-settled decisions, and
  active release-safety notes.
- `.planning/PROJECT.md` - project vision, v1.10 milestone intent, D-19/D-25
  brand-source context, and out-of-scope boundaries.

### Adoption mechanics and release safety
- `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md` - git
  adoption mechanics, reference sweep, ex_doc caveats for later phases,
  Release Please safety, and GitHub social preview/PNG export notes.
- `release-please-config.json` - package attribution and linked-version setup.
- `.github/workflows/pr-title.yml` - allowed Conventional Commit types.
- `.github/workflows/ci.yml` - path filters and CI behavior.
- `mailglass_inbound/mix.exs` - exact core pin comments and why accidental
  core releases drag inbound follow-up work.
- `CLAUDE.md` - release gotchas and current project guide.

### Binding brand constraints
- `.planning/milestones/v1.9-phases/87-logo-tournament/87-decision-record.md`
  - sealed-flap winner, asset mapping, C-15 no broken reads, and C-16
  envelope-by-light-only.
- `brandbook-fable/README.md` - pre-move fable folder contents and usage rules.
- `brandbook-fable/brand-book.md` - active source-of-truth content that will
  become `brandbook/brand-book.md`.
- `prompts/mailglass-brand-book.md` - historical prompt-era brand research;
  preserve as provenance, not as the active source of truth.

### Quality gate precedent
- `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/gate.sh` -
  source gate to adapt.
- `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/90-gate-evidence.md`
  - first-pass gate output and browser evidence.
- `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/90-VERIFICATION.md`
  - proof that v1.9 fable artifacts passed all gate and UAT checks.

### Active reference targets
- `CLAUDE.md` - current-state and Brand & Voice source-of-truth pointer.
- `mailglass_admin/docs/design-system.md` - HexDocs-facing admin design-system
  pointer.
- `mailglass_admin/assets/css/app.css` - active admin CSS source comment
  naming the old prompt-era brand source.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `brandbook-fable/` contains the approved fable book: `index.html`,
  `brand-book.md`, `tokens.css`, `tokens.json`, 8 logo assets, 6 examples, and
  copy docs. It is the content to move into canonical `brandbook/`.
- `brandbook/` currently contains the old codex/draft baseline and must be
  removed from the active tree, not merged with fable content.
- Phase 90 `gate.sh` is the strongest reusable verification asset. It is
  hardcoded to `brandbook-fable/` and must be re-pathed/adapted.

### Established Patterns
- Brand artifacts are text-first SVG/HTML/MD/CSS/JSON and open from `file://`;
  no Node toolchain or external network dependency is introduced by Phase 91.
- Historical `.planning/milestones/**` archives are immutable evidence. Live
  planning files can be updated by the workflow; archived phase records are
  not rewritten.
- Commit types drive release automation. `chore:` and `docs:` are the safe
  forms for this phase; `feat:`/`fix:` can create release train work.
- Admin static assets have bundle-drift rules, but Phase 91 only updates a CSS
  source comment. Do not rebuild or change `priv/static/` unless execution
  changes compiled CSS content beyond comments.

### Integration Points
- Git/index operations around `brandbook/` and `brandbook-fable/`.
- Active project guide and docs pointers: `CLAUDE.md`,
  `mailglass_admin/docs/design-system.md`, `mailglass_admin/assets/css/app.css`.
- Phase-local verification artifacts under
  `.planning/phases/91-folder-adoption-and-reference-reconciliation/`.
- Future consumers: Phase 92 README/OG/admin work and Phase 93 HexDocs/release
  hardening expect stable post-rename `brandbook/` paths.

</code_context>

<specifics>
## Specific Ideas

- Use an evidence-led implementation transcript:
  `git status --ignored --short --untracked-files=all -- brandbook brandbook-fable`,
  `git rm -r brandbook`, `rm -rf brandbook`, `git mv brandbook-fable brandbook`,
  then `test ! -e brandbook-fable` and `git ls-files brandbook-fable`.
- The gate's active-reference check should be explicit rather than a broad
  "grep must be empty" over historical records. It should fail active stale
  pointers and permit documented historical/provenance paths.
- Design-system propagation is intentionally delayed because each visible
  surface needs its own light/dark/accessibility/release verification.

</specifics>

<deferred>
## Deferred Ideas

- README brand header using `brandbook/examples/readme-header.svg` - Phase 92.
- `brandbook/examples/og-card.png` export and GitHub Settings UI upload notes
  - Phase 92.
- Admin wordmark replace-or-defer disposition, including bundle proof if
  replaced - Phase 92.
- SVG width/height attrs for ex_doc assets, all three `docs:` configs, and
  local `mix docs` proof - Phase 93.
- Release-please path hardening / commit-type lint for brand/planning-only
  commits - Phase 93.

None beyond those already assigned to Phases 92/93.

</deferred>

---

*Phase: 91-folder-adoption-and-reference-reconciliation*
*Context gathered: 2026-06-12*
