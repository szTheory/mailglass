---
phase: 78-seed-data-expressiveness
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - mailglass_admin/e2e/operator.spec.js
  - mailglass_admin/test/support/operator_fixtures.ex
  - reference/demo_app/lib/mailglass_demo/demo_data.ex
  - reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 78: Code Review Report

**Reviewed:** 2026-06-04
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed the Phase 78 seed-data expressiveness changes: the demo-app seed
generator (`demo_data.ex`) and its determinism test, the operator test-support
fixture (`operator_fixtures.ex`), and the operator Playwright e2e spec.

Per scope, findings target real correctness defects (seed/payload consistency,
sort-order determinism, idempotency, assertion accuracy) rather than
production-grade hardening that does not apply to synthetic demo data.

The counts and matrices in `demo_data_reset_test.exs` were cross-checked against
the actual seed body and reconcile correctly (16 deliveries, 35 events, 6
inbound, 1 suppression, 6 evidence, 8 replay runs). The Playwright row-index
assumptions were traced against the live delivery ordering query
(`lib/mailglass/operator/deliveries.ex`: `desc: last_event_at, desc: inserted_at,
desc: id`) and are consistent with the seed — with one latent fragility noted
below. No blockers found; four warnings concern internally inconsistent webhook
payloads, mislabeled replay metadata, and ordering determinism that rests on
microsecond insert timing.

## Warnings

### WR-01: Webhook `raw_payload` contradicts its own event type for the bounce webhook

**File:** `reference/demo_app/lib/mailglass_demo/demo_data.ex:142-165, 683-701`
**Issue:** `webhook!/6` hardcodes `raw_payload` to a *Delivery* shape for every
caller:
```elixir
raw_payload: %{
  "RecordType" => "Delivery",
  "MessageID" => message_id,
  "ID" => event_id,
  "DeliveredAt" => "2026-06-01T14:10:00Z"
}
```
But `usage_webhook` is created with `event_type_raw: "Bounce"` /
`event_type_normalized: "bounced"`. The resulting row claims `RecordType =>
Delivery` with a `DeliveredAt` timestamp while its normalized type is `bounced`.
This is a self-contradictory seed record: any operator/admin surface that renders
the raw payload alongside the normalized type will show a "delivered" payload for
a bounced event, undermining the demo's purpose of exercising the bounce path
realistically. It also means the seed cannot be trusted as a fixture for
payload-vs-type consistency.
**Fix:** Make the payload follow the event type. Branch `raw_payload` on
`event_type_raw`, e.g.:
```elixir
raw_payload:
  case event_type_raw do
    "Bounce" ->
      %{"RecordType" => "Bounce", "MessageID" => message_id, "ID" => event_id,
        "Type" => "HardBounce", "BouncedAt" => "2026-06-01T14:10:00Z"}
    _ ->
      %{"RecordType" => "Delivery", "MessageID" => message_id, "ID" => event_id,
        "DeliveredAt" => "2026-06-01T14:10:00Z"}
  end
```

### WR-02: Shared `replay_metadata/2` hardcodes `provider_event_id => "demo-receipt-child"` for every delivery

**File:** `reference/demo_app/lib/mailglass_demo/demo_data.ex:152, 757-765`
**Issue:** `replay_metadata/2` always emits `"provider_event_id" =>
"demo-receipt-child"`:
```elixir
defp replay_metadata(webhook, delivery) do
  %{
    "provider" => delivery.provider,
    "provider_event_id" => "demo-receipt-child",   # constant
    ...
  }
end
```
It is called for both `receipt` (line 98) and `usage_alert` (line 152). The
`usage_alert` `:sent` event therefore carries replay metadata labeling its child
provider event as `demo-receipt-child`, even though it belongs to the usage
delivery (`sg-demo-usage-001`, sendgrid). The `webhook_event_id`/`message_id`
fields are correct (derived from args) but the `provider_event_id` is mislabeled
and shared across two unrelated deliveries — a correctness defect in the linked
replay metadata that any replay-target lookup keyed on `provider_event_id` would
see as a collision/mismatch.
**Fix:** Derive the child id from the delivery (or pass it in), e.g.
`"provider_event_id" => "demo-replay-child-#{delivery.provider_message_id}"`, so
each delivery's replay metadata is distinct and self-consistent.

### WR-03: Playwright row-index stability depends on microsecond insert timing, not an explicit deterministic key

