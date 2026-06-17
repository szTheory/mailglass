# Requirements: mailglass v1.12 — Adopter Onboarding & Day-2 Confidence

**Defined:** 2026-06-16
**Core outcome:** A serious Phoenix developer goes from `mix mailglass.install` to a
correctly-wired, production-ready integration without hitting a silent webhook failure, a
broken copy-paste example, or a missing day-2 runbook — and the whole accumulated v1.7–v1.12
body of work (admin polish, brand, design-system uplift, onboarding fixes) finally ships to Hex.

**Scope locks (apply to every requirement):**

- **Onboarding / DX + release only.** No new product capability, no new providers, no transport
  expansion, no new operator routes. mailglass is feature-complete for its scope (D-23
  convergence posture); this milestone removes adoption friction and publishes — it does not grow
  the product.
- **Code changes are confined to:** the installer (`mailglass/lib/mailglass/installer/*` + the
  install / doctor mix tasks) and the admin inbound replay modal. No changes to the
  outbound / webhook / inbound runtime contracts, Ecto schemas, or the public `Mailglass.Error`
  set. The folded-in a11y fix (A11Y-01, ex-v1.11 WR-03) is a quality-parity item, not a feature.
- **Docs guardrails:** every guide code block must parse (the `test/mailglass/docs_contract_test.exs`
  gate); use canonical telemetry/error vocabulary from `docs/api_stability.md`; no over-claims; new
  guides registered in BOTH `mix.exs` `extras:` and `groups_for_extras: [Guides: …]`.
- **Zero Node toolchain.** For the a11y phase, the admin CSS bundle is rebuilt + committed if any
  class changes (`git diff --exit-code priv/static/`).
- **Release posture: actually cut.** This milestone closes by cutting a real linked-version Hex
  release (admin-minor bump drags matched core + inbound; CHANGELOG entries; D-13 inbound exact-pin
  re-pin after the Release Please PR merges). This is the deliberate change from the v1.7/v1.11
  prepare-only precedent — the staged polish must reach adopters.

## v1.12 Requirements

### INSTALL — Fail-Closed Installer + Verifiable Wiring

- [x] **INSTALL-01**: `mix mailglass.install` fails closed (`Mix.raise`, non-zero exit) with an
  actionable message when `endpoint.ex` contains an unmanaged `plug Plug.Parsers` lacking a
  `:body_reader`, instead of printing a yellow warning and continuing (today
  `installer/apply.ex:47-76` warns and the result is never propagated).
