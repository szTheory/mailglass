# Phase 119: App-shell + Nav + Overview redesign - Pattern Map

**Mapped:** 2026-06-26
**Files analyzed:** 6 changed (shell.ex, operator_live.ex, heroicons-inline.js, app.css, operator.spec.js, judgment.spec.js)
**Analogs found:** 8 / 8

This is a **surgical correction** of existing operator LiveView templates. Every change has a same-file
or sibling-file analog already in the codebase — the executor copies the established pattern, it does
not invent. All line numbers below are verified against the current tree.

## File Classification

| Changed file | Role | Data Flow | Closest Analog | Match Quality |
|--------------|------|-----------|----------------|---------------|
| `mailglass_admin/lib/mailglass_admin/operator/shell.ex` | component (shell/nav chrome) | request-response | itself (existing Deliveries/Inbound nav_link + nav_pill instances) | exact (in-file clone) |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | LiveView (caller/render) | request-response | itself (existing `<.link patch={build_path...}>` + conditional renders) | exact (in-file clone) |
| `mailglass_admin/assets/vendor/heroicons-inline.js` | config (icon vendor map) | transform (build-time) | existing `chart-bar` entry (line 28) | role-match (no `squares-2x2` analog) |
| `mailglass_admin/priv/static/app.css` | build artifact | n/a | rebuilt only IF a new utility class lands (D-12) | n/a |
| `mailglass_admin/e2e/operator.spec.js` | test (Playwright e2e) | request-response | itself (VERIF-02 block 352-368) | exact (in-file edit) |
| `mailglass_admin/e2e/judgment.spec.js` | test (Playwright gate) | request-response | itself (drafted `test.fixme` gates 77-112) | exact (flip + assertion fix) |

## Pattern Assignments

### 1. New sidebar `nav_link` ("Overview")  —  `shell.ex`

**Analog:** `shell.ex:231-243` — the existing Deliveries + Inbound `nav_link` instances inside
`<nav aria-label="Operator sections">`.

```elixir
# shell.ex:230-244 (sidebar <nav>)
<nav class="flex flex-col gap-xs p-sm" aria-label="Operator sections">
  <Components.nav_link
    label="Deliveries"
    icon="hero-paper-airplane"
    href={@deliveries_path}
    active={@active == :deliveries}
  />
  <Components.nav_link
    :if={@inbound_available?}
    label="Inbound"
    icon="hero-inbox-arrow-down"
    href={@inbound_path}
    active={@active == :inbound}
  />
</nav>
```

**Copy:** the exact attr shape (`label` / `icon` / `href` / `active={@active == ...}`). Place the new
Overview instance **above** Deliveries (first child of the `<nav>`).
**Change:** `label="Overview"`; `active={@active == :overview}`; `href={@overview_path}` (a NEW assign —
the bare operator root, no `?view=`; see Shared Pattern A); **omit** the `:if={...}` gate (Overview is
always shown, unlike Inbound). `icon=` — see Pattern 7 (icon embed decision).

### 2. New mobile `nav_pill` ("Overview")  —  `shell.ex`

**Analog:** `shell.ex:253-265` — the existing Deliveries + Inbound `nav_pill` instances inside the
mobile-only `<nav class="... md:hidden">`.

```elixir
# shell.ex:253-265 (mobile <nav>)
<nav class="flex items-center gap-xs md:hidden" aria-label="Operator sections">
  <Components.nav_pill label="Deliveries" href={@deliveries_path} active={@active == :deliveries} />
  <Components.nav_pill :if={@inbound_available?} label="Inbound" href={@inbound_path} active={@active == :inbound} />
</nav>
```

**Copy:** the `nav_pill` attr shape (`label` / `href` / `active`). `nav_pill` has no `icon` attr (verified
`components.ex:271-285`) — do NOT add one.
**Change:** `label="Overview"`; `href={@overview_path}`; `active={@active == :overview}`; place above
Deliveries; omit the `:if` gate (always shown).

### 3. Extending an `attr ... values:` enum  —  `shell.ex:201`

