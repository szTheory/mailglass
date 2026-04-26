# Project Research Summary

**Project:** mailglass v0.2 — Production-Credible Core
**Domain:** Phoenix-native transactional email framework (subsequent milestone; v0.1.1 shipped 2026-04-26)
**Researched:** 2026-04-26
**Confidence:** HIGH

> *Synthesized from STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md (v0.2 editions). v0.1 research archived in `.planning/milestones/v0.1-research/`. Read this single page to plan phases 8–13; reach into the four research files for implementation detail.*

---

## Executive Summary

v0.2 is not a greenfield milestone. It is an incremental addition to a shipped, Hex-published codebase (~33k LOC, 319 commits, 84/84 v1 REQ-IDs satisfied). The work divides into three pillars of unequal urgency: (1) **API stability** — downstream OSS packages (`accrue` and others) are about to pin to mailglass; every breaking change after v0.2 multiplies cost across all downstream pinners; this is the single highest-leverage action in the milestone. (2) **Deliverability floor** — RFC 8058 List-Unsubscribe + auto-suppression are legally required under Gmail/Yahoo/Microsoft 2024–2025 bulk-sender enforcement; they are correctness requirements, not features. (3) **Release-engineering hardening** — 9 v0.1.2 TODOs accumulated during the v0.1.1 ship; closing them makes the sibling-release pipeline trustworthy before downstream pinners depend on it.

The recommended implementation approach is evolutionary, not rewriting. Five v0.2 additions slot into existing module boundaries without rewriting them: the Mailable API redesign removes `import Swoosh.Email` at a single line (`mailable.ex:129`); stream policy fills an existing no-op seam (`stream.ex:35`); RFC 8058 headers extend the existing compliance pipeline (`add_rfc_required_headers/1`); auto-suppression slots as a new `Multi.run` step after each `{:projector_apply, idx}` in the existing webhook ingest Multi; and the codemod generator adds a new mix task. One new dev dep (`{:igniter, "~> 0.7", only: [:dev], runtime: false}`) — that is the only `mix.exs` change.

**Five corrections to existing planning docs must propagate into phase plans before work begins.** (A) The Dialyzer flag in STATE.md/PROJECT.md is wrong: `--halt-exit-status` does not exist in Dialyxir; the default `mix dialyzer` already halts on warnings; re-tightening means REMOVING `--ignore-exit-status`, not adding a flag. (B) The publish-hex workflow trigger must switch from `on: push: tags:` to `on: release: types: [published]` to prevent double-publish on workflow rerun (PITFALLS REL-01). (C) The event row MUST be the first `Ecto.Multi` step in webhook ingest; suppression insert must follow, never precede it, or replays leave orphan suppression rows with no event parent (PITFALLS SUPP-01). (D) The unsubscribe controller belongs in `mailglass` core, not `mailglass_admin` — Phoenix.Controller is already a hard dep; adopters running headless need RFC 8058 POST handling before v0.5 admin ships. (E) The Mailable macro injection site is `lib/mailglass/mailable.ex:129` — single-line removal of `import Swoosh.Email, except: [new: 0]`.

---

## Key Findings

### Recommended Stack

The v0.1 stack is fully validated and unchanged. v0.2 adds exactly one new dep: `{:igniter, "~> 0.7", only: [:dev], runtime: false}` as the codemod foundation for `mix mailglass.upgrade.v0_2`. Igniter (v0.7.9, April 2026, Ash Framework / Zach Daniel) is the 2026 ecosystem standard for mix-task-based AST-safe codemods — it wraps Sourceror and provides dry-run, interactive prompts, and file batching that raw Sourceror does not.

**Stack additions and corrections for v0.2:**

