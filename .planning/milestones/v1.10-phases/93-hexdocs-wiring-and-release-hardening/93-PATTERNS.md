# Phase 93: HexDocs Wiring and Release Hardening - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 9 (1 new workflow, 3 mix.exs docs/0, 1 config, 1 manifest + 3 @version + 2 pins, 2 SVGs)
**Analogs found:** 9 / 9 (every new/modified file has an in-repo analog)

This is a config/infrastructure phase — there are no controller/service/component
roles. Files classify as `workflow`, `config`, `mix-config`, and `asset`. "Data
flow" is replaced by the operative concern (CI-event, release-trigger, doc-build,
version-pin). Every edit is **additive or value-replacement against an existing
shape** — no new architecture. Extract the surrounding shape and match it exactly.

## File Classification

| New/Modified File | Role | Concern | Closest Analog | Match Quality |
|-------------------|------|---------|----------------|---------------|
| `.github/workflows/guard-release-trigger.yml` (NEW) | workflow | CI-event / release-trigger guard | `.github/workflows/pr-title.yml` (trigger + permissions + SHA-pin) + `.github/workflows/ci.yml` (job shape, `gh`/token, the `paths-ignore` to OMIT) | composite — two analogs |
| `mix.exs` `docs/0` (root, line 355) | mix-config | doc-build (add `logo:`/`favicon:`) | itself + the other two `docs/0` | exact (3 siblings) |
| `mailglass_admin/mix.exs` `docs/0` (line 214) | mix-config | doc-build | root `mix.exs` `docs/0` | exact |
| `mailglass_inbound/mix.exs` `docs/0` (line 147) | mix-config | doc-build | root `mix.exs` `docs/0` | exact |
| `release-please-config.json` (root `.` entry) | config | release-trigger (add `exclude-paths`) | the existing `.` package entry block | exact |
| `.release-please-manifest.json` (3 versions) | config | version-align | the file itself (value replace) | exact |
| `mix.exs:4` / `admin:4` / `inbound:4` `@version` | mix-config | version-align | each other | exact (3 siblings) |
| `mailglass_admin/mix.exs:142` + `mailglass_inbound/mix.exs:127` pins | mix-config | version-pin (the `fix(inbound):` dance) | each other (identical pin shape) | exact |
| `brandbook/assets/logo-mark.svg` + `favicon.svg` root `<svg>` | asset | add `width`/`height` | each other (same root-element shape) | exact |

## Pattern Assignments

### `.github/workflows/guard-release-trigger.yml` (NEW workflow, CI-event / release-trigger guard)

**Primary analog:** `.github/workflows/pr-title.yml` (trigger model, permissions, SHA-pin convention)
**Secondary analog:** `.github/workflows/ci.yml` (job/step shape, `gh`/token usage, the `paths-ignore` block this workflow must NOT copy)
**Lint logic:** 93-RESEARCH.md Open Item 1 (the shell script — copy verbatim; do not re-derive)

**Header + trigger pattern — adapt from `pr-title.yml` lines 1-9, but use plain `pull_request` (NOT `pull_request_target`) and OMIT `paths-ignore`:**

`pr-title.yml` current shape:
```yaml
name: PR Title

on:
  pull_request_target:
    branches: [main]
    types: [opened, edited, synchronize, reopened]

permissions:
  pull-requests: read
```

**What to replicate vs. change (per 93-RESEARCH.md Open Item 1 "Placement"/"Trigger choice"):**
- Use `name:` + `on:` + `permissions:` top-level block in this exact order (matches both analogs).
- Use **`pull_request`** (not `pull_request_target` — research §94: this repo is single-maintainer, no fork PRs, so the plain, lower-risk trigger is sufficient and the lint needs no secrets/write).
- Keep `branches: [main]` and the same `types:` list (title edits must re-trigger, so include `edited`).
- **DELIBERATELY OMIT `paths-ignore`.** This is the load-bearing inversion of `ci.yml` lines 6-13 / 11-13 — the guard must run on brand/planning-only PRs that `ci.yml` skips.
- Permissions: `pull-requests: read` (read PR title) plus `contents: read`. `pr-title.yml` declares only `pull-requests: read`; this workflow also runs `gh pr view ... --json files`, which the default `GITHUB_TOKEN` with `pull-requests: read` covers.