**Analog (same file, same attr):** `shell.ex:201` is the exact line to edit. Sibling enum examples in the
same module confirm the form: `shell.ex:206` (`values: [:system, :light, :dark]`), `shell.ex:369`
(`values: [:deliveries, :inbound, :preview]` — a 3-value enum identical in shape to the target).

```elixir
# shell.ex:201 — current
attr(:active, :atom, values: [:deliveries, :inbound], required: true)
# target
attr(:active, :atom, values: [:overview, :deliveries, :inbound], required: true)
```

**Copy:** the `attr(:name, :atom, values: [...], required: true)` form (already in use 3 lines down).
**Change:** add `:overview` as the first enum member. No other attr semantics change.

### 4. Wrapping a presentational component in `<.link patch={...}>`  —  `operator_live.ex`

**Analog:** `operator_live.ex:586-592` — the "Back to deliveries" `<.link patch={build_path(...)}>` that
wraps non-interactive content with a focus-ring class. Also `shell.ex:343-352` (tenant_selector) shows the
canonical wrap-a-block-in-a-patch-link with `mg-focus-ring ... hover:border-primary`.

```elixir
# operator_live.ex:586-592 — <.link patch={build_path(...)}> wrapper
<.link
  patch={build_path(@base_path, @filter_params, nil, @dark_chrome)}
  data-testid="operator-detail-back"
  class="mg-focus-ring btn btn-ghost !h-11 min-h-11 md:hidden"
>
  Back to deliveries
</.link>
```

```elixir
# shell.ex:344-352 — wrap-a-block pattern with focus-ring + hover:border-primary (the styling analog)
<.link
  patch={tenant_switch_path(@current_uri, tenant.id)}
  class="mg-focus-ring flex min-h-11 items-center justify-between gap-md rounded-field border border-base-300 bg-base-100 px-md py-sm text-body hover:border-primary"
>
  ...presentational content...
</.link>
```

**Copy:** wrap the `<Components.stat_card .../>` call at the **call site** (operator_live.ex Overview
branch, ~`:381` and ~`:397`) in a `<.link patch={...} class="block mg-focus-ring rounded-box hover:border-primary transition-colors ease-out duration-(--duration-fast)" aria-label="...">`. The `mg-focus-ring` +
`hover:border-primary` classes are both already present in these analogs.
**Change:** Do NOT embed an `<a>` inside `stat_card` (D-06) — `stat_card` (`components.ex:380-412`) is a
pure `<article>` with no inner interactive element, so a wrapping link is nested-interactive-clean. Wrap
**only** the failures + suppressions cards; leave Orphan backlog (`phx-click` drilldown) and Overall status
(no link) unwrapped.

### 5. Constructing a filtered Deliveries path via `build_path`  —  `operator_live.ex`

**Analog:** `operator_live.ex:425-432` — the soon-to-be-deleted "View Deliveries" card already calls
`build_path` with a `Map.put(@filter_params, "view", "deliveries")`. This is the exact call shape to reuse
for the drill-throughs (then the surrounding nav block is deleted per D-04). `build_path_with_view/3`
(`:922-925`) is the named helper that encapsulates the same `Map.put("view", "deliveries")` step.

```elixir
# operator_live.ex:425-432 — existing build_path call with a view param
build_path(
  @base_path,
  Map.put(@filter_params, "view", "deliveries"),
  nil,
  @dark_chrome
)
```

**`build_path/5` signature** (`operator_live.ex:898-920`): `(base_path, filter_params, delivery_id,
dark_chrome, support_state \\ default)`. The **4-arg call is correct** (5th defaults) — already the form
used at `:425` and `:587`.

**Copy:** the 4-arg `build_path(@base_path, filter_params, nil, @dark_chrome)` form.
**Change:** chain a second `Map.put` for status —
`Map.put(@filter_params, "view", "deliveries") |> Map.put("status", "failed")` (and `"suppressed"` for the
suppressions card). `:failed`/`:suppressed` are already valid in `@status_values` (`operator_live.ex:34`),
so no filter plumbing is needed. `build_path` already strips `page=1`, rejects blanks, and merges theme
(`:910-913`) — do not hand-build query strings.

