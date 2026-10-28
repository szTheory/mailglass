---
phase: 176-direct-filters-and-useful-inbound-evidence
reviewed: 2026-10-28T00:00:00Z
depth: standard
files_reviewed: 40
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound/address_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
  - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/filter_commit.ex
  - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/operator/results_status.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/priv/static/hooks.js
  - mailglass_admin/test/mailglass_admin/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/address_list_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
  - mailglass_admin/test/mailglass_admin/operator/filter_commit_test.exs
  - mailglass_admin/test/mailglass_admin/operator/results_status_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs
  - mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs
  - mailglass_admin/test/support/inbound_fixtures.ex
  - mailglass_admin/test/support/operator_fixtures.ex
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/inbound-layout.spec.js
  - mailglass_admin/e2e/operator.spec.js
  - mailglass_admin/e2e/phase169-journey.spec.js
  - mailglass_admin/e2e/phase170-journey.spec.js
  - mailglass_admin/e2e/phase175-inbound.spec.js
  - mailglass_admin/e2e/phase176-filters.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - reference/demo_app/assets/e2e/inbound-evidence.spec.js
  - reference/demo_app/assets/e2e/phase176-filters.spec.js
  - reference/demo_app/dev/mailglass_demo_web/storybook.ex
  - reference/demo_app/storybook/inbound_evidence.story.exs
  - reference/persona_spec/quick_view_scenarios.ex
  - reference/persona_spec/quick_view_scenarios.json
findings:
  critical: 0
  warning: 8
  info: 7
  total: 15
status: issues_found
---

# Phase 176: Code Review Report

**Reviewed:** 2026-10-28T00:00:00Z
**Depth:** standard (diff range `c96c8a4f..HEAD`)
**Files Reviewed:** 40. lib/ was read in full context. Tests and e2e specs were checked only for false-green and flaky patterns. `priv/static/app.css` is a generated bundle and was excluded.
**Status:** issues_found

## Summary

The filter commit path holds up. `FilterCommit.commit_params/2` takes `tenant_id` only from `socket.assigns.selected_tenant_id`, so a tampered payload cannot change the Account. A commit always drops `page`, `delivery_id`, `inbound_id` and `full`. `handle_params` is still the authorization gate. Retry re-reads without a patch. Account canonicalization now patches with `replace: true`. No markup goes through `raw`. Address values, display names and the "Custom period (… hours)" option label are all HEEx-escaped. The reveal and detail telemetry did not change, and none of it carries PII. No Critical issues were found.

The defects are about truthfulness and accessibility, which are this phase's own goals (FILTER-04, INUX-05, INUX-06, D-12/D-13/D-16/D-26):

- The evidence card can report the byte size of one stored field and then reveal a different one.
- An auto-applied time window can remove the Operator filter toolbar entirely.
- The denial message is likely not announced.
- Every contact address is hidden from assistive technology by the copy button's `aria-label`.
- An invalid enum value from the URL leaves its select contradicting its error.
- The URL-invalid label is replaced by a misleading draft note.
- The Operator status region announces on background PubSub refreshes.

One browser spec relies on a 250 ms wall-clock bound.

## Warnings

### WR-01: Payload size and revealed raw source describe different stored fields

