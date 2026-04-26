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
      # `strict: true` would fail the build on ~169 lower-priority software
      # design / readability / refactoring suggestions that pre-date Phase
      # 07.1 — out of scope for v0.1.0. Custom Credo checks (12 in
      # credo_checks/) remain mandatory at default priority. Re-enable
      # strict in a post-publish cleanup phase.
      strict: false,
      files: %{
        included: ["lib/", "test/"],
        excluded: []
      },
      requires: ["./credo_checks/*.ex"],
      # `Mailglass.Error.*` is the project's intentional error namespace
      # (see CLAUDE.md "Errors as a public API contract"). The default
      # ExceptionNames check picks the dominant `*Error` suffix and flags
      # `Mailglass.Error.BatchFailed` as inconsistent — false positive.
      checks: extra_checks ++ [{Credo.Check.Consistency.ExceptionNames, false}],
      extra_checks: extra_checks
    }
  ]
}
