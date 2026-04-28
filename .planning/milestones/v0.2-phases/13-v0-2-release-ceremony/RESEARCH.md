# Phase 13: v0.2 Release Ceremony - Research

**Researched:** 2026-04-28 [VERIFIED: date(2026-04-28)]
**Domain:** v0.2 release planning for linked-version Hex packages, adopter migration confidence, docs trust, and publish-ceremony safety in mailglass [VERIFIED: .planning/phases/13-v0-2-release-ceremony/13-CONTEXT.md]
**Confidence:** HIGH for release-workflow seams, changelog/docs gate extensions, and publish/smoke mechanics; MEDIUM for the exact adopter-fixture layout because that is still planner discretion [VERIFIED: repo audit]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- `mailglass` `0.2.0` must lead with a maintainer-narrative changelog entry, not a raw generated ledger. [VERIFIED: .planning/phases/13-v0-2-release-ceremony/13-CONTEXT.md]
- The public release story must explicitly cover breaking changes, exact upgrade path (`mix mailglass.upgrade.v0_2`), minimum dependency matrix, ambiguous-case escape hatch, rollback, and user-visible behavior changes. [VERIFIED: .planning/phases/13-v0-2-release-ceremony/13-CONTEXT.md]
- REL-14 is intentionally narrow but strict: fresh host install proof, happy-path v0.1 upgrade proof, and one sentinel ambiguous-case proof. [VERIFIED: .planning/phases/13-v0-2-release-ceremony/13-CONTEXT.md]
- Tier 1 release-blocking docs are `README.md`, `guides/getting-started.md`, `guides/upgrading-from-v0_1.md`, `guides/migration-from-swoosh.md`, `guides/authoring-mailables.md`, `guides/unsubscribe.md`, `guides/dkim-setup.md`, and `guides/webhooks.md`. [VERIFIED: .planning/phases/13-v0-2-release-ceremony/13-CONTEXT.md]
- The `release-please-action` v5 upgrade is explicitly out of scope for this release; Phase 13 stays on the pinned v4 path. [VERIFIED: .planning/phases/13-v0-2-release-ceremony/13-CONTEXT.md][VERIFIED: .github/workflows/release-please.yml]
- Planning/execution must resolve the current ambiguity around downstream workflow invocation from Release Please and define a canonical fallback path. [VERIFIED: .planning/phases/13-v0-2-release-ceremony/13-CONTEXT.md]

### the agent's Discretion
- Exact changelog prose and section naming, as long as the required migration content is front-loaded.
- Exact fixture names and folder layout for fresh-host / v0.1-upgrade / ambiguous-case proofs.
- Exact low-noise docs-gate implementation, as long as it is Tier-1-focused and avoids generic prose linting.
- Exact rehearsal/runbook structure for release-day fallback handling.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Requirement | Research Support |
|----|-------------|------------------|
| REL-13 | Changelog narrative for `mailglass` + `mailglass_admin` with upgrade path, dep matrix, and rollback. [VERIFIED: .planning/REQUIREMENTS.md:92] | Existing changelog files already show both the curated-entry pattern (`CHANGELOG.md` `0.1.0`) and the linked-version sibling pattern (`mailglass_admin/CHANGELOG.md`). |
| REL-14 | Fresh Phoenix 1.8.5 host + v0.1 adopter walkthrough + ambiguous-case warning contract. [VERIFIED: .planning/REQUIREMENTS.md:93] | Existing installer and post-publish smoke tests already prove fresh-host generation/install/boot patterns; `mix mailglass.upgrade.v0_2` is the load-bearing codemod seam. |
| REL-15 | All release-blocking docs updated for v0.2 behavior and commands. [VERIFIED: .planning/REQUIREMENTS.md:94] | `mix mailglass.docs.check` establishes the project’s doc-gate pattern but currently only catches internal-ID leakage; Tier 1 stale-version/API checks are new work. |
| REL-16 | Linked-version release bump, tarball size budgets, protected-ref publish, and post-publish smoke. [VERIFIED: .planning/REQUIREMENTS.md:95] | Release Please, publish, and smoke workflows already exist; the main remaining work is rehearsal, explicit fallback semantics, and any missing size/whitelist verification seams. |
</phase_requirements>

