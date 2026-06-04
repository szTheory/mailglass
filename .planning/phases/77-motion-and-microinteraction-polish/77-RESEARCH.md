# Phase 77: Motion and Microinteraction Polish — Research

**Researched:** 2026-06-04
**Domain:** LiveView animation, CSS motion vocabulary, Playwright e2e, shell conformance gating
**Confidence:** HIGH (all claims verified against live codebase)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Add `id={"delivery-detail-#{@selected_delivery.id}"}` to the bare `motion-reveal`
  div at `operator_live.ex:442`. LiveView replaces (not patches) the element on
  delivery-selection change, re-firing the entrance animation exactly once per selection.
  This is the literal GAP-19 fix.
- **D-02:** Apply the parallel id-key to the identical latent twin at `inbound_live.ex:341`:
  `id={"inbound-detail-#{@selected_record.id}"}`. Same bug, not named in GAP-19, but it
  rides the same fix. `@selected_record.id` is non-nil in the selected branch.
  **[CORRECTION — see Anchor 2 below: `@detail.record.id` is the correct expression; see
  Verification Anchor 2 section for rationale.]**
- **D-03:** No CSS changes for the re-fire fix. Pattern reference:
  `preview/tabs.ex:84` id-keyed `motion-tab-swap`.
- **D-04:** GAP-20 and layout-thrashing sweep are verification-only — no code changes.
  Thrash sweep is already clean.
- **D-05:** GAP-21 a11y is out of scope — already satisfied by Phases 75/76.
- **D-06:** Author a new `scripts/check_motion_conformance.sh` (or similar name). Greps
  `lib/` and `app.css` for banned tokens; exits nonzero on any hit. NOT inside
  `ui-audit.sh`. Reused at Phase 79.
- **D-07:** Extend `e2e/operator.spec.js` with a reduced-motion test using
  `page.emulateMedia({ reducedMotion: "reduce" })` plus id-presence assertions on
  `#delivery-detail-<id>` (and the inbound twin).
- **D-08:** Rebuild the admin asset bundle and commit `priv/static/` in the same PR.
  `git diff --exit-code priv/static/` gate. Bundle may be a no-op rebuild (id attributes
  do not change Tailwind class set) — run it, don't assume.

### Claude's Discretion

- Exact filename/location of the new conformance grep script (D-06) and how much e2e
  coverage to add (D-07) are planner-resolvable.

### Deferred Ideas (OUT OF SCOPE)

- Promotion of motion + token conformance grep gates into full CI matrix and before/after
  visual-regression diff — Phase 79.
- Deep-link unstyled-CSS bug — Phase 79.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MOTION-01 | Existing six-motion vocabulary applied only where UI-SPEC assigns it; entrances fire on mount (record-keyed ids — fixes the `motion-reveal` re-fire on `operator_live.ex`) not on every LiveView patch | D-01/D-02 id-key fix; pattern reference verified at `preview/tabs.ex:84`; LiveView element-replacement semantics confirmed |
| MOTION-02 | Motion respects `prefers-reduced-motion`, animates transform/opacity only (no height/width), and stays ≤ 300ms with exits faster than entrances | Layout-thrashing sweep confirmed clean (0 hits); all keyframes verified transform+opacity only; all durations ≤ 220ms; global reduced-motion block confirmed at `app.css:274-282` |
</phase_requirements>

---

## Summary

Phase 77 is a small, precise application phase. The six-motion vocabulary is already authored
and spec-conformant in `mailglass_admin/assets/css/app.css`. The only code changes are two
two-line additions (one id attribute each) in `operator_live.ex:442` and `inbound_live.ex:341`,
plus a new shell conformance grep gate and reduced-motion e2e tests. No CSS changes are needed.

The re-fire bug (MOTION-01 / GAP-19) is a LiveView semantics issue: without an `id` attribute,
LiveView patches the existing element in-place on delivery selection, so no mount event fires and
the `mg-reveal` animation does not re-trigger. Adding a record-keyed id causes LiveView to treat
each new delivery selection as an element replacement rather than a patch, firing the animation
exactly once per selection. The identical bug exists in `inbound_live.ex:341` — both are fixed
in the same change.

The MOTION-02 conformance sweep is verification-only (no code changes). All four observable
success criteria — animations fire on mount not patch, all motion respects `prefers-reduced-motion`,
no layout-thrashing properties, no duration over 300ms — are already satisfied in the codebase.
The work is adding gates that will catch regression.

**Primary recommendation:** Fix both id-keys, author the shell conformance gate (D-06), extend
the Playwright suite with reduced-motion + id-presence tests (D-07), run the bundle rebuild (D-08).
Total changeset: ~4 HEEx lines, 1 shell script (~25 lines), ~25 lines of e2e test additions.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Motion re-fire fix (D-01/D-02) | Frontend Server (LiveView) | — | LiveView element-keying controls mount/patch semantics; fix is a HEEx `id=` attribute, not CSS |
| CSS motion vocabulary | CDN / Static | — | Already in `priv/static/` committed bundle; no changes needed |
| Conformance grep gate (D-06) | CI / Shell | — | Stateless grep; runs as a `bash scripts/` step in the `credo_strict` CI job |
| Reduced-motion e2e (D-07) | Browser (Playwright) | Frontend Server | Playwright emulates media query; verifies DOM at the rendered element layer |
| Bundle rebuild / clean gate (D-08) | CDN / Static | CI | `mix mailglass_admin.assets.build` + `git diff --exit-code priv/static/` in `verify.preview` alias |

