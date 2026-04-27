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
  # Reason: Phase-9-firewall — insert_into_body_end/2 unused until tracking pipeline is wired in Phase 9.
  {"lib/mailglass/tracking/rewriter.ex", "Function insert_into_body_end/2 will never be called."},
  # Reason: Phase-9-firewall — tracking_host/0 unused until tracking pipeline is wired in Phase 9.
  {"lib/mailglass/tracking/rewriter.ex", "Function tracking_host/0 will never be called."},
  # Reason: Phase-9-firewall — tracking_scheme/0 unused until tracking pipeline is wired in Phase 9.
  {"lib/mailglass/tracking/rewriter.ex", "Function tracking_scheme/0 will never be called."},
  # Reason: Phase-9-firewall — sign_open/3 always raises when signing key unset; resolved in Phase 9.
  {"lib/mailglass/tracking/token.ex", "Invalid type specification for function sign_open."},
  # Reason: Phase-9-firewall — sign_click/4 always raises when signing key unset; resolved in Phase 9.
  {"lib/mailglass/tracking/token.ex", "Invalid type specification for function sign_click."},
  # Reason: Phase-9-firewall — sign_open/3 no_return flows from unconfigured signing key; resolved in Phase 9.
  {"lib/mailglass/tracking/token.ex", "Function sign_open/3 has no local return."},
  # Reason: Phase-9-firewall — sign_click/4 no_return flows from unconfigured signing key; resolved in Phase 9.
  {"lib/mailglass/tracking/token.ex", "Function sign_click/4 has no local return."},
  # Reason: fail_step/2 raises intentionally to halt CI with a non-zero exit; no_return is by design.
  {"lib/mix/tasks/mailglass.publish.check.ex", "Function fail_step/2 only terminates with explicit exception."}
]
