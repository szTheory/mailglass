---
phase: 46-mailgun-ses-inbound-ingress
plan: 03
subsystem: api
tags: [inbound, webhook, ses, sns, s3, optional-dep, gateway, signature, mime, bounded-retry]

# Dependency graph
requires:
  - phase: 46-mailgun-ses-inbound-ingress
    provides: "Plan 01 — verify_envelope!/2 SES crypto seam, widened {:ok,facts}|{:control_plane,_} contract, four-provider plug allowlist + dual SignatureError rescue, S3Fetcher behaviour, S3FetchError + SignatureError closed-type errors"
  - phase: 45-inbound-telemetry-idempotency-foundation
    provides: "MailglassInbound.MIME.parse/1 (never-raise RFC 5322 parser, first consumer)"
  - phase: 16-ses-webhook-provider-sns-cache
    provides: "core SES CertCache + TrustPolicy (process-global ETS, reused not re-supervised)"
provides:
  - "MailglassInbound.Ingress.Providers.SES — SES inbound provider: SNS X.509 verify via reused core seam + control-plane no-op + S3/inline MIME extraction"
  - "MailglassInbound.OptionalDeps.ExAwsS3 — inbound-local optional-dep gateway for ex_aws/ex_aws_s3 (D-46-14)"
  - "MailglassInbound.S3Fetcher.Fake — fake-first test-default S3 fetcher (D-13)"
  - "MailglassInbound.S3Fetcher.ExAwsS3 — real S3 fetcher behind the gateway"
  - "MailglassInbound.S3Fetcher.Retry — bounded GetObject retry mapping exhaustion to S3FetchError (D-46-16)"
affects: [phase-50-inbound-setup-docs]

# Tech tracking
tech-stack:
  added:
    - "ex_aws ~> 2.7 (optional) — first optional runtime dep since the v1.0 STACK lock (D-46-20)"
    - "ex_aws_s3 ~> 2.5 (optional)"
  patterns:
    - "Inbound-local optional-dep gateway mirroring Mailglass.OptionalDeps.GenSmtp (no_warn_undefined + available?/0 + never-raise wrapper)"
    - "Process-local verify->normalize handoff (process dictionary) so the single S3 fetch in verify!/2 reaches normalize/1 with no double fetch"
    - "Bounded GetObject retry: transient :s3_object_not_ready retries, :s3_fetch_failed short-circuits; exhaustion raises S3FetchError so SNS redelivers"
    - "reraise SignatureError.new(...), __STACKTRACE__ to re-classify core's SignatureError as the package-local one while preserving the stacktrace"

key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex
    - mailglass_inbound/lib/mailglass_inbound/s3_fetcher/fake.ex
    - mailglass_inbound/lib/mailglass_inbound/s3_fetcher/ex_aws_s3.ex
    - mailglass_inbound/lib/mailglass_inbound/s3_fetcher/retry.ex
    - mailglass_inbound/test/mailglass_inbound/s3_fetcher_test.exs
    - mailglass_inbound/test/mailglass_inbound/ingress/ses_provider_test.exs
  modified:
    - mailglass_inbound/lib/mailglass_inbound/optional_deps.ex
    - mailglass_inbound/mix.exs
    - .credo.exs
    - mailglass_inbound/CHANGELOG.md

key-decisions:
  - "dispatch_message_type/3 is PRIVATE in core SES (the plan interface listed it as public — erratum). The inbound provider implements its own control-plane handling: TrustPolicy.valid_subscribe_url?/1 SSRF/hijack guard + {:control_plane, 200} no-op. Topic activation (the actual ConfirmSubscription HTTP call) is core's outbound concern; the inbound deliverable is the 200 no-op with no record (D-46-06)."
  - "verify->normalize handoff via the process dictionary (same request process) so the single S3 fetch in verify!/2 reaches normalize/1. Defensive fallback re-parses + re-fetches if normalize/1 is called without a prior verify in the same process."
  - "S3Fetcher.Retry is a separate small module (not inlined in ses.ex) so the bounded retry is unit-testable in isolation AND callable from the SES provider."
  - "S3FetchError ships no new/N builder (its public surface is __types__/0 + the struct), so the Retry helper and SES provider construct the %S3FetchError{} struct directly — no contract change to the Plan-01 error."
  - "Gateway available?/0 test asserts the CONTRACT (== Code.ensure_loaded?(ExAws.S3)) rather than a hardcoded false, so it is correct whether or not the dev worktree has ex_aws compiled into _build; the mix compile --no-optional-deps lane is the real proof the gateway compiles with the dep stripped."