### 6. Conditionally rendering a component on an all-clear / empty predicate  —  `operator_live.ex`

**Analog (in-file conditional renders gated on summary/count assigns):**
- `operator_live.ex:377` — `<%= if blank_to_nil(@filter_params["tenant_id"]) do %>` gates the whole health
  block on a tenant assign.
- `support_cards.ex:87` — `:if={@support_summary && @support_summary.orphan_backlog.count > 0}` is the
  canonical **null-guarded** count predicate (the `@support_summary && ...` guard form).
- `support_cards.ex:169-176` — `:if={not (@support_summary && @support_summary.failed_ingest.count > 0)}`
  shows the all-clear / zero-state negation already in use.

```elixir
# support_cards.ex:87 — the null-safe count-predicate analog to copy
<article :if={@support_summary && @support_summary.orphan_backlog.count > 0} ...>
```

**Copy:** the `@support_summary && <predicate>` guard form — it is the established way this codebase avoids
a nil raise on summary access.
**Change:** gate the `orientation_strip` (currently unconditional at `operator_live.ex:375`) on the
all-clear/empty state. **CRITICAL (RESEARCH Pitfall 4):** `all_clear?/1` (`operator_live.ex:1150-1152`)
does `summary.failed_ingest.count == 0 and ...` and **raises on nil**. The render gate MUST null-guard:
`@support_summary && all_clear?(@support_summary) && @suppression_count in [0, nil]`. The same guarded
condition drives the subtitle predicate (D-10, RESEARCH Code Examples §"Subtitle predicate"). The
orientation strip copy (`shell.ex:392-410`) stays byte-frozen — only its render condition changes.

### 7. Embedding a new heroicon SVG in `heroicons-inline.js` + rebuilding  —  `heroicons-inline.js` + `app.css`

**Analog (nearest STRUCTURAL example — there is NO `squares-2x2`/`home` analog; both are absent):**
`heroicons-inline.js:28` — the `"chart-bar"` entry. The icon map is a flat `var icons = { "<name>":
"<single-line raw SVG string>" , ... }` object (`heroicons-inline.js:23`). The header comment
(`:16-19`) documents the exact add procedure.

```javascript
// heroicons-inline.js:28 — entry structure: key (no "hero-" prefix) → single-line escaped SVG string
"chart-bar": "<svg xmlns=\"http://www.w3.org/2000/svg\" fill=\"none\" viewBox=\"0 0 24 24\" stroke-width=\"1.5\" stroke=\"currentColor\" aria-hidden=\"true\" data-slot=\"icon\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" d=\"...\"/></svg>",
```

**No analog exists for `hero-squares-2x2`** — verified absent from the icon map (embedded keys: arrow-path,
arrow-uturn-left, bell-slash, chart-bar, check-circle, clock, device-phone-mobile, envelope, envelope-open,
exclamation-circle, exclamation-triangle, eye, hand-thumb-up, inbox, inbox-arrow-down, inbox-stack,
lifebuoy, lock-closed, magnifying-glass, minus-circle, moon, paper-airplane, pencil-square,
question-mark-circle, sun, window, x-circle; building-office-2/chart-bar/display/vertical-align per the
broader plugin set). `home` is also absent.

**Decision branch (planner/executor):**
- **Option A (no embed — RESEARCH recommendation):** use the already-embedded `hero-chart-bar` (line 28,
  semantically "at-a-glance metrics") — no `heroicons-inline.js` edit, no rebuild, no TokenParityTest risk.
- **Option B (UI-SPEC preference `hero-squares-2x2`):** add a new `"squares-2x2": "<svg ...>"` entry copying
  the line-28 entry's exact escaping/format (heroicons v2.2.0 24/outline source per `:13`), then run
  `mix mailglass_admin.assets.build` and commit the rebuilt `priv/static/app.css` in the same commit.

