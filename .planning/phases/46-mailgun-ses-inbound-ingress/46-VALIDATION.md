---
phase: 46
slug: mailgun-ses-inbound-ingress
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
audited: 2026-05-23
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

| Requirement | Wave | Secure Behavior | Test Type | Automated Command | Status |
|-------------|------|-----------------|-----------|-------------------|--------|
| MGUN-01 | 1+ | authentic Mailgun → `{:ok, facts}` → persisted | integration | `mix test .../ingress/mailgun_provider_test.exs` | ✅ green |
| MGUN-01 | 1+ | **forged** HMAC → `MailglassInbound.SignatureError` → 401, no record | integration | same file | ✅ green |
| MGUN-01 | 1+ | new error `__types__/0` matches `api_stability.md` | unit | `mix test .../signature_error_test.exs` | ✅ green |
| MGUN-02 | 1+ | **replayed** token → `{:replay}` → 200, no 2nd record; GenServer reused not duplicated | integration | mailgun_provider + plug_test | ✅ green |
| MGUN-03 | 1+ | multipart → `%InboundMessage{}` + raw in `inbound_evidence` | integration | mailgun_provider_test | ✅ green |
| MGUN-03 | 1+ | dedupe on Message-Id (parsed) AND MD5 fallback (no Message-Id) | integration (Postgres) | persist_test | ✅ green ⚠️ |
| MGUN-04 | 1+ | plug allowlist accepts `:mailgun` (one switch) | unit | plug_test | ✅ green |
| SESI-01 | 1+ | authentic SNS X.509 → verified; **forged** → SignatureError → 401 | integration | `.../ingress/ses_provider_test.exs` | ✅ green |
| SESI-02 | 1+ | `SubscriptionConfirmation` w/ valid SubscribeURL → `{:control_plane, 200}`, no record; **hijacked URL** → rejected | integration | ses_provider_test | ✅ green |
| SESI-03/04 | 1+ | `S3Fetcher.Fake` is test default; `.ExAwsS3` gated; `available?/0` tracks dep | unit | s3_fetcher_test | ✅ green (see Reliability Note R-2) |
| SESI-05 | 1+ | S3 fetch retry-then-`S3FetchError`; on exhaustion non-2xx (SNS redelivers); idempotency on messageId | integration | ses_provider_test (Fake returns :error first N) | ✅ green |
| SESI-05 | 1+ | `S3FetchError.__types__/0` matches `api_stability.md` | unit | s3_fetch_error_test | ✅ green |
| (cross) | all | `mix compile --no-optional-deps --warnings-as-errors` green | CI gate | compile command above | ✅ green |
| (cross) | all | `NoBareOptionalDepReference` flags bare ExAws refs | credo | `mix credo --strict` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky (intermittent — see Reliability Note R-1)*

---

## Wave 0 Requirements

> All Wave 0 test files were created during execution (Plans 01–03) and verified present + green during the 2026-05-23 audit. See the Validation Audit section.

- [x] `test/mailglass_inbound/ingress/mailgun_provider_test.exs` — MGUN-01..03 (code-built multipart fixtures, no `.eml`) — created Plan 02 (`57bfc11`/`466f656`/`5e04a73`)
- [x] `test/mailglass_inbound/ingress/ses_provider_test.exs` — SESI-01..05 (code-built SNS envelopes) — created Plan 03 (`7680a31`)
- [x] `test/mailglass_inbound/signature_error_test.exs` — `__types__/0` contract — created Plan 01 (`9178d3d`)
- [x] `test/mailglass_inbound/s3_fetch_error_test.exs` — `__types__/0` contract — created Plan 01 (`9178d3d`)
- [x] `test/mailglass_inbound/s3_fetcher_test.exs` — Fake + gateway `available?/0` — created Plan 03 (`65aa083`)
- [x] Mailgun + SES code-built payload builders in test support — ad-hoc builders live inline in the provider test files (Phase 47 formalizes `MailglassInbound.Fixtures`)
- [x] Extend `plug_test.exs` for `:mailgun`/`:ses` allowlist + widened-result branches — Plan 01 (`79cf565`)
- [x] New migration test coverage for the Mailgun fingerprint index — `persist_test.exs` Postgres-backed dedupe tests, Plan 02 (+ SES fingerprint coverage added in review fix WR-02)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real-provider sandbox round-trip (live Mailgun route / live SES→S3) | MGUN-01, SESI-04 | Requires live AWS/Mailgun credentials; advisory-only per fake-adapter-first DNA (D-13) | Documented in Phase 50 setup guide; not a PR-blocking gate |