patterns-established:
  - "SES verify->normalize process-local handoff (single fetch, single verify)"
  - "Bounded S3 GetObject retry with transient/non-retryable classification"

requirements-completed: [SESI-01, SESI-02, SESI-04, SESI-05]

# Metrics
duration: ~25min
completed: 2026-05-23
---

# Phase 46 Plan 03: SES Inbound Ingress Summary

**Ships `MailglassInbound.Ingress.Providers.SES` — the second production inbound provider — reusing core's SNS X.509 verify seam, returning a `{:control_plane, 200}` no-op for SNS subscription confirmations, and extracting the raw MIME body from the receipt-rule S3 action (primary) or SNS-inline `content` (secondary) behind a fake-first `S3Fetcher` with a bounded GetObject retry; plus the inbound-local `MailglassInbound.OptionalDeps.ExAwsS3` gateway and the first new optional deps (`ex_aws`/`ex_aws_s3`) since the v1.0 STACK lock.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 3 (Task 1 auto; Tasks 2 + 3 TDD)
- **Files:** 10 (6 created, 4 modified)
- **Tests added:** 23 (13 S3 fetcher + 10 SES provider), all green

## Accomplishments

- **`MailglassInbound.OptionalDeps.ExAwsS3`** — inbound-local gateway mirroring `Mailglass.OptionalDeps.GenSmtp`: `@compile {:no_warn_undefined, [ExAws, ExAws.S3]}`, `available?/0` via `Code.ensure_loaded?(ExAws.S3)`, and a never-raise `get_object/2` (`rescue` + `catch :exit`). The ONLY place that names `ExAws`/`ExAws.S3` (D-46-14).
- **`{:ex_aws, "~> 2.7", optional: true}` + `{:ex_aws_s3, "~> 2.5", optional: true}`** added to `mailglass_inbound/mix.exs` — the first optional deps since the v1.0 STACK lock, recorded in CHANGELOG (D-46-20). NOT added to the project `no_warn_undefined` (the gateway's own `@compile` covers them).
- **`.credo.exs`** gates `ExAws` and `ExAws.S3` to the gateway via `NoBareOptionalDepReference`.
- **`MailglassInbound.S3Fetcher.Fake`** — dependency-free `:test`-default fetcher (D-13). Canned `{:ok, body}`, always-error, and error-first-N modes via the calling process's dictionary (async-safe); counts calls so the retry budget is assertable.
- **`MailglassInbound.S3Fetcher.ExAwsS3`** — real adapter routing all access through the gateway (no bare `ExAws` ref); extracts `:body`, surfaces `{:error, _}` unchanged, treats a non-binary body as a fetch error.
- **`MailglassInbound.S3Fetcher.Retry`** — bounded retry (default 3 attempts, 250ms→1s→2s). `:s3_object_not_ready` is transient (retry), `:s3_fetch_failed` short-circuits; exhaustion raises `S3FetchError :s3_object_not_ready` so SNS redelivers (D-46-16).
- **`MailglassInbound.Ingress.Providers.SES`** — `verify!/2` reuses `Mailglass.Webhook.Providers.SES.verify_envelope!/2`, re-raises forgery/SSRF as `MailglassInbound.SignatureError :bad_signature`; three-way `Type` dispatch (Notification persists; Subscription/Unsubscribe → `{:control_plane, 200}` no-op, hijacked SubscribeURL → `:subscribe_url_untrusted`); Notification MIME extraction via S3 (bounded retry) or inline `content` (UTF-8/Base64) fed to `MIME.parse/1`; `normalize/1` builds `%InboundMessage{}` + evidence.

## Task Commits

1. **Task 1: ExAwsS3 gateway + optional deps + .credo.exs gating** — `2644e36` (feat)
2. **Task 2: S3Fetcher Fake/ExAwsS3 + bounded retry (TDD)** — `65aa083` (feat) — RED then GREEN within the commit (failing tests written first)
3. **Task 3: SES inbound provider (TDD)** — `7680a31` (feat) — RED then GREEN within the commit

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `dispatch_message_type/3` is private in core SES (plan interface erratum)**
- **Found during:** Task 3
- **Issue:** The plan's `<interfaces>` and Task 3 action said to "reuse `SES.dispatch_message_type(type, sns_payload, config)`", but that function is `defp` in `lib/mailglass/webhook/providers/ses.ex` — not callable cross-module.
- **Fix:** The inbound SES provider implements its own control-plane handling: validate `SubscribeURL` with the public `TrustPolicy.valid_subscribe_url?/1` (raise `:subscribe_url_untrusted` on a hijacked URL) and return `{:control_plane, 200}`. The actual ConfirmSubscription HTTP call (topic activation) is core's outbound concern; the inbound deliverable is the 200 no-op with no record (D-46-06, T-46-23). No core change.
- **Files modified:** `ingress/providers/ses.ex`
- **Verification:** SubscriptionConfirmation + UnsubscribeConfirmation + hijacked-URL tests pass.
- **Committed in:** `7680a31`

**2. [Rule 3 - Blocking] `normalize/2` required by the Provider behaviour; `normalize/1` is not a callback**
- **Found during:** Task 3 (`--warnings-as-errors` failed)
- **Issue:** The behaviour declares `normalize/2` as required (not in `@optional_callbacks`) and has no `normalize/1` callback. Implementing only `normalize/1` warned twice ("normalize/2 required ... not implemented" + "`@impl` for normalize/1 but no such callback").
- **Fix:** Mirror the SendGrid provider exactly — mark the struct-arity `normalize/1` `@impl false` and add a `normalize/2` compatibility shim (`@impl MailglassInbound.Ingress.Provider`) that wraps the raw body into a `%Request{}` and delegates.
- **Files modified:** `ingress/providers/ses.ex`
- **Verification:** Both compile lanes exit 0.
- **Committed in:** `7680a31`

**3. [Rule 1 - Bug] `raise` inside `rescue` failed `WrongStacktraceInRescue` (credo --strict exit 16)**
- **Found during:** Task 3 (credo)
- **Issue:** Re-classifying core's `SignatureError` into the inbound one via a bare `raise SignatureError.new(...)` inside the `rescue` block tripped `Credo.Check.Warning.WrongStacktraceInRescue` (exit 16).
- **Fix:** Use `reraise SignatureError.new(type, provider: :ses, cause: e, context: ...), __STACKTRACE__` — the canonical idiom (core SendGrid uses it) that preserves the original stacktrace while raising a new exception type.
- **Files modified:** `ingress/providers/ses.ex`
- **Verification:** `mix credo --strict` exit 0; forged-signature test still raises `:bad_signature`.
- **Committed in:** `7680a31`

**4. [Rule 3 - Blocking] `mix deps.get` pulled optional deps + upgraded unrelated transitive lock entries**
- **Found during:** Task 1
- **Issue:** The fresh worktree had no `deps/`; `mix deps.get` was required to compile/test. It resolved `ex_aws 2.7.0` / `ex_aws_s3 2.5.9` (matching the threat-model-verified versions) and upgraded several unrelated transitive deps in `mix.lock` (same environmental drift Plan 01 noted).
- **Fix:** Ran `mix deps.get` (declared deps only). `mix.lock` was intentionally EXCLUDED from all commits — those out-of-scope lock changes are for the orchestrator/merge to resolve on the integration branch.
- **Committed in:** N/A (environment setup, no source change)

### Out-of-scope (logged, not fixed)

- Pre-existing core warning under `--no-optional-deps`: `unknown module Mailglass.Outbound.Worker is listed as an export` at `lib/mailglass/outbound.ex:75` (Oban-gated worker). NOT caused by 46-03 and does NOT fail the lane (exit 0). Logged to `deferred-items.md`.

**Total deviations:** 4 (1 plan interface erratum, 2 blocking compile/lint, 1 environment).
**Impact on plan:** No scope creep — no core source changed, no public `%InboundMessage{}` widening, no new error builders added to the Plan-01 closed-type errors. All deviations were necessary for correctness, clean compilation, or lint.

## Authentication Gates

None. The SES inbound test default is `S3Fetcher.Fake`; CI needs no AWS setup. Real AWS credentials (ex_aws standard chain) are an adopter-side Phase-50 concern.

## Verification Results

- `cd mailglass_inbound && mix test test/mailglass_inbound/s3_fetcher_test.exs test/mailglass_inbound/ingress/ses_provider_test.exs` → **23 tests, 0 failures**
- `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` → **exit 0**
- `cd mailglass_inbound && mix compile --warnings-as-errors` → **exit 0**
- `mix credo --strict` → **exit 0, no issues** (no `NoBareOptionalDepReference`; gateway is the only ExAws reference)
- Inbound error contract tests (`s3_fetch_error_test`, `signature_error_test`) → **15 tests, 0 failures** (closed-type contracts unbroken)
- Forged-signature test asserts `MailglassInbound.SignatureError :bad_signature`; control-plane tests assert `{:control_plane, 200}` with no record; retry-exhaustion test asserts `S3FetchError :s3_object_not_ready`.

## Threat Model Coverage

- **T-46-20 (Spoofing, X.509):** reuse `verify_envelope!/2`; forgery reraised as `SignatureError :bad_signature` → 401 no-recovery. Tested.
- **T-46-21 (SSRF, SigningCertURL):** `TrustPolicy.valid_cert_url?/1` runs inside `verify_envelope!` before any network I/O; forged S3-namespace cert URL → `:bad_signature`. Tested.
- **T-46-22 (SubscribeURL hijack):** `TrustPolicy.valid_subscribe_url?/1`; hijacked URL → `:subscribe_url_untrusted`. Tested.
- **T-46-23 (control-plane no-op):** Subscription/Unsubscribe return `{:control_plane, 200}` with NO InboundRecord. Tested.
- **T-46-24 (unbounded S3 retry):** bounded ≤3 attempts, exhaustion → `S3FetchError :s3_object_not_ready` + non-ack (SNS redelivers). Tested.
- **T-46-26 (KMS ciphertext):** scoped out (D-46-18) — ciphertext parses as a degraded record via the never-raise `MIME.parse/1`, never a crash.
- **T-46-27 (Info Disclosure):** `S3FetchError`/`SignatureError` derives exclude `:cause`/`:provider`; the SES provider verify facts (`%{auth: :sns_x509}`) are PII-free.
- **T-46-SC (dep installs):** `ex_aws`/`ex_aws_s3` added as OPTIONAL deps, gateway-gated; versions match the RESEARCH Hex audit (ex_aws 2.7.0, ex_aws_s3 2.5.9).

## Known Stubs

None. The `S3Fetcher.Fake` is the intentional fake-first test default (D-13), not a stub — `S3Fetcher.ExAwsS3` is the wired real path resolved by the config seam outside `:test`.

## Next Phase Readiness

- SES inbound is production-grade and unblocks Phase 50 setup docs (SESI-06): route/SNS-topic config, S3 bucket + IAM policy, the `ex_aws`/`ex_aws_s3`/`sweet_xml`/HTTP-client dep snippet, and the standard-credential-chain note.
- The four-provider plug (Plan 01) already dispatches `:ses`; this plan supplies the referenced `MailglassInbound.Ingress.Providers.SES` module, so the `no_warn_undefined` forward reference now resolves at runtime.

## Self-Check: PASSED

All created files verified on disk; all task commits (`2644e36`, `65aa083`, `7680a31`) present in git history.
