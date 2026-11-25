---
phase: 182-admin-words-and-layout-one-job-first
reviewed: 2026-11-16T01:00:10Z
depth: standard
files_reviewed: 34
files_reviewed_list:
  - brandbook/status-marks.json
  - docs/api_stability.md
  - lib/mailglass/operator/deliveries.ex
  - mailglass_admin/docs/api_stability.md
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/controllers/assets.ex
  - mailglass_admin/lib/mailglass_admin/copy.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound/destructive_action.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/operator/health_overview.ex
  - mailglass_admin/lib/mailglass_admin/operator/mailer_name.ex
  - mailglass_admin/lib/mailglass_admin/operator/orphan_count.ex
  - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/operator/results_status.ex
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
  - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
  - mailglass_admin/lib/mailglass_admin/operator/timeline.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/preview/return_context.ex
  - mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex
  - mailglass_admin/lib/mailglass_admin/preview_live.ex
  - mailglass_admin/lib/mailglass_admin/status_map.ex
  - mailglass_admin/lib/mailglass_admin/surface_nav.ex
  - reference/demo_app/assets/catalog/capture-before-catalog.cjs
  - reference/demo_app/assets/catalog/phase182-rubric.md
  - reference/demo_app/lib/mailglass_demo/journey_seed.ex
  - scripts/brand_status_marks.exs
findings:
  critical: 1
  warning: 6
  info: 9
  total: 16
  necessity: 2
status: issues_found
---

# Phase 182: Code Review Report

**Reviewed:** 2026-11-16T01:00:10Z
**Depth:** standard
**Files Reviewed:** 34
**Status:** issues_found

## Summary

Reviewed the Phase 182 delta (`78dcb7d0..HEAD`) across the additive core read-model change, the admin
copy/layout/verdict work, the status-mark pin script and JSON, and the demo capture tooling. Each source
file was read in full or by full diff. Three of the defects below were confirmed by running the pure
functions (`mix run --no-start` in `mailglass_admin`, test env), not only by reading.

The word and layout changes are mostly sound, and the core projection change is correct: the extra
`GROUP BY` expressions match their `SELECT` twins and add no parameters. The new `StatusMap.delivery_class/1`
rule is applied consistently to the Activity row badge, the summary tiles, the Quick view and the Full detail.
The weak spots all sit where the phase claims truthfulness:

- one verdict cause is invented for provider-reported failures (CR-01);
- the suppression verdict conflates "no entry now" with "entry without a reason" (WR-02);
- the Health overview still counts with the pre-phase atom rule, so it disagrees with Activity for the
  very bounce-then-open case this phase set out to fix (WR-01);
- a mailer name can render as "Nil" (WR-03);
- one retired word survives on screen (WR-04).

The `<external_reviewer_evidence>` and `<structural_findings>` blocks were not provided, so there are no
fallow or external-lane sections. The necessity reference (`necessity-review.md`) was read; two findings
carry the `necessity` category. The pre-existing nil/`>` defect in the Failed webhook attempts card
(`deferred-items.md`, 182-04) was not re-reported, and no new instance of it was found.

## Critical Issues

### CR-01: Provider-reported `:failed` events are given the invented cause "Sending failed before a successful handoff to the provider."

**File:** `mailglass_admin/lib/mailglass_admin/copy.ex:429-432` (also `:436-440`)
**Issue:** `event_cause/1` maps any `:failed` event with a nil `reject_reason` to the send-time sentence:

```elixir
{:failed, nil} -> @send_failure_cause
```

Only the `:failed` events that `Mailglass.Outbound.Persistence` writes (persistence.ex:343-361) are send-time
failures. Provider mappers also emit `{:failed, nil}` for deliveries that were handed off successfully:
Mailgun `"event" => "failed"` with no severity (`webhook/providers/mailgun.ex:204`) and SES `"Rendering Failure"`
(`webhook/providers/ses.ex:877`). Such a row has `status: :sent` and a provider-sourced `:failed` event.

Confirmed by running `Copy.delivery_verdict/2` with `status: :sent`, `last_event_type: :failed` and a
`%{type: :failed, reject_reason: nil}` event. It returns the cause "Sending failed before a successful
handoff to the provider." That is a factual claim the product cannot support, and it tells the operator the
app never reached the provider when the provider accepted the email and then failed it. It contradicts the
phase's own rule R-TRUTH-1 ("names a cause only when one was recorded"; the no-reason text must be
"No reason was recorded for this email."). The correct signal already exists in the same module:
`send_failure_or_fallback/1` (`copy.ex:438-440`) keys on the row's `status == :failed`, which is true only for
the send-time path.

