# Milestone Candidate: Inbound Developer Experience (mailglass_inbound v1.2)

## Verdict

**Ship.** The inbound package shipped its core pipeline (ingress → persist → route → execute) in v1.1 with `MailglassInbound.Mailbox`, `Router.Matcher`, `Execution.Worker`, but adopters get *zero* DX surface — no test assertions, no fixtures, no fake provider, no generators, no case template. Outbound has `Mailglass.TestAssertions` (lib/mailglass/test_assertions.ex), `Mailglass.MailerCase`, `Mailglass.Adapters.Fake`, three `mix mailglass.gen.*` tasks. This milestone closes the parity gap and makes adopting `mailglass_inbound` writeable in tests rather than "stub everything yourself." Defer: a separate inbound LiveView admin (separate candidate 02).

## Concrete API: `MailglassInbound.TestAssertions`

Mirror outbound 4-style matcher (test_assertions.ex:86-119). Mailbox outcomes are locked to `:accept | :ignore | {:reject, _} | {:bounce, _}` (mailbox.ex:22) — assertions key off those.

```elixir
# Style 1-4 mirroring outbound (presence / keyword / map pattern / predicate fn)
defmacro assert_inbound_received()                     # :: any inbound message dispatched
defmacro assert_inbound_received(keyword | map | fn)   # match on InboundMessage fields
defmacro assert_no_inbound_received()                  # refute_received {:inbound, _}

# Outcome-keyed assertions (one per locked outcome from mailbox.ex)
@spec assert_inbound_accepted(InboundMessage.t() | keyword(), timeout()) :: :ok
@spec assert_inbound_ignored (InboundMessage.t() | keyword(), timeout()) :: :ok
@spec assert_inbound_rejected(reason :: term() | nil, timeout()) :: :ok
@spec assert_inbound_bounced (reason :: term() | nil, timeout()) :: :ok

# Routing assertions — verify the router selected the expected mailbox BEFORE execution
@spec assert_inbound_routed_to(mailbox :: module(), timeout()) :: :ok
@spec assert_inbound_no_match(timeout()) :: :ok           # routes to nothing — record execution_run with mailbox_outcome: :no_match

# Inspection (mirror last_mail/0 from test_assertions.ex:173)
@spec last_inbound() :: InboundMessage.t() | nil
@spec inbound_executions(keyword()) :: [%ExecutionRun{}]   # filter by :tenant, :mailbox, :outcome
```

Supported keyword keys (mirror test_assertions.ex:122-159): `:from`, `:to`, `:subject`, `:envelope_recipient`, `:tenant`, `:provider`, `:mailbox`. Reject unsupported keys with `flunk/1` listing supported set — same pattern as outbound.

Failure messages embed caller-supplied values (not telemetry). Same PII rationale as outbound (test_assertions.ex:47-52).

## Fake Adapter / Fixture Strategy

Two-layer design — match ActionMailbox's `create_*` vs `receive_*` distinction (TestHelper.rb).