**Copy:** the entry format (escaped single-line SVG, key without `hero-` prefix) + the documented rebuild
procedure (`:18-19`).
**Change:** add one new key IF Option B. **Asset landmine (D-12, RESEARCH Pitfall 5):** a fresh
`assets.build` re-emits raw-inline daisyUI theme blocks that break TokenParityTest — run
`mix test mailglass_admin/test/mailglass_admin/token_parity_test.exs` (NOTE: NOT `.../components/...`)
**before** committing the bundle. Skip the rebuild entirely if no new class/icon lands (Option A).

### 8. Flipping a Playwright `test.fixme`→`test` + rewriting an assertion  —  `judgment.spec.js` / `operator.spec.js`

**Analog A — the gate flip (`judgment.spec.js:77-112`):** two drafted gates already encode the Phase 119
end-state, fixme'd until this phase lands.

```javascript
// judgment.spec.js:77 + :102 — flip test.fixme → test
test.fixme("nav-active-correctness: Overview route highlights Overview, not Deliveries", async ({ page }) => { ... });
test.fixme("no-nav-duplication: populated Overview renders no in-page Navigate card block", async ({ page }) => { ... });
```

**Copy:** the gate bodies as-is — they already assert the correct end-state (Overview has `aria-current`,
no `operator-overview-nav`).
**Change (REQUIRED, not just a fixme flip — RESEARCH Pitfall 3):** `judgment.spec.js:87` asserts
`toHaveAttribute("aria-current", "false")`, but `nav_link` emits `aria-current={@active && "page"}`
(`components.ex:230`) — Phoenix **omits** the attribute when inactive (unit-confirmed: `components_test.exs`
`refute html =~ ~s(aria-current="page")`). Rewrite line 87 to
`await expect(deliveriesLink).not.toHaveAttribute("aria-current", "page")` (or
`getByRole("link", { name: "Deliveries", current: false })`). Without this edit the flipped gate fails
immediately on the Deliveries assertion.

**Analog B — the VERIF-02 rewrite (`operator.spec.js:352-368`):** the existing structural test asserts the
soon-deleted block IS visible.

```javascript
// operator.spec.js:361-367 — current assertions
await expect(page.getByTestId("operator-overview")).toBeVisible();
await expect(page.getByTestId("operator-overview-health")).toBeVisible();
await expect(page.getByTestId("operator-overview-nav")).toBeVisible();   // ← line 367: DELETE this
```