- `{:igniter, "~> 0.7", only: [:dev], runtime: false}` — codemod foundation; only new dep
- `@deprecated` attribute — built into Elixir 1.18+; zero new dep for one-cycle BC warnings
- `Phoenix.Token` — already a hard dep; covers RFC 8058 signed unsubscribe tokens with no additions
- Oban OSS `~> 2.21` — already optional dep; `schedule_in: {7, :days}` covers soft-bounce escalation; Oban Pro NOT required
- Dialyxir re-tightening — remove `--ignore-exit-status` from CI (it is the advisory flag); the default `mix dialyzer` already halts on warnings
- `googleapis/release-please-action` v5.0.0 (released 2026-04-22) — evaluate upgrade; only breaking change is Node 24 runtime; Elixir release-type continuity not yet confirmed (MEDIUM confidence)

**What NOT to add:** No RFC 8058 Hex package exists (build in 2 functions); no Oban Pro; no DKIM signing library (DKIM `h=` is controlled by the ESP, not the app layer); no JWT libraries (Phoenix.Token is correct for in-Phoenix tokens).

See [STACK.md](STACK.md) for full verification, flag corrections, and actions/checkout SHA guidance.

### Expected Features

v0.2 ships 14 table-stakes features (TS-V2-01..14) and 5 differentiators (DF-V2-01..05). All 14 TS items are P1 and ship-blocking for the milestone promise. The feature dependency tree is strict: stream separation must land before RFC 8058; native Message setters must land before deprecation warnings and the codemod; webhook ingest (v0.1, already built) is a hard prerequisite for auto-suppression.

**Table stakes (all P1, all required for milestone promise):**

- **TS-V2-01** Native `Mailglass.Message` field setters: `to/2`, `from/2`, `subject/2`, `html_body/2`, `text_body/2`, `header/3`, `attach/2`, `put_tag/2` — hides Swoosh from adopter call sites
- **TS-V2-02** `update_swoosh/2` retained as named, documented escape hatch — must NOT be removed or deprecated
- **TS-V2-03** `api_stability.md` v2 — explicit public-surface freeze; machine-readable contract for downstream pinners
- **TS-V2-04** Deprecation warnings on v0.1 `import Swoosh.Email` paths — one-cycle BC for `~> 0.1` adopters
- **TS-V2-05** `mix mailglass.upgrade.v0_2` codemod (Igniter/Sourceror AST-safe; ambiguous cases warn+skip, never silent-corrupt)
- **TS-V2-06** Message-stream separation: `:transactional`/`:operational`/`:bulk` with compile + runtime enforcement
- **TS-V2-07** RFC 8058 List-Unsubscribe auto-injection on `:bulk` (mandatory), opt-in on `:operational` — both headers atomically via single function only; NEVER on `:transactional`
- **TS-V2-08** Signed-token unsubscribe controller (`Phoenix.Token`, multi-salt rotation, idempotent POST)
- **TS-V2-09** `mix mailglass.gen.unsubscribe` generator — configurable path prefix `/mailglass/unsubscribe/:token` (not bare `/unsubscribe`)
- **TS-V2-10/11** Auto-suppress on `:bounced`/`:complained`/`:unsubscribed` — inside the webhook ingest Multi, event row FIRST
- **TS-V2-12** Soft-bounce escalation: configurable threshold (default 5 in 7 days), async Oban worker; `:complained` suppression is permanent and non-reversible (Postgres check constraint)
- **TS-V2-13** `mix mailglass.suppressions.resync` — must require `--tenant-id` flag; never cross-tenant
- **TS-V2-14** Feedback-ID stream-aware format update (stream slot added)

**Differentiators:**

- **DF-V2-01** `NoUnstreamedBulkMailable` Credo check — compile-time stream policy; no other Elixir email framework does this
- **DF-V2-02** `update_swoosh/2` named to signal escape — discourages casual use by name design
- **DF-V2-03** In-app unsubscribe controller (vs ESP-hosted) — brand control + audit trail in adopter's event ledger
- **DF-V2-04** `suppressions.resync` as explicit projection rebuild — teaches event-sourcing discipline
- **DF-V2-05** Igniter-based AST-safe codemod — not a bash sed script