---

## Verification Anchors (CONTEXT claimed → verified against live codebase)

### Anchor 1 — `operator_live.ex:442`: bare motion-reveal div, NO id

**VERIFIED [CONFIRMED].** `[VERIFIED: codebase grep + file read]`

```
operator_live.ex:442:  <div class="motion-reveal space-y-4">
```

The surrounding context: this is the `true ->` branch of a `cond do` at the detail column
`<section data-testid="operator-detail-column">`. `@selected_delivery` is non-nil at this
branch. The div has no `id` attribute. The fix: add
`id={"delivery-detail-#{@selected_delivery.id}"}`.

**Note:** The GAP-19 register and the UI-SPEC both reference `operator_live.ex:332`. This line
number is stale — Phases 75/76 inserted content above the detail section (orientation strip,
support cards), shifting the bare div down to line 442. Line 442 is the correct current anchor.

### Anchor 2 — `inbound_live.ex:341`: bare motion-reveal twin, NO id

**VERIFIED [CONFIRMED WITH CORRECTION].** `[VERIFIED: codebase grep + file read]`

```
inbound_live.ex:341:  <div class="motion-reveal space-y-4">
```

This is the `true ->` branch of a `cond do` at `<section data-testid="inbound-detail-column">`.

**Correction to CONTEXT.md D-02:** D-02 specifies `id={"inbound-detail-#{@selected_record.id}"}`.
However, the template at line 341 renders `@detail` (not `@selected_record`) — specifically
`<DetailHeader.detail_header detail={@detail} />`. `@detail` is a map with shape
`%{record: %InboundRecord{}, mailbox: _, outcome: _, outcome_reason: _, evidence: _}`.

Two valid id-key expressions exist:
- `id={"inbound-detail-#{@detail.record.id}"}` — recommended; uses the canonical detail-level
  struct; guaranteed non-nil in the `true ->` branch where `@detail` is non-nil by `cond`.
- `id={"inbound-detail-#{@selected_record.id}"}` — also works; `@selected_record.id` equals
  `selected_inbound_id`; but `@selected_record` could theoretically be nil in a corner case
  where the detail resolved from a URL-injected id that is not in the current filtered list.

**Recommended expression: `id={"inbound-detail-#{@detail.record.id}"}`**. The planner should
use this, not `@selected_record.id`. Both yield the same UUID in practice — but `@detail.record.id`
is the struct that is actually rendered, eliminating the nil-crash risk at the template layer.

### Anchor 3 — `preview/tabs.ex:84`: id-keyed motion-tab-swap reference pattern

**VERIFIED [CONFIRMED].** `[VERIFIED: codebase file read]`

```elixir
# preview/tabs.ex:84
<div id={"preview-tab-" <> Atom.to_string(@active_tab)} class="motion-tab-swap">
```

This is the exact id-keyed pattern to mirror. The id interpolates the current atom value
(`:html`, `:text`, `:raw`, `:headers`), causing LiveView to replace the element when the tab
changes. The D-01/D-02 pattern is the same mechanism using the delivery/detail UUID.

### Anchor 4 — Layout-thrashing sweep CLEAN

**VERIFIED [CONFIRMED CLEAN].** `[VERIFIED: codebase grep]`

Banned token grep results against `mailglass_admin/lib/` and `mailglass_admin/assets/css/app.css`:

| Token | Hits in lib/ | Hits in app.css | Verdict |
|-------|-------------|-----------------|---------|
| `transition-height` | 0 | 0 | CLEAN |
| `transition-max-height` | 0 | 0 | CLEAN |
| `transition-padding` | 0 | 0 | CLEAN |
| `transition-all` | 0 | 0 | CLEAN |
| `duration-300` or higher | 0 | 0 | CLEAN |
| `ease-in-out` (as Tailwind class in lib/) | 0 | comment + CSS var only | CLEAN |
| `ease-linear` | 0 | 0 | CLEAN |

**Important nuance for D-06 grep gate:** `app.css` contains two false-positive hits on the
`ease-in-out` pattern:
- Line 117: a comment (`/* ... never ease-in; in-out for on-screen movement... */`)
- Line 120: a CSS custom property definition (`--ease-in-out: cubic-bezier(...)`)

These are design token definitions, not Tailwind utility class usage. The conformance grep gate
MUST NOT produce a false positive on these. Two implementation strategies:

1. **Grep `lib/` only** for ease-related banned tokens (Tailwind class usage is only in HEEx).
   The `app.css` ban on layout-thrashing tokens (`transition-height` etc.) can still cover both.
2. **Use a word-boundary regex** that excludes CSS variable definitions: e.g.,
   `grep -E '(^|[^-])ease-in-out([^-]|$)'` in `app.css` would still hit the comment but
   not the variable definition — fragile. Simpler to restrict ease-class checks to `lib/` only.

**Recommended approach:** In the new `check_motion_conformance.sh`, split the banned-token check
into two passes: (a) `transition-height|transition-max-height|transition-padding|transition-all|duration-300`
grepped across both `lib/` and `assets/css/app.css`; (b) `ease-in-out|ease-linear` grepped
across `lib/` only (HEEx files where Tailwind class usage lives).

