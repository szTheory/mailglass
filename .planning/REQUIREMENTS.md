# Requirements: mailglass — v1.15 Release-Pipeline Efficiency & Contributor DX

**Defined:** 2026-07-01
**Core Value:** Email you can see, audit, and trust before it ships.
**Milestone goal:** Kill the exact-pin release dance and close the local↔CI parity gap — make
releases genuinely hands-free and make one command reproduce the mergeable surface — with zero
product-behavior change, then cut a real linked Hex release that dogfoods the hardened pipeline.

> Decisions of record: `.planning/research/milestone-cicd/SYNTHESIS.md` (LD-1..13). Raw research:
> `CICD-RELEASE-HARDENING.md`, `DX-MIX-CI.md`. Requirement IDs continue from prior milestones with
> new milestone-scoped category prefixes.

## v1.15 Requirements

### PIN — Sibling-pin loosening (keystone, atomic → Phase 125)

- [x] **PIN-01**: Both sibling `{:mailglass, "== X.Y.Z"}` pins are replaced with `~>` — inbound
  `{:mailglass, "~> 1.10 and >= 1.10.2"}`, admin `{:mailglass, "~> 1.10"}` — behind the existing
  `MIX_PUBLISH` gate (LD-2).

- [x] **PIN-02**: `stability_contract_test` and `publish.check` (`verify_deps`/`verify_linked_constraint`)
  assert the sibling pin *admits* core `@version` via `Version.match?` and is pessimistic (`~>`),
  rejecting `==` — replacing the exact-equality assertions (LD-3).

- [x] **PIN-03**: The two `== X.Y.Z` sed rewrites are deleted from `release-please.yml`; a core patch
  release touches zero sibling pin lines (LD-3).

- [x] **PIN-04**: The pin change ships a CHANGELOG entry and documents `mix hex.retire` as the rollback
  lever that replaces the `==` wall (LD-5).

- [x] **PIN-05**: The whole pin change lands as one indivisible change verified green on a bare main
  SHA where core `@version` is unchanged (the scenario that was red before) (LD-3).

### GATE — CI Green fan-in gate + branch-protection (→ Phase 126)

- [x] **GATE-01**: A single `CI Green` aggregate job (`if: always()`, explicit `needs`) is the SOLE
  required branch-protection context alongside `guard-release-trigger`, replacing the 5 leaf contexts.

- [x] **GATE-02**: On the release/publish path a required lane must be `success` — a `skipped` required
  lane does NOT count as green (LD-6).

- [x] **GATE-03**: A coverage meta-test asserts set-equality between `REQUIRED_CHECKS`, `ci-green.needs`,
  and the job set, and that no required lane is permanently `if:`-disabled (LD-6).

- [x] **GATE-04**: `guard-release-trigger` is verified to always report (no green-but-BLOCKED regression)
  and `gate-self-test.yml`'s stale `check_name` default is corrected to `CI Green` (LD-6).

### DET — Inbound test determinism (→ Phase 127)

- [ ] **DET-01**: The shared-mode/async sandbox flake is fixed at the root (`MailboxCase` defaults
  `async: false`, drops `shared:`, plain ownership checkout) so the suite is deterministic by
  construction (LD-8).

- [ ] **DET-02**: `--seed 0` is deleted from `ci.yml` and never appears in the `mix ci` inbound step;
  the suite is green across 20 random-seed runs (LD-8).

### MIXCI — `mix ci` local↔CI parity (folds in PR #104 → Phase 128)

- [ ] **MIXCI-01**: `mix ci` equals the mergeable surface — it runs all 5 required gates including
  Installer Host Smoke and the reference-host trust lane (LD-10).

- [ ] **MIXCI-02**: The tiered aliases exist and are env-pinned — `mix ci.fast` (seconds, no DB),
  `mix ci` (full parity), `mix ci.browser` (opt-in Node) — with sibling-local `ci`/`ci.fast` aliases
  and a discoverable `make ci`/`make help` wrapper.

- [ ] **MIXCI-03**: A manifest-membership parity-drift test asserts `ci` ∪ `ci.browser` covers every
  required+advisory CI lane by identity + flag-set (shared source with GATE-03), failing loudly on
  drift (LD-10).

- [ ] **MIXCI-04**: `mix ci`/`ci.setup` preflight-probes Postgres (and the installer step probes
  network) and prints a brand-voice actionable message on absence, never a raw connection crash (LD-12).

