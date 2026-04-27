extra_checks = [
  {Mailglass.Credo.NoRawSwooshSendInLib,
   [
     allowed_modules: [Mailglass.Adapters.Swoosh]
   ]},
  {Mailglass.Credo.NoPiiInTelemetryMeta,
   [
     blocked_keys: ~w(to from cc bcc body html_body text_body subject headers recipient email)a
   ]},
  {Mailglass.Credo.NoUnscopedTenantQueryInLib,
   [
     tenanted_schemas: [
       Mailglass.Outbound.Delivery,
       Mailglass.Events.Event,
       Mailglass.Suppression.Entry,
       Mailglass.Webhook.WebhookEvent
     ],
     repo_functions: [:all, :one, :get, :get!, :get_by, :get_by!],
     unscoped_audit_helpers: [{Mailglass.Tenancy, :audit_unscoped_bypass}]
   ]},
  {Mailglass.Credo.NoBareOptionalDepReference,
   [
     gated_modules: %{
       Oban => Mailglass.OptionalDeps.Oban,
       OpenTelemetry => Mailglass.OptionalDeps.OpenTelemetry,
       Mjml => Mailglass.OptionalDeps.Mjml,
       GenSmtp => Mailglass.OptionalDeps.GenSmtp,
       Sigra => Mailglass.OptionalDeps.Sigra
     },
     included_path_prefixes: ["lib/mailglass/"]
   ]},
  {Mailglass.Credo.NoOversizedUseInjection, [max_lines: 20]},
  {Mailglass.Credo.PrefixedPubSubTopics, [required_prefix: "mailglass:"]},
  {Mailglass.Credo.NoDefaultModuleNameSingleton,
   [
     watched_modules: [GenServer, Agent, Registry, Supervisor]
   ]},
  {Mailglass.Credo.NoCompileEnvOutsideConfig,
   [
     allowed_modules: [Mailglass.Config]
   ]},
  {Mailglass.Credo.NoOtherAppEnvReads, [allowed_apps: [:mailglass]]},
  {Mailglass.Credo.TelemetryEventConvention, [required_root: :mailglass, min_segments: 4]},
  {Mailglass.Credo.NoFullResponseInLogs,
   [
     suspicious_fragments: ~w(response resp body payload)
   ]},
  {Mailglass.Credo.NoDirectDateTimeNow,
   [
     allowed_modules: [Mailglass.Clock, Mailglass.Clock.System, Mailglass.Clock.Frozen],
     included_path_prefixes: ["lib/mailglass/"]
   ]},
  {Mailglass.Credo.NoTrackingOnAuthStream,
   [
     auth_name_heuristics:
       ~w(magic_link password_reset verify_email confirm_account reset_token verification_token confirm_email two_factor 2fa)
   ]}
]

%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        # D-08-21: included stays ["lib/", "test/"]; do NOT add credo_checks/
        # (Credo would lint its own checks, producing false positives).
        included: ["lib/", "test/"],
        excluded: []
      },
      requires: ["./credo_checks/*.ex"],
      checks:
        extra_checks ++
          [
            # `Mailglass.Error.*` is the project's intentional error namespace
            # (see CLAUDE.md "Errors as a public API contract"). The default
            # ExceptionNames check picks the dominant `*Error` suffix and flags
            # `Mailglass.Error.BatchFailed` as inconsistent — false positive.
            # Reason: project uses Mailglass.Error.* namespace intentionally; ExceptionNames
            # flags it as inconsistent when it is consistent by design.
            # Tracking: permanent.
            {Credo.Check.Consistency.ExceptionNames, false},

            # Reason: stylistic; conflicts with deliberate `apply/3` use in adapter dispatch.
            # Tracking: permanent.
            {Credo.Check.Refactor.Apply, false},

            # Reason: macro-heavy library; `quote do` blocks in `Mailable`/`MailglassAdmin.Router`
            # are intentionally long for `use` injection.
            # Tracking: permanent.
            {Credo.Check.Refactor.LongQuoteBlocks, false},

            # Reason: low signal in a 33k-LOC codebase with mixed nesting depth.
            # Tracking: permanent (Oban posture).
            {Credo.Check.Readability.AliasOrder, false},

            # Reason: 102 findings, 99% in test files where nested-module-aliases are
            # deliberate scoping.
            # Tracking: permanent.
            {Credo.Check.Design.AliasUsage, false},

            # Reason: explicit `try`/`rescue` in `webhook/providers/sendgrid.ex` and
            # `webhook/plug.ex` documents the rescue-and-rewrap contract for
            # `Mailglass.SignatureError`.
            # Tracking: permanent (house style).
            {Credo.Check.Readability.PreferImplicitTry, false},

            # Reason: nesting depth exceeds Credo's default in webhook/ingest.ex,
            # suppression_store/ets.ex, tracking/rewriter.ex, tracking/token.ex,
            # webhook/reconciler.ex, events/reconciler.ex, and outbound.ex — all
            # structurally justified by the multi-step pipeline and error-propagation
            # patterns. In-scope refactors (installer/apply.ex, postmark.ex) have
            # been fixed; remaining sites are Phase-9-stable or lower-risk.
            # Tracking: revisit after Phase 9 API redesign; reduce to 0 suppressions.
            {Credo.Check.Refactor.Nesting, false},

            # Reason: cyclomatic complexity exceeds 9 in webhook/ingest.ex and
            # publish.check.ex — both have intentionally broad branching for
            # provider event-type dispatch and tarball validation respectively.
            # In-scope files (installer/apply.ex, postmark.ex) have been refactored.
            # Tracking: revisit after Phase 9; extract provider dispatch to reduce score.
            {Credo.Check.Refactor.CyclomaticComplexity, false},

            # Reason: single-condition `cond do` used deliberately in
            # installer/apply.ex, events/reconciler.ex, and mailer_case.ex for
            # future-extensibility (additional conditions expected in follow-on plans).
            # Tracking: revisit at v0.3 cleanup phase.
            {Credo.Check.Refactor.CondStatements, false},

            # Reason: TODO tags in test files are intentional Phase-8 REL-07 reminders
            # for installer idempotency work; they are tracked in .planning/ todos and
            # will be resolved in the follow-on cleanup plan.
            # Tracking: remove after REL-07 todos are resolved.
            {Credo.Check.Design.TagTODO, false},

            # Reason: large integers in webhook_fixtures.ex are OID tuples (e.g.
            # secp256r1 OID {1, 2, 840, 10045, 3, 1, 7}) — underscores would
            # misrepresent the structure and hurt readability for this domain literal.
            # Tracking: permanent (OID values are domain constants, not human numbers).
            {Credo.Check.Readability.LargeNumbers, false},

            # Reason: `Enum.map/2 |> Enum.join/2` is used in publish.check.ex and
            # install.ex where readability of the intermediate step is more important
            # than micro-optimisation; these are CLI tools, not hot paths.
            # Tracking: revisit at v0.3 cleanup phase; convert if performance evidence found.
            {Credo.Check.Refactor.MapJoin, false},

            # Reason: `if not condition do` is used in worker_test.exs for optional-dep
            # guard clauses (Code.ensure_loaded?) where the positive form would require
            # an extra level of nesting or an unless that obscures the skip intent.
            # Tracking: permanent (test-file guard pattern for optional deps).
            {Credo.Check.Refactor.NegatedConditionsWithElse, false}
          ],
      extra_checks: extra_checks
    }
  ]
}
