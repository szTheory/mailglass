# Milestones

## v1.6 Inbound 1.0 Release and Truth Lock (Shipped: 2026-06-02)

**Phases completed:** 3 phases, 6 plans, 5 tasks

**Key accomplishments:**

- Exact inbound 1.0.0 release-truth proof with blocker-only root docs/runbook corrections
- Inbound RELEASE-RECORD and RELEASE-CHECKLIST authored under prepare-and-stage posture: mix mailglass.publish.check (exit 0) and stability_contract test (6/0) captured; all post-publish fields (Hex, HexDocs, smoke, 60-minute) marked pending/not run

---

## v1.5 Demo Evidence and Click-Around Confidence (Shipped: 2026-06-02)

**Phases completed:** 4 phases, 8 plans, 14 tasks

**Key accomplishments:**

- Demo app now has executable local-vs-Hex dependency modes with current published constraints, and reference-host scope lock blocks rich-demo drift.
- Compose demo now enforces Phoenix health readiness and deterministic Playwright dependency setup for reliable click-around and browser evidence runs.
- Phase 67 now has executable deterministic reset proof plus a one-command `verify.phase67` lane and bounded `demo_browser_evidence.v1` wording for demo-only adoption evidence.
- Deterministic Northstar fixture corpus now seeds six outbound and four inbound named stories with replay lineage plus a repo-root quick gate.
- Preview mailers now expose deterministic, realistic scenario props and copy, and six scenario contracts are pinned at the public `Mailglass.Message` seam.
- Guided Northstar dashboard hub copy now points maintainers into real preview/outbound/inbound surfaces with explicit destructive reset wording and focused controller proof.
- Canonical demo docs now pin quickstart, click-path, seeded stories, reset semantics, and boundary claims with executable ExUnit contract checks.

---

## v1.4 Inbound Stability Lock (Shipped: 2026-06-01)

**Phases completed:** 4 phases, 12 plans, 22 tasks

**Key accomplishments:**

- Semantics-first inbound stability inventory with package-local docs-contract guards for stable, testing, internal, and deferred seams
- Inbound runtime seam metadata now reflects package-line truth (`0.1.0` and `0.2.0`) for compiled-doc contract proofing.
- Stable inbound structured-error and operator task modules now expose truthful `0.2.0` `since` metadata without widening direct invocation guarantees.
- Aligned inbound testing helper compiled-doc metadata to the truthful `0.2.0` package line across fixtures, ingress drivers, assertions, and mailbox case template.
- Inbound docs contract now fails closed on structured-error type-set drift, stale dep pins, and stable-surface over-claims while preserving explicit deferred-language mentions.
- Inbound now owns one authoritative compiled-doc stability proof lane, and root `verify.stability_contract` delegates to that package-owned support-contract alias.
- Canonical inbound adoption and compatibility flow now routes all stability guarantees through the inbound API stability inventory.
- Inbound operator, testing, and admin trust docs now explicitly lock command semantics, process-local assertion behavior, and replay trust boundaries without promoting internal APIs.
- Inbound adoption and compatibility wording is now executable: docs-contract and Tier 1 checks fail closed on canonical-path or compatibility-topology drift.
- Operator/testing/admin trust semantics are now fail-closed in both package-local docs-contract tests and root Tier 1 docs checks.
- Promoted `mailglass_inbound` to `1.0.0` with aligned source/manifest/README truth, operational release notes, and refreshed candidate-version publish evidence.

---

## v1.3 Adopter Trust Proof (Shipped: 2026-05-31)

**Phases completed:** 7 phases, 18 plans, 29 tasks

**Key accomplishments:**

