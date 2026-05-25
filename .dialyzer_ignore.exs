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
  # Reason: invalid_adapter_entry!/2 raises NimbleOptions.ValidationError intentionally to surface adapter-config typos at boot; no_return is by design (matches resolve_from_path scope/2 pattern above).
  {"lib/mailglass/config.ex", "Function invalid_adapter_entry!/2 only terminates with explicit exception."},
  # Reason: BIMI.analyze/2 spec'd as analysis_result() (open map shape) for forward-compat; success typing collapses to a closed atom-set on findings/facts which would force every consumer to widen on the next BIMI status enum bump.
  {"lib/mailglass/deliverability/bimi.ex", "Type specification for analyze is a supertype of the success typing."},
  # Reason: GenSmtp.decode/2 spec widens the ok branch to {:ok, tuple()} on purpose — the :mimemail 5-tuple shape varies across gen_smtp versions and callers pattern-match the tuple themselves; dialyzer flags the generic tuple() as an extra range (same intentional-supertype pattern as the BIMI entry above).
  {"lib/mailglass/optional_deps/gen_smtp.ex", "The type specification has too many types for the function."}
]
