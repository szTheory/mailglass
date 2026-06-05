---
phase: 75-information-architecture-navigation-and-orientation
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - lib/mailglass/operator/suppressions.ex
  - lib/mailglass/repo.ex
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/preview_live.ex
  - mailglass_admin/docs/design-system.md
  - mailglass_admin/e2e/operator.spec.js
  - reference/demo_app/assets/e2e/demo.spec.js
  - test/mailglass/operator/suppressions_test.exs
  - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
  - mailglass_admin/test/mailglass_admin/preview_live_test.exs
findings:
  critical: 0
  warning: 6
  info: 5
  total: 11
status: issues_found
---

# Phase 75: Code Review Report

**Reviewed:** 2026-06-04
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Phase 75 adds an Operator Overview landing branch to `OperatorLive`, extracts a
shared, surface-keyed `Shell.orientation_strip/1` component reused across the
deliveries, inbound, and preview surfaces, and adds a `count_active_suppressions/1`
read-model function (backed by a new `Repo.aggregate/3` delegate). The diff is
mostly additive and the security posture is preserved: tenant scoping, no PII in
the new surfaces (health cards are counts only), no telemetry added, and no
event-ledger mutation. The runtime-module-indirection seam (`suppression_count_module/0`
+ try/rescue degradation) is correctly applied for the new overview data.