**Job + step + SHA-pin + token pattern — from `ci.yml` lines 28-44 (the canonical checkout + step shape and the SHA-pin convention):**
```yaml
jobs:
  format_check:
    name: Format Check (Elixir 1.18 / OTP 27)
    runs-on: ubuntu-latest
    ...
    steps:
      - name: Checkout
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd  # v6.0.2
```

**SHA-pin convention (CLAUDE.md non-negotiable, confirmed in 93-RESEARCH.md "Project Constraints"):** every third-party action is pinned to a full commit SHA with a `# vX.Y.Z` trailing comment. Use only `actions/checkout` (SHA-pinned, copy the exact `de0fac2e4500dabe0009e67214ff5f5447ce83dd  # v6.0.2` line if a checkout is needed) + preinstalled `gh`. Do NOT add a new marketplace action (research favors the shell-script form).

**`gh` / token usage pattern (from the research script, lines 107-174):** the script reads `PR_TITLE`/`PR_NUMBER` from the `pull_request` event context and calls `gh pr view "$PR_NUMBER" --json files --jq '.files[].path'`. `gh` authenticates via `GH_TOKEN`/`GITHUB_TOKEN` env — set `env: { GH_TOKEN: ${{ secrets.GITHUB_TOKEN }} }` on the step (mirrors how `pr-title.yml` passes `GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}` at lines 18-19). Note: `actions/checkout` is NOT strictly required for `gh pr view` (it queries the API), but a checkout is harmless if the script is committed as a file rather than inlined.

**Lint body:** transcribe the bash from 93-RESEARCH.md Open Item 1 "Check logic" (lines 107-175) verbatim — `set -euo pipefail`, the `GUARDED=( "brandbook/" ".planning/" "prompts/" )` array, the conventional-commit title regex, the `is_bump` case, the changed-files subset test, and the `::error::` failure block. The five-row edge-case table (research lines 179-185) is the acceptance spec.

---

### `mix.exs` `docs/0` (root, line 355) — mix-config, doc-build

**Analog:** the `docs/0` function itself (all three are siblings; the root is the most complete reference).

**Current shape (lines 355-360, head of the keyword list — this is where `logo:`/`favicon:` get added):**
```elixir
defp docs do
  [
    main: "getting-started",
    homepage_url: @source_url,
    source_url: @source_url,
    source_ref: "v#{@version}",
    skip_undefined_reference_warnings_on: [
      ...
```

**Confirmed:** no `logo:`, `favicon:`, or `assets:` key exists anywhere in this list today (verified to line 392; matches ADOPTION-MECHANICS.md §1). Add `logo:` / `favicon:` as additional top-level keys in this keyword list (idiomatic placement: alongside `main:`/`source_url:` near the top, before the large `extras:` list).

**Path values (D-03, ADOPTION-MECHANICS.md §1 "Path resolution"):**
```elixir
logo: "brandbook/assets/logo-mark.svg",
favicon: "brandbook/assets/favicon.svg",
```
(Root package: paths are relative to the package dir = repo root, so NO `../` prefix.)

---

### `mailglass_admin/mix.exs` `docs/0` (line 214) — mix-config, doc-build

**Analog:** root `mix.exs` `docs/0`.

**Current shape (lines 214-218):**
```elixir
defp docs do
  [
    main: "MailglassAdmin",
    source_url: @source_url,
    source_ref: "v" <> @version,
    extras: [
      ...
```

**Add (D-03 — sibling package, so `../` prefix into canonical `brandbook/`):**
```elixir
logo: "../brandbook/assets/logo-mark.svg",
favicon: "../brandbook/assets/favicon.svg",
```
Insert after `source_ref:` / before `extras:`. No `:files` allowlist change (ex_doc auto-copies into doc output — D-03, ADOPTION-MECHANICS.md §1).

---

### `mailglass_inbound/mix.exs` `docs/0` (line 147) — mix-config, doc-build

**Analog:** root `mix.exs` `docs/0`.

**Current shape (lines 147-151):**
```elixir
defp docs do
  [
    main: "MailglassInbound",
    source_url: @source_url,
    source_ref: "v" <> @version,
    extras: [
      ...
```

**Add (sibling package, `../` prefix — identical to admin):**
```elixir
logo: "../brandbook/assets/logo-mark.svg",
favicon: "../brandbook/assets/favicon.svg",
```
Insert after `source_ref:` / before `extras:`.

---

### `release-please-config.json` — config, release-trigger (add `exclude-paths`)

**Analog:** the existing root `"."` package entry block (lines 4-9).

