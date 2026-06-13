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

Command:

```bash
PHASE_BASE=$(sed -n 's/.*Phase base: `\([0-9a-f][0-9a-f]*\)`.*/\1/p' .planning/phases/91-folder-adoption-and-reference-reconciliation/91-gate-evidence.md | head -1)
git diff --name-status "$PHASE_BASE" --
```

Output:

```text
PHASE_BASE=63701373af556a6c4fbc9d48f0d1a2d7c31782fb
M	.planning/MILESTONES.md
M	.planning/PROJECT.md
M	.planning/REQUIREMENTS.md
M	.planning/RETROSPECTIVE.md
M	.planning/ROADMAP.md
M	.planning/STATE.md
A	.planning/phases/91-folder-adoption-and-reference-reconciliation/91-01-SUMMARY.md
A	.planning/phases/91-folder-adoption-and-reference-reconciliation/91-02-SUMMARY.md
A	.planning/phases/91-folder-adoption-and-reference-reconciliation/91-03-SUMMARY.md
M	.planning/phases/91-folder-adoption-and-reference-reconciliation/91-VALIDATION.md
A	.planning/phases/91-folder-adoption-and-reference-reconciliation/91-gate-evidence.md
M	CLAUDE.md
D	brandbook-fable/README.md
D	brandbook-fable/assets/favicon.svg
D	brandbook-fable/assets/logo-mark.svg
D	brandbook-fable/assets/logo-monochrome.svg
D	brandbook-fable/assets/logo-primary.svg
D	brandbook-fable/assets/social-avatar.svg
D	brandbook-fable/brand-book.md
D	brandbook-fable/examples/docs-page.svg
D	brandbook-fable/examples/readme-header.svg
D	brandbook-fable/index.html
D	brandbook-fable/tokens.css
D	brandbook-fable/tokens.json
M	brandbook/README.md
D	brandbook/assets/concepts/concept-07r-no-idot-01-natural-lockup.svg
D	brandbook/assets/concepts/concept-07r-no-idot-02-tighter-gap.svg
D	brandbook/assets/concepts/concept-07r-no-idot-03-larger-mark.svg
D	brandbook/assets/concepts/concept-07r-no-idot-04-larger-wordmark.svg
D	brandbook/assets/concepts/concept-07r-no-idot-05-raised-baseline.svg
D	brandbook/assets/concepts/concept-07r-no-idot-06-lower-baseline.svg
D	brandbook/assets/concepts/concept-07r-no-idot-07-mono-first.svg
D	brandbook/assets/concepts/concept-07r-no-idot-08-black-bg-native.svg
D	brandbook/assets/concepts/concept-07r-no-idot-09-small-header.svg
D	brandbook/assets/concepts/concept-07r-no-idot-10-final-synthesis.svg
D	brandbook/assets/concepts/concept-07r-pane-rhythm-bold-type.svg
M	brandbook/assets/favicon.svg
M	brandbook/assets/logo-mark.svg
M	brandbook/assets/logo-monochrome.svg
M	brandbook/assets/logo-primary.svg
R100	brandbook-fable/assets/logo-typemark.svg	brandbook/assets/logo-typemark.svg
R100	brandbook-fable/assets/logo-with-tagline.svg	brandbook/assets/logo-with-tagline.svg
D	brandbook/assets/options/option-a-folded-pane.svg
D	brandbook/assets/options/option-b-pane-lines.svg
D	brandbook/assets/options/option-c-inspection-pane.svg
D	brandbook/assets/options/option-d-wordmark-aperture.svg
D	brandbook/assets/options/option-e-mg-header-mark.svg
D	brandbook/assets/options/option-f-wordmark-trace.svg
D	brandbook/assets/options/option-g-header-checksum.svg
D	brandbook/assets/options/option-h-console-row.svg
D	brandbook/assets/options/option-i-inline-source-cursor.svg
D	brandbook/assets/options/option-j-negative-at-lens.svg
D	brandbook/assets/options/option-k-header-stack-mark.svg
D	brandbook/assets/options/option-l-source-diff.svg
D	brandbook/assets/options/option-m-protocol-brackets.svg
D	brandbook/assets/options/option-n-transparent-routing-node.svg
D	brandbook/assets/options/option-o-delivery-timeline.svg
D	brandbook/assets/options/option-p-normalized-event-pulse.svg
D	brandbook/assets/options/option-q-glass-caliper.svg
D	brandbook/assets/options/option-r-refraction-line.svg
R100	brandbook-fable/assets/social-avatar-dark.svg	brandbook/assets/social-avatar-dark.svg
M	brandbook/assets/social-avatar.svg
D	brandbook/brand-audit.md
M	brandbook/brand-book.md
R100	brandbook-fable/copy/copy-blocks.md	brandbook/copy/copy-blocks.md
R100	brandbook-fable/copy/microcopy.md	brandbook/copy/microcopy.md
R100	brandbook-fable/examples/diagram-language.svg	brandbook/examples/diagram-language.svg
M	brandbook/examples/docs-page.svg
R100	brandbook-fable/examples/email-template.html	brandbook/examples/email-template.html
R100	brandbook-fable/examples/landing-page.html	brandbook/examples/landing-page.html
R100	brandbook-fable/examples/og-card.svg	brandbook/examples/og-card.svg
D	brandbook/examples/palette.svg
M	brandbook/examples/readme-header.svg
D	brandbook/examples/typography.svg
D	brandbook/examples/ui-primitives.svg
M	brandbook/index.html
D	brandbook/logo-concepts.html
D	brandbook/logo-concepts.md
D	brandbook/logo-creative-brief.md
D	brandbook/logo-options.md
M	brandbook/tokens.css
M	brandbook/tokens.json
M	mailglass_admin/assets/css/app.css
M	mailglass_admin/docs/design-system.md
```

