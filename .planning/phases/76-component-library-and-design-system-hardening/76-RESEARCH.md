# Phase 76: Component-Library and Design-System Hardening — Research

**Researched:** 2026-06-04
**Domain:** Phoenix LiveView component consolidation, daisyUI 5 badge classes, Tailwind v4 JIT, design-system token migration
**Confidence:** HIGH — all findings verified directly from vendored source files and codebase

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Delete all FIVE `badge_class/1` copies (deliveries_list:80-84, timeline:130-135, records_list:97-101, detail_header:81-85, inbound/detail_header:142-146). All call sites route through `Components.status_badge/1`.
- **D-02:** Inbound singular→past-tense normalization via an admin-side adapter at `record_outcome/1` (records_list.ex:88) and the equivalent in inbound/detail_header.ex — never in `mailglass_inbound` (locked 1.0 schema contract).
- **D-03:** `Components.status_badge/1` is a sibling to the existing `badge/1` (Preview-sidebar atom). Does not replace or absorb `badge/1`.
- **D-04:** Render icon + label (user decision). Per-atom Heroicon mapping (`status_icon/1`) required, covering all 24 atoms. Icons: outline style, decorative (`aria-hidden`). 390px overflow re-check required after icon addition.
- **D-05:** `status_class/1`, `status_label/1`, `status_icon/1` return only literal complete strings, one pattern-matched clause per atom. Zero interpolation. `attr :status, :atom, values: [...]`; `attr :size, :atom, values: [:sm, :md]`, default `:sm`. Component always emits the base `badge` class.
- **D-06:** Restructure `support_cards.ex` flat `xl:grid-cols-2` into Tier 1 (full `card bg-base-200 border border-base-300 rounded-box p-lg`) / Tier 2 (`border-t border-base-300` compact row). Same `@support_summary` map + `@suppression_count` assign. No new data plumbing.
- **D-07:** Restructure-first, then tokenize (Pitfall 4). Support card: (1) redesign structure, (2) then token-migrate.
- **D-08:** Token migration is admin-wide HEEx. Mapping: `text-sm`/`text-base` → `text-body`; `text-xs` → `text-label`; `gap-3` → `gap-sm`; `gap-4` → `gap-md`; `gap-6` → `gap-lg`. Single hex (`#ffffff`, `preview/tabs.ex:113`) → CSS var. `tracking-[0.08em]` (43 occ.) NOT in gate list.
- **D-09:** Phase 75's Overview/orientation markup (`operator_live.ex:279-362`) already token-clean — excluded. Remaining `text-sm/base/xs` in `operator_live.ex` at line 363+ are in scope.
- **D-10:** New regression test at `test/mailglass_admin/components_test.exs` using `render_component(&Components.status_badge/1, ...)` and `assert html =~`. Assert exact CSS class per atom across all four taxonomy tables, including new atoms, and per-atom icon name.
- **D-11:** Bundle rebuild is `mix mailglass_admin.assets.build`. Commits `mailglass_admin/priv/static/app.css` in the same PR as every HEEx change. `badge-primary` + new `hero-*` icon names must appear literally in HEEx source so JIT includes them.
- **D-12:** Phase 75 did not touch any badge call site — all 5 `badge_class/1` copies remain divergent. Clean consolidation surface.

### Claude's Discretion

- Final per-atom Heroicon names in `status_icon/1` (within outline-style, on-brand, semantically consistent constraints — D-04). Resolved below.
- Internal form of status mapping clauses (case vs function-head pattern match).
- Ordering of badge consolidation vs token migration vs support-card restructure across waves (restructure-first-then-tokenize D-07 holds for support cards).
- Whether inbound past-tense adapter is a shared helper or duplicated across both inbound files (shared helper recommended to prevent re-divergence).

### Deferred Ideas (OUT OF SCOPE)

- `motion-reveal` re-fire fix (GAP-19) — Phase 77
- Deep-link CSS bug (GAP-22) — Phase 79 per Phase 75 D-17
- Motion vocabulary application (GAP-20/21) — Phase 77
- Seed expansion (SEED-01/02) — Phase 78
- GAP-18 (`mono` class on ledger IDs/timestamps, sev-2) — opportunistic only
- Absorbing Preview `badge/1` atom — out of scope (D-03)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DS-01 | One unified `status_badge` atom in `components.ex` (icon + label); all five private `badge_class/1` copies deleted; all call sites route through it with no unintended color change | Icon mapping table (Gap 1); daisyUI badge class verification (Gap 2); regression test pattern (Gap 4) |
| DS-02 | Admin-wide token migration — zero raw `text-sm/base/xs`, zero faux-bold, zero off-grid gaps in admin HEEx (grep-enforced) | Token migration mechanics (Gap 3); footgun inventory (Gap 3); grep gate regex |
| DS-03 | Support-card flat grid restructured into primary/secondary triage hierarchy — restructure first, then tokenize | Support-card structure confirmed from live codebase; D-07 order constraint |
| DS-04 | Admin asset bundle rebuilt and committed; `git diff --exit-code priv/static/` clean | Bundle mechanics (Gap 5); 150KB ceiling analysis |
</phase_requirements>

---

## Summary

Phase 76 is a pure refactor of `mailglass_admin`: consolidate five divergent `badge_class/1` copies into a single `Components.status_badge/1` function component (with icon + label per DS-01), migrate all admin HEEx off raw Tailwind type/spacing utilities onto the design-system token scale (DS-02), restructure the support-cards flat grid into a primary/secondary triage hierarchy (DS-03), and commit the rebuilt bundle (DS-04). All decisions are locked in CONTEXT.md D-01..D-12.