## Summary

Phase 13 is not a greenfield release-engineering phase. Most of the mechanics already exist in the repo: Release Please is pinned and customized, publish is gated by prepublish summary + CI green + environment approval, and post-publish smoke already performs a real Phoenix host install/boot. The planning job is therefore to package those existing seams into five bounded plans with explicit proof artifacts, low-noise doc gating, and a boring fallback story. [VERIFIED: .github/workflows/release-please.yml][VERIFIED: .github/workflows/publish-hex.yml][VERIFIED: .github/workflows/post-publish-smoke.yml]

The highest-risk gaps are not “how do we publish to Hex?” but rather: (1) whether the public migration story is coherent across changelog + upgrade guide + codemod behavior, (2) whether there is a committed v0.1 adopter fixture that proves the non-ambiguous zero-manual-edit promise, (3) whether Tier 1 docs can fail loudly on stale v0.1 surface area without noisy false positives, and (4) whether the maintainer runbook states one canonical recovery path when Release Please and follow-on workflows partially succeed. [VERIFIED: .planning/phases/13-v0-2-release-ceremony/13-CONTEXT.md][VERIFIED: lib/mix/tasks/mailglass.docs.check.ex][VERIFIED: lib/mix/tasks/mailglass.upgrade.v0_2.ex]

**Primary recommendation:** keep the roadmap’s five-plan split, but make each plan own one proof artifact: curated changelog sections, fixture-backed upgrade validation, Tier 1 doc gate/report, release rehearsal evidence, and explicit publish/smoke runbook confirmation. The planner should resist bundling 13-04 and 13-05 into one plan because rehearsal/verification and irreversible publish ceremony have different rollback profiles. [VERIFIED: .planning/ROADMAP.md:155][VERIFIED: repo workflow audit]

## Recommended Plan Split

### 13-01 — Changelog Narrative
- Rework `CHANGELOG.md` so `0.2.0` starts with a maintainer-written migration front door, then preserves a categorized ledger underneath.
- Add a short coordinated `mailglass_admin` `0.2.0` entry that explicitly states whether adopters need action beyond the core upgrade.
- Cross-check content against the actual codemod contract in `lib/mix/tasks/mailglass.upgrade.v0_2.ex` and the dependency/runtime floors in the repo docs/config.

### 13-02 — Adopter Walkthrough Validation
- Reuse the fresh-host proof shape from post-publish smoke and installer smoke tests, but make it a committed phase-owned validation fixture rather than only a release-day workflow.
- Add a committed v0.1 fixture that exercises the supported setter patterns and proves zero manual edits for non-ambiguous cases.
- Add a sentinel ambiguous-case fixture proving warning emission plus documented `update_swoosh/2` escape-hatch resolution.

### 13-03 — Tier 1 Doc Audit
- Update only the release-blocking docs first; do not turn Tier 2 polish into release blockers unless they contain broken commands or behavior claims.
- Extend `mix mailglass.docs.check` with low-noise assertions for Tier 1 docs: stale version references, outdated commands, missing v0.2-specific guide anchors, or other deterministic checks.
- Prefer executable/compileable doc smoke where the guide contains canonical upgrade or migration snippets.

### 13-04 — Release Please + Tarball + Rehearsal
- Keep Release Please on the current pinned v4 path and verify linked-version bump semantics, custom dep-pin sync, tarball whitelist, and size budgets before any real release cut.
- Produce a rehearsal artifact or runbook evidence proving the canonical invocation path and the fallback path when Release Please and downstream workflows do not chain automatically.
- Treat review of the generated release PR diff as a mandatory acceptance criterion because the repo uses custom version-sync behavior.

### 13-05 — Protected Publish + Post-Publish Smoke
- Preserve the existing `release` + `workflow_dispatch` dual-entry model in `publish-hex.yml` and `post-publish-smoke.yml`; do not invent a separate publish mechanism.
- Make the plan own the maintainer-runbook clarity: environment approval, manual fallback trigger, Hex indexing wait, HexDocs `curl -fsI`, and `mix hex.info` verification.
- Keep this plan focused on the irreversible ceremony and immediate smoke, not on preflight rehearsals that belong in 13-04.