**Fix:**
```elixir
defp failure_cause(row, events) when is_list(events) do
  case events |> Enum.filter(&(Map.get(&1, :type) in @failure_event_types)) |> List.last() do
    nil -> {send_failure_or_fallback(row), []}
    event -> {event_cause(row, event), []}
  end
end

defp event_cause(row, event) do
  case {Map.get(event, :type), Map.get(event, :reject_reason)} do
    # A :failed event with no provider reason is a send-time failure only when the row says so.
    {:failed, nil} -> send_failure_or_fallback(row)
    {_type, reason} -> reason_cause(:reject_reason, @reject_reason_sentences, reason)
  end
end
```
Add a case for a `status: :sent` row whose latest event is `:failed` with a nil reason: it must read the
fallback sentence.

## Warnings

### WR-01: Health overview delivery counts still use the pre-phase atom rule, so a bounce followed by an open is counted nowhere

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:2896-2908` (`health_issues/7`)
**Issue:** The Activity summary tiles and row badges now bucket by `StatusMap.delivery_class/1` (`:2777-2800`,
"one rule for the summary and the row marks"). The Health overview's Failed, Bounced, Rejected and Delayed
cards still do:

```elixir
matching = Enum.filter(groups, &(Components.delivery_display_status(&1) == event))
```

`delivery_display_status/1` returns the latest event atom. Confirmed by running both functions on a
bounce-then-open group: `delivery_class` gives `:failed` and `delivery_display_status` gives `:opened`. That
email therefore counts under "Needs attention" on Activity and under no card on Health, so Health can say
"Bounced emails: 0" while Activity shows the bounce. The same split applies to a row confirmed delivered
whose latest event is a later `:deferred`: Health shows it under "Delayed emails" and Activity reads
Delivered. Decision D-05 names this exact defect ("a bounce followed by an open reads Delivered") and fixes
only one of the two consumers of `outcome_groups`.

**Fix:** Bucket the health cards from `StatusMap.delivery_class/1` as well, or state in the card help that
the counts follow the latest event. For example, count the `:failed` class under "Failed emails" and keep the
event-specific cards (Bounced, Rejected) only where `last_event_type` is the failure event. Add a Health
overview test with a bounce-then-open group.

### WR-02: "Not sent" verdict treats "no matching suppression entry" as "an entry that recorded no reason"

**File:** `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:132-137` (feeds `copy.ex:397-411, 442-451`)
**Issue:** When the suppression read succeeds but no entry matches (`Suppressions.get_delivery_suppression_state/2`
returns nil; entries that expired or were removed no longer match), `suppression_evidence(:ready, nil)` returns
`%{reason: nil}`. `Copy.suppression_cause/1` renders that as the fixed "No reason was recorded for this email."
The same verdict still says, in the present tense, "This address is on your suppression list" and tells the
operator to "Remove this address from the suppression list". Confirmed by running `delivery_verdict/2` with
`suppressed_at` set and `suppression: %{reason: nil}`. The suppression card directly below says
"No current Mailglass match" (`suppression_card.ex:133`), so Full detail contradicts itself. Entry rows cannot
lack a reason (see WR-06), so the "no reason" reading is never the true one for this input.

**Fix:** Pass a distinct evidence value for "read ok, no entry" and have `Copy.verdict(:not_sent, ...)` word
it truthfully, for example a note "No current suppression entry matches this address. It was blocked when
this was recorded." with no removal step. For example:
```elixir
defp suppression_evidence(:ready, nil), do: :no_entry
```
and a `suppression_cause(:no_entry)` clause returning `{nil, ["No current suppression entry matches this address."]}`.

### WR-03: A persisted `"nil"` mailable is shown as the mailer name "Nil"

**File:** `mailglass_admin/lib/mailglass_admin/operator/mailer_name.ex:26-36, 42-48`
**Issue:** The moduledoc promises "No name is invented: a nil, blank or unreadable value has no name". But core
persists `mailable: inspect(rendered.mailable)` (`lib/mailglass/outbound/persistence.ex:15, 222, 236`), and
`Message.mailable` is typed `module() | nil` with `nil` the default from `Message.build/2`
(`message.ex:57, 114`). A message built without a mailable is stored as the string `"nil"`. Confirmed by
running `MailerName.plain_name("nil")`, which returns `"Nil"`. Every such row then shows a "Nil" mailer line in
the Activity list and a "Mailer: Nil" cell with the identity "nil" in Full detail, which is an invented name
for a missing one.

**Fix:**
```elixir
def identity(value) when is_binary(value) do
  trimmed = String.trim(value)

  if trimmed != "" and trimmed != "nil" and String.valid?(trimmed), do: trimmed
