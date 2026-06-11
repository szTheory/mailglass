# Phase 76: Component-Library and Design-System Hardening - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 9 (1 new, 3 modified components, 5 call-site rewires/deletions)
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/mailglass_admin/components_test.exs` | test | request-response | `test/mailglass_admin/inbound/components_test.exs` | exact |
| `lib/mailglass_admin/components.ex` | component | request-response | `lib/mailglass_admin/components.ex:86-114` (existing `badge/1` + `alert_class/1`) | self-analog (additive) |
| `lib/mailglass_admin/operator/deliveries_list.ex` | component | request-response | `lib/mailglass_admin/inbound/records_list.ex` (sibling call site) | exact |
| `lib/mailglass_admin/operator/timeline.ex` | component | event-driven | `lib/mailglass_admin/operator/deliveries_list.ex` (badge rewire pattern) | role-match |
| `lib/mailglass_admin/inbound/records_list.ex` | component | request-response | `lib/mailglass_admin/operator/deliveries_list.ex` (sibling) | exact |
| `lib/mailglass_admin/operator/detail_header.ex` | component | request-response | `lib/mailglass_admin/operator/deliveries_list.ex` (same badge_class shape) | exact |
| `lib/mailglass_admin/inbound/detail_header.ex` | component | request-response | `lib/mailglass_admin/inbound/records_list.ex` (same badge_class shape) | exact |
| `lib/mailglass_admin/operator/support_cards.ex` | component | request-response | `lib/mailglass_admin/operator_live.ex:286-325` (health-card Tier1/Tier2 pattern) | role-match |
| Admin-wide HEEx token migration (~22 files) | component (bulk) | n/a | `lib/mailglass_admin/operator/shell.ex:125,183,207,248` (already-tokenized reference) | exact |

---

## Pattern Assignments

### `test/mailglass_admin/components_test.exs` (test, new file)

**Analog:** `test/mailglass_admin/inbound/components_test.exs` (lines 1-26) and `test/mailglass_admin/operator/shell_test.exs` (lines 1-12)

**Module + use block pattern** (`inbound/components_test.exs:1-23`):
```elixir
defmodule MailglassAdmin.ComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MailglassAdmin.Components
```

**render_component + assert html =~ house pattern** (`inbound/components_test.exs:25-29`, three assertions per atom per Pitfall 5):
```elixir
  describe "status_badge/1 — outbound delivery statuses" do
    test "dispatched renders badge-primary + paper-airplane icon" do
      html = render_component(&Components.status_badge/1, status: :dispatched, size: :sm)
      assert html =~ "badge-primary"
      assert html =~ "hero-paper-airplane"
      assert html =~ "Dispatched"
    end
```

**Negative / refute pattern** (`inbound/components_test.exs:47-48`):
```elixir
      refute html =~ "alice@example.com"
      assert html =~ "a****@e******.com"
```

**Shell test render_component pattern** (`operator/shell_test.exs:11-14`):
```elixir
    test "renders deliveries-orientation testid with frozen copy" do
      html = render_component(&Shell.orientation_strip/1, surface: :deliveries)
      assert html =~ ~s(data-testid="deliveries-orientation")
```

**Token-conformance assertion pattern** (`operator/shell_test.exs:33-37`) — use this form to assert `status_badge/1` emits `text-label` / no raw `text-sm`:
```elixir
    test "uses text-label not text-sm for bullet list" do
      html = render_component(&Shell.orientation_strip/1, surface: :deliveries)
      assert html =~ "text-label"
      refute html =~ ~r/class="[^"]*text-sm/
    end
