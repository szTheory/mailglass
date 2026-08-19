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
  # MIGR-06: mailglass injects the Postgres schema prefix at RUNTIME via the
  # facade (Config.schema/0). A compile-time `@schema` `@prefix` module attribute
  # pins the read side to a baked-in schema and inverts read-vs-write prefix
  # precedence (decision 6). This check fails the build on any such attribute
  # under lib/mailglass/.
  {Mailglass.Credo.NoSchemaPrefixAttribute, []},
  {Mailglass.Credo.RawRepoPrefixContract,
   [
     schema_modules: [
       Mailglass.Outbound.Delivery,
       Mailglass.Events.Event,
       Mailglass.Suppression.Entry,
       Mailglass.Webhook.WebhookEvent,
       MailglassInbound.InboundRecords.InboundRecord,
       MailglassInbound.InboundRecords.InboundEvidence,
       MailglassInbound.InboundRecords.ExecutionRun,
       MailglassInbound.InboundRecords.ReplayRun
     ],
     included_path_prefixes: ["lib/mailglass/", "mailglass_inbound/lib/"]
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
   [included_path_prefixes: ["lib/mailglass/", "mailglass_inbound/lib/"]]},
  # HARNESS-01 (plan 143-08): the prevention half of the two-layer recurrence
  # guard for the Sandbox ownership acquire/release leak. Forbids raw
  # Ecto.Adapters.SQL.Sandbox ownership calls under test/, outside the two
  # allowlisted modules (the sanctioned door and its own mechanism test).
  {Mailglass.Credo.NoRawSandboxOwnership, []},
  # HARNESS-01 / D-31 Class A (143 gap closure): the prevention half of the
  # two-layer recurrence guard for the `search_path` pool-poisoning defect. A
  # session-level `SET search_path` issued under Sandbox `:auto` mode persists on
  # the pooled Postgres connection for its whole lifetime, so the connection
  # returns to the pool poisoned and some later, unrelated test fails with 42P01
  # — the innocent-victim misattribution that cost two diagnosis cycles. The
  # detection half (`SandboxOwnership.with_search_path!/3`'s verified restore)
  # shipped without prevention, which is exactly how the class recurred.
  #
  # ALLOWLIST — three module entries, each structural, none a "this file is
  # inconvenient" exemption. Every entry is safe because of WHAT the module is,
  # not because of what it happens to contain today:
  #   * Mailglass.TestSupport.SandboxOwnership — the sanctioned seam itself. It
  #     is the only place that may issue the raw statement, because it is the
  #     only place that pins ONE pooled connection for the whole block, restores
  #     the prior value on that same connection, and RE-READS it to verify the
  #     restore landed. Exempting it is what makes every other exemption
  #     unnecessary: legitimate needs route through it instead of being
  #     allowlisted.
  #   * Mailglass.TestSupport.SandboxOwnershipTest — the seam's own mechanism
  #     test. It must drive real `SET`/`SHOW search_path` statements against the
  #     live pool to prove the restore-verification raise path actually fires;
  #     a mechanism test that cannot contain its own mechanism proves nothing.
  #     Same allowlist rationale (and same module) as NoRawSandboxOwnership.
  #   * Mailglass.Credo.NoRawSearchPathMutationTest — this check's own fixture
  #     corpus. Its positive cases must spell the banned statements verbatim
  #     (including the multi-statement `...; SET search_path ...` evasion the
  #     semicolon branch exists to catch), and there is no way to write that
  #     fixture without a statement-initial literal. The alternative — splitting
  #     the literal to dodge the check — is strictly worse: it teaches exactly
  #     the evasion this guard exists to prevent. Zero risk: the module is a
  #     pure `async: true` Credo unit test that opens no database connection.
  # Assertion match targets (`body =~ "SET search_path = ''"`) need NO allowlist
  # entry: the check exempts them positionally via :match_target_functions,
  # because a compared literal is never an executed statement. That positional
  # carve-out is why `upgrade_v2_schema_generation_test.exs` needed no migration
  # and no exemption.
  {Mailglass.Credo.NoRawSearchPathMutation, []},
  # D-31 Class D (143 gap closure): the prevention half of the recurrence guard
  # for the Application-env restore defect. `Application.put_all_env/1` MERGES,
  # so it can never remove a key a test ADDED — seven test modules used it as
  # their "restore" and all seven leaked `config :mailglass, :compliance` (in no
  # `config/*.exs`) into every later module, plus, on the runs where the key
  # ordering lined up, a tenancy resolver whose `scope/2` applies `as: :scoped`.
  # That leak failed the mailglass gating leg of CI run 30571989203 on a
  # DOCS-ONLY commit and was green two commits later with `lib/` byte-identical.
  #
  # ALLOWLIST — two entries, both structural, neither an inconvenience
  # exemption, and the same pair (and the same reasoning) as
  # NoRawSandboxOwnership's:
  #   * Mailglass.TestSupport.SandboxOwnership — the sanctioned seam. It is
  #     allowlisted for its @doc, which must quote the banned idiom verbatim to
  #     explain what it replaces; the seam's own restore uses `put_env/3` +
  #     `delete_env/2` and never calls `put_all_env/1` at all.
  #   * Mailglass.TestSupport.SandboxOwnershipTest — the seam's mechanism test.
  #     Its non-vacuity proof reinstates the real merging idiom and asserts the
  #     leak reappears; a mechanism test that cannot contain its own mechanism
  #     proves nothing.
  #
  # Scope covers `mailglass_inbound/test/` too, even though that tree has ZERO
  # instances today (its restores already use the presence-aware
  # `fetch_env` / `nil -> delete_env` idiom, audited site by site). Linting a
  # clean tree costs nothing and stops the idiom arriving there by copy-paste.
  {Mailglass.Credo.NoRawAppEnvRestore, []}
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

            # The default thresholds remain the debt-discovery thresholds in
            # config/quality/credo_ratchet.exs.  The ordinary Credo run uses
            # the measured repository maxima so acknowledged debt does not
            # hide unrelated findings; scripts/check_static_analysis_exceptions.exs
            # enforces the tighter, per-function no-growth ledger.
            {Credo.Check.Refactor.Nesting, [max_nesting: 5]},
            {Credo.Check.Refactor.CyclomaticComplexity, [max_complexity: 17]},

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