### Anchor 5 — GAP-21 a11y attributes ALREADY SATISFIED

**VERIFIED [CONFIRMED OUT OF SCOPE].** `[VERIFIED: codebase grep]`

All GAP-21 required attributes present:
- `aria-current="page"`: `operator/shell.ex:205` and `:229`
- `aria-selected`: `operator/deliveries_list.ex:35-36`, `inbound/records_list.ex:41-42`,
  `preview/tabs.ex:44,54,64,74`
- `role="dialog"` + `aria-modal="true"`: `operator/replay_modal.ex:21-22`,
  `inbound/replay_modal.ex:25-26`

D-05 claim confirmed. No Phase 77 work required for a11y.

### Anchor 6 — `scripts/check_*.sh` conventions

**VERIFIED [CONFIRMED].** `[VERIFIED: codebase file read]`

Conventions from `scripts/check_credo_suppressions.sh` and `scripts/check_dialyzer_ignore.sh`:

1. Shebang: `#!/usr/bin/env bash`
2. Safety: `set -euo pipefail`
3. Logic: grep/awk against target file(s); accumulate `errors` counter; nonzero on hit
4. Exit: `exit 1` with message to stderr on failure; `echo "OK: ..."` to stdout on success
5. CI wiring: added as a `run: bash scripts/check_XXXX.sh` step in the `credo_strict` job
   in `.github/workflows/ci.yml` (same job as `check_credo_suppressions.sh`)

The `check_motion_conformance.sh` script should follow this exact pattern. It is NOT wired
through a mix alias — it is a direct `bash scripts/` invocation.

**Suggested filename:** `scripts/check_motion_conformance.sh`

**Note on `ui-audit.sh`:** The D-06 note says "do NOT add the grep inside `ui-audit.sh`".
`ui-audit.sh` is NOT in `scripts/` (it is a different file, policy-banned from CI). The new
script goes in `scripts/`, not in or near `ui-audit.sh`.

### Anchor 7 — Playwright harness: `e2e/operator.spec.js` + `playwright.config.cjs`

**VERIFIED [CONFIRMED].** `[VERIFIED: codebase file read]`

Key findings:
- Config: `mailglass_admin/playwright.config.cjs` — `baseURL` is `http://127.0.0.1:4101` (or
  `$OPERATOR_BASE_URL`); `webServer.command` starts the OperatorBrowserServer via
  `mix run --no-halt`; test timeout 30s; browser: Chromium (installed via `npx playwright install`)
- Route: `/ops/mail?tenant_id=browser-tenant` then `/ops/mail?tenant_id=browser-tenant&view=deliveries`
- Existing tests use `page.setViewportSize`, `page.goto`, `page.getByTestId`, `page.request.get`
- `page.emulateMedia({ reducedMotion: "reduce" })` is net-new (zero existing uses in e2e/)
- The `openOperator(page)` helper calls reset + login, navigates to the deliveries view, and
  asserts the deliveries list is visible — it is reusable for the new reduced-motion test

**Id-presence assertion design:**
After clicking a delivery row, the URL contains `delivery_id=<uuid>`. The spec can extract the id
with `new URL(page.url()).searchParams.get("delivery_id")` and then assert
`page.locator('#delivery-detail-' + deliveryId)` is present. This is the id-presence assertion
that ExUnit cannot make (the heroicons-inline lesson).

For the inbound twin: a separate test navigating to `/ops/inbound?tenant_id=browser-tenant` and
clicking an inbound record, then asserting `#inbound-detail-<id>`.

**OperatorBrowserServer seed:** Deliveries are seeded via `OperatorFixtures.seed_browser_scenario!()`.
The `browser-selected@example.com` recipient is row 0 in the list. The seed does NOT provide a
fixed UUID — the id is dynamic per test run. The e2e test must click the row, read the URL, and
then assert the id-keyed element.

### Anchor 8 — `mix.exs verify.preview` alias and bundle gate

**VERIFIED [CONFIRMED].** `[VERIFIED: codebase file read]`

```elixir
# mailglass_admin/mix.exs:183-188
"verify.preview": [
  "compile --no-optional-deps --warnings-as-errors",
  "test --warnings-as-errors --exclude flaky",
  "mailglass_admin.assets.build",
  "cmd git diff --exit-code priv/static/"
]
```

The vendored Tailwind binary: `mailglass_admin/tailwind-macos-arm64` (present at root of admin
package). The `mailglass_admin.assets.build` task invokes this binary to compile `assets/css/app.css`
into `priv/static/`.

**Important for D-08:** `verify.preview` is NOT wired into CI — it is a local developer gate.
CI does NOT run `git diff --exit-code priv/static/` as a dedicated step. The bundle clean gate
is enforced by the `verify.preview` convention at PR time (phase executor runs it). The `priv/static/`
diff is in the Hex publish allowlist (`files: ~w(... priv/static/ ...)`), so a stale bundle
would ship the wrong CSS.

**Since D-01/D-02 only add id attributes to HEEx (no new Tailwind classes),** the bundle rebuild
may produce a bit-identical output. Run `mix mailglass_admin.assets.build` and let
`git diff --exit-code priv/static/` confirm — do not skip the step.