- A committed maintained Phoenix host baseline now boots with Ecto wiring and a deterministic README-backed boot contract for HOST-01.
- HOST-02 is now mechanically enforced by locking the reference host to stable public seams and adding a fail-closed contract test for forbidden internal coupling.
- HOST-03 is now enforced by a committed scope contract plus deterministic required/forbidden token tests that prevent trust-proof drift into second-product expansion.
- Shipped one canonical `mix verify.reference_host.journey` entrypoint backed by a deterministic stage runner and fail-closed contract tests that preserve the Phase 57/58 trust boundary.
- Delivered deterministic fixture/checkpoint evidence for the trust runner, including `trust_runner.v1` schema output, stable ordering/hash semantics, and fail-closed checkpoint validation for downstream trust lanes.
- Postmark webhook evidence now proves the maintained reference-host route verifies before tenant, persistence, or execution work.
- No-match routing diagnosis evidence now completes the verify-first webhook plus operator troubleshooting trust checkpoint.
- Added `trust_lane_repo_head` and clean-baseline trust lanes, registered repo-head in branch-protection `REQUIRED_CHECKS`, and uploaded 90-day `trust_runner.v1` checkpoint artifacts for release evidence.
- Post-publish smoke now runs the published-version trust journey, guards fresh published installs against hackney regressions, and closes the smoke tracker automatically after green CI evidence.
- Maintainer release docs now require green trust evidence, describe hands-free publish accurately, and have deterministic tests preventing stale gate drift.
- Reference-host docs now explicitly state a usage-proof-only boundary and route stable guarantees to canonical api_stability inventories, with deterministic Phase 61 token checks enforced in the existing trust-runner contract test.
- Maintainer, webhook, troubleshooting, and operator trust-entry docs now route guarantee semantics to canonical stability inventories and executable contract lanes without widening public contract scope.
- Phase 61 trust-entry docs are now fail-closed under deterministic checker and ExUnit contract assertions for canonical stability routing, non-contract framing, and internals-as-guarantee overreach.
- Reference host release-line proof now resolves the v1.3 sibling packages from Hex and fails closed on stale Hex versions.

---

## v0.4 Roadmap: mailglass (Backfilled: 2026-05-29)

**Note:** Synthesized from archive snapshot by `/gsd-health --backfill`. Original completion date unknown.

---

## v0.3 : Webhook Coverage Complete (Backfilled: 2026-05-29)

**Note:** Synthesized from archive snapshot by `/gsd-health --backfill`. Original completion date unknown.

---

## v0.1 : Validation Release (Backfilled: 2026-05-29)

**Note:** Synthesized from archive snapshot by `/gsd-health --backfill`. Original completion date unknown.

---

## v0.2 Production-Credible Core (Shipped: 2026-04-28)

**Phases completed:** 5 phases, 29 plans, 41 tasks

**Key accomplishments:**

- Replace dead workflow_run-with-head_branch gate with on: release: types: [published] across both publish workflows, and add mix hex.info idempotency guard so workflow reruns cannot double-publish.
- Scan before execution:
- Bash-loop generalization:
- One-liner:
- AsyncAdapter behaviour (5th first-class behaviour) + CitextProbe extraction: eliminates Task.Supervisor sandbox ownership leaks and citext OID flakes; PR-A foundation landed; PR-B advisory lane added; PR-C gate flip awaiting szTheory soak sign-off
- Credo step
- 1. [Rule 3 - Refactoring] Internal usage of `Message.new` migrated to `Message.build`
- Phase:
- Enforced v0.2 API stability via a CI script scanning for Swoosh type leaks and documented the official freeze policy.
- Phase:
- 1. [Rule 3 - Blocker] Fixed struct compile deadlock between Message and Stream
- RFC 8058 unsubscribe config, lifecycle seam, and Phoenix.Token URL service with raw-secret rotation fallback
- Message-aware outbound compliance now injects RFC 8058 unsubscribe headers atomically and strict lint blocks any ad hoc header mutation path.
- Core RFC 8058 unsubscribe controller with standalone GET confirmation, replay-safe POST event append, and lifecycle-aware transaction composition
- Added the core router macro for RFC 8058 unsubscribe routes, backed by compile-time collision detection and route reflection tests.
- Read-only `mix mailglass.gen.unsubscribe` checklist with strict CLI parsing, canonical router instructions, and live route-preflight guidance
- StreamData coverage now proves unsubscribe secret rotation, expiry, URL hardening, stream header gating, and one-click POST replay convergence.
- Adopter-facing RFC 8058 setup, replay, rotation, and DKIM verification guidance with load-bearing docs smoke coverage
- Webhook ingest now projects complaint, unsubscribe, and hard-bounce events into idempotent suppression rows through a centralized helper and replay-convergence property coverage
- A targeted Credo check now fails when webhook ingest moves suppression writes ahead of the durable event append and projector path
- Soft-bounce escalation now has an Oban-backed worker, a direct evaluation helper, and the V03 storage slot needed for its event-window query
- Tenant-scoped suppression rebuild via a shared resync service and strict `mix mailglass.suppressions.resync` contract
- Structured suppression preflight errors with reason/source/expiry context plus explicit non-PII telemetry for blocked sends and webhook auto-adds
- Tenant-scoped suppression removal now rejects complaint and unsubscribe rows, complaint expiries are blocked before insert and in Postgres, and the webhook guide documents why complaint suppression outlives deletable source evidence.

---

## v0.5 Adoption Hardening (Shipped: 2026-05-03)