The only genuinely open research items were: (1) the per-atom Heroicon mapping for all 24 status atoms, (2) daisyUI 5 badge class presence verification, (3) token migration footgun identification, (4) Nyquist validation architecture, and (5) bundle headroom analysis. All five are resolved below with direct codebase evidence.

**Primary recommendation:** Build in three waves: (A) badge consolidation + test, (B) support-card restructure then tokenize, (C) admin-wide token migration + bundle rebuild. This ordering ensures the badge component is available before the support-card markup references it, and the restructure-first constraint (D-07) is mechanically enforced.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Badge rendering (icon + label) | Frontend (LiveView component) | — | `Components.status_badge/1` is a stateless HEEx component; status data flows from parent assign |
| Status normalization (inbound past-tense adapter) | Frontend (call-site adapter) | — | Adapter is admin-side only per D-02; never touches `mailglass_inbound` locked schema |
| Support-card triage hierarchy | Frontend (LiveView component) | — | Reads existing `@support_summary` + `@suppression_count` assigns; no new data plumbing |
| Token conformance enforcement | CSS build (Tailwind JIT scan) | CI grep gate | JIT emits only literal class strings found in `@source "../../lib"` scan |
| Asset bundle | CSS build (tailwind standalone binary) | CI diff gate | `mix mailglass_admin.assets.build` + `git diff --exit-code priv/static/` |

---

## Gap 1: Per-Atom Heroicon Mapping (PRIMARY OUTPUT)

[VERIFIED: deps/heroicons/optimized/24/outline/] — Complete outline icon set confirmed present via sibling project's deps. Icon syntax confirmed from `components.ex:40`: `<.icon name="hero-<name>" class="w-3 h-3" />` (no suffix = outline; `-solid` suffix = solid; outline-only for badges per brand book).

### Icon Selection Rationale

Semantic families per D-04 constraints:
- **Success / terminal-good** → `hero-check-circle` (positive resolution, closed loop)
- **In-flight / dispatched** → `hero-paper-airplane` (sent to provider; forward motion) or `hero-arrow-path` (queued/retry states)
- **Warning / retry** → `hero-exclamation-triangle` (caution, not terminal)
- **Terminal-bad / error** → `hero-x-circle` (closed, negative) or `hero-exclamation-circle` (error emphasis)
- **Neutral / investigate** → `hero-question-mark-circle` (unknown), `hero-ellipsis-horizontal-circle` (in-flight neutral)
- **Consent / engagement** → `hero-hand-thumb-up` (clicked), `hero-envelope-open` (opened), `hero-bell-slash` (unsubscribed)
- **Replay/audit** → `hero-arrow-path` (requested/retry), `hero-check-circle` (succeeded), `hero-x-circle` (failed)
- **Intentional discard** → `hero-minus-circle` (ignore = intentional, not an error)

### Complete Per-Atom Heroicon Mapping Table

All 24 atoms verified against the frozen Phase 74 taxonomy. This table is directly liftable into `status_icon/1` + `status_class/1` clauses.

#### Outbound Delivery Status Atoms (14)

| Atom | `status_class/1` return | `status_label/1` return | `status_icon/1` return | Semantic family | daisyUI badge color |
|------|------------------------|------------------------|------------------------|-----------------|---------------------|
| `:dispatched` | `"badge-primary"` | `"Dispatched"` | `"hero-paper-airplane"` | In-flight | Glass/primary tint |
| `:queued` | `"badge-primary"` | `"Queued"` | `"hero-arrow-path"` | In-flight / pending | Glass/primary tint |
| `:sent` | `"badge-primary"` | `"Sent"` | `"hero-paper-airplane"` | In-flight (provider accepted) | Glass/primary tint |
| `:delivered` | `"badge-success"` | `"Delivered"` | `"hero-check-circle"` | Terminal good | Pine/success |
| `:deferred` | `"badge-warning"` | `"Deferred"` | `"hero-exclamation-triangle"` | Warning / retry | Amber/warning |
| `:bounced` | `"badge-error"` | `"Bounced"` | `"hero-x-circle"` | Terminal bad | Crimson/error |
| `:failed` | `"badge-error"` | `"Failed"` | `"hero-x-circle"` | Terminal bad | Crimson/error |
| `:rejected` | `"badge-error"` | `"Rejected"` | `"hero-x-circle"` | Terminal bad | Crimson/error |
| `:complained` | `"badge-error"` | `"Complained"` | `"hero-exclamation-circle"` | Terminal bad (user action) | Crimson/error |
| `:unsubscribed` | `"badge-warning"` | `"Unsubscribed"` | `"hero-bell-slash"` | Consent event | Amber/warning |
| `:opened` | `"badge-success"` | `"Opened"` | `"hero-envelope-open"` | Positive engagement | Pine/success |
| `:clicked` | `"badge-success"` | `"Clicked"` | `"hero-hand-thumb-up"` | Positive engagement | Pine/success |
| `:autoresponded` | `"badge-outline"` | `"Autoresponded"` | `"hero-arrow-uturn-left"` | Neutral / automated | Outline/neutral |
| `:unknown` | `"badge-outline"` | `"Unknown"` | `"hero-question-mark-circle"` | Neutral / investigate | Outline/neutral |

#### Inbound Message Outcome Atoms (6)