**Defer to v0.3+:** Webhook coverage expansion (Mailgun/SES/Resend), preference center generator, granular stream-level unsubscribe.

See [FEATURES.md](FEATURES.md) for full TS-V2-/DF-V2-/AF-V2- catalog, dependency graph, and competitor comparison.

### Architecture Approach

All v0.2 changes integrate into existing module boundaries without rewrites. Eight new modules; eight existing modules modified; one migration. The webhook ingest Multi gains `{:auto_suppress, idx}` steps; the send pipeline gains real stream enforcement at the existing no-op seam; the compliance pipeline gains conditional header injection.

**New modules (v0.2):**

1. `Mailglass.Compliance.Unsubscribe` — token sign/verify (Phase 11)
2. `Mailglass.Compliance.UnsubscribeController` — Phoenix.Controller, core package (Phase 11)
3. `Mailglass.Router` — macro that mounts unsubscribe routes (Phase 11)
4. `Mailglass.Suppression.AutoSuppress` — Multi.run step, pure Repo insert (Phase 12)
5. `Mailglass.Suppression.Escalation` — Oban worker for soft-bounce threshold (Phase 12)
6. `lib/mix/tasks/mailglass.upgrade.v0_2.ex` — Igniter codemod task (Phase 9)
7. `lib/mix/tasks/mailglass.suppressions.resync.ex` — projection rebuild task (Phase 12)
8. `credo_checks/stream_policy_consistent.ex` — new Credo check (Phase 10)

**Critical boundary rule:** `Mailglass.Suppression.AutoSuppress` must NOT depend on `Mailglass.Webhook.Ingest`. Direction: `Webhook.Ingest → Suppression.AutoSuppress`, never the reverse. AutoSuppress calls `repo.insert` directly — no nested Multi. Unsubscribe controller must NOT depend on `Mailglass.Outbound`.

See [ARCHITECTURE.md](ARCHITECTURE.md) for exact line references, data flow diagrams, and boundary contract additions.

### Critical Pitfalls

22 new pitfalls (6 CRITICAL, 12 HIGH, 4 MEDIUM). v0.1 pitfall catalog (42 pitfalls) archived separately.

1. **SUPP-01 (CRITICAL)** — Event row MUST be first Multi step in webhook ingest. Suppression before event = replay creates orphan suppression rows with no event parent. Prevention: custom Credo check `MultiEventFirstInWebhookIngest`.

2. **REL-01 (CRITICAL)** — `on: push: tags:` trigger fires on workflow rerun → double-publish. Fix: switch to `on: release: types: [published]` + `mix hex.info` pre-check.

3. **UNSUB-02 (CRITICAL)** — `List-Unsubscribe-Post` omitted on `:bulk` — silent Gmail/Yahoo compliance failure. Prevention: `inject_unsubscribe_headers/2` is the ONLY path to setting EITHER header; Credo check `RequireAtomicUnsubscribeHeaders`.

4. **SUPP-04 (CRITICAL)** — `:complained` suppression mistakenly treated as reversible. Prevention: Postgres check constraint `CHECK (reason != 'complained' OR expires_at IS NULL)`; `Suppression.remove/2` refuses `:complained`.

5. **SUPP-05 (CRITICAL)** — `suppressions.resync` cross-tenant data leak. Prevention: `--tenant-id` flag required; task goes through `Mailglass.Tenancy.scope/2`.

6. **UNSUB-01 (CRITICAL)** — List-Unsubscribe URL exceeds RFC 5322 998-octet limit. Prevention: token payload minimal (delivery_id only); `byte_size(url) <= 900` assertion in `unsubscribe_url/2`.

7. **API-03 (HIGH)** — `update_swoosh/2` accidentally removed. Prevention: named in `api_stability.md` v2; codemod must NOT touch it.

8. **REL-02 (HIGH)** — Dialyzer 230 residual findings. Prevention: Phase 8 triage budget; `.dialyzer_ignore.exs` entries require comments; target <15 entries.