No BLOCKER-class defects were found. The findings below are robustness, test-quality,
and documentation-accuracy issues. The most material concerns are (1) the
deliveries-view `load_support_summary/2` path is NOT wrapped in the same
try/rescue degradation the overview path uses, so a failing/unconfigured support
module crashes the deliveries detail view; (2) a degradation test that does not
actually exercise the degradation path it claims to cover; and (3) the `Shell`
moduledoc and architectural boundary claim ("never reaches the dev-preview
surface") that this phase contradicts by calling `orientation_strip/1` from
`PreviewLive`.

## Warnings

### WR-01: Deliveries-view support-summary load lacks the degradation guard the overview path has

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:796-806` (and call site `:582`)
**Issue:** In `assign_overview_state/2` the support-summary call is defensively
wrapped (`:597-610`):
```elixir
try do
  apply(support_summary_module(), :summarize_tenant, [...])
rescue
  _ -> nil
end
```
But the deliveries detail path calls `load_support_summary/2` (`:582`), which is
NOT wrapped:
```elixir
defp load_support_summary(filter_params, _selected_delivery) do
  apply(support_summary_module(), :summarize_tenant, [...])  # no rescue
end
```
This phase establishes the degradation contract for the overview ("show em-dash
on error, never crash"). The deliveries view, which renders the same
`SupportCards` from the same module, will crash the LiveView if
`Mailglass.Operator.SupportSummary` raises (e.g. `:repo` unconfigured raises
`Mailglass.ConfigError`, or a transient Postgres error). The two paths now have
inconsistent failure semantics for the identical data source. (Pre-existing code,
but phase 75 made the inconsistency visible by introducing the guarded sibling —
the overview's resilience makes the deliveries view's fragility a regression in
expectations.)
**Fix:** Extract the guarded fetch into one helper and use it from both paths:
```elixir
defp safe_summarize(filter_params) do
  try do
    apply(support_summary_module(), :summarize_tenant, [
      %{
        tenant_id: filter_params["tenant_id"],
        window_hours:
          parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
      }
    ])
  rescue
    _ -> nil
  end
end
```
Then `load_support_summary(filter_params, _selected) -> safe_summarize(filter_params)`
and have `assign_overview_state` reuse it. `SupportCards`/health cards already
nil-guard `@support_summary`, so `nil` renders cleanly.

### WR-02: "suppression count degradation" test does not exercise the degradation path

**File:** `mailglass_admin/test/mailglass_admin/operator_live_test.exs:890-904`
**Issue:** The test is named
`"suppression count degradation renders em-dash in text-secondary when count errors"`
but its body never forces `count_active_suppressions/1` to error or return nil.
It mounts a healthy tenant (count = 0) and only asserts the health row renders.
The inline comment concedes the gap: "either as number or em-dash — both are
valid render outputs." This is a green-by-construction test that provides zero
coverage of the `nil`/error branch (`operator_live.ex:310`,
`if is_nil(@suppression_count), do: "—"`) and the `suppression_count_module/0` +
try/rescue seam it purports to validate. A real regression in the degradation
path would not turn this test red.
**Fix:** Drive the actual nil branch — e.g. point `suppression_count_module/0` at
a module whose `count_active_suppressions/1` raises (via a config/override seam
analogous to how the production indirection resolves the module), or assert the
positive case with seeded suppressions AND a separate test that stubs the count
module to raise and asserts the em-dash with `class~="text-secondary"`:
```elixir
# with a raising stub wired through the indirection seam:
assert html =~ ~s(data-testid="operator-overview-health-suppressions")
assert html =~ "—"
```

### WR-03: `Shell` moduledoc and boundary claim contradicted by PreviewLive usage

**File:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex:1-28` (claim);
contradicted by `mailglass_admin/lib/mailglass_admin/preview_live.ex:292`
**Issue:** The `Shell` moduledoc states the shell "is a within-surface concern,
not a cross-mount one — **it never reaches the dev-preview surface**." Phase 75
adds `orientation_strip/1` to this module as a `def` (public) and calls it from
`PreviewLive` (`:292`, `surface={:preview}`), which IS the dev-preview surface.
The module now spans both surfaces, so the moduledoc is factually wrong and the
stated architectural boundary (operator shell vs. dev preview) is broken: the
preview surface now has a hard compile-time dependency on
`MailglassAdmin.Operator.Shell`. A reader trusting the moduledoc would
mis-reason about coupling.
**Fix:** Either (a) move `orientation_strip/1` + its `copy_for/1` into a
surface-neutral module (e.g. `MailglassAdmin.Components.OrientationStrip`) that
all three surfaces depend on, leaving `Shell` operator-only; or (b) update the
`Shell` moduledoc to state that `orientation_strip/1` is the one cross-surface
component intentionally shared with dev-preview, and remove the "never reaches
the dev-preview surface" sentence.

### WR-04: `@inbound_path` resolved via `Map.get` fallback creates a latent assign-or-fallback split

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:257`
**Issue:**
```elixir
inbound_path: Map.get(assigns, :inbound_path, paths.inbound),
```
`:inbound_path` is assigned only by `assign_overview_state/2` (`:634`), never by
`assign_delivery_state/2`. So in the deliveries view the render falls back to
`paths.inbound`, while in overview it uses the stored assign. The two values are
computed from the same `surface_paths/3` inputs today, so they coincide — but the
divergence is silent and fragile: any future change to how overview derives
`:inbound_path` (e.g. carrying a filter into the inbound link) will not apply in
the deliveries view, and the bug will be invisible because both branches "work."
This is also a LiveView change-tracking smell: conditionally-present assigns
read with `Map.get/3` defeat compile-time assign checks.
**Fix:** Assign `:inbound_path` unconditionally in both `assign_delivery_state/2`
and `assign_overview_state/2` (or compute it once in `handle_params/3`), then read
`@inbound_path` directly in `render/1` without the `Map.get` fallback. This makes
the two views provably consistent.

### WR-05: Overview "View Deliveries" / nav path relies on `view` smuggled through `filter_params`

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:334-342` and `:713-716`
**Issue:** The overview "View Deliveries" CTA builds its target with
`Map.put(@filter_params, "view", "deliveries")` and passes the merged map into
`build_path/5`, which treats `view` as just another query key. Separately,
`build_path_with_view/3` does the same `Map.put(..., "view", "deliveries")`. The
`view` switch is therefore carried as an untyped string key threaded through the
generic filter map in two different code paths, with no single helper owning the
"go to deliveries" URL construction. `normalize_filter_params/2` does not include
`view`, so `view` survives in URLs only because `build_path` blindly forwards
unknown keys. This is brittle: if `build_path` ever starts filtering to a known
key set (a reasonable hardening), the navigation silently breaks, and the two
duplicated `Map.put` sites can drift.
**Fix:** Introduce one helper, e.g. `deliveries_view_path(base_path, filter_params,
dark_chrome)`, used by both the CTA and `apply_filters`, that explicitly sets the
`view` param. Document `view` as a first-class URL param alongside the filters so
future allow-listing of query keys preserves it.

### WR-06: `@doc since:` tags on new functions are inaccurate (version provenance wrong)

**File:** `lib/mailglass/repo.ex:137` and `lib/mailglass/operator/suppressions.ex` (new `count_active_suppressions/1`, no since tag)
**Issue:** `Repo.aggregate/3` is annotated `@doc since: "1.4.5"`, but this code is
introduced in the phase-75 (v1.7) work — 1.4.5 already shipped to Hex. The
`since:` tag is a public API-provenance contract (it tells adopters which release
first exposed a function); tagging a brand-new function with an already-released
version is misleading and will mis-document the changelog/ExDoc. Relatedly,
`Suppressions.count_active_suppressions/1` has no `@doc`/`@doc since:` at all,
inconsistent with the documented read-model convention.
**Fix:** Set `@doc since:` to the actual first-shipping version for both
`Repo.aggregate/3` and `count_active_suppressions/1` (the v1.7 release version),
and add a one-line `@doc` to `count_active_suppressions/1` describing the
tenant-scoped active-count contract.

## Info

### IN-01: `Repo.aggregate/3` typespec is wider than its only caller needs

**File:** `lib/mailglass/repo.ex:138-139`
**Issue:** `@spec aggregate(..., atom(), atom()) :: term() | nil`. The sole caller
(`count_active_suppressions/1`) uses `:count`, which always returns a
`non_neg_integer()`, yet `count_active_suppressions/1` is spec'd
`:: non_neg_integer()`. The `term() | nil` return widens the contract more than
the delegate's documented use warrants and weakens Dialyzer's ability to catch a
nil flowing into the integer-typed caller.
**Fix:** Acceptable as a thin generic delegate, but consider narrowing to the
aggregates actually used, or add a comment that `:count` callers rely on the
non-nil guarantee.

### IN-02: Duplicated URL/filter plumbing across OperatorLive and InboundLive

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:692-753` and
`mailglass_admin/lib/mailglass_admin/inbound_live.ex:602-657`
**Issue:** `build_path/N`, `maybe_put_theme/2`, `theme_query/1`, `cast_enum/2`,
`parse_positive_integer/1`, `normalize_window/1`, `normalize_string/1`, and
`blank_to_nil/1` are near-identical copies in both LiveViews (InboundLive's
moduledoc even labels itself "clone, not a refactor"). Phase 75 deepened the
divergence (OperatorLive's `build_path` now carries support-state + view; the
inbound copy does not), making the two harder to keep in sync. Pure quality/
maintainability, not a correctness defect.
**Fix:** Extract the shared URL/param helpers into a single
`MailglassAdmin.Operator.UrlState` module when the next change touches both.

### IN-03: `surface_paths/3` recomputed in both `render/1` and `assign_overview_state/2`

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:247-252` and `:623-628`
**Issue:** `Shell.surface_paths(base_path, :deliveries, dark_chrome)` is computed
in `render/1` every render AND again in `assign_overview_state/2`. The render-time
computation already feeds `deliveries_path`/`inbound_path`; the overview-state
computation duplicates it solely to assign `:inbound_path`. Combined with WR-04,
this is redundant work and a second source of truth for the same derived value.
**Fix:** Compute once (in `handle_params/3` after `base_path`/`dark_chrome` are
assigned) and reuse.

### IN-04: Skipped placeholder test left in the suite

**File:** `mailglass_admin/test/mailglass_admin/operator/shell_test.exs:41-45`
**Issue:** An empty `@tag :skip` test
(`"passes active={:deliveries} so nav_link emits aria-current=page on Overview"`)
with no body documents an intended assertion that was never written. The
aria-current behavior it names is a real a11y contract (`shell.ex:204`,
`aria-current={@active && "page"}`) that currently has no automated coverage.
**Fix:** Implement the assertion (mount overview, assert the Deliveries nav link
carries `aria-current="page"`) or delete the stub so it does not masquerade as
planned coverage.

### IN-05: GAP-22 (deep-link unstyled CSS) documented but unguarded

**File:** `mailglass_admin/docs/design-system.md:141-159`
**Issue:** The known-limitation note correctly records that a hard refresh on a
deep URL can render unstyled (relative `css-<md5>` resolves against the deep
path), deferred to Phase 79. This is acceptable disposition, but the IA work in
this phase adds new deep-linkable states (`?view=deliveries`,
`?tenant_id=…&delivery_id=…`) that widen the surface where a hard refresh lands
on a deep, potentially-unstyled URL. No code guard or redirect-to-mount-root
mitigation was added.
**Fix:** None required for v1.7 per the recorded GAP-22 severity-3 disposition;
flagged so Phase 79 closeout reconsiders it with the larger deep-link surface in
mind.

---

_Reviewed: 2026-06-04_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
