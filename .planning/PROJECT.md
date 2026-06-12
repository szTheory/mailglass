# mailglass

> *Mail you can see through.*

## What This Is

**mailglass** is a batteries-included transactional email framework for Phoenix — the layer that sits on top of [Swoosh](https://hex.pm/packages/swoosh) and ships everything Swoosh deliberately doesn't: HEEx-native components, a LiveView preview/admin dashboard, normalized webhook events, signed unsubscribe tokens with RFC 8058 List-Unsubscribe headers, message-stream separation, suppression lists, an append-only event ledger, multi-tenant routing, and `mix mail.doctor` deliverability checks. It's for senior Phoenix teams shipping production transactional email (welcome flows, password resets, magic links, receipts, notifications) who today rebuild 40% of ActionMailer + Anymail + ActionMailbox by hand on every project.

It is shipped as three sibling Hex packages: `mailglass` (core), `mailglass_admin` (mountable LiveView dashboard), and `mailglass_inbound` (Action Mailbox equivalent — post-`v1.0`).

## Current Milestone: v1.10 Brand Adoption

**Goal:** Make the A/B-winning fable brand the project's one canonical identity everywhere it shows: fold `brandbook-fable/` into `brandbook/` (deleting the codex book), propagate the sealed-flap identity to the root README and the repo social preview, and wire HexDocs/ex_doc logos for all three packages.

**Target features:**
- Folder adoption: `brandbook-fable/` becomes canonical `brandbook/` via git mv; codex book removed (history preserves it at the frozen baseline `09a84dd4`); all internal references (CLAUDE.md brand pointers, planning intel) reconciled; the v1.9 quality gate re-passes on the new path.
- Repo surfaces: root README adopts `brandbook/examples/readme-header.svg`; og-card exported to PNG (1200×630) with documented GitHub social-preview upload steps; favicon adopted where the repo serves one.
- HexDocs wiring: ex_doc logo/assets config for `mailglass`, `mailglass_admin`, `mailglass_inbound` — verified with local `mix docs` renders; committed as non-release-triggering types so the brand ships with the next natural release (no forced release train in this milestone).
- CLAUDE.md "Brand & Voice" source-of-truth pointer moves from `prompts/mailglass-brand-book.md` to `brandbook/brand-book.md`.

**Scope locks:**
- No Hex release is cut in this milestone; mix.exs changes are docs-config only, commit types must not trigger release-please.
- The sealed-flap usage rules and constraints C-15/C-16 (in the v1.9 decision record) are binding on every propagated surface.
- Binary additions limited to the single og-card PNG export.

**v1.9 context (shipped):**

**`v1.9 Brand Book Fable — A/B Brand System` SHIPPED 2026-06-12.** The
competing brand book at `brandbook-fable/` is complete and maintainer-approved
("I LOVE THE NEW BRANDBOOK"): the sealed-flap identity (4-round tournament
winner) as an 8-asset two-expression logo system, contrast-proven two-tier
tokens with full light/dark parity, a self-contained 77.7 KB HTML book with
live theme toggle / keyboard-operable gallery / runtime-computed WCAG matrix,
landing + email specimens, four portable SVGs, and a domain-noun copy library.
22/22 requirements verified; the Phase 90 gate passed 9/9 on its first run.
**Deferred to the next milestone:** adopting the winner as canonical
`brandbook/` (folder rename, README/HexDocs/social propagation, PNG exports).

<details>
<summary>v1.9 original goal and targets (shipped)</summary>

**Goal:** Build a second, fully self-contained brand book at `brandbook-fable/` to A/B against the frozen codex `brandbook/` baseline (commit `09a84dd4`) — and beat it on craft, buildability, and standalone polish.

**Target features:**
- Research-grounded differentiation brief (forensic codex audit + world-class OSS/devtools brand-system research)
- Foundations: semantic design tokens with interaction/feedback state roles, light AND dark, computed WCAG contrast matrix
- Bounded logo tournament with a maintainer hard-pause: 8 diverse-by-axis options including integrated custom typemarks; no rectangular background plates, boundary-breaking marks, tight logotype proximity, no subtitle in the main lockup; refinement rounds on the pick(s); winner shipped as outlined-path SVGs (zero `font-family` in assets)
- Standalone HTML brand book (`index.html`): self-contained, light/dark toggle, live component gallery with real hover/focus/disabled states, rendered contrast matrix, logo system section
- Collateral: landing-page and transactional-email HTML specimens, README/docs/OG/diagram-language SVGs, per-surface copy library and domain-noun microcopy
- Scripted quality gate: no planning-language leakage, no font dependencies, size budgets, local-only references, dark/16px render checks

**Scope locks:** Only `brandbook-fable/` is written. `brandbook/` (frozen baseline), `mailglass_admin`, guides, and README are out of scope. Text artifacts only (SVG/MD/JSON/CSS/HTML); no Node toolchain, no binaries, no embedded fonts, no external network requests. Creative latitude on palette/type/logo where justified; locked essence: "mail you can see through," thoughtful-maintainer voice, glass-as-metaphor-not-gimmick.

</details>

## Current State

**`v1.8 Brand System and Repo-Ready Brandbook` is closed superseded as of 2026-06-11.** Phases 80-82 completed through GSD (brand audit/gap register, source brandbook + tokens, logo option evidence); the logo selection checkpoint and phases 83-84 were resolved out-of-band in a separate working session that selected `concept-07r-no-idot-02-tighter-gap` and finished the brandbook around it (frozen at commit `09a84dd4`). Milestone audit verdict `gaps_found` — accepted at close because v1.9 supersedes the remaining work.

- Known accepted gaps: EXAMPLE/VOICE/REPO requirements never verified through GSD; `brandbook/` logo wordmark is live `<text>` in macOS-only Avenir Next; `tokens.json` retains stale planning language; dark tokens exist but are undemonstrated.
- v1.8 is archived in `.planning/milestones/v1.8-ROADMAP.md`, `v1.8-REQUIREMENTS.md`, `v1.8-MILESTONE-AUDIT.md`, and `v1.8-phases/`.

**`v1.7 Admin UI — IA & Design-System Polish v2` is complete and archived as of 2026-06-05. Phases 74-79 took `mailglass_admin` to "v2 polish" by applying the shipped design system more completely — a frozen UI-SPEC + scored gap register evidence gate, shell-level orientation parity across all 3 surfaces, an in-library Operator Overview landing, one unified `status_badge` atom replacing five divergent copies, full token migration, motion discipline, fully-expressive seed data, and a self-verified closeout (structural e2e + conformance/bundle grep gates, no human UAT). Milestone audit `status: passed` (19/19 requirements, 7/7 seams, 3/3 flows). No new dependencies, no brand-book amendment, stable seams untouched.**

- Phase 74 produced the evidence gate (gap register, frozen UI-SPEC with canonical status-badge taxonomy, before-baseline screenshots, assertion inventory) with zero code changed.
- Phase 75 generalized `Shell.orientation_strip/1` to Deliveries/Inbound/Preview and added the `:overview` Operator Overview landing via `OperatorLive.handle_params/3` — no router-macro change.
- Phase 76 collapsed five `badge_class/1` copies into `Components.status_badge/1`, migrated every admin HEEx file onto the v1 token scale, restructured support cards into a Tier1/Tier2 triage hierarchy, and committed the rebuilt bundle behind a self-contained `heroicons-inline.js` plugin.
- Phase 77 fixed the `motion-reveal` re-fire with record-keyed ids and enforced reduced-motion / transform-opacity-only / ≤300ms via a motion conformance gate.
- Phase 78 made every screen state reachable by a seeded URL with same-commit e2e count-assertion updates and untouched baseline pins.
- Phase 79 re-ran the full audit matrix vs the Phase 74 baseline, extended Playwright to 10 green tests, closed all sev-4/5 gap rows, and staged the linked-version release ceremony prepare-only (inbound exact-pin `== 1.4.5` → `== 1.5.0`; the publish pipeline owns the actual Hex cut — admin-minor bump mechanically drags matched core/inbound versions per D-01).
- v1.7 is archived in `.planning/milestones/v1.7-ROADMAP.md`, `.planning/milestones/v1.7-REQUIREMENTS.md`, and `.planning/milestones/v1.7-MILESTONE-AUDIT.md`.

**`v1.5 Demo Evidence and Click-Around Confidence` is complete as of 2026-06-02. Phases 67-70 shipped a separate realistic demo app, deterministic B2B SaaS Ops data, short click-around docs, and browser-driven evidence across preview, outbound operator, and inbound operator journeys.**

- Phase 67 established `reference/demo_app` as the rich demo surface separate from the narrow `reference/host_app`, with local-path and published-Hex dependency modes, health-gated Compose startup, cache-aware browser setup, deterministic reset proof, and `verify.phase67`.
- Phase 68 expanded deterministic Northstar fixture data with six outbound and four inbound stories, suppression/webhook/replay lineage, realistic preview mailers, and repo-root demo data tests.
- Phase 69 made the dashboard a guided hub into the real mounted preview/outbound/inbound surfaces, made `reference/demo_app/README.md` the canonical quickstart and click-path guide, and replaced human UAT with automated browser/docs evidence.
- Phase 70 reconciled the browser evidence gate to the Phase 69 automation lane: `mix verify.phase69` drives Playwright through the demo dashboard and writes `demo_browser_evidence.v1` checkpoint evidence.
- v1.5 is archived in `.planning/milestones/v1.5-ROADMAP.md`, `.planning/milestones/v1.5-REQUIREMENTS.md`, and `.planning/milestones/v1.5-MILESTONE-AUDIT.md`.

**`v1.4 Inbound Stability Lock` shipped on 2026-06-01. Phase 66 recorded the release-position decision: promote `mailglass_inbound` to the `1.0.0` candidate, with release ceremony / maintenance posture next.**

- Phase 63 reconciled `mailglass_inbound/docs/api_stability.md` into the canonical stable/testing/internal/deferred inbound inventory.
- Provider support is now documented through `MailglassInbound.Ingress.Plug` semantics, while provider modules, replay internals, route structs, workers, queues, and UI details stay internal.
- Deferred inbound capabilities are explicitly named: public replay API, provider extension API, matcher expansion, lifecycle callbacks, fan-out, synthetic UI, `gen_smtp`, and ecosystem integrations.
- Package-local docs-contract assertions now pin those section boundaries and over-claim guards.
- Phase 64 made the inbound contract executable: compiled-doc metadata is verified package-locally, closed error/type sets are locked to docs, release-line/over-claim checks fail closed, and root `mix verify.stability_contract` delegates to the inbound support-contract lane.
- Phase 65 locked the adopter-facing DX story: the inbound README is the canonical adoption lane, install/compatibility/operator/testing/admin trust docs agree on stable versus internal boundaries, and docs-contract plus Tier 1 checks now fail closed on drift.
- Phase 66 promoted the source-of-truth candidate to `mailglass_inbound` `1.0.0`, aligned release notes / README pins / publish proof, and kept broad feature-growth gated until explicit adopter pull or contract gaps justify new scope.

**`v1.3 Adopter Trust Proof` shipped on 2026-05-31.**

- Milestone archive complete: 7 phases (`52`, `57-62`), 18 plans, 16/16 requirements satisfied, final audit `status: passed`
- **Current package versions on Hex: `mailglass` 1.4.5 / `mailglass_admin` 1.4.5 / `mailglass_inbound` 1.1.5** (as of 2026-06-03). The 1.4.x line shipped as quiet maintenance **outside** GSD milestone planning: 1.4.2 unstuck a stranded linked release (admin pinned `mailglass == 1.3.0`); 1.4.3–1.4.5 fixed a stack of latent `mix mailglass.install` bugs the long-red consumer-install smoke had masked (swoosh-1.26 boot crash, OPS-01 finch-in-lock, installer codegen). Inbound was force-bumped to 1.1.5 to track each core release. Earlier line for reference: v1.3 shipped `mailglass`/`mailglass_admin` 1.3.0 (2026-05-29) and v1.6 shipped `mailglass_inbound` 1.0.0 inbound-only (2026-06-02).
- The maintained `reference/host_app` now proves a narrow, public-seam-only adopter path with an explicit scope contract and non-goals.
- One canonical deterministic trust runner now covers install -> preview -> send -> signed webhook ingest -> operator troubleshooting, with stable `trust_runner.v1` checkpoint evidence.
- Required repo-head and clean-baseline trust lanes enforce checkpoint evidence, Hex-first dependency resolution, and branch-protection/release-gate expectations.
- Post-publish smoke now runs a published-version trust journey and guards the current release line against stale-lock and hackney dependency regressions.
- Reference-host and trust-entry docs now route guarantee truth to canonical `api_stability.md` inventories and `mix verify.stability_contract`, with deterministic docs-check enforcement against contract-boundary drift.
- Backlog phase 999.1 completed on 2026-05-27: planning-artifact comment cleanup now covers scoped core/admin/inbound source paths, with Credo drift prevention (`Mailglass.Credo.NoPlanningArtifactComments`) and guard tests added
- Backlog phase 999.2 completed on 2026-05-27: deterministic preview URL/capture matrix foundations, mix screenshot capture workflow, advisory CI artifact lane, and docs claim-boundary contract checks are now in place
- `mailglass_inbound` now has production-credible telemetry, Mailgun + SES ingress, test helpers + generators, admin observability, operator tooling, and six first-party inbound guides
- Phase 51 retired the remaining v1.0 carry-forward debt inside the same milestone: Phase 35 Nyquist bookkeeping, branch-protection repo truth, bare `mix test` citext race, boundary warnings, and WR-01..WR-06 dispositions
- `v1.1` remains the previous shipped slice: `mailglass` 1.0.0 / `mailglass_admin` 1.0.0 / `mailglass_inbound` 0.1.0 published on 2026-05-07 via Phase 44.5

v1.0 milestone closed 2026-05-06. 4 phases (35-38), 12 plans, Stability Lock complete.
v0.6 milestone closed 2026-05-05. 3 phases (32-34), 9 plans, Production Maturity complete.
v0.5 milestone closed 2026-05-03. 4 phases (28-31), 7 plans, Adoption Hardening complete.

**Codebase characteristics:**
- Three sibling Hex packages (`mailglass`, `mailglass_admin`, `mailglass_inbound`) — `mailglass_inbound` opened in v1.1
- Phoenix 1.8+ / Elixir 1.18+ / OTP 27+ / Postgres only
- Append-only `mailglass_events` ledger with SQLSTATE 45A01 immutability trigger
- Multi-tenant first-class — `tenant_id` on every record
- 17 custom Credo checks operationalizing domain rules at lint time (every check registered in `.credo.exs` and meta-test-enforced against the inert-guard blind spot as of Phase 45)
- Boundary-enforced module hierarchy
- Optional-deps (Oban, OpenTelemetry, MJML, gen_smtp, sigra) gated through `Mailglass.OptionalDeps.*` modules
- HEEx + MSO VML fallbacks; zero Node toolchain anywhere
- Preview LiveView shipped at v0.1; production admin workflows, replay history, and tenant-safe operator actions shipped by v0.5
- Inbound package: canonical `%InboundMessage{}` value object, thin router DSL, mailbox behaviour with locked outcomes, Postmark + SendGrid first-party ingress, tenant-safe replayable storage of normalized + raw provider source, Oban-backed async execution with bounded `Task.Supervisor` fallback (v1.1)

**Open issues / debt**:
- Release-workflow fanout still relies on the documented `workflow_dispatch` fallback because GitHub `GITHUB_TOKEN` anti-recursion blocks downstream publish workflows from release-created releases.
- Admin publish still needs an explicit Hex-index wait on inbound when sibling packages release in parallel.
- `SEED-003-ecosystem-integrations` is intentionally deferred and remains dormant for later milestone selection.
- **`v1.6 Inbound 1.0 Release and Truth Lock` SHIPPED 2026-06-02: `mailglass_inbound` 1.0.0 is live on Hex (inserted 17:42:31Z, HexDocs up, release-triggered smoke green).** Cut via the canonical `release: published` path at `50bc4b82`; publish-core/publish-admin idempotency-skipped so no core/admin release was forced. Two release-readiness fixes were made at publish time: dropped 7 untracked draft files from the inbound publish allowlist (the package had been building from a dirty working tree, incl. a duplicate `suppression_flagged` migration), and greened `main` (mix format + a stale compatibility-contract assertion — `main` had been silently red since 2026-05-29 because phases 66–73 landed via `paths-ignore`d commits that never ran `ci.yml`). Posture now: quiet maintenance / adopter-pull, no feature-growth milestone queued.
- A few latent hardening notes remain in per-phase review artifacts, but none block the shipped `v1.2` surface.

## Latest Completed Milestone

<details>
<summary>v1.7 Admin UI — IA & Design-System Polish v2 — milestone closed 2026-06-05</summary>

**Goal:** Take `mailglass_admin` to "v2 polish" — a consistent, brand-distinct, intuitive, joy-to-use design system where each reused component pays dividends, information architecture that orients every persona on landing, and seed data that fully expresses every screen state — all by applying the existing shipped design system more completely (no new dependencies, no brand-book amendment).

- **Orientation parity + Operator Overview (Fork A)** — generalized `orientation_strip` into shell-level `Shell.orientation_strip/1` on Deliveries/Inbound/Preview; added an in-library task-oriented Operator Overview landing (`:overview` action in `OperatorLive.handle_params/3`, zero router-macro change) surfacing orphan-backlog / recent-failure / suppression-count health. ✓
- **Design-system hardening** — one unified `Components.status_badge/1` atom replaced five divergent `badge_class/1` copies (GAP-01..06); every admin HEEx file migrated onto the v1 token scale; the flat 2×2 support-card grid became a Tier1/Tier2 triage hierarchy; rebuilt bundle committed behind a self-contained `heroicons-inline.js` plugin. ✓
- **Motion & expressiveness within the brand book (Fork B)** — `motion-reveal` re-fire fixed with record-keyed ids (GAP-19); reduced-motion / transform-opacity-only / ≤300ms enforced by a motion conformance gate; seed data made every screen state reachable by a seeded URL. ✓
- **Self-verification + visual-regression hardening** — full audit-matrix re-run vs the Phase 74 baseline, Playwright extended to 10 green structural tests, conformance + bundle-clean grep gates, all sev-4/5 gap rows closed; no human UAT. ✓
- **Audit:** `status: passed` — 19/19 requirements, 7/7 cross-phase seams, 3/3 E2E flows.

**Release posture:** prepare-only — the inbound exact-pin was bumped `== 1.4.5` → `== 1.5.0` and the linked-version pipeline owns the Hex publish (admin-minor bump mechanically drags matched core/inbound versions; CHANGELOG entries administrative per D-01).

**Accepted residual debt:**

- Phase 76 human-UAT/verification artifacts left in `partial`/`human_needed` state — resolved downstream by Phases 77 + 79 and confirmed by the milestone audit; recorded as deferred in STATE.md.
- Two draft Nyquist VALIDATION records (Phases 75, 78) — coverage-bookkeeping only; both phases fully verified with green e2e.
- Pre-existing `operator_live.ex` / `suppression_card.ex` nil-guard tech debt (CR-01/02/03, predate v1.7) — candidates for a future maintenance pass.
- Leftover phase directories (71-79, 999.x) still in `.planning/phases/`; run `/gsd-cleanup` to archive execution history retroactively.

</details>

<details>
<summary>v1.6 Inbound 1.0 Release and Truth Lock — milestone closed 2026-06-02</summary>

**Goal:** Publish and prove the selected `mailglass_inbound` `1.0.0` release line, reconcile public docs with that contract truth, and leave Mailglass in a quiet maintenance / adopter-pull posture without adding new product surface.

- **Inbound-only release proof** — `mailglass_inbound` `1.0.0` shipped live on Hex 2026-06-02 (inserted 17:42:31Z, HexDocs up, release-triggered smoke green) via the canonical `release: published` path at `50bc4b82`; publish-core/publish-admin idempotency-skipped so no core/admin release was forced. ✓
- **Own 1.0 contract wording** — inbound described as its own stable `1.0` package contract routed through `mailglass_inbound/docs/api_stability.md`, with core/admin kept on the matched `1.x` sibling line. ✓
- **Release-runbook + published-artifact truth** — stale inbound `1.0` install/fallback/smoke/Hex/HexDocs claims reconciled; release evidence captured. ✓

**Note on subsequent maintenance line:** after v1.6 closed, the `1.4.x` quiet-maintenance line (1.4.2 unstuck a stranded linked release; 1.4.3–1.4.5 fixed `mix mailglass.install` bugs) shipped **outside** GSD milestone planning, bringing live versions to `mailglass` 1.4.5 / `mailglass_admin` 1.4.5 / `mailglass_inbound` 1.1.5 by 2026-06-03.

**Accepted residual debt:**

- Quiet-maintenance posture held; no feature-growth milestone was queued until this v1.7 adopter-visible-quality investment.

</details>

<details>
<summary>v1.5 Demo Evidence and Click-Around Confidence — milestone closed 2026-06-02</summary>

**Goal:** Prove Mailglass is done enough for pre-adopter confidence by shipping a realistic B2B SaaS Ops demo app with rich deterministic data, one-command Docker DX, and browser-driven adoption evidence across preview, outbound operator, and inbound operator journeys.

- **Separate demo app** — `reference/demo_app` stays distinct from `reference/host_app`, supports local-path and published-Hex dependency modes, and starts through health-gated Compose. ✓
- **Realistic fixture corpus** — deterministic Northstar outbound, inbound, suppression, webhook, replay, and preview-mailer scenarios reset from one command. ✓
- **Guided click-around** — dashboard and docs route maintainers into real preview, outbound operator, and inbound operator surfaces with explicit destructive reset wording. ✓
- **Browser evidence** — Playwright drives the dashboard/preview/outbound/inbound paths and writes bounded `demo_browser_evidence.v1` checkpoint evidence. ✓

**Accepted residual debt:**

- Phase directories remain in `.planning/phases/` for now; use `$gsd-cleanup` later if you want to move execution history under the milestone archive.
- The next milestone still needs fresh requirements; `REQUIREMENTS.md` is removed during closeout by design.

</details>

<details>
<summary>v1.4 Inbound Stability Lock — milestone closed 2026-06-01</summary>

**Goal:** Lock `mailglass_inbound` into a stable adopter contract by defining its public API, compatibility policy, docs guarantees, and executable stability checks without expanding feature scope.

- **Stable inventory** — reconciled `mailglass_inbound/docs/api_stability.md` around stable runtime, testing, operator, telemetry, error, internal, and deferred seams. ✓
- **Executable proof** — root `mix verify.stability_contract` now delegates to the package-owned inbound support-contract lane with compiled-doc and docs-contract proof. ✓
- **Adopter DX lock** — README, install, compatibility, operator, testing, and admin trust docs now agree on stable semantics and internal boundaries. ✓
- **Release position** — Phase 66 selected the `mailglass_inbound` `1.0.0` candidate and refreshed source/manifest/docs/publish-proof truth. ✓

**Accepted residual debt:**

- The live Hex release ceremony for `mailglass_inbound` `1.0.0` remains the next release-governance step.
- Broad feature-growth remains blocked unless concrete adopter pull or contract gaps justify new scope.

</details>

<details>
<summary>v1.3 Adopter Trust Proof — milestone closed 2026-05-31</summary>

**Goal:** Prove real-world adoption confidence with one maintained Phoenix reference host app and deterministic trust evidence across local, CI, and published-version release checks.

- **Reference host baseline** — shipped a maintained Phoenix host app with clean-checkout setup, public-seam-only integration, and a fail-closed scope contract. ✓
- **Deterministic trust journey** — shipped `mix verify.reference_host.journey` and stable `trust_runner.v1` checkpoint evidence for install, preview, send, webhook ingest, and operator troubleshooting. ✓
- **CI/release trust evidence** — required repo-head and clean-baseline lanes now publish checkpoint artifacts and guard Hex-first dependency resolution. ✓
- **Published-version proof** — post-publish smoke now runs the current-release trust journey and blocks stale release-line claims. ✓
- **Contract-boundary docs** — reference docs are usage proof only; public guarantee truth routes to canonical stability inventories and executable contract checks. ✓

**Accepted residual debt:**

- Advisory review notes remain for docs checker path-scoping consistency, async mutation flake risk, and broad assertion granularity.
- `mailglass_inbound` still needs a dedicated stability-lock milestone before it carries the same compatibility posture as the core/admin `1.x` surface.

</details>

<details>
<summary>v1.2 Inbound Production Confidence — milestone closed 2026-05-26</summary>

**Goal:** Finish opening `mailglass_inbound` so adopters can install, observe, test, and operate inbound mail with the same confidence already available on outbound.

- **Telemetry + replay proof** — shipped PII-safe inbound spans, PubSub hooks, never-raise MIME parsing, and a 1000-replay convergence proof. ✓
- **Major-provider ingress** — shipped Mailgun and SES inbound verification, normalization, replay-safe persistence, and bounded S3 fetch handling. ✓
- **Adopter DX** — shipped `MailboxCase`, `TestAssertions`, `Test.Ingress`, code-built fixtures, and three Igniter generators. ✓
- **Operator/admin depth** — shipped `InboundLive`, routing-trace and evidence views, replay controls, `mailglass.inbound.{doctor,replay,prune}`, rate limiting, and suppression-flag-only behavior. ✓
- **Closeout discipline** — published `mailglass` 1.2.0 / `mailglass_admin` 1.2.0 / `mailglass_inbound` 0.2.0, then resolved the remaining v1.0 carry-forward debt in Phase 51 before archiving. ✓

**Accepted residual debt:**

- Release-workflow fallback remains manual-by-design until a future maintainer chooses PAT-based or alternate fanout automation.
- `SEED-003-ecosystem-integrations` is acknowledged and dormant, not promoted into the next milestone automatically.

</details>

<details>
<summary>v1.1 Inbound Core Slice — milestone closed 2026-05-06 (audit re-passed 2026-05-07)</summary>

**Goal:** Open `mailglass_inbound` as the first deliberate post-`v1.0` expansion, proving Mailglass can receive, persist, route, and process inbound transactional email without weakening the locked outbound/admin core.

- **Inbound package foundation** — canonical `%InboundMessage{}`, thin router DSL, mailbox behaviour with locked outcomes, package-local persistence boundary, optional-Oban execution seam. ✓
- **First-party provider ingress** — Postmark verify-first ingress with sealed normalization; SendGrid second-provider proof with shared canonical shape and provider-specific dedup. ✓
- **Replayable persistence** — normalized canonical inbound rows alongside raw provider source evidence; replay over stored truth that never pretends a stored message is a fresh provider event. ✓
- **Async execution + adopter proof** — Oban-backed inbound worker, bounded `Task.Supervisor` fallback with explicit warn-on-enter, canonical install / testing / operator docs, repo-root release-proof coverage for the new sibling package. ✓
- **Audit-gap closure** — Phase 43 recovered Phases 39-41 verification artifacts and added Phase 41 validation; Phase 44 recovered Phase 42 verification and reconciled REQUIREMENTS.md / STATE.md / ROADMAP.md so the v1.1 audit re-ran with `status: passed`. No source code under `mailglass/` or `mailglass_inbound/` was modified during the gap closure. ✓

**Accepted closeout debt:**

- No new debt introduced in v1.1. Carry-forward only: v1.0 partial Nyquist bookkeeping for Phase 35, non-blocking boundary warnings in support-contract lanes, manual GitHub branch-protection verification, bare `mix test` citext-OID-cache race.

</details>

<details>
<summary>v1.0 Stability Lock — milestone closed 2026-05-06</summary>

**Goal:** Declare the transactional/admin core stable for long-lived production adoption without expanding the product boundary.

- **Stable surface lock** — core and admin contract inventories are now canonical, narrow, and backed by compiled-doc and docs-surface proof. ✓
- **Compatibility promise** — `1.x` deprecation/support policy and the canonical `0.x -> 1.0` upgrade path are now explicit and mechanically verified. ✓
- **Trust and release proof** — semantic stability verification, canonical testing/admin trust docs, and committed release rehearsal artifacts are now shipped. ✓

**Accepted closeout debt:**

- Phase 35 Nyquist bookkeeping still reports `wave_0_complete: false` even though verification now passes.
- Non-blocking boundary warnings remain in the stability verification lane.
- Manual GitHub branch-protection verification remains external to the repo.

</details>

## Next Milestone Queue (after v1.5)

- **Recommended next step after Demo Evidence:** define a fresh milestone with `$gsd-new-milestone`, biased toward release ceremony for the selected `mailglass_inbound` `1.0.0` candidate, maintenance, release hygiene, docs truth, or narrow adopter-pull work.
- **Convergence posture:** Mailglass is no longer in broad feature-growth mode. Core `mailglass`, `mailglass_admin`, and the inbound source candidate are effectively product-complete for the original transactional-email framework thesis unless concrete adopter pull or a contract gap says otherwise.
- **Done-enough target:** After inbound stability lock, default future posture should be maintenance, release hygiene, docs accuracy, and narrow adopter-pull work. Do not keep asking whether the project is "done" at every milestone boundary; assume the library is approaching done unless a concrete adopter need or contract gap says otherwise.
- Follow-on ordering:
  1) cut the selected `mailglass_inbound` `1.0.0` release line,
  2) enter quiet maintenance / "silence on the wire" mode by default,
  3) consider synthetic inbound dev tooling only if it has clear adopter pull and strict dev-only tenant/provenance safety,
  4) consider Cloudflare forwarding recipe docs or narrow ecosystem integration slices only as pull-driven strategic work,
  5) re-evaluate `gen_smtp` listener only with strong adopter pull and a separate threat/ops model.