---

## Architecture Patterns

### System Architecture Diagram

```
User selects delivery row
        |
        v
LiveView push_patch (URL param: delivery_id=<uuid>)
        |
        v
handle_params → assign_delivery_state
        |
        v
Template renders cond-do branch (true -> when @selected_delivery non-nil)
        |
        ├── WITHOUT id (current bug):
        |     LiveView PATCHES existing <div class="motion-reveal"> in-place
        |     No mount event → mg-reveal does NOT re-fire
        |
        └── WITH id={"delivery-detail-#{@selected_delivery.id}"} (fix):
              id changes per delivery → LiveView REPLACES element
              New element insertion → mg-reveal fires exactly once
              prefers-reduced-motion: reduce block makes animation ~0ms
```

### Pattern 1: Record-Keyed Id for Animation Re-Fire

**What:** Add an id whose value changes when the rendered record changes. LiveView uses ids to
match elements during diff — a changed id means remove-old / insert-new, which triggers CSS
`@keyframes` animations attached to the new element via the `.motion-reveal` class.

**When to use:** Any element that should animate on each selection of a different record, where
the element is always present (not conditionally rendered via `:if`) but its content changes.

**Reference pattern from `preview/tabs.ex:84`:**
```heex
<div id={"preview-tab-" <> Atom.to_string(@active_tab)} class="motion-tab-swap">
  <.tab_content active_tab={@active_tab} ... />
</div>
```

**Fix for `operator_live.ex:442`:**
```heex
<div id={"delivery-detail-#{@selected_delivery.id}"} class="motion-reveal space-y-4">
  <DetailHeader.detail_header delivery={@selected_delivery} ... />
  ...
</div>
```

**Fix for `inbound_live.ex:341`:**
```heex
<div id={"inbound-detail-#{@detail.record.id}"} class="motion-reveal space-y-4">
  <DetailHeader.detail_header detail={@detail} />
  ...
</div>
```

Note: `@detail.record.id` is preferred over `@selected_record.id` (see Anchor 2 correction).

### Pattern 2: Motion CSS Vocabulary (READ-ONLY — no changes)

All six motions are defined in `app.css` and already conform to the UI-SPEC matrix. Summary:

| Class | Keyframe | Duration | Easing | Properties animated |
|-------|----------|----------|--------|---------------------|
| `motion-reveal` | `mg-reveal` | 220ms | ease-out | opacity 0→1, translateY 6px→0 |
| `motion-tab-swap` | `mg-fade-in` | 150ms | ease-out | opacity 0→1 |
| `motion-overlay` | `mg-overlay` | 220ms | ease-out | opacity 0→1, scale 0.98→1 |
| `motion-timeline > *` | `mg-timeline-in` | 220ms + stagger | ease-out | opacity 0→1, translateY 4px→0 |
| row-state | `transition-colors` | 100ms (via `--duration-fast`) | ease-out | color tokens |
| flash | `motion-reveal` (reuse) | 220ms | ease-out | opacity 0→1, translateY 6px→0 |

Global reduced-motion block (`app.css:274-282`) sets all animation/transition durations to
`0.01ms !important` — effectively instantaneous. No per-component variants needed.

### Pattern 3: Shell Conformance Gate Script

**What:** A `check_*.sh` bash script that greps target directories for banned CSS class tokens
and exits nonzero on any hit.

**Conventions** (from `check_credo_suppressions.sh` and `check_dialyzer_ignore.sh`):
```bash
#!/usr/bin/env bash
# [Purpose comment]
set -euo pipefail

errors=0

# grep logic that sets errors=$((errors + 1)) on hits

if [[ $errors -gt 0 ]]; then
  echo "FAIL: [message]" >&2
  exit 1
fi

echo "OK: [message]"
```

**Banned token set (D-06):**

Pass A — grep `mailglass_admin/lib/` and `mailglass_admin/assets/css/app.css`:
- `transition-height`
- `transition-max-height`
- `transition-padding`
- `transition-all`
- `duration-300` (and higher: `duration-[3-9][0-9][0-9]`, `duration-[0-9]{4,}`)

Pass B — grep `mailglass_admin/lib/` ONLY (not app.css, to avoid false positive on CSS vars):
- `ease-in-out` (as a Tailwind utility class in HEEx — the CSS var `--ease-in-out` is legitimate)
- `ease-linear`
- `ease-in\b` (bare ease-in, distinct from ease-in-out)

**CI wiring:** Add as a `run: bash scripts/check_motion_conformance.sh` step in the `credo_strict`
job in `.github/workflows/ci.yml`, after `check_credo_suppressions.sh`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Animation re-fire on element update | JS hooks, phx-mounted events, custom LiveView push_event | Record-keyed `id=` attribute on the animated wrapper | LiveView's diff algorithm handles element replacement automatically when id changes; zero JS needed |
| Reduced-motion CSS coverage | Per-component `motion-reduce:` Tailwind variants | Single global `@media (prefers-reduced-motion: reduce)` block in app.css | Already present at app.css:274-282; covers all six motions with one rule |
| Animation timing > 220ms | Custom keyframes with longer durations | Use `--duration-reveal: 220ms` token | UI-SPEC ceiling is 300ms; all existing tokens are ≤ 220ms; do not author new keyframes |

