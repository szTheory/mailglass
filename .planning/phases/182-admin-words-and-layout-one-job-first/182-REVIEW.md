---
phase: 182-admin-words-and-layout-one-job-first
reviewed: 2026-11-16T01:30:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/copy.ex
  - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/operator/mailer_name.ex
  - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
  necessity: 0
status: issues_found
---

# Phase 182: Code Review Report (re-review after fix pass)

**Reviewed:** 2026-11-16T01:30:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Re-reviewed the five fix commits (`git diff ba128b87 HEAD -- mailglass_admin/lib`: a7f843a2, 8eeae107,
03222998, 7276280e, 2bf8f496) against CR-01 and WR-01..WR-04 from `182-REVIEW.iter2.md`. WR-05 (compile-time
parity raise) and IN-01..IN-09 / WR-06 were not re-reported. The four changed test files
(`phase182_cause_contract_test`, `phase182_journey_test`, `phase182_words_contract_test`,
`mailer_name_test`) pass: 123 tests, 0 failures, `--seed 0`. `mix format --check-formatted` is clean on all
five source files. The pure functions were also run directly (`mix run --no-start`, test env).

All five prior findings are resolved at the point they cited, and none of the five fixes introduced a defect
in the code it changed:

- **CR-01 resolved.** `event_cause(row, event)` now sends `{:failed, nil}` through `send_failure_or_fallback/1`,
  which keys on `row.status == :failed`. Confirmed: a `status: :sent` row with a provider `:failed` event and
  no reason reads "No reason was recorded for this email."; a `status: :failed` row still reads "Sending failed
  before a successful handoff to the provider.". The row-status condition is sound because the only code that
  writes `Delivery.status :failed` (`persistence.ex:225, 353`) also writes the `:failed` event with no
  `reject_reason` (`persistence.ex:343-361`), and a delivery that never reached the provider cannot receive a
  provider event. The provider mappers that emit `{:failed, nil}` (`mailgun.ex:204`, `ses.ex:877`) leave the
  row `:sent`.
- **WR-01 resolved for the counts, with one parity regression in the link (WR-02 below).** `health_delivery_card/1`
  buckets by `StatusMap.delivery_class/1`. Confirmed on the cases that mattered: bounce then open counts once
  under Bounced, a confirmed delivery followed by a deferral counts nowhere, a provider-reported failure on a
  handed-off row counts under Failed. Every group lands in at most one card, `Map.get` makes the function total
  over the pre-phase three-field group shape (which always carries `:status`), and Failed, Bounced and Rejected
  keep exact count-to-landing-list parity.