**Current root entry:**
```json
".": {
  "package-name": "mailglass",
  "release-type": "elixir",
  "component": "mailglass",
  "changelog-path": "CHANGELOG.md"
},
```

**Add `exclude-paths` as a sibling key inside this object (JSON style: 6-space indent matching the existing keys, comma after the now-non-final `changelog-path` line):**
```json
"exclude-paths": ["brandbook", ".planning", "prompts", "mailglass_admin", "mailglass_inbound"]
```

**Style/semantics notes (93-RESEARCH.md Open Item 1 + caveat line 82):**
- Bare directory names, **no leading `./`, no trailing `/`** — matches how `component`/package paths are written elsewhere in the schema.
- Research recommends all five paths (the three brand/planning dirs PLUS `mailglass_admin`/`mailglass_inbound`) so the root `.` only releases for genuine core changes — this also stops the second proven 1.6.x trigger (`fix(inbound):` bumping core). This is the SECONDARY mechanism; the CI workflow is primary (D-09).
- File already declares `"$schema"` (line 30) — `exclude-paths` is schema-valid per-package.

---

### `.release-please-manifest.json` + 3 `@version` + 2 pins — mix-config/config, version-align (RELH-02)

**Reconciliation truth (93-RESEARCH.md Open Item 2 — Hex is authoritative): 1.6.2 / 1.6.2 / 1.3.1, inbound pins core `== 1.6.2`.** In-repo is STALE at 1.6.1/1.6.1/1.3.0. The release-state memory was CORRECT. The train HAS settled — D-13 stop-short does NOT apply.

**Manifest — current (whole file):**
```json
{
  ".": "1.6.1",
  "mailglass_admin": "1.6.1",
  "mailglass_inbound": "1.3.0"
}
```
**Target:** `"."` → `"1.6.2"`, `"mailglass_admin"` → `"1.6.2"`, `"mailglass_inbound"` → `"1.3.1"`.

**The three `@version` lines (all at line 4 of each mix.exs):**
- `mix.exs:4` — `@version "1.6.1"` → `"1.6.2"`
- `mailglass_admin/mix.exs:4` — `@version "1.6.1"` → `"1.6.2"`
- `mailglass_inbound/mix.exs:4` — `@version "1.3.0"` → `"1.3.1"`

**The two `{:mailglass, "== x.y.z"}` pins — both currently `== 1.6.1`, both → `== 1.6.2`:**
- `mailglass_admin/mix.exs:142` (inside `mailglass_dep/0`, guarded by `MIX_PUBLISH == "true"`)
- `mailglass_inbound/mix.exs:127` (inside `mailglass_dep/0`)

**BINDING comment block to respect — `mailglass_inbound/mix.exs` lines 114-124 (quote it; do NOT delete/edit it):**
```elixir
# Published builds pin the exact core version this inbound release was cut
# against (linked-release tracking). Bumping this pin must land as a
# `fix(inbound):` commit — chore/docs commits do NOT trigger a Release Please
# inbound bump, which would leave adopters on a stale `== <prev>` pin while
# core advances. Dev/test resolves the sibling via the local path dep.
#
# Note: the release workflow's sed step may pre-sync this pin line inside a
# core/admin release commit (a `chore`), which updates the pin in git WITHOUT
# cutting an inbound release — the published inbound then still carries the
# previous pin and blocks dependency resolution beside the new core. A
# `fix(inbound):` release is required either way to ship the new pin to Hex.
```

**The admin pin has its own comment (`mailglass_admin/mix.exs` lines 126-139)** explaining the literal-not-interpolation reason and the release-please sed sync — leave it intact; only the `"== 1.6.1"` literal on line 142 changes.

**Ordering / commit-type discipline (93-RESEARCH.md Open Item 2 "Commit typing", "Ordering constraint"):**
- This is a **catch-up to already-published Hex**, NOT a new release. Core 1.6.2 IS published → pinning `== 1.6.2` is safe (never pin to an unpublished core — that reds main via the docs-contract/installer-smoke resolution jobs).
- Use **non-bumping commit types** so this phase cuts nothing: `chore(release): align in-repo manifest + @version + dep pins to released 1.6.2/1.6.2/1.3.1` for the manifest+mix.exs edits; `docs(state): correct release-state memory to 1.6.2/1.6.2/1.3.1` for `.planning` docs.
- Tags: `git fetch --tags origin` then **KEEP** (1.6.1/1.6.2 package tags are real published releases on `origin`, just un-fetched locally) — do NOT delete. Annotate-and-document the `mailglass_admin-v1.6.1`-tag-without-Hex-publish quirk.
- Cross-check vs. RELH-01 lint: a `chore(release):` PR touching `mix.exs`/manifest (real package files, non-bumping) passes trivially; a `docs(state):` `.planning`-only PR passes at the non-bumping short-circuit. No conflict landing both requirements in this phase.

