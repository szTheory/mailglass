---
phase: 76-component-library-and-design-system-hardening
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 26
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/assets/vendor/heroicons-inline.js
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
  - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex
  - mailglass_admin/lib/mailglass_admin/inbound/timeline.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
  - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
  - mailglass_admin/lib/mailglass_admin/operator/timeline.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex
  - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
  - mailglass_admin/lib/mailglass_admin/preview/tabs.ex
  - mailglass_admin/lib/mailglass_admin/preview_live.ex
  - mailglass_admin/test/mailglass_admin/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
findings:
  critical: 3
  warning: 4
  info: 3
  total: 10
status: issues_found
---

# Phase 76: Code Review Report

**Reviewed:** 2026-06-04
**Depth:** standard
**Files Reviewed:** 26
**Status:** issues_found

## Summary

Phase 76 shipped a unified `Components.status_badge/1`, a vendored heroicons-inline.js Tailwind plugin, design-system token migration, and inbound sibling components. The badge consolidation and token migration are structurally correct and the inbound components faithfully mirror the operator design contract.

Three blockers are present. Two are crash-path `FunctionClauseError` risks: one in `SuppressionCard.body_copy/1` (no fallback clause) and one in `OperatorLive.handle_event("open_support_exemplar", ...)` (unconditional `.id` access on a potentially-nil `selected_delivery`). The third is a Phoenix.Component attribute-declaration mismatch: `:suppressed` is in `@status_values` and flows into `status_badge/1` at runtime, but it is absent from the `attr :status, values:` list, which will emit a compile-time warning and indicates a contract gap between the badge and the filter set. Four warnings cover a dead attribute (`can_reveal?`), an unguarded `apply` in the delivery-state path, a CSS z-index duplication, and a logic gap in the Tier 2 separator rendering. Three info items cover a weak test assertion, `body_copy` for `headline`, and the `heroicons-inline.js` `module.exports` note.

---

## Critical Issues

### CR-01: `SuppressionCard.body_copy/1` has no fallback clause — FunctionClauseError on novel suppression shapes

**File:** `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex:55-57`

**Issue:** `body_copy/1` is called unconditionally at line 40 whenever `@suppression_state` is truthy. The three clauses cover `%{reversibility: :immutable}`, `%{reversibility: :reversible}`, and `%{reversibility_copy: copy}`. Any suppression state map that has a different `:reversibility` atom (e.g. `:permanent`, `:expires_at`) or has neither `:reversibility` nor `:reversibility_copy` raises a `FunctionClauseError` in the LiveView render, crashing the socket. `headline/1` has the same gap — it handles `nil` and two `:reversibility` atoms but no fallback for other shapes.

**Fix:**
```elixir
# Add a catch-all to both private functions
defp body_copy(_suppression_state), do: ""

defp headline(%{reversibility: other}), do: other |> Atom.to_string() |> String.capitalize()
defp headline(_suppression_state), do: "Suppressed"
```
At minimum add `defp body_copy(_), do: ""` and `defp headline(_), do: "Suppressed"` so novel shapes degrade gracefully rather than crashing the socket.

---

### CR-02: `OperatorLive.handle_event("open_support_exemplar", ...)` crashes when `selected_delivery` is nil

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:152`

**Issue:** The handler reads:
```elixir
delivery_id = blank_to_nil(params["delivery_id"]) || socket.assigns.selected_delivery.id
```
`socket.assigns.selected_delivery` is initialized to `nil` in `mount/3`. When the `open_support_exemplar` event is triggered from the support cards and `params["delivery_id"]` is blank (e.g. from the orphan-backlog drilldown which passes `phx-value-event_id` but not `phx-value-delivery_id`), this crashes with `UndefinedFunctionError` (nil.id). The test fixture always has a selected delivery so this path is not covered.

**Fix:**
```elixir
delivery_id =
  blank_to_nil(params["delivery_id"]) ||
    (socket.assigns.selected_delivery && socket.assigns.selected_delivery.id)

if is_nil(delivery_id) do
  {:noreply, socket}
else
  {:noreply,
   push_patch(socket,
     to: build_path(socket.assigns.base_path, socket.assigns.filter_params,
           delivery_id, socket.assigns.dark_chrome, support_state)
   )}