- **WR-02 resolved.** `suppression_evidence(:ready, _)` returns `:no_entry`; the dedicated `verdict(:not_sent, ...)`
  clause is matched before the general one, drops the removal step and the "Go to the suppression card" link,
  and puts the note "No current suppression entry matches this address." where the cause was. A `nil` or `%{}`
  state under `:ready` reaches `:no_entry` (the first clause's `map_size/1` guard fails closed on `nil`); a
  `:stale` or `:unavailable` read with no facts still reaches `:read_failed`. The Quick view keeps
  `:not_loaded` and the general clause.
- **WR-03 resolved.** `MailerName.identity("nil")` is nil, so `plain_name/1`, the list line and the Full detail
  cell all drop it. `@missing_mailable inspect(nil)` is defined before its only use and the match is exact, so a
  real module named `Nil` still renders.
- **WR-04 resolved.** The banner, the moduledoc line and the title/body agree, and no visible "unmatched"
  string remains in `mailglass_admin/lib` (the remaining hits are identifiers and the `:unmatched_reports`
  vocabulary entry).

Two new findings remain. WR-01 is the same invented-cause defect as CR-01 in a second renderer that the fix did
not reach. WR-02 is a count/landing-list mismatch on one Health card that the new bucketing opened.

## Warnings

### WR-01: A provider-reported `:failed` event still gets the send-time cause in the Full detail timeline

**File:** `mailglass_admin/lib/mailglass_admin/components.ex:1845-1846` (rendered at `mailglass_admin/lib/mailglass_admin/operator/timeline.ex:104-108`)
**Issue:** CR-01 was fixed in the verdict, and commit a7f843a2 says "a provider-reported failed event no longer
claims the handoff failed". The per-event help in the timeline still does. `outcome_help(:delivery, :failed)`
returns "Sending failed before a successful handoff to the provider." for any `:failed` event, and
`Operator.Timeline` passes it as the help text for every event whose type is `:failed`. The text depends on the
status atom alone, so it cannot tell a send-time `:failed` event (written by `persistence.ex:343-361`) from a
provider-sourced one (Mailgun `"failed"` without a severity, SES "Rendering Failure"). For the provider case the
timeline row for that event therefore still tells the operator the app never reached the provider, on the same
Full detail screen where the verdict now (correctly) says no reason was recorded. This is the factual claim
rubric R-TRUTH-1 forbids and the one CR-01 set out to remove. The comment above the clause ("a send-time failure
records no provider reason") shows the author treated `:failed` as send-time only. The Health "Failed emails"
help written in 8eeae107 already has the neutral wording needed.
**Fix:** Make the context-free event help neutral, and keep the send-time sentence only where the row status
proves it (the verdict):
```elixir
defp outcome_help(:delivery, :failed),
  do: "The email did not get through: sending failed, or the provider reported a failure."
```
Update `phase182_review_words_test.exs` if it pins the old text, and add a timeline test with a provider
`:failed` event (nil reason, row `status: :sent`) asserting the help does not contain "before a successful
handoff".

### WR-02: Health "Delayed emails" count no longer matches the list its link opens

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:2898-2906` (with `:2951-2957`)
**Issue:** The count now comes from `StatusMap.delivery_class/1` (`:delayed` only), but the destination is still
chosen by the old rule: `Enum.all?(matching, &(&1.last_event_type == event))` adds `event=deferred`, and the
Activity event filter is `delivery.last_event_type == ^event` (`lib/mailglass/operator/deliveries.ex:241-243`).
For the Delayed card every matching group has `last_event_type == :deferred` by construction (`:deferred` is the
only way to reach `:delayed` in `delivery_class/1`), so the `Enum.all?` check is always true and the filter is
always applied. The filter then also returns the rows whose latest event is `:deferred` but whose class is
Delivered (a confirmed delivery followed by a later deferral), Failed (a durable bounce followed by a deferral)
or Not sent. Confirmed by classing the two groups: `%{status: :sent, last_event_type: :deferred}` is `:delayed`
and the same group with `delivery_confirmed: true, terminal: true` is `:delivered`. With one of each, Health
shows "Delayed emails: 1" and the link opens an Activity list of 2 results, one of which reads Delivered. The
Failed, Bounced and Rejected cards keep exact parity (every row with latest event `:failed` or `:rejected` is
class Failed, and the Bounced card drops the filter when any matching group's latest event differs), so
Delayed is the only card where the new bucketing made the link wider than the count. Before 8eeae107 the count
and the filter used the same latest-event rule, so this is a regression, though it needs out-of-order provider
events to appear. The journey test added for this fix seeds the confirmed-then-deferred row alone, so it never
checks the link against a Delayed row.
**Fix:** Apply the event filter only when it cannot widen the list. The simplest form keeps the destination
unfiltered for the Delayed card when any other class carries `last_event_type == :deferred`, or drops the filter
for it entirely:
```elixir
destination =
  if event != :deferred and Enum.all?(matching, &(&1.last_event_type == event)),
    do: Map.put(params, "event", Atom.to_string(event)),
    else: params
```
Prefer the first form if the filtered link matters for the common case: compute
`widened? = Enum.any?(groups, &(&1.last_event_type == event and health_delivery_card(&1) != event))` and skip
the filter when it is true. Add a journey test with one Delayed row and one confirmed-then-deferred row that
asserts the Delayed link either carries no `event=deferred` or opens a list with the same count.

---

_Reviewed: 2026-11-16T01:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
