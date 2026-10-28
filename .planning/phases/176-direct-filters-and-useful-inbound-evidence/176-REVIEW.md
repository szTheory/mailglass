---
phase: 176-direct-filters-and-useful-inbound-evidence
reviewed: 2026-10-28T00:00:00Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
  - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/test/mailglass_admin/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs
  - mailglass_admin/test/support/inbound_fixtures.ex
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/inbound-layout.spec.js
  - mailglass_admin/e2e/phase169-journey.spec.js
  - mailglass_admin/e2e/phase175-inbound.spec.js
  - mailglass_admin/e2e/phase176-filters.spec.js
  - reference/demo_app/assets/e2e/cohort.spec.js
findings:
  critical: 0
  warning: 1
  info: 4
  total: 5
status: issues_found
---

# Phase 176: Code Review Report (gap-round re-review)

**Reviewed:** 2026-10-28
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

This is the gap-round re-review of plans 176-11..15, with base `d9418fca` (`git diff d9418fca..HEAD`). The prior round's findings and their dispositions are in `176-REVIEW-DISPOSITION.md` and git history. I did not re-report prior open INFO items (IN-01, IN-02, IN-03, IN-05, IN-06 in that record) or the deferred WR-08.

I re-read the claimed fixes against the source and ran the six affected Elixir test files (`mix test ... --seed 0`): 526 tests, 0 failures. The browser specs were not run.

The claimed fixes for WR-01 (single `raw_source/1` selector), WR-02 (`non_default_window?/1` in `filters_active?/1`), WR-03 (denial in the persistent status region), WR-04 (copy aria-label carries the value), WR-05 (Not applied option stays enabled and selected), WR-06 (`filter_url_invalid` follows the committed URL) and IN-07 (blank window) are complete in code. I found no regressions in them:

- Every `copy_value` call site and every e2e or demo selector for the new `Copy <label>: <value>` name is updated. The remaining non-exact `Copy Delivery ID` selector in `reference/demo_app/assets/e2e/quick-views.spec.js:236` still matches by substring.
- The `Not applied` option escapes its user-supplied value and label. The tests cover a `"b<c>` payload.
- The `.mg-inbound-filters-open` rule exists in both `assets/css/app.css:375` and the committed `priv/static/app.css`, so `JS.toggle_class` on the Operator panel needs no bundle rebuild.
- `Clear filters` drops `window_hours`, so the new "non-default window is a filter" rule cannot trap an operator.

One new defect came from the WR-07 fix: the frozen status region can contradict the list. The other findings are small quality issues.

## Warnings

### WR-01: Frozen Operator status region contradicts the list after a background refresh that changes the read state (176-13 WR-07 fix)

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:1231-1243`
**Issue:** `refresh_visible_state/1` re-reads the rows on a PubSub `:delivery_updated` and then restores the previous `results_status_text` unconditionally. That is correct for a ready-to-ready refresh (D-16: never announce another actor's activity). It is wrong whenever the background read changes the settled state:

- **Ready to stale or error.** The visible panel switches to the "Showing results from HH:MM UTC; refresh failed" stale panel. `Components.data_state` carries no `role` or `aria-live`, so nothing announces it. The sr-only `role="status"` region keeps saying "12 deliveries match".
- **Error or stale to ready.** The rows come back, but the region still says "Couldn't load deliveries" or "Showing results from ...; refresh failed".
- **Empty to non-empty.** The region still says "No deliveries in this time window" while rows are visible.

The new test `operator_live_test.exs` "a PubSub refresh does not rewrite the status region" asserts only the count-change case, where the stale text is harmless. It codifies the frozen text, and nothing covers the state-change cases. Assistive-technology users who read the region by navigation get a statement that disagrees with the page, and an operator who loses a refresh to a failure gets no announcement at all.

**Fix:** Freeze the text only when the settled state class is unchanged. Recompute it when the background read moves between ready, stale and error, or between empty and non-empty:

```elixir
defp refresh_visible_state(%{assigns: %{view: :deliveries}} = socket) do
  before = socket.assigns.results_status_text
  prev_state = socket.assigns.deliveries_read_state
  prev_empty? = socket.assigns.deliveries_page_meta.total_count == 0

  socket =
    socket
    |> assign(:provider_options, load_provider_options(socket.assigns.filter_params))
    |> assign_delivery_state(...)

  same_class? =
    prev_state == :ready and socket.assigns.deliveries_read_state == :ready and
      prev_empty? == (socket.assigns.deliveries_page_meta.total_count == 0)

  if same_class?, do: assign(socket, :results_status_text, before), else: socket
end
```

Add a test for ready-to-stale and error-to-ready.

## Info

### IN-01: `filter_error_source` can no longer be `:url`, so the assignment is dead state

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:192`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex:225`
**Issue:** After 176-15 the URL note reads `filter_url_invalid`, and the only remaining reader of `filter_error_source` is `== :draft` (`operator_live.ex:1002`, `inbound_live.ex:785`). The `if(map_size(filter_errors) > 0, do: :url)` assignment is never read. The state is also duplicated: `filter_url_invalid` mirrors `filter_errors` at `handle_params` time.
**Fix:** Drop the `:url` branch and assign `nil` there. Better, replace `filter_error_source` with a `filter_draft_invalid?` boolean so the assign name matches its only meaning.

### IN-02: "Payload size" now reports the pretty-printed re-encoding, not the stored payload

**File:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:152-160`
**Issue:** For a map payload, `payload_byte_size/1` returns `byte_size(Jason.encode(payload, pretty: true))`. That counts indentation whitespace and re-serialised key order. It is neither the provider's wire size nor the compact stored JSON size. The fact and the `<pre>` now agree, but the label "Payload size" still claims something the number does not measure. The test comment calls this a "measurement decision" without recording the cost.
**Fix:** Either rename the fact to "Revealed size", or show the compact size and keep the pretty printing as presentation only. If the current behaviour stays, document in the module doc that the fact is the displayed text size.

### IN-03: `nothing_stored?/1` reports "was not stored" for a stored value of an unexpected shape

**File:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:164-175,220`
**Issue:** `raw_source/1` falls through to `:unknown` for any `raw_payload` that is neither a map nor nil. The test `evidence_card_test.exs` "nothing stored" includes `raw_payload: "not-a-map"` and asserts the sentence "No raw provider source was stored for this message." A value that is present is thereby reported as absent. `raw_payload` is a jsonb map in practice, so this is not reachable today.
**Fix:** Handle a non-nil, non-map `raw_payload` as its own `:unreadable` source. Render "Unavailable" for the size and a sentence that does not claim absence, or remove the `"not-a-map"` case from the test.

### IN-04: New browser specs add fixed sleeps and a race-prone connectivity check

**File:** `mailglass_admin/e2e/phase176-filters.spec.js:821`, `:792-793`
**Issue:** The "keeps the URL note after reconnect and Search" test asserts that the search never commits using `waitForTimeout(800)`. That is the wall-clock pattern WR-08 deferred, and it is sound only while the debounce stays at 300 ms. Right after `liveSocket.disconnect()` and `connect()`, the `expect(page.locator("[data-phx-main].phx-connected")).toBeVisible()` check can pass before the disconnect is processed. The later `draftNote` assertion retries, which hides the race for this test. Both are advisory-lane flake risks, not correctness defects.
**Fix:** Wait for a `phx-disconnected` class or the draft note instead of the sleep. For the "never commits" assertion, use `expect.poll` over a bounded window, or `page.waitForResponse`, instead of a fixed delay.

---

_Reviewed: 2026-10-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
