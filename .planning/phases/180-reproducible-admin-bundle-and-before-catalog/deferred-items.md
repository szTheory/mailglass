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

## From plan 180-03

### 4. `structural.spec.js` "Preview: Phase 178 axe cell matches the committed baseline" times out when axe scans a settled Preview page

- **Found during:** 180-03 phase gate (`e2e/structural.spec.js:2655`; 4 of 4 runs in suite or in a small subset, plus the full `npm run test:operator-browser`: 353 passed, 1 failed, 1 skipped). Error: `Test timeout of 90000ms exceeded` then `browserContext.newPage: Target page, context or browser has been closed` thrown from `AxeBuilder.analyze` (`structural.spec.js:2671`).
- **Cause (measured, not theorised):** `@axe-core/playwright` runs `axe.runPartial` inside the email `<iframe sandbox="allow-same-origin">`, a script-disabled `srcdoc` document. When the scan starts after the LiveView connect, that partial run never completes until a roughly 30 s stall ends (trace: `runPartialRecursive end` at +0.66 s, `finishRun start` at +30.35 s; a `setTimeout` probe evaluated in the child frame does not resolve within 5 s while the main frame answers in 14 ms). The test scans three themes in one `test.slow()` body (90 s), so three stalls of ~30 s exceed the budget. `axe-baseline.spec.js` scans one cell per test with its own 90 s budget, so it passes at ~30 s per Preview cell.
- **Not a 180-03 or theme-ownership defect, and not new in kind:** with the 7a848162 `preview/tabs.ex` restored, a Preview page that is allowed to settle (`.phx-connected` plus 1 s) stalls 29.2 s on 4 of 4 fresh-context scans, exactly like the 180-02 tree (29.2 s on 8 of 8). Scans that start before the connect finish in ~1.1 s on both trees.
- **Honest caveat:** in the unsettled harness this exact test passed on the pre-180 `tabs.ex` in 7 of 7 runs (six at 3.5 to 3.8 s, one at 32.9 s where one of the three scans stalled) and failed on the 180-02 `tabs.ex` (5.6 s, 32.7 s, then a 90 s timeout on `--repeat-each=3`; 4 of 4 in suite or subset runs). The 180-02 markup moved the race across the timing window; why it moved was not isolated (machine load average was 20 to 55 throughout, so timings are noisy). I did not edit the test (one concern per plan).
- **Suggested follow-up (owner decision, test-scope change):** make the Phase 178 axe cell test and `axe-baseline.spec.js` scan the admin page only, with `new AxeBuilder({ page }).exclude('iframe[title^="Email HTML preview"]')`. The email document is previewed third-party HTML in a script-disabled sandbox that axe cannot reliably enter, and the committed Preview cells (`aria-allowed-attr: 1`, `#assigns-plan`) are identical with and without the stall. Regenerating the baseline is Phase 181's single allowed change, so do not combine it with this edit.
- **Lane:** advisory `operator_browser_gate`; no required lane is affected.

### 5. Demo specs reworked in 180-03 were not executed locally

- `reference/demo_app/assets/e2e/persona-screenshots.spec.js` and `phase178-stories.spec.js` were checked with `node --check` and the plan greps. `make demo` (isolated project `mailglass-demo-180`, ports 4045/5445) failed to start: the container exited 1 with `Error while loading project :mailglass_admin at /workspace/mailglass_admin ... could not load /workspace/mailglass_admin/mix.exs. Reason: enoent` (Mix could not read the bind-mounted path dependency inside the container). The project was removed with `docker compose -p mailglass-demo-180 down -v`; no repository file changed.
- The production-gallery half of the StatCard test (per-theme cookie plus `emulateMedia` plus goto, `<html>` owns the theme, no nested `[data-theme]` in the specimen, `--color-base-100` equal to `<html>`, then `readStatCardRoles` on the specimen) was run verbatim as a throwaway spec against the admin `OperatorBrowserServer`: 1 passed, roles Inter 400 / Inter 700 / IBM Plex Mono 700 in both themes. The Storybook halves and the persona spec need the demo and are exercised by the advisory `demo_browser_evidence` lane.

