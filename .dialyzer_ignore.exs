# See `defp dialyzer/0` in mix.exs for flag and format rationale.
# Format: ignore_file_strict tuples — {file, short_description}.
# Each entry MUST be preceded by a `# Reason: <one-line>` comment
# validated by `scripts/check_dialyzer_ignore.sh`.
# Hard cap: 15 entries (D-08-07). Over-budget triggers a v0.3 deep-clean phase.
# Generate entries with: mix dialyzer --format ignore_file_strict

[
  # Reason: BatchFailed struct macro-generated callbacks mismatch Error behaviour type/1; Phase-9 cleanup.
  {"lib/mailglass/errors/batch_failed.ex", "Type mismatch with behaviour callback to type/1."},
  # Reason: BatchFailed struct macro-generated callbacks mismatch Error behaviour retryable?/1; Phase-9 cleanup.
  {"lib/mailglass/errors/batch_failed.ex", "Type mismatch with behaviour callback to retryable?/1."},
  # Reason: resolve_from_path scope/2 raises Mailglass.ConfigError intentionally; no_return is by design.
  {"lib/mailglass/tenancy/resolve_from_path.ex", "Function scope/2 only terminates with explicit exception."},
  # Reason: fail_step/2 raises intentionally to halt CI with a non-zero exit; no_return is by design.
  {"lib/mix/tasks/mailglass.publish.check.ex", "Function fail_step/2 only terminates with explicit exception."},
  # Reason: schema_version/0 spec'd as pos_integer() for forward-compat; narrowing to `1` would force consumers to widen on every bump.
  {"lib/mailglass/deliverability/result.ex", "Type specification is a supertype of the success typing."},
  # Reason: RouteRecordingAdapter (test/support/outbound_route_test_support.ex) is a deliberately-misshapen test adapter that returns `{:error, :bad_shape}` to assert `Mailglass.Tenancy.resolve_outbound_adapter_ref/1`'s dispatcher rejects malformed shapes; the divergence is the test contract.
  {"test/support/outbound_route_test_support.ex", "Type mismatch for @callback resolve_outbound_adapter_ref/1 in Mailglass.Tenancy behaviour."}
]