- Guardrail remains: do not auto-promote `SEED-003-ecosystem-integrations` or transport-expansion tails as default next work.

## Core Value

**Email you can see, audit, and trust before it ships.** Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure — without leaving Phoenix or bolting on Node.

If everything else fails, the preview dashboard, normalized event ledger, and one-line `Mailglass.deliver/2 → deliver_later/2` ergonomics must work flawlessly.

## Validated Requirements (v0.1, v0.2, v1.1, v1.3, v1.4, v1.7 — SHIPPED)

All 84 v1 REQ-IDs, 38 v0.2 REQ-IDs, 10 v1.1 REQ-IDs, 13 v1.4 REQ-IDs, and 19 v1.7 REQ-IDs satisfied. v1.8 validated so far: 2 brand-audit requirements.

**By category (v1.8 in progress — Brand System and Repo-Ready Brandbook):**
- ✓ BRAND-01..02 — critical KEEP/TIGHTEN/REWORK/ADD/REMOVE brand audit and required-surface stress matrix validated in Phase 80.

**By category (v1.7 — Admin UI IA & Design-System Polish v2):**
- ✓ AUDIT-01..03 — scored gap register, frozen UI-SPEC with canonical status-badge taxonomy, and before-baseline screenshot + assertion-ripple inventory validated in Phase 74 (evidence-only gate, zero code)
- ✓ IA-01..04 — shell-level orientation-strip parity on all 3 surfaces, in-library Operator Overview landing (`handle_params/3`, no router change), deliberate IA vocabulary, and explicit deep-link-fix decision validated in Phase 75
- ✓ DS-01..04 — unified `status_badge` atom replacing five `badge_class/1` copies, token migration off the raw scale, support-card Tier1/Tier2 hierarchy, and committed bundle validated in Phase 76
- ✓ MOTION-01..02 — six-motion vocabulary applied per UI-SPEC (mount-not-patch, record-keyed ids) and reduced-motion / ≤300ms / transform-opacity discipline validated in Phase 77
- ✓ SEED-01..02 — seed data making every screen state reachable by URL with same-commit demo/e2e assertion ripple and unchanged baseline pins validated in Phase 78
- ✓ VERIF-01..04 — full audit-matrix re-run vs baseline, extended structural e2e, conformance + bundle gates, and deep-link resolution/deferral validated in Phase 79

