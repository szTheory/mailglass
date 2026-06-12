# Phase 91: Folder Adoption and Reference Reconciliation - Pattern Map

**Mapped:** 2026-06-12
**Files analyzed:** 11 grouped targets
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `brandbook/**` replacing `brandbook-fable/**` | static artifact tree | file-I/O / transform | `brandbook-fable/README.md` + `brandbook-fable/brand-book.md` | exact |
| deleted old `brandbook/**` codex-only files | static artifact cleanup | file-I/O / transform | `git ls-files brandbook brandbook-fable` inventory | exact |
| `CLAUDE.md` | documentation / project guide | transform | existing `CLAUDE.md` Brand & Voice/current-state sections | exact |
| `mailglass_admin/docs/design-system.md` | documentation | transform | existing `mailglass_admin/docs/design-system.md` source-pointer intro | exact |
| `mailglass_admin/assets/css/app.css` | config / CSS source comment | transform | existing `mailglass_admin/assets/css/app.css` header and brand comments | exact |
| `.planning/PROJECT.md` | planning memory | transform | existing `.planning/PROJECT.md` v1.10 milestone + D-19 rows | exact |
| `.planning/STATE.md` | planning state | transform | existing `.planning/STATE.md` current focus / decisions / continuity | exact |
| `.planning/ROADMAP.md` | roadmap | transform | existing `.planning/ROADMAP.md` Phase 91 details | exact |
| `.planning/REQUIREMENTS.md` | requirements | transform | existing `.planning/REQUIREMENTS.md` FOLD requirements | exact |
| `.planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` | validation utility | batch / file-I/O | `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/gate.sh` | exact |
| `.planning/phases/91-folder-adoption-and-reference-reconciliation/91-gate-evidence.md` | verification evidence | batch / transform | `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/90-gate-evidence.md` | exact |

## Pattern Assignments

### `brandbook/**` replacing `brandbook-fable/**` (static artifact tree, file-I/O / transform)

**Analog:** `brandbook-fable/README.md`

**Folder contents pattern** (lines 10-19):

```markdown
| `index.html` | The brand book, rendered live: theme toggle, computed contrast matrix, real component gallery, logo system |
| `brand-book.md` | The text master — same nine sections, exact values, static contrast tables for both themes |
| `tokens.css` | The design tokens as CSS custom properties (`:root` light, `[data-theme="dark"]`, OS-preference media block) |
| `tokens.json` | The same values with raw palette names, for tooling |
| `assets/` | The eight logo assets — outlined paths, no live text, no font dependencies |
```

**Local-only artifact pattern** (lines 20-29):

```markdown
Open `index.html` in any browser, straight from disk. There is no server, no
build step, and no network request — the page is complete over `file://`.
```

**Asset rules pattern** (lines 31-44):

```markdown
- **The primary lockup lives on light grounds only.**
- **`favicon.svg` adapts on its own** — the pane flips for OS dark mode; the
  Glass seal holds in both themes.
- **Tokens are the only color source.**
- **Assets are outlined paths only** — no live text, no font references.
- **No background plate behind the mark.** The square social avatars are the
  sole exception.