**Phases completed:** 4 phases, 7 plans

**Key accomplishments:**

- `mix mailglass.gen.mailable` generator implemented using Igniter for boilerplate-free scaffolding of mailable modules and HEEx templates.
- Comprehensive `Mailglass.TestAssertions` suite added, providing high-signal helpers for verifying outbound delivery, async webhook outcomes (delivered/bounced), and HTML content matching.
- Multi-bucket per-domain rate limiting implemented with `Mailglass.RateLimiter`, ensuring reputation protection with transactional bypass safety for critical emails.
- First-party Webhook Troubleshooting Guide and Upgrading Guide published to address common adopter friction points.
- Hardened `mix mailglass.install` with dry-run support, conflict detection, and improved dependency management.

---

## v0.6 Production Maturity (Shipped: 2026-05-05)

**Phases completed:** 3 phases, 9 plans

**Key accomplishments:**

- Replay and reconcile operator flows now resolve exact tenant-safe targets before adopter-owned destructive-action authorization and preserve audit cleanliness on stale-auth denials.
- Replay and repair wording is unified across the operator header, modal, timeline, and audit surfaces with explicit availability, outcome, and effect states.
- Reconcile now has one honest contract across Oban and Oban-less installs, including a truthful `mix mailglass.reconcile` fallback and aligned maintenance docs.
- Incident support now includes a canonical operator guide, a tenant-scoped support-summary read model, masked overview cues, and exemplar drilldowns into webhook and timeline evidence.
- Verification now relies on explicit root/admin support-contract authorities and three named required CI buckets, with only manual branch-protection verification and non-blocking boundary warnings accepted as closeout debt.

---

## v1.0 Stability Lock (Shipped: 2026-05-06)

**Phases completed:** 4 phases (35-38), 12 plans

**Key accomplishments:**

- Canonical core/admin stability inventories with explicit stable / internal / sibling-package-only classification, backed by compiled-doc and docs-surface verification.
- Explicit `1.x` compatibility/deprecation guide and a canonical latest-`0.x` to `1.0` upgrade path, both folded into existing repo-native verification lanes.
- Semantic Tier 1 drift checks, canonical testing and admin trust docs, and a repo-root `verify.stability_contract` proof entrypoint.
- Committed release-rehearsal artifacts (install + upgrade evidence), explicit release checklist/record, and Hex publish posture ready for live cutover.
- Accepted closeout debt: partial Nyquist bookkeeping for Phase 35, non-blocking boundary warnings in support-contract lanes, manual GitHub branch-protection verification.
- **Live publish: 2026-05-07** — `mailglass` 1.0.0, `mailglass_admin` 1.0.0, `mailglass_inbound` 0.1.0 published to Hex.pm via Phase 44.5 ceremony. See `.planning/phases/044.5-v1-0-1-1-release-ceremony/044.5-RELEASE-RECORD.md`.

---

## v1.1 Inbound Core Slice (Shipped: 2026-05-06)

**Phases completed:** 6 phases (39-44), 17 plans (12 product + 5 audit-gap closure)

**Key accomplishments:**

- Opened `mailglass_inbound` as the first sibling-package expansion past `v1.0` — canonical `%InboundMessage{}` struct, narrow router DSL, and mailbox behaviour with locked `:accept` / `:reject` / `:ignore` / `{:bounce, reason}` outcomes.
- First-party Postmark inbound ingress: verify-first plug, sealed normalization seam, and duplicate-safe persistence of both normalized canonical data and raw provider source for replay/debug truth.
- First-party SendGrid inbound ingress: post-commit mailbox execution, SendGrid-specific dedup, and honest replay over stored truth that never re-pretends a stored message is a fresh provider event.
- Operationally credible async execution: Oban-backed inbound worker plus bounded `Task.Supervisor` fallback when Oban is absent, canonical adoption / install / testing / operator docs, and repo-root release-proof coverage for the new sibling package.
- Execution verification chain restored end-to-end: Phase 43 recovered `39-VERIFICATION.md`, `40-VERIFICATION.md`, replaced the plan-check `41-VERIFICATION.md`, and added `41-VALIDATION.md`; Phase 44 recovered `42-VERIFICATION.md` and reconciled `REQUIREMENTS.md` / `STATE.md` / `ROADMAP.md` so the v1.1 audit re-ran with `status: passed`.
- Accepted carry-forward debt only — no new closeout debt introduced. Conductor-style dev UI, Mailgun / SES / `gen_smtp` relay ingress remain deliberately deferred so the first inbound milestone stays narrow and supportable.