**By category (v1.4 — Inbound Stability Lock):**
- ✓ LOCK-01..03 — Canonical stable/testing/operator inventory, stable-vs-internal distinction, and explicit deferred inbound capability list validated in Phase 63
- ✓ PROOF-01..03 — Inbound compiled-doc proof, closed atom/type set docs locks, and over-claim/stale-release docs guards validated in Phase 64
- ✓ DX-01..04 — Canonical adoption path, operator semantics, testing semantics, and admin/operator trust boundaries validated in Phase 65
- ✓ REL-01..03 — Explicit `mailglass_inbound` `1.0.0` candidate decision, operational release notes, and feature-growth gate validated in Phase 66

**By category (v1.3 Phase 52 — trust baseline):**
- ✓ HOST-01..03 — Maintained reference host baseline, public-seam-only integration boundary, and fail-closed scope lock artifact/test contracts validated in Phase 52
- ✓ JOUR-01..02 — Canonical deterministic trust-runner command plus deterministic fixture/checkpoint schema and validator contract validated in Phase 57
- ✓ EVID-02, EVID-03 — Clean-baseline trust lane and published-version trust evidence gates validated in Phases 59-60, with current-release Hex proof closed in Phase 62
- ✓ OPS-01..02 — Release-gate drift prevention and smoke reliability guardrails validated in Phase 60
- ✓ DOCB-01..03 — Reference-host usage-proof boundary, canonical stability routing, and deterministic docs-contract enforcement validated in Phase 61