end
```

---

### CR-03: `:suppressed` is in `@status_values` but absent from `status_badge/1`'s `attr :status, values:` list

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:32` and `mailglass_admin/lib/mailglass_admin/components.ex:132-155`

**Issue:** `@status_values` includes `:suppressed` (line 32 of `operator_live.ex`). `DeliveriesList` renders `<Components.status_badge status={delivery.status} />` for every row. When a delivery has `status: :suppressed`, Phoenix.Component emits a compile-time warning because `:suppressed` is not declared in the `values:` list for `attr :status`. The runtime fallback clause catches it silently, but the contract is broken: the badge component's declared contract disagrees with the values that actually flow into it. This is the kind of mismatch that causes the badge to render a generic `badge-outline` "Unknown" label for a real operational status, misleading operators.

**Fix:** Add `:suppressed` to the `values:` list and add explicit clauses in `status_class/1`, `status_icon/1`, and `status_label/1`:
```elixir
# In attr :status, values:
:suppressed,

# status_class
defp status_class(:suppressed), do: "badge-warning"

# status_icon
defp status_icon(:suppressed), do: "hero-minus-circle"

# status_label
defp status_label(:suppressed), do: "Suppressed"
```

---

## Warnings

### WR-01: `EvidenceCard.can_reveal?` attr is declared but never read in the template

**File:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:27`

**Issue:** `attr :can_reveal?, :boolean, default: true` is declared but the template never uses `@can_reveal?`. The "Reveal raw source" button visibility is controlled solely by `@reveal_state != :revealed`. If the intent was to gate the button on an authorization check performed in the parent (i.e. hide the button when the operator does not have the capability), that gate is silently non-functional. Any operator who can see the evidence card gets the "Reveal raw source" button regardless of their `:reveal_raw` capability. The capability check happens in `authorize_reveal/1` only after the button is clicked, but the button should not be shown at all to unauthorized operators.

**Fix:** Either wire the attr into the template:
```heex
<button
  :if={@evidence && @reveal_state != :revealed && @can_reveal?}
  ...
>
```
and pass the pre-computed `can_reveal?` from `InboundLive` (which has access to `socket.assigns.operator_auth`), or remove the dead attr if the click-time gate is intentional.

---

### WR-02: `load_support_summary/2` in `assign_delivery_state/3` is called without error handling

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:799-807`

**Issue:** `assign_overview_state/2` wraps `apply(support_summary_module(), :summarize_tenant, [...])` in `try/rescue` (lines 598-608). But `assign_delivery_state/3` calls `load_support_summary/2` at line 583 without any guard — `load_support_summary` uses a bare `apply` with no rescue (lines 799-807). If `Mailglass.Operator.SupportSummary` is absent or raises, the delivery detail view crashes the socket. The overview path degrades to `nil`; the delivery path does not.

**Fix:** Apply the same `try/rescue` pattern:
```elixir
defp load_support_summary(filter_params, _selected_delivery) do
  try do
    apply(support_summary_module(), :summarize_tenant, [
      %{
        tenant_id: filter_params["tenant_id"],
        window_hours: parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
      }
    ])
  rescue
    _ -> nil
  end
end
```

---

### WR-03: Tier 2 separator dot is rendered even when both flanking spans are hidden — leading orphaned bullet

**File:** `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex:169-171`

**Issue:** The separator between "No failures" and "No orphan backlog" at lines 169-171:
```heex
<span
  :if={not (...failed_ingest.count > 0) and not (...orphan_backlog.count > 0)}
  aria-hidden="true"
>·</span>
```
This span renders when BOTH zero-state spans are shown — which is correct. However, if `@support_summary` is `nil` (module unavailable), the condition `not (@support_summary && @support_summary.failed_ingest.count > 0)` evaluates to `true` for all three expressions, so both "No failures" and "No orphan backlog" are shown alongside the separator even though there is no data. More concretely: when `@support_summary` is nil AND `@suppression_count` is nil, the Tier 2 row renders "No failures · No orphan backlog · Active suppressions: —" with separators but the `aria-hidden="true"` separator at line 175 (fixed `·` before the suppression count) is always emitted even when the two preceding spans are both absent (e.g. both counts are non-zero showing only in Tier 1). This produces a leading orphaned `·` in the Tier 2 strip.

