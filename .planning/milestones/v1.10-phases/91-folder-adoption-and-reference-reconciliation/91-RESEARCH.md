# Phase 91: Folder Adoption and Reference Reconciliation - Research

**Researched:** 2026-06-12
**Domain:** Git folder adoption, tracked-reference reconciliation, bash validation gate
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
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
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FOLD-01 | `brandbook-fable/` becomes canonical `brandbook/` via `git mv`; old codex files removed in same commit; codex history preserved at `09a84dd4`. | Git/index plan, ignored-file preflight, and old-only file inventory below. [VERIFIED: .planning/REQUIREMENTS.md + git ls-files] |
| FOLD-02 | Reconcile tracked active references to `brandbook-fable/` and old brand source pointer. | Active targets are `CLAUDE.md`, `mailglass_admin/docs/design-system.md`, and `mailglass_admin/assets/css/app.css`; live planning memory also needs wording updates. [VERIFIED: rg repo sweep + 91-CONTEXT.md] |
| FOLD-03 | Re-path v1.9 `gate.sh` and pass it on canonical `brandbook/`. | Phase 90 checks 1-8 are reusable; Check 9 must become adoption-scope checks because the frozen-codex assertion now intentionally fails. [VERIFIED: gate.sh run + 91-CONTEXT.md] |
</phase_requirements>

## Summary

Phase 91 is a repository-layout adoption phase, not a product-code or package-install phase. [VERIFIED: .planning/ROADMAP.md] The planner should treat it as three tightly coupled tasks: preflight the working tree and ignored files, replace tracked `brandbook/` with tracked `brandbook-fable/` using Git operations, then reconcile active references and prove the move with a copied Phase 91 gate. [VERIFIED: 91-CONTEXT.md + git status + gate.sh]

The highest-risk detail is `brandbook/` already exists and contains tracked codex-era files plus ignored `.DS_Store` leftovers. [VERIFIED: git ls-files + git status --ignored] If `git mv brandbook-fable brandbook` is attempted while the directory remains, Git can create the wrong nested layout or fail, so the plan must remove tracked old files and clear ignored leftovers first. [VERIFIED: 91-CONTEXT.md]