---

## Common Pitfalls

### Pitfall 1: Using `@selected_record.id` vs `@detail.record.id` for inbound id-key

**What goes wrong:** `@selected_record` is populated from the `records` list and could be nil
if the URL-injected `inbound_id` does not match any record in the current filtered view (e.g.,
pagination, cross-tenant URL). Using `@selected_record.id` in the `true ->` branch (where
`@detail` is non-nil but `@selected_record` might not be) could produce a `nil.id` crash.

**Why it happens:** The `true ->` branch activates when `@detail_error` is falsy AND `@detail`
is non-nil — it does NOT require `@selected_record` to be non-nil. `load_detail` resolves from
the URL param directly; `find_selected_record` resolves from the in-memory `records` list.

**How to avoid:** Use `id={"inbound-detail-#{@detail.record.id}"}`. `@detail.record` is
guaranteed to be an `%InboundRecord{}` struct (non-nil) whenever `@detail` is non-nil.

**Warning signs:** Crash with `** (UndefinedFunctionError) function nil.id/0` on the inbound
surface when a delivery id is injected in the URL with an empty or mismatched tenant filter.

### Pitfall 2: App.css false positive in conformance grep (ease-in-out CSS variable)

**What goes wrong:** The grep gate produces a false positive on `ease-in-out` in `app.css:120`
(`--ease-in-out: cubic-bezier(...)`), causing every CI run to fail.

**Why it happens:** The banned token set includes `ease-in-out` to catch the Tailwind utility
class. But `app.css` legitimately defines `--ease-in-out` as a design token (the custom property
name contains the banned substring).

**How to avoid:** Restrict the `ease-in-out` / `ease-linear` / `ease-in` grep to `lib/` only.
The layout-thrashing token checks (`transition-height`, etc.) can still cover both `lib/` and
`app.css`.

**Warning signs:** `check_motion_conformance.sh` fails locally before any code changes; output
shows `app.css:120` as the offending line.

### Pitfall 3: Skipping the bundle rebuild (D-08)

**What goes wrong:** The Hex tarball ships with a stale `priv/static/app.css` that does not
include any change from the HEEx modification (even a no-op rebuild ensures hash integrity).

**Why it happens:** id attributes in HEEx do not add new Tailwind classes, so the output appears
unchanged — leading to a temptation to skip the rebuild. The `verify.preview` alias will catch
this via `git diff --exit-code priv/static/` only if the rebuild was run.

**How to avoid:** Always run `mix mailglass_admin.assets.build` in the D-08 plan step; commit
the result even if `git diff` shows no change (a no-op rebuild produces the same bytes, so
`--exit-code` passes cleanly).

### Pitfall 4: ExUnit substring tests cannot verify id-attribute presence

**What goes wrong:** A test like `assert html =~ "delivery-detail-"` appears to verify the
id-key was added, but it is a substring match that would pass even if the id attribute format
was wrong (e.g., placed on the wrong element, or present as a class name by mistake).

**Why it happens:** ExUnit's `render_component` and `live/2` + `html_response` return raw HTML
strings. A substring match cannot distinguish `id="delivery-detail-abc123"` from `class="delivery-detail-abc123"`.

**How to avoid:** The id-presence assertion MUST be at the Playwright layer. The e2e test can
assert `page.locator('#delivery-detail-' + deliveryId)` to confirm the id is (a) present and
(b) correctly formatted as an HTML id (not a class or data attribute).

**Warning signs:** ExUnit test passes but animation still does not re-fire in the browser;
id-presence Playwright assertion catches the regression, ExUnit test does not.

---

## Validation Architecture

> This section drives the Nyquist gate for MOTION-01 and MOTION-02.

### MOTION-01: Entrance animations fire exactly once per record selection

**Success criterion (from ROADMAP/REQUIREMENTS):** The `motion-reveal` re-fire bug is fixed —
selecting a different delivery causes the detail pane animation to fire; selecting the same
delivery a second time does not re-fire (because the id is unchanged, LiveView patches in-place).

**Observable truth condition:** After clicking delivery row A, the DOM must contain an element
with `id="delivery-detail-<uuid-A>"`. After clicking delivery row B, the DOM must contain an
element with `id="delivery-detail-<uuid-B>"` (and the old `uuid-A` element must be gone).

**Why ExUnit cannot verify this:** ExUnit substring tests match rendered HTML strings — they
cannot distinguish "id attribute present and correctly keyed" from "id string appears anywhere
in the output". The heroicons-inline lesson: the test would pass even if the id was in a comment
or a CSS class.

**Layer: Playwright e2e (DOM id-presence assertion)**

