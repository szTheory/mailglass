---
phase: 149-first-send-contract-foundation
reviewed: 2026-08-02T18:39:02Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - lib/mailglass/outbound/preflight.ex
  - lib/mailglass/outbound.ex
  - lib/mailglass/config.ex
  - lib/mailglass/renderer.ex
  - test/mailglass/boundary_test.exs
  - test/mailglass/outbound/preflight_test.exs
  - test/mailglass/outbound/deliver_later_test.exs
  - test/mailglass/outbound_test.exs
  - test/mailglass/renderer_test.exs
  - test/mailglass/tenancy_test.exs
  - test/mailglass/docs_migration_smoke_test.exs
  - mailglass_admin/test/mailglass_admin/preview_live_test.exs
  - docs/api_stability.md
  - guides/authoring-mailables.md
  - guides/getting-started.md
  - guides/jobs.md
  - guides/preview.md
  - guides/multi-tenancy.md
  - mix.exs
  - mailglass_admin/mix.exs
  - guides/migration-from-swoosh.md
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 149: Code Review Report

**Reviewed:** 2026-08-02T18:39:02Z
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found

## Summary

The iteration-2 fixes close the original recipient-field and blank-rendered-HTML blockers: sole `to`/`cc`/`bcc` recipients are carried through current sync and async dispatch, explicit plaintext survives blank function HTML, malformed recipient envelopes fail before effects with non-PII context, the migration example executes, and the required core/admin support aliases pass. However, two first-send contract violations remain. An unsupported explicit plaintext value is silently replaced when HTML is valid, and idempotency treats otherwise different native recipient fields as the same delivery. The report therefore cannot be clean under the evidence-or-fail UAT requirement.

## Critical Issues

### CR-01 (BLOCKER): Supported HTML masks and silently drops an unsupported explicit plaintext body

**File:** `/Users/jon/projects/mailglass/lib/mailglass/outbound/preflight.ex:71-79`

**Issue:** `validate_body/1` returns `:ok` as soon as either body is `:present`, before rejecting the other body's `:unsupported` state. A message with valid HTML and `text_body: :invalid` therefore passes preflight. `Renderer.render/1` then treats that non-binary plaintext as absent and either generates plaintext from the HTML or replaces it with `nil` ([`renderer.ex:97-102`](/Users/jon/projects/mailglass/lib/mailglass/renderer.ex:97)). This violates D-05/FIRST-07: unsupported body values must produce `%SendError{type: :preflight_rejected}` before durable/provider effects; no path may silently drop content. Direct evidence: `MIX_ENV=test mix run --no-start` with HTML `"<p>valid</p>"` and `text_body: :invalid` returned `{:ok, _}` from preflight and rendered `text_body: "valid"`.

**Fix:** Reject any unsupported supplied body before accepting a present counterpart, while continuing to allow `nil`/blank alongside a valid body. For example:

```elixir
cond do
  :unsupported in states -> body_invalid(:unsupported)
  :present in states -> :ok
  true -> body_invalid(:empty)
end
```

Add sync, async, and batch regression tests for valid HTML plus each invalid plaintext shape (atom, invalid UTF-8), asserting typed rejection and zero deliveries/jobs/provider sends.

### CR-02 (BLOCKER): Idempotency erases the native recipient field and suppresses a distinct valid envelope

**File:** `/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:1205-1218`

**Issue:** `compute_idempotency_key/1` hashes tenant, mailable, normalized recipient address, and body bytes, but omits the sole-recipient field. Thus otherwise identical messages addressed as `to: recipient@example.com` and `cc: recipient@example.com` (or `bcc`) generate the same unique key even though Phase 149 explicitly treats the native field as part of the supported envelope and retains it for async dispatch. The second synchronous insert conflicts at the unique index; batch replay similarly returns/reuses the first field's delivery. Consequently a valid `cc`/`bcc` envelope can be lost at the idempotency path, contrary to FIRST-03 and the required re-review proof.

**Fix:** Include the validated field in the key material and prove the field-aware behavior:

```elixir
{:ok, %{field: field, address: recipient}} = Message.sole_recipient(msg)
:crypto.hash(:sha256, [tenant_id, "|", mailable, "|", Atom.to_string(field), "|", recipient, "|", content_hash])
```

Add tests that send otherwise identical `to`, `cc`, and `bcc` messages and assert three distinct delivery keys and provider envelopes, while an exact same-field replay remains idempotent.

---

_Reviewed: 2026-08-02T18:39:02Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
