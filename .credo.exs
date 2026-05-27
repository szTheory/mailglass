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
     # Each optional-dep root maps to its sanctioned gateway module(s). The
     # inbound sibling package keeps its own gateway surface
     # (MailglassInbound.OptionalDeps.*) rather than reusing the core gateways
     # across the package boundary, so those gateways are listed as additional
     # allowed call sites for the deps inbound integrates (Oban; GenSmtp lands
     # with Plan 03's MIME parser gateway).
     #
     # gen_smtp is an Erlang library with NO `GenSmtp` Elixir module: its surface
     # is reached only via the Erlang call-site atoms `:mimemail` (the MIME
     # parser) and `:gen_smtp_client` (the SMTP client) — see the
     # `Mailglass.OptionalDeps.GenSmtp` gateway moduledoc. The check resolves a
     # bare `:mimemail.decode(...)` call to the root atom `:mimemail`, so the map
     # MUST be keyed on those atoms for the guard to fire — CR-01 coverage rides
     # ENTIRELY on the `:mimemail` / `:gen_smtp_client` atom keys.
     #
     # WR-04 correction: Credo does NOT resolve aliases. Inbound `mime.ex` uses
     # `alias Mailglass.OptionalDeps.GenSmtp, as: OptionalGenSmtp` and calls
     # `OptionalGenSmtp.decode/2`; Credo sees the literal call root
     # `OptionalGenSmtp`, NOT the underlying `GenSmtp` alias target. That call
     # passes the guard simply because `OptionalGenSmtp` is not a key in
     # `gated_modules` — never because the alias is followed back to a `GenSmtp`
     # key. The vestigial `GenSmtp` key below would only ever match a *literal*
     # `GenSmtp.<fn>` call, which no Elixir code makes (the dep is the Erlang
     # `:gen_smtp`). It is retained as documentation of the gateway alias name,
     # but it carries no live CR-01 coverage.
     gated_modules: %{
       Oban => [Mailglass.OptionalDeps.Oban, MailglassInbound.OptionalDeps.Oban],
       OpenTelemetry => Mailglass.OptionalDeps.OpenTelemetry,
       Mjml => Mailglass.OptionalDeps.Mjml,
       GenSmtp => [Mailglass.OptionalDeps.GenSmtp, MailglassInbound.OptionalDeps.GenSmtp],
       :mimemail => Mailglass.OptionalDeps.GenSmtp,
       :gen_smtp_client => Mailglass.OptionalDeps.GenSmtp,
       # ex_aws/ex_aws_s3 (Phase 46, D-46-14): SES inbound's real S3 fetcher
       # routes all ExAws access through the inbound-local
       # MailglassInbound.OptionalDeps.ExAwsS3 gateway. Both the root `ExAws`
       # (for `ExAws.request/1`) and `ExAws.S3` (for `get_object/2`) are keyed so
       # NoBareOptionalDepReference flags any stray reference outside the gateway.
       # included_path_prefixes already covers "mailglass_inbound/lib/".
       ExAws => MailglassInbound.OptionalDeps.ExAwsS3,
       ExAws.S3 => MailglassInbound.OptionalDeps.ExAwsS3,
       Sigra => Mailglass.OptionalDeps.Sigra
     },
     # Inbound code routes `:mimemail` (gen_smtp) through a gateway only; this
     # prefix makes the check flag any bare reference in inbound code outside the
     # gateway (Plan 03 depends on this guard).
     included_path_prefixes: ["lib/mailglass/", "mailglass_inbound/lib/"]
   ]},
  {Mailglass.Credo.MultiEventFirstInWebhookIngest, []},
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
  {Mailglass.Credo.TelemetryEventConvention,
   [required_root: [:mailglass, :mailglass_inbound], min_segments: 4]},
  {Mailglass.Credo.NoFullResponseInLogs,
   [
     suspicious_fragments: ~w(response resp body payload)
   ]},
  {Mailglass.Credo.NoPlanningArtifactComments,
   [
     included_path_prefixes: ["lib/mailglass/", "mailglass_admin/lib/", "mailglass_inbound/lib/"],
     allowed_literals: []
   ]},
  # Egress PII guard for HTTP response bodies (TELE-06). NoFullResponseInLogs
  # covers logs and NoPiiInTelemetryMeta covers telemetry, but neither inspects
  # response-body sinks — that gap let `inspect(reason)` (a changeset carrying
  # recipient PII) reach the provider on a persist failure. This check flags
  # inspect/changeset/bare-error payloads inside send_resp/send_json/put_resp_body
  # call heads, scoped to the only surfaces that build provider response bodies:
  # the core webhook plug and the inbound ingress plug.
  {Mailglass.Credo.NoPiiInResponseBody,
   [
     included_path_prefixes: [
       "lib/mailglass/webhook/",
       "mailglass_inbound/lib/mailglass_inbound/ingress/"
     ]
   ]},
  {Mailglass.Credo.NoDirectDateTimeNow,
   [
     allowed_modules: [Mailglass.Clock, Mailglass.Clock.System, Mailglass.Clock.Frozen],
     # Reason: NoDirectDateTimeNow stays scoped to core only this phase. The
     # `mailglass_inbound` sibling package deliberately does not depend on the
     # core `Mailglass.Clock` seam (it has no clock-injection surface of its
     # own yet), and routing inbound's five `DateTime.utc_now/0` sites — several
     # of which stamp replay-lineage `executed_at`/`received_at` timestamps —
     # through the core Clock is a runtime refactor outside this Wave-0 lint/infra
     # plan's scope. The D-45 `.credo.exs` path-scope widening intentionally does
     # NOT extend this check to inbound; an inbound clock seam is a future-phase
     # decision. (Plan allowance: document non-applicability rather than widen.)
     # Tracking: revisit if inbound gains a clock-injection seam.
     included_path_prefixes: ["lib/mailglass/"]
   ]},
  {Mailglass.Credo.RequireAtomicUnsubscribeHeaders, []},
  {Mailglass.Credo.NoTrackingOnAuthStream,
   [
     auth_name_heuristics:
       ~w(magic_link password_reset verify_email confirm_account reset_token verification_token confirm_email two_factor 2fa)
   ]},
  # Open/click tracking is opt-in per mailable and demands an explicit
  # `:bulk`/`:operational` stream — a tracking-enabled mailable left on the
  # default/`:transactional` stream is a policy violation (CLAUDE.md
  # open/click-tracking discipline). Registered here so it actually runs under
  # `mix credo`; the checks_have_tests meta-test fails CI if any
  # credo_checks/*.ex is defined but left unregistered like this one was.
  #
  # Path-scoped to production mailables (same pattern as NoDirectDateTimeNow /
  # NoPiiInResponseBody / NoBareOptionalDepReference): test fixtures in
  # core_send_integration_test.exs deliberately declare `tracking` on a
  # `:transactional` stream to exercise the *runtime* auth-stream guard
  # (`UATAuthMailer` asserts the ConfigError; `TrackingOnMailer` asserts pixel
  # injection). Those are intentional bad-config shapes, so linting test files
  # would be a false positive that breaks `mix credo --strict` (exit 16).
  {Mailglass.Credo.StreamPolicyConsistent,
   [included_path_prefixes: ["lib/mailglass/", "mailglass_inbound/lib/"]]}
]

%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        # D-08-21: do NOT add credo_checks/ (Credo would lint its own checks,
        # producing false positives). Widened in D-45 Wave 0 to cover the
        # mailglass_inbound sibling package so TELE-06's PII check, the bare
        # optional-dep check, and the full --strict ruleset actually lint it
        # (silent non-coverage was the prior failure mode — RESEARCH Pitfall 1).
        included: ["lib/", "test/", "mailglass_inbound/lib/", "mailglass_inbound/test/"],
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
