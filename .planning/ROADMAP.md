# Roadmap: mailglass

**Granularity:** standard (config.json)

## Milestones

- ✅ **v0.1 Validation Release** - Phases 1-7 + 07.1 (shipped 2026-04-26) - see [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- ✅ **v0.2 Production-Credible Core** - Phases 8-13 (shipped 2026-04-28) - see [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)
- ✅ **v0.3 Webhook Coverage Complete** - Phases 14-21 (shipped 2026-04-30) - see [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Operator Confidence** - Phases 22-27 (shipped 2026-05-02) - see [milestones/v0.4-ROADMAP.md](milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 Adoption Hardening** - Phases 28-31 (shipped 2026-05-03) - see [milestones/v0.5-ROADMAP.md](milestones/v0.5-ROADMAP.md)
- ✅ **v0.6 Production Maturity** - Phases 32-34 (shipped 2026-05-05) - see [milestones/v0.6-ROADMAP.md](milestones/v0.6-ROADMAP.md)
- ✅ **v1.0 Stability Lock** - Phases 35-38 (shipped 2026-05-06) - see [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Inbound Core Slice** - Phases 39-44 (shipped 2026-05-06) - see [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Inbound Production Confidence** - Phases 44.5, 45-50, 50.5, 50.7, 51 (shipped 2026-05-26) - see [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Adopter Trust Proof** - Phases 52, 57-62 (shipped 2026-05-31) - see [milestones/v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 Inbound Stability Lock** - Phases 63-66 (shipped 2026-06-01) - see [milestones/v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 Demo Evidence and Click-Around Confidence** - Phases 67-70 (shipped 2026-06-02) - see [milestones/v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 Inbound 1.0 Release and Truth Lock** - Phases 71-73 (shipped 2026-06-02) - see [milestones/v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 Admin UI - IA & Design-System Polish v2** - Phases 74-79 (shipped 2026-06-05) - see [milestones/v1.7-ROADMAP.md](milestones/v1.7-ROADMAP.md)
- ✅ **v1.8 Brand System and Repo-Ready Brandbook** - Phases 80-84 (closed superseded 2026-06-11; audit verdict gaps_found, accepted) - see [milestones/v1.8-ROADMAP.md](milestones/v1.8-ROADMAP.md) and [milestones/v1.8-MILESTONE-AUDIT.md](milestones/v1.8-MILESTONE-AUDIT.md)
- ✅ **v1.9 Brand Book Fable — A/B Brand System** - Phases 85-90 (shipped 2026-06-12) - see [milestones/v1.9-ROADMAP.md](milestones/v1.9-ROADMAP.md)
- ✅ **v1.10 Brand Adoption** - Phases 91-93 (shipped 2026-06-13) - see [milestones/v1.10-ROADMAP.md](milestones/v1.10-ROADMAP.md) and [milestones/v1.10-MILESTONE-AUDIT.md](milestones/v1.10-MILESTONE-AUDIT.md)
- ✅ **v1.11 mailglass_admin Design-System Uplift** - Phases 94-103 (shipped 2026-06-16) - see [milestones/v1.11-ROADMAP.md](milestones/v1.11-ROADMAP.md) and [milestones/v1.11-MILESTONE-AUDIT.md](milestones/v1.11-MILESTONE-AUDIT.md)
- ✅ **v1.12 Adopter Onboarding & Day-2 Confidence** - Phases 104-108 (shipped 2026-06-17) - see [milestones/v1.12-ROADMAP.md](milestones/v1.12-ROADMAP.md) and [milestones/v1.12-MILESTONE-AUDIT.md](milestones/v1.12-MILESTONE-AUDIT.md)
- ✅ **v1.13 Admin Design-System Stress Test & UX Uplift (v3)** - Phases 109-117 (shipped 2026-06-21) - see [milestones/v1.13-ROADMAP.md](milestones/v1.13-ROADMAP.md) and [milestones/v1.13-MILESTONE-AUDIT.md](milestones/v1.13-MILESTONE-AUDIT.md)
- ✅ **v1.14 Operator IA & Lived-Experience Redesign** - Phases 118-124 (shipped 2026-06-30 — mailglass 1.10.1 / mailglass_admin 1.10.1 / mailglass_inbound 1.5.3) - see [milestones/v1.14-ROADMAP.md](milestones/v1.14-ROADMAP.md) and [milestones/v1.14-MILESTONE-AUDIT.md](milestones/v1.14-MILESTONE-AUDIT.md)

🚧 **v1.15 Release-Pipeline Efficiency & Contributor DX** — Phases 125-131 (active, opened 2026-07-01) — decisions of record: [research/milestone-cicd/SYNTHESIS.md](research/milestone-cicd/SYNTHESIS.md)

## Phases (Active — v1.15)

**Milestone goal:** Kill the exact-pin release dance and close the local↔CI parity gap — make
releases genuinely hands-free and make **one command reproduce the mergeable surface** — with zero
product-behavior change, then cut a real linked Hex release that dogfoods the hardened pipeline.
Decisions of record (LD-1..13): `.planning/research/milestone-cicd/SYNTHESIS.md`. Infrastructure/DX
only — D-23 convergence holds; no product code, no schema change (that is v2.0).

- [ ] **Phase 125: Sibling-pin loosening (keystone, atomic)** — Replace both `{:mailglass, "== X.Y.Z"}` pins with `~>` (inbound `~> 1.10 and >= 1.10.2`, admin `~> 1.10`), relax `stability_contract_test` + `publish.check` to admit-not-equal, delete the `==` sed rewrites from `release-please.yml`, ship the CHANGELOG + Hex-retirement rollback note — as ONE indivisible change. **Requirements:** PIN-01..05. **Success:** (1) both siblings resolve core from Hex under `~>` with `MIX_PUBLISH=true`; (2) the relaxed contract test passes on a bare main SHA where core `@version` is unchanged (the scenario that was red before); (3) a simulated core patch release touches zero sibling pin lines; (4) `publish.check` passes for all three packages.
- [ ] **Phase 126: CI Green fan-in gate + branch-protection collapse** — Add the `CI Green` aggregate job (release-SHA-safe `skipped` handling), collapse branch protection to `CI Green` + `guard-release-trigger`, add the set-equality coverage meta-test, verify `guard-release-trigger` always reports, fix the `gate-self-test` stale default. **Requirements:** GATE-01..04. **Success:** (1) a synthetic failing PR shows `CI Green` = FAILURE and is blocked; (2) a fully-green PR is mergeable without `--admin`; (3) the meta-test fails if a required lane is dropped from `needs`; (4) `gate-self-test` polls the real gate.
- [ ] **Phase 127: Inbound test determinism** — Root-cause fix for the shared-mode/async sandbox flake (`MailboxCase` serial + drop `shared:`); delete `--seed 0` everywhere. **Requirements:** DET-01..02. **Success:** (1) the inbound suite is green across 20 random-seed runs; (2) `--seed 0` appears nowhere in `ci.yml` or the `mix ci` alias; (3) `grep shared: mailbox_case.ex` is empty.
- [x] **Phase 128: `mix ci` parity completion (folds in PR #104)** — Complete `mix ci` to equal the mergeable surface (add Installer Host Smoke + trust lane); tiered `ci.fast`/`ci`/`ci.browser` + sibling aliases + `make ci`; manifest-membership parity-drift test (shared source with GATE-03); Postgres/network preflight brand-voice guard; designate `verify.*` internal + remove deprecated `verify.phase_NN`; land the CONTRIBUTING copy. **Requirements:** MIXCI-01..05. **Success:** (1) `mix ci` runs all 5 required gates; (2) the parity-drift test fails when a required CI lane isn't covered by the alias; (3) `mix ci` with no Postgres prints an actionable brand-voice message, not a raw crash; (4) CONTRIBUTING points at `mix ci`, no `verify.phase_07`. (completed 2026-07-01)
- [ ] **Phase 129: Cache-key + PLT correctness** — Toolchain-scoped cache key derived from a single `.tool-versions`/`env:` source; Bandit-style PLT self-healing eviction; only then may Dialyzer move toward required. **Requirements:** CACHE-01..02. **Success:** (1) cache keys in Actions logs carry OTP+Elixir dims from one source; (2) a corrupted PLT is evicted and rebuilt by the workflow; (3) no per-block hardcoded toolchain literals remain.
- [ ] **Phase 130: Supply chain + workflow hygiene** — `mix_audit` advisory-on-PR / block-at-release; dependabot sibling-dir coverage; cowlib OSV-staleness forcing function (loud CI warning + publish hard-block, fail-open); `actionlint` on workflow PRs; latest-Elixir 1.19/OTP28 advisory row (non-blocking) + floor-coincidence note. **Requirements:** SUPPLY-01..05. **Success:** (1) a simulated unfixable advisory reds the publish gate but NOT open PRs; (2) dependabot watches both sibling locks; (3) `actionlint` fails a malformed workflow PR; (4) the 1.19/28 row runs on cron only and never blocks.
- [ ] **Phase 131: Release cut + milestone closeout** — Cut the real linked v1.15 (core+admin linked; inbound minor for the dependency-policy change) through the hardened pipeline; consumer + post-publish smoke; milestone audit + archive. **Requirements:** SHIP-01..03. **Success:** (1) v1.15 live on Hex, `~>` pins resolve from Hex; (2) consumer + post-publish smoke green; (3) the release ceremony was a confirmation (per-phase CI caught regressions earlier); (4) milestone audited + archived.

**Execution order:** 125 → 126 → 127 → 128 → 129 → 130 → 131 (dependency-ordered, biggest-leverage
first). **125 is the keystone** — it unblocks every future release and is internally atomic. **127
precedes 128** (the `mix ci` inbound step must consume the `--seed 0` deletion). **129 precedes any
Dialyzer promotion** (PLT self-healing must exist before Dialyzer can block merges — LD-7). **131 is
last** and cuts the real release, validating the whole pipeline end-to-end (LD-1).

**Method:** dogfood the v1.14-post-mortem backlog fix — each phase pushes a `phase/NN` branch and
requires green CI, so the release ceremony is a confirmation, not a discovery.

**Research flags:** none — the milestone is research-complete (decision-ready dossiers +
`SYNTHESIS.md` adversarial refinement). All phases plan directly.

## Phase Details (Active — v1.15)

> Decisions of record for every phase below: `.planning/research/milestone-cicd/SYNTHESIS.md`
> (LD-1..13). Live versions at milestone open: `mailglass` 1.10.2 / `mailglass_admin` 1.10.2 /
> `mailglass_inbound` 1.5.4.

### Phase 125: Sibling-pin loosening (keystone, atomic)

**Goal**: Replace both `{:mailglass, "== X.Y.Z"}` sibling pins with pessimistic `~>` constraints and
relax every gate that enforced exact equality — as ONE indivisible change — so a core patch release no
longer drags a paired sibling release. This is the keystone: it unblocks every future release.
**Depends on**: Nothing (first phase of v1.15; keystone for the whole milestone)
**Requirements**: PIN-01, PIN-02, PIN-03, PIN-04, PIN-05
**Success Criteria** (what must be TRUE):

  1. Both siblings resolve core from Hex under `~>` with `MIX_PUBLISH=true` — inbound pinned
     `{:mailglass, "~> 1.10 and >= 1.10.2"}` (floored at the V05 deliveries-migration fix), admin
     `{:mailglass, "~> 1.10"}` (safe via the linked-versions plugin) (LD-2).

  2. `stability_contract_test` (:105 regex, :154–159 assertion) and `publish.check`
     (`verify_deps`, `verify_linked_constraint`) assert the sibling pin *admits* core `@version` via
     `Version.match?` and is pessimistic (`~>`), rejecting `==` — the relaxed contract passes on a bare
     main SHA where core `@version` is unchanged (the exact scenario that was red before) (LD-3).

  3. The two `== X.Y.Z` sed rewrites are deleted from `release-please.yml`; a simulated core patch
     release touches zero sibling pin lines (LD-3).

  4. The change ships a CHANGELOG entry and documents `mix hex.retire mailglass X.Y.Z` as the rollback
     lever that replaces the `==` wall (LD-5); `publish.check` passes for all three packages.

  5. The whole change lands atomically — splitting any part reds main or miscuts the next release (the
     sed anchor would match zero `==` lines) (LD-3).
**Plans**: 1 plan

- [x] 125-01-PLAN.md — Loosen both sibling `==` pins to `~>` (inbound `~> 1.10 and >= 1.10.2`, admin `~> 1.10`), relax stability_contract_test + publish.check + admin mix_config_test to admit-`~>`-reject-`==`, delete the two `== X.Y.Z` sed rewrites (retire the 3 dead sed-anchor gates), ship CHANGELOG entries + `mix hex.retire` rollback doc — as ONE atomic change (PIN-01..05)

**UI hint**: no

### Phase 126: CI Green fan-in gate + branch-protection collapse

**Goal**: Collapse the 5 required leaf branch-protection contexts into a single `CI Green` aggregate
job (plus `guard-release-trigger`), with release-SHA-safe `skipped` handling and a set-equality
coverage meta-test so no required lane can silently drop out of `needs`.
**Depends on**: Phase 125 (the pin change must be green first; the keystone lands before pipeline gates
are re-shaped)
**Requirements**: GATE-01, GATE-02, GATE-03, GATE-04
**Success Criteria** (what must be TRUE):

  1. A single `CI Green` aggregate job (`if: always()`, explicit `needs`) is the sole required
     branch-protection context alongside `guard-release-trigger`, replacing the 5 leaf contexts
     (GATE-01); a synthetic failing PR shows `CI Green` = FAILURE and is blocked; a fully-green PR is
     mergeable without `--admin`.

  2. On the release/publish path a required lane must be `success` — a `skipped` required lane does NOT
     count as green (LD-6, GATE-02).

  3. A coverage meta-test asserts set-equality between `setup_branch_protection.sh` `REQUIRED_CHECKS`,
     `ci-green.needs`, and the actual job set (not superset), and that no required lane is permanently
     `if:`-disabled; it fails if a required lane is dropped from `needs` (GATE-03).

  4. `guard-release-trigger` is verified to always report (no green-but-BLOCKED regression) and
     `gate-self-test.yml`'s stale `check_name` default is corrected to `CI Green` (GATE-04).
**Plans**: 2 plans

- [x] 126-01-PLAN.md — Add the `CI Green` aggregate job (`if: always()`, `needs` = the 5 required leaves) + a hand-rolled `changes` detection gate (drops the workflow-level `paths-ignore` so `CI Green` always reports), collapse `REQUIRED_CHECKS` to `{CI Green, Guard Release Trigger}`, and extend `required_checks_test.exs` to the set-equality coverage meta-test (GATE-01, GATE-03)
- [x] 126-02-PLAN.md — Enforce required-lane-must-be-`success` on the publish path (`REQUIRED_LANES` set; skipped required lane blocks), fix the `gate-self-test.yml` stale `Tests (` default → `CI Green`, and add the `guard-release-trigger` always-reports invariant test (GATE-02, GATE-04)

**UI hint**: no

### Phase 127: Inbound test determinism

**Goal**: Root-cause-fix the shared-mode/async sandbox flake in the inbound suite so it is
deterministic by construction, then delete `--seed 0` everywhere. Precondition for the `mix ci` inbound
step (Phase 128).
**Depends on**: Phase 126 (lands on the hardened gate; determinism precedes the `mix ci` inbound step)
**Requirements**: DET-01, DET-02
**Success Criteria** (what must be TRUE):

  1. The shared-mode/async sandbox flake is fixed at the root — `MailboxCase` defaults `async: false`,
     drops `shared:`, uses a plain ownership checkout (Option B) — so the suite is deterministic by
     construction (LD-8); `grep shared: mailbox_case.ex` is empty.

  2. `--seed 0` is deleted from `ci.yml` and the `mix ci` alias and appears nowhere; the inbound suite
     is green across 20 random-seed runs (DET-02). Any `|| mix test --failed` retry idiom is kept only
     as a time-boxed transition net with a removal date (LD-8).
**Plans**: 1 plan
Plans:

- [x] 127-01-PLAN.md — Fix MailboxCase (async: false default, drop shared:), update docs, delete --seed 0 from ci.yml; prove 20-seed determinism

**UI hint**: no

### Phase 128: `mix ci` parity completion (folds in PR #104)

**Goal**: Complete `mix ci` so it equals the mergeable surface (add Installer Host Smoke + trust lane),
ship tiered `ci.fast`/`ci`/`ci.browser` aliases + sibling aliases + `make ci`, a manifest-membership
parity-drift test, brand-voice preflight guards, and the CONTRIBUTING copy. Folds in and completes the
open PR #104 DX slice.
**Depends on**: Phase 127 (the `mix ci` inbound step must consume the `--seed 0` deletion)
**Requirements**: MIXCI-01, MIXCI-02, MIXCI-03, MIXCI-04, MIXCI-05
**Success Criteria** (what must be TRUE):

  1. `mix ci` equals the mergeable surface — runs all 5 required gates including Installer Host Smoke
     and the reference-host trust lane (LD-10, MIXCI-01).

  2. Tiered env-pinned aliases exist — `mix ci.fast` (seconds, no DB), `mix ci` (full parity),
     `mix ci.browser` (opt-in Node) — with sibling-local `ci`/`ci.fast` aliases and a discoverable
     `make ci`/`make help` wrapper (MIXCI-02).

  3. A manifest-membership parity-drift test asserts `ci` ∪ `ci.browser` covers every required+advisory
     CI lane by identity + flag-set (shared `ci_lanes` source with GATE-03), failing loudly on drift —
     not a vacuous substring superset (LD-10, MIXCI-03).

  4. `mix ci`/`ci.setup` preflight-probe Postgres (and the installer step probes network) and print a
     brand-voice actionable message on absence, never a raw connection crash (LD-12, MIXCI-04).

  5. `verify.*` are designated internal composition targets, the deprecated `verify.phase_NN`
     pass-throughs are removed, and CONTRIBUTING points at `mix ci`/`mix ci.fast` (only once MIXCI-01
     holds), with no `verify.phase_07` 404 (LD-12, MIXCI-05).
**Plans**: 2 plans

- [x] 128-01-PLAN.md — ci alias family (ci.fast/ci/ci.setup/ci.browser) + sibling aliases + preflight guards + make ci + CONTRIBUTING + remove deprecated pass-throughs (MIXCI-01/02/04/05)
- [x] 128-02-PLAN.md — shared ci_lanes source + GATE-03 rewire + MIXCI-03 parity-drift test (MIXCI-03)

**UI hint**: no

### Phase 129: Cache-key + PLT correctness

**Goal**: Derive the deps/`_build` cache key from a single toolchain source (kill the ~15 hardcoded
`otp27-ex1.18` literals) and add Bandit-style self-healing PLT eviction — the precondition before
Dialyzer can move toward the required set.
**Depends on**: Phase 128 (pipeline DX complete; cache/PLT correctness precedes any Dialyzer promotion)
**Requirements**: CACHE-01, CACHE-02
**Success Criteria** (what must be TRUE):

  1. The deps/`_build` cache key includes OTP+Elixir dims derived from a single `.tool-versions`/`env:`
     source (not per-block hardcoded literals) with a per-env prefix; cache keys in Actions logs carry
     OTP+Elixir dims from one source and no per-block hardcoded toolchain literals remain (LD-9,
     CACHE-01).

  2. The PLT cache uses Bandit-style self-healing eviction — a corrupted/stale PLT is evicted and
     rebuilt by the workflow; only after this may Dialyzer be promoted toward the required set (LD-7,
     CACHE-02).
**Plans**: TBD (planning)
**UI hint**: no

### Phase 130: Supply chain + workflow hygiene

**Goal**: Add supply-chain and workflow-hygiene guards that never red an open PR under an unfixable
advisory wave — `mix_audit` advisory-on-PR/block-at-release, dependabot sibling coverage, a cowlib
OSV-staleness forcing function (fail-open), `actionlint` on workflow PRs, and a non-blocking
latest-Elixir advisory row.
**Depends on**: Phase 129 (advisory-row + Dialyzer sequencing rests on the cache/PLT fix)
**Requirements**: SUPPLY-01, SUPPLY-02, SUPPLY-03, SUPPLY-04, SUPPLY-05
**Success Criteria** (what must be TRUE):

  1. `mix deps.audit` runs advisory (non-blocking) on PR and blocking only at the publish gate — a
     simulated unfixable advisory reds the publish gate but NOT open PRs (LD-4, SUPPLY-01).

  2. `dependabot.yml` watches the `mailglass_admin` and `mailglass_inbound` sibling locks (not the
     frozen reference baselines) (SUPPLY-02).

  3. The cowlib allowlist has a forcing function — OSV-staleness is a loud CI warning on every run + a
     hard block at publish, fail-open on OSV API outage (LD-4, SUPPLY-03).

  4. `actionlint` gates `.github/workflows/**` changes on PR and fails a malformed workflow PR
     (LD-11, SUPPLY-04).

  5. A latest-Elixir advisory row (1.19 / OTP 28) runs non-blocking on push+cron only and never blocks;
     the floor-coincidence invariant (LD-13) is documented (SUPPLY-05).
**Plans**: TBD (planning)
**UI hint**: no

### Phase 131: Release cut + milestone closeout

**Goal**: Cut the real linked v1.15 Hex release through the hardened pipeline (core+admin linked;
inbound a minor bump for the dependency-policy change), prove consumer + post-publish smoke, and audit +
archive the milestone — validating the whole pipeline end-to-end.
**Depends on**: Phase 130 (everything hardened and green before the real release ceremony)
**Requirements**: SHIP-01, SHIP-02, SHIP-03
**Success Criteria** (what must be TRUE):

  1. A real linked Hex release is cut through the hardened pipeline — core+admin linked, inbound a
     **minor** bump for the dependency-policy change — and v1.15 is live on Hex with `~>` pins resolving
     from Hex (LD-1, SHIP-01).

  2. Consumer + post-publish smoke pass against the published packages; the `~>` pins resolve correctly
     from Hex (SHIP-02).

  3. The release ceremony was a confirmation (per-phase "CI-the-body" method — push `phase/NN`, require
     green CI — caught regressions earlier); the milestone is audited against intent and archived
     (SHIP-03).
**Plans**: TBD (planning)
**UI hint**: no

## Phases (Archived — v1.14, shipped 2026-06-30)

**Milestone goal:** Invert the admin-UI quality method to **top-down, JTBD/IA-led**, add a
**judgment-level adversarial persona-critic review loop** that catches taste/redundancy/IA problems
structural gates can't, and redesign the four admin/operator surfaces **page-by-page,
biggest-impact-first** to ruthlessly de-duplicated, Apple-like deliberate IA — then ship to Hex.
Binding quality bar: `.planning/research/v1.14/STRESS-TEST-PROMPT.md` (do not dilute).

- [x] **Phase 118: Method, Audit & Storybook stand-up** - Persona-critic harness + screenshot-backed defect register; phoenix_storybook dev-only review surface; new judgment gates drafted; floor inherited (completed 2026-06-26)
- [x] **Phase 119: App-shell + Nav + Overview redesign** - The keystone #1-pain surface: fix the false-active-nav bug, give Overview its own identity, kill redundant nav cards, make health stats actionable (completed 2026-06-26)
- [x] **Phase 120: Deliveries surface redesign** - Core operator JTBD redesigned to a streamlined, non-info-dump IA across the full matrix (completed 2026-06-27)
- [x] **Phase 121: Inbound surface redesign** - Inbound brought consistent with the cleaned-up Deliveries patterns across the full matrix (completed 2026-06-28)
- [x] **Phase 122: Preview surface redesign** - Preview brought consistent with the established patterns across the full matrix (completed 2026-06-28)
- [x] **Phase 123: Cross-surface coherence + ratchet re-arm** - All four surfaces cohere; storybook + gallery finalized; aesthetic ratchet re-scored only-forward with new judgment gates armed
- [ ] **Phase 124: Release cut + milestone closeout** - Linked-version Hex release (admin-minor drags core+inbound), D-13 inbound re-pin, consumer + post-publish smoke, audit + archive

**Execution order:** 118 → 119 → 120 → 121 → 122 → 123 → 124 (strictly sequential).
Top-down, biggest-impact-first: the persona-critic harness (118) must precede the keystone shell
redesign (119); each surface redesign (120 → 121 → 122) inherits the cleaned-up patterns from the
prior one; coherence + ratchet-arm (123) lands after all four surfaces are clean; the release cut
(124) is last. **118 is a hard precondition for 119** — the review loop produces the hit-list that
drives every surface redesign.

**Research flags:** Phase 118 (persona-critic harness design + `phoenix_storybook` sandbox-CSS
integration: wiring the committed `app.css` as the storybook sandbox stylesheet, `only: :dev`) and
Phase 119 (GOV.UK IA patterns + overview-as-triage redesign) likely need light `/gsd-plan-phase`
research. Surface-redesign phases 120-122 inherit the 118/119 patterns and the v1.11/v1.13 research
dossiers — plan directly. Phase 123 (ratchet re-score mechanics) and Phase 124 (release ceremony)
plan directly from the v1.13 precedent.

## Phase Details

### Phase 118: Method, Audit & Storybook stand-up

**Goal**: Stand up the inverted, judgment-level review method — an adversarial persona-critic harness
that produces the prioritized screenshot-backed defect register driving the redesign — plus a dev-only
`phoenix_storybook` review surface, the new judgment regression gates, and the inherited ratchet floor.
**Depends on**: Nothing (first phase of v1.14; the keystone precondition for all surface redesigns)
**Requirements**: METHOD-01, METHOD-02, STORY-01, STORY-02
**Success Criteria** (what must be TRUE):

  1. Adversarial persona/JTBD critic agents (dev-evaluator, library-integrator, maintainer-debugging,
     operator/on-call-SRE-under-stress, security-reviewer) walk every admin surface — live `make demo`
     plus the review surface — across the 320/375/768/1024/1440/wide × light/dark/system ×
     happy/empty/loading/error/permission-denied/boundary matrix using the northstar / fjordline-aps /
     helios-void persona stress data, and emit one prioritized, severity-ranked, **screenshot-backed
     defect register** (the hit-list).

  2. A dev-only `phoenix_storybook` surface (`only: :dev`) renders admin primitives, component groups,
     and pages on-brand — its **sandbox stylesheet is the committed `app.css`** — with stories spanning
     states/themes/viewports; adopters never install it and the shipped `priv/static/app.css` is
     unchanged (zero-Node guarantee intact).

  3. The existing `/dev/mail/gallery` is retained as the structural-contract / ratchet surface with no
     drift-guard regression.

  4. New judgment-level regression guards (nav-active-correctness; no nav-duplication on a populated
     page) are drafted/armed and the full v1.13 ratchet floor (~26 conformance gates, 54-cell aesthetic
     baseline, 9-cell axe baseline, 24-item Bucket-A manifest, persona drift-guard) is inherited green.
**Plans**: 3 plans
**Wave 1**

- [x] 118-01-PLAN.md — phoenix_storybook dev-only stand-up + sandbox CSS + Wave-0 .gitignore prereq (METHOD-01, STORY-01)
- [x] 118-02-PLAN.md — two drafted judgment gates (test.fixme) + verify-green inherited floor + gallery unchanged (METHOD-02, STORY-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 118-03-PLAN.md — persona-critic screenshot harness + milestone-scoped DEFECT-REGISTER.md (METHOD-01)

**UI hint**: yes

### Phase 119: App-shell + Nav + Overview redesign

**Goal**: Redesign the #1-pain surface — the app shell, navigation, and Overview landing — into a real
triage destination with correct location awareness and zero redundant chrome. This is the keystone:
it establishes the cleaned-up IA/component/microcopy patterns every later surface inherits.
**Depends on**: Phase 118 (consumes the defect register hit-list and the persona-critic harness;
the storybook/gallery review surfaces must exist to iterate against)
**Requirements**: SHELL-01, SHELL-02, SHELL-03
**Success Criteria** (what must be TRUE):

  1. The sidebar nav shows the **correct active item** for the current surface (overview / deliveries /
     inbound) — never a false highlight (fixes the hardcoded `active={:deliveries}` bug); active state
     is conveyed non-color-alone and is obvious in light, dark, and system themes.

  2. The Overview is a **real triage destination**: the redundant "Navigate" nav cards are removed, the
     generic orientation strip shows only on genuine empty panes, health stats are
     actionable/drill-down, and Overview has its own nav identity.

  3. Shell + Overview microcopy is streamlined, on-brand (thoughtful-maintainer voice, "Oops" banned),
     and non-redundant — no boilerplate labels, nothing duplicating the always-visible sidebar.

  4. The whole surface holds across the full matrix: 320→wide responsive (no squished tables, no chopped
     content, no horizontal overflow), light/dark/system, happy/empty/error/boundary states, WCAG 2.2 AA
     (keyboard-complete, visible/restored focus, 44×44 targets, labeled controls), and Emil-Kowalski-grade
     transform/opacity motion that snaps instant under reduced-motion.
**Plans**: 2 plans

- [x] 119-01-PLAN.md — SHELL-01/02/03 code: nav active-state fix + Overview nav identity, delete Navigate block, drill-through health + empty-pane orientation, triage microcopy + motion (Wave 1; Wave-0 e2e scaffolds)
- [x] 119-02-PLAN.md — D-09 paired tests: rewrite operator.spec.js VERIF-02 + flip/fix both judgment.spec.js gates (Wave 2)

**UI hint**: yes

### Phase 120: Deliveries surface redesign

**Goal**: Redesign the Deliveries surface — the core operator JTBD — into a streamlined, focused
interaction model (not an info-dump), inheriting the Phase 119 shell/IA/microcopy patterns.
**Depends on**: Phase 119 (inherits the cleaned-up shell, nav, IA, microcopy, and motion patterns)
**Requirements**: DELIV-01
**Success Criteria** (what must be TRUE):

  1. The Deliveries surface is redesigned for its core operator JTBD with a streamlined, non-info-dump
     IA — operators scan status/severity/entity/time/next-action fast; no redundant UI; least-surprise
     throughout.

  2. The surface satisfies the full cross-cutting matrix: 320→wide responsive (tables → cards/lists
     < 768, no squished columns, graceful long IDs/UUIDs/module-names/non-ASCII/high-counts/nulls),
     light/dark/system, happy/empty/loading/error/permission-denied/boundary/disconnected-reconnect.

  3. WCAG 2.2 AA + APG holds (keyboard-complete, visible/restored focus, never color-alone, 44×44
     targets, labeled controls, predictable dialogs); microcopy is on-brand and recovery-oriented; motion
     is Emil-Kowalski-grade within the v1.13 MOTION locks; all inherited gates stay green.
**Plans**: 2 plans

**Wave 1**

- [x] 120-01-PLAN.md — render-condition gating: filters toolbar + Open-delivery CTA on populated/no-match, orientation strip empty-pane-only, paired ExUnit update (DELIV-01)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 120-02-PLAN.md — paired Playwright updates + new Deliveries empty-pane-only judgment gate + persona re-shoot + inherited-floor/TokenParity hold (DELIV-01)

**UI hint**: yes

### Phase 121: Inbound surface redesign

**Goal**: Redesign the Inbound surface consistent with the cleaned-up Deliveries patterns, preserving
its PII/raw-payload boundaries.
**Depends on**: Phase 120 (inherits the Deliveries-surface patterns for cross-surface consistency)
**Requirements**: INB-01
**Success Criteria** (what must be TRUE):

  1. The Inbound surface is redesigned consistent with the cleaned-up Deliveries patterns (spacing,
     hierarchy, IA, microcopy, motion) — streamlined, non-info-dump, least-surprise — while preserving
     PII/raw-payload-default-hidden boundaries.

  2. The surface satisfies the full cross-cutting matrix: 320→wide responsive (cards/lists < 768,
     graceful long values), light/dark/system, happy/empty/loading/error/permission-denied/boundary/
     disconnected-reconnect.

  3. WCAG 2.2 AA + APG holds (keyboard-complete, visible/restored focus, never color-alone, 44×44
     targets, predictable dialogs incl. the replay modal); microcopy is on-brand and recovery-oriented;
     motion is Emil-Kowalski-grade within the v1.13 MOTION locks; all inherited gates stay green.
**Plans**: 4 plans

- [x] 121-01-PLAN.md — Inbound IA gating (no-data/no-match/populated cond, empty-pane-only orientation, data_state wiring, D-07 noun fix) + paired ExUnit/voice updates
- [x] 121-02-PLAN.md — Reveal ARIA disclosure + re-redact + aria-live + PII-free reveal telemetry
- [x] 121-03-PLAN.md — Both replay modals: Tab focus-trap + double-submit pending-lock (lockstep)
- [x] 121-04-PLAN.md — e2e judgment gate + paired split + reveal/replay a11y assertions + structural verify + persona re-shoot

**UI hint**: yes

### Phase 122: Preview surface redesign

**Goal**: Redesign the Preview surface consistent with the established patterns, keeping the previewed
email's independent theme toggle intact.
**Depends on**: Phase 121 (inherits the now-consistent Deliveries + Inbound patterns)
**Requirements**: PREV-01
**Success Criteria** (what must be TRUE):

  1. The Preview surface is redesigned consistent with the established cross-surface patterns (spacing,
     hierarchy, IA, microcopy, motion) — streamlined, non-info-dump, least-surprise — with the previewed
     email keeping its own independent dark/light toggle distinct from the admin chrome theme.

  2. The surface satisfies the full cross-cutting matrix: 320→wide responsive, light/dark/system admin
     chrome at parity, happy/empty/loading/error/boundary states.

  3. WCAG 2.2 AA + APG holds (keyboard-complete, visible/restored focus, never color-alone, 44×44
     targets, labeled controls); microcopy is on-brand and recovery-oriented; motion is
     Emil-Kowalski-grade within the v1.13 MOTION locks; all inherited gates stay green.
**Plans**: 3 plans
**Wave 1**

- [x] 122-01-PLAN.md — Dual-theme toggle a11y: adopt theme_picker for admin chrome routed through the frame-aware preview_theme_path (D-05 load-bearing invariant), harden the backdrop button, toggle-a11y e2e (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 122-02-PLAN.md — Microcopy + a11y + dead-code: brandbook onboarding (generator primary), recovery-oriented error card with inline `<pre>`, error-transition focus/announce, dead dark_chrome removal, token normalization + paired voice/e2e updates (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 122-03-PLAN.md — Persona re-shoot (no new cells / D-17 fallback) + asset-bundle-untouched + inherited floor green only-forward (wave 3)

**UI hint**: yes

### Phase 123: Cross-surface coherence + ratchet re-arm

**Goal**: Prove the four surfaces cohere as one deliberate, Apple-like system; finalize the storybook +
gallery review surfaces; re-score the aesthetic ratchet only-forward and arm the new judgment gates so
the fixed issues cannot silently regress.
**Depends on**: Phase 122 (all four surfaces must be redesigned before cross-surface coherence and the
final pillar re-score)
**Requirements**: COH-01, COH-02
**Success Criteria** (what must be TRUE):

  1. All four surfaces (Overview/shell, Deliveries, Inbound, Preview) are **cross-surface coherent** —
     consistent spacing, hierarchy, IA, microcopy, and motion — and the storybook + `/dev/mail/gallery`
     review surfaces are finalized and consistent with the shipped UI.

  2. The aesthetic ratchet baseline is re-scored **only-forward** (meet-or-beat, zero regressions): the
     54-cell aesthetic baseline, 9-cell axe baseline, 24-item Bucket-A manifest, and persona drift-guard
     are all green, with current promoted over prior under distinct run-ids.

  3. The new judgment-level gates (nav-active-correctness; no nav-duplication on a populated page) are
     armed and green in the inherited ratchet floor (~26+ conformance gates), so the redesign's headline
     fixes cannot silently regress.
**Plans**: 3 plans

**Wave 1** *(independent — re-score floor + review-surface finalization run in parallel)*

- [x] 123-01-PLAN.md — COH-02: promote+re-score the 54-cell ratchet only-forward (distinct run_ids, anti-vacuity guard) + arm the two judgment gates (de-disclaim judgment.spec.js + floor gate-count ~26→~28); no asset rebuild (wave 1)
- [x] 123-02-PLAN.md — COH-01: storybook story-inventory completeness vs shipped primitives + accept indigo explorer chrome (dev-only cosmetic) + stale-boot DX caveat; gallery byte-unchanged (wave 1)

**Wave 2** *(blocked on Wave 1 — verdict cites the green floor + finalized review surfaces)*

- [x] 123-03-PLAN.md — COH-01: re-run the adversarial persona-critic harness across all four surfaces (evidence only) + close out DEFECT-REGISTER (Status flips + coherence sign-off, five hats/three personas verbatim); no new coherence gate, Personas.spec/0 untouched (wave 2)

**UI hint**: yes

### Phase 124: Release cut + milestone closeout

**Goal**: Cut the linked-version Hex release that carries the redesign to adopters, re-pin inbound, prove
Hex resolution + consumer + post-publish smoke, and audit + archive the milestone.
**Depends on**: Phase 123 (everything must be coherent, re-scored, and gate-green before publishing)
**Requirements**: REL-01, REL-02
**Success Criteria** (what must be TRUE):

  1. A linked-version Hex release is cut — the admin-minor bump drags matched core + inbound — the D-13
     inbound exact-pin is re-pinned to the new core version, and Hex resolution + consumer smoke +
     post-publish smoke are green.

  2. The milestone is audited (`status: passed`, every v1.14 requirement satisfied) and archived
     (`milestones/v1.14-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`; MILESTONES/PROJECT/ROADMAP/STATE
     evolved; tagged `v1.14`).
**Plans**: 1 plan

- [ ] 124-01-PLAN.md — 6-wave linked-version release ceremony (rebase-reconcile origin + ff-push, fix(inbound): re-pin == 1.10.0, verify regenerated RP PR 1.10.0/1.10.0/1.5.2, maintainer go/no-go, Hex confirm, consumer + post-publish smoke) + milestone audit/archive/tag v1.14 (REL-01, REL-02)

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 118. Method, Audit & Storybook stand-up | 3/3 | Complete    | 2026-06-26 |
| 119. App-shell + Nav + Overview redesign | 2/2 | Complete    | 2026-06-26 |
| 120. Deliveries surface redesign | 2/2 | Complete    | 2026-06-27 |
| 121. Inbound surface redesign | 4/4 | Complete    | 2026-06-28 |
| 122. Preview surface redesign | 3/3 | Complete    | 2026-06-28 |
| 123. Cross-surface coherence + ratchet re-arm | 3/3 | Complete   | 2026-06-28 |
| 124. Release cut + milestone closeout | 0/? | Not started | - |

## Phases (Shipped — Archived)

All milestones through v1.13 are shipped and archived. Per-milestone phase detail,
success criteria, and plan breakdowns live in `.planning/milestones/vX.Y-ROADMAP.md`.

<details>
<summary>✅ v1.13 Admin Design-System Stress Test & UX Uplift (Phases 109-117) — SHIPPED 2026-06-21</summary>

Bottom-up fractal admin design-system uplift (foundations → primitives → forms → app-shell →
data-display → composed groups → motion → WCAG 2.2 AA ratchet), then a linked-version MINOR
release → **mailglass 1.8.0 / mailglass_admin 1.8.0 / mailglass_inbound 1.5.0 live on Hex**.
Audit status: passed — 41/41 requirements, 9/9 phases. Inbound re-pinned {:mailglass, "== 1.8.0"}.
Full detail: [milestones/v1.13-ROADMAP.md](milestones/v1.13-ROADMAP.md).

</details>
<details>
<summary>✅ v1.12 Adopter Onboarding & Day-2 Confidence (Phases 104-108) — SHIPPED 2026-06-17</summary>

Friction-removal + the first real linked-version Hex release since 1.6.2 → **mailglass 1.7.0 /
mailglass_admin 1.7.0 / mailglass_inbound 1.4.0 live on Hex**. Installer fail-closed + webhook
doctor (104), onboarding docs + learning arc (105), day-2 guides (106), inbound replay-modal a11y
parity (107), release cut + closeout (108). Audit `status: passed` — 13/13 requirements, 5/5
phases. Full detail: [milestones/v1.12-ROADMAP.md](milestones/v1.12-ROADMAP.md).

</details>

<details>
<summary>✅ v1.11 mailglass_admin Design-System Uplift (Phases 94-103) — SHIPPED 2026-06-16</summary>

Re-baseline the admin UI onto the canonical fable brand tokens, then fractally
audit-and-uplift every component, component-group, and page across the Operator,
Inbound, and Preview surfaces — enforced by an idempotent, research-grounded quality
ratchet. Admin UI only (3 surfaces). Release posture: prepare-only (no Hex release cut).
Audit `status: passed` — 34/34 requirements, 10/10 phases, 16/16 integration, 7/7 flows.
Full detail: [milestones/v1.11-ROADMAP.md](milestones/v1.11-ROADMAP.md).

- [x] Phase 94: Token Re-Baseline onto Canonical Brand (3/3 plans) — completed 2026-06-13
- [x] Phase 95: Audit Apparatus + Quality-Ratchet v2 (4/4 plans) — completed 2026-06-14
- [x] Phase 96: Research Dossier (6/6 plans) — completed 2026-06-14
- [x] Phase 97: Cross-Surface Component Layer (8/8 plans) — completed 2026-06-14
- [x] Phase 98: Operator / Deliveries Surface (4/4 plans) — completed 2026-06-14
- [x] Phase 99: Inbound Surface (5/5 plans) — completed 2026-06-15
- [x] Phase 100: Preview Surface (3/3 plans) — completed 2026-06-15
- [x] Phase 101: Microcopy Pass (2/2 plans) — completed 2026-06-16
- [x] Phase 102: Motion + Micro-interaction Pass (3/3 plans) — completed 2026-06-16
- [x] Phase 103: Verification + Idempotent Closeout (4/4 plans) — completed 2026-06-16

**Critical path:** 94 → 95 → 96 → 97 → {98, 99, 100 parallel} → {101, 102 parallel} → 103

</details>

## Backlog

### Phase 999.1: Human-Readable Code Comments + GSD Artifact Cleanup

Retained from previous milestones. Promote separately when worth the maintenance
pass.

### Phase 999.2: Shift-Left Email Screenshot + Responsive Preview Workflow

Retained from previous milestones. Do not fold into brandbook milestones; the
brandbooks avoid committing generated screenshot sets by design.