```

**Implementation note:** Use Git operations, not manual copy. Preserve this exact artifact tree by moving tracked `brandbook-fable/` to `brandbook/` after removing the old tracked `brandbook/` tree and ignored leftovers.

---

### Deleted old `brandbook/**` codex-only files (static artifact cleanup, file-I/O / transform)

**Analog:** Current tracked inventory from `git ls-files brandbook brandbook-fable`

**Old-only absence pattern:** After adoption, these codex-era paths must not exist under canonical `brandbook/`:

```text
brandbook/assets/concepts/
brandbook/assets/options/
brandbook/brand-audit.md
brandbook/examples/palette.svg
brandbook/examples/typography.svg
brandbook/examples/ui-primitives.svg
brandbook/logo-concepts.html
brandbook/logo-concepts.md
brandbook/logo-creative-brief.md
brandbook/logo-options.md
```

**Preflight ignored-file pattern:** Current ignored leftovers are:

```text
!! brandbook-fable/.DS_Store
!! brandbook/.DS_Store
!! brandbook/assets/.DS_Store
```

**Implementation note:** Clear ignored leftovers before `git mv` so `brandbook-fable/` cannot move inside an existing `brandbook/` directory.

---

### `CLAUDE.md` (documentation / project guide, transform)

**Analog:** `CLAUDE.md`

**Current-state pointer pattern** (line 17):

```markdown
**Current state (as of 2026-06-12):** ... **v1.9 "Brand Book Fable" shipped 2026-06-12** — `brandbook-fable/` is the maintainer-approved A/B winner over the frozen codex `brandbook/` ...
```

**Brand source pattern** (lines 52-62):

```markdown
## Brand & Voice (applies to docs, errors, log messages, UI)

mailglass is **clear, exact, confident (not cocky), warm (not cute), modern (not trendy), technical (not intimidating)** — "a thoughtful maintainer."

Source of truth: `prompts/mailglass-brand-book.md`.
```

**Copy direction:** Update current-state prose to say the fable book is now canonical `brandbook/`; update the source-of-truth pointer to `brandbook/brand-book.md`. Keep release gotchas and historical v1.8/v1.9 context intact.

---

### `mailglass_admin/docs/design-system.md` (documentation, transform)

**Analog:** `mailglass_admin/docs/design-system.md`

**Intro pointer pattern** (lines 3-6):

```markdown
The reference for how the admin UI is built, so each component compounds the
same polish rather than re-deciding it. The voice and palette come from
`prompts/mailglass-brand-book.md`; this doc covers the *mechanics* — tokens,
motion, conformance, and how to audit them.
```

**Single-source rule pattern** (lines 8-11):

```markdown
> **One rule above all:** there is a single source of truth for every visual
> decision. Color lives in the daisyUI theme blocks; size / type / elevation /
> motion live in the `@theme` block and `:root` tokens.
```

**Copy direction:** Change only the active source pointer to `brandbook/brand-book.md`; do not broaden into admin visual changes.

---

### `mailglass_admin/assets/css/app.css` (config / CSS source comment, transform)

**Analog:** `mailglass_admin/assets/css/app.css`

**Header pointer pattern** (lines 1-3):

```css
/* mailglass_admin v0.1 - dev preview dashboard styles.
   Brand: prompts/mailglass-brand-book.md (Ink/Glass/Ice/Mist/Paper/Slate).
   Built by: mix mailglass_admin.assets.build  (zero Node toolchain). */