**File:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:166-183` vs `:205-212`
**Issue:** `payload_byte_size/1` now uses `raw_mime` first when it is non-empty. `raw_payload_text/1` still renders `raw_payload` first when it is non-empty. When both are stored, the "Payload size" fact measures the MIME bytes while "Reveal raw source" shows the JSON-encoded `raw_payload`, so the size is not the size of what the operator sees. Both fields are stored for SES (`mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex:118-120` persists `raw_payload: payload` and `raw_mime: raw_mime`), and Mailgun keeps a params map next to the MIME. Before this phase the two functions used the same order (`raw_payload` first), so this is a regression in the D-26 "truth fixes". No test feeds evidence with both fields set, so the suite stays green.
**Fix:** Pick one source and use it for both the size and the reveal. For example, share one selector:
```elixir
defp raw_source(%{raw_mime: mime}) when is_binary(mime) and mime != "", do: {:mime, mime}
defp raw_source(%{raw_payload: p}) when is_map(p) and map_size(p) > 0, do: {:payload, p}
defp raw_source(%{raw_payload: p}) when p == %{}, do: :empty
defp raw_source(_), do: :unknown
```
Derive both `payload_byte_size/1` and `raw_payload_text/1` from it. Add a test where `raw_mime` and `raw_payload` are both non-empty and assert that the size equals `byte_size` of the revealed text.

### WR-02: Auto-applied time window can remove the Operator filter toolbar (focus lost, no way back)

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:821-823`, `:1308-1311`
**Issue:** The genuine-no-data branch renders only the empty pane and the orientation strip, without the filter toolbar. It is chosen when `total_count == 0 and not filters_active?(@filter_params)`. Operator `filters_active?/1` drops `"window_hours"`, so a non-default window does not count as a filter. Picking "Last 24 hours" with no deliveries in that window now commits immediately and removes the whole toolbar, including the focused select, so focus falls to `<body>`. The screen then says "No deliveries in this time window" with no control to widen the window again; only browser Back gets the operator out. Inbound does not have this problem because its `filters_active?/1` (`inbound_live.ex:1495-1501`) counts `non_default_window?`. The condition predates this phase. Apply used to sit between the choice and the commit; auto-apply (D-01) now makes the trap a single select change. The new `applied_filter_count/1` does count the window, which disagrees with `filters_active?/1`.
**Fix:** Count a non-default window as an active filter, matching Inbound:
```elixir
defp filters_active?(filter_params) do
  Map.drop(filter_params, ["tenant_id", "window_hours", "page"]) !=
    Map.drop(default_filter_params(), ["tenant_id", "window_hours", "page"]) or
    filter_params["window_hours"] != Integer.to_string(@default_window_hours)
end
```
Add a LiveView test: select `window_hours=24` with deliveries only older than 24h, then assert `#operator-filters` is still rendered.

### WR-03: Reveal denial is placed in a freshly inserted live region and likely not announced