**By category (v1.1 — Inbound Core Slice):**
- ✓ MODEL-01 — Canonical `%MailglassInbound.InboundMessage{}` value object with stable fields for routing, tenancy, and provider provenance — v1.1
- ✓ ROUTE-01 — Inbound router DSL matching on recipient, subject, and headers, backed by compiled ordered route data and pure matcher engine — v1.1
- ✓ MAILBOX-01 — Mailbox behaviour with locked `:accept` / `:reject` / `:ignore` / `{:bounce, reason}` outcomes — v1.1
- ✓ INGRESS-01..02 — First-party Postmark + SendGrid ingress plugs with verify-first signature checks and sealed normalization into the canonical inbound model — v1.1
- ✓ STORE-01..02 — Tenant-safe persistence of normalized canonical data plus raw provider source evidence; replay over stored truth without re-receive ambiguity — v1.1
- ✓ EXEC-01..02 — Oban-backed async mailbox execution with bounded `Task.Supervisor` fallback and explicit warn-on-enter for the degraded path — v1.1
- ✓ ADOPT-01 — Canonical install / testing / operator-trust docs and repo-root release-proof coverage for the inbound sibling package — v1.1

**By category (v0.2 - Production-Credible Core):**
- ✓ API-01..07 — Mailable API redesign + native Message field setters + `api_stability.md` v2 + codemod task + deprecation warnings + migration guide
- ✓ STREAM-01..04 — Message-stream separation (`:transactional`/`:operational`/`:bulk`) + runtime + compile-time enforcement + stream-aware Feedback-ID
- ✓ UNSUB-01..06 — RFC 8058 List-Unsubscribe headers + signed-token controller + rotation + generator + property tests
- ✓ SUPP-01..05 — Auto-suppression on bounce/complaint/unsubscribe + soft-bounce escalation + resync mix task + default-deny pre-send check
- ✓ REL-01..16 — Release-engineering hardening: 9 v0.1.2 polish TODOs + Tests gate halt-on-failure + Credo strict + Dialyzer halt-exit-status + release ceremony (CHANGELOG, migration guide, Hex publish)

