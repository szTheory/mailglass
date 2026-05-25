# Phase 50: Inbound Documentation Pass — Context

**Gathered:** 2026-05-25 (artifact review of Phases 45-49 shipped surfaces)
**Status:** Ready for planning

<domain>
## Phase Boundary

An adopter coming to `mailglass_inbound` for the first time can read a canonical
documentation set and have the package running in production with confidence. Six
documents, one docs-check extension, one mix.exs update (IDOC-01..06, MGUN-05, SESI-06):

1. **`mailglass_inbound/docs/inbound-install.md`** (IDOC-01) — install guide: deps,
   repo config, router macro setup, first mailbox, first ingress endpoint, sandboxed test
2. **`mailglass_inbound/docs/inbound-testing.md`** (IDOC-02) — testing guide:
   MailboxCase, TestAssertions (4 matcher styles + outcome + routing assertions),
   Test.Ingress, Fixtures, idempotency property pattern
3. **`mailglass_inbound/docs/inbound-operator.md`** (IDOC-03) — operator guide:
   `inbound.doctor`, `inbound.replay`, `inbound.prune`, retention config, rate-limit
   config, suppression flag interpretation, Oban cron wiring
4. **`mailglass_inbound/docs/inbound-mailgun.md`** (MGUN-05) — Mailgun setup: HTTP
   route URL, API signing key config, signing key rotation, HMAC verification explanation
5. **`mailglass_inbound/docs/inbound-ses.md`** (SESI-06) — SES setup: SNS topic,
   IAM policy template, S3 bucket, `:ex_aws_s3` install, SubscribeURL trust policy,
   S3 consistency race mitigation, KMS limitation
6. **`mailglass_inbound/docs/inbound-routing-debug.md`** (IDOC-05) — routing debug:
   InboundLive routing-trace card workflow, common matcher failure modes, CLI
   inspection patterns, one fully-narrated trace example
7. **`mix mailglass.docs.check` extension** (IDOC-06) — add all 6 new docs to
   `@tier1_paths` + `@tier1_surface_rules`; update `mailglass_inbound/mix.exs` docs config;
   update `test/mailglass/docs_contract_test.exs`

**Out of scope:** code changes to inbound package (all shipped by Phases 45-49);
the v1.2 release ceremony (Phase 50.5); new provider support (future milestone).

**Architectural anchor:** all docs live under `mailglass_inbound/docs/`. The
`mix mailglass.docs.check` task reads from repo root using relative paths
(`"mailglass_inbound/docs/..."`) — consistent with existing inbound doc paths.
</domain>

<decisions>
## Key Facts for Plans

### Package Version
`mailglass_inbound` will ship at **0.2.0** in Phase 50.5 (inbound stays on 0.x
version line until Conductor + relay providers land). Install guides use
`{:mailglass_inbound, "~> 0.2"}` — NOT `~> 1.2` (that was a ROADMAP.md shorthand
for the v1.2 *milestone*, not the inbound package version).

### Config Keys (verified from source)
**Mailgun:**
```elixir
config :mailglass_inbound, :mailgun,
  signing_key: "YOUR_MAILGUN_SIGNING_KEY",
  timestamp_tolerance_seconds: 300,    # optional, default 300
  future_skew_seconds: 60,             # optional, default 60
  replay_cache_ttl_seconds: 28_800     # optional, default 8h
```

**SES:**
```elixir
config :mailglass_inbound, :ses,
  s3_fetcher: MailglassInbound.S3Fetcher.ExAwsS3,  # default is Fake (test only)
  cert_cache_ttl_seconds: 3600,                    # optional
  s3_retry_opts: [attempts: 3, base_sleep_ms: 250] # optional
```
TrustPolicy is hardcoded to `sns.*.amazonaws.com` — no adopter config needed.

**Retention + Rate-limit:**
```elixir
config :mailglass_inbound,
  retention: [
    records_days: 90,
    evidence_days: 90,
    execution_runs_days: 90,
    replay_runs_days: 30
  ],
  rate_limit: [
    tenant:        [capacity: 1000, per_minute: 1000],
    sender_domain: [capacity: 200,  per_minute: 200],
    recipient:     [capacity: 500,  per_minute: 500]
  ]
```

### Key Interface Facts (verified from source)
- **Ingress.Plug provider allowlist:** `:postmark`, `:sendgrid`, `:mailgun`, `:ses`
- **CachingBodyReader wiring** is REQUIRED on all inbound endpoints (the plug reads
  `conn.private[:raw_body]`)
- **MailboxCase must be `async: false`** (ETS sandbox, snapshot/restore of
  `:async_execution_impl` config)
- **replay --tenant is REQUIRED** (cross-tenant replay guard T-49-17; every record
  is loaded scoped to that tenant)
- **prune uses typed "yes" confirmation** (stronger than replay's `[y/N]` because it
  DELETES rows; `--yes` skips for cron/CI)
- **doctor exit codes:** 0 (all pass), 1 (failure/warn-under-strict), 2 (cannot diagnose)
- **TrustPolicy:** SubscribeURL validated against hardcoded `^sns\.[a-zA-Z0-9-]{3,}\.amazonaws\.com(\.cn)?$`
  pattern — no adopter-side allowlist config
- **SES KMS:** client-side KMS-encrypted S3 objects are NOT decrypted; use bucket-level
  SSE instead
- **Mailgun two modes:** `body-mime` field presence → raw-MIME mode; absent → parsed mode
- **Oban cron worker:** `MailglassInbound.Prune.Worker` exists but is NOT auto-registered;
  adopter wires `{MailglassInbound.Prune.Worker, cron: "0 3 * * *"}` in their Oban config

### docs.check Extension (IDOC-06)
The `mix mailglass.docs.check` task (at `lib/mix/tasks/mailglass.docs.check.ex`)
has two enforcement surfaces:
1. **@tier1_paths** — paths to check for banned internal IDs (`D-XX`, `LINT-XX`)
2. **@tier1_surface_rules** — per-path `required:` tokens and `forbidden:` tokens

All 6 new docs must be added to both. The test contract
(`test/mailglass/docs_contract_test.exs`) has tier1 surface assertions — extend with
a `describe "inbound doc contracts"` block. The `mailglass_inbound/mix.exs` `docs()`
function must reference all 6 new files in `extras:` and `groups_for_extras:`.

### Brand Voice Constraints
- No `D-XX`, `LINT-XX`, `T-49-XX`, plan ID references in doc content
- Error messages: specific not generic ("Configuration error: no signing_key for :mailgun")
- Voice: clear, exact, confident, warm, technical — never "Oops!", never "experience the
  full rendering lifecycle"
- Docs are for adopters, not for GSD plan readers
</decisions>

<wave_plan>
## Wave Plan

**Wave 1** (2 plans, parallel):
- **50-01**: Install guide (IDOC-01) + Testing guide (IDOC-02) + Operator guide (IDOC-03)
- **50-02**: Mailgun guide (MGUN-05) + SES guide (SESI-06)

**Wave 2** (1 plan, blocked on Wave 1 completion):
- **50-03**: Routing-debug guide (IDOC-05) + docs.check extension (IDOC-06) + mix.exs
  update + docs_contract_test

Routing-debug waits for Wave 1 so cross-references to the install/operator guides can
be accurate. docs.check waits for all docs to be written before adding them to the tier1
list (minimizes churn from docs that don't exist yet).
</wave_plan>