end
```
Add a test row with `mailable: "nil"` that asserts no mailer line renders.

### WR-04: Retired word "unmatched" is still on screen in the support drilldown banner

**File:** `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex:432`
**Issue:** D-12 retires "unmatched" as a headline word and the `:unmatched_reports` vocabulary entry is
`wired: true`. The title and body in `operator_live.ex` were changed, but the banner still reads
`"Showing unmatched webhook evidence"` for `%{focus: :orphan_backlog}` with no `event_id`, the state the Health
overview link produces when the summary has no oldest event. The rubric rule R-WORDS-1 names "unmatched
events" as a breach.

**Fix:**
```elixir
defp drilldown_banner(%{focus: :orphan_backlog}),
  do: "Showing provider reports that match no email"
```
Also change the moduledoc line `support_cards.ex:6` ("unmatched webhooks") so the doc and the screen agree.

### WR-05: Compile-time `raise` over a core enum can break an adopter's build

**File:** `mailglass_admin/lib/mailglass_admin/copy.ex:255-263`
**Issue:** The module body compares its sentence keys with `Mailglass.Events.Event.__reject_reasons__()` and
raises `ArgumentError` at compile time if they differ. That is useful in this repo. In a published package it
runs in the adopter's compile against whichever core version resolved. Admin's Hex requirement on core is
`{:mailglass, "~> 2.0"}` (`mailglass_admin/mix.exs:152`), and `docs/api_stability.md` treats additions to closed
atom sets as minor-version extensions. Any core release that adds a reject reason, paired with an older admin
the resolver still allows, fails `mix compile` with an error raised from a dependency's module. The module
already has the runtime defence for the same case: `reason_cause/3` returns `@unrecognized_reason` for an
unlisted value. The suppression enum, which has the same drift risk, is deliberately guarded by a test rather
than a compile-time raise (see the comment at `copy.ex:251-254`), so the two enums are handled inconsistently.

**Fix:** Move the parity assertion into the required admin-lane test, as is already done for suppression
reasons, and keep the runtime `@unrecognized_reason` fallback. If a compile-time guard is wanted, make it warn
(`IO.warn/2`), not raise.

### WR-06: Fixed "no reason" text for a suppression entry that cannot exist without a reason

**File:** `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex:135-141`
**Category:** necessity
**Issue:** `reason_value/1` and the comment above it ("the entry exists, it just carries no reason") guard a
state that cannot occur. `mailglass_suppressions.reason` is `NOT NULL` (`lib/mailglass/migrations/postgres/v01.ex:169`),
`Entry` lists `:reason` in `@required` (`lib/mailglass/suppression/entry.ex:67`), and `project_state/1`
(`lib/mailglass/operator/suppressions.ex:105-123`) copies it unconditionally. The only nil the card can see is
no state at all, which renders a different branch. The sentence also reaches the verdict only through the
WR-02 conflation. Keeping the branch encourages that conflation.

**Fix:** Drop the nil branch and render `value(@suppression_state, :reason)` directly. Keep the "no reason
recorded" text only for provider failure events, where a nil `reject_reason` is real.

## Info

### IN-01: `outcome_groups` reuses `bounced_at`, `complained_at` and `suppressed_at` as `true | nil` while rows carry `DateTime | nil`

**File:** `lib/mailglass/operator/deliveries.ex:85-92` (vs `:139-145`)
**Issue:** The same key names hold two types in a read model that `docs/api_stability.md` lists as a stable
adopter surface. The comment explains the intent (a non-nil value means "recorded"), but nothing in `@spec`
or `@doc` tells adopters, and a caller doing `DateTime.diff(group.bounced_at, now)` crashes on `true`. The new
`docs/api_stability.md` sentence only says maps may gain keys.
**Fix:** Document the two shapes in the function `@doc`, or name the group keys `bounced?` / `terminal?` and
let `StatusMap` read either shape.

### IN-02: `status_badge` ignores `size` in its pane-mark branch

**File:** `mailglass_admin/lib/mailglass_admin/components.ex:1568-1574`
**Issue:** The mark branch hard-codes `badge-md` and `status_mark size={:row}`. `delivery_badge`'s `size`
(`:row | :detail`) and `status_badge`'s `size` (`:sm | :md`) only affect the Unknown fallback, although the
docstring says "size: :md for detail headers".
**Fix:** Pass `@size` through to the class and the mark size, or remove the unused attribute for the mark branch
and document it.

### IN-03: The provider is named three different ways on one screen

**File:** `mailglass_admin/lib/mailglass_admin/copy.ex:178-184` (vs `operator/detail_header.ex:80`, `operator/quick_view.ex:236`, `operator_live.ex:1494-1497`)
**Issue:** The verdict says "Sent with Postmark." and "Amazon SES", the header cell and Quick view show
`String.upcase/1` ("POSTMARK", "SES"), and the filter uses `provider_label/1` ("SES"). There are three
naming functions for one fact.
**Fix:** Route the header, Quick view and filter through `Copy.provider_name/1`.

### IN-04: The whole "Not sent" class has no producer in the product

**File:** `mailglass_admin/lib/mailglass_admin/status_map.ex:29-34` (and `reference/demo_app/lib/mailglass_demo/journey_seed.ex:115-150`)
**Category:** necessity
**Issue:** `StatusMap`'s own comment says suppression is checked in `Preflight` before any insert, so a
suppressed send leaves no Delivery row and no Event, and "no library code writes Delivery.status :suppressed".
A search of `lib/` for a `:suppressed` status or event producer found none. So the Not sent verdict, mark,
next-step copy, "Go to the suppression card" link and the Needs attention bucket for it cannot be reached by
real data, and `JourneySeed.suppressed!/1` hand-writes a row the product never creates, then the after-catalog
uses it as evidence of that screen. The real case for the headline job (customer's address is suppressed) has
no Activity row at all and no empty-state hint pointing to the suppression list. This rests on judgment: the
brand book defines the word and the code is written to be ready for it.
**Fix:** Say plainly in the phase record that the Not sent screen is unreachable from production data, and
either add an Activity empty-state hint for suppressed recipients or make the seed row's docstring state that
the row is synthetic.

### IN-05: Gallery "long-label" specimens are no longer long

**File:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex:874, 919`
**Issue:** The `nav_pill` "long-label" specimen was shortened to "Needs attention" and the `stat_card` one to
"Activity that needs attention" to avoid retired wording. Both keep the name "long-label" but no longer stress
wrapping or truncation, so the overflow regression they exist to catch is no longer exercised.
**Fix:** Keep the stress length with new wording (for example a 60-plus character Activity phrase), or rename
the specimens and add a real long-label one.