```

**Coverage rule:** 24 atoms × 3 assertions (class + icon + label) = 72 minimum assertions. One `describe` block per taxonomy table (outbound 14, inbound 6, timeline 4).

---

### `lib/mailglass_admin/components.ex` — add `status_badge/1` (component, additive)

**Analog (self):** existing `badge/1` at lines 91-114 and `alert_class/1` at lines 86-89.

**The house pattern for attr + private literal-string mapping defp** (`components.ex:86-114`):
```elixir
# Private literal-string mapping defp (alert_class pattern, lines 86-89)
defp alert_class(:info), do: "alert-info"
defp alert_class(:success), do: "alert-success"
defp alert_class(:warning), do: "alert-warning"
defp alert_class(:error), do: "alert-error"

# attr declaration with values: list (badge pattern, lines 91-92)
attr :variant, :atom, values: [:warning, :stub], required: true

# @doc since: annotation (line 101)
@doc since: "0.1.0"

# Component with class list (badge/1 :warning clause, lines 102-108)
def badge(%{variant: :warning} = assigns) do
  ~H"""
  <span class="badge badge-warning badge-sm gap-1">
    <.icon name="hero-exclamation-triangle" class="w-3 h-3" /> Error
  </span>
  """
end
```

**Icon rendering pattern** (`components.ex:44-48`) — `hero-*` class on `<span>` with `aria-hidden`:
```elixir
def icon(assigns) do
  ~H"""
  <span class={[@name, @class]} aria-hidden="true"></span>
  """
end
```

**New `status_badge/1` follows this exact shape** — `attr :status, :atom, values: [...]` + `attr :size, :atom, values: [:sm, :md], default: :sm` + component body + three private literal-string defps (`size_class/1`, `status_class/1`, `status_icon/1`, `status_label/1`). The component always emits the base `badge` class; size and status classes are list-merged:
```heex
<span class={["badge", size_class(@size), status_class(@status)]}>
  <span class={[status_icon(@status), "w-3 h-3"]} aria-hidden="true"></span>
  {status_label(@status)}
</span>
```

**JIT discipline (D-05, Pitfall 1):** Every clause of `status_class/1`, `status_icon/1`, `status_label/1` returns a complete literal string with no interpolation. The Tailwind scanner finds `"badge-primary"`, `"hero-paper-airplane"`, etc. as literal strings in `components.ex` and includes them in the bundle. Pattern:
```elixir
defp size_class(:sm), do: "badge-sm"
defp size_class(:md), do: "badge-md"

defp status_class(:dispatched), do: "badge-primary"
defp status_class(:queued), do: "badge-primary"
defp status_class(:sent), do: "badge-primary"
defp status_class(:delivered), do: "badge-success"
# ... one clause per atom — never defp status_class(atom), do: "badge-#{atom}"

defp status_icon(:dispatched), do: "hero-paper-airplane"
defp status_icon(:queued), do: "hero-arrow-path"
# ... one clause per atom — never defp status_icon(atom), do: "hero-#{atom}"

defp status_label(:dispatched), do: "Dispatched"
# ... one clause per atom
```

**`@doc since:`** add `"1.5.0"` to match `mask_recipient/1` at line 127.

---

### `lib/mailglass_admin/operator/deliveries_list.ex` — delete `badge_class/1`, rewire call site (component, call-site rewire)

**Analog (self):** own `badge_class/1` at lines 80-84 is the deletion target. Own call site at line 49 is the rewire target.

**Current call site** (`deliveries_list.ex:49-51`):
```heex
<span class={["badge badge-sm", badge_class(delivery.status)]}>
  {label(delivery.status)}