| Atom | `status_class/1` return | `status_label/1` return | `status_icon/1` return | Semantic family | daisyUI badge color |
|------|------------------------|------------------------|------------------------|-----------------|---------------------|
| `:accepted` | `"badge-success"` | `"Accepted"` | `"hero-check-circle"` | Terminal good | Pine/success |
| `:no_match` | `"badge-warning"` | `"No match"` | `"hero-exclamation-triangle"` | Warning / investigate | Amber/warning |
| `:rejected` | `"badge-error"` | `"Rejected"` | `"hero-x-circle"` | Terminal bad | Crimson/error |
| `:bounced` | `"badge-error"` | `"Bounced"` | `"hero-x-circle"` | Terminal bad | Crimson/error |
| `:ignore` | `"badge-outline"` | `"Ignored"` | `"hero-minus-circle"` | Intentional discard | Outline/neutral |
| `:failed_ingest` | `"badge-error"` | `"Ingest failed"` | `"hero-exclamation-circle"` | Error / infrastructure | Crimson/error |

#### Timeline Event Marker Atoms (4)

| Atom | `status_class/1` return | `status_label/1` return | `status_icon/1` return | Semantic family | daisyUI badge color |
|------|------------------------|------------------------|------------------------|-----------------|---------------------|
| `:webhook_replay_requested` | `"badge-outline"` | `"Replay requested"` | `"hero-arrow-path"` | In-flight / neutral | Outline/neutral |
| `:webhook_replay_succeeded` | `"badge-success"` | `"Replay succeeded"` | `"hero-check-circle"` | Success | Pine/success |
| `:webhook_replay_failed` | `"badge-error"` | `"Replay failed"` | `"hero-x-circle"` | Terminal bad | Crimson/error |
| `:reconciled` | `"badge-warning"` | `"Reconciled"` | `"hero-exclamation-triangle"` | Warning (needs investigation) | Amber/warning |

### Icon Name Verification

All proposed icon names confirmed present in the 24/outline set [VERIFIED: sibling project deps/heroicons/optimized/24/outline/]:

- `hero-paper-airplane` → `paper-airplane.svg` ✓
- `hero-arrow-path` → `arrow-path.svg` ✓
- `hero-check-circle` → `check-circle.svg` ✓
- `hero-exclamation-triangle` → `exclamation-triangle.svg` ✓
- `hero-x-circle` → `x-circle.svg` ✓
- `hero-exclamation-circle` → `exclamation-circle.svg` ✓
- `hero-bell-slash` → `bell-slash.svg` ✓
- `hero-envelope-open` → `envelope-open.svg` ✓
- `hero-hand-thumb-up` → `hand-thumb-up.svg` ✓
- `hero-arrow-uturn-left` → `arrow-uturn-left.svg` ✓
- `hero-question-mark-circle` → `question-mark-circle.svg` ✓
- `hero-minus-circle` → `minus-circle.svg` ✓

All 12 distinct icon names are confirmed present.

### Icon Syntax (from codebase)

[VERIFIED: mailglass_admin/lib/mailglass_admin/components.ex:40-48]

The `icon/1` component renders `<span class={[@name, @class]} aria-hidden="true"></span>`. The `hero-<name>` class is the mechanism — the standalone Tailwind heroicons plugin resolves it to a CSS mask + background-color at build time. Usage within the new component:

```heex
<span class={["badge", size_class(@size), status_class(@status)]} aria-label={status_label(@status)}>
  <span class={[status_icon(@status), "w-3 h-3"]} aria-hidden="true"></span>
  {status_label(@status)}
</span>
```

`aria-hidden="true"` on the icon span is correct — the text label is the semantic carrier.

---

## Gap 2: daisyUI 5 Badge Class Verification + JIT Safety

[VERIFIED: mailglass_admin/assets/vendor/daisyui.js — badge component definition at line 706-712]

### Confirmed Badge Classes in daisyUI 5

From the vendored `daisyui.js` badge component object:

| Class | Present | Definition |
|-------|---------|-----------|
| `.badge` | ✓ | Base: `display: inline-flex`, `align-items: center`, height via `--size-selector` |
| `.badge-sm` | ✓ | `--size: calc(var(--size-selector, 0.25rem) * 5)`, `font-size: 0.75rem` |
| `.badge-md` | ✓ | `--size: calc(var(--size-selector, 0.25rem) * 6)`, `font-size: 0.875rem` |
| `.badge-primary` | ✓ | `--badge-color: var(--color-primary)`, `--badge-fg: var(--color-primary-content)` |
| `.badge-success` | ✓ | `--badge-color: var(--color-success)`, `--badge-fg: var(--color-success-content)` |
| `.badge-warning` | ✓ | `--badge-color: var(--color-warning)`, `--badge-fg: var(--color-warning-content)` |
| `.badge-error` | ✓ | `--badge-color: var(--color-error)`, `--badge-fg: var(--color-error-content)` |
| `.badge-outline` | ✓ | `color: var(--badge-color)`, `--badge-bg: #0000`, border: currentColor |

**`badge-ghost` is NOT the correct neutral class** — it uses `var(--color-base-200)` fill. `badge-outline` is the correct transparent/neutral variant. This matches UI-SPEC Pitfall 3.

**`badge-primary` is available** for `:dispatched`, `:queued`, `:sent` (in-flight Glass/primary tint). Glass `#277B96` is the primary color on light theme (`--color-primary: #277B96` in `app.css:24`).

### JIT/Tree-Shake Rule

[VERIFIED: mailglass_admin/assets/css/app.css:5-8]

```css
@import "tailwindcss" source(none);
@source "../css";
@source "../../lib";
```

`source(none)` disables automatic content scanning. Only `../css` (app.css itself) and `../../lib` (all `.ex` files in `lib/`) are scanned. The heroicons plugin uses `matchComponents` which scans for `hero-*` class strings in the same source paths.