### IN-06: `display_parts/1` writes "UTC" without checking the zone

**File:** `mailglass_admin/lib/mailglass_admin/components.ex:2050-2051, 2053-2066`
**Issue:** The zone is a literal "UTC" and `exact_utc/1` also appends " UTC", but neither shifts the value. A
`DateTime` in another zone would be printed in its own wall-clock time under a "UTC" label, which is the false
zone this phase exists to remove. Current callers pass Ecto UTC values or `DateTime.from_iso8601/1` results, so
this is not reachable today.
**Fix:** Normalise first: `at = DateTime.shift_zone!(at, "Etc/UTC")` in `display_parts/1` and `exact_utc/1`, or
add a `%DateTime{time_zone: "Etc/UTC"}` guard.

### IN-07: The capture driver exempts one path from the clean-tree check but still records `dirty: false`

**File:** `reference/demo_app/assets/catalog/capture-before-catalog.cjs:162-176, 178-192, 215`
**Issue:** `.planning/config.json` is excluded from the clean-tree guard (the repo's current working tree has
exactly that file modified). The manifest still records `dirty: false` and `recheck.clean: true`. The reasoning
in the comment is sound (the demo and bundle never read the file), but the manifest then states something
slightly stronger than what was checked, in an evidence tool whose point is provenance.
**Fix:** Record the exemption in the manifest, for example `source.exempt_paths: [".planning/config.json"]`, so
a reader can see the rule that applied.

### IN-08: The verdict cause reads only the first 101 events of a delivery

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:1517` (with `lib/mailglass/operator/timeline.ex:20-21`, `copy.ex:422-427`)
**Issue:** The timeline read is `limit: 101` in ascending order. `Copy.failure_cause/2` takes `List.last/1` of
the failure events in that window as "the latest failure". Open and click events accumulate, so a delivery with
more than 101 events can show an older failure's cause, or the "No reason was recorded" fallback, while a later
failure event outside the window carries a reason. The timeline itself shows a "more events" marker; the verdict
does not.
**Fix:** Read the latest failure event with its own bounded query, or mark the cause as "from the first 100
events" when `has_more_events?`.

### IN-09: "Latest: Dispatched" appears on every normally sent row

**File:** `mailglass_admin/lib/mailglass_admin/components.ex:1655-1663`
**Issue:** A successful send is stored with `status: :sent` and `last_event_type: :dispatched`
(`lib/mailglass/outbound/persistence.ex:72`). The class word is "Sent", so `latest_event_differs?/1` compares
"Dispatched" with "Sent" and returns true (confirmed by running it on that row shape). Every healthy sent row
in the list and every Full detail therefore gets an extra "Latest: Dispatched" line, repeating a word the
rubric retires as a status. The demo seeds write `last_event_type: :sent`, so the after-catalog screenshots do
not show this.
**Fix:** Treat `:dispatched` as the same fact as the Sent class in `latest_event_differs?/1`, and give the demo
seed rows the `:dispatched` shape production writes.

---

_Reviewed: 2026-11-16T01:00:10Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