**Primary recommendation:** Plan one `chore:` adoption commit for the folder/gate mechanics and one `docs:` commit for pointer/planning-memory updates; do not include README, OG PNG, admin wordmark, HexDocs config, SVG width/height, or release-hardening lint. [VERIFIED: 91-CONTEXT.md + .planning/ROADMAP.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical brandbook folder adoption | Git / Repository | Static assets | The changed system of record is tracked files and paths, not runtime code. [VERIFIED: .planning/ROADMAP.md] |
| Active reference reconciliation | Documentation / Planning memory | Admin CSS source comment | References are prose/source comments consumed by future agents and docs readers. [VERIFIED: rg repo sweep] |
| Quality gate adaptation | Validation tooling | Git / Repository | `gate.sh` validates file inventory, local references, SVG/JSON shape, and adoption invariants. [VERIFIED: gate.sh] |
| Release safety | Git history / CI conventions | GitHub release automation | Commit types are the immediate guard; RELH-01 automation hardening is deferred to Phase 93. [VERIFIED: 91-CONTEXT.md + pr-title.yml] |

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists or has readable content in the repository root. [VERIFIED: `test -f AGENTS.md && sed ... || true` returned no content]

Project-local `.codex/skills/` and `.agents/skills/` directories were not present. [VERIFIED: `find .codex/skills .agents/skills -name SKILL.md` returned no files]

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Git | 2.41.0 | Tracked directory removal, `git mv`, diff/path validation | The phase is a tracked-path replacement; Git preserves history and gives path-scoped proof. [VERIFIED: git --version + phase goal] |
| Bash | 5.2.37 | Phase-local validation gate | Phase 90 gate is already a Bash script and is the required precedent. [VERIFIED: bash --version + gate.sh] |
| `/usr/bin/xmllint` | libxml 2.9.13 | SVG XML parse check | Phase 90 gate already uses this exact binary for SVG parse checks. [VERIFIED: gate.sh + xmllint output] |
| Python | 3.14.4 | JSON parse check via `python3 -m json.tool` | Phase 90 gate already uses Python's stdlib JSON parser for `tokens.json`. [VERIFIED: gate.sh + python3 --version] |
| ripgrep | 15.1.0 | Active-reference sweeps | Fast tracked/untracked text search; required for exact stale-reference proof. [VERIFIED: rg --version + repo sweep] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `find`, `grep`, `wc`, `du`, `sed`, `awk` | macOS/BSD userland plus awk 20200816 | Inventory counts, pattern checks, size budgets | Reuse because Phase 90 gate already depends on these utilities. [VERIFIED: gate.sh + environment probe] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `git mv` | Manual copy/delete | Rejected by locked D-01; manual copy loses the clear tracked-rename intent the phase requires. [VERIFIED: 91-CONTEXT.md] |
| Phase-local Bash gate | Elixir ExUnit test | Rejected for this phase because FOLD-03 specifically requires adapting v1.9 `gate.sh`. [VERIFIED: .planning/REQUIREMENTS.md] |
| Broad grep-zero policy | Explicit active-reference allowlist | Use the allowlist because historical `.planning/milestones/**`, research, todos, vendored baselines, and `prompts/` must remain intact. [VERIFIED: 91-CONTEXT.md + rg sweep] |

**Installation:** No external packages should be installed for Phase 91. [VERIFIED: phase scope + existing tools available]

## Package Legitimacy Audit

No external package installation is recommended. Package Legitimacy Gate is not applicable. [VERIFIED: Standard Stack uses existing local tools only]

## Architecture Patterns

### System Architecture Diagram

```text
Repo root before Phase 91
  |
  +--> tracked brandbook/ (old codex baseline) + ignored .DS_Store leftovers
  |
  +--> tracked brandbook-fable/ (approved fable artifacts)
  |
  +--> active pointers (CLAUDE.md, admin design-system.md, app.css comment)
  |
  v
Preflight
  -> git status --ignored --short --untracked-files=all -- brandbook brandbook-fable
  -> confirm only ignored .DS_Store leftovers exist
  |
  v
Tracked replacement
  -> git rm -r brandbook
  -> remove ignored leftover directory/files
  -> git mv brandbook-fable brandbook
  |
  v
Reference reconciliation
  -> point active docs/comments at brandbook/brand-book.md
  -> update live .planning memory
  -> keep historical archives/prompts untouched
  |
  v
Phase 91 gate
  -> checks 1-8 from Phase 90 with BB=brandbook
  -> new Check 9 verifies adoption invariants and allowed diff scope
  -> evidence file records commands/output
```

### Recommended Project Structure

```text
brandbook/
├── README.md
├── brand-book.md
├── index.html
├── tokens.css
├── tokens.json
├── assets/
├── copy/
└── examples/

.planning/phases/91-folder-adoption-and-reference-reconciliation/
├── 91-CONTEXT.md
├── 91-RESEARCH.md
├── gate.sh
└── 91-gate-evidence.md
```

### Pattern 1: Clean Tracked Replacement

**What:** Remove tracked old `brandbook/`, remove verified ignored leftovers, then `git mv brandbook-fable brandbook`. [VERIFIED: 91-CONTEXT.md]

**When to use:** Use for FOLD-01 because the destination path already exists and the old codex files must not remain active. [VERIFIED: git ls-files]

**Example:**

```bash
git status --ignored --short --untracked-files=all -- brandbook brandbook-fable
git rm -r brandbook
rm -rf brandbook
git mv brandbook-fable brandbook
test ! -e brandbook-fable
test -f brandbook/brand-book.md
git ls-files brandbook-fable
```

### Pattern 2: Explicit Active-Reference Sweep

**What:** Use direct `rg` checks over active paths and broad repo checks with historical allowlists. [VERIFIED: 91-CONTEXT.md + rg sweep]

**When to use:** Use after pointer edits and in Check 9. [VERIFIED: FOLD-02]

**Example:**

```bash
rg -n 'brandbook-fable|prompts/mailglass-brand-book\.md' \
  CLAUDE.md mailglass_admin/docs/design-system.md mailglass_admin/assets/css/app.css \
  .planning/PROJECT.md .planning/STATE.md .planning/ROADMAP.md .planning/REQUIREMENTS.md

rg -n 'brandbook-fable' --glob '!.planning/milestones/**'
```

### Pattern 3: Replace Check 9 With Adoption Invariants

**What:** Keep Phase 90 Checks 1-8 materially intact and replace Check 9 with post-adoption checks. [VERIFIED: gate.sh + 91-CONTEXT.md]

**When to use:** Use because the old Check 9 failed on current HEAD by design: it still asserts a v1.9 range limited to `brandbook-fable/` + `.planning/`, but newer files outside that range now exist. [VERIFIED: local gate run]

**Example:**

```bash
c9_ok=1
[ ! -e brandbook-fable ] || fail 9 "brandbook-fable/ still exists"
[ -f "$BB/brand-book.md" ] || fail 9 "$BB/brand-book.md missing"
git ls-files brandbook-fable | grep -q . && fail 9 "tracked brandbook-fable files remain"
git ls-files "$BB/assets/concepts" "$BB/assets/options" "$BB/brand-audit.md" \
  "$BB/logo-concepts.html" "$BB/logo-concepts.md" "$BB/logo-creative-brief.md" \
  "$BB/logo-options.md" | grep -q . && fail 9 "old codex-only files remain"
git status --ignored --short --untracked-files=all -- "$BB" brandbook-fable | \
  grep -E '^[?!]' | grep -v '\.DS_Store$' && fail 9 "unexpected ignored/untracked brandbook files"
[ "$c9_ok" -eq 1 ] && echo "CHECK-9 PASS"
```

### Anti-Patterns to Avoid

- **Keeping a codex archive under the active tree:** This violates D-03; history at `09a84dd4` is the archive. [VERIFIED: 91-CONTEXT.md]
- **Using broad grep output as a cleanup todo:** This would rewrite immutable archives and historical research. Use an allowlist instead. [VERIFIED: 91-CONTEXT.md + rg sweep]
- **Editing README, OG PNG, admin wordmark, HexDocs config, or SVG width/height:** These are Phase 92/93 responsibilities, not FOLD. [VERIFIED: 91-CONTEXT.md]
- **Rebuilding admin static CSS for a comment-only source change:** CSS comments do not change shipped semantics, and D-12 keeps visible admin work out of scope; planner should avoid `priv/static/` churn unless implementation changes compiled CSS content. [VERIFIED: 91-CONTEXT.md + CLAUDE.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Directory move/history | Custom copy script | `git rm` + `git mv` | The phase requires a Git-visible replacement. [VERIFIED: FOLD-01] |
| SVG/XML validation | Custom parser | `/usr/bin/xmllint --noout` | Existing v1.9 gate already validates all SVG assets this way. [VERIFIED: gate.sh] |
| JSON validation | Custom JSON parsing | `python3 -m json.tool` | Existing v1.9 gate already validates `tokens.json` this way. [VERIFIED: gate.sh] |
| Stale-reference detection | Manual review | `rg` checks with explicit allowlists | The active and historical surfaces must be distinguished mechanically. [VERIFIED: 91-CONTEXT.md] |
| Release safety | New release-hardening lint | Commit type discipline + verification | RELH-01 is deferred to Phase 93. [VERIFIED: 91-CONTEXT.md] |

**Key insight:** This phase is about preserving artifact identity while changing the canonical path; custom migration logic adds risk without improving correctness. [VERIFIED: phase scope + 91-CONTEXT.md]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None found. No database/datastore state stores `brandbook-fable`, `brandbook/`, or `prompts/mailglass-brand-book.md` in active runtime code paths. [VERIFIED: rg hidden sweep excluding deps/build outputs] | None. |
| Live service config | None found in repo-managed service config. `.env.example`, `reference/host_app/.env.example`, and `compose.demo.yml` exist but did not expose brandbook path state. [VERIFIED: find + rg sweep] | None. |
| OS-registered state | None found. No launchd/systemd/pm2-style registration files were present in the repository scan. [VERIFIED: find for plist/systemd/ecosystem files] | None. |
| Secrets/env vars | None found. `.env.example` files do not carry the renamed path; no SOPS/secret path files were found in the depth-limited repo scan. [VERIFIED: find + rg sweep] | None. |
| Build artifacts | Generated/build directories exist (`_build/`, `doc/`, package `_build/`/`doc/`, `tmp/`) and may contain stale generated references; they are not tracked adoption targets. [VERIFIED: find] | Do not edit generated artifacts. Gate tracked files and active pointers only. |

**Canonical question answer:** After every tracked file is updated, no runtime system needs a separate data migration or re-registration for this path rename. [VERIFIED: runtime-state audit]

## Common Pitfalls

### Pitfall 1: Nested or Failed Move Because Destination Exists

**What goes wrong:** Running `git mv brandbook-fable brandbook` before removing old `brandbook/` can produce the wrong layout or fail. [VERIFIED: 91-CONTEXT.md]

**Why it happens:** `brandbook/` is already a tracked directory and also has ignored `.DS_Store` leftovers. [VERIFIED: git ls-files + git status --ignored]

**How to avoid:** Preflight ignored files, `git rm -r brandbook`, remove leftovers, then `git mv brandbook-fable brandbook`. [VERIFIED: 91-CONTEXT.md]

**Warning signs:** `brandbook/brandbook-fable/`, tracked files under `brandbook-fable/`, or `.DS_Store` staged for commit. [VERIFIED: adoption invariant design]

### Pitfall 2: Rewriting Historical Evidence

**What goes wrong:** A broad grep-zero cleanup touches `.planning/milestones/**`, historical research, todos, or prompt provenance. [VERIFIED: rg sweep]

**Why it happens:** Historical records intentionally mention `brandbook-fable/`, codex baselines, and prompt-era sources. [VERIFIED: rg sweep + 91-CONTEXT.md]

**How to avoid:** Gate active surfaces and live planning memory; explicitly allow archives and provenance records. [VERIFIED: 91-CONTEXT.md]

**Warning signs:** Diffs under `.planning/milestones/**` or edits to `prompts/mailglass-brand-book.md`. [VERIFIED: scope locks]

### Pitfall 3: Reusing Old Check 9

**What goes wrong:** The adapted gate fails even when artifacts are valid because Check 9 still checks that frozen `brandbook/` is unchanged and that `09a84dd4..HEAD` touched only `brandbook-fable/` + `.planning/`. [VERIFIED: local gate run]

**Why it happens:** Phase 90 protected the A/B baseline; Phase 91 intentionally deletes that active baseline. [VERIFIED: gate.sh + FOLD-01]

**How to avoid:** Replace Check 9 with adoption-scope checks. [VERIFIED: 91-CONTEXT.md]

**Warning signs:** Gate output mentions "frozen brandbook/ differs" or "outside brandbook-fable/ + .planning/ changed". [VERIFIED: gate.sh]

### Pitfall 4: Accidental Release Trigger

**What goes wrong:** A `feat:`, `fix:`, breaking marker, or `Release-As` commit can create release-please work. [VERIFIED: 91-CONTEXT.md + release-please config]

**Why it happens:** Release Please parses Conventional Commit types; PR title enforcement allows several types, including `feat` and `fix`. [VERIFIED: release-please-config.json + pr-title.yml]

**How to avoid:** Use only `chore:` and `docs:` for Phase 91 and verify no Release Please PR appears. [VERIFIED: 91-CONTEXT.md]

**Warning signs:** Commit titles include `feat`, `fix`, `!`, `BREAKING CHANGE`, `Release-As`, or path-aware lint work. [VERIFIED: 91-CONTEXT.md]

## Code Examples

### Old-Only Codex Files to Assert Absent After Adoption

```text
assets/concepts/
assets/options/
brand-audit.md
examples/palette.svg
examples/typography.svg
examples/ui-primitives.svg
logo-concepts.html
logo-concepts.md
logo-creative-brief.md
logo-options.md
```

Source: current tracked `brandbook/` minus tracked `brandbook-fable/`. [VERIFIED: git ls-files + comm]

### Focused Reference Reconciliation Targets

```text
CLAUDE.md:17
CLAUDE.md:62
mailglass_admin/docs/design-system.md:5
mailglass_admin/assets/css/app.css:2
.planning/PROJECT.md D-19 and current milestone prose
.planning/STATE.md current position/decisions
.planning/ROADMAP.md and .planning/REQUIREMENTS.md only as needed for live status wording
```

Source: active reference sweep and D-04/D-06. [VERIFIED: rg sweep + 91-CONTEXT.md]

### Gate Run

```bash
bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh
```

Expected sentinel after adoption: `GATE-PASS`. [VERIFIED: Phase 90 gate convention]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| v1.8 codex `brandbook/` as active brand artifact | v1.9 fable book becomes canonical `brandbook/` | Phase 91, v1.10 | Remove codex files from active tree; preserve only in Git history. [VERIFIED: ROADMAP + CONTEXT] |
| Prompt-era brand pointer `prompts/mailglass-brand-book.md` | Canonical source pointer `brandbook/brand-book.md` | Phase 91, v1.10 | Future agents/docs should read the moved fable book for active brand decisions. [VERIFIED: 91-CONTEXT.md] |
| Phase 90 gate protects frozen A/B baseline | Phase 91 gate proves adoption invariants | Phase 91, v1.10 | Check 9 must change; checks 1-8 remain. [VERIFIED: gate.sh + CONTEXT] |

**Deprecated/outdated:**
- Active references to `brandbook-fable/`: outdated after the move. [VERIFIED: FOLD-02]
- Active source-of-truth references to `prompts/mailglass-brand-book.md`: outdated after Phase 91, but the prompt file itself remains historical provenance. [VERIFIED: D-04/D-05]
- Old codex-only files under canonical `brandbook/`: outdated active artifacts after adoption. [VERIFIED: D-03 + old-only inventory]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No external live service outside the repository stores the brandbook path. [ASSUMED] | Runtime State Inventory | A manually configured external dashboard could retain old path prose, but no repo evidence points to one. |

## Open Questions (RESOLVED)

1. **RESOLVED: Should gate Check 9 inspect commit titles locally or leave release verification outside the script?**
   - What we know: D-14/D-15 require non-release-triggering commit types and no Release Please PR. [VERIFIED: 91-CONTEXT.md]
   - What's unclear: The local gate can inspect local Git log only after commits exist; pre-commit execution cannot prove future PR behavior. [VERIFIED: Git workflow constraints]
   - Recommendation: Put path/adoption invariants in `gate.sh`; put commit-title and no-release-PR proof in `91-gate-evidence.md` / verification. [VERIFIED: phase workflow fit]
   - Final decision: Check 9 stays scoped to folder adoption/path invariants; release-safety evidence stays outside the script and is recorded by Plan 91-04 in `91-gate-evidence.md`. [RESOLVED: 2026-06-12]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Git | FOLD-01, FOLD-02, release-safety proof | Yes | 2.41.0 | None needed. [VERIFIED: git --version] |
| Bash | FOLD-03 gate | Yes | 5.2.37 | POSIX shell would require script edits; not needed. [VERIFIED: bash --version] |
| `/usr/bin/xmllint` | Gate Check 1 | Yes | libxml 2.9.13 | None needed. [VERIFIED: xmllint output] |
| Python 3 | Gate Check 2 | Yes | 3.14.4 | `jq` could parse JSON, but Python is already in Phase 90 gate. [VERIFIED: python3 --version] |
| ripgrep | Reference sweeps | Yes | 15.1.0 | `grep -R` with careful excludes. [VERIFIED: rg --version] |
| `find`/`grep`/`wc`/`du`/`sed`/`awk` | Gate checks | Yes | macOS/BSD userland, awk 20200816 | None needed. [VERIFIED: command probes] |

**Missing dependencies with no fallback:** None. [VERIFIED: environment audit]

**Missing dependencies with fallback:** None. [VERIFIED: environment audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Phase-local Bash gate adapted from Phase 90. [VERIFIED: gate.sh] |
| Config file | None; script-local constants (`BB="brandbook"`). [VERIFIED: gate.sh pattern] |
| Quick run command | `bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` |
| Full suite command | Same as quick run; this phase has no package-code test surface. [VERIFIED: phase scope] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FOLD-01 | Canonical `brandbook/` contains fable artifacts; `brandbook-fable/` absent; codex-only files absent. | bash/integration | `bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` | No, create in Wave 0. [VERIFIED: phase dir] |
| FOLD-02 | Active references point to `brandbook/brand-book.md`; stale `brandbook-fable/` outside allowed history is absent. | bash/integration | `bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` plus recorded `rg` sweep | No, create in Wave 0. [VERIFIED: phase dir] |
| FOLD-03 | Re-pathed v1.9 quality gate passes on canonical folder. | bash/integration | `bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` | No, create in Wave 0. [VERIFIED: phase dir] |

### Sampling Rate

- **Per task commit:** Run the phase-local gate for any commit touching `brandbook/`, `brandbook-fable/`, active pointers, or `gate.sh`. [VERIFIED: FOLD-03]
- **Per wave merge:** Run the phase-local gate and active `rg` sweep. [VERIFIED: FOLD-02/FOLD-03]
- **Phase gate:** `GATE-PASS`, evidence file, and release-safety proof before `$gsd-verify-work`. [VERIFIED: 91-CONTEXT.md]

### Wave 0 Gaps

- [ ] `.planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` - adapted from Phase 90 with `BB="brandbook"` and new Check 9. [VERIFIED: phase dir has no gate yet]
- [ ] `.planning/phases/91-folder-adoption-and-reference-reconciliation/91-gate-evidence.md` - records gate output, reference sweep, ignored-file preflight, and release-safety proof. [VERIFIED: 91-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No | No auth surface changes. [VERIFIED: phase scope] |
| V3 Session Management | No | No session surface changes. [VERIFIED: phase scope] |
| V4 Access Control | No | No access-control surface changes. [VERIFIED: phase scope] |
| V5 Input Validation | Yes | Validate repo inputs with `xmllint`, `python3 -m json.tool`, and explicit `rg`/Git invariants. [VERIFIED: gate.sh] |
| V6 Cryptography | No | No cryptographic changes. [VERIFIED: phase scope] |

### Known Threat Patterns for Repository Refactor

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tampering with canonical brand artifacts during move | Tampering | Keep checks 1-8 intact and prove inventory/content shape on new path. [VERIFIED: gate.sh + D-09] |
| Misleading future agents through stale source-of-truth pointers | Spoofing / Repudiation | Update active pointers and live planning memory; preserve archives only as historical records. [VERIFIED: D-04..D-07] |
| Accidental release train from docs/brand commit | Denial of service / Operational risk | Use only `chore:`/`docs:` commit types and verify no Release Please PR. [VERIFIED: D-14/D-15] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/91-folder-adoption-and-reference-reconciliation/91-CONTEXT.md` - locked implementation decisions, active references, gate adaptation. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - FOLD-01..03. [VERIFIED: file read]
- `.planning/ROADMAP.md` - Phase 91 goal and success criteria. [VERIFIED: file read]
- `.planning/STATE.md` and `.planning/PROJECT.md` - live milestone memory and D-19 update target. [VERIFIED: file read]
- `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md` - prior reference sweep and release-safety research. [VERIFIED: file read]
- `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/gate.sh` - gate implementation to adapt. [VERIFIED: file read and local run]
- Repo commands: `git ls-files`, `git status --ignored`, `rg`, environment probes. [VERIFIED: command output]

### Secondary (MEDIUM confidence)

- None needed; this is a codebase-only/path-refactor research phase. [VERIFIED: research scope]

### Tertiary (LOW confidence)

- External live service state absence is assumed beyond repo evidence. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new stack; all required tools exist locally and Phase 90 already uses them. [VERIFIED: environment probes + gate.sh]
- Architecture: HIGH - phase scope is a locked repository refactor with explicit active targets. [VERIFIED: CONTEXT + rg sweep]
- Pitfalls: HIGH - destination-exists, historical-grep, stale Check 9, and commit-type risks were verified against repo state and locked decisions. [VERIFIED: git/rg/gate outputs]

**Research date:** 2026-06-12
**Valid until:** 2026-07-12 for repo-local mechanics; re-check if Phase 92/93 lands first or if release workflow changes. [ASSUMED]
