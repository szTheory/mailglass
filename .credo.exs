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
     ]
   ]},
  {Mailglass.Credo.NoBareOptionalDepReference,
   [
     gated_modules: %{
       Oban => Mailglass.OptionalDeps.Oban,
       OpenTelemetry => Mailglass.OptionalDeps.OpenTelemetry,
       Mjml => Mailglass.OptionalDeps.Mjml,
       GenSmtp => Mailglass.OptionalDeps.GenSmtp,
       Sigra => Mailglass.OptionalDeps.Sigra
     }
   ]},
  {Mailglass.Credo.NoOversizedUseInjection, [max_lines: 20]},
  {Mailglass.Credo.PrefixedPubSubTopics, [required_prefix: "mailglass:"]},
  {Mailglass.Credo.NoDefaultModuleNameSingleton, []},
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
     allowed_modules: [Mailglass.Clock, Mailglass.Clock.System, Mailglass.Clock.Frozen]
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
        included: ["lib/", "test/"],
        excluded: []
      },
      requires: ["./lib/mailglass/credo/*.ex"],
      checks: extra_checks,
      extra_checks: extra_checks
    }
  ]
}