**Copy:** keep the `operator-overview` + `operator-overview-health` assertions (`:361`, `:364`) and the
test scaffolding (viewport, `openOperator`, `page.goto` tenant-scoped Overview).
**Change:** delete/rewrite line 367 (the `operator-overview-nav` `toBeVisible` assertion) since D-04
deletes that block. Leaving it turns the operator browser gate red on a green-only-forward floor (D-09,
Pitfall 2 — directly opposes `judgment.spec.js:111`'s `toHaveCount(0)`).

## Shared Patterns

### A. Overview href construction (`@overview_path` assign)
**Source:** `shell.ex:55-63` `surface_paths/4` + call site `operator_live.ex:827-833`.
**Apply to:** Patterns 1 + 2 (both nav instances need the bare-root href).
```elixir
# shell.ex:55-63 — surface_paths builds {deliveries, inbound} from base_path + carried query
def surface_paths(base_path, active, dark_chrome, tenant_id \\ nil) do
  root = operator_root(base_path, active)
  query = build_query(tenant_id, dark_chrome)
  %{deliveries: root <> query, inbound: path_join(root, "inbound") <> query}
end
```
The Overview link needs the **operator root with no `?view=`** — which is exactly `root <> query` already
computed here. Cleanest: extend `surface_paths/4` to also return `overview: root <> query` (the bare root)
and thread a new `overview_path` attr into the shell. Fallback (RESEARCH A1, LOW risk): strip `view` from
`@deliveries_path` at the caller. Either is a small caller edit; the deliveries path differs from overview
only by the `view=deliveries` param.

### B. Motion tokens (no new CSS — D-11)
**Source:** `components.ex:232-233` (`nav_link`) + `shell.ex:301`/`:309` (`flash_region` `.motion-reveal`).
**Apply to:** the drill-through link hover (Pattern 4) and any Overview mount reveal.
```
transition-colors ease-out duration-(--duration-fast)   # nav_link active-change token
motion-reveal                                            # flash_region reveal token (reduced-motion-safe)
```
Reuse ONLY these existing token classes. No new `@keyframes`, no `ease-in`, no height/width transitions.
Reduced-motion neutralization is inherited (no new motion CSS = no new compliance work).

### C. aria-current emission (do NOT hand-roll)
**Source:** `components.ex:230` (`nav_link`) + `components.ex:275` (`nav_pill`): `aria-current={@active && "page"}`.
**Apply to:** all three nav items. The shell active logic is ALREADY correct (`shell.ex:235`
`@active == :deliveries`). The only caller fix is `operator_live.ex:349` literal `active={:deliveries}` →
`active={@view}` (`@view` resolves to `:overview`/`:deliveries`/`:inbound`, set at `operator_live.ex:836`).
Thread `active={@view}` through the Inbound caller too, or Inbound regresses to a false Overview highlight
(D-03). Do NOT add manual `aria-current` in templates — the primitive emits it; the enabled branch is
required (the disabled `<span>` branch at `components.ex:208` omits it).

## No Analog Found

| Element | Role | Reason | Nearest structural example |
|---------|------|--------|----------------------------|
| `hero-squares-2x2` SVG entry | icon (config) | Not embedded in `heroicons-inline.js`; neither is `home`. Only relevant if UI-SPEC's `squares-2x2` is chosen over the embedded `chart-bar`. | `heroicons-inline.js:28` (`chart-bar` entry) — copy its escaped-single-line SVG format |

Everything else has an in-file or sibling-file analog. This phase invents **nothing** new structurally —
it is deletion + one literal swap + cloning existing nav instances + wrapping existing primitives in
existing link patterns + flipping/fixing existing test gates.

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/operator/` (shell.ex, support_cards.ex),
`mailglass_admin/lib/mailglass_admin/` (operator_live.ex, components.ex),
`mailglass_admin/assets/vendor/` (heroicons-inline.js), `mailglass_admin/e2e/` (operator.spec.js,
judgment.spec.js).
**Files scanned:** 7.
**Pattern extraction date:** 2026-06-26.

## PATTERN MAPPING COMPLETE

**Phase:** 119 - App-shell + Nav + Overview redesign
**Files classified:** 6 changed
**Analogs found:** 8 / 8 (7 exact in-file/sibling clones; 1 role-match — the absent `squares-2x2` icon points at the `chart-bar` structural example)

### Coverage
- Files with exact analog: 5 (shell.ex, operator_live.ex, operator.spec.js, judgment.spec.js, app.css-by-omission)
- Files with role-match analog: 1 (heroicons-inline.js — `chart-bar` entry as the embed template)
- Files with no analog: 0 (the only "no analog" is a single icon glyph, with a documented structural template)

### Key Patterns Identified
- Nav items (link + pill) are cloned in-file from the existing Deliveries/Inbound instances; the only deltas are label, always-shown (drop the `:if`), `active={@active == :overview}`, and the bare-root `@overview_path` href.
- Drill-through = wrap the presentational `stat_card` `<article>` in an existing-style `<.link patch={build_path(...)}>` with `mg-focus-ring`/`hover:border-primary` (both already in the codebase); never mutate the primitive (D-06).
- All conditional renders on summary/count must use the established `@support_summary && <predicate>` null-guard form — `all_clear?/1` raises on nil (RESEARCH Pitfall 4).
- The two test seams are NOT pure flips: `judgment.spec.js:87` needs the `aria-current="false"` → `not.toHaveAttribute("aria-current","page")` assertion fix, and `operator.spec.js:367` must drop the deleted-block assertion (D-09 / Pitfalls 2 & 3).

### File Created
`.planning/phases/119-app-shell-nav-overview-redesign/119-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. The planner can reference each analog (file:line) directly in PLAN.md action steps.