**By category (v0.1):**
- ✓ CORE-01..07 — Error hierarchy, Config, Telemetry whitelist, Repo.transact/1, IdempotencyKey, OptionalDeps gateway, boundary
- ✓ AUTHOR-01..05 — Mailable behaviour, HEEx components with MSO fallbacks, render pipeline <50ms, Gettext i18n, MJML opt-in
- ✓ PERSIST-01..06 — 3 tables (deliveries/events/suppressions), append-only trigger, idempotency partial UNIQUE, append/1 + append_multi/3, migration generator
- ✓ TENANT-01..03 — tenant_id on every schema, Tenancy behaviour + SingleTenant default, NoUnscopedTenantQueryInLib Credo enforcement
- ✓ TRANS-01..04 — Adapter behaviour, Fake (merge gate), Swoosh wrapper, Outbound facade
- ✓ SEND-01..05 — Preflight pipeline, ETS RateLimiter, Outbound.Worker, Suppression check_before_send, PubSub.Topics
- ✓ TRACK-01..03 — Off by default, NoTrackingOnAuthStream lint, signed Phoenix.Token rewriting
- ✓ HOOK-01..07 — CachingBodyReader, Postmark + SendGrid HMAC, Anymail taxonomy verbatim, one-Multi ingest, 1000-replay convergence
- ✓ COMP-01..02 — RFC headers, Feedback-ID
- ✓ PREV-01..06 — mailglass_admin sibling package, Router macro, PreviewLive with sidebar/tabs/device toggle, LiveReload, brand-conformant components, committed bundle
- ✓ TEST-01..05 — TestAssertions (4 matcher styles), per-domain Case templates, StreamData properties, real-provider sandbox advisory cron, Clock injection
- ✓ LINT-01..12 — 12 custom Credo checks operationalizing domain rules at lint time
- ✓ INST-01..04 — `mix mailglass.install` with idempotent sidecars, golden-diff CI, verify.phase aliases
- ✓ CI-01..07 — GHA workflows, single-cell required matrix, Conventional Commits, Release Please linked-versions, tarball whitelisted, Actions SHA-pinned, HEX_API_KEY in protected Environment
- ✓ DOCS-01..05 — ExDoc with 9 guides, migration-from-swoosh, doc-contract tests, governance files
- ✓ BRAND-01..03 — Brand-conformant UI + voice + docs