</span>
```

**After rewire** — replace the `<span>` block entirely; `status_badge/1` emits `badge` + size + color:
```heex
<Components.status_badge status={delivery.status} size={:sm} />
```

**Current deletion target** (`deliveries_list.ex:80-84`):
```elixir
defp badge_class(status) when status in [:delivered, :sent, :dispatched], do: "badge-success"
defp badge_class(:deferred), do: "badge-warning"
defp badge_class(status) when status in [:failed, :bounced, :complained], do: "badge-error"
defp badge_class(:suppressed), do: "badge-warning"
defp badge_class(_status), do: "badge-outline"
```
Delete all 5 clauses. The `label/1` helper at line 86 is NOT deleted — it is used for `delivery.last_event_type` in the meta line at line 59.

**Token migration in same file** — lines 16, 20, 54 contain `gap-3`, `text-base`, `text-sm`, `text-xs`:
```heex
<!-- line 16: gap-3 → gap-sm -->
<div class="flex min-h-64 flex-col items-center justify-center gap-3 p-6 text-center">
<!-- becomes -->
<div class="flex min-h-64 flex-col items-center justify-center gap-sm p-6 text-center">

<!-- line 20: text-sm → text-body -->
<p class="text-sm text-secondary">
<!-- becomes -->
<p class="text-body text-secondary">

<!-- line 44: text-sm → text-body -->
<p class="truncate text-sm font-bold text-base-content">
<!-- becomes -->
<p class="truncate text-body font-bold text-base-content">

<!-- line 47, 54: text-xs → text-label -->
<p class="mono mt-1 text-xs text-secondary">
<!-- becomes -->
<p class="mono mt-1 text-label text-secondary">
```

---

### `lib/mailglass_admin/operator/timeline.ex` — delete `badge_class/1`, rewire call site (component, call-site rewire)

**Analog:** `deliveries_list.ex` badge_class deletion pattern above.

**Current call site** (`timeline.ex:52-54`) — the guard `event_badge(event.type)` remains unchanged (it returns a label string or `nil`; serves as the `:if` condition). Only the `badge_class/1` return value is replaced:
```heex
<span :if={event_badge(event.type)} class={badge_class(event.type)}>
  {event_badge(event.type)}
</span>
```

**After rewire** — the `event_badge/1` guard stays; the rendered atom routes through `status_badge/1`. Since `event_badge/1` returns a string label (not an atom), the guard test is kept but the rendered content becomes `status_badge/1`. The timeline badge atoms are: `:webhook_replay_requested`, `:webhook_replay_succeeded`, `:webhook_replay_failed`, `:reconciled`. These are available as the `event.type` atom:
```heex
<Components.status_badge :if={event_badge(event.type)} status={event.type} size={:sm} />
```

**Current deletion target** (`timeline.ex:130-135`):
```elixir
defp badge_class(type)
     when type in [:webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed],
     do: "badge badge-outline badge-error"

defp badge_class(:reconciled), do: "badge badge-outline badge-warning"
defp badge_class(_type), do: "badge badge-outline"
```
Note: this is the "full-string structural outlier" (GAP-03) — it emits `"badge badge-outline badge-error"` (includes the base `badge` class and `badge-outline` modifier together). After deletion, `status_badge/1` handles all classes. Delete all 3 clauses.

**Token migration in same file** — lines 21, 25, 56, 57, 59, 64 contain `text-base`, `text-sm`, `text-xs`, `gap-3`:
```heex
<!-- line 19: gap-3 → gap-sm -->
<div class="mb-4 flex items-center justify-between gap-3">
<!-- line 21: text-base → text-body -->
<h3 class="text-base font-bold text-base-content">Event timeline</h3>
<!-- line 25: text-sm → text-body -->
<p class="text-sm text-secondary">
<!-- line 51, 56, 57, 59, 64: text-xs → text-label -->
<span class="text-xs text-secondary">Chronological order</span>
<p class="text-xs text-secondary">
<p class="mono text-xs text-secondary">
<p class="mono text-xs text-secondary">
```

---

### `lib/mailglass_admin/inbound/records_list.ex` — delete `badge_class/1`, rewire call site + normalize `record_outcome/1` adapter (component, call-site rewire + adapter)

**Analog:** `deliveries_list.ex` rewire pattern above; `inbound/detail_header.ex` for the inbound singular-atom normalization pattern.

**Current call site** (`records_list.ex:55-57`):
```heex
<span class={["badge badge-sm", badge_class(record_outcome(record))]}>
  {outcome_label(record_outcome(record))}