**Fix:** Guard the always-present suppression separator with the same `:if` condition pattern used for the other separators, or restructure the Tier 2 row with a proper CSS gap/list separator that never orphans.

---

### WR-04: `heroicons-inline.js` uses `module.exports` — may fail with ESM-mode Tailwind v4 runtimes

**File:** `mailglass_admin/assets/vendor/heroicons-inline.js:59`

**Issue:** The plugin file uses `module.exports = { handler: ... }`. The comment at the top states this targets the Tailwind v4 standalone binary, which "does not expose Node.js built-in modules". However `module.exports` is itself a CommonJS/Node.js global that may or may not be available depending on how the standalone binary evaluates `@plugin` files. The vendored `daisyui.js` uses the same pattern, which implies the current build works, but the comment creates a contradiction: it claims to avoid Node.js APIs while relying on one. If a future standalone binary version switches to strict ESM evaluation, this will silently produce an empty plugin.

**Fix:** Add a self-registration guard consistent with how `daisyui.js` resolves it, or verify at the next standalone binary upgrade that the IIFE + `module.exports` pattern still works. At minimum, update the comment to remove the contradiction:
```js
// module.exports is available in the Tailwind v4 standalone binary's
// CommonJS-mode plugin evaluator (confirmed with v4.x.x binary).
```

---

## Info

### IN-01: `components_test.exs` — inbound components test asserts `"Accept"` not `"Accepted"` for the normalized label

**File:** `mailglass_admin/test/mailglass_admin/inbound/components_test.exs:68`

**Issue:** The test asserts `html =~ "Accept"` for a record with `outcome: :accept`. After normalization this becomes `:accepted` → label `"Accepted"`. The assertion passes because `"Accepted"` contains `"Accept"` as a substring, but it would also pass incorrectly if the badge rendered just `"Accept"` (the raw outcome string), masking a regression where normalization was skipped. The assertion should use the precise label.

**Fix:**
```elixir
assert html =~ "Accepted"
```

---

### IN-02: `PreviewLive.safe_scenario_atom/1` returns `:error` (atom) not `{:error, reason}` tuple — inconsistent with `with` error branch

**File:** `mailglass_admin/lib/mailglass_admin/preview_live.ex:420-424`

**Issue:** `safe_scenario_atom/1` returns `:error` on `ArgumentError` rescue (line 423). The `with` chain at line 90-93 expects `{:ok, _}` on success; any non-`{:ok, _}` value falls through to the `else` block. The `else` block has a specific match for `{:error, {:preview_props_raised, msg}}` and a catch-all `_`. So `:error` is caught by the catch-all and routes to "Scenario not found". This is functionally correct by accident — the bare `:error` atom happens to fall into the right else branch — but the inconsistency with `safe_mailable_atom/1` (which also returns `:error`) means both functions behave identically through the `with` catch-all rather than through named error tuples. The design is fragile against any future restructuring of the `else` block.

**Fix:** For consistency and intent clarity:
```elixir
defp safe_scenario_atom(str) do
  {:ok, String.to_existing_atom(str)}
rescue
  ArgumentError -> {:error, :not_found}
end
```

---

### IN-03: Dead `heroicons.js` vendor file alongside the new `heroicons-inline.js`

**File:** `mailglass_admin/assets/vendor/heroicons.js` (not reviewed, but sibling)

**Issue:** Both `heroicons.js` (the original, Node.js-dependent) and `heroicons-inline.js` (the new standalone-binary-compatible plugin) exist in the vendor directory. The `app.css` `@plugin` directive now points to `heroicons-inline`. The original `heroicons.js` is no longer referenced and becomes dead weight in the build artifact. If both were somehow loaded, the `matchComponents("hero", ...)` registration would be duplicated.

**Fix:** Remove `mailglass_admin/assets/vendor/heroicons.js` once the migration is confirmed stable. If it must be kept for reference, add a `// DEPRECATED:` comment at the top.

---

_Reviewed: 2026-06-04_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
