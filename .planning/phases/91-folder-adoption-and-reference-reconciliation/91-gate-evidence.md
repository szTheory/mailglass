# Phase 91 Gate Evidence - canonical brandbook/ adoption

- **Date:** 2026-06-12
- **Gate script:** `.planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` (run from repo root)
- **Phase scope:** FOLD-01, FOLD-02, FOLD-03

## Phase Base

Phase base: `63701373af556a6c4fbc9d48f0d1a2d7c31782fb`

The phase base is the commit after the phase-local gate was created. Adoption,
reference reconciliation, final evidence, and summary metadata are measured from
this point by the Check 9 diff-scope invariant.

## Wave 0 Gate Setup

Command:

```bash
bash -n .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh
```

Output:

```text
```

Exit code: 0

The syntax proof confirms the adapted `gate.sh` is valid Bash before any folder
adoption task relies on it.

## Ignored File Preflight

Command:

```bash
git status --ignored --short --untracked-files=all -- brandbook brandbook-fable
```

Output before cleanup:

```text
!! brandbook-fable/.DS_Store
!! brandbook/.DS_Store
!! brandbook/assets/.DS_Store
```

Cleanup command:

```bash
rm -f brandbook-fable/.DS_Store brandbook/.DS_Store brandbook/assets/.DS_Store
```

Post-clean verification:

```bash
git status --ignored --short --untracked-files=all -- brandbook brandbook-fable | grep -E '^[?!]' | grep -v '\.DS_Store$'
git status --short -- brandbook brandbook-fable | grep '\.DS_Store'
```

Both verification commands printed no lines. Only the known ignored `.DS_Store`
leftovers were removed; no unexpected untracked or ignored brandbook files
were present.

## Git Folder Adoption

Commands:

```bash
git rm -r brandbook
rm -rf brandbook
git mv brandbook-fable brandbook
```

Result: all three commands exited 0. The old tracked codex-era `brandbook/`
tree was staged for removal, the destination directory was cleared, and the
approved fable artifact tree was moved into canonical `brandbook/` using Git.

Verification:

```bash
test -f brandbook/brand-book.md
test -f brandbook/index.html
test -f brandbook/assets/logo-primary.svg
test ! -e brandbook-fable
test -z "$(git ls-files brandbook-fable)"
test ! -e brandbook/assets/concepts
test ! -e brandbook/assets/options
test ! -e brandbook/brand-audit.md
test ! -e brandbook/logo-concepts.html
test ! -e brandbook/logo-concepts.md
test ! -e brandbook/logo-creative-brief.md
test ! -e brandbook/logo-options.md
git status --short -- brandbook brandbook-fable | grep '\.DS_Store'
```

All `test` commands exited 0. The `.DS_Store` grep printed no lines, which
confirms no `.DS_Store` file is tracked, staged, or untracked under the moved
brandbook paths.

## Active Reference Sweep

Plan 91-03 active pointer verification:

```bash
grep -n 'Source of truth: `brandbook/brand-book.md`\.' CLAUDE.md
grep -n 'brandbook/brand-book.md' mailglass_admin/docs/design-system.md
grep -n 'Brand: brandbook/brand-book.md (Ink/Glass/Ice/Mist/Paper/Slate).' mailglass_admin/assets/css/app.css
```

Output:

```text
CLAUDE.md:62:Source of truth: `brandbook/brand-book.md`.
mailglass_admin/docs/design-system.md:5:`brandbook/brand-book.md`; this doc covers the *mechanics* — tokens, motion,
mailglass_admin/assets/css/app.css:2:   Brand: brandbook/brand-book.md (Ink/Glass/Ice/Mist/Paper/Slate).
```

Active stale pointer sweep:

```bash
grep -n 'brandbook/brand-book.md' \
  .planning/PROJECT.md \
  .planning/STATE.md \
  .planning/ROADMAP.md \
  .planning/REQUIREMENTS.md

rg -n 'brandbook-fable/|prompts/mailglass-brand-book\.md' \
  CLAUDE.md \
  mailglass_admin/docs/design-system.md \
  mailglass_admin/assets/css/app.css \
  .planning/PROJECT.md \
  .planning/STATE.md \
  .planning/ROADMAP.md \
  .planning/REQUIREMENTS.md \
  .planning/MILESTONES.md \
  .planning/RETROSPECTIVE.md
```

Output:

```text
.planning/PROJECT.md:19:- CLAUDE.md "Brand & Voice" source-of-truth pointer moves to `brandbook/brand-book.md`.
.planning/PROJECT.md:458:| D-19 | Brand voice & visual identity locked to `brandbook/brand-book.md` | Brand discipline prevents drift toward generic SaaS or growth-marketing aesthetic; prompt-era research remains preserved as provenance | Superseded by v1.10 canonical adoption |
.planning/STATE.md:79:- [v1.10] Active brand voice and visual identity source is now `brandbook/brand-book.md`; prompt-era brand research remains preserved as provenance, not as an active source pointer.
.planning/ROADMAP.md:71:  2. No active tracked file outside provenance archives references the former fable staging path; the CLAUDE.md Brand & Voice source-of-truth pointer and `mailglass_admin/docs/design-system.md:5` both point at `brandbook/brand-book.md` (the v1.9 sweep proved these are the only tracked consumers)
.planning/REQUIREMENTS.md:30:  names `brandbook/brand-book.md`) and `mailglass_admin/docs/design-system.md:5`'s
```

The stale-pointer `rg` command printed no lines.

Protected provenance status check:

```bash
git status --short -- .planning/milestones .planning/research .planning/todos prompts/mailglass-brand-book.md
git status --short -- mailglass_admin/priv/static
```

Output:

```text
```

No active stale source pointer remains in the checked active files, and the
prompt-era brand book, planning archives, research records, todos, generated
admin static bundle, and milestone archives were left untouched.

## Adoption Diff Scope

Pending - recorded during Plan 91-04 using:

```bash
git diff --name-status "$PHASE_BASE" --
```

## Gate Run

Pending - recorded during Plan 91-04 after folder adoption and reference
reconciliation.

## Release Safety

Pending - recorded during Plan 91-04 after Phase 91 commits exist.

## Result

Wave 0 setup complete. Final result pending.