</span>
```

**After rewire** — normalize_outcome adapter is applied before passing to `status_badge/1`:
```heex
<Components.status_badge status={normalize_outcome(record_outcome(record))} size={:sm} />
```

**Current deletion target** (`records_list.ex:97-101`):
```elixir
defp badge_class(:accept), do: "badge-success"
defp badge_class(:no_match), do: "badge-warning"
defp badge_class(outcome) when outcome in [:reject, :bounce, :failed], do: "badge-error"
defp badge_class(:ignore), do: "badge-outline"
defp badge_class(_outcome), do: "badge-outline"
```
Delete all 5 clauses (GAP-04 — singular atoms).

**New `normalize_outcome/1` adapter** (D-02 — admin-side only; never touches `mailglass_inbound`):
```elixir
# Admin-side adapter: normalizes inbound @outcomes singular atoms (:accept, :reject, :bounce)
# to past-tense atoms matching the Components.status_badge/1 taxonomy (:accepted, :rejected, :bounced).
# :no_match, :ignore, :failed_ingest, and nil pass through unchanged.
# The `mailglass_inbound` @outcomes schema (locked 1.0 contract) is never modified.
defp normalize_outcome(:accept), do: :accepted
defp normalize_outcome(:reject), do: :rejected
defp normalize_outcome(:bounce), do: :bounced
defp normalize_outcome(atom), do: atom
```

**`outcome_label/1` and `record_outcome/1`** — both remain unchanged; `outcome_label/1` is no longer used in the badge span (removed when call site is replaced), but may be used elsewhere in the template. Audit for remaining usages before deleting.

**Token migration in same file** — same pattern as `deliveries_list.ex` (it is a sibling clone): `gap-3` → `gap-sm`, `text-sm` → `text-body`, `text-xs` → `text-label` on lines 22, 26, 50, 53, 60.

---

### `lib/mailglass_admin/operator/detail_header.ex` — delete `badge_class/1`, rewire call site (component, call-site rewire)

**Analog (self):** own `badge_class/1` at lines 81-85 (latent duplicate of `deliveries_list.ex:80-84`, GAP-05).

**Current call site** (`detail_header.ex:21-23`):
```heex
<span class={["badge", badge_class(@delivery.status)]}>
  {label(@delivery.status)}
</span>
```

**After rewire** — note the detail header does NOT pass `badge-sm`; `status_badge/1` defaults to `:sm` per D-05:
```heex
<Components.status_badge status={@delivery.status} />
```

**Current deletion target** (`detail_header.ex:81-85`) — verbatim duplicate of `deliveries_list.ex:80-84`:
```elixir
defp badge_class(status) when status in [:delivered, :sent, :dispatched], do: "badge-success"
defp badge_class(:deferred), do: "badge-warning"
defp badge_class(status) when status in [:failed, :bounced, :complained], do: "badge-error"
defp badge_class(:suppressed), do: "badge-warning"
defp badge_class(_status), do: "badge-outline"
```
Delete all 5 clauses (GAP-05 latent duplicate).

**Token migration in same file** — `gap-3`, `gap-4`, `text-sm`, `text-xs` scattered throughout:
```heex
<!-- line 31: gap-3 → gap-sm -->
<dl class="grid gap-3 text-sm text-secondary sm:grid-cols-2">
<!-- line 31: text-sm → text-body -->
<dl class="grid gap-3 text-sm text-secondary sm:grid-cols-2">
<!-- becomes -->
<dl class="grid gap-sm text-body text-secondary sm:grid-cols-2">

<!-- lines 33,36,40,44,49,53: text-xs → text-label -->
<dt class="text-xs font-bold uppercase tracking-[0.08em]">Tenant</dt>
<!-- becomes (leave font-bold uppercase tracking-[0.08em] untouched) -->
<dt class="text-label font-bold uppercase tracking-[0.08em]">Tenant</dt>