Test design in `e2e/operator.spec.js`:
```javascript
test("delivery detail pane carries record-keyed id for animation re-fire", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  await openOperator(page);

  // Click first delivery row — triggers delivery selection
  await deliveryRow(page, 0).click();

  // Extract delivery_id from the URL
  const url = new URL(page.url());
  const deliveryId = url.searchParams.get("delivery_id");
  expect(deliveryId).toBeTruthy();

  // Assert the record-keyed id is present in the DOM (not just in a string)
  await expect(page.locator(`#delivery-detail-${deliveryId}`)).toBeVisible();

  // Click a second row and verify the id changes (re-fire correctness)
  await deliveryRow(page, 1).click();
  const url2 = new URL(page.url());
  const deliveryId2 = url2.searchParams.get("delivery_id");
  expect(deliveryId2).not.toEqual(deliveryId);
  await expect(page.locator(`#delivery-detail-${deliveryId2}`)).toBeVisible();
  await expect(page.locator(`#delivery-detail-${deliveryId}`)).toHaveCount(0);
});
```

For the inbound twin, a parallel test navigates to `/ops/inbound`, selects a record, reads the
`inbound_id` URL param, and asserts `#inbound-detail-<id>` is visible. Note: the inbound surface
requires the `mailglass_inbound` optional dep to be available in the browser server — verify
the OperatorBrowserServer seeds inbound records before adding this test. If inbound is not seeded
in the browser scenario, the inbound id-presence test should be stubbed or skipped with a comment
explaining the dependency.

### MOTION-02: Motion respects prefers-reduced-motion; no layout-thrashing

**Success criterion 1:** `prefers-reduced-motion: reduce` suppresses all animation.

**Observable truth condition:** Under reduced-motion emulation, the `#delivery-detail-<id>`
element exists immediately (not hidden by opacity: 0) — the animation is effectively instant.
This is testable via Playwright's `page.emulateMedia({ reducedMotion: "reduce" })` which emulates
the OS-level media query at the browser level.

**Layer: Playwright e2e (media emulation) + shell grep (CSS rule presence)**

Playwright test design (appended to the existing `test.describe` block):
```javascript
test("motion-reveal is suppressed under prefers-reduced-motion", async ({ page }) => {
  // Emulate reduced motion BEFORE navigation
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.setViewportSize({ width: 1280, height: 900 });
  await openOperator(page);

  // Select a delivery
  await deliveryRow(page, 0).click();
  const deliveryId = new URL(page.url()).searchParams.get("delivery_id");
  expect(deliveryId).toBeTruthy();

  // Under reduced-motion, the element must still be present/visible
  // (animation is 0.01ms, not hidden permanently)
  await expect(page.locator(`#delivery-detail-${deliveryId}`)).toBeVisible();
});
```

Note: Playwright's `emulateMedia` sets `window.matchMedia("(prefers-reduced-motion: reduce")`)` 
to `true` at the browser level. The global CSS block at `app.css:274-282` sets
`animation-duration: 0.01ms !important` — the element appears immediately. The test confirms
no regression in element visibility under reduced-motion (the element is not stuck hidden at
`opacity: 0` due to a broken animation).

**Success criterion 2:** No layout-thrashing animation properties.

**Observable truth condition:** Zero occurrences of banned tokens (`transition-height`,
`transition-max-height`, `transition-padding`, `transition-all`, `duration-300+`, `ease-in-out`
as a Tailwind class, `ease-linear`) in the codebase.

**Layer: Shell grep gate (`scripts/check_motion_conformance.sh`)**

The grep gate is the regression guard. It exits nonzero on any hit, blocking the `credo_strict`
CI job. Current baseline: zero hits confirmed by hand (see Anchor 4). The gate catches any
future addition of banned classes.

**Success criterion 3:** All durations ≤ 300ms (actual max 220ms).

**Observable truth condition:** All `--duration-*` custom properties ≤ 300ms; no `duration-300`
or higher Tailwind utility class in HEEx.

**Layer: shell grep gate** (the `duration-300+` check catches Tailwind class regressions).
The CSS custom property values are verified by reading `app.css` — all are ≤ 220ms:
`--duration-instant: 90ms`, `--duration-fast: 150ms`, `--duration-reveal: 220ms`,
`--duration-flash: 200ms`. No grep gate needed for token values (they are stable design tokens,
not utility classes injected via HEEx).

**Success criterion 4:** Keyframes animate transform/opacity only.

**Observable truth condition:** All four `@keyframes` blocks in `app.css` use only `opacity`
and `transform` properties.

**Layer: source read (verified once, monitored by the no-new-CSS rule for this phase)**

Currently verified:
- `mg-reveal`: `opacity 0→1, translateY 6px→0` — CLEAN
- `mg-timeline-in`: `opacity 0→1, translateY 4px→0` — CLEAN
- `mg-fade-in`: `opacity 0→1` — CLEAN
- `mg-overlay`: `opacity 0→1, scale 0.98→1` — CLEAN

Since D-03 and D-04 both specify no CSS changes, no new keyframes are authored in this phase.
The shell grep gate adds coverage against future regressions.

### Sampling Adequacy

The re-fire bug (MOTION-01) is the headline regression risk. Its regression would be:
1. Invisible to ExUnit (substring tests pass even without the id attribute)
2. Invisible to static grep analysis (the `motion-reveal` class is still present)
3. Caught ONLY by Playwright id-presence assertion

This is why the Playwright test is the Nyquist gate for MOTION-01. The existing operator browser
gate already runs in CI (`operator_browser_gate` job, triggered on every PR). The new tests add
to this existing job — no new CI infrastructure needed.

The conformance grep gate (MOTION-02) is additive: it provides CI-enforced regression protection
against future layout-thrashing class additions. It does not replace the manual verification of
the keyframe definitions (which are stable, no-CSS-changes this phase).

