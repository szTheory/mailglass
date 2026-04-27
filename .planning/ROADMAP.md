# Roadmap: mailglass

**Granularity:** standard (config.json)
**Sibling package out of milestone:** `mailglass_inbound` (v0.5+, not roadmapped here)

## Milestones

- ✅ **v0.1 Validation Release** — Phases 1–7 + 07.1 (shipped 2026-04-26) — see [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- 🚧 **v0.2 Production-Credible Core** — Phases 8–13 (in progress)

## Phases

<details>
<summary>✅ v0.1 Validation Release (Phases 1–07.1) — SHIPPED 2026-04-26</summary>

- [x] Phase 1: Foundation (6/6 plans) — completed 2026-04-22
- [x] Phase 2: Persistence + Tenancy (6/6 plans) — completed 2026-04-22
- [x] Phase 3: Transport + Send Pipeline (12/12 plans) — completed 2026-04-23
- [x] Phase 4: Webhook Ingest (9/9 plans) — completed 2026-04-24
- [x] Phase 5: Dev Preview LiveView (6/6 plans) — completed 2026-04-25
- [x] Phase 6: Custom Credo + Boundary (6/6 plans) — completed 2026-04-24
- [x] Phase 7: Installer + CI/CD + Docs (5/5 plans) — completed 2026-04-25
- [x] Phase 07.1: Publish to Hex.pm (INSERTED) (11/11 plans) — completed 2026-04-26

Total: 8 phases, 61 plans. Hex.pm: `mailglass` 0.1.0 + 0.1.1, `mailglass_admin` 0.1.0 + 0.1.1.

Full details: [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md).

</details>

### 🚧 v0.2 Production-Credible Core (In Progress)

**Milestone Goal:** Lock mailglass's public API for downstream OSS dependencies, ship the RFC 8058 + auto-suppression deliverability floor that makes "batteries-included" load-bearing, and close v0.1.1 release-engineering debt so the publish pipeline is trustworthy for sibling-version coordinated releases.

**Phase Numbering:** Continues from v0.1's last phase (07.1) → starts at Phase 8.

- [ ] **Phase 8: Release-Engineering Hardening** - Close 9 v0.1.2 debt items + re-tighten Credo/Dialyzer/Tests gates before any API-freezing work
- [ ] **Phase 9: Mailable API Redesign + Freeze** - Remove Swoosh namespace leakage; ship native Message field setters, deprecation warnings, Igniter codemod, and api_stability.md v2
- [ ] **Phase 10: Stream Policy Implementation** - Fill the existing no-op seam at stream.ex:35; enforce compile-time + runtime stream separation; add StreamPolicyConsistent Credo check
- [ ] **Phase 11: RFC 8058 List-Unsubscribe** - Signed-token unsubscribe controller (core package); atomic header injection; mix mailglass.gen.unsubscribe; property tests
- [ ] **Phase 12: Auto-Suppression + Soft-Bounce Escalation** - Event-first Multi suppression inserts; Oban escalation worker; suppressions.resync task; complained permanence constraint
- [ ] **Phase 13: v0.2 Release Ceremony** - CHANGELOG, adopter walkthrough validation, full doc audit, coordinated Hex publish

## Phase Details

### Phase 8: Release-Engineering Hardening
**Goal**: Quality gates (Dialyzer, Credo strict, Tests halt-on-failure) are enforced and 9 v0.1.2 debt items are closed before any API-freezing work begins
**Depends on**: Nothing (v0.1.1 already shipped; first v0.2 phase)
**Requirements**: REL-01, REL-02, REL-03, REL-04, REL-05, REL-06, REL-07, REL-08, REL-09, REL-10, REL-11, REL-12
**Success Criteria** (what must be TRUE):
  1. Tag-push to mailglass-v0.2.0 triggers `publish-hex.yml` via `on: release: types: [published]` — NOT `on: push: tags:` — and a workflow rerun does NOT double-publish (`mix hex.info` pre-check skips if version already on Hex)
  2. `mix credo --strict` passes with zero warnings; each suppressed check in `.credo.exs` has a reasoning comment; `mix dialyzer` halts on warnings with `--ignore-exit-status` REMOVED from CI (subtraction, not addition); residual `.dialyzer_ignore.exs` entries are ≤15, each with a comment explaining why
  3. Bare `mix test` completes without the citext-OID-cache race; Tests gate runs `continue-on-error: false`; `mix test --only phase_NN_uat` is clean
  4. `CLAUDE.md` does not appear in HexDocs extras; no `D-NN` or `LINT-NN` IDs appear in public guides; `mix mailglass.docs.check` fails the build if any internal ID leaks
  5. All 6 closed Dependabot PRs merged; all Actions SHA pins refreshed for 2026-Q2; `verify.phase_NN` aliases renamed to semantic names (with deprecated pass-throughs for one cycle)
**Plans**: 6 plans

Plans:
- [x] 08-01: Fix publish-hex.yml + post-publish-smoke.yml triggers (on: release: types: [published]) + mix hex.info pre-check idempotency guard (REL-01)
- [x] 08-02: HexDocs hygiene — exclude CLAUDE.md; strip D-NN/LINT-NN from guides; add mix mailglass.docs.check CI gate (REL-02)
- [x] 08-03: Rename verify aliases to semantic names + wire installer goldens into mix mailglass.publish.check + resolve release-please extra-files (REL-03, REL-04, REL-05)
- [x] 08-04: Fix Advisory Matrix CI (DB-setup + Elixir 1.17); unskip install_idempotency tests; re-batch 6 Dependabot PRs; refresh SHA pins (REL-06, REL-07, REL-08, REL-09)
- [x] 08-05: Re-tighten Tests gate — sandbox + Task.Supervisor isolation; citext-OID-cache race fix; halt-on-failure (REL-10) — PR-A+PR-B shipped; PR-C deferred to operator (1-week tests_strict soak then halt-on-failure flip + branch protection)
- [x] 08-06: Enable Credo --strict (REL-11) + Dialyzer triage: remove --ignore-exit-status, triage ~230 findings to ≤15 annotated .dialyzer_ignore.exs entries (REL-12)

### Phase 9: Mailable API Redesign + Freeze
**Goal**: Adopter mailable modules compile against v0.2 with zero Swoosh.Email references in their API surface; downstream OSS packages can pin to `mailglass ~> 0.2` with a frozen, machine-readable public surface
**Depends on**: Phase 8 (clean lint/test gates required before API-freezing work)
**Requirements**: API-01, API-02, API-03, API-04, API-05, API-06, API-07
**Success Criteria** (what must be TRUE):
  1. Adopter app on `~> 0.2` compiles `MyApp.UserMailer` with zero `Swoosh.Email` references at call sites; native setters `to/2`, `from/2`, `subject/2`, `html_body/2`, `text_body/2`, `header/3`, `attach/2`, `put_tag/2` all work
  2. `update_swoosh/2` compiles, works, and appears in `api_stability.md` v2 §Message Extensions; running `mix mailglass.upgrade.v0_2` does NOT rewrite any `update_swoosh/2` call sites
  3. A v0.1 adopter's existing mailable code compiled against v0.2 emits `@deprecated` compile-time warnings at every superseded call site, but does NOT fail compilation (one-cycle BC)
  4. `mix mailglass.upgrade.v0_2 --dry-run` prints all mechanically-rewritable sites; `--apply` rewrites them; ambiguous cases emit `IO.warn` with migration guide URL and are NOT silently rewritten
  5. `mix mailglass.stability.check` exits zero; no `Swoosh.Email.t()` reference appears in public-API docstrings or typespecs; `guides/upgrading-from-v0_1.md` doctest snippets compile in CI
**Plans**: 8 plans

Plans:
- [ ] 09-01: Add Igniter ~> 0.7 dev dep + add 8 native field setters to Mailglass.Message (API-01)
- [ ] 09-02: Remove import Swoosh.Email at mailable.ex:129; update use Mailglass.Mailable injection to ≤20 lines (API-03)
- [ ] 09-03: Add @deprecated annotations on all v0.1 superseded paths (API-04)
- [ ] 09-04: Retain + document update_swoosh/2 as named escape hatch; add to api_stability.md v2 §Message Extensions (API-02)
- [ ] 09-05: Implement mix mailglass.upgrade.v0_2 Igniter codemod — dry-run default, --apply flag, ambiguous-case warn+skip, skip string literals/heredocs/comments (API-05)
- [ ] 09-06: Write api_stability.md v2 — public surface freeze, Since: annotations, deprecation policy, freeze-until-vNext promise (API-06)
- [ ] 09-07: Add mix mailglass.stability.check script + doc-contract test asserting no Swoosh.Email.t() in public typespecs (API-06)
- [ ] 09-08: Write guides/upgrading-from-v0_1.md — before/after examples, codemod walkthrough, ambiguous-case recipes, dep matrix, rollback procedure (API-07)

### Phase 10: Stream Policy Implementation
**Goal**: Message stream separation is enforced at both compile-time and runtime; the existing no-op seam at stream.ex:35 is replaced with real policy; adopters cannot accidentally ship a :bulk mailable without a stream set
**Depends on**: Phase 9 (StreamPolicyConsistent Credo check inspects the v0.2 macro shape; macro must be finalized first)
**Requirements**: STREAM-01, STREAM-02, STREAM-03, STREAM-04
**Success Criteria** (what must be TRUE):
  1. A mailable declared `use Mailglass.Mailable, stream: :bulk` has `%Message{stream: :bulk}` stamped at `Message.new_from_use/2`; runtime `%Message{stream: :bulk}` assignment also works; `:transactional`, `:operational`, `:bulk` are the only accepted atoms
  2. Sending a message that violates stream policy raises `%Mailglass.Error{type: :stream_policy_violated, detail: %{rule: atom, suggestion: String.t}}` with an informative message; existing `with :ok <- Stream.policy_check(msg)` call sites require zero modification
  3. `mix credo --strict` catches a `:bulk` mailable with no stream set and a `:transactional` mailable with tracking enabled at compile time, via `Mailglass.Credo.StreamPolicyConsistent` (LINT-13)
  4. Feedback-ID format auto-populated as `{sender_id}:{mailable}:{tenant_id}:{stream}` when feedback_id is configured; stream slot reflects runtime stream value
**Plans**: 5 plans

Plans:
- [ ] 10-01: Implement Mailglass.Stream module — closed atom set, per-mailable default resolution, Message.new_from_use/2 stamping (STREAM-01)
- [ ] 10-02: Replace no-op seam at stream.ex:35 with real StreamPolicy stage — runtime check, structured :stream_policy_violated error (STREAM-02)
- [ ] 10-03: Write Mailglass.Credo.StreamPolicyConsistent (LINT-13) — bulk-missing + tracking-on-transactional checks; coexists with NoTrackingOnAuthStream (STREAM-03)
- [ ] 10-04: Update Feedback-ID format to include stream slot (STREAM-04)
- [ ] 10-05: Boundary tests + StreamData property — policy violations caught at compile + runtime; stream stamping round-trips correctly

### Phase 11: RFC 8058 List-Unsubscribe
**Goal**: Bulk mailables rendered from a Phoenix host carry both List-Unsubscribe and List-Unsubscribe-Post headers (atomically injected — both or neither); a one-click POST records an :unsubscribed event within 5 seconds; signed tokens survive rotation
**Depends on**: Phase 10 (stream policy gates RFC 8058 header injection; add_rfc_required_headers/1 reads msg.stream)
**Requirements**: UNSUB-01, UNSUB-02, UNSUB-03, UNSUB-04, UNSUB-05, UNSUB-06
**Success Criteria** (what must be TRUE):
  1. Bulk mailable rendered from a Phoenix host has both `List-Unsubscribe` and `List-Unsubscribe-Post` headers; `:transactional` mailable has neither; `byte_size(url) <= 900` assertion fails fast in `unsubscribe_url/2` before any header is set
  2. `inject_unsubscribe_headers/2` is the ONLY code path that sets either header; `mix credo --strict` rejects any other path via `RequireAtomicUnsubscribeHeaders`; both headers are always set together, never one without the other
  3. One-click POST to `/mailglass/unsubscribe/:token` returns HTTP 200 within 5 seconds; a subsequent identical POST also returns 200 (idempotent); an `:unsubscribed` event row appears in `mailglass_events` for the delivery
  4. A token minted with salt A, then verified after rotation to salt B (with A still in rotation window), resolves correctly; an expired token returns a structured error (not a 500)
  5. StreamData property test (100 sequences): round-trip mint → verify across rotation boundary passes; SSRF/open-redirect check on `unsubscribe_url/2` passes; List-Unsubscribe present on `:bulk`, absent on `:transactional`
**Plans**: 7 plans

Plans:
- [ ] 11-01: Mailglass.Compliance.Unsubscribe — token mint/verify, multi-salt rotation, byte_size(url) <= 900 assertion in unsubscribe_url/2 (UNSUB-01)
- [ ] 11-02: inject_unsubscribe_headers/2 as sole atomic header injection path; extend add_rfc_required_headers/1 with stream-conditional logic (mandatory :bulk, opt-in :operational, never :transactional) (UNSUB-02)
- [ ] 11-03: Mailglass.Compliance.UnsubscribeController in mailglass core — GET (confirmation page) + POST (RFC 8058 one-click, 200, idempotent, no redirect) (UNSUB-03)
- [ ] 11-04: Mailglass.Router macro — mount /mailglass/unsubscribe/:token routes; configurable path prefix; collision detection against adopter routes (UNSUB-04)
- [ ] 11-05: mix mailglass.gen.unsubscribe — print mount instructions, config snippets, test recipe (does NOT copy code) (UNSUB-04)
- [ ] 11-06: StreamData property tests — rotation boundary, expired-token rejection, idempotent POST, SSRF/open-redirect check (UNSUB-05)
- [ ] 11-07: guides/unsubscribe.md + guides/dkim-setup.md — per-ESP DKIM h= (Postmark auto; SendGrid gap #893 documented); rotation playbook; troubleshooting (UNSUB-06)

### Phase 12: Auto-Suppression + Soft-Bounce Escalation
**Goal**: Webhook ingest automatically suppresses recipients on :bounced/:complained/:unsubscribed events with the event row FIRST in Multi always; :complained suppression is permanent by Postgres constraint; soft-bounce escalation is async via Oban; resync task is strictly per-tenant
**Depends on**: Phase 11 (full :unsubscribed lifecycle testable end-to-end before that event type is covered in AutoSuppress)
**Requirements**: SUPP-01, SUPP-02, SUPP-03, SUPP-04, SUPP-05
**Success Criteria** (what must be TRUE):
  1. StreamData property test (100 webhook sequences): recipient count in `mailglass_suppressions` exactly equals distinct suppression-causing events; replaying the same webhook sequence twice produces identical suppression state (`on_conflict: :nothing`)
  2. `mix credo --strict` raises `MultiEventFirstInWebhookIngest` if any suppression insert step precedes the event row step in the webhook ingest Multi
  3. After 5 `:deferred` events within a 7-day window for a recipient, an Oban job runs `Escalation` and inserts a hard suppression row; the job does NOT run synchronously inside the webhook request cycle
  4. `mix mailglass.suppressions.resync` without `--tenant-id` exits with a structured error; with `--tenant-id`, it projects `mailglass_events` into `mailglass_suppressions` idempotently via `Tenancy.scope/2`
  5. `Mailglass.Suppression.remove/2` with `reason: :complained` returns a structured `%Mailglass.Error{}` and does NOT delete the row; the Postgres `CHECK (reason != 'complained' OR expires_at IS NULL)` constraint prevents any expiry being set on complained rows
**Plans**: 6 plans

Plans:
- [ ] 12-01: Mailglass.Suppression.AutoSuppress — Multi.run {:auto_suppress, idx} after {:projector_apply, idx}; on_conflict: :nothing; triggers on :bounced/:complained/:unsubscribed (SUPP-01)
- [ ] 12-02: Mailglass.Credo.MultiEventFirstInWebhookIngest — lint check (LINT-14) enforcing event-first Multi ordering (SUPP-01)
- [ ] 12-03: Mailglass.Suppression.Escalation — Oban worker; soft-bounce threshold (5, 7d, :hard_suppress); covering index migration; OptionalDeps.Oban gate; Task.Supervisor fallback warning at boot (SUPP-02)
- [ ] 12-04: mix mailglass.suppressions.resync — --tenant-id required; Tenancy.scope/2; idempotent; --from/--to ISO-8601; default last-90-days scan window (SUPP-03)
- [ ] 12-05: Tighten pre-send check to default-deny on match; structured %Mailglass.Error{type: :suppressed}; telemetry [:mailglass, :suppression, :auto_added | :pre_send_blocked, :stop] with whitelisted metadata (SUPP-04)
- [ ] 12-06: :complained permanence — Postgres CHECK constraint; Suppression.remove/2 rejects :complained with structured error; GDPR delete-source/keep-suppression pattern documented (SUPP-05)

### Phase 13: v0.2 Release Ceremony
**Goal**: mailglass 0.2.0 and mailglass_admin 0.2.0 are published to Hex.pm via protected-ref trigger; all guides audited for v0.2 surface; adopter walkthrough validated end-to-end
**Depends on**: Phases 8–12 (coordinated release requires all three pillars complete)
**Requirements**: REL-13, REL-14, REL-15, REL-16
**Success Criteria** (what must be TRUE):
  1. CHANGELOG for mailglass 0.2.0 + mailglass_admin 0.2.0 lists breaking changes (Mailable API redesign), upgrade path (`mix mailglass.upgrade.v0_2`), and minimum dep matrix; an adopter reading it has everything needed to migrate without reaching for search
  2. Fresh Phoenix 1.8.5 host runs `mix mailglass.install` then `mix mailglass.upgrade.v0_2` from a v0.1 fixture project with zero manual edits for non-ambiguous cases; ambiguous cases emit clear `IO.warn` with migration guide URL
  3. All 9 v0.1 guides updated for v0.2 surface; `migration-from-swoosh.md` targets v0.2 native Message API; `upgrading-from-v0_1.md` finalized; `dkim-setup.md` covers per-ESP List-Unsubscribe DKIM h= verification
  4. Release Please bumps both packages to 0.2.0 via linked-versions; tarball sizes verified (<500KB mailglass, <2MB mailglass_admin); Hex publish from protected ref + GitHub Environment; `curl -fsI https://hexdocs.pm/mailglass/0.2.0/` returns HTTP 200
**Plans**: 5 plans

Plans:
- [ ] 13-01: Write CHANGELOG narrative — breaking changes, upgrade path, dep matrix, rollback (REL-13)
- [ ] 13-02: Adopter walkthrough validation — v0.1 fixture → mix mailglass.install → mix mailglass.upgrade.v0_2; assert zero manual edits for non-ambiguous cases (REL-14)
- [ ] 13-03: Doc audit — update all 9 v0.1 guides for v0.2 surface; finalize upgrading-from-v0_1.md; finalize dkim-setup.md (REL-15)
- [ ] 13-04: Release Please bump + tarball whitelist + size budget verification (REL-16)
- [ ] 13-05: Hex publish from protected ref + GitHub Environment + post-publish smoke (curl hexdocs + mix hex.info) (REL-16)

## Progress

**Execution Order:** 8 → 9 → 10 → 11 → 12 → 13

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v0.1 | 6/6 | Complete | 2026-04-22 |
| 2. Persistence + Tenancy | v0.1 | 6/6 | Complete | 2026-04-22 |
| 3. Transport + Send Pipeline | v0.1 | 12/12 | Complete | 2026-04-23 |
| 4. Webhook Ingest | v0.1 | 9/9 | Complete | 2026-04-24 |
| 5. Dev Preview LiveView | v0.1 | 6/6 | Complete | 2026-04-25 |
| 6. Custom Credo + Boundary | v0.1 | 6/6 | Complete | 2026-04-24 |
| 7. Installer + CI/CD + Docs | v0.1 | 5/5 | Complete | 2026-04-25 |
| 07.1. Publish to Hex.pm (INSERTED) | v0.1 | 11/11 | Complete | 2026-04-26 |
| 8. Release-Engineering Hardening | v0.2 | 0/6 | Not started | - |
| 9. Mailable API Redesign + Freeze | v0.2 | 0/8 | Not started | - |
| 10. Stream Policy Implementation | v0.2 | 0/5 | Not started | - |
| 11. RFC 8058 List-Unsubscribe | v0.2 | 0/7 | Not started | - |
| 12. Auto-Suppression + Soft-Bounce Escalation | v0.2 | 0/6 | Not started | - |
| 13. v0.2 Release Ceremony | v0.2 | 0/5 | Not started | - |

---
*v0.1 roadmap defined: 2026-04-21. v0.1 archived: 2026-04-26.*
*v0.2 roadmap defined: 2026-04-26. Coverage: 38/38 v0.2 REQ-IDs mapped. No orphans, no duplicates.*