## From plan 180-04

### 6. The seeded `pm-demo-receipt-001` delivery answers HTTP 400 on its quick view and full detail

- **Found during:** 180-04 Task 2 full staged dry run (3 of 80 captures timed out waiting for `[data-phx-main].phx-connected`: `delivery-detail` for the `delivered-no-open` case, which the plan mapped to this row).
- **Evidence (measured):** `GET /ops/mail?tenant_id=northstar&view=deliveries&delivery_id=<id of pm-demo-receipt-001>&full=1` and the same URL without `&full=1` return `400 Ecto.Query.CastError`: `lib/mailglass/operator/replay_targets.ex:101` casts `metadata["webhook_event_id"]` with `type(^id, Ecto.UUID)`, and `reference/demo_app/lib/mailglass_demo/demo_data.ex:457` and `:463` seed two `:webhook_replay_succeeded` events on that delivery with `"webhook_event_id" => "demo-replay-wh-001"` and `"demo-replay-wh-002"`, which are not UUIDs. The invite row (`pm-demo-invite-001`), the other eight Northstar cases and every Fjordline screen render (HTTP 200).
- **Two defects in one:** (a) a fixture bug (DemoData seeds a non-UUID webhook event id on a replay event) and (b) a robustness gap (an operator screen turns a malformed `webhook_event_id` in event metadata into a 400 instead of ignoring the replay link). Existing demo e2e specs never open this delivery, so nothing caught it.
- **Why it is out of scope:** D-22 forbids editing `DemoData` to shape the catalog, and a fix in `lib/mailglass/operator/replay_targets.ex` is a release-visible core change that would alter the "before" the catalog records. Not fixed.
- **What 180-04 did instead:** mapped the `delivered-no-open` case to the invite row (delivered, no open event, no replay events) so the catalog keeps ten distinct, rendering cases. The defect is recorded here, not captured as a screenshot.
- **Suggested follow-up (owner decision, separate PR):** seed real UUIDs for the replay events' `webhook_event_id` (or insert matching `mailglass_webhook_events` rows), and make `ReplayTargets.load_candidate/3` treat a non-UUID id as "no linked webhook event". Add a demo e2e case that opens `pm-demo-receipt-001`. Input for Phase 182's reviewer if the detail screen's replay panel is in scope.

### 7. `docker compose exec demo mix run` cannot start beside the live demo server

- **Measured:** `docker compose -f compose.demo.yml exec -T demo mix run -e '...'` exits 1 with `** (Mix) Could not start application mailglass_demo ... failed to start child: MailglassDemoWeb.Endpoint ... :eaddrinuse`, because `mix run` starts the application, whose endpoint binds the port the running server already holds. This happened on every driver run (4 of 4), so the catalog driver's pre-decided fallback (`docker compose run --rm --no-deps -T demo mix run -e ...`, a separate container with its own network namespace) is the branch that actually seeds.
- **Not measured:** `make demo-reset` (`docker compose exec demo mix demo.reset`, which runs `priv/repo/seeds.exs` after `Mix.Task.run("app.start")`) very likely fails the same way. It was not run here.
- **Suggested follow-up:** `exec -e PORT=<unused>` or `mix run --no-start` with an explicit repo start; or point `make demo-reset` at the reset endpoint the evidence harness already uses.

### 8. `/dev/mail` (the Preview "index") redirects to the first scenario

- `GET /dev/mail` lands on `/dev/mail/MailglassDemoWeb.Mailers.AccountMailer/invite_admin?width=768`, so the catalog's `preview-index` capture shows the Preview pane for the first mailable, not a list. There is no separate empty-selection Preview screen to capture. Recorded in each capture's `route`.