### Test Framework Summary

| Property | Value |
|----------|-------|
| ExUnit (admin) | `mix test` in `mailglass_admin/`; 187 tests, 1 pre-existing voice_test failure |
| Playwright | `npm run test:operator-browser` in `mailglass_admin/`; runs against OperatorBrowserServer |
| Shell gate | `bash scripts/check_motion_conformance.sh` (to be authored) |
| Bundle gate | `mix mailglass_admin.assets.build && git diff --exit-code priv/static/` (via `verify.preview`) |
| Quick run | `npm run test:operator-browser` (covers id-presence + reduced-motion tests) |
| Full suite | `mix verify.preview` (compile + ExUnit + bundle gate) |

### Phase Gate (before `/gsd:verify-work`)

1. `bash scripts/check_motion_conformance.sh` — 0 violations
2. `npm run test:operator-browser` (in `mailglass_admin/`) — includes new tests, all green
3. `mix verify.preview` (in `mailglass_admin/`) — ExUnit green, bundle clean

---

## Code Examples

### Example 1: Delivery detail id-key (D-01)

```heex
<%# operator_live.ex:442 — add id attribute; no other changes %>
<div id={"delivery-detail-#{@selected_delivery.id}"} class="motion-reveal space-y-4">
  <DetailHeader.detail_header
    delivery={@selected_delivery}
    replay_targets={@replay_targets}
    latest_replay={latest_replay(@replay_history)}
  />
  ...
</div>
```

### Example 2: Inbound detail id-key (D-02, corrected)

```heex
<%# inbound_live.ex:341 — add id attribute using @detail.record.id, not @selected_record.id %>
<div id={"inbound-detail-#{@detail.record.id}"} class="motion-reveal space-y-4">
  <DetailHeader.detail_header detail={@detail} />
  <Timeline.timeline runs={@runs} />
  ...
</div>
```

### Example 3: Conformance script structure (D-06)

```bash
#!/usr/bin/env bash
# Fail if any banned motion CSS token appears in lib/ or app.css.
# Tokens banned per UI-SPEC Motion Rules (Phase 74 FROZEN contract).
# Reused at Phase 79 as part of the full conformance gate.
set -euo pipefail

LIB="mailglass_admin/lib"
CSS="mailglass_admin/assets/css/app.css"
errors=0

# Pass A: layout-thrashing tokens — check both lib/ and app.css
THRASH_PATTERN='transition-height|transition-max-height|transition-padding|transition-all|duration-300|duration-[4-9][0-9][0-9]|duration-[0-9]{4,}'
if grep -rE "$THRASH_PATTERN" "$LIB" "$CSS" 2>/dev/null; then
  echo "FAIL: banned layout-thrashing token found" >&2
  errors=$((errors + 1))
fi

# Pass B: banned easing classes — lib/ only (app.css defines --ease-in-out as a CSS var)
EASE_PATTERN='ease-in-out|ease-linear|[^-]ease-in[^-]'
if grep -rE "$EASE_PATTERN" "$LIB" 2>/dev/null; then
  echo "FAIL: banned easing class found in lib/" >&2
  errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
  echo "FAIL: motion conformance violations found (see above)" >&2
  exit 1
fi
echo "OK: motion conformance clean."
```

*Note: the exact regex for `ease-in\b` needs to avoid matching `ease-in-out`. Use
`'ease-in\b'` with grep's POSIX word-boundary or test carefully. The planner should
verify the grep command does not produce false positives on `ease-in-out` matches.*

---

## Project Constraints (from CLAUDE.md)

| Constraint | Enforcement |
|------------|-------------|
| No write to `mailglass_admin/priv/static/` without committing the rebuilt bundle | `git diff --exit-code priv/static/` gate in `verify.preview` alias; committed in same PR (D-08) |
| No new dependencies | This phase adds no deps; id attributes and shell scripts require nothing new |
| No brand-book amendment | No new CSS keyframes; no new motion vocabulary; application-only |
| Anti-churn gate: every build task cites a Phase 74 gap-register row at severity ≥ 3 | D-01: GAP-19 sev 3; D-02: folded under GAP-19; D-06: GAP-20 conformance verification; D-07: reduced-motion coverage |
| Engineering DNA: Telemetry — never PII | Not relevant (this phase is UI motion only) |
| Engineering DNA: Errors as structured `%Mailglass.Error{}` | Not relevant (no new error paths) |
| Do not add to `ui-audit.sh` | D-06 explicitly targets `scripts/check_motion_conformance.sh`, not `ui-audit.sh` |
| No stable seam changes (router macro, Auth behaviour, replay semantics) | This phase only adds `id=` attributes and verification tooling; no seam changes |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | HEEx compile, ExUnit | Yes | 1.18 (CI) | — |
| Node.js + npm | Playwright e2e | Yes | 22 (CI, node_modules present) | — |
| Playwright (Chromium) | e2e tests | Yes | installed via `npx playwright install` | — |
| `tailwind-macos-arm64` | Bundle rebuild | Yes | present at `mailglass_admin/tailwind-macos-arm64` | — |
| bash | check_motion_conformance.sh | Yes (macOS + Ubuntu CI) | any | — |
| PostgreSQL | OperatorBrowserServer (e2e seed) | Yes (via CI service container) | 16-alpine (CI) | — |

