# Requirements: mailglass v0.2 — Production-Credible Core

**Status:** 🚧 IN PLANNING
**Defined:** 2026-04-26
**Core Value:** Email you can see, audit, and trust before it ships.
**Driving constraint:** Other szTheory OSS libraries (e.g. `accrue`) about to depend on mailglass. Locking the public API NOW is the highest-leverage move; every breaking change after v0.2 multiplies cost across all downstream pinners.

> Requirements derive from `PROJECT.md` (locked decisions D-01..D-21), `.planning/research/SUMMARY.md` (v0.2 synthesis), `.planning/research/PITFALLS.md` (22 new v0.2 pitfalls — 6 CRITICAL), and `.planning/milestones/v0.1-REQUIREMENTS.md` (v0.5 candidate set carried forward to Future Requirements).
>
> Each REQ-ID is atomic, user-observable, and testable. Cross-references to `research/FEATURES.md` IDs (TS-V2-/DF-V2-/AF-V2-) and `research/PITFALLS.md` IDs (UNSUB-/SUPP-/STREAM-/API-/REL-/CROSS-) are noted in parentheses.
>
> **Three-pillar structure** (corresponds to milestone framing in `PROJECT.md` Current Milestone section):
> - **Pillar A — API stability**: API-01..07 — downstream OSS deps can pin to v0.2 without Swoosh-namespace exposure
> - **Pillar B — Deliverability floor**: STREAM-01..04, UNSUB-01..06, SUPP-01..05 — RFC 8058 + auto-suppression make "batteries-included" load-bearing
> - **Pillar C — Release-engineering hardening**: REL-01..16 — close v0.1.2 debt + tighten merge gates + ship v0.2 to Hex.pm

---

## v0.2 Requirements (= v0.2 release)

### Pillar A — API Stability

- [x] **API-01
**: `Mailglass.Message` exposes 8 native field setters: `to/2`, `from/2`, `subject/2`, `html_body/2`, `text_body/2`, `header/3`, `attach/2`, `put_tag/2`. Each delegates internally to `Swoosh.Email.*` but the adopter API surface contains zero direct `Swoosh.Email` references. (TS-V2-01)
- [x] **API-02
**: `Mailglass.Message.update_swoosh/2` is retained as the named, documented escape hatch for raw `Swoosh.Email` access (custom adapters, raw headers, MIME shenanigans). Listed in `api_stability.md` v2 §Message Extensions; codemod task does NOT touch it. (TS-V2-02, DF-V2-02; pitfall API-03)
- [x] **API-03
**: `use Mailglass.Mailable` injection no longer contains `import Swoosh.Email, except: [new: 0]` (currently at `lib/mailglass/mailable.ex:129`). Total injection size remains ≤20 lines (LINT-05 enforces). Adopter `MyApp.UserMailer` modules compile against v0.2 with native Message field setters and zero `Swoosh.Email` references. (TS-V2-01)
- [x] **API-04
**: `@deprecated` compile-time warnings emit on every v0.1 path superseded by v0.2 native setters. v0.1 adopter code (`~> 0.1`) compiles against v0.2 with warnings, not errors. One-cycle BC commitment documented in `api_stability.md` v2. Zero new dep — `@deprecated` is built into Elixir 1.18+. (TS-V2-04)
- [x] **API-05**: `mix mailglass.upgrade.v0_2` codemod (Igniter ~> 0.7) AST-rewrites mechanically-safe call sites: `Swoosh.Email.to/2` → `Mailglass.Message.to/2` etc. where the `%Mailglass.Message{}` variable name is statically determinable. Ambiguous cases emit `IO.warn` with human-readable description + migration guide URL — NEVER silent rewrite. Default mode is dry-run; `--apply` required to mutate. `--dry-run` and `--check` modes supported. Codemod skips string literals, heredocs, and comments. (TS-V2-05, DF-V2-05; pitfalls API-02
, CODEMOD-01..04)
- [x] **API-06**: `api_stability.md` v2 enumerates the public surface explicitly: every public module + function with `Since: 0.2.0` annotations or earlier; freeze-until-vNext promise; deprecation policy. Doc-contract test asserts no `Swoosh.Email.t()` reference appears in public-API docstrings or typespecs. `mix mailglass.stability.check` script validates the contract. (TS-V2-03; pitfall API-01
)
- [ ] **API-07**: `guides/upgrading-from-v0_1.md` ships with: worked before/after examples; `mix mailglass.upgrade.v0_2` walkthrough; ambiguous-case manual-edit recipes; minimum dep matrix (Phoenix 1.8.5+, Oban 2.21+ if used, Postgrex versions); rollback procedure if codemod produces unexpected results. Doctest-style snippets compile against v0.2 in CI. (Pitfall CROSS-02)

