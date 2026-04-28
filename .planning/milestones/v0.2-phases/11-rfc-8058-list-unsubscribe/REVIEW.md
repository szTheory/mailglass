---
phase: 11-rfc-8058-list-unsubscribe
reviewed: 2026-04-28T10:21:36Z
depth: standard
files_reviewed: 33
files_reviewed_list:
  - .planning/phases/11-rfc-8058-list-unsubscribe/11-01-SUMMARY.md
  - .planning/phases/11-rfc-8058-list-unsubscribe/11-02-SUMMARY.md
  - .planning/phases/11-rfc-8058-list-unsubscribe/11-03-SUMMARY.md
  - .planning/phases/11-rfc-8058-list-unsubscribe/11-04-SUMMARY.md
  - .planning/phases/11-rfc-8058-list-unsubscribe/11-05-SUMMARY.md
  - .planning/phases/11-rfc-8058-list-unsubscribe/11-06-SUMMARY.md
  - .planning/phases/11-rfc-8058-list-unsubscribe/11-07-SUMMARY.md
  - .credo.exs
  - credo_checks/require_atomic_unsubscribe_headers.ex
  - guides/dkim-setup.md
  - guides/unsubscribe.md
  - lib/mailglass.ex
  - lib/mailglass/compliance.ex
  - lib/mailglass/compliance/unsubscribe.ex
  - lib/mailglass/compliance/unsubscribe_controller.ex
  - lib/mailglass/compliance/unsubscribe_html.ex
  - lib/mailglass/compliance/unsubscribe_html/confirm.html.heex
  - lib/mailglass/config.ex
  - lib/mailglass/lifecycle.ex
  - lib/mailglass/outbound.ex
  - lib/mailglass/router.ex
  - lib/mailglass/tenancy.ex
  - lib/mix/tasks/mailglass.gen.unsubscribe.ex
  - mix.exs
  - test/credo_checks/require_atomic_unsubscribe_headers_test.exs
  - test/mailglass/compliance/unsubscribe_controller_test.exs
  - test/mailglass/compliance/unsubscribe_test.exs
  - test/mailglass/compliance_test.exs
  - test/mailglass/docs/unsubscribe_guide_test.exs
  - test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs
  - test/mailglass/properties/unsubscribe_property_test.exs
  - test/mailglass/router/unsubscribe_router_test.exs
  - test/mix/tasks/mailglass.gen.unsubscribe_test.exs
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-04-28T10:21:36Z
**Depth:** standard
**Files Reviewed:** 33
**Status:** issues_found

## Summary

Reviewed the Phase 11 RFC 8058 implementation plus the phase summaries. The main regression is in the real outbound pipeline: unsubscribe headers are generated before a persisted `delivery.id` exists, so production unsubscribe links can point at a random UUID instead of the stored delivery. I also verified the changed controller suite directly; two tamper-path tests fail today because the test mutation does not reliably invalidate a Phoenix token, so the claimed coverage in the phase summaries is overstated.

Verification performed:

- `mix test test/mix/tasks/mailglass.gen.unsubscribe_test.exs test/mailglass/router/unsubscribe_router_test.exs test/mailglass/compliance/unsubscribe_controller_test.exs`
- `mix run -e '...Mailglass.Compliance.apply_outbound_headers()...'` to confirm header generation signs a random UUID when `metadata[:delivery_id]` is absent

## Warnings

### WR-01: Outbound unsubscribe links are minted before a real delivery id exists

**File:** `lib/mailglass/outbound.ex:293-308`, `lib/mailglass/compliance.ex:202-229`
**Issue:** `Mailglass.Outbound` applies unsubscribe headers immediately after render, but `Mailglass.Compliance` falls back to `Ecto.UUID.generate()` when `message.metadata[:delivery_id]` is missing. The actual `delivery.id` is only stamped later in `do_send_after_preflight/2`, after `persist_queued/2` succeeds. In normal `deliver/2`, `deliver_later/2`, and batch preflight flows, the emitted `List-Unsubscribe` token can therefore resolve to a UUID that does not correspond to any stored delivery, producing dead one-click links in real sends. The current tests miss this because they either call `sign_token/1` directly or inject `metadata[:delivery_id]` up front.
**Fix:**
```elixir
# Option 1: defer unsubscribe injection until the delivery row exists
with {:ok, %{delivery: delivery}} <- persist_queued(rendered, opts) do
  rendered_with_id = Message.put_metadata(rendered, :delivery_id, delivery.id)

  prepared =
    rendered_with_id
    |> Compliance.apply_outbound_headers()
    |> Tracking.rewrite_if_enabled()
end
```

Add an integration test that drives `Mailglass.Outbound.deliver/2` or `deliver_later/2`, extracts the emitted unsubscribe token, and asserts it verifies to the persisted `delivery.id`.

### WR-02: Tamper-path controller tests are not actually invalidating the token and currently fail

**File:** `test/mailglass/compliance/unsubscribe_controller_test.exs:156-167`, `test/mailglass/compliance/unsubscribe_controller_test.exs:254-276`
**Issue:** The test suite mutates only the last character of the Phoenix token and assumes the result is invalid. In practice that mutation still verifies in the current runtime, so the GET tamper test returns `200` and the POST tamper test writes an unsubscribe event. I reproduced this via the targeted `mix test` run above, which currently fails with 2 test failures. Even if the runtime verification is acceptable, these tests do not reliably prove tamper rejection and leave the controller contract under-verified.
**Fix:**
```elixir
tampered =
  token
  |> String.split(".")
  |> update_in([Access.at(2)], fn signature ->
    String.replace_prefix(signature, String.first(signature), "A")
  end)
  |> Enum.join(".")

assert {:error, :invalid} = Unsubscribe.verify_token(tampered)
```

Mutate a deterministic position in the signed payload/signature segment, and assert `verify_token/1` is invalid before exercising the controller path.

## Info

### IN-01: Phase summaries overstate validation coverage relative to the current code

**File:** `.planning/phases/11-rfc-8058-list-unsubscribe/11-03-SUMMARY.md:49-52`, `.planning/phases/11-rfc-8058-list-unsubscribe/11-03-SUMMARY.md:83-104`, `.planning/phases/11-rfc-8058-list-unsubscribe/11-06-SUMMARY.md:52-55`, `.planning/phases/11-rfc-8058-list-unsubscribe/11-06-SUMMARY.md:97-101`
**Issue:** The plan summaries claim the controller paths are locked down and that Phase 11 has no remaining unsubscribe-flow test gaps, but the current controller suite fails on tamper cases and there is no integration coverage proving the outbound pipeline signs the persisted `delivery.id`.
**Fix:** Re-run the affected verification after fixing WR-01 and WR-02, then update the summaries so they match the actual test and coverage state.

---

_Reviewed: 2026-04-28T10:21:36Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