---

## v1.2 Inbound Production Confidence (Shipped: 2026-05-26)

**Phases completed:** 10 phases (44.5, 45-50, 50.5, 50.7, 51), 42 plans

**Live publish: 2026-05-26** — `mailglass` 1.2.0, `mailglass_admin` 1.2.0, `mailglass_inbound` 0.2.0 published to Hex.pm via Phase 50.5 ceremony. See `.planning/phases/50.5-v1-2-release-ceremony/50.5-RELEASE-RECORD.md`. Sandbox install proof (`mix phx.new` + `~> 1.2` / `~> 0.2` deps + `mix compile --warnings-as-errors`) passed within the 60-minute window.

**Key accomplishments (9 REQ-ID categories):**

- **TELE** (Phase 45) — `MailglassInbound.Telemetry` span surface at `[:mailglass_inbound, :ingress|route|execution|persist, *]` with PII-free whitelisted metadata; per-tenant PubSub topics via `PubSub.Topics`; never-raise `MailglassInbound.MIME` parse seam over the optional `Mailglass.OptionalDeps.GenSmtp.decode/2` (returns `{:ok, _}` or `{:error, %MIMEError{}}`); StreamData 1000-replay convergence property guarantees idempotent execution.
- **MIME** (Phase 45) — Package-local `MailglassInbound.MIMEError` defexception; depth-guarded never-raise contract verified against malformed MIME.
- **MGUN** (Phase 46) — `MailglassInbound.Ingress.Providers.Mailgun` HMAC-SHA256 ingress with `SignatureError` no-recovery contract, dual body-mime/parsed mode, fingerprint dedupe via `unique_constraint`.
- **SESI** (Phase 46) — `MailglassInbound.Ingress.Providers.SES` SNS X.509 verification + S3 fetch (SSRF-guarded); `MailglassInbound.S3Fetcher` behaviour with `ExAwsS3` + `Fake` adapters; `MailglassInbound.OptionalDeps.ExAwsS3` gateway (first optional deps since the v1.0 STACK lock; `--no-optional-deps` lane intact); `S3FetchError` transient/permanent mapping.
- **ITEST** (Phase 47) — Hex-public Testing helpers under one ExDoc group: `MailboxCase` (ExUnit case template, `async: false`, ETS sandbox), `TestAssertions` (4 matcher styles + outcome + routing + negative), `Test.Ingress` (real persist+sync-execute driver), `Fixtures` (code-built Postmark/SendGrid/Mailgun/SES-SNS payloads incl. a signed SNS minted from an ephemeral RSA-2048 keypair through the real `CertCache` — no `.eml`/`.pem` files on disk).
- **IGEN** (Phase 47) — Three Igniter generators: `mix mailglass.gen.{mailbox,inbound_router,inbound_route}` (idempotent Sourceror-zipper edits, `--dry-run` free).
- **IADM** (Phase 48) — `MailglassAdmin.InboundLive` mountable admin UI at `/inbound` (list, detail, timeline, routing-trace views; tenant-gated replay confirm modal); `MailglassAdmin.OptionalDeps.MailglassInbound` runtime gateway so admin works with or without inbound.
- **IOPS** (Phase 49) — `mix mailglass.inbound.{doctor,replay,prune}` operator tasks (three-state exit codes; `--tenant` required for replay; typed "yes" confirmation for prune; `--dry-run` / `--yes` for cron); `MailglassInbound.RateLimiter` three-bucket limiter (tenant / sender_domain / recipient); `InboundMessage.Signals` suppression-flag-only contract at `.signals.suppression_flagged` (no auto-bounce, Deviation D-49-21).
- **IDOC** (Phase 50) — Six adopter guides under `mailglass_inbound/docs/`: install, testing, operator, mailgun, ses, routing-debug; extended `mix mailglass.docs.check` to enforce all six.
- **CLOSE** (Phases 44.5 and 51) — Live `v1.0`/`v1.1` publish closeout, Phase 35 Nyquist reconciliation, branch-protection repo truth, citext race fix, boundary cleanup, and explicit WR-01..WR-06 dispositions.

**Known deferred items at close:** 1 (see `STATE.md` Deferred Items)

**Residual follow-up (non-blocking):**

- release-please-action v5 + `GITHUB_TOKEN` anti-recursion still forces `workflow_dispatch` for downstream publish fanout.
- Admin publish still needs an explicit Hex-index wait on inbound when sibling packages release in parallel.
- `SEED-003-ecosystem-integrations` remains dormant for a future milestone rather than being treated as partial `v1.2` scope.