## Active

**v1.8 Brand System and Repo-Ready Brandbook is active as of 2026-06-05.**
Commit `572f3eb2` created draft `brandbook/` artifacts, but the milestone is not
complete. The next correct step is Phase 80 discussion/audit, followed by normal
planning and execution. This is a source-controlled brand-system milestone, not a
product-feature milestone.
Post-v1.8 feature posture remains **quiet maintenance / adopter-pull** per D-23
unless a concrete adopter need or contract gap justifies new scope.

Candidate carry-forward work (none committed):
- `/gsd-cleanup` to archive the leftover `.planning/phases/` execution history (71-79, 999.x) into milestone phase-archives.
- Pre-existing nil-guard tech debt in `operator_live.ex` / `suppression_card.ex` (CR-01/02/03) if an admin maintenance pass is opened.
- Promote backlog Phase 999.1 / 999.2 only via `/gsd-review-backlog` if adopter-pull justifies it.

## Out of Scope

Explicit boundaries with permanent reasoning to prevent re-litigation.

- **Marketing email** (campaigns, contact lists, segmentation, drip automations, A/B testing, broadcast scheduling) — that's [Keila](https://www.keila.io) / [Listmonk](https://listmonk.app) territory. Mailglass is forever **transactional + operational** mail.
- **Single-pane multi-channel notifications** (push, SMS, in-app, Slack alongside email) — that's a [Noticed](https://github.com/excid3/noticed)-shaped library with a different abstraction. Mailglass stays focused on email so it can be excellent at email.
- **Built-in subscriber management / preference center** — depends on having marketing concerns; if/when individual adopters need it, they can build it on the suppression + consent primitives mailglass exposes.
- **AMP for Email** — declared dead post-Cloudflare's October 2025 sunset; <5% adoption.
- **MJML as a default rendering path** — HEEx + Phoenix.Component with MSO fallbacks IS the default. MJML stays as opt-in `Mailglass.TemplateEngine.MJML` via the `mjml` Hex package.
- **Standalone ops console / SaaS dashboard** — `mailglass_admin` mounts in adopters' Phoenix apps; we don't run hosted infrastructure.
- **Backwards compatibility with Bamboo APIs** — Bamboo in maintenance mode; Swoosh is Phoenix 1.7+ default. Migration guide is from raw Swoosh + `Phoenix.Swoosh`.
- **Pre-Phoenix-1.8 / pre-LiveView-1.0 / pre-Elixir-1.18 support** — bleeding-edge floor (Elixir 1.18+, OTP 27+, Phoenix 1.8+, LiveView 1.0+, Ecto 3.13+).
- **Custom SMTP server** — `gen_smtp` for inbound relay is the floor; mailglass is not building or maintaining an SMTP daemon.
- **MySQL/SQLite support** — Postgres only. Advisory locks, JSONB, partial unique indexes, triggers are load-bearing.
- **Open/click tracking on by default** — privacy-first stance; legal liability on auth-carrying messages.
- **Open core / paid Pro tier** — MIT pure OSS across all sibling packages forever. No `mailglass_pro`.
- **Hosted SaaS Pro tier** — same as standalone ops console; we mount, never host.
- **Conductor-style inbound dev UI in `v1.1`** — the first inbound milestone proves routing, storage, and execution before adding a synthetic/replay LiveView surface.
- **Mailgun / SES / `gen_smtp` relay ingress in `v1.1`** — the first inbound milestone proves the package on Postmark + SendGrid before broadening provider or transport scope.
- **Provider-matrix broadening in `v1.3`** — trust proof is a single representative journey, not a breadth expansion milestone.
- **`SEED-003-ecosystem-integrations` auto-promotion in `v1.3`** — remains deferred until trust proof and inbound stability lock are complete.
- **Transport-class expansion (`gen_smtp` listener) in `v1.3`** — requires a dedicated milestone with separate threat model and ops burden review.