See [PITFALLS.md](PITFALLS.md) for all 22 v0.2 pitfalls with phase mapping and prevention strategies.

---

## Implications for Roadmap

### Validated Build Order: Phase 8 → 9 → 10 → 11 → 12 → 13

This order is validated and locked. No inversions are safer.

**Phase 8 first:** Quality gates (Dialyzer, Credo strict, Tests halt-on-failure) must be enforced before any API-freezing work. Re-tightening Dialyzer = REMOVING `--ignore-exit-status` from CI — the default `mix dialyzer` already halts on warnings. This is subtraction, not addition.

**Phase 9 before Phase 10:** The `StreamPolicyConsistent` Credo check (Phase 10) reads the `use Mailglass.Mailable` macro shape. Phase 9 changes the macro (removes `import Swoosh.Email`). If Phase 10 ran first, its check would reference the old macro shape and require a rewrite.

**Phase 10 before Phase 11:** RFC 8058 header injection is stream-conditional. `add_rfc_required_headers/1` reads `msg.stream`. Stream policy enforcement from Phase 10 guarantees `msg.stream` is validated before Phase 11 reads it.

**Phase 11 before Phase 12:** The full unsubscribe lifecycle (header injected → user clicks → POST received → suppression inserted) must be testable end-to-end before Phase 12 covers the `:unsubscribed` event type. Auto-suppression for `:bounced`/`:complained` could technically precede Phase 11, but the batteries-included promise requires the full loop.

**Phase 13 last:** Coordinated release depends on all of 8–12 complete.

---

### Phase 8: Release-Engineering Hardening

**Rationale:** Close v0.1.2 debt and re-tighten quality gates before API-freezing work.

**Delivers:** Close 9 v0.1.2 TODOs (CLAUDE.md exclusion from HexDocs; publish trigger `on: release:`; installer-goldens wired; verify aliases renamed; D-NN/LINT-NN stripped from guides; Advisory Matrix fixes; managed-snippet drift detection); remove `continue-on-error: true` from Tests gate; enable `mix credo --strict`; Dialyzer triage (~230 findings → <15 annotated ignores); Dependabot PR batch; SHA pin updates.

**TS addressed:** REL-01, REL-02, CROSS-02 pitfalls.

**KEY CORRECTIONS IN THIS PHASE:**
- Dialyzer: REMOVE `--ignore-exit-status` from CI command. That is all. No new flag.
- Publish trigger: Use `on: release: types: [published]`, NOT `on: push: tags:`.

---

### Phase 9: Mailable API Redesign + Freeze

**Rationale:** Highest-leverage phase — downstream pinners are waiting on this.

**Delivers:** Remove `import Swoosh.Email, except: [new: 0]` at `mailable.ex:129`; add 8 native field setters to `Mailglass.Message`; retain `update_swoosh/2` as documented escape hatch; `@deprecated` compile-time warnings (zero new dep); `mix mailglass.upgrade.v0_2` Igniter codemod (AST-safe, ambiguous → warn+skip); `api_stability.md` v2; `guides/migration-v0-2.md`.

**TS addressed:** TS-V2-01, TS-V2-02, TS-V2-03, TS-V2-04, TS-V2-05; DF-V2-02, DF-V2-05.

**Pitfalls:** API-01 (internal helper accidentally frozen), API-02 (codemod silent rewrite), API-03 (update_swoosh/2 removed), API-04 (guide doctests not updated).

---

### Phase 10: Stream Policy Implementation

**Rationale:** Fills the existing no-op seam at `stream.ex:35`. Gates RFC 8058.

**Delivers:** Real `Mailglass.Stream.policy_check/1`; `credo_checks/stream_policy_consistent.ex`; runtime `StreamPolicyError` with structured `:detail` map (rule atom + suggestion string); `NoUnstreamedBulkMailable` Credo check; updated boundary tests.