**JIT guarantee for new classes:** Every new `badge-primary`, `badge-sm`, `badge-md`, `badge-outline`, `badge-success`, `badge-warning`, `badge-error`, and every new `hero-*` icon name MUST appear as a **literal complete string** in an `.ex` file under `mailglass_admin/lib/`. Since `status_class/1`, `status_icon/1` use pattern-matched function heads returning literal strings, the scanner will find them in `components.ex`. No safelist is needed — the literal string presence in the source file is sufficient.

**Verification:** After implementing `status_class/1` and `status_icon/1` in `components.ex`, run `mix mailglass_admin.assets.build` and confirm the bundle contains the new classes. If any class is absent from the output bundle, the corresponding literal string is missing from the scanned source.

**The JIT trap (D-05, Pitfall 1):** Any interpolated form like `"badge-#{@status}"` or `"hero-#{status_icon(@status)}"` at the call site is tree-shaken to nothing because the scanner sees only the template string, not the runtime value. Function-head pattern-matched return of literal strings in `components.ex` is the correct approach — the scanner sees `"badge-primary"`, `"hero-check-circle"`, etc. as literal strings in that file.

---

## Gap 3: Token Migration Mechanics and Footguns

[VERIFIED: codebase grep across mailglass_admin/lib/**/*.ex]

### Source → Target Mapping

| Raw utility | Token replacement | Count in lib/ | Safe? |
|-------------|------------------|----------------|-------|
| `text-sm` | `text-body` | ~65 occurrences | See footguns below |
| `text-base` | `text-body` | ~8 occurrences | See footguns below |
| `text-xs` | `text-label` | ~70 occurrences | See footguns below |
| `gap-3` | `gap-sm` | ~25 occurrences | See footguns below |
| `gap-4` | `gap-md` | ~15 occurrences | See footguns below |
| `gap-6` | `gap-lg` | ~5 occurrences | See footguns below |

### Footgun Inventory

**Footgun 1 — `text-xs font-bold uppercase tracking-[0.08em]` pattern (38 occurrences)**

[VERIFIED: grep across lib/] — This pattern appears 38 times across `dt` labels, `span` filter labels, and section headers. It is the admin's design-system convention for uppercase metadata labels (e.g., "Provider", "Tenant", "Webhook row ID"). These occurrences have `text-xs` — which D-08 maps to `text-label`. However, they also have `font-bold`, which is valid (400/700 weight contract). The `tracking-[0.08em]` is explicitly excluded from the Phase 76 gate list (D-08: "Leave it"). Migration instruction: replace `text-xs` → `text-label` in these patterns but leave `font-bold`, `uppercase`, and `tracking-[0.08em]` unchanged.

Example from `inbound/detail_header.ex:56`:
```heex
<dt class="text-xs font-bold uppercase tracking-[0.08em]">Tenant</dt>
```
Becomes:
```heex
<dt class="text-label font-bold uppercase tracking-[0.08em]">Tenant</dt>
```

**Footgun 2 — `font-mono text-xs` combinations (Preview surface)**

[VERIFIED: preview/tabs.ex, preview/assigns_form.ex, preview_live.ex] — `font-mono` is not the same as the design-system `mono` class. The brand book uses `mono` (IBM Plex Mono) for ledger contexts; `font-mono` is a raw Tailwind utility that maps to `ui-monospace, monospace`. In these occurrences, `font-mono text-xs` appears in `<pre>`, `<code>`, `<textarea>`, and `<th>/<td>` elements for raw email content rendering — these are Preview surface internals, not operator-surface token violations. Migration: replace `text-xs` → `text-label` in these, but note that `font-mono` → `mono` is GAP-18 (sev-2, opportunistic only). Do not block DS-02 on the `font-mono`→`mono` swap.

**Footgun 3 — `sm:grid-cols-2` on a container that also has `text-sm`**

[VERIFIED: `inbound/evidence_card.ex:72`: `<dl class="grid gap-1 text-sm sm:grid-cols-2">`] — The `text-sm` here is on the container `dl`, not on an inner element. Replacing with `text-body` is safe — `sm:grid-cols-2` is a responsive layout class, not a type scale class, and the two are orthogonal. No footgun: naive replace is safe for this occurrence.

**Footgun 4 — `gap-2` and `gap-1` (do NOT migrate)**

[VERIFIED: gap-1 and gap-2 appear extensively and are NOT in the migration list] — Only `gap-3`, `gap-4`, and `gap-6` are targeted (D-08). `gap-2` (8px off-grid by some interpretations) and `gap-1` (4px = `xs`) are left untouched. The grep for token violations must be scoped to exactly `gap-3`, `gap-4`, `gap-6`.

**Footgun 5 — `label-text text-sm` (daisyUI form component class, NOT a token violation)**

[VERIFIED: `preview/assigns_form.ex:68,83,99,122,131,146,161,177,209`] — `label-text` is a daisyUI fieldset/label modifier class; `text-sm` here appears as `label-text text-sm font-normal`. This is a daisyUI-authored class combination. Replacing `text-sm` → `text-body` in this context is safe for conformance, but note that `font-normal` (400 weight) is valid and should be retained (or can be dropped since 400 is the default — either is fine).

**Footgun 6 — `hover:text-base-content` (safe — different token)**

[VERIFIED: `operator/shell.ex:211,234`] — `hover:text-base-content` contains the string `text-base` as a prefix but is NOT the raw `text-base` utility. The grep must be `\btext-base\b` (word boundary) to avoid false matches. The planner's grep should use: `grep -E '\btext-(sm|base|xs)\b'` not plain `text-sm|text-base|text-xs`.