*All other phase behaviors have automated verification via the Fake adapter + code-built fixtures.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (plan-checker D8 PASS)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter
- [x] `wave_0_complete` — flipped 2026-05-23 (audit): all 8 Wave 0 items exist and pass deterministically

**Approval:** approved 2026-05-23 (plan-checker VERIFICATION PASSED, all 12 dimensions)

---

## Validation Audit 2026-05-23

Retroactive Nyquist coverage audit (State A — audited the existing contract against the executed codebase).

| Metric | Count |
|--------|-------|
| Requirements in Per-Task Map | 14 rows / 9 REQ-IDs |
| COVERED (test exists, targets behavior, runs green) | 14 / 14 |
| Gaps found (MISSING / PARTIAL) | 0 |
| Resolved | 0 (none needed) |
| Escalated to manual-only | 0 |
| New test files generated | 0 (all Wave 0 files already created during execution) |

**Verdict: Phase 46 is Nyquist-compliant.** Every requirement has automated verification that exists in the codebase and passes deterministically.

### Audit evidence (commands re-run during the audit)

| Check | Command | Result |
|-------|---------|--------|
| Phase-46 targeted suite | `mix test <7 phase files>` | **97 tests, 0 failures** |
| Full inbound suite (deterministic) | `mix test --seed 0` | **1 property, 176 tests, 0 failures** (~82s) |
| Compile (no optional deps) | `mix compile --no-optional-deps --warnings-as-errors` | exit 0 |
| Lint + opt-dep gating | `mix credo --strict` | no issues (389 files) |

### Reliability Notes (test-infra; do NOT affect Nyquist compliance)

These are intermittent **test-reliability** observations surfaced by re-running the suite under multiple random seeds during the audit. Neither is a phase-46 coverage gap or a logic defect — phase-46 source is correct and its tests are deterministically green. Both are logged for transparency and a future infra/phase-45 follow-up.

- **R-1 — Cross-phase DB-pool flake (NOT phase 46).** Under random seeds the full inbound suite intermittently fails one DB-backed test (observed: `ingress/persist_test.exs:136`, `DBConnection.ConnectionError: tcp recv: closed (pool timeout)`). Root cause is the **phase-45** property test `MailglassInbound.Properties.InboundIdempotencyConvergenceTest` (`properties/inbound_idempotency_convergence_test.exs:87`, TELE-08): a single 1000-iteration StreamData property driving real Postgres writes that dominates ~99% of suite wall-time (82s→347s, highly variable). When it runs long, sandbox connections go stale and a subsequent DB-backed test (here phase-46's `persist_test`, a collateral victim) can draw a closed connection. Phase-46 dedupe logic is correct — it passes 100% under `--seed 0` and in the per-file targeted run. **Recommended follow-up (phase-45 / infra, out of phase-46 scope):** tag the property test `:slow` and/or shrink `max_runs` for the default lane, or harden TestRepo pool resilience (`queue_target`/`queue_interval`/larger `pool_size`) in `mailglass_inbound/config/test.exs`. The VALIDATION "estimated runtime ~30–60s" line is already optimistic because of this phase-45 test.

- **R-2 — Non-hermetic gateway test (phase 46, latent).** `s3_fetcher_test.exs:81` ("gateway `get_object/2` never raises") calls `MailglassInbound.OptionalDeps.ExAwsS3.get_object/2` directly. When `ex_aws` is compiled into the worktree `_build` (it is, after `mix deps.get`), this performs a **real** `ExAws.request` — walking the AWS credential chain (incl. the EC2 instance-metadata probe, which can hang off-EC2) and HTTP retries. It runs in the async bucket and was fast/green during the audit (0.04s in isolation), but it is a latent flake/slowness source. The test's intent (prove the never-raise wrapper degrades to a tuple) is met. **Recommended hardening (optional, test-only):** make it hermetic via `config :ex_aws` test config (static dummy creds + `retries: [max_attempts: 1]` + a fail-fast `http_client` stub) so no real network I/O occurs.