## Repo-Specific Risks

### 1. Public migration story drift
`CHANGELOG.md`, `guides/upgrading-from-v0_1.md`, and `mix mailglass.upgrade.v0_2` can diverge if edited independently. The changelog must summarize the codemod truth, not invent a broader automation guarantee. [VERIFIED: CHANGELOG.md][VERIFIED: guides/upgrading-from-v0_1.md][VERIFIED: lib/mix/tasks/mailglass.upgrade.v0_2.ex]

### 2. No current Tier 1 stale-surface gate
`mix mailglass.docs.check` currently enforces only “no leaked internal planning IDs.” That is necessary but insufficient for Phase 13. The planner should add deterministic Tier 1 checks, not subjective prose checks. [VERIFIED: lib/mix/tasks/mailglass.docs.check.ex]

### 3. Adopter-upgrade proof likely under-specified today
The repo already proves fresh-host install/boot, but the Phase 13 requirement is stronger: it also needs a committed v0.1 adopter fixture and an ambiguous-case proof around `IO.warn` + migration-guide URL. [VERIFIED: .github/workflows/post-publish-smoke.yml][VERIFIED: test/mailglass/install/install_idempotency_test.exs]

### 4. Release trigger ambiguity is the real ceremony hazard
The context explicitly calls out uncertainty around Release Please creating a tag/release while downstream publish/smoke workflows depend on trigger semantics. This is higher risk than staying on `release-please-action` v4 for one more cut. [VERIFIED: .planning/phases/13-v0-2-release-ceremony/13-CONTEXT.md][VERIFIED: .github/workflows/release-please.yml][VERIFIED: .github/workflows/publish-hex.yml]

### 5. Custom linked-version sync means the release PR diff is load-bearing
`mailglass_admin/mix.exs` is patched by a guarded `sed` step after Release Please runs. That is acceptable, but it raises the cost of “merge the release PR without reading it.” [VERIFIED: .github/workflows/release-please.yml][VERIFIED: mailglass_admin/mix.exs]

## Verification Guidance Per Plan

| Plan | Proof Artifact | Recommended Verification |
|------|----------------|--------------------------|
| 13-01 | `CHANGELOG.md` + `mailglass_admin/CHANGELOG.md` entry drafts | `mix mailglass.publish.check --package mailglass`; reviewer checklist against REL-13 sections; confirm wording matches `mix mailglass.upgrade.v0_2` behavior. |
| 13-02 | fresh-host fixture/test + v0.1 upgrade fixture/test + ambiguous-case proof | focused ExUnit for upgrade/install suites; explicit assertion on `IO.warn`; compile/preview smoke in generated or fixture host. |
| 13-03 | Tier 1 doc updates + docs gate extension + optional guide smoke tests | `mix mailglass.docs.check`; any new guide-smoke tests; spot-check Tier 1 commands/examples against current API. |
| 13-04 | rehearsal notes/artifact + workflow/runbook updates + tarball/size verification | dry-run/rehearsal command path; verify release PR diff; verify package contents and size budgets before publish. |
| 13-05 | runbook-confirmed publish ceremony + smoke workflow contract | `workflow_dispatch` fallback path documented; `mix hex.info` for both packages; `curl -fsI https://hexdocs.pm/mailglass/<ver>/`; post-publish smoke success criteria. |

## Must-Read Files For Planner

- `.planning/phases/13-v0-2-release-ceremony/13-CONTEXT.md`
- `.planning/phases/13-v0-2-release-ceremony/13-PATTERNS.md`
- `CHANGELOG.md`
- `mailglass_admin/CHANGELOG.md`
- `guides/upgrading-from-v0_1.md`
- `lib/mix/tasks/mailglass.upgrade.v0_2.ex`
- `lib/mix/tasks/mailglass.docs.check.ex`
- `.github/workflows/release-please.yml`
- `.github/workflows/publish-hex.yml`
- `.github/workflows/post-publish-smoke.yml`
- `MAINTAINING.md`

## RESEARCH COMPLETE