<!-- line 17: gap-4 → gap-md -->
<div class="flex flex-wrap items-start justify-between gap-4">
<!-- becomes -->
<div class="flex flex-wrap items-start justify-between gap-md">
```

---

### `lib/mailglass_admin/inbound/detail_header.ex` — delete `badge_class/1`, rewire call site + normalize outcome adapter (component, call-site rewire + adapter)

**Analog (self):** own `badge_class/1` at lines 142-146 (latent duplicate of `records_list.ex:97-101`, GAP-06).

**Current call site** (`inbound/detail_header.ex:40-42`):
```heex
<span class={["badge", badge_class(@outcome)]}>
  {outcome_label(@outcome)}
</span>
```

**After rewire** — the `@outcome` assign comes from `assigns.detail[:outcome]` (set at line 27). Apply `normalize_outcome/1` before `status_badge/1`:
```heex
<Components.status_badge status={normalize_outcome(@outcome)} />
```

**Current deletion target** (`inbound/detail_header.ex:142-146`) — verbatim duplicate of `records_list.ex:97-101`:
```elixir
defp badge_class(:accept), do: "badge-success"
defp badge_class(:no_match), do: "badge-warning"
defp badge_class(outcome) when outcome in [:reject, :bounce, :failed], do: "badge-error"
defp badge_class(:ignore), do: "badge-outline"
defp badge_class(_outcome), do: "badge-outline"
```
Delete all 5 clauses (GAP-06 latent duplicate).

**`normalize_outcome/1` adapter** — same clauses as `records_list.ex` above; either extract to `Components` as a public helper or duplicate with an identical docstring. Shared helper recommended (D-02 "Claude's Discretion") to prevent re-divergence. If extracted to `Components`, it is `Components.normalize_inbound_outcome/1`.

**`outcome_label/1` at lines 148-155** — remains unchanged; check remaining usages before removing.

**Token migration in same file** — `gap-3`, `gap-4`, `text-sm`, `text-xs` on lines 54, 56, 60, 64, 68, 73, 82, 84, 85. Same `dt/dd` label pattern as `operator/detail_header.ex`:
```heex
<!-- line 54: gap-3 → gap-sm, text-sm → text-body -->
<dl class="grid gap-3 text-sm text-secondary sm:grid-cols-2">
<!-- becomes -->
<dl class="grid gap-sm text-body text-secondary sm:grid-cols-2">

<!-- lines 56,60,64,68,73,76: text-xs → text-label (leave font-bold uppercase tracking-[0.08em]) -->
<dt class="text-xs font-bold uppercase tracking-[0.08em]">Tenant</dt>
<!-- becomes -->
<dt class="text-label font-bold uppercase tracking-[0.08em]">Tenant</dt>

<!-- line 82: text-sm → text-body -->
<p class="text-sm text-base-content">{replay_hint(@outcome)}</p>
<!-- becomes -->
<p class="text-body text-base-content">{replay_hint(@outcome)}</p>
```

---

### `lib/mailglass_admin/operator/support_cards.ex` — Tier1/Tier2 restructure then tokenize (component, structural restructure)

**Analog:** `operator_live.ex:286-325` — the health-card pattern with `text-display font-bold` + conditional semantic color + `card bg-base-200 border border-base-300 rounded-box p-md`.

**Health-card pattern to reuse** (`operator_live.ex:287-294`, already token-clean):
```heex
<div class="card bg-base-200 border border-base-300 rounded-box p-md">
  <div
    class={"text-display font-bold #{if(@support_summary && @support_summary.failed_ingest.count > 0, do: "text-error", else: "text-success")}"}
    data-testid="operator-overview-health-failures"
  >
    <%= if @support_summary, do: @support_summary.failed_ingest.count, else: "—" %>
  </div>
  <div class="text-label text-secondary">Recent failures</div>