**Layer 1 — `MailglassInbound.Test.Fixtures`** (build, don't dispatch):
```elixir
@spec build_inbound_message(keyword()) :: InboundMessage.t()      # in-memory struct, no DB
@spec build_inbound_record(keyword()) :: {:ok, %InboundRecord{}}  # persisted, no execution
@spec build_postmark_payload(keyword()) :: map()                  # raw Postmark JSON
@spec build_sendgrid_payload(keyword()) :: %Plug.Upload{} | map() # raw SendGrid multipart
```

**Layer 2 — `MailglassInbound.Test.Ingress`** (mirror outbound `Fake.trigger_event/3` at execution.ex:266 — drives the REAL persist+route+execute path):
```elixir
@spec receive_inbound(InboundMessage.t() | keyword(), keyword()) :: {:ok, map()}
# Routes through Ingress.Persist → Router.Matcher → Execution.execute (synchronous, like Inline async adapter).
# Returns {:ok, %{record: ..., evidence: ..., execution: ...}}.

@spec receive_provider_payload(:postmark | :sendgrid, map(), keyword()) :: {:ok, map()}
# Dispatches through Ingress.Plug to exercise provider normalization + signature paths.
# Use Fixtures.build_*_payload/1 to construct.
```

**No new "Fake provider" needed.** The outbound Fake adapter exists because Swoosh's `deliver/1` is the seam — there's no equivalent seam in inbound (the seam is the Plug). Instead: `Test.Ingress` is the gate-keeping helper that exercises the production write path end-to-end. The release-blocking property: every PR's CI runs the full inbound pipeline through these helpers. This mirrors D-13's Fake-as-release-gate spirit without duplicating the Plug.

## Per-Mailbox Case Template: `MailglassInbound.MailboxCase`

Mirror mailer_case.ex structure (Sandbox start_owner!, tenancy stamp, frozen clock, PubSub subscribe). Key differences:

- Set `:async_execution_impl` to `Inline` (analog to `:async_adapter_impl` at mailer_case.ex:131) so `Execution.dispatch/2` runs synchronously — needed because async tests can't share Oban/Task.Supervisor connection state without the v0.2 sandbox-ownership bug pattern reappearing.
- Default tenant `"test-tenant"`, `@tag tenant: :unset`, `@tag frozen_at:`, `@tag oban: :manual` — same surface.
- `setup_mailglass_inbound_global/1` for cross-process (same I-12 raise rule: `oban` tagged → `async: false` enforced).
- Subscribe to inbound PubSub topic for `assert_inbound_executed/2` PubSub-backed assertions (analog to `assert_mail_delivered/2` at test_assertions.ex:230).

## Generators (Igniter-based, mirror gen.mailable.ex pattern)

```
mix mailglass.gen.mailbox MyApp.Inbound.Support
  → lib/my_app/inbound/support.ex (use MailglassInbound.Mailbox, process/1 stub returning :ignore)
  → test/my_app/inbound/support_test.exs (uses MailglassInbound.MailboxCase, sample assert_inbound_accepted)

mix mailglass.gen.inbound_router MyAppWeb.Inbound.Router
  → lib/my_app_web/inbound/router.ex (use MailglassInbound.Router, sample route block)

mix mailglass.gen.inbound_route MyAppWeb.Inbound.Router MyApp.Inbound.Support --recipient support@
  → patches the named router with a new route/2 entry (Igniter source-edit, NOT regeneration)
```

All three use `Igniter.Mix.Task` like gen.mailable.ex:11. No fixture-file generator — adopters use `build_postmark_payload/1` in test setup instead (avoids file-bytes-on-disk PII risk, see Anti-patterns).

## Property Test Surfaces (StreamData)

1. **Router matcher correctness** (router/matcher.ex:8) — generate ordered route lists + InboundMessages, prove first-match-wins, header AND-semantics, regex/exact equivalence.
2. **Provider normalization round-trip** — generate Postmark/SendGrid payloads → assert canonical InboundMessage shape stable (no field loss).
3. **Idempotent ingest convergence** — replay 1000× same payload through `Test.Ingress.receive_provider_payload/2`, assert exactly one InboundRecord (mirrors outbound's 1000-replay test from v0.1).
4. **Outcome closure** — generate arbitrary process/1 return values, assert `Mailbox.valid_outcome?/1` (mailbox.ex:27) is the closed-set decider.
5. **Tenant scoping** — generate (tenant, mailbox) pairs, assert no cross-tenant leak through `inbound_executions(tenant: t)`.

## Anti-Patterns to Avoid

- **No real email addresses in fixture builders.** Default to `"user-#{:rand.uniform(99_999)}@example.test"` — mirror outbound's no-PII-in-telemetry rule extended to fixtures.
- **No tenant-id default at the helper level past test boundary.** `MailboxCase` stamps `"test-tenant"` only inside the test process; assertions that filter `inbound_executions/1` MUST require explicit tenant or honor `Mailglass.Tenancy.current/0`.
- **Don't rebroadcast `set_mailglass_global` race fix.** mailer_case.ex:120-204 has HI-01 snapshot/restore for `:async_adapter_impl`. The inbound MailboxCase MUST adopt the identical snapshot pattern for `:async_execution_impl` — a copy-paste of the bug is the predictable failure mode.
- **Don't pattern-match outcomes by message string.** `assert_inbound_rejected(:invalid_sender)` matches the reason term — never the failure message (CLAUDE.md "Things Not To Do" #7).
- **Don't ship a fixture-on-disk loader (`receive_inbound_email_from_fixture` Rails-style).** ActionMailbox's `.eml` files in `test/fixtures/files/` invite real-PII commits. Build payloads in code via `Fixtures.build_*`.
- **Tracking-on-auth doesn't apply, but the inbound analog does:** assertions should not log `from`/`to`/`subject` to telemetry (only to test failure output). Lint via existing Credo `NoPIIInTelemetry` check — extend to the new helpers.

## References

1. ActionMailbox TestHelper — https://github.com/rails/rails/blob/main/actionmailbox/lib/action_mailbox/test_helper.rb (`create_inbound_email_from_*` / `receive_inbound_email_from_*` paired API)
2. Bamboo.Test — https://github.com/beam-community/bamboo/blob/master/lib/bamboo/test.ex (`assert_delivered_email_matches`, `shared: true` mode — Mailglass already does both better)
3. Outbound reference: `lib/mailglass/test_assertions.ex:86-159` (4-style macro), `:230-255` (PubSub-backed), `test/support/mailer_case.ex:120-204` (HI-01 snapshot/restore), `lib/mailglass/adapters/fake.ex:166-195` (`trigger_event/3` driving real write path).
4. Inbound contracts to mirror: `mailglass_inbound/lib/mailglass_inbound/mailbox.ex:22` (locked outcomes), `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex:8` (matcher entry), `mailglass_inbound/lib/mailglass_inbound/execution.ex:38-49` (execute/2 — the seam `Test.Ingress` calls).
5. Generator pattern: `lib/mix/tasks/mailglass.gen.mailable.ex:11-59` (Igniter scaffold + template emission).