The diff is limited to the approved Phase 91 scope: canonical `brandbook/`
replacement, deleted/renamed former fable source paths, active pointer files,
live planning memory, and Phase 91 planning/evidence artifacts.

## Gate Run

Command:

```bash
bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh
```

Output:

```text
CHECK-1 PASS
CHECK-2 PASS
CHECK-3 PASS
CHECK-4 PASS
CHECK-5 PASS
CHECK-6 PASS
CHECK-7 PASS (folder 248 KB, index.html 79789 B)
CHECK-8 PASS (2 shape elements, 16x16 viewBox)
CHECK-9 PASS
GATE-PASS
```

Exit code: 0

Final active stale-reference sweeps:

```bash
rg --hidden -n 'brandbook-fable/' \
  --glob '!.git/**' \
  --glob '!.planning/milestones/**' \
  --glob '!.planning/research/**' \
  --glob '!.planning/phases/91-folder-adoption-and-reference-reconciliation/**' \
  --glob '!.planning/todos/**' \
  --glob '!prompts/**' \
  --glob '!_build/**' \
  --glob '!doc/**' \
  --glob '!mailglass_admin/_build/**' \
  --glob '!mailglass_admin/doc/**' \
  --glob '!mailglass_inbound/_build/**' \
  --glob '!mailglass_inbound/doc/**' \
  --glob '!reference/**/_build/**' \
  --glob '!reference/**/doc/**'

rg -n 'prompts/mailglass-brand-book\.md' \
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
```

Both final stale-reference sweeps printed no lines.

## Release Safety

Command:

```bash
BASE=$(sed -n 's/.*Phase base: `\([0-9a-f][0-9a-f]*\)`.*/\1/p' .planning/phases/91-folder-adoption-and-reference-reconciliation/91-gate-evidence.md | head -1)
git log --no-merges --format=%s "$BASE"..HEAD
```

Output:

```text
BASE=63701373af556a6c4fbc9d48f0d1a2d7c31782fb
docs(91-04): complete final evidence plan
docs(91-04): record release safety proof
docs(91-04): record final adoption gate evidence
docs(91-03): complete reference reconciliation plan
docs(91-03): reconcile live brand planning memory
docs(91-03): point active brand docs at canonical brandbook
docs(91-02): complete brandbook folder adoption plan
chore(91-02): adopt fable brandbook folder
chore(91-02): record brandbook preflight cleanup
docs(91-01): complete adoption gate plan
chore(91-01): record phase gate evidence contract
```

Validation:

```bash
git log --no-merges --format=%s "$BASE"..HEAD | awk 'NF && $0 !~ /^(chore|docs)(\([^)]*\))?: / {print; bad=1} END {exit bad}'
git log --no-merges --format=%s "$BASE"..HEAD | grep -E '^(feat|fix|deps)(\(|:)|!|BREAKING CHANGE|Release-As'
```

The `awk` validation exited 0. The forbidden-subject grep printed no lines.

GitHub Release Please PR check:

```bash
gh pr list --state open --search 'release-please in:title' --limit 20 --json number,title --template '{{len .}}'
```

Output:

```text
0
```

No open Release Please PR exists for these Phase 91 commits.

## Result

Wave 0 setup complete. Final result pending.