</div>
```

**Health Count Colors per UI-SPEC** — apply these to Tier 1 counts:
- Failures (`failed_ingest.count > 0`) → `text-error`
- Orphan backlog (`orphan_backlog.count > 0`) → `text-warning`
- All-clear / suppression count → `text-secondary` (informational)

**Current flat grid** (`support_cards.ex:29`):
```heex
<div class="mt-4 grid gap-4 xl:grid-cols-2">
  <article class="rounded-box border border-base-300 bg-base-100 p-4">
    ...
  </article>
  ...four articles...
</div>
```

**Target Tier 1 structure** (restructure-first per D-07 — apply token classes to the final markup):
```heex
<!-- Tier 1: non-zero/actionable — full card containers -->
<div class="flex flex-col gap-lg mt-md">
  <article :if={@support_summary.failed_ingest.count > 0}
           class="card bg-base-200 border border-base-300 rounded-box p-lg">
    <div class="text-display font-bold text-error">{@support_summary.failed_ingest.count}</div>
    <p class="text-body text-secondary">Recent failures (last 24h)</p>
    <!-- drilldown button retained -->
  </article>
  <article :if={@support_summary.orphan_backlog.count > 0}
           class="card bg-base-200 border border-base-300 rounded-box p-lg">
    <div class="text-display font-bold text-warning">{@support_summary.orphan_backlog.count}</div>
    <p class="text-body text-secondary">Orphan backlog</p>
  </article>
</div>

<!-- Tier 2: zero-state compact row / informational items -->
<div class="border-t border-base-300 flex gap-md items-center py-sm text-label text-secondary">
  <!-- zero-count items + suppression count (always Tier 2 — informational) -->
</div>
```

**`@suppression_count` note** — this assign comes from `operator_live.ex:615` (wired in Phase 75). The `support_cards.ex` component currently only receives `@support_summary` and `@support_state` attrs. A new `attr :suppression_count, :integer, default: nil` is needed to receive it (D-06 says same data map; suppression comes from the separate `@suppression_count` assign).

**D-07 constraint:** FIRST restructure the markup from flat grid to Tier1/Tier2, THEN apply `text-body` / `text-label` / `gap-sm/md/lg` token classes. Never apply tokens to the old flat markup.

---

### Admin-wide HEEx token migration (~22 files) (bulk token migration)

**Analog:** `lib/mailglass_admin/operator/shell.ex` — already-tokenized, the canonical reference.

**Target idiom examples from shell.ex** (lines 125, 183, 207, 248, 287, 326):
```heex
<!-- gap-sm -->
<div class="flex items-center gap-sm border-b border-base-300 px-md py-md">

<!-- text-label -->
<span class="text-label font-bold uppercase tracking-[0.12em] text-secondary">

<!-- text-body -->
<p :if={@subtitle} class="text-body text-secondary">{@subtitle}</p>

<!-- text-body on nav links -->
"flex min-h-11 items-center gap-sm rounded-field border-l-2 px-sm text-body transition-colors ease-out"

<!-- gap-sm + text-body together -->
class="motion-reveal flex items-start gap-sm rounded-box border border-success bg-success/10 px-md py-sm text-body text-base-content"

<!-- text-label in list -->
<ul class="mt-2 grid gap-1 text-label text-secondary">
```

**Token mapping (D-08)**:
```
text-sm   → text-body
text-base → text-body
text-xs   → text-label
gap-3     → gap-sm
gap-4     → gap-md
gap-6     → gap-lg
```

**Footgun rules (from RESEARCH.md Gap 3)**:
- `text-xs font-bold uppercase tracking-[0.08em]` pattern: replace `text-xs` → `text-label` only; leave `font-bold`, `uppercase`, `tracking-[0.08em]` untouched (38 occurrences in `dt` labels)
- `hover:text-base-content` is NOT `text-base`: use `\btext-base\b` word-boundary grep to avoid false matches
- `gap-2`, `gap-1` are NOT migrated — only `gap-3`, `gap-4`, `gap-6`
- `#ffffff` in `preview/tabs.ex:113` inline `style=` attribute: replace `background: #ffffff` → `background: var(--color-base-100)` (not a Tailwind class — handled as a one-off CSS var fix)
- `tracking-[0.08em]` (43 occurrences): NOT in scope — leave untouched