```

**Theme-token pattern** (lines 16-28):

```css
@plugin "../vendor/daisyui-theme" {
  name: "mailglass-light";
  default: true;
  prefersdark: false;
  color-scheme: "light";

  /* Brand book §7.3 — canonical palette mapped to daisyUI semantic tokens */
  --color-base-100: #F8FBFD;
  --color-primary: #277B96;
```

**Copy direction:** Update the source comment path only. Do not change token values or rebuild `priv/static/` unless execution changes compiled CSS beyond comments.

---

### `.planning/PROJECT.md` (planning memory, transform)

**Analog:** `.planning/PROJECT.md`

**Milestone intent pattern** (lines 11-19):

```markdown
## Current Milestone: v1.10 Brand Adoption

**Goal:** Make the A/B-winning fable brand the project's one canonical identity everywhere it shows: fold `brandbook-fable/` into `brandbook/` ...

**Target features:**
- Folder adoption: `brandbook-fable/` becomes canonical `brandbook/` via git mv ...
- CLAUDE.md "Brand & Voice" source-of-truth pointer moves from `prompts/mailglass-brand-book.md` to `brandbook/brand-book.md`.
```

**Decision row to supersede** (line 458):

```markdown
| D-19 | Brand voice & visual identity locked to `prompts/mailglass-brand-book.md` | Brand discipline prevents drift toward generic SaaS or growth-marketing aesthetic | ✓ Held v0.1 |
```

**Historical provenance pattern** (lines 414-420):

```markdown
**Prior research artifacts** (preserved in `prompts/`, source of truth for vocabulary + conventions):

- `mailglass-brand-book.md` — visual identity, voice, palette
```

**Copy direction:** Supersede D-19 for active brand identity with `brandbook/brand-book.md`; keep `prompts/` as historical/prior research where appropriate.

---

### `.planning/STATE.md` (planning state, transform)

**Analog:** `.planning/STATE.md`

**Current-position pattern** (lines 25-31):

```markdown
## Current Position

Phase: 91 — Folder Adoption and Reference Reconciliation (next up, not started)
Plan: —
Status: Context gathered — ready to plan Phase 91
Last activity: 2026-06-12 — Phase 91 context gathered (assumptions mode)
```

**Scope-lock pattern** (lines 52-64):

```markdown
## v1.10 Scope Locks

- No Hex release is cut by this milestone's commits: brand/docs commits use
  non-release-triggering types (`docs:`, `chore:`, `test:`) ...
- Planning archives (`.planning/milestones/`) are never edited.
```

**Decision-memory pattern** (lines 77-84):

```markdown
## Decisions

- [v1.10] Research pre-settled ... CLAUDE.md + `mailglass_admin/docs/design-system.md:5` are the only tracked reference-sweep targets.
- [D-25] v1.8 brand-system work is a repo-artifact milestone, not product expansion ...
```

**Copy direction:** Update live status and decisions to reflect canonical `brandbook/`; keep archive immutability and non-release commit constraints.

---

### `.planning/ROADMAP.md` (roadmap, transform)

**Analog:** `.planning/ROADMAP.md`

**Phase detail pattern** (lines 61-70):

```markdown
### Phase 91: Folder Adoption and Reference Reconciliation
**Goal**: The fable brand book is the project's one canonical `brandbook/` — the old codex book exists only in history, every tracked reference points at the new location, and the v1.9 quality gate proves nothing broke in the move
**Requirements**: FOLD-01, FOLD-02, FOLD-03
**Success Criteria** (what must be TRUE):
  1. `brandbook/` at the repo root contains the fable book ...
  2. No tracked file outside `.planning/milestones/` archives references `brandbook-fable/` ...
  3. The v1.9 quality gate (`gate.sh`, re-pathed) passes on the folder at its new location
  4. Every commit in the phase uses a non-release-triggering type (`chore:`/`docs:`) ...
```

**Copy direction:** Mark progress/status as needed after planning/execution; preserve the explicit criteria and phase boundaries.

---

### `.planning/REQUIREMENTS.md` (requirements, transform)

**Analog:** `.planning/REQUIREMENTS.md`

**FOLD requirements pattern** (lines 22-34):

```markdown
### FOLD — Folder Adoption

- [ ] **FOLD-01**: `brandbook-fable/` becomes canonical `brandbook/` via
  `git mv`; the codex book's files are removed in the same commit ...
- [ ] **FOLD-02**: Every tracked reference to `brandbook-fable/` or to the
  old brandbook's contents is reconciled ...
- [ ] **FOLD-03**: The v1.9 quality gate (gate.sh, re-pathed) passes on the
  folder at its new location.
```

**Traceability pattern** (lines 88-103):

```markdown
## Traceability

| FOLD-01 | Phase 91 | Pending |
| FOLD-02 | Phase 91 | Pending |
| FOLD-03 | Phase 91 | Pending |
```

**Copy direction:** Only update status/wording if execution state changes; do not touch Phase 92/93 requirements during Phase 91.

---

### `.planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` (validation utility, batch / file-I/O)

**Analog:** `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/gate.sh`

**Script contract pattern** (lines 1-18):

```bash
#!/usr/bin/env bash
# Runs ALL 9 checks per invocation (no early exit — one run reports everything),
# prints "CHECK-N PASS" or "CHECK-N FAIL: detail" per check, exits non-zero on
# any failure, and prints the sentinel GATE-PASS only when all 9 pass.

set -u
FAIL=0
BB="brandbook-fable"

fail() {
  echo "CHECK-$1 FAIL: $2"
  FAIL=1
}
```

**SVG/inventory pattern** (lines 26-45):

```bash
c1_ok=1
for f in "$BB"/assets/*.svg "$BB"/examples/*.svg; do
  if ! /usr/bin/xmllint --noout "$f" 2>/dev/null; then
    fail 1 "xmllint parse error in $f"
    c1_ok=0
  fi
done
assets_count=$(find "$BB/assets" -type f | wc -l | tr -d ' ')
examples_count=$(find "$BB/examples" -type f | wc -l | tr -d ' ')
[ "$c1_ok" -eq 1 ] && echo "CHECK-1 PASS"
```

**Local-reference and no-network pattern** (lines 62-91):

```bash
c3_ok=1
for html in index.html examples/landing-page.html examples/email-template.html; do
  file="$BB/$html"
  dir=$(dirname "$file")
  while IFS= read -r ref; do
    target="${ref%%#*}"
    [ -z "$target" ] && continue
    if [ ! -f "$dir/$target" ]; then
      fail 3 "$html references '$ref' which does not resolve ($dir/$target missing)"
      c3_ok=0
    fi
  done < <(grep -Eo '(href|src)="[^"]*"' "$file" | sed -E 's/^(href|src)="//; s/"$//')
done
```

**Denylist pattern** (lines 103-110):

```bash
DENY_BASE='phase|milestone|roadmap|tournament|codex|gsd|REQ-[0-9A-Z]|BOOK-0|DIF-[0-9]|CDX-|COLL-0|COPY-0|FOUND-0|LOGO-0|GATE-0|TODO|FIXME|lorem|placeholder|draft'
DENY_EXT='\bplans?\b|checkpoint|\bTBD\b|option-|variant-|\bbaseline\b'
deny_hits=$(grep -riE "$DENY_BASE|$DENY_EXT" "$BB"/ | grep -viE 'align-items:[[:space:]]*baseline' | wc -l | tr -d ' ')
```

**SVG structural checks pattern** (lines 116-154):

```bash
for f in "$BB"/assets/*.svg "$BB"/examples/*.svg; do
  text_n=$(grep -c '<text' "$f" || true)
  font_n=$(grep -ic 'font-family' "$f" || true)
  if [ "$text_n" -ne 0 ] || [ "$font_n" -ne 0 ]; then
    fail 5 "$f contains live text/fonts (<text x$text_n, font-family x$font_n)"
  fi
done
```

**Exit sentinel pattern** (lines 222-229):

```bash
if [ "$FAIL" -eq 0 ]; then
  echo "GATE-PASS"
  exit 0
else
  echo "GATE-FAIL"
  exit 1
fi
```

**Adaptation direction:** Copy checks 1-8 materially intact and set `BB="brandbook"`. Replace lines 190-220 with Phase 91 adoption invariants: `brandbook-fable/` absent, `brandbook/brand-book.md` present, no tracked `brandbook-fable` files, old codex-only files absent, `.DS_Store` remains untracked/ignored, active pointers use `brandbook/brand-book.md`, and diff scope stays within approved rename/reference/gate/planning evidence work.

---

### `.planning/phases/91-folder-adoption-and-reference-reconciliation/91-gate-evidence.md` (verification evidence, batch / transform)

**Analog:** `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/90-gate-evidence.md`

**Header metadata pattern** (lines 1-7):

```markdown
# Phase 90 Gate Evidence — brandbook-fable/ (GATE-01 + GATE-02)

- **Date:** 2026-06-11
- **HEAD:** `106229bd`
- **Gate script:** `.planning/phases/90-quality-gate-and-uat/gate.sh` (run from repo root)
- **Frozen codex baseline:** `09a84dd4`
```

**Verbatim gate output pattern** (lines 18-36):

````markdown
## Scripted Gate Runs (GATE-01)

### Run 1 — 2026-06-11, HEAD 106229bd — verbatim output

```
CHECK-1 PASS
CHECK-2 PASS
...
GATE-PASS
```

Exit code: 0.
````

**Check summary table pattern** (lines 38-48):

```markdown
| Check | What it proves | Result |
|---|---|---|
| 1 | All 12 SVGs xmllint-parse; inventory exactly 8 assets + 6 examples (4 SVG + 2 HTML) | PASS |
| 9 | Tree clean outside .planning/; frozen brandbook/ identical to 09a84dd4; nothing outside brandbook-fable/ + .planning/ changed in 09a84dd4..HEAD | PASS |
```

**Phase 91 evidence direction:** Record ignored-file preflight, Git move/removal proof, phase-local gate output, active `rg` sweeps, and release-safety proof. Do not add browser screenshots unless rendered brandbook content changes.

## Shared Patterns

### Active Reference Reconciliation

**Source:** `CLAUDE.md`, `mailglass_admin/docs/design-system.md`, `mailglass_admin/assets/css/app.css`
**Apply to:** All active pointer edits

```bash
rg -n 'brandbook-fable|prompts/mailglass-brand-book\.md' \
  CLAUDE.md mailglass_admin/docs/design-system.md mailglass_admin/assets/css/app.css \
  .planning/PROJECT.md .planning/STATE.md .planning/ROADMAP.md .planning/REQUIREMENTS.md
```

Use exact active-path sweeps. Do not rewrite `.planning/milestones/**`, historical research records, completed todos, generated docs, vendored baselines, or `prompts/mailglass-brand-book.md` for grep cleanliness.

### Release Safety

**Source:** `.github/workflows/pr-title.yml`, `release-please-config.json`, `.github/workflows/ci.yml`
**Apply to:** Commit planning and evidence

```yaml
# .github/workflows/pr-title.yml lines 21-32
types: |
  feat
  fix
  docs
  style
  refactor
  perf
  test
  build
  ci
  chore
  revert
```

```json
// release-please-config.json lines 3-9
"packages": {
  ".": {
    "package-name": "mailglass",
    "release-type": "elixir",
    "component": "mailglass"
  }
}
```

```yaml
# .github/workflows/ci.yml lines 6-13
paths-ignore:
  - ".planning/**"
  - "prompts/**"
```

Use only `chore:` and `docs:` for Phase 91 commits. Do not add release-hardening lint in this phase; RELH-01 belongs to Phase 93.

### Planning Archive Immutability

**Source:** `.planning/ROADMAP.md` lines 25-35 and `.planning/STATE.md` lines 52-64
**Apply to:** Planning memory edits and reference sweeps

```markdown
- **Planning archives (`.planning/milestones/`) are never edited.**
```

Live planning files may be updated: `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`. Archived milestones are provenance.

### Gate Check Shape

**Source:** `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/gate.sh`
**Apply to:** Phase 91 `gate.sh`

Keep the all-checks/no-early-exit contract: every check prints PASS/FAIL, `FAIL` accumulates, and only the final sentinel reports `GATE-PASS` or `GATE-FAIL`.

## No Analog Found

All Phase 91 targets have close analogs in the codebase. No planner fallback to external research patterns is required.

## Metadata

**Analog search scope:** `brandbook/`, `brandbook-fable/`, `CLAUDE.md`, `mailglass_admin/docs/`, `mailglass_admin/assets/css/`, `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/milestones/v1.9-phases/90-quality-gate-and-uat/`, `.github/workflows/`, `release-please-config.json`

**Files scanned:** 17 directly read/scanned files plus tracked brandbook inventories
**Pattern extraction date:** 2026-06-12