**TS addressed:** TS-V2-06, TS-V2-14; DF-V2-01.

**Pitfalls:** STREAM-01 (`:transactional` misclassified), STREAM-02 (runtime override bypasses compile check), STREAM-03 (error message uninformative).

---

### Phase 11: RFC 8058 List-Unsubscribe

**Rationale:** Deliverability floor. Controller in CORE (not admin) — Phoenix.Controller is already a hard dep; headless adopters need RFC 8058 POST handling before v0.5 admin. Headers injected atomically — BOTH or NEITHER.

**Delivers:** `Mailglass.Compliance.Unsubscribe` (token sign/verify, multi-salt rotation); `Mailglass.Compliance.UnsubscribeController` (GET + POST, core package); `Mailglass.Router` macro (`/mailglass/unsubscribe/:token`); `mix mailglass.gen.unsubscribe` (configurable path prefix, collision detection); `inject_unsubscribe_headers/2` as atomic single-function path; extended `add_rfc_required_headers/1`; `guides/dkim-setup.md`; root boundary export additions.

**TS addressed:** TS-V2-07, TS-V2-08, TS-V2-09; DF-V2-03.

**Pitfalls:** UNSUB-01 (URL >998 octets), UNSUB-02 (`List-Unsubscribe-Post` omitted), UNSUB-03 (rotated salt breaks in-flight links), UNSUB-04 (slow POST → provider retries), UNSUB-05 (DKIM `h=` missing), UNSUB-06 (route collision).

---

### Phase 12: Auto-Suppression + Soft-Bounce Escalation

**Rationale:** Completes the deliverability floor. Event row FIRST in Multi, always. Suppression on `:complained` is permanent (Postgres constraint). Resync scoped to single tenant.

**Delivers:** `Mailglass.Suppression.AutoSuppress` (`Multi.run {:auto_suppress, idx}` after `{:projector_apply, idx}`; `on_conflict: :nothing`); `Mailglass.Suppression.Escalation` (Oban worker, async, with covering index migration); `mix mailglass.suppressions.resync` (requires `--tenant-id`; uses `Tenancy.scope/2`); soft-bounce escalation with anchor-to-now sliding window documented exactly; Postgres check constraint on `:complained`; `Suppression.remove/2` rejects `:complained`; boundary test additions.

**TS addressed:** TS-V2-10, TS-V2-11, TS-V2-12, TS-V2-13.

**Pitfalls:** SUPP-01 (suppression before event in Multi), SUPP-02 (escalation synchronous), SUPP-03 (window semantics ambiguous), SUPP-04 (`:complained` reversible misread), SUPP-05 (resync cross-tenant), CROSS-01 (Multi chain > 4 steps).

---

### Phase 13: Release Ceremony

**Rationale:** Coordinated sibling release, linked versions, protected-ref publish.

**Delivers:** CHANGELOG review; `mix hex.info` pre-check as idempotency guard; coordinated publish via Release Please; dep conflict table in migration guide; SHA pin updates; post-publish smoke verification.

**Pitfalls:** REL-01 (already fixed in Phase 8), CROSS-02 (dep conflict matrix).

---

### Research Flags

**Standard patterns — plan directly (no `/gsd-research-phase` needed):**

- **Phase 8:** Release-engineering patterns 4-of-4 convergent; corrections documented above; execution is mechanical.
- **Phase 9:** Mailable injection site exact (`mailable.ex:129`); Igniter API verified; `update_swoosh/2` contract already in `api_stability.md`. Plan directly.
- **Phase 10:** Stream seam location verified (`stream.ex:35`); Credo check structure identical to existing `NoTrackingOnAuthStream`. Plan directly.
- **Phase 13:** Identical to v0.1.1 ship ceremony, refined with REL-01 fix. Plan directly.

**Open questions to resolve at planning time:**

