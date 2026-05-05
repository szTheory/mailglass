---
phase: 08-release-engineering-hardening
plan: "02"
subsystem: docs-hygiene
tags: [hexdocs, mix-task, ci, guides, rel-02]
dependency_graph:
  requires: []
  provides: [mix-mailglass-docs-check, hexdocs-claude-md-removed]
  affects: [.github/workflows/ci.yml, mix.exs, mailglass_admin/mix.exs, guides/webhooks.md]
tech_stack:
  added: []
  patterns: [mix-task-grep-gate, boundary-classify-to]
key_files:
  created:
    - lib/mix/tasks/mailglass.docs.check.ex
  modified:
    - mix.exs
    - guides/webhooks.md
    - .github/workflows/ci.yml
decisions:
  - "CLAUDE.md removed from mix.exs extras/groups_for_extras/skip_undefined_reference_warnings_on; file stays on disk"
  - "D-NN tokens in guides replaced with prose descriptions preserving full meaning"
  - "docs.check step added to existing docs_warnings_as_errors CI job (no new job needed)"
  - "mailglass_admin/mix.exs had no CLAUDE.md references — already clean"
metrics:
  duration: "~12 minutes"
  completed: "2026-04-26"
  tasks_completed: 2
  files_modified: 4
  files_created: 1
---

# Phase 8 Plan 2: HexDocs Hygiene (REL-02) Summary

Closed REL-02 in two tasks: removed CLAUDE.md from HexDocs publication surfaces in `mix.exs`, stripped 11 D-NN internal-ID tokens from `guides/webhooks.md`, and created `Mix.Tasks.Mailglass.Docs.Check` as a CI-wired grep gate that fails the build on any future leak.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Remove CLAUDE.md from mix.exs HexDocs surfaces | cee469a | mix.exs |
| 2 | Strip D-NN tokens, create docs.check Mix task, wire CI | ce18e06 | lib/mix/tasks/mailglass.docs.check.ex, guides/webhooks.md, .github/workflows/ci.yml |

## D-NN / LINT-NN Token Strip Results

**Scan before execution:**
```
grep -rnE '\b(D-[0-9]{2,3}|LINT-[0-9]{2})\b' guides/
```

| File | Tokens found | Tokens after |
|------|-------------|-------------|
| guides/webhooks.md | 11 (all D-NN) | 0 |
| guides/getting-started.md | 0 | 0 |
| guides/migration-from-swoosh.md | 0 | 0 |
| guides/configuration.md | 0 | 0 |
| guides/installer.md | 0 | 0 |
| guides/observability.md | 0 | 0 |
| guides/security.md | 0 | 0 |
| guides/testing.md | 0 | 0 |
| guides/authoring-mailables.md | 0 | 0 |
| guides/components.md | 0 | 0 |
| guides/multi-tenancy.md | 0 | 0 |
| guides/preview.md | 0 | 0 |
| guides/telemetry.md | 0 | 0 |

**Total stripped: 11 D-NN tokens from guides/webhooks.md. LINT-NN tokens: 0 anywhere.**

Replacement strategy for each token (meaning preserved):
- `(D-12)` in section heading → removed bare ID, section name unchanged
- `(D-13 "verify-first...")` → removed ID, kept the quoted rule text
- `D-23 whitelist` → "telemetry PII policy"
- `per D-21` (two occurrences) → "closed atom set" / module ref
- `(D-25)` in recipe heading → removed, recipe name unchanged
- `D-23` in code comment → "telemetry PII policy"
- `per D-23` in prose → "telemetry PII policy"
- `per D-04` in section heading → removed
- `(D-18 — append, never UPDATE)` → "append-only ledger — never UPDATE"
- `(D-16)` inline → removed, knob description unchanged
- `(D-29)` in section heading → removed, section name unchanged
- `D-21 atoms` in table → replaced with `Mailglass.SignatureError.__types__/0` module reference

## New Mix Task

**Module:** `Mix.Tasks.Mailglass.Docs.Check`
**File:** `lib/mix/tasks/mailglass.docs.check.ex`
**CLI shape:**
```
mix mailglass.docs.check
mix mailglass.docs.check --path "guides/**/*.md"
```

Key properties:
- `use Boundary, classify_to: Mailglass` — Boundary classification per shared patterns
- `@banned_patterns [~r/\bD-\d{2,3}\b/, ~r/\bLINT-\d{2}\b/]` — exact regex from plan
- All `Mix.raise/1` messages start with `"Delivery blocked: "` — brand voice per CLAUDE.md
- Exits 0 with `[mailglass.docs.check] OK — ...` on clean run
- Exits non-zero with per-leak error lines + `Delivery blocked: N internal ID(s) leaked` on failure

## CI Wiring

**Job:** `docs_warnings_as_errors` (existing lightweight job, no DB required)
**Step added:**
```yaml
- name: Validate guides have no leaked internal IDs (REL-02)
  run: mix mailglass.docs.check
```
`continue-on-error: false` (default) — build blocks on any leaked ID.

`actionlint` validated the ci.yml changes.

## Negative Test Confirmation

Before commit, a synthetic D-99 token was injected into `guides/getting-started.md`:
```bash
echo "D-99 leak test" >> guides/getting-started.md
mix mailglass.docs.check
# => [mailglass.docs.check] internal ID "D-99" found in guides/getting-started.md
# => ** (Mix) Delivery blocked: 1 internal ID(s) leaked into guides/*.md
# => Exit code: 1
```
Token reverted before commit. Task exits cleanly after revert.

## Verification

```
mix compile --warnings-as-errors  → exit 0
mix mailglass.docs.check          → exit 0
grep -rcE '\bD-[0-9]{2,3}\b' guides/ → 0 matches
grep -rcE '\bLINT-[0-9]{2}\b' guides/ → 0 matches
grep -c 'mix mailglass.docs.check' .github/workflows/ci.yml → 1
actionlint .github/workflows/ci.yml → exit 0
grep -c '"CLAUDE.md"' mix.exs → 0
grep -c 'CLAUDE.md' mix.exs → 0
grep -c 'CLAUDE.md' mailglass_admin/mix.exs → 0
ls CLAUDE.md → file present on disk
```

## Deviations from Plan

None — plan executed exactly as written.

`mailglass_admin/mix.exs` had no CLAUDE.md references at all (its `docs/0` block only has `main`, `source_url`, `source_ref`) so no edits were needed there. The acceptance criteria requiring 0 count was already satisfied.

## Known Stubs

None — the Mix task reads real filesystem paths and all guide content is genuine.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The Mix task reads local files only; `--path` accepts arbitrary globs but runs only in CI on the repo's own code (T-08-02-02 accepted per plan threat model).

## Self-Check: PASSED

- `lib/mix/tasks/mailglass.docs.check.ex` — FOUND
- Commit `cee469a` — FOUND (Task 1)
- Commit `ce18e06` — FOUND (Task 2)