---

### `brandbook/assets/logo-mark.svg` + `favicon.svg` — asset, add `width`/`height` (HEXD-01 / D-02)

**Analog:** each other (identical root-`<svg>`-element shape).

**`logo-mark.svg` current root element (line 1):**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="-12 32 164 156" role="img" aria-labelledby="mg-fable-mark-title mg-fable-mark-desc">
```
**Add `width="164" height="156"`** (matches the `viewBox` 164×156 extent — D-02). Idiomatic placement: immediately after `xmlns` and before `viewBox` (or right after `viewBox`). Discretion on exact attribute ordering (CONTEXT.md "Claude's Discretion").

**`favicon.svg` current root element (line 1):**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" role="img" aria-labelledby="mg-fable-favicon-title mg-fable-favicon-desc">
```
**Add `width="16" height="16"`** (matches `viewBox` 0 0 16 16 — D-02).

**Constraint (D-02, ADOPTION-MECHANICS.md §1 "Critical gap"):** edit the canonical SVGs in place — do NOT create ex_doc-only duplicate copies. ex_doc 0.40.1 requires explicit `width`/`height`/`viewBox` on SVGs used as `logo:`/`favicon:` for predictable 48×48 sizing. Both files are outlined-path SVGs, so no font-substitution concern. Existing `<img>`/`<link rel="icon">` embeds override intrinsic size, so adding these attributes is safe for current consumers.

## Shared Patterns

### SHA-pinned third-party actions (applies to: the new workflow)
**Source:** `.github/workflows/ci.yml:39` and `.github/workflows/pr-title.yml:17`
**Apply to:** `guard-release-trigger.yml`
Every `uses:` is a full commit SHA + `# vX.Y.Z` comment. Dependabot watches `.github/workflows/`. Prefer `gh` (preinstalled) + at most `actions/checkout` over any new marketplace action.
```yaml
uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd  # v6.0.2
```

### `name:` → `on:` → `permissions:` top-level block (applies to: the new workflow)
**Source:** `.github/workflows/pr-title.yml:1-9`, `.github/workflows/ci.yml:1-26`
**Apply to:** `guard-release-trigger.yml`
Least-privilege `permissions:` declared at top level (`pull-requests: read` / `contents: read`). `branches: [main]`.

### Non-bumping commit-type discipline (applies to: ALL Phase 93 commits)
**Source:** CLAUDE.md "Commit & Branch Conventions" + `mailglass_inbound/mix.exs:114-124` comment + 93-RESEARCH.md
**Apply to:** every edit in this phase
This phase cuts NO Hex release. All mix.exs/SVG/config edits land as `docs:`/`chore:`/`docs(state):`/`chore(release):` (release-please defaults: non-bumping, no release PR). `docs(state):` for STATE.md updates skips CI path filters. The `fix(inbound):` type is reserved for actually SHIPPING a new inbound pin to Hex — not used here (the 1.6.2 pin is catch-up to an already-published artifact).

### ex_doc auto-copy → no `:files` allowlist churn (applies to: all three `docs/0` edits)
**Source:** ADOPTION-MECHANICS.md §1 "Path resolution" + D-03
**Apply to:** root/admin/inbound mix.exs
`logo:`/`favicon:` are auto-copied by ex_doc into `doc/assets/`; the Hex tarball does not need the source. Do NOT touch any package's `files:` list (root `mix.exs:345-353`, admin `:210`, inbound `:143` stay untouched) — the publish-allowlist `*-files.expected` proofs stay green.

## No Analog Found

None. Every file in this phase modifies or directly mirrors an existing in-repo
shape. The single NEW file (`guard-release-trigger.yml`) is a composite of two
existing workflow analogs plus a research-supplied shell body — no greenfield
pattern is required.

## Metadata

**Analog search scope:** `.github/workflows/`, root + `mailglass_admin/` + `mailglass_inbound/` `mix.exs`, `release-please-config.json`, `.release-please-manifest.json`, `brandbook/assets/`.
**Files scanned:** 11 (read in full or in targeted, non-overlapping ranges).
**Pattern extraction date:** 2026-06-13
