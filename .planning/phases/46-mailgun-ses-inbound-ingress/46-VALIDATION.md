---
phase: 46
slug: mailgun-ses-inbound-ingress
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-23
---

# Phase 46 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Sourced from `46-RESEARCH.md` § Validation Architecture (HIGH confidence).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18) + StreamData (property) |
| **Config file** | `mailglass_inbound/test/test_helper.exs` (runs inbound migrations, starts `MailglassInbound.TestRepo` Sandbox `:manual`) |
| **Quick run command** | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/mailgun_provider_test.exs` (per-provider, fast) |
| **Full suite command** | `cd mailglass_inbound && mix test` |
| **Compile gate** | `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` (MUST stay green — D-46-14) |
| **Lint gate** | `mix credo --strict` + `mix test test/mailglass/credo/` (run actual credo, not grep) |
| **Estimated runtime** | ~30–60 seconds (inbound suite, Postgres-backed) |

> **Scope note:** Bare `mix test` in the core worktree has ~57 unrelated Oban failures — always scope to `mailglass_inbound`.

---

## Sampling Rate

- **After every task commit:** Run the touched provider's test file (`mailgun_provider_test.exs` or `ses_provider_test.exs`) + `mix compile --no-optional-deps --warnings-as-errors`.
- **After every plan wave:** `cd mailglass_inbound && mix test` (full inbound suite) + `mix credo --strict`.
- **Before `/gsd:verify-work`:** Full inbound suite green + both compile lanes green + credo strict clean.
- **Max feedback latency:** ~60 seconds.

**Critical observability points (highest-information signals — under-sampling any one risks shipping a silent forgery-accept or duplicate-insert):**
1. Forged-vs-authentic signature path for **both** providers
2. Replay no-op (Mailgun token → 200, no second record)
3. Control-plane no-op (SES `SubscriptionConfirmation` → 200, no record)
4. S3-fetch retry-then-error (exhaustion → non-2xx so SNS redelivers)
5. Dedupe on `Message-Id` **and** MD5 fingerprint fallback

---

## Per-Task Verification Map

> Task IDs are assigned by the planner. This requirement→test map is the contract each task's `<acceptance_criteria>` must satisfy.

| Requirement | Wave | Secure Behavior | Test Type | Automated Command | File Exists |
|-------------|------|-----------------|-----------|-------------------|-------------|
| MGUN-01 | 1+ | authentic Mailgun → `{:ok, facts}` → persisted | integration | `mix test .../ingress/mailgun_provider_test.exs` | ❌ W0 |
| MGUN-01 | 1+ | **forged** HMAC → `MailglassInbound.SignatureError` → 401, no record | integration | same file | ❌ W0 |
| MGUN-01 | 1+ | new error `__types__/0` matches `api_stability.md` | unit | `mix test .../signature_error_test.exs` | ❌ W0 |
| MGUN-02 | 1+ | **replayed** token → `{:replay}` → 200, no 2nd record; GenServer reused not duplicated | integration | mailgun_provider + plug_test | ❌ W0 |
| MGUN-03 | 1+ | multipart → `%InboundMessage{}` + raw in `inbound_evidence` | integration | mailgun_provider_test | ❌ W0 |
| MGUN-03 | 1+ | dedupe on Message-Id (parsed) AND MD5 fallback (no Message-Id) | integration (Postgres) | persist_test | ❌ W0 |
| MGUN-04 | 1+ | plug allowlist accepts `:mailgun` (one switch) | unit | plug_test | extend existing |
| SESI-01 | 1+ | authentic SNS X.509 → verified; **forged** → SignatureError → 401 | integration | `.../ingress/ses_provider_test.exs` | ❌ W0 |
| SESI-02 | 1+ | `SubscriptionConfirmation` w/ valid SubscribeURL → `{:control_plane, 200}`, no record; **hijacked URL** → rejected | integration | ses_provider_test | ❌ W0 |
| SESI-03/04 | 1+ | `S3Fetcher.Fake` is test default; `.ExAwsS3` gated; `available?/0` false w/o dep | unit | s3_fetcher_test + optional_deps_test | ❌ W0 |
| SESI-05 | 1+ | S3 fetch retry-then-`S3FetchError`; on exhaustion non-2xx (SNS redelivers); idempotency on messageId | integration | ses_provider_test (Fake returns :error first N) | ❌ W0 |
| SESI-05 | 1+ | `S3FetchError.__types__/0` matches `api_stability.md` | unit | s3_fetch_error_test | ❌ W0 |
| (cross) | all | `mix compile --no-optional-deps --warnings-as-errors` green | CI gate | compile command above | existing lane |
| (cross) | all | `NoBareOptionalDepReference` flags bare ExAws refs | credo | `mix credo --strict` | extend `.credo.exs` |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass_inbound/ingress/mailgun_provider_test.exs` — MGUN-01..03 (code-built multipart fixtures, no `.eml`)
- [ ] `test/mailglass_inbound/ingress/ses_provider_test.exs` — SESI-01..05 (code-built SNS envelopes)
- [ ] `test/mailglass_inbound/signature_error_test.exs` — `__types__/0` contract
- [ ] `test/mailglass_inbound/s3_fetch_error_test.exs` — `__types__/0` contract
- [ ] `test/mailglass_inbound/s3_fetcher_test.exs` — Fake + gateway `available?/0`
- [ ] Mailgun + SES code-built payload builders in test support (Phase 47 formalizes `MailglassInbound.Fixtures`; this phase needs ad-hoc builders now)
- [ ] Extend `plug_test.exs` for `:mailgun`/`:ses` allowlist + widened-result branches
- [ ] New migration test coverage for the Mailgun fingerprint index

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real-provider sandbox round-trip (live Mailgun route / live SES→S3) | MGUN-01, SESI-04 | Requires live AWS/Mailgun credentials; advisory-only per fake-adapter-first DNA (D-13) | Documented in Phase 50 setup guide; not a PR-blocking gate |

*All other phase behaviors have automated verification via the Fake adapter + code-built fixtures.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