- **Phase 11:** (a) Token rotation strategy — reuse Phoenix.Endpoint signing key or require separate `config :mailglass, :unsubscribe_signing_key`? (b) DKIM `h=` per-ESP: SendGrid historically omitted `List-Unsubscribe-Post` from `h=` (GitHub issue #893, MEDIUM confidence); documentation must cover per-ESP verification.
- **Phase 12:** (a) Soft-bounce event type: Anymail maps soft bounces as `:deferred`, not `:bounced` with soft subtype; audit existing v0.1 provider mappers before implementing escalation. (b) Resync task time window: scan all historical events or only last N days?

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All deps verified Hex.pm 2026-04-26; Dialyzer flag correction verified against Dialyxir 1.4.7 docs; release-please-action v5 Elixir continuity is MEDIUM |
| Features | HIGH | RFC 8058 verified against IETF datatracker; suppression behavior modeled against Anymail/Postmark/SendGrid docs; framework comparison grounded in ActionMailer/Laravel/Symfony docs |
| Architecture | HIGH | All integration points grounded in exact line references to shipped v0.1 source; build order validated via dependency chain analysis |
| Pitfalls | HIGH | 22 pitfalls grounded in RFC analysis, Elixir/Phoenix library experience, and exact v0.1 codebase knowledge; 6 CRITICAL pitfalls have Postgres-level enforcement strategies |

**Overall confidence: HIGH.** The v0.1 codebase is the primary source — all integration points are exact file/line references, not estimates.

### Gaps to Address

- **DKIM `h=` per-ESP (Phase 11):** Postmark auto-includes `List-Unsubscribe`; SendGrid has a known gap for `List-Unsubscribe-Post` (GitHub issue #893). Phase 11 must include per-ESP verification guidance. Cannot resolve until Phase 11 scoping.
- **Soft-bounce event type from v0.1 mappers (Phase 12):** Anymail taxonomy maps soft bounces as `:deferred` events. Phase 12 must audit existing Postmark/SendGrid mapper implementations before implementing escalation logic.
- **Igniter dev-dep gating (Phase 9):** Confirm whether `only: [:dev]` is sufficient for codemod integration tests or whether `:test` must also be included.
- **release-please-action v5.0.0 (Phase 8):** Released 2026-04-22. Elixir release-type support not explicitly confirmed. Evaluate on a branch before committing to the upgrade.

---

## Sources

### Primary (HIGH confidence)

- `.planning/research/STACK.md` — v0.2 stack additions, Dialyzer flag correction, Igniter verification
- `.planning/research/FEATURES.md` — TS-V2-01..14, DF-V2-01..05, AF-V2-01..08, RFC 8058 spec
- `.planning/research/ARCHITECTURE.md` — exact line refs, module inventory, build order validation
- `.planning/research/PITFALLS.md` — 22 v0.2 pitfalls with phase mapping
- `.planning/PROJECT.md` — v0.2 milestone spec, locked decisions
- `.planning/STATE.md` — pending TODOs, deferred items
- RFC 8058 — https://datatracker.ietf.org/doc/html/rfc8058
- Dialyxir 1.4.7 — https://hexdocs.pm/dialyxir/Mix.Tasks.Dialyzer.html (flag verification)
- Phoenix.Token — https://hexdocs.pm/phoenix/Phoenix.Token.html (Phoenix 1.8.5)
- Igniter 0.7.9 — https://hex.pm/packages/igniter, https://hexdocs.pm/igniter/readme.html
- Oban 2.21.1 — https://hexdocs.pm/oban/Oban.Job.html (schedule_in verification)

### Secondary (MEDIUM confidence)

- SendGrid GitHub issue #893 — DKIM `h=` / `List-Unsubscribe-Post` coverage gap
- `googleapis/release-please-action` v5.0.0 release notes (2026-04-22) — Elixir continuity unconfirmed
- `.planning/milestones/v0.1-research/SUMMARY.md` — v0.1 baseline for contrast

---
*Research completed: 2026-04-26*
*Ready for roadmap: yes*
