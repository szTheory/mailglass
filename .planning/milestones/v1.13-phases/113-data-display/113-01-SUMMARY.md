---
phase: 113-data-display
plan: 01
subsystem: mailglass_admin
tags: [data-display, components, icons, heroicons, data-state, stat-card, DATA-02, DATA-03]
requirements: [DATA-02, DATA-03]
status: complete

dependency_graph:
  requires: []
  provides:
    - "Components.data_state/1 public four-state primitive (DATA-03 foundation)"
    - "hero-inbox, hero-lock-closed, hero-clock vendored SVGs (ICON-EXISTS-GATE)"
    - "stat_card meaningful-text contract lock (DATA-02 foundation)"
  affects:
    - "mailglass_admin/lib/mailglass_admin/components.ex"
    - "mailglass_admin/assets/vendor/heroicons-inline.js"
    - "mailglass_admin/test/mailglass_admin/components_test.exs"

tech_stack:
  added: []
  patterns:
    - "attr + private-clause-helper convention (matching stat_card/1 shape)"
    - "Distinct testid literals (no string interpolation) for DATA-STATE-GATE grep"
    - "Gate-parseable heroicons-inline.js entry format (^[[:space:]]*\"key\":)"

key_files:
  created: []
  modified:
    - mailglass_admin/assets/vendor/heroicons-inline.js
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/test/mailglass_admin/components_test.exs

decisions:
  - "data_state/1 placed after stat_card/1 in components.ex, before private nav helpers"
  - "aria-hidden omitted from data_state icon call-site — icon/1 renders it internally via its template"
  - "All four testid literals are hardcoded strings in defp clauses, not interpolated, for gate-grep safety"

metrics:
  duration: "~10 minutes"
  completed: "2026-06-20"
  tasks: 3
  files: 3
---

# Phase 113 Plan 01: Data-State Primitive + Icon Embedding + Stat-Card Contract Lock Summary

Embedded three net-new Heroicons outline SVGs (inbox, lock-closed, clock) into the vendored standalone plugin, added `Components.data_state/1` as the single public four-state data-display primitive, and locked the `stat_card/1` meaningful-text contract with certification tests.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Embed three net-new data-state Heroicons | 06341e5d | `heroicons-inline.js` |
| 2 | Add public Components.data_state/1 with four distinct kinds | 78cd04b4 | `components.ex`, `components_test.exs` |
| 3 | Certify stat_card meaningful-text states (DATA-02 contract lock) | 8097c53c | `components_test.exs` |

## What Was Built

### Task 1 — Icon Embedding

Three outline SVG entries added to `mailglass_admin/assets/vendor/heroicons-inline.js` using the exact `"key": "<svg-markup>"` line shape the ICON-EXISTS-GATE parses:

- `"clock"` — for `:stale` data state (`hero-clock`)
- `"inbox"` — for `:empty` data state (`hero-inbox`)
- `"lock-closed"` — for `:permission_denied` data state (`hero-lock-closed`)

`exclamation-circle` (for `:error`) was already present and untouched.

### Task 2 — `Components.data_state/1`

New public function component in `MailglassAdmin.Components`:

```elixir
attr :kind, :atom, values: [:empty, :error, :permission_denied, :stale], required: true
attr :title, :string, required: true
attr :body, :string, required: true
attr :icon, :string, default: nil
attr :rest, :global, default: %{}
def data_state(assigns)
```

- Renders a `<section>` with per-kind `data-testid` (four distinct literal strings)
- `<.icon>` with per-kind mapped name and color class (`data_state_icon/1`, `data_state_icon_class/1`)
- Visible `<h3>` title and `<p>` body — all HEEx auto-escaped; no `raw()` calls
- Private helper clauses: `data_state_testid/1`, `data_state_icon/1`, `data_state_icon_class/1`

Kind-to-icon/color/testid mapping:

| Kind | Testid | Icon | Color |
|------|--------|------|-------|
| `:empty` | `data-state-empty` | `hero-inbox` | `text-secondary` |
| `:error` | `data-state-error` | `hero-exclamation-circle` | `text-error` |
| `:permission_denied` | `data-state-permission-denied` | `hero-lock-closed` | `text-warning` |
| `:stale` | `data-state-stale` | `hero-clock` | `text-secondary` |

Six contract tests added to `components_test.exs`:
1. `:empty` kind renders correct testid/icon/color/title/body
2. `:error` kind renders correct testid/icon/color
3. `:permission_denied` kind renders correct testid/icon/color
4. `:stale` kind renders correct testid/icon/color
5. Distinctness — `:empty` and `:error` have different testids; `:permission_denied` icon/testid differs from `:empty`
6. A11y — `aria-hidden="true"` on icon span, title in visible `<h3>`

### Task 3 — `stat_card/1` DATA-02 Certification

Five certification tests in a new `stat_card/1 — DATA-02 meaningful-text contract lock` describe block:

1. `state: :empty` renders `"No data yet"`, never a bare dash
2. `state: :unavailable` renders `"Unavailable"`, never a bare dash
3. `state: :loading` renders `"Resolving"`, never a bare dash
4. `severity: :neutral` renders `"All clear"` + `hero-minus-circle` + `text-secondary`
5. `value: nil` falls back to `empty_text`, not a dash

`stat_card/1` source is unchanged — these are pure certification tests.

## Verification

```
cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors
```

Result: **86 tests, 0 failures, 0 warnings**

Icon key gate:
```
for k in inbox lock-closed clock exclamation-circle; do
  grep -qE "^[[:space:]]*\"$k\":" assets/vendor/heroicons-inline.js || echo "MISSING $k"
done
```
Result: **All four icon keys present**

`grep -c 'def data_state' mailglass_admin/lib/mailglass_admin/components.ex` → **1**

No `raw(` calls in `data_state/1` body.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed aria-hidden from icon call-site in data_state/1**
- **Found during:** Task 2 compilation
- **Issue:** `icon/1` declares only `:name` and `:class` attrs (no `:rest, :global`), so passing `aria-hidden="true"` to it emits a `--warnings-as-errors`-failing warning about an undefined attribute
- **Fix:** Removed the `aria-hidden="true"` attribute from the `<.icon>` call in `data_state/1`. The `icon/1` component already renders `aria-hidden="true"` in its own template (`<span class={[@name, @class]} aria-hidden="true"></span>`), so the rendered HTML still contains the attribute and the a11y test passes
- **Files modified:** `mailglass_admin/lib/mailglass_admin/components.ex`
- **Commit:** 78cd04b4

## Threat Mitigations Applied

| Threat ID | Status |
|-----------|--------|
| T-113-01 Information Disclosure — permission_denied as no-data | Mitigated: `:permission_denied` has distinct testid `data-state-permission-denied`, distinct icon `hero-lock-closed`, distinct color `text-warning`; confirmed by distinctness test |
| T-113-02 Tampering (XSS) — title/body interpolation | Mitigated: HEEx auto-escaping preserved; `grep -c 'raw(' components.ex` = 0 |
| T-113-03 Information Disclosure — data-state copy | Accepted: copy uses domain nouns only; no PII or UUIDs in component copy |
| T-113-SC Tampering — npm/pip/cargo installs | N/A: no package installs in this plan |

## Known Stubs

None — the `data_state/1` primitive renders caller-provided title/body strings with no hardcoded placeholder values. The stat_card/1 certification tests confirm non-placeholder defaults are in place.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- [x] `mailglass_admin/assets/vendor/heroicons-inline.js` — modified (3 new icon entries added)
- [x] `mailglass_admin/lib/mailglass_admin/components.ex` — modified (`data_state/1` component added)
- [x] `mailglass_admin/test/mailglass_admin/components_test.exs` — modified (11 new tests added)
- [x] Commit 06341e5d exists (Task 1 — icons)
- [x] Commit 78cd04b4 exists (Task 2 — data_state component + tests)
- [x] Commit 8097c53c exists (Task 3 — stat_card certification)
- [x] 86 tests, 0 failures confirmed
