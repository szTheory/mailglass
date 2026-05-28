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
  # Reason: GenSmtp.decode/2 spec widens the ok branch to {:ok, tuple()} on purpose — the :mimemail 5-tuple shape varies across gen_smtp versions and callers pattern-match the tuple themselves; with :underspecs dialyzer flags {:ok, tuple()} as an extra range (same intentional-supertype pattern as the BIMI entry above).
  {"lib/mailglass/optional_deps/gen_smtp.ex", "@spec for decode has more types than are returned by the function."},
  # Reason: OperatorDiagnosisProof.run/0 returns a deterministic evidence map; map() is intentionally broad for forward-compat as evidence keys evolve (reference-host proof, Phase 57/58). v1.4 green-main may narrow it.
  {"lib/mailglass/reference_host/operator_diagnosis_proof.ex", "Type specification for run is a supertype of the success typing."},
  # Reason: MailglassAdmin.OptionalDeps.MailglassInbound.explain_routes/2 is an optional-dep call resolved at runtime via Code.prepend_path; dialyzer cannot see the soft-loaded sibling module.
  {"lib/mailglass/reference_host/operator_diagnosis_proof.ex", "Function MailglassAdmin.OptionalDeps.MailglassInbound.explain_routes/2 does not exist."},
  # Reason: MailglassAdmin.Components.mask_recipient/1 is an optional-dep (mailglass_admin) call resolved at runtime; dialyzer cannot see the soft-loaded sibling module.
  {"lib/mailglass/reference_host/operator_diagnosis_proof.ex", "Function MailglassAdmin.Components.mask_recipient/1 does not exist."},
  # Reason: WebhookOperatorProof.run/0 returns the proof struct; %__MODULE__{} is intentionally broad over the field success-typing (reference-host proof, Phase 57/58). v1.4 green-main may narrow it.
  {"lib/mailglass/reference_host/webhook_operator_proof.ex", "Type specification for run is a supertype of the success typing."},
  # Reason: MailglassReferenceHostWeb.Router.call/2 is a reference-host router loaded at runtime via Code.require_file; dialyzer cannot see the soft-loaded module.
  {"lib/mailglass/reference_host/webhook_operator_proof.ex", "Function MailglassReferenceHostWeb.Router.call/2 does not exist."},
  # Reason: TrustRunnerFixtures.webhook_ingest_evidence/0 returns a deterministic evidence map; map() is intentionally broad for forward-compat (test-support fixture, Phase 57).
  {"test/support/reference_host/trust_runner_fixtures.ex", "Type specification for webhook_ingest_evidence is a supertype of the success typing."}
]