**Grep gate (run before and after to confirm zero violations)**:
```bash
grep -rE '\btext-(sm|base|xs)\b' mailglass_admin/lib/ --include="*.ex"
grep -rE '\bgap-(3|4|6)\b' mailglass_admin/lib/ --include="*.ex"
grep -rE '#[0-9a-fA-F]{3,6}\b' mailglass_admin/lib/ --include="*.ex"
```

**Excluded from migration (D-09):** `operator_live.ex:279-362` (the Overview/orientation markup already token-clean in Phase 75). The remaining `text-sm/base/xs` in `operator_live.ex` at line 363+ (the pre-existing Deliveries `:else` branch) ARE in scope.

---

## Shared Patterns

### Private Literal-String Mapping (JIT discipline)
**Source:** `lib/mailglass_admin/components.ex:86-89` (`alert_class/1`)
**Apply to:** all new `status_class/1`, `status_icon/1`, `status_label/1`, `size_class/1` functions

```elixir
# Correct — literal strings, one clause per atom
defp alert_class(:info), do: "alert-info"
defp alert_class(:success), do: "alert-success"
defp alert_class(:warning), do: "alert-warning"
defp alert_class(:error), do: "alert-error"

# WRONG — tree-shaken to nothing at build time
# defp status_class(atom), do: "badge-#{atom}"
```

### Icon Rendering (decorative, aria-hidden)
**Source:** `lib/mailglass_admin/components.ex:44-48` (`icon/1`)
**Apply to:** `status_badge/1` icon span

```elixir
<span class={[@name, @class]} aria-hidden="true"></span>
```

New badge icon span follows same shape with literal `status_icon(@status)` class:
```heex
<span class={[status_icon(@status), "w-3 h-3"]} aria-hidden="true"></span>
```

### `render_component` Test Pattern
**Source:** `test/mailglass_admin/inbound/components_test.exs:25-29`
**Apply to:** `test/mailglass_admin/components_test.exs`

```elixir
html = render_component(&RecordsList.records_list/1, records: [], selected_record: nil)
assert html =~ "No inbound records"
```

### Health-Card Count Color Pattern
**Source:** `lib/mailglass_admin/operator_live.ex:287-294`
**Apply to:** `support_cards.ex` Tier 1 count styling

```heex
<div
  class={"text-display font-bold #{if(@support_summary && @support_summary.failed_ingest.count > 0, do: "text-error", else: "text-success")}"}
  data-testid="operator-overview-health-failures"
>
  <%= if @support_summary, do: @support_summary.failed_ingest.count, else: "—" %>
</div>
<div class="text-label text-secondary">Recent failures</div>
```

### `dt` Label Pattern (token-clean form)
**Source:** `lib/mailglass_admin/operator/shell.ex:125` + existing `detail_header.ex` occurrences
**Apply to:** all `dt` label elements during token migration — replace `text-xs` only; leave the rest:

```heex
<!-- Before -->
<dt class="text-xs font-bold uppercase tracking-[0.08em]">Tenant</dt>
<!-- After -->
<dt class="text-label font-bold uppercase tracking-[0.08em]">Tenant</dt>
```

---

## No Analog Found

All files have strong analogs. No entries.

---

## Metadata

**Analog search scope:** `mailglass_admin/lib/`, `mailglass_admin/test/`
**Files scanned:** 9 source files + grep across 22+ token-migration targets
**Pattern extraction date:** 2026-06-04