No missing blocking dependencies.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `@detail.record.id` is preferred over `@selected_record.id` for the inbound id-key | Anchor 2 | Low — both yield the same UUID in practice; the nil-safety argument is a corner-case concern |
| A2 | The `true ->` branch in `inbound_live.ex` cannot have a non-nil `@detail` with a nil `@selected_record` in normal operation | Anchor 2 | Low — reviewed `assign_inbound_state` and `find_selected_record`; both are set in the same call; theoretical edge case requires URL injection |
| A3 | The bundle rebuild will be a no-op (no new Tailwind classes from id attributes) | Anchor 8 / D-08 | Very low — id attributes are not scanned by JIT; confirmed by reviewing app.css and Tailwind JIT behavior |
| A4 | Inbound records are NOT seeded in the current `OperatorFixtures.seed_browser_scenario!()` | Validation Architecture | Medium — not verified directly; if inbound IS seeded, the inbound id-presence test is straightforward; if not, it requires a separate setup step |

---

## Open Questions (RESOLVED)

1. **Are inbound records seeded in the browser scenario?** — **RESOLVED: NOT seeded.**
   - What we know: `OperatorFixtures.seed_browser_scenario!()` seeds delivery rows; the
     e2e spec tests delivery-only flows; no inbound-specific browser tests exist yet.
   - **Resolution (confirmed by pattern-mapper grep of `operator_fixtures.ex` — zero inbound
     hits):** the browser scenario seeds ZERO inbound records. Disposition adopted in
     `77-03-PLAN.md`: the inbound HEEx id-key fix still ships in `77-01` (Task 2), but its
     `#inbound-detail-<id>` Playwright assertion is `test.skip`-ed with a comment documenting
     the seed dependency; remove the skip once Phase 78 seeds an inbound record.

2. **`ease-in\b` grep pattern — avoidance of false positive on `ease-in-out`** —
   **RESOLVED: use `ease-in[^-]`.**
   - What we know: bash `grep -E` on macOS and Linux handles `\b` differently; `ease-in\b`
     may or may not correctly exclude `ease-in-out` depending on the grep variant.
   - **Resolution adopted in `77-02-PLAN.md` (Task 1):** the conformance gate uses
     `ease-in[^-]` (BSD/GNU-portable), NOT `\b`, and scopes the banned-easing Pass B to
     `lib/` ONLY — `app.css:120` legitimately defines `--ease-in-out` as a CSS custom
     property and would otherwise be a false positive.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No id on motion-reveal div (re-fire bug) | Record-keyed `id=` attribute triggers LiveView element replace | Phase 77 (this phase) | Animation fires exactly once per selection, not never |
| Manual layout-thrashing audit (ad-hoc) | `check_motion_conformance.sh` CI gate | Phase 77 (this phase) | Regression-proof; reused at Phase 79 |

---

## Sources

### Primary (HIGH confidence)

- `/Users/jon/projects/mailglass/mailglass_admin/assets/css/app.css` — motion vocabulary
  confirmed (keyframes, tokens, reduced-motion block, stagger cap)
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:442` —
  bare motion-reveal div, no id, @selected_delivery available
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/inbound_live.ex:341` —
  bare motion-reveal twin, no id; @detail available with .record.id
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/preview/tabs.ex:84` —
  id-keyed motion-tab-swap reference pattern confirmed
- `/Users/jon/projects/mailglass/mailglass_admin/e2e/operator.spec.js` — Playwright test
  structure, openOperator helper, URL pattern, delivery row click flow
- `/Users/jon/projects/mailglass/mailglass_admin/playwright.config.cjs` — Chromium, port 4101,
  webServer config
- `/Users/jon/projects/mailglass/scripts/check_credo_suppressions.sh` — shell gate convention
  confirmed (shebang, set -euo pipefail, awk logic, exit 1 pattern)
- `/Users/jon/projects/mailglass/.github/workflows/ci.yml` — CI job structure for
  `credo_strict` and `operator_browser_gate` confirmed
- `/Users/jon/projects/mailglass/mailglass_admin/mix.exs:183-188` — `verify.preview` alias confirmed
- `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md:175-201` — GAP-19, GAP-20, GAP-21 confirmed
- `.planning/phases/74-systematic-audit-and-ui-spec/74-UI-SPEC.md:347-373` — Motion Assignment Matrix, Motion Rules, Phase 77 spec confirmed

### Secondary (MEDIUM confidence)

- LiveView element keying semantics: mechanism confirmed by reading the existing tab-swap pattern at `preview/tabs.ex:84` and the absence of id on the motion-reveal divs. [ASSUMED: LiveView documentation knowledge from training, consistent with observed pattern.]

### Tertiary (LOW confidence)

None.

---

## Metadata

**Confidence breakdown:**
- Anchor verification: HIGH — all file:line anchors confirmed by direct file read
- Fix expressions: HIGH (D-01: confirmed); MEDIUM (D-02: @detail.record.id correction based on template analysis)
- Validation architecture: HIGH — based on direct examination of existing test infrastructure
- Shell gate design: HIGH — based on existing check_*.sh conventions and direct grep verification

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable; no fast-moving dependencies; all verified against live codebase)
