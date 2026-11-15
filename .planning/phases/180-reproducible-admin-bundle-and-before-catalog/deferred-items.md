# Phase 180 Deferred Items

Out-of-scope discoveries logged during execution. None of these were caused by phase 180 changes and none were fixed here.

## From plan 180-01

### 1. `mix docs --warnings-as-errors` inside `mailglass_admin` is red at HEAD

- **Found during:** 180-01 Task 3 verify (third automated command, `cd mailglass_admin && MIX_ENV=dev mix docs --warnings-as-errors`).
- **Result:** exit 1 with 5 distinct "documentation references ... but it is hidden" warnings (each printed twice, html and epub):
  - `docs/api_stability.md:150` `Mailglass.Operator.Deliveries.get_delivery/2`
  - `docs/api_stability.md:151` `Mailglass.Operator.Timeline.get_delivery_event/3`
  - `docs/api_stability.md:152` `Mailglass.Operator.SupportSummary.read_failed_ingest/1`
  - `docs/api_stability.md:155` `Mailglass.Operator.SupportSummary.get_webhook_event/2`
  - `lib/mailglass_admin/preview/sidebar.ex:474` `MailglassAdmin.MountPath.base/1`
- **Why it is out of scope:** every warning is in a file plan 180-01 did not touch, and none mentions `design-system.md`, `MailglassAdmin.AssetsCheck` or the `assets.build` / `assets.watch` tasks, the only docs this plan edited. The CI job `docs_warnings_as_errors` runs `mix docs --warnings-as-errors` at the repository root (core package) only, so the admin docs warnings are ungated today.
- **Suggested follow-up:** either reference the hidden functions without backticks or un-hide them, then add admin docs to the gated docs job. Owner decision; not part of this phase.

### 2. `MailglassDemo.QuickViewScenarios is not included in any boundary`

- **Found during:** every admin `mix compile` / `mix test` in `MIX_ENV=test` (`reference/persona_spec/quick_view_scenarios.ex:0`).
- **Effect:** `mix compile --warnings-as-errors` exits 1 at HEAD, so the admin `ci.fast` alias and `verify.preview` fail on a cold compile. `mix test --warnings-as-errors` is unaffected because it governs test-file warnings only. The new `--check` gate deliberately does not depend on a warnings-free compile.
- **Already recorded:** 180-RESEARCH.md "Anti-Patterns to Avoid". Listed here so it stays owner-visible.

## From plan 180-02

### 3. The gallery still renders 39 duplicated id values after the one-specimen collapse

- **Found during:** 180-02 Task 3 (the gallery document-level cases).
- **Plan assumption that did not hold:** RESEARCH F10 and the plan truth said collapsing the light, dark and system columns to one specimen would leave the gallery document with no duplicate ids. It removes the threefold copies (182 duplicated id values at HEAD) but 39 remain.
- **Cause:** shared components emit literal or fixture-derived ids that the gallery renders in several states of the same component: `flash-error` (2 cells), `inbound-routing-trace-content` (3), `inbound-evidence-caption` and `inbound-evidence-reveal-btn` (3), `delivery-detail-*` and `delivery-suppression-scope*` (detail_header, suppression_card, composed cells), `delivery-outcome-*` and `operator-delivery-*` rows (3 deliveries_list cells), `delivery-event-*` (2 timeline cells), `operator-suppression-refresh-action`.
- **Effect:** none on `live/2` (it mounts without a duplicate-id raise; the contract test mounts it). `aria-describedby` tooltip ids resolve to the first match on this dev-only audit page.
- **Why it is out of scope:** removing them means changing id derivation in about seven shared components (or per-state fixture ids), which edits files outside this plan and moves selectors the e2e specs read. It is not a theme-ownership defect.
- **Guard in place:** `root_theme_ownership_contract_test.exs` keeps a floor (`@duplicate_id_floor 39`) so the count cannot grow back.
- **Suggested follow-up:** thread a `specimen_id` prefix through those components, then lower the floor to 0 and turn the floor test into a plain no-duplicates assertion.
