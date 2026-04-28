# Phase 10: Stream Policy Implementation - Validation

## Goal
Implement the core stream atom set and strict runtime setters for message streams, enforce policies, catch violations with credo, and automatically apply Feedback-ID headers.

## Truths
- A mailable declared `use Mailglass.Mailable, stream: :bulk` has `%Message{stream: :bulk}` stamped at `Message.new_from_use/2`.
- Runtime `%Message{stream: :bulk}` assignment also works via `put_stream/2`.
- `:transactional`, `:operational`, `:bulk` are the only accepted atoms for the stream field.
- Sending a message that violates stream policy (e.g., `:bulk` without `mailable` set) raises a structured error tuple.
- Existing `with :ok <- Stream.policy_check(msg)` call sites require zero modification.
- `mix credo --strict` catches a `:transactional` mailable with tracking enabled.
- `mix credo --strict` catches a mailable with tracking enabled that defaults to transactional (missing stream set).
- Feedback-ID format auto-populated as `{sender_id}:{mailable}:{tenant_id}:{stream}` when feedback_id is configured.
- stream slot reflects runtime stream value.

## Artifacts
- `lib/mailglass/stream.ex` (Stream atom definitions and valid?/1 guard, policy_check/1 returning error tuples)
- `lib/mailglass/message.ex` (put_stream/2 setter and strict new_from_use/2 stamping)
- `lib/mailglass/errors/stream_policy_error.ex` (StreamPolicyError struct implementing Mailglass.Error)
- `credo_checks/stream_policy_consistent.ex` (Custom credo check logic)
- `lib/mailglass/config.ex` (`feedback_id` schema field)
- `lib/mailglass/compliance.ex` (Logic to inject the Feedback-ID header into the message)

## Key Links
- from: `lib/mailglass/message.ex` to: `lib/mailglass/stream.ex` via: valid?/1 guard in setter and builder functions
- from: `lib/mailglass/stream.ex` to: `lib/mailglass/errors/stream_policy_error.ex` via: Return of `{:error, %StreamPolicyError{}}` instead of raise
- from: `credo_checks/stream_policy_consistent.ex` to: AST (Macro.traverse) via: Finding `use Mailglass.Mailable` opts
- from: `lib/mailglass/compliance.ex` to: `lib/mailglass/config.ex` via: Reading the `feedback_id` config at runtime