- [x] **INSTALL-02**: A `--force` escape hatch lets advanced adopters proceed past the conflict
  (insert the managed parser above the existing one — preserving today's behavior), documented in
  both the error message and the getting-started troubleshooting section.
- [x] **INSTALL-03**: A verifiable post-install webhook-wiring check (extend `mix mail.doctor` with
  an endpoint/webhook lane, or a focused `mix mailglass.doctor`) confirms
  `Mailglass.Webhook.CachingBodyReader` is wired into the endpoint parser and exits non-zero when
  it is not (`mail.doctor` is DNS-only today).
- [x] **INSTALL-04**: The fail-closed, `--force`, and doctor paths are covered by tests following
  the `test/mailglass/install/install_idempotency_test.exs` fixture pattern.

### DOCS — Quickstart Fix + Learning Arc

- [x] **DOCS-01**: The README quickstart copy-pastes and runs cleanly — a config-first block (reuse
  the working snippet from `guides/getting-started.md`) is added so the `Mailglass.deliver()`
  example cannot `ConfigError`; validated by `docs_contract_test.exs`.
- [x] **DOCS-02**: `guides/getting-started.md` ends with a "Next steps" section sequencing the
  natural first-week path (jobs → authoring-mailables → preview → webhooks → testing → operate),
  instead of ending on installer troubleshooting.
- [x] **DOCS-03**: A discoverable learning-path / index (a new `guides/learning-path.md` and/or a
  restructured README documentation index) gives the existing guides a clear, ordered first-week arc.
- [x] **DOCS-04**: `guides/migration-from-swoosh.md` opens with the value-proposition pitch
  ("Swoosh handles transport; mailglass adds the framework layer you'd otherwise rebuild — preview,
  webhooks, audit ledger, suppressions, multi-tenancy") before the incremental-adoption mechanics.

### OPS — Day-2 Production Confidence

- [x] **OPS-01**: A new `guides/production-go-live-checklist.md` surfaces the pre-production
  verification surface: `mix mail.doctor` (DKIM/SPF/DMARC) + the INSTALL-03 webhook-wiring check,
  webhook secret provisioning/rotation, Oban queue sizing, per-tenant adapter routing, suppression
  strategy, and telemetry/alerting wiring. Registered in `mix.exs` docs and docs-contract gated.
- [x] **OPS-02**: A new `guides/errors-and-troubleshooting.md` provides a unified map of every
  `Mailglass.Error` struct (SendError, TemplateError, SignatureError, SuppressedError,
  RateLimitError, ConfigError, EventLedgerImmutableError, TenancyError, StreamPolicyError,
  PublishError) → cause → fix → remediation, routing canonical truth to `docs/api_stability.md`.
  Registered in `mix.exs` docs and docs-contract gated.

### A11Y — Inbound Replay-Modal Parity (folded-in v1.11 WR-03)

- [x] **A11Y-01**: The admin inbound replay modal gains operator-style accessibility parity — a
  focus trap and Escape-to-close handler matching the operator replay modal — with a structural
  Playwright assertion added and the CSS bundle rebuilt + committed if any classes change.

### REL — Cut the Release

- [ ] **REL-01**: A real linked-version Hex release is cut for the accumulated v1.7–v1.12 work —
  CHANGELOG entries written, the admin-minor bump mechanically drags matched core + inbound, the
  Release Please PR merges green, and all three packages publish to Hex.
- [ ] **REL-02**: The D-13 inbound exact-pin re-pin is performed (`mailglass_inbound/mix.exs`
  `{:mailglass, "== <new core version>"}`) after the release PR merges and core publishes, with
  `mix deps.get` Hex resolution and `post-publish-smoke` verified green.

## Future Requirements (deferred)

- Core mailglass **email-template HEEx component** design-system uplift (recipients' inboxes;
  email-client CSS constraints — different audience than the admin UI). Diminishing-returns /
  pull-gated.
- Promote backlog Phase 999.1 (human-readable code comments + GSD artifact cleanup) / 999.2
  (shift-left email screenshot + responsive preview workflow) via `/gsd-review-backlog`.
- Register `guard-release-trigger` as a required branch-protection check once a PR has exercised it
  (carried v1.10 follow-up; naturally exercised by the REL-01 release PR).

## Out of Scope

- **New product capability / providers / transports / routes** — feature-complete for scope; see
  `.planning/threads/transport-expansion-watchlist.md` and the diminishing-returns list in
  PROJECT.md.
- **SEED-003 ecosystem integrations** — no adopter signal; needs a narrow spike + real pull first.
- **Refactoring the installer's plan/apply architecture** — the fix is the minimal fail-closed
  routing of one already-detected conflict, not an installer redesign.
- **Marketing email** — permanently out of scope (D-01).

## Traceability

REQ-ID → Phase mapping for v1.12 (Phases 104–108). All 13 v1.12 requirements map to exactly one
phase — 100% coverage, no orphans, no double-maps.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INSTALL-01 | Phase 104 | Complete |
| INSTALL-02 | Phase 104 | Complete |
| INSTALL-03 | Phase 104 | Complete |
| INSTALL-04 | Phase 104 | Complete |
| DOCS-01 | Phase 105 | Complete |
| DOCS-02 | Phase 105 | Complete |
| DOCS-03 | Phase 105 | Complete |
| DOCS-04 | Phase 105 | Complete |
| OPS-01 | Phase 106 | Complete |
| OPS-02 | Phase 106 | Complete |
| A11Y-01 | Phase 107 | Complete |
| REL-01 | Phase 108 | Pending |
| REL-02 | Phase 108 | Pending |

**Coverage:** 13/13 v1.12 requirements mapped to exactly one phase ✓
