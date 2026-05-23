**Plans**: 9 plans (4 functional + 5 gap-closure; gap-closure runs in 3 waves)

- [x] 45-01-PLAN.md — Wave 0: inbound test DB infra (MailglassInbound.TestRepo + config/test.exs + migration-running test_helper + Postgres CI job) + cross-package Credo coverage (.credo.exs widen, TelemetryEventConvention root) + gen_smtp optional dep [TELE-06]
- [x] 45-02-PLAN.md — Wave 1: MailglassInbound.Telemetry single span surface + 4 fixed span wraps (ingress/route/persist/execution) + per-tenant PubSub topic builder + post-commit broadcast [TELE-01..05, TELE-07]
- [x] 45-03-PLAN.md — Wave 1 (parallel): standalone MailglassInbound.MIME never-raise parser + extended GenSmtp decode/2 seam + package-local MailglassInbound.MIMEError [MIME-01, MIME-02, MIME-04]
- [x] 45-04-PLAN.md — Wave 2: StreamData 1000-replay convergence property through the real persist+execute write path (one InboundRecord + one fresh ExecutionRun per unique payload) [TELE-08]
- [ ] 45-05-PLAN.md — Gap Wave 1: Credo-check correctness — fix CR-01 (gated_modules keyed on `:mimemail`/`:gen_smtp_client` + Erlang-atom regression test with explicit params + default-params negative control) and WR-02 (TelemetryEventConvention `:telemetry.span/3` clause + fixtures run with the configured inbound root) [MIME-02, TELE-06]
- [ ] 45-06-PLAN.md — Gap Wave 1 (parallel): inbound `--no-optional-deps` lane — add `Mailglass.Oban.TenancyMiddleware` to inbound `no_warn_undefined` (WR-03 fix) + dedicated `inbound_compile_no_optional_deps` CI job (compile-only, SHA-pinned) [MIME-02]
- [ ] 45-07-PLAN.md — Gap Wave 2: PII-safe ingress error path — static `persist_failed` 500 body + `classify_persist_error/1` (PII-free `error_kind` in stop-meta, status stays 500) + new `NoPiiInResponseBody` egress Credo check + its test [TELE-06]
- [ ] 45-08-PLAN.md — Gap Wave 1 (parallel): doc honesty — mime.ex max_depth-guard admonition + contract bullet fix + mime_test describe rename + gen_smtp.ex `:undef`-under-rescue correction (doc/test-only) [MIME-01, MIME-04]
- [ ] 45-09-PLAN.md — Gap Wave 3: recurrence backstops + pre-existing-check coverage — positive/negative regression tests for the two uncovered checks (RequireAtomicUnsubscribeHeaders, StreamPolicyConsistent) + check-coverage meta-test (zero exclusions) + `.credo.exs` config sentinel pinning the CR-01/WR-02 keys [MIME-02, TELE-06]

**UI hint**: no

**Hardest sub-tasks:**