## Context

**The gap mailglass fills.** Swoosh is the canonical Phoenix mailer (39k downloads/month, healthy maintenance, extensible). It is excellent at the `compose → adapter → deliver` primitive. But everything around it — responsive templates, preview dashboards, normalized webhook events, suppression enforcement, signed unsubscribe, inbound routing, admin tooling, deliverability tooling — is left to each project to rebuild. The 2024 Gmail/Yahoo bulk-sender rules, React Email's emergence, and Phoenix 1.7's removal of `Phoenix.View` made the timing acute.

**Position relative to the ecosystem.** Mailglass is **not** a Swoosh replacement; it composes on top. It is **not** Bamboo (maintenance mode). It is **not** Keila (newsletter application, AGPLv3, not embeddable). It IS the missing framework layer between Swoosh's transport and a senior Phoenix team's transactional email needs.

**Engineering DNA inherited from prior libraries** (accrue, lattice_stripe, sigra, scrypath):

- Pluggable behaviours over magic — narrow callbacks, minimal surface
- Errors as a public API contract — structured `Mailglass.Error.t()` with closed `:type` atom set, `:cause` excluded from `Jason.Encoder`, one mapper per provider
- Telemetry as first-class — `[:mailglass, :domain, :resource, :action, :start | :stop | :exception]` 4-level naming, never raise from handlers, never include PII
- Append-only event ledger with Postgres trigger immutability — every mutation flows through `Ecto.Multi` that includes a `mailglass_events` row; SQLSTATE 45A01 on UPDATE/DELETE
- Sibling packages with linked-version releases — Release Please with `separate-pull-requests: false` + linked-versions plugin
- Fake adapter as required release gate — real-provider sandbox tests advisory only (daily cron + `workflow_dispatch`)
- Custom Credo checks for domain rules — domain invariants enforced at lint time
- Continuous phase counter & evidence-led backlog triage — the `.planning/` discipline this very document is part of

**Brand voice.** mailglass is "clear, exact, confident (not cocky), warm (not cute), modern (not trendy), technical (not intimidating)." The voice is "a thoughtful maintainer." Errors are specific and composed ("Delivery blocked: recipient is on the suppression list" — never "Oops!"). Documentation prefers the direct word ("preview" over "experience the full rendering lifecycle"). Visual palette: **Ink** #0D1B2A, **Glass** #277B96, **Ice** #A6EAF2, **Mist** #EAF6FB, **Paper** #F8FBFD, **Slate** #5C6B7A. Typography: Inter (UI/body), Inter Tight (display), IBM Plex Mono (code). Mobile-first responsive. No glassmorphism, bevels, lens flares, or "literal broken glass" visuals.

**Target persona / JTBD.** Senior or technical-lead Phoenix developers shipping production transactional email for SaaS apps. Common JTBDs: "let me ship a welcome email I can preview before deploying," "let me trust my password-reset deliveries," "let me audit why a customer's receipt didn't arrive," "let me operationalize bounce/complaint handling without rolling my own webhook plumbing," "let me support multiple tenants with different sending domains."

**Prior research artifacts** (preserved in `prompts/`, source of truth for vocabulary + conventions):

- `Phoenix needs an email framework not another mailer.md` — the founding thesis
- `mailglass-brand-book.md` — visual identity, voice, palette
- `mailer-domain-language-deep-research.md` — canonical vocabulary (Mailable / Message / Delivery / Event / InboundMessage / Mailbox / Suppression)
- `mailglass-engineering-dna-from-prior-libs.md` — engineering patterns distilled
- Various Elixir/Ecto/Phoenix/LiveView/Plug/OSS-CI/CD best-practices research files

## Constraints

- **Tech stack**: Elixir 1.18+ / OTP 27+ / Phoenix 1.8+ / LiveView 1.0+ / Ecto 3.13+ / Postgres (Postgrex). Bleeding-edge floor.
- **Required deps**: `:ecto_sql`, `:postgrex`, `:phoenix`, `:swoosh`, `:nimble_options`, `:telemetry`, `:gettext`, `:premailex`, `:floki`. Hard required from v0.1.
- **Optional deps**: `:oban`, `:opentelemetry`, `:sigra`, `:mjml`, `:gen_smtp`. CI must pass `mix compile --no-optional-deps --warnings-as-errors`.
- **Persistence**: Postgres only. MySQL/SQLite explicitly not supported.
- **Phoenix coupling**: Phoenix is a hard dep; mailglass is unapologetically Phoenix-first.
- **License**: MIT across all sibling packages, forever.
- **Distribution**: Hex.pm only. Source on GitHub. No standalone npm packages, no compiled binaries, no Node toolchain anywhere.
- **Compliance**: RFC 8058, 2024 Gmail/Yahoo bulk-sender rules, US CAN-SPAM, GDPR-shaped consent + suppression audit trail.
- **Privacy**: open/click tracking off by default. Telemetry metadata never includes recipient addresses, message bodies, or response payloads.
- **Security**: webhook signature failures raise `Mailglass.SignatureError` at call site — no recovery from forged webhooks. Unsubscribe tokens are signed with rotation support.
- **Maintenance budget**: one-person maintainer realistic; v0.1 must be coastable for 6 months without releases. Provider/compliance churn is expected to consume 20–30% of maintenance time forever.

## Key Decisions