**File:** `mailglass_admin/e2e/operator.spec.js:52,108,139,167,197,208` and `mailglass_admin/test/support/operator_fixtures.ex:46-108`
**Issue:** The spec addresses delivery rows by hardcoded index (row 0 selected,
row 1 noop, row 2 ambiguous, row 3 exact). Three of these — exact, ambiguous,
noop — are seeded with the *identical* `last_event_at: hours_ago(2)` (fixtures
lines 53, 72, 98). The list query orders `desc: last_event_at, desc:
inserted_at, desc: id`. The three-way tie therefore resolves on `desc:
inserted_at`; because the fixture inserts them in order exact → ambiguous → noop,
the descending `inserted_at` yields noop(1), ambiguous(2), exact(3), which is
exactly what the spec asserts. This works *today* only because
`timestamps(type: :utc_datetime_usec)` gives each sequential insert a distinct
microsecond. If two of the three inserts ever land in the same microsecond, the
tie falls through to `desc: id` (a random UUID) and the row indices become
non-deterministic — a latent flake that would surface as the wrong recipient at
a given index.
**Fix:** Give the three "tied" deliveries strictly distinct `last_event_at`
values in the fixture (e.g. exact = hours_ago(2), ambiguous = minutes_ago(125),
noop = minutes_ago(124)) so row order is fixed by the primary sort key and no
longer relies on insert timing. Alternatively, change the spec to select rows by
recipient text (`getByTestId("operator-delivery-row").filter({ hasText:
noopRecipient })`) instead of positional index.

### WR-04: `insert_noise/0` comment claims to prove RESTART IDENTITY but cannot — tables use UUID PKs

**File:** `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs:14,105-107`
**Issue:** The test comment states "Prove truncation + RESTART IDENTITY by
perturbing data before the second reset," but `insert_noise/0` only
`TRUNCATE ... RESTART IDENTITY`s the suppressions table — it inserts no rows and
does not consume any identity sequence. More fundamentally, every table here uses
UUID primary keys (`Ecto.UUID.generate()` / schema `binary_id`), so there is no
serial identity sequence for `RESTART IDENTITY` to reset. The assertion
`refute snapshot() == baseline` passes solely because the suppression count drops
1 → 0, not because anything about identity restart was exercised. The test gives
false confidence that RESTART IDENTITY behavior is covered.
**Fix:** Either drop the RESTART-IDENTITY claim from the comment (since UUID PKs
make it inapplicable), or make the perturbation meaningful by inserting extra
rows across multiple tables before the second `reset!()` and asserting the rerun
snapshot returns exactly to baseline (which already happens) — and rename the
helper to reflect that it perturbs row *contents*, not identity sequences.

## Info

### IN-01: Redundant `Map.put_new(:inserted_at/:updated_at)` after `Enum.into(defaults)` already set them

**File:** `mailglass_admin/test/support/operator_fixtures.ex:228-229`
**Issue:** `defaults` (lines 217-218) already set `inserted_at` and `updated_at`,
so the subsequent `Map.put_new(:updated_at, ...)` / `Map.put_new(:inserted_at,
...)` are unreachable no-ops (`put_new` never overwrites an existing key). Dead
code that obscures intent.
**Fix:** Remove the two `Map.put_new/3` calls on lines 228-229.

### IN-02: Mixed access styles on the suppression row map (`row.metadata` vs `row[:expires_at]`)

**File:** `mailglass_admin/test/support/operator_fixtures.ex:303,305`
**Issue:** `insert_suppression!/1` accesses most fields with dot syntax
(`row.id`, `row.address`, `row.metadata`) but uses `row[:expires_at]` for one
column. `expires_at` is never added to `defaults` or by `normalize_suppression_row/1`,
so the bracket access is a deliberate "may be absent → nil" lookup; the
inconsistency is easy to misread as an oversight. Functionally fine (column gets
nil), but a reviewer cannot tell at a glance whether the nil is intended.
**Fix:** Add `expires_at: nil` to the `defaults` map and use `row.expires_at`
uniformly, making the nil explicit and the access style consistent.

### IN-03: `event_types` and `replay_sources` are captured in the snapshot but never independently asserted

**File:** `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs:94,99,141-146,164-169`
**Issue:** `event_types` and `replay_sources` are computed in `snapshot/0` and
listed in `deterministic_keys/0`, so they are only checked for baseline-vs-rerun
equality (a determinism check), never against an expected literal set the way
`delivery_message_ids`, `webhook_provider_matrix`, etc. are. Given Phase 78's
goal is seed *expressiveness* (broad event-type and outcome coverage), the
absence of an explicit expected-set assertion means a regression that drops a
seeded event type (e.g. removing the `:autoresponded` or `:webhook_replay_failed`
seed) would still pass as long as both runs agree.
**Fix:** Add explicit assertions, e.g. `assert rerun.event_types == [...]` with
the full expected sorted type list, mirroring the other matrix assertions, so
event-type breadth is actually pinned.

---

_Reviewed: 2026-06-04_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