**File:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:133-140`, `:147-154`, `:235`
**Issue:** D-26 requires the denial to go through the existing `role="status"` region. That region (`inbound-evidence-status`) is always present, but in the `:denied` state `reveal_status_text/1` gives it the same text as `:redacted` ("Raw source hidden."). Its content therefore does not change when a reveal is denied, and nothing is announced from it. The denial text sits in a new `<p role="status">` that is inserted in the same patch. Screen readers do not reliably announce live regions that are created together with their content. A screen-reader user who presses "Reveal raw source" and is denied may hear nothing.
**Fix:** Announce the denial from the persistent region and drop `role` from the inserted paragraph:
```elixir
defp reveal_status_text(:revealed), do: "Raw source revealed. It may contain personal information."
defp reveal_status_text(:denied), do: "You don't have permission to reveal raw source."
defp reveal_status_text(_redacted), do: "Raw source hidden."
```
Keep the visible denied paragraph as plain text, without `role="status"`.

### WR-04: Contact addresses are hidden from assistive technology by the copy button's `aria-label`

**File:** `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex:96-100`, `:223`, `:232`; `mailglass_admin/lib/mailglass_admin/components.ex:1605-1617`
**Issue:** INUX-05 makes the full addresses the content of the detail header. Each address is rendered only as `Components.copy_value`, which sets `aria-label={"Copy " <> @label}`. Because `aria-label` replaces the button's text as its accessible name, screen-reader users hear "Copy To address, button" once for every recipient and never hear the address itself. The same applies to From, Reply-To, Cc, Delivered to and the unparseable original. This also fails WCAG 2.5.3 Label in Name: the visible label is the address, but the accessible name does not contain it. The pattern already existed for record IDs, but this phase makes it the only way the main contact data is presented.
**Fix:** Keep the visible value in the accessible name, for example `aria-label={"Copy #{@label}: #{@value}"}`. Alternatively, drop `aria-label` and add visually hidden text: `<span class="sr-only">Copy {@label}: </span>{@value}`. Add a test that asserts the address appears in the accessible name.

### WR-05: Invalid enum from the URL leaves its select contradicting its error (D-12)

**File:** `mailglass_admin/lib/mailglass_admin/inbound_live.ex:1938-1947`, `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex:52-61`; `mailglass_admin/lib/mailglass_admin/operator_live.ex:1400-1405`, `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex:45-54`; `mailglass_admin/lib/mailglass_admin/components.ex:1010-1016`
**Issue:** The comment on Inbound `filter_draft_params/3` says a rejected outcome stays in the draft so the select never contradicts its error. The draft does keep `"bogus"`, but the outcome select (and the Operator event select) only lists known values. `filter_field` marks `selected` only on an exact match, so no option is selected and the browser shows the prompt ("Any outcome" / "Any status") next to the error "… was not applied". The window select has a "Custom period" fallback, but the enum selects do not. Because the form posts the prompt's `""` on the next change, an unrelated edit (for example typing a search) commits the cleared enum without the operator ever choosing it.
**Fix:** Mirror the window fallback in both enum selects. When the draft value is not a listed option, prepend a disabled option such as `{"Not applied: #{value}", value}` so the select matches the error. Otherwise, correct the comment and D-12 claim to say the select resets to the prompt.

### WR-06: URL-invalid results lose their "filter excluded" label after any edit or reconnect (D-13)

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:1359-1365`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex:2101-2111`
**Issue:** With an invalid `window_hours` in the URL (for example `window_hours=abc`), the draft keeps `"abc"` as the selected custom option, and results fall back to the default window under the note "Showing results for the default time window instead." Every later change event re-posts `"abc"`: typing a search, changing another select, or the `phx-auto-recover` payload after a reconnect. That fails validation and sets `filter_error_source` to `:draft`. The draft note "Showing results for your previous filters until the highlighted field is fixed" then replaces the URL note. That is false: the results do not reflect any filters the operator chose; they still exclude the URL's invalid window. Because the invalid field blocks every commit, the search box also silently does nothing until the window is fixed.
**Fix:** Keep the URL note while the committed URL still carries the invalid value. For example, track URL errors separately (`filter_url_errors`) and render the URL note whenever that map is non-empty, alongside the draft note. Another option is to leave `filter_error_source` as `:url` when the only draft errors are the same field and value that the URL already had.

### WR-07: Operator status region announces on background PubSub refreshes (D-16)

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:1221-1229`, `:1791-1801`
**Issue:** D-16 says the polite `role="status"` region updates only after `handle_params` settles a commit. `results_status_text` is set inside `assign_delivery_state/5`. That function also runs from `refresh_visible_state/1` on every matching `{:delivery_updated, …}` PubSub message. On a busy Account, each new delivery that changes `total_count` makes the region announce "N deliveries match", and a transient read failure announces "Showing results from HH:MM UTC; refresh failed", all without any operator action. Inbound does not do this (`prepend_live_record/2` leaves the text alone), so the two collections also behave differently.
**Fix:** Only update `results_status_text` on commit-driven reads. For example, pass an `announce?: true` option from `handle_params`/`retry_deliveries` and leave the assign unchanged on the PubSub path. You could also recompute the text in `handle_params` after `assign_delivery_state` and remove it from the shared function.

### WR-08: Browser specs assert a 250 ms wall-clock bound (flaky)

**File:** `mailglass_admin/e2e/phase176-filters.spec.js:89-90`, `:212-213`, `:417-418`, `:515`
**Issue:** `waitForURL(..., { timeout: 250 })` together with `expect(Date.now() - startedAt).toBeLessThan(250)` measures round-trip latency: keypress, LiveView event, `push_patch`, `handle_params` (a synchronous DB read), and the history update. Debounce flushing is only part of that. Cold caches, CI CPU contention or a GC pause push this past 250 ms with no defect in the code. Because the lane is advisory, a red result here gets dismissed, which wears down trust in the gate.
**Fix:** Prove the debounce flush by ordering, not by wall time. Assert the URL is reached well before the debounce would have fired on its own, for example by temporarily using a large debounce in a test fixture. Alternatively, raise the bound to something CI can meet (for example 1,500 ms) and keep the "no extra history entry later" check.