| ID | Decision | Rationale | Outcome |
|----|----------|-----------|---------|
| D-01 | Sibling packages from v0.1 (`mailglass`, `mailglass_admin`, `mailglass_inbound` v0.5+) | Per accrue/sigra DNA — admin is mounted in adopters' apps, not run standalone; linked-version releases via Release Please | ✓ Validated v0.1 — Release Please linked-versions works; `mailglass_admin/mix.exs` pins `{:mailglass, "== <ver>"}` |
| D-02 | MIT license across all packages | Aligns with Swoosh/Phoenix/Ecto; maximizes adoption | ✓ Held v0.1 |
| D-03 | Marketing email **permanently** out of scope | Different problem (lists/segments/campaigns), different compliance surface, different abstraction | ✓ Held v0.1 |
| D-04 | Single-pane multi-channel notifications **out** | That's a Noticed-shaped lib; mailglass stays email-only | ✓ Held v0.1 |
| D-05 | Inbound (Action Mailbox equivalent) **in scope** as `mailglass_inbound` sibling package | Inbound webhook plumbing shares HMAC + plug + event-normalization infrastructure with the existing mailglass delivery and webhook foundation | ✓ Validated v1.1 — `mailglass_inbound` opened with Postmark + SendGrid ingress, replayable persistence, Oban-optional execution |
| D-06 | Bleeding-edge version floor (Elixir 1.18+ / OTP 27+ / Phoenix 1.8+ / LiveView 1.0+ / Ecto 3.13+) | Newest features (streams, async, scopes, schema_redact, colocated hooks); smallest CI matrix | ✓ Validated v0.1 — Elixir 1.19 type checker forced struct-discrimination tests via `__struct__` comparison (worked, with documented workaround) |
| D-07 | Ecto + Phoenix **required**; Oban **optional** | mailglass is a Phoenix-first framework; `deliver_later/2` degrades to `Task.Supervisor` with a warning when Oban absent | ✓ Validated v0.1 — Outbound.Worker conditionally compiled; Task.Supervisor fallback path tested |
| D-08 | Open/click tracking **off by default** | Apple Mail Privacy Protection makes opens noisy; auth-carrying messages must NEVER have rewritten links | ✓ Validated v0.1 — NoTrackingOnAuthStream Credo check operationalizes |
| D-09 | Multi-tenancy **first-class from v0.1** | Phoenix 1.8 scopes default makes this the right time; harder to retrofit | ✓ Held v0.1 — `tenant_id` on every schema |
| D-10 | v0.1 normalizes **Postmark + SendGrid** webhooks; Mailgun/SES/Resend land in v0.5 | Most-used per Anymail data; smallest validation matrix | ✓ Held v0.1 |
| D-11 | Preview LiveView is **dev-only at v0.1**, prod admin lands at v0.5 | v0.1 surface stays scoped; admin UI needs event taxonomy maturity | ✓ Held v0.1 |
| D-12 | Full `mix mailglass.install` with golden-diff CI from v0.1 | "Batteries-included" brand promise demands one-command setup | ✓ Validated v0.1 — Phase 07.1 closed installer blockers G-1..G-5 (real `Apply.run` driving golden test) |
| D-13 | Test pyramid: doctests + ExUnit + StreamData property + Mox + **Fake adapter release gate** + real-provider sandbox advisory only | Per accrue DNA — real provider tests on daily cron + `workflow_dispatch`, never block PRs | ✓ Held v0.1 |
| D-14 | Anymail event taxonomy **verbatim** for normalized webhook events | Don't reinvent; multi-language standard; lowers cognitive cost for polyglot teams | ⚠ Held with one amendment — `:reconciled` is `@mailglass_internal_types` (audit-only), never emitted by provider mappers |
| D-15 | `mailglass_events` table is **append-only**, enforced by Postgres trigger raising SQLSTATE 45A01 | Per accrue DNA — single source of truth; immutability is structural, not policy | ✓ Validated v0.1 — `Mailglass.Repo` write path translates SQLSTATE at four sites |
| D-16 | Conventional Commits + Release Please + sibling-linked-version automation; Hex publish from protected ref only | Per OSS CI/CD best practices; squash-merge workflow keeps casual contributor UX low-friction | ✓ Validated v0.1 — release-please extra-files no-op surfaced; mitigated with workflow sed step |
| D-17 | Custom Credo checks enforce domain rules | Per engineering DNA — invariants caught at lint time, not just runtime | ✓ Validated v0.1 — 12 checks operational |
| D-18 | Renderer default is HEEx + `Phoenix.Component` with MSO VML fallbacks; MJML opt-in via `:mjml` Hex package (NOT `:mrml`) | Native composition, no Node, killer differentiator vs React Email + Mailing | ✓ Held v0.1 |
| D-19 | Brand voice & visual identity locked to `prompts/mailglass-brand-book.md` | Brand discipline prevents drift toward generic SaaS or growth-marketing aesthetic | ✓ Held v0.1 |
| D-20 | Domain vocabulary locked to `prompts/mailer-domain-language-deep-research.md` | Borrowed from battle-tested libs; avoid "Email" or "Status" as ambiguous primitives | ✓ Held v0.1 |
| D-21 | Adapter call between Multi#1 and Multi#2 (never inside transaction) | Postgres pool starvation prevention | ✓ Held v0.1 — Phase 3 Outbound enforces |
| D-22 | The first `mailglass_inbound` milestone stays narrow: Postmark + SendGrid ingress, normalized plus raw replayable storage, and Oban-optional execution; Conductor/Mailgun/SES/SMTP are deferred | Protect the locked `v1.x` core and make the first sibling-package expansion supportable for a one-person maintainer | ✓ Validated v1.1 — narrow scope held; Conductor / Mailgun / SES / `gen_smtp` remained deliberately deferred |
| D-23 | Post-v1.3 project posture shifts from broad capability expansion to convergence, stability, and maintenance by default | Core/admin have crossed the original product-complete threshold; endless polish or provider breadth has diminishing returns unless tied to adopter pull | ✓ Validated v1.4 — inbound contract posture is locked, `mailglass_inbound` has a `1.0.0` candidate, and future work defaults to release ceremony / maintenance unless adopter pull or contract gaps justify scope |
| D-24 | v1.7 admin UI polish is a sanctioned **adopter-visible-quality** investment under the D-23 convergence rule (not feature growth); delivered **within** the brand book (Fork B) by *applying* the shipped design system more completely, with a real in-library Operator Overview landing + generalized orientation (Fork A) | First-run/forensic UX quality is the highest-leverage remaining adopter lever now that the product surface is complete; restraint (no brand amendment, no new deps, grep-enforceable conformance) keeps it convergence-aligned, not scope creep | ✓ Validated v1.7 — anti-churn gate held (every build task cited a sev≥3 gap-register row), stable seams untouched, no new deps, conformance grep-enforced; audit passed 19/19; linked-version admin bump confirmed mechanical |
| D-25 | v1.8 brand-system work is a repo-artifact milestone, not product expansion | Mailglass had strong prompt-era brand direction but lacked source-controlled, buildable collateral for maintainers, future agents, docs, landing pages, tokens, logos, and marketing copy | Active v1.8 — all artifacts stay under `brandbook/`; no public API/package code changes; no binary-heavy collateral; prompt-era brand strategy preserved |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions with `D-NN` ID
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state
5. Brand voice / domain vocabulary still aligned with `prompts/` source-of-truth files? Reconcile any drift.

**Release-cadence rule (added 2026-05-06 — see ROADMAP.md):** Each milestone closes with a release ceremony to Hex.pm before the next milestone implementation starts. Convention: a `Phase X.5` numbered between the last feature phase of milestone N and the first feature phase of milestone N+1 (e.g. Phase 44.5 between v1.1 and v1.2). The 4-milestone-deep gap that accumulated between `v0.3.2` and `1.0.0` (v0.5 + v0.6 + v1.0 + v1.1 all unreleased on Hex while milestone planning labels marched forward) is the failure mode this rule prevents. Milestone "shipped" status now requires both planning-archive completion AND Hex publish — not just one.

---
*Last updated: 2026-06-12 after shipping **v1.9 Brand Book Fable — A/B Brand System** (22/22 requirements verified, maintainer A/B sign-off). Next decision: adopt the fable book as canonical `brandbook/` in a future milestone.*