- [ ] **MIXCI-05**: `verify.*` are designated internal composition targets, the deprecated
  `verify.phase_NN` pass-throughs are removed, and CONTRIBUTING points at `mix ci`/`mix ci.fast`
  (only once MIXCI-01 holds) (LD-12).

### CACHE — Cache-key + PLT correctness (→ Phase 129)

- [ ] **CACHE-01**: The deps/`_build` cache key includes OTP+Elixir dims derived from a single
  `.tool-versions`/`env:` source (not per-block hardcoded literals) with per-env prefix (LD-9).

- [ ] **CACHE-02**: The PLT cache uses Bandit-style self-healing eviction (evict + rebuild on a stale
  Dialyzer failure); only after this may Dialyzer be promoted toward the required set (LD-7).

### SUPPLY — Supply chain + workflow hygiene (→ Phase 130)

- [ ] **SUPPLY-01**: `mix deps.audit` (mix_audit) runs advisory (non-blocking) on PR and blocking only
  at the publish gate; never reds an open PR under an unfixable-advisory wave (LD-4).

- [ ] **SUPPLY-02**: `dependabot.yml` watches the `mailglass_admin` and `mailglass_inbound` sibling
  locks (not the frozen reference baselines).

- [ ] **SUPPLY-03**: The cowlib allowlist has a forcing function — OSV-staleness is a loud CI warning
  on every run + a hard block at publish, fail-open on OSV outage (LD-4).

- [ ] **SUPPLY-04**: `actionlint` gates `.github/workflows/**` changes on PR (LD-11).
- [ ] **SUPPLY-05**: A latest-Elixir advisory row (1.19 / OTP 28) runs non-blocking on push+cron only;
  the floor-coincidence invariant is documented (LD-13).

### SHIP — Release cut + closeout (→ Phase 131)

- [ ] **SHIP-01**: A real linked Hex release is cut through the hardened pipeline — core+admin linked,
  inbound a **minor** bump for the dependency-policy change (LD-1).

- [ ] **SHIP-02**: Consumer + post-publish smoke pass against the published packages; the `~>` pins
  resolve correctly from Hex.

- [ ] **SHIP-03**: The milestone is audited against intent and archived; the per-phase "CI-the-body"
  method (push `phase/NN`, require green CI) was used throughout so the ceremony was a confirmation.

## Future Requirements (deferred)

### Schema isolation (→ v2.0, next milestone)

- **SCHEMA-01**: Runtime Postgres schema prefix via a Repo facade (research-locked in
  `.planning/research/milestone-schema-isolation/`).

- **SCHEMA-02**: The events-immutability trigger (currently hard-bound to `public`) works under a
  non-public prefix — the 2.0 breaking change.

### Deferred DX / hardening (post-v1.15, not blocking)

- **DET-A1**: Option A honest-async inbound suite (`Sandbox.allow/3`) if inbound grows concurrent
  paths — preserves concurrency-regression signal that Option B trades away (LD-8).

- **SUPPLY-A1**: `dependency-review.yml` on PRs (paired with actionlint) if PR-volume warrants (LD-11).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Any product-code / provider / transport / route change | D-23 convergence; library is feature-complete (~93–95%). This milestone is infrastructure/DX only. |
| Postgres schema isolation | The *next* milestone (v2.0). This one must not touch schema. |
| Sobelow scanning | App-level scanner; mailglass ships libraries, not an app. Low value, high false-positive noise. |
| Min-supported floor matrix row (< 1.18) | Declared floor is `~> 1.18`; a lower row tests an unclaimed contract (REL-06). |
| Test partitioning (`--partitions`) | 0/10 flagship Elixir libs use it; parallelism comes from the matrix + async ExUnit. |
| `ex_check` / `bin/ci` as the `mix ci` form | Bespoke gates (trust lane, installer smoke, cd-into-siblings) don't fit ex_check auto-detection; Elixir contributors expect `mix <verb>`. |
| Custom `elixir-workspace` release-please plugin | Only justified if exact `==` lockstep is ever mandated; `~>` is strictly simpler and idiomatic. |

## Traceability

Filled by the roadmap (`.planning/ROADMAP.md`). Every PIN/GATE/DET/MIXCI/CACHE/SUPPLY/SHIP requirement
maps to exactly one phase (125–131).
