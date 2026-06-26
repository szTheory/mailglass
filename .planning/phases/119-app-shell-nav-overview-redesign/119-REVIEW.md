---
phase: 119-app-shell-nav-overview-redesign
reviewed: 2026-06-26T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/e2e/operator.spec.js
  - mailglass_admin/e2e/judgment.spec.js
  - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Phase 119: Code Review Report

**Reviewed:** 2026-06-26
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Phase 119 lands SHELL-01/02/03: Overview nav identity, active-state fix, deleted Navigate block,
drill-through health stat cards, empty-pane-only orientation strip, and triage microcopy. The core
correctness and security goals are met — null-safe gate is correct, banned phrases are absent,
tenant_id is preserved in drill-through links, `hero-chart-bar` is embedded, the compiled CSS bundle
is undisturbed, and the judgment gates are properly armed with the correct `not.toHaveAttribute`
assertion. No injection surface or auth bypass was introduced.

Three warnings and two info items were found. No critical (BLOCKER) issues.

## Warnings

### WR-01: `operator_root/2` missing `:overview` clause — latent FunctionClauseError

**File:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex:160-161`

**Issue:** `operator_root/2` has only two clauses:

```elixir
defp operator_root(base_path, :inbound), do: trim_inbound(base_path)
defp operator_root(base_path, :deliveries), do: base_path
```

The public `surface_paths/4` now accepts `active=:overview` as a valid value (the attr enum was
extended to `[:overview, :deliveries, :inbound]`), and `surface_paths/4` calls `operator_root/2`
with its `active` argument directly. If any caller ever passes `active=:overview`, the function
crashes with `FunctionClauseError` at runtime — no compile-time or Dialyzer signal.

All current callers pass `:deliveries` or `:inbound` hardcoded, so the crash path is dormant
today. However the public signature implies `:overview` is valid, and the next engineer to call
`surface_paths("/operator", :overview, false, tenant_id)` would encounter a runtime crash with no
warning. The enum was extended without updating the private function it feeds into.

**Fix:** Add a fallback clause that treats `:overview` the same as `:deliveries` (the overview
surface shares the operator root path):

```elixir
defp operator_root(base_path, :inbound), do: trim_inbound(base_path)
defp operator_root(base_path, _active), do: base_path
```

Or add an explicit `:overview` clause for clarity:

```elixir
defp operator_root(base_path, :inbound), do: trim_inbound(base_path)
defp operator_root(base_path, :overview), do: base_path
defp operator_root(base_path, :deliveries), do: base_path
```

---

### WR-02: `assign_overview_state/2` does not assign `:deliveries_path` to the socket

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:856-870`

**Issue:** `assign_overview_state/2` assigns `:overview_path` and `:inbound_path` from the
computed paths (lines 860-861) but does not assign `:deliveries_path`:

```elixir
socket
|> assign(:view, :overview)
|> assign(:support_summary, support_summary)
|> assign(:suppression_count, suppression_count)
|> assign(:overview_path, paths.overview)
|> assign(:inbound_path, paths.inbound)
# :deliveries_path is never set here
```

By contrast, `assign_delivery_state/3` does not set these path assigns either — path assigns are
recomputed at `render/1` time and injected into local assigns (lines 340-346). So the template
access to `@deliveries_path` is currently safe because render always rebinds it.

However the asymmetry is fragile. The socket carries a stale `:deliveries_path` value from
whatever the previous state was — or none at all on the first overview mount before
`assign_delivery_state` has ever run. If a future refactor reads
`socket.assigns.deliveries_path` outside of `render/1` (e.g., in a `handle_event` or a Phoenix
`push_patch` path), it will get the wrong or missing value with no compile-time signal.

Additionally, `assign_overview_state` IS the one function that consciously adds path assigns —
the deliberate inclusion of `:overview_path` and `:inbound_path` implies `:deliveries_path`
should be there too but was missed.

**Fix:** Add `:deliveries_path` to the socket assign pipe in `assign_overview_state/2`:

```elixir
socket
|> assign(:view, :overview)
|> assign(:support_summary, support_summary)
|> assign(:suppression_count, suppression_count)
|> assign(:overview_path, paths.overview)
|> assign(:deliveries_path, paths.deliveries)   # add this
|> assign(:inbound_path, paths.inbound)
```