## Info

### IN-01: `commit_params/2` doc says the draft stays untrimmed, but the draft is built from the trimmed params

**File:** `mailglass_admin/lib/mailglass_admin/operator/filter_commit.ex:38-50`; `operator_live.ex:1342,1352,1362`; `inbound_live.ex:2082,2096,2107`
**Issue:** `commit_filters/3` rebinds `filters` to the trimmed `commit_params/2` result and then builds the draft form from it. The draft assign is therefore trimmed. Nothing visible changes, because a focused input is never overwritten, but the documented contract is wrong.
**Fix:** Keep the raw payload for `filter_draft_params` (`raw = filters; filters = FilterCommit.commit_params(raw, …)`), or correct the doc.

### IN-02: Spoof cue fires on a local-part case difference only

**File:** `mailglass_admin/lib/mailglass_admin/inbound/address_list.ex:96-98`, `:106-119`
**Issue:** `display_name/2` drops the name only on exact byte equality. A name of `"Alex@Example.com"` on the address `alex@example.com` is therefore kept, and because the local part is compared case-sensitively, it gets flagged "Display name contains a different address." This is a false spoof warning.
**Fix:** Drop the name, and skip the spoof check, when `String.downcase(name) == String.downcase(address)`.

### IN-03: RFC 5322 quoted local parts are labeled "Unparseable address"

**File:** `mailglass_admin/lib/mailglass_admin/inbound/address_list.ex:124-129`
**Issue:** `parse/1` requires exactly one `@`, so a valid address such as `"a@b"@example.com` is shown as unparseable. That is rare but not malformed. A value like `Name <user@host>` stored raw in `address` would pass as an addr-spec.
**Fix:** Split on the last `@` (`String.split(address, "@") |> List.pop_at(-1)`) and reject `<`/`>` in the addr-spec.

### IN-04: Reveal says "Provider sent an empty payload." when the payload is unknown, not empty

**File:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:183`, `:212`
**Issue:** If both `raw_payload` and `raw_mime` are `nil`, the size fact correctly renders "Unavailable". The reveal text, however, falls through to "Provider sent an empty payload.", which asserts an empty payload that was never observed.
**Fix:** Use "Raw source unavailable." for the `nil`/`nil` case, and keep the empty-payload copy for `raw_payload == %{}` with no MIME.

### IN-05: Inbound status region holds a no-data claim before any read

**File:** `mailglass_admin/lib/mailglass_admin/inbound_live.ex:146`, `:1052-1080`
**Issue:** `initial_results_status_text/0` ("No messages have been received yet") is assigned at mount. Inbound `clear_surface_state/1` does not reset it, while the Operator version does. In the `:auto_select` state, the status region renders with that claim, or with the previous Account's count, before any read for the current Account has run.
**Fix:** Start with `""` and reset `results_status_text` (and `inbound_loaded_for`/`inbound_loaded_at`) in `clear_surface_state/1`.

### IN-06: `FilterSearchSync` loses the Back sync when a round trip exceeds 1.5 s

**File:** `mailglass_admin/priv/static/hooks.js:124-127`
**Issue:** The pending flag clears after a fixed 1,500 ms. If `handle_params` takes longer (for example a slow read on a large tenant), `updated()` arrives after the flag has cleared. The focused search then keeps the pre-Back draft while the URL shows the restored filters.
**Fix:** Clear `pending` in `updated()` or on the next `input` only, without a timer. Alternatively, use a much larger guard such as 10 s.

### IN-07: Operator renders a "Custom period ( hours)" option for a blank URL window

**File:** `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex:70-78`, `mailglass_admin/lib/mailglass_admin/operator_live.ex:1400-1405`
**Issue:** The URL `?window_hours=` (key present, blank) produces a window error. Operator `filter_draft_params/2` keeps the raw `""`, so `window_options/2` prepends an empty-looking "Custom period ( hours)" option. Inbound avoids this case.
**Fix:** In `window_options/2`, skip the custom option when `value == ""`.

---

_Reviewed: 2026-10-28T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