**Footgun 7 — The `#ffffff` hex in `preview/tabs.ex:113`**

[VERIFIED: `preview/tabs.ex:113`]: `style={"width: #{@device_width}px; height: 600px; border: 1px solid var(--color-base-300); border-radius: var(--radius-box); background: #ffffff;"}` — This is an inline `style=` attribute on a device-frame iframe container. D-08 says "convert to a CSS var for cleanliness." The replacement is `background: var(--color-base-100)` (Paper `#F8FBFD` on light, Ink `#0D1B2A` on dark — the device frame background should be the app's base surface color, and this correctly inverts for dark mode). Note: this is the only hex in the codebase; no other hex violations exist in HEEx class attributes [VERIFIED: grep found no `#[0-9a-f]{3,6}` in class= attributes].

### Grep Gate Exact Regex (from design-system.md conformance pillars)

The Phase 79 conformance gate and Phase 76 verification checks use:

**Type violations (should return zero after migration):**
```bash
grep -rE '\btext-(sm|base|xs)\b' mailglass_admin/lib/ --include="*.ex"
grep -rE '\bfont-(medium|semibold)\b' mailglass_admin/lib/ --include="*.ex"
```

**Spacing violations (should return zero after migration):**
```bash
grep -rE '\bgap-(3|4|6)\b' mailglass_admin/lib/ --include="*.ex"
```

**Hex color violations (should return zero):**
```bash
grep -rE '#[0-9a-fA-F]{3,6}\b' mailglass_admin/lib/ --include="*.ex"
```

**Badge function existence (should return zero — all five deleted):**
```bash
grep -rn 'defp badge_class' mailglass_admin/lib/ --include="*.ex"
```

### Safe Find-and-Verify Approach

1. Run the grep gate for each pattern to establish the full list of files to touch.
2. For `text-xs` specifically: review each occurrence to confirm it is not inside a string used as a daisyUI component name (e.g., `badge-xs` — that is a badge size class, not a type token). No such false positives found [VERIFIED: no `badge-xs` usage in lib/].
3. Apply migration file-by-file (not a global sed), reviewing context around each occurrence.
4. After each file: run `mix mailglass_admin.assets.build` periodically (or at wave end) to confirm the bundle is building clean.
5. Run the grep gate again to confirm zero violations.

---

## Gap 4: Validation Architecture (Nyquist)

Nyquist validation is enabled (no `workflow.nyquist_validation: false` in config.json).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Quick run command | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs` |
| Full suite command | `cd mailglass_admin && mix test --seed 0` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | File | Exists? |
|--------|----------|-----------|------|---------|
| DS-01 | `status_badge/1` renders correct CSS class per atom | Unit | `test/mailglass_admin/components_test.exs` | No — Wave 0 gap |
| DS-01 | `status_badge/1` renders correct icon name per atom | Unit | `test/mailglass_admin/components_test.exs` | No — Wave 0 gap |
| DS-01 | `status_badge/1` renders correct label per atom | Unit | `test/mailglass_admin/components_test.exs` | No — Wave 0 gap |
| DS-01 | `badge_class/1` private function is absent from all 5 files | Structural (grep) | CI grep gate | Automated |
| DS-02 | Zero `text-sm/base/xs` in admin HEEx after migration | Structural (grep) | CI grep gate | Automated |
| DS-02 | Zero `gap-3/4/6` in admin HEEx after migration | Structural (grep) | CI grep gate | Automated |
| DS-03 | Support-card Tier1/Tier2 markup present | Unit (render check) | `test/mailglass_admin/operator_live_test.exs` (existing) | Partial |
| DS-04 | Bundle clean gate | Structural | CI `git diff --exit-code priv/static/` | Automated |

### Test Pattern (House Pattern)

[VERIFIED: `test/mailglass_admin/inbound/components_test.exs:26`, `test/mailglass_admin/operator/shell_test.exs:12`]

```elixir
# test/mailglass_admin/components_test.exs
defmodule MailglassAdmin.ComponentsTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias MailglassAdmin.Components

  describe "status_badge/1 — outbound delivery statuses" do
    test "dispatched renders badge-primary + paper-airplane icon" do
      html = render_component(&Components.status_badge/1, status: :dispatched, size: :sm)
      assert html =~ "badge-primary"
      assert html =~ "hero-paper-airplane"
      assert html =~ "Dispatched"
    end

    # ... one test per atom (24 total) ...

    test "unknown renders badge-outline + question-mark-circle icon" do
      html = render_component(&Components.status_badge/1, status: :unknown, size: :sm)
      assert html =~ "badge-outline"
      assert html =~ "hero-question-mark-circle"
      assert html =~ "Unknown"
    end
  end
end
```

One `assert html =~` per atom per assertion (three assertions per atom: class, icon, label) — Pitfall 5 prevention. 24 atoms × 3 assertions = 72 assertions minimum.

### Wave 0 Gaps

- [ ] `test/mailglass_admin/components_test.exs` — covers DS-01 (no root Components test file exists per `ls test/mailglass_admin/`)
- [ ] 24 atom × 3 assertion coverage in that file

Existing infrastructure (`ExUnit`, `Phoenix.LiveViewTest`, `import Phoenix.LiveViewTest`) is already set up — no new test framework installation required.

---

## Gap 5: Bundle Rebuild Mechanics and 150KB Ceiling

[VERIFIED: `mailglass_admin/test/mailglass_admin/bundle_test.exs`]
[VERIFIED: `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex:28`]

### Invocation

```bash
cd mailglass_admin && mix mailglass_admin.assets.build
```

This runs `Mix.Task.run("tailwind", ["default", "--minify"])`, which invokes the Tailwind v4.1.12 standalone binary with:
- `--input=assets/css/app.css`
- `--output=priv/static/app.css`
- Working directory: `mailglass_admin/`

### Committed Artifact

`mailglass_admin/priv/static/app.css` — this is the committed bundle. The CI gate is:
```bash
git diff --exit-code priv/static/
```
Any uncommitted change to `priv/static/app.css` (or fonts, logo) fails the gate.

### 150KB Ceiling Analysis

[VERIFIED: `bundle_test.exs:24`] — Budget is `< 150_000` bytes (147KB). Current bundle size: **70,789 bytes** (~69KB).

Adding ~20 new `hero-*` icon CSS masks (each icon is an inline SVG encoded as a CSS `mask` value) will increase the bundle. Each Heroicon SVG in 24/outline is approximately 200-400 bytes as encoded CSS. 20 icons × 400 bytes = ~8KB additional at maximum. This brings the estimated bundle to ~77KB — well within the 150KB budget with ~73KB headroom. **The 150KB ceiling is not at risk.** [ASSUMED: SVG size estimates from typical Heroicons outline SVGs; the exact sizes depend on path complexity.]

The 800KB total `priv/static/` budget (fonts + logo + css) also has substantial headroom: fonts are ~480KB (6 woff2 × ~80KB), logo ~5KB, CSS ~70KB = ~555KB currently. Adding ~8KB to CSS leaves ~245KB headroom. [ASSUMED: woff2 font sizes are estimates.]

### Heroicons Plugin Scan

[VERIFIED: `mailglass_admin/assets/vendor/heroicons.js:6-43`] — The plugin uses `matchComponents` scanning the same `@source "../../lib"` paths as Tailwind. The heroicons plugin resolves `hero-*` class names found in the source scan to inline SVG CSS masks. New `hero-*` names in `components.ex` are automatically included by the build — no additional configuration required beyond their literal presence in the source file.

---

## Architecture Patterns

### Recommended Project Structure (new file)

```
test/mailglass_admin/
└── components_test.exs    # NEW — DS-01 regression, 24-atom coverage
```

### Pattern: status_badge/1 Component Shape

Based on the house pattern from `components.ex:91-114` (existing `badge/1`):

```elixir
# mailglass_admin/lib/mailglass_admin/components.ex

attr :status, :atom,
  values: [
    :dispatched, :queued, :sent, :delivered, :deferred, :bounced, :failed,
    :rejected, :complained, :unsubscribed, :opened, :clicked, :autoresponded, :unknown,
    :accepted, :no_match, :ignore, :failed_ingest,
    :webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed,
    :reconciled
  ],
  required: true

attr :size, :atom, values: [:sm, :md], default: :sm

@doc since: "1.5.0"
def status_badge(assigns) do
  ~H"""
  <span class={["badge", size_class(@size), status_class(@status)]}>
    <span class={[status_icon(@status), "w-3 h-3"]} aria-hidden="true"></span>
    {status_label(@status)}
  </span>
  """
end

defp size_class(:sm), do: "badge-sm"
defp size_class(:md), do: "badge-md"

defp status_class(:dispatched), do: "badge-primary"
defp status_class(:queued), do: "badge-primary"
defp status_class(:sent), do: "badge-primary"
defp status_class(:delivered), do: "badge-success"
# ... (one clause per atom per D-05, literal strings only)

defp status_icon(:dispatched), do: "hero-paper-airplane"
defp status_icon(:queued), do: "hero-arrow-path"
# ... (one clause per atom, literal strings only)

defp status_label(:dispatched), do: "Dispatched"
# ... (one clause per atom, literal strings only)
```

### Pattern: Inbound Adapter (Shared Helper)

Shared helper recommended (D-02 / Claude's Discretion) to prevent re-divergence between `records_list.ex` and `inbound/detail_header.ex`:

```elixir
# In records_list.ex or a shared inbound components module
defp normalize_outcome(:accept), do: :accepted
defp normalize_outcome(:reject), do: :rejected
defp normalize_outcome(:bounce), do: :bounced
defp normalize_outcome(atom), do: atom  # :no_match, :ignore, :failed_ingest, nil pass through
```

The existing `record_outcome/1` at `records_list.ex:88` should be updated to normalize before returning. The same logic should be extracted or duplicated into `inbound/detail_header.ex` (shared module is cleaner; the planner decides the extraction boundary).

### Anti-Patterns to Avoid

- **Interpolated icon/badge classes:** Never `"hero-#{status_icon(@status)}"` at a call site — the literal must appear in `components.ex`.
- **Tokenizing before restructuring support cards:** D-07 / Pitfall 4. Always restructure the `support_cards.ex` markup first, then apply token classes to the final structure.
- **Touching `mailglass_inbound`:** The `@outcomes` schema atoms (`:no_match, :accept, :ignore, :reject, :bounce, :failed`) are a locked 1.0 contract. Normalization lives exclusively in the admin adapter.
- **Adding a `badge-ghost` class:** Use `badge-outline` for neutral/fallback. `badge-ghost` has a filled background and is not the correct daisyUI 5 neutral variant (UI-SPEC Pitfall 3).
- **Missing the two latent copies (GAP-05, GAP-06):** `operator/detail_header.ex:81-85` and `inbound/detail_header.ex:142-146` are latent duplicates. Deleting only the three named copies leaves the detail-header badge rendering divergent (Pitfall 5).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Icon rendering | Custom SVG inline | `hero-*` CSS class on `<span>` | The heroicons plugin resolves it to inline SVG CSS mask at build time; no runtime SVG injection needed |
| Badge color logic | Manual conditional in HEEx | `status_class/1` private defp | One literal per clause; JIT-safe; testable |
| daisyUI badge variants | Custom CSS | `badge-primary`, `badge-success`, etc. | Already in vendored daisyUI.js; auto-themed for light/dark |

---

## Common Pitfalls

### Pitfall A: JIT Tree-Shake on Interpolated Class Names

**What goes wrong:** `class={"badge-#{status}"}` or `name={"hero-#{icon}"}` renders as an empty/invisible element in production. The Tailwind scanner sees only the template string, not the runtime value.

**Why it happens:** Tailwind v4 (and v3) emit only class strings found literally in the scanned source at build time.

**How to avoid:** Every `status_class/1`, `status_icon/1`, `status_label/1` clause must return a complete literal string. The scanner finds `"badge-primary"`, `"hero-check-circle"` etc. in `components.ex` and includes them.

**Warning signs:** Badge renders with no background/border (badge-outline fallback instead of badge-primary); icon span is invisible.

### Pitfall B: Missing Latent Duplicate Copies (GAP-05, GAP-06)

**What goes wrong:** After consolidation, the list view renders the new `status_badge/1` correctly but the detail header still uses the old `badge_class/1` private function with the phantom `:suppressed` atom.

**Why it happens:** The audit found five copies, but the REQUIREMENTS.md and ROADMAP text say "three." The two latent copies in `detail_header.ex` files are verbatim duplicates of the list copies.

**How to avoid:** `grep -rln badge_class mailglass_admin/lib` must return zero files after consolidation.

### Pitfall C: Token Migration Order on Support Cards

**What goes wrong:** Token classes applied to the flat 2×2 grid structure — then when the structure is redesigned, all the token work is undone and re-applied.

**Why it happens:** Attempting to do token migration and hierarchy restructure together.

**How to avoid:** D-07 / Pitfall 4 — restructure `support_cards.ex` markup first (Tier1/Tier2), then apply token classes to the final markup.

### Pitfall D: `badge-xs` False Positive in Grep

**What goes wrong:** A grep for `\btext-xs\b` incorrectly flags `badge-xs` if the regex is `text-xs` without word boundary.

**How to avoid:** Use `\btext-xs\b` (word boundary anchors) in the grep gate. No `badge-xs` usage exists in the current codebase [VERIFIED], but the pattern is a risk.

### Pitfall E: Bundle Committed Without Rebuilding After Every HEEx Change

**What goes wrong:** CI `git diff --exit-code priv/static/` fails because `app.css` was not rebuilt after a HEEx change added a new `hero-*` or `badge-*` class.

**How to avoid:** Rebuild the bundle as the final step of every wave that touches HEEx. The bundle commit must be in the same PR as the HEEx changes (D-11).

---

## Code Examples

### Complete `status_badge/1` Integration Pattern

```elixir
# Source: components.ex house pattern (existing badge/1 at lines 91-114)

# Call site in deliveries_list.ex (replaces: <span class={["badge badge-sm", badge_class(delivery.status)]}>)
<Components.status_badge status={delivery.status} size={:sm} />

# Call site in timeline.ex (replaces: <span :if={event_badge(event.type)} class={badge_class(event.type)}>)
<Components.status_badge :if={timeline_badge_atom?(event.type)} status={event.type} size={:sm} />

# Call site in records_list.ex (replaces: <span class={["badge badge-sm", badge_class(record_outcome(record))]}>)
<Components.status_badge status={normalize_outcome(record_outcome(record))} size={:sm} />
```

### Support Card Tier1/Tier2 Structure Sketch

```heex
<!-- Tier 1: non-zero/actionable (one per failing signal) -->
<div class="flex flex-col gap-lg">
  <article :if={@support_summary.failed_ingest.count > 0}
           class="card bg-base-200 border border-base-300 rounded-box p-lg">
    <span class="text-display font-bold text-error">{@support_summary.failed_ingest.count}</span>
    <p class="text-body text-secondary">Recent failures (last 24h)</p>
    <.link navigate={...} class="btn btn-sm btn-primary mt-sm">View failures</.link>
  </article>
</div>

<!-- Tier 2: zero-state compact row -->
<div class="border-t border-base-300 flex gap-md items-center py-sm text-label text-secondary">
  <span>No failures</span>
  <span>·</span>
  <span>No orphan backlog</span>
</div>
```

### Token Migration Example

```heex
<!-- Before -->
<p class="text-sm text-secondary">Tenant-scoped facts.</p>
<div class="flex gap-3 items-center">
<dt class="text-xs font-bold uppercase tracking-[0.08em]">Provider</dt>

<!-- After -->
<p class="text-body text-secondary">Tenant-scoped facts.</p>
<div class="flex gap-sm items-center">
<dt class="text-label font-bold uppercase tracking-[0.08em]">Provider</dt>
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Three `badge_class/1` private copies (per REQUIREMENTS.md) | Five copies found by Phase 74 audit (including two latent duplicates in detail_header files) | Plan must target all 5, not 3 |
| Inline class string in call site | `Components.status_badge/1` function component | Enables icon + label per DS-01 |
| `badge-outline` for all neutral states | `badge-outline` confirmed as correct daisyUI 5 neutral (not `badge-ghost`) | No change needed from existing pattern |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | New hero-* icons add ~8KB to bundle (~400 bytes each encoded) | Gap 5 bundle analysis | If icons are larger, could approach 150KB ceiling — but 73KB headroom makes this very low risk |
| A2 | woff2 font files are ~80KB each (~480KB total for 6 fonts) | Gap 5 bundle analysis | Does not affect DS-04 directly; bundle_test checks total tree separately |

**All other claims are verified from the vendored source files or live codebase.**

---

## Open Questions

1. **`status_badge/1` — timeline call site guard function name**
   - What we know: `timeline.ex:52` uses `:if={event_badge(event.type)}` as the guard; `event_badge/1` returns a string label or `nil` (from `repair_state.ex:84-88`). The `badge_class/1` private function at `timeline.ex:130` will be deleted.
   - What's unclear: Should the existing `event_badge/1` guard be renamed/replaced with a dedicated `timeline_badge_atom?/1` predicate that checks atom membership, or should it continue using the label-returning function as a boolean?
   - Recommendation: Keep `event_badge/1` as-is for the guard (the planner can decide); replace only `badge_class/1` with `Components.status_badge/1`.

2. **Support card: `@suppression_count` in Tier1/Tier2 threshold**
   - What we know: `@suppression_count` feeds the suppression card; `count_active_suppressions/1` was shipped in Phase 75. The UI-SPEC Health Count Colors assigns `text-secondary` (not `text-warning` or `text-error`) to active suppressions — it is informational.
   - Recommendation: Suppression count always renders in Tier 2 (compact row) regardless of count, because it is informational/secondary by design (not actionable in the same way as failures or orphan backlog). Only `failed_ingest.count > 0` and `orphan_backlog.count > 0` trigger Tier 1 cards.

---

## Environment Availability

Step 2.6: SKIPPED — this phase is purely HEEx/component/CSS changes within the existing project. The Tailwind standalone binary (v4.1.12) and ExUnit are already installed and operational. No external dependencies are introduced.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mailglass_admin/test/test_helper.exs` (existing) |
| Quick run command | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs` |
| Full suite command | `cd mailglass_admin && mix test --seed 0` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DS-01 | CSS class per atom (24 atoms) | unit | `mix test test/mailglass_admin/components_test.exs` | ❌ Wave 0 |
| DS-01 | Icon name per atom (24 atoms) | unit | `mix test test/mailglass_admin/components_test.exs` | ❌ Wave 0 |
| DS-01 | Label per atom (24 atoms) | unit | `mix test test/mailglass_admin/components_test.exs` | ❌ Wave 0 |
| DS-01 | No `badge_class/1` private defp remains | structural grep | `grep -rn 'defp badge_class' mailglass_admin/lib/` | Automated |
| DS-02 | Zero `text-sm/base/xs` in lib/ | structural grep | `grep -rE '\btext-(sm|base|xs)\b' mailglass_admin/lib/` | Automated |
| DS-02 | Zero `gap-3/4/6` in lib/ | structural grep | `grep -rE '\bgap-(3|4|6)\b' mailglass_admin/lib/` | Automated |
| DS-04 | Bundle clean | structural diff | `git diff --exit-code priv/static/` | Automated (CI) |

### Sampling Rate

- **Per wave commit:** `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs`
- **Per wave merge:** `cd mailglass_admin && mix test --seed 0`
- **Phase gate:** Full suite green before `/gsd:verify-work` + grep gates zero + bundle clean

### Wave 0 Gaps

- [ ] `test/mailglass_admin/components_test.exs` — 24-atom `status_badge/1` coverage (DS-01)

*(All other test infrastructure already exists — ExUnit, Phoenix.LiveViewTest, LiveViewCase.)*

---

## Security Domain

This phase makes no changes to authentication, session management, data access, or input validation surfaces. It is a pure admin-dashboard CSS/component refactor. No ASVS categories apply beyond V5 input validation, which is not relevant to HEEx template token migration.

PII discipline: icons and badge labels carry no user data. The `mask_recipient/1` function is unchanged. No new data surfaces introduced.

---

## Sources

### Primary (HIGH confidence)

- `mailglass_admin/assets/vendor/daisyui.js` lines 706-712 — badge class definitions verified from vendored source
- `mailglass_admin/assets/vendor/heroicons.js` — hero-* plugin mechanism verified
- `mailglass_admin/assets/css/app.css` — `@source` directives, `@theme` token definitions, brand colors
- `mailglass_admin/lib/mailglass_admin/components.ex:91-114` — house pattern for new component
- `mailglass_admin/test/mailglass_admin/bundle_test.exs` — 150KB ceiling, font set spec
- `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex` — build invocation
- `sibling project deps/heroicons/optimized/24/outline/` — complete outline icon set (ls output)
- `.planning/phases/74-systematic-audit-and-ui-spec/74-UI-SPEC.md` — frozen taxonomy (all 4 sub-tables)
- `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md` — gap rows GAP-01..GAP-18
- `.planning/phases/76-component-library-and-design-system-hardening/76-CONTEXT.md` — D-01..D-12 locked decisions

### Secondary (MEDIUM confidence)

- Codebase grep across `mailglass_admin/lib/**/*.ex` — token violation inventory, call site locations

### Tertiary (LOW confidence)

- Bundle size estimates for hero-* icon SVG encoding (A1 in Assumptions Log)

---

## Metadata

**Confidence breakdown:**
- Per-atom Heroicon mapping: HIGH — all 12 distinct icon names verified present in outline set
- daisyUI 5 badge classes: HIGH — verified from vendored daisyui.js source
- Token migration mechanics: HIGH — verified from codebase grep
- Footgun inventory: HIGH — verified from live codebase
- Bundle ceiling analysis: MEDIUM — icon size estimates are approximate

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable stack — Tailwind v4.1.12, daisyUI 5 pinned)