### Pillar B — Deliverability Floor

#### Streams (Phase 10)

- [x] **STREAM-01
**: `Mailglass.Stream` module exposes a closed atom set: `:transactional | :operational | :bulk`. Streams are settable both compile-time (via `use Mailglass.Mailable, stream: :bulk`, stamped onto `%Message{}` in `Message.new_from_use/2`) and runtime (via `%Message{stream: :bulk}`). Per-Mailable default-stream resolution. (TS-V2-06)
- [x] **STREAM-02
**: `Mailglass.Send.Pipeline.StreamPolicy` stage replaces the v0.1 no-op seam at `lib/mailglass/stream.ex:35`. Runtime check raises `%Mailglass.Error{type: :stream_policy_violated, detail: %{rule: atom, suggestion: String.t}}` with informative messages. Existing call sites at `outbound.ex:291`, `:355`, `:509` require zero modification (the `with :ok <- Stream.policy_check(msg)` pattern already handles `{:error, _}` short-circuits). (Pitfall STREAM-03)
- [x] **STREAM-03**: Custom Credo check `Mailglass.Credo.StreamPolicyConsistent` flags compile-time stream-policy violations: tracking on `:transactional`, missing stream on `:bulk` mailables, `:operational` mailables with `List-Unsubscribe` opt-out missing. Follows the structure of existing `NoTrackingOnAuthStream` (`credo_checks/no_tracking_on_auth_stream.ex`) — both checks coexist (related but independent). 13th custom Credo check (LINT-13). (DF-V2-01; pitfalls STREAM-01
, STREAM-02)
- [x] **STREAM-04
**: Stream-aware Feedback-ID format `{sender_id}:{mailable}:{tenant_id}:{stream}` (DELIV-10 carried over from v0.5 candidates because it's small and ships free with stream work). Auto-injected when `feedback_id` is configured. (TS-V2-14)

#### List-Unsubscribe (Phase 11)

- [x] **UNSUB-01**: `Mailglass.Compliance.Unsubscribe` module mints + verifies signed tokens via `Phoenix.Token` with multi-salt rotation (minimum 2 salts during rotation window). Token payload is minimal — `delivery_id` only — so URL byte length stays ≤900 octets (well below RFC 5322 998-octet line limit). `byte_size(url) <= 900` assertion fails fast in `unsubscribe_url/2`. (TS-V2-08; pitfalls UNSUB-01
, UNSUB-03)
- [x] **UNSUB-02**: `Mailglass.Compliance.Unsubscribe.inject_unsubscribe_headers/2` is the **ONLY** code path that sets either `List-Unsubscribe` or `List-Unsubscribe-Post` on a Message. Both headers are injected atomically — both or neither, never one without the other. Custom Credo check `Mailglass.Credo.RequireAtomicUnsubscribeHeaders` enforces. `Mailglass.Compliance.add_rfc_required_headers/1` extended to call `inject_unsubscribe_headers/2` conditionally on `msg.stream`: mandatory on `:bulk`, opt-in on `:operational`, **never** on `:transactional`. (TS-V2-07; pitfall UNSUB-02 — Gmail/Yahoo bulk-sender silent compliance failure)
- [x] **UNSUB-03
**: `Mailglass.Compliance.UnsubscribeController` (Phoenix.Controller, **`mailglass` core package** — NOT `mailglass_admin`) handles `GET /mailglass/unsubscribe/:token` (confirmation page) + `POST /mailglass/unsubscribe/:token` (RFC 8058 one-click; returns 200 within 5 seconds; idempotent; no redirects per RFC). Persists `:unsubscribed` event to ledger via existing `Events.append_multi/3`. (TS-V2-08; pitfall UNSUB-04)
- [x] **UNSUB-04
**: `Mailglass.Router` macro mounts unsubscribe routes (`mailglass_router_routes "/mailglass"`) following the `MailglassAdmin.Router` pattern (PREV-02 reference). `mix mailglass.gen.unsubscribe` mix task prints mount instructions, config snippets, and a test recipe — does NOT copy code (unlike `mix mailglass.install`). Configurable path prefix; collision detection against adopter routes. (TS-V2-09; pitfall UNSUB-06)
- [x] **UNSUB-05**: StreamData property test (Phase 11 UAT): round-trip mint → verify across rotation boundary; expired-token rejection; one-click POST recorded as `:unsubscribed` event with idempotent insert; SSRF/open-redirect check on `unsubscribe_url/2`; List-Unsubscribe header present on `:bulk`, absent on `:transactional`, conditionally present on `:operational`. Integrates into the existing HOOK-07 1000-replay convergence property. (Pitfalls UNSUB-04
, UNSUB-05)
- [x] **UNSUB-06**: `guides/unsubscribe.md` ships with: adopter walkthrough; per-ESP DKIM `h=` verification (Postmark auto-includes both headers; SendGrid has known historical gap on `List-Unsubscribe-Post`, GitHub issue #893 — adopter must verify in their ESP diagnostics); rotation playbook; troubleshooting "user can't unsubscribe" scenarios. (DF-V2-03; pitfall UNSUB-05
)

#### Auto-Suppression (Phase 12)

- [ ] **SUPP-01**: `Mailglass.Suppression.AutoSuppress` extends `Mailglass.Webhook.Ingest.ingest_multi/3` with one new `Multi.run {:auto_suppress, idx}` step **AFTER** each `{:projector_apply, idx}` step. **Event row MUST be the FIRST step** in the Multi — suppression insert must follow, never precede, or replays leave orphan suppression rows with no event parent (breaks append-only ledger auditability). Custom Credo check `Mailglass.Credo.MultiEventFirstInWebhookIngest` enforces the ordering invariant at lint time. AutoSuppress calls `repo.insert/2` directly (flat-Multi anti-pattern lesson from v0.1's projector refactor); `on_conflict: :nothing` keeps replay convergence intact (HOOK-07 property test). Triggers on `:bounced` (hard), `:complained`, `:unsubscribed`. (TS-V2-10, TS-V2-11; pitfall SUPP-01 — CRITICAL)
- [ ] **SUPP-02**: `Mailglass.Suppression.Escalation` is an Oban worker (Oban OSS `~> 2.21` — Oban Pro NOT required) that evaluates the soft-bounce escalation rule asynchronously: configurable `{count, window_days, action}`; default `{5, 7, :hard_suppress}`. Anchor-to-now sliding window semantics documented exactly in `guides/suppression.md`. Synchronous evaluation forbidden (latency bomb under webhook bursts). Conditionally compiled via `Mailglass.OptionalDeps.Oban` gateway; `Task.Supervisor` fallback emits one `Logger.warning` at boot if Oban absent. Postgres covering index migration ships with this requirement. (TS-V2-12; pitfalls SUPP-02, SUPP-03)
- [ ] **SUPP-03**: `mix mailglass.suppressions.resync` mix task projects `mailglass_events` rows into `mailglass_suppressions` rows. **Requires `--tenant-id` flag** — task is per-tenant, NEVER cross-tenant. Goes through `Mailglass.Tenancy.scope/2` (LINT-03 enforces). Idempotent via UNIQUE constraint. Default time-window scan: last 90 days; `--from`/`--to` flags accept ISO-8601 timestamps. (TS-V2-13; pitfall SUPP-05 — CRITICAL cross-tenant data leak)
- [ ] **SUPP-04**: Pre-send `Mailglass.Suppression.check_before_send/1` tightened to default-deny on match. Returns structured `%Mailglass.Error{type: :suppressed, detail: %{reason: atom, source: atom, expires_at: DateTime.t() | nil}}`. Telemetry emits `[:mailglass, :suppression, :auto_added, :stop]` and `[:mailglass, :suppression, :pre_send_blocked, :stop]` with whitelisted metadata (no PII per CORE-03).
- [ ] **SUPP-05**: `:complained` suppression is **permanent** and non-reversible. Postgres check constraint `CHECK (reason != 'complained' OR expires_at IS NULL)` enforces. `Mailglass.Suppression.remove/2` rejects `:complained` reason at the API layer with structured error. GDPR right-to-be-forgotten requires DELETE on the source delivery records, but suppression row stays (compliance audit trail). (Pitfall SUPP-04 — CRITICAL)

### Pillar C — Release-Engineering Hardening

#### Phase 8 — Close v0.1.2 debt + re-tighten gates

- [ ] **REL-01**: `publish-hex.yml` and `post-publish-smoke.yml` triggers switch from `on: workflow_run` (with dead `head_branch` gate) to `on: release: types: [published]`. NOT `on: push: tags:` — that fires on workflow rerun and would double-publish. `mix hex.info` pre-check inside the publish job acts as additional idempotency guard (skips publish if version already on Hex). (Pitfall REL-01 — CRITICAL)
- [ ] **REL-02**: HexDocs hygiene — `CLAUDE.md` removed from `mix.exs:262` `extras:` and `mix.exs:265` `groups_for_extras:` for both `mailglass` and `mailglass_admin`. Internal `D-NN`/`LINT-NN` IDs stripped from public guides (`guides/*.md`); `mix mailglass.docs.check` grep gate in CI fails the build if any internal ID leaks into the rendered docs.
- [ ] **REL-03**: `mix verify.phase_NN` aliases renamed to semantic names: `verify.phase_01` → `verify.foundation`, `verify.phase_02` → `verify.persistence`, `verify.phase_03` → `verify.send_pipeline`, `verify.phase_04` → `verify.webhooks`, `verify.phase_05` → `verify.preview`, `verify.phase_06` → `verify.lint`, `verify.phase_07` → `verify.installer`. Old aliases kept as deprecated pass-through for one cycle.
- [ ] **REL-04**: Installer goldens wired into `mix mailglass.publish.check` so version bumps fail pre-publish (not at post-merge CI). Closes v0.1.2 TODO `add-installer-goldens-to-publish-check.md`.
- [ ] **REL-05**: Release Please managed-mix-exs `extra-files` no-op resolution: either consolidate the Path 2 `sed` step into a maintained release-please plugin, or document the workflow-level mitigation permanently in `CONTRIBUTING.md`. Decided in plan.
- [ ] **REL-06**: Advisory Matrix DB-setup + Elixir 1.17 compile failures fixed. `provider-live.yml` runs cleanly in nightly cron (still advisory; failures notify, never block PRs).
- [ ] **REL-07**: Installer manifest drift detection — unskip the 2 `install_idempotency` tests that were skipped during v0.1 ship. Managed-snippet drift fails the test if installer-generated content diverges from the manifest.
- [ ] **REL-08**: 6 closed Dependabot PRs re-batched (setup-beam, checkout, cache, sigra, dependency-review-action, actionlint). Each PR re-tested against current `mix.lock` before merge.
- [ ] **REL-09**: All third-party GitHub Actions SHA pins refreshed for 2026-Q2 (CI-06 maintenance).
- [ ] **REL-10**: Tests gate re-tightened from `continue-on-error: true` to halt-on-failure. Sandbox + `Task.Supervisor` test isolation cleanup ships first; `MailerCase.async_adapter` env isolation hardened (HI-01 pattern from Phase 03-10 carried forward); citext-OID-cache race fixed for bare `mix test` (currently clean only in `--only phase_NN_uat` scope). (Pitfall REL-03)
- [ ] **REL-11**: Credo `--strict` enabled (currently `false`). Strict baseline residuals documented in `.credo.exs` `:disabled_checks` with reasoning comments; aim for zero suppressions, but each kept suppression cites a specific rule + reason. (Pitfall REL-04)
- [ ] **REL-12**: Dialyzer re-tightened by **REMOVING `--ignore-exit-status`** from `ci.yml` (not adding `--halt-exit-status` — that flag does NOT exist in Dialyxir; the default `mix dialyzer` already halts on warnings). Triage budget: 230 residual findings → ≤15 documented `.dialyzer_ignore.exs` entries with comments explaining why each is kept. Each ignore entry is a deliberate decision, not a blanket suppression. (Pitfall REL-02 — CRITICAL FLAG CORRECTION)

#### Phase 13 — Release ceremony

- [ ] **REL-13**: CHANGELOG narrative for `mailglass` 0.2.0 + `mailglass_admin` 0.2.0 — feature highlights; breaking-change list (Mailable API redesign); upgrade walkthrough referencing `mix mailglass.upgrade.v0_2`; minimum dep matrix; rollback procedure.
- [ ] **REL-14**: Adopter walkthrough validation — fresh Phoenix 1.8.5 host runs `mix mailglass.install` then `mix mailglass.upgrade.v0_2` from a v0.1 fixture project; assert zero manual edits required for non-ambiguous cases; ambiguous cases emit clear `IO.warn` with migration guide URL.
- [ ] **REL-15**: Doc audit — all 9 v0.1 guides updated for v0.2 surface; `migration-from-swoosh.md` retargeted to v0.2 native Message API; new `upgrading-from-v0_1.md` finalized; `dkim-setup.md` ships covering per-ESP `List-Unsubscribe` DKIM `h=` verification.
- [ ] **REL-16**: Release Please bump → 0.2.0 across both packages via linked-versions; tarball whitelist + size budgets verified (<500KB `mailglass`, <2MB `mailglass_admin`); Hex publish from protected ref + GitHub Environment with required reviewer; HexDocs verification + post-publish smoke (`curl -fsI https://hexdocs.pm/mailglass/0.2.0/`).

---

## Future Requirements (deferred to v0.3+, tracked but not in current execution roadmap)

### v0.3 — Webhook Coverage Expansion

- **DELIV-04**: Webhook normalization extended to `Mailglass.Webhook.Providers.{Mailgun, SES, Resend}`. Mailgun: HMAC-SHA256. SES: SNS subscription confirmation + signature. Resend: provider-specific signing. Closes "batteries-included webhook coverage" claim across major Anymail providers.

### v0.5 — Deliverability + Admin Wave

- **DELIV-05**: Prod-mountable admin LiveView (`mailglass_admin` v0.5): sent-mail browser (stream-based, paginated, filterable by tenant/recipient/status/date); per-delivery event timeline with raw + normalized payloads; suppression management UI (list, add, remove with reason audit); one-click resend with idempotency key bump; replay webhook from raw payload. Step-up auth on destructive actions via sigra/PhxGenAuth integration.
- **DELIV-06**: `mix mail.doctor` — live DNS deliverability checks: SPF lookup count <10, DKIM selector exists + key valid, DMARC `p=` policy, MX records, BIMI hint. Output: actionable per-domain report with severity.
- **DELIV-07**: Per-tenant adapter resolver — different ESPs per customer. `Mailglass.AdapterRegistry` caches resolved adapters per `(tenant_id, scope)`.
- **DELIV-08**: Per-domain rate limiting promoted from ETS-only to `:pg`-coordinated when cluster-coordinated limits required (defer evaluation to v0.5 with empirical benchmark).
- **DELIV-09**: DKIM signing helper for self-hosted SMTP relay use case. Pass-through for ESPs (they sign with their key).

### v0.5+ — Inbound (`mailglass_inbound` separate sibling package)

- **INBOUND-01**: `Mailglass.Inbound.Router` DSL with recipient regex, subject pattern, header matcher, function matcher.
- **INBOUND-02**: `Mailglass.Inbound.Mailbox` behaviour: `before_process/1`, `process/1`, `bounce_with/2`. Handlers respond `:accept | :reject | :ignore | {:bounce, reason}`.
- **INBOUND-03**: Ingress plugs for Postmark (JSON), SendGrid (multipart), Mailgun (form/MIME), SES (SNS). Each verifies signature + parses to `%InboundMessage{}`.
- **INBOUND-04**: SMTP relay ingress via `gen_smtp` for self-hosted scenarios.
- **INBOUND-05**: `Mailglass.Inbound.Storage` behaviour. Default `LocalFS` impl + reference S3 impl preserve raw MIME for replay. Configurable retention + incineration.
- **INBOUND-06**: Async routing via Oban. Each inbound message becomes one Oban job that runs the matching mailbox handler.
- **INBOUND-07**: `Mailglass.Inbound.Conductor` dev LiveView — synthesize inbound messages from fixtures, replay stored messages through router for debugging.

---

## Out of Scope (carried over from v0.1; permanent)

Explicitly excluded with permanent reasoning. Anti-features documented to prevent re-litigation. Full table in `PROJECT.md` Out of Scope section.

**v0.2-specific anti-features** (new in this milestone):

| Anti-feature | Reason |
|--------------|--------|
| **Preference center as List-Unsubscribe target** (AF-V2-01) | RFC 8058 non-compliant; Google rejects it; that's a v0.5+ admin feature, not a v0.2 List-Unsubscribe path. |
| **Auto-unsuppression on user re-engagement** (AF-V2-02) | CAN-SPAM/GDPR legal hazard; deliverability anti-pattern. Suppression removal is a deliberate adopter action via `Mailglass.Suppression.remove/2` (which refuses `:complained`). |
| **List-Unsubscribe on `:transactional` stream** (AF-V2-03) | Signals password resets are optional (they are not). Stream policy enforces. |
| **JWT tokens for unsubscribe** (AF-V2-04) | `Phoenix.Token` is strictly better in-Phoenix; JWT adds unnecessary dep + complexity. |
| **First-soft-bounce suppression** (AF-V2-05) | Causes false suppressions on legitimate transactional mail. Default escalation `(5, 7d, :hard_suppress)` is more lenient than broadcast norms. |
| **Codemod auto-merge into adopter codebases** (AF-V2-06) | High blast radius; default is dry-run; `--apply` is explicit. |
| **Removing `update_swoosh/2`** (AF-V2-07) | Documented escape hatch; needed for adapter-specific features mailglass doesn't wrap. |
| **Compile-time-only stream check** (AF-V2-08) | Runtime-set `%Message{stream:}` would bypass; both compile and runtime checks ship. |

**Permanent exclusions** (carried over from v0.1, validated this milestone):

- Marketing email (D-03)
- Single-pane multi-channel notifications (D-04)
- AMP for Email (Cloudflare sunset Oct 2025)
- MJML as default rendering path (D-18 — opt-in via `:mjml` Hex package only)
- Standalone ops console / SaaS dashboard
- Backwards compatibility with Bamboo APIs
- Pre-Phoenix-1.8 / pre-LiveView-1.0 / pre-Elixir-1.18 support (D-06)
- Custom SMTP server
- MySQL/SQLite support
- Open/click tracking on by default (D-08)
- Open core / paid Pro tier (D-02)
- Hosted SaaS Pro tier

---

## Traceability

38/38 v0.2 requirements mapped to exactly one phase. No orphans, no duplicates.

| Requirement | Phase | Status |
|-------------|-------|--------|
| API-01 | Phase 9 | Pending |
| API-02 | Phase 9 | Pending |
| API-03 | Phase 9 | Pending |
| API-04 | Phase 9 | Pending |
| API-05 | Phase 9 | Pending |
| API-06 | Phase 9 | Pending |
| API-07 | Phase 9 | Pending |
| STREAM-01 | Phase 10 | Pending |
| STREAM-02 | Phase 10 | Pending |
| STREAM-03 | Phase 10 | Pending |
| STREAM-04 | Phase 10 | Pending |
| UNSUB-01 | Phase 11 | Complete |
| UNSUB-02 | Phase 11 | Complete |
| UNSUB-03 | Phase 11 | Complete |
| UNSUB-04 | Phase 11 | Complete |
| UNSUB-05 | Phase 11 | Complete |
| UNSUB-06 | Phase 11 | Complete |
| SUPP-01 | Phase 12 | Pending |
| SUPP-02 | Phase 12 | Pending |
| SUPP-03 | Phase 12 | Pending |
| SUPP-04 | Phase 12 | Pending |
| SUPP-05 | Phase 12 | Pending |
| REL-01 | Phase 8 | Pending |
| REL-02 | Phase 8 | Pending |
| REL-03 | Phase 8 | Pending |
| REL-04 | Phase 8 | Pending |
| REL-05 | Phase 8 | Pending |
| REL-06 | Phase 8 | Pending |
| REL-07 | Phase 8 | Pending |
| REL-08 | Phase 8 | Pending |
| REL-09 | Phase 8 | Pending |
| REL-10 | Phase 8 | Pending |
| REL-11 | Phase 8 | Pending |
| REL-12 | Phase 8 | Pending |
| REL-13 | Phase 13 | Pending |
| REL-14 | Phase 13 | Pending |
| REL-15 | Phase 13 | Pending |
| REL-16 | Phase 13 | Pending |

**Coverage:**
- v0.2 requirements: 38 total (API: 7, STREAM: 4, UNSUB: 6, SUPP: 5, REL: 16)
- Mapped to phases: 38 / 38
- Unmapped: 0

**Phase breakdown:**
- Phase 8: REL-01..12 (12 requirements)
- Phase 9: API-01..07 (7 requirements)
- Phase 10: STREAM-01..04 (4 requirements)
- Phase 11: UNSUB-01..06 (6 requirements)
- Phase 12: SUPP-01..05 (5 requirements)
- Phase 13: REL-13..16 (4 requirements)

---

*Requirements defined: 2026-04-26*
*Traceability populated: 2026-04-26 (gsd-roadmapper)*
*Source: research/SUMMARY.md + research/PITFALLS.md (5 corrections folded in: Dialyzer flag subtraction, `on: release:` trigger, Multi event-first ordering, controller in core, `mailable.ex:129` injection site).*