---

### WR-03: Bare `rescue _ -> nil` swallows all exceptions in `assign_overview_state/2`

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:822-832` and `839-843`

**Issue:** Both `support_summary` and `suppression_count` load paths use a bare rescue:

```elixir
try do
  apply(support_summary_module(), :summarize_tenant, [...])
rescue
  _ -> nil
end
```

This catches `UndefinedFunctionError`, `BadArityError`, `FunctionClauseError`, `ArgumentError`,
and any other programming error alongside the intended `UndefinedFunctionError` (when the module
is not loaded). A typo in the module name or an arity mismatch would silently produce nil stats
and show the all-clear strip incorrectly — there is no logging or telemetry event on the rescue
path.

This pattern is pre-existing (not introduced in this phase) and is a documented degradation
behavior. However since this phase added visible UI behavior contingent on the nil outcome (the
all-clear strip, the triage subtitle, the calm paragraph), a silent failure now produces a visible
and potentially misleading result: "Your delivery system is healthy." when the read model simply
errored out.

**Fix:** Narrow the rescue to `UndefinedFunctionError` (the intended degradation case) and emit a
telemetry event on unexpected exceptions:

```elixir
try do
  apply(support_summary_module(), :summarize_tenant, [...])
rescue
  UndefinedFunctionError -> nil
  e ->
    :telemetry.execute([:mailglass_admin, :overview, :summary_error], %{}, %{error: e})
    nil
end
```

## Info

### IN-01: `surface_paths/4` tests do not assert `:overview` key with tenant or theme params

**File:** `mailglass_admin/test/mailglass_admin/operator/shell_test.exs:42-77`

**Issue:** The five `surface_paths/4` tests (lines 43-76) assert `:deliveries` and `:inbound`
path values but none assert `:overview` path values across the different tenant/theme
combinations. The only `:overview` key test lives inside the `aria-current nav resolution`
describe block at line 318-329, which tests one specific case. The tenant+theme combinations
(`tenant_id=northstar&theme=dark`, blank tenant, no-query) are not tested for `:overview`.

This is not a bug — the `:overview` and `:deliveries` values are both `root <> query` (identical
at runtime), so if `:deliveries` is correct, `:overview` is too. But a future change that
differentiates the two would not be caught by the current test.

**Fix:** Add `:overview` assertions alongside the existing `:deliveries` assertions in each
`surface_paths/4` test, e.g.:

```elixir
test "carries tenant_id across surfaces so nav preserves scope" do
  paths = Shell.surface_paths("/ops/mail", :deliveries, false, "northstar")

  assert paths.overview == "/ops/mail?tenant_id=northstar"   # add
  assert paths.deliveries == "/ops/mail?tenant_id=northstar"
  assert paths.inbound == "/ops/mail/inbound?tenant_id=northstar"
end
```

---

### IN-02: No test that the Overview nav target preserves the current tenant (parity gap with Inbound nav test)

**File:** `mailglass_admin/test/mailglass_admin/operator_live_test.exs:958-963`

**Issue:** `operator_live_test.exs` has a test at line 958 ("rendered Inbound nav target
preserves the current tenant") that asserts `/ops/mail/inbound?tenant_id=#{@tenant_id}` appears
in the rendered HTML. There is no analogous test asserting that the new Overview nav target
(`/ops/mail?tenant_id=#{@tenant_id}`, no `view=` param) appears in the rendered HTML.

The `shell_test.exs` at line 318 tests that `surface_paths` returns the `:overview` key pointing
to the bare root, and the inline render test at line 282 checks the href equals `/operator`. But
neither a `live/2`-rendered integration test confirms the tenant_id is carried on the Overview
nav link as rendered from the full LiveView mount.

**Fix:** Add a parity test alongside the Inbound nav test:

```elixir
test "rendered Overview nav target preserves the current tenant", %{conn: conn} do
  conn = operator_conn(conn)
  {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

  # Overview nav link should point to bare root with tenant_id, no view= param
  assert html =~ "/ops/mail?tenant_id=#{@tenant_id}"
  refute html =~ "/ops/mail?tenant_id=#{@tenant_id}&view="
end
```

---

_Reviewed: 2026-06-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
