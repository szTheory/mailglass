# Project Research Summary

**Project:** Mailglass v2.7 Repository Stewardship & Operational Hygiene
**Domain:** Operational closeout for a protected Phoenix/Elixir sibling-package repository
**Researched:** 2026-08-21
**Confidence:** HIGH

## Executive Summary

Mailglass v2.7 is a bounded repository-stewardship milestone, not a product release. The repository already has the required control plane: native Git state, pinned GitHub Actions, repository-local Mix policy tasks, protected release-policy scripts, PostgreSQL-backed property tests, and the serialized Playwright operator-browser lane. The recommended approach is to use those existing seams to establish one canonical `main`, classify every residual worktree/branch/stash and release artifact, recover or explicitly disposition scheduled controls, and leave reproducible evidence rather than adding tools or redesigning automation.

The ordering is essential. Preserve and inventory Git/release state before deleting anything; reconcile the release ledger, PR, and immutable target before attempting schedule or post-publish recovery; reproduce each observed timeout before changing its narrow test/configuration seam; and reconcile documentation/ignore rules only after facts settle. The primary risks are evidence loss, false-green automation, and turning timeout failures into weaker tests. Mitigate them with explicit per-item dispositions, manual plus observed scheduled-run proof, exact candidate/digest checks, preserved test invariants and matrix coverage, and a final clean-state audit.

## Key Findings

### Recommended Stack

No new dependency, service, CI product, or runtime upgrade is warranted. v2.7 should retain the locked Beam/Mix stack and SHA-pinned Actions; the work is recovery, reconciliation, and focused proof. Use Git for workspace provenance, GitHub Actions and `gh` for automation/PR state, existing Mix tasks and release scripts for policy truth, and the existing PostgreSQL/Playwright lanes for narrow regressions.

**Core technologies:**

- **Git worktrees, branches, stashes, and reachability checks:** inventory and selectively retire residue only after unique-work and preservation checks.
- **GitHub Actions with existing SHA pins:** recover release-please, repo-hygiene, and post-publish evidence from the default branch without changing automation topology.
- **Elixir 1.18.4 / Erlang-OTP 27.3.4.13 and Mix:** run the repository's existing hygiene, policy, CI, and focused proof commands; do not upgrade the toolchain.
- **Release-policy scripts plus `.planning/release-target.json`:** retain the authoritative exact-candidate, content-digest, protected-main publication model.
- **PostgreSQL 16 and StreamData:** retain the 1,000-case property and correct only the deterministic timeout cause.
- **Playwright / Axe, single worker:** retain gallery discovery, viewport/theme matrix, stress checks, and fail-closed overflow assertions while correcting the one bounded failure.

### Expected Features

This milestone's table stakes are operational outcomes: an explained clean `main`; disposition of every temporary worktree, stash, divergent branch, and release leftover; an explicit outcome for the blocked release PR; truthful release-please, repo-hygiene, and post-publish automation; narrow regression-backed fixes for the PostgreSQL property and browser-gallery timeouts; and documentation/artifact/ignore rules that match the settled state. A small machine-readable disposition record is acceptable only if existing planning/release evidence cannot provide the required audit trail.

**Must have (table stakes):**

- **Canonical workspace and safe Git-state disposition** — inventory provenance before removal and preserve unique work.
- **Truthful automation and release disposition** — reconcile ledger, PR, checks, schedules, and exact immutable publication targets without making a release ceremonial.
- **Targeted timeout repairs with proof** — retain the property invariant/execution count and browser coverage contract.
- **Docs, artifacts, ignores, and closeout evidence** — correct only evidence-backed drift and show a quiet final state.

**Should have (only if required for proof):**

- **Minimal machine-readable disposition ledger** — only when existing artifacts cannot name each audited object.
- **Focused automation recovery-contract test** — only when a repaired path otherwise lacks a regression assertion.

**Defer (v2+):**

- CI/CD efficiency or topology redesign, generic worktree tooling, automation dashboards, dependency/action/toolchain upgrades, and any new product or release work.

### Architecture Approach

The architecture is an existing control plane, not a new subsystem. Root `main` is the integration root; the repository-hygiene Mix task produces inventory truth; CI plus `Guard Release Trigger` is protected merge proof; release-please captures proposals only; `release-target.json` and release-policy scripts authorize immutable publication; post-publish smoke validates only a completed exact target; and docs/ignores record the resulting evidence. Changes should be selective at these seams, never a replacement layer.

**Major components:**

1. **Git workspace and hygiene task** — inventory and preserve/disposition local repository state and emit inspectable hygiene JSON.
2. **Protected release control plane** — reconcile the blocked release PR, ledger, candidate/content digest, tags, and checks without creating a new authorization path.
3. **Scheduled workflow proofs** — verify release proposal, hygiene, and post-publish behavior through their current manual/scheduled entry points and artifacts.
4. **Focused quality lanes** — repair the SQLSTATE 57014 property path and gallery matrix timeout while retaining existing test contracts.
5. **Documentation and tracked-artifact truth** — align maintenance guidance and ignore rules to live state while retaining release/planning evidence.

### Critical Pitfalls

1. **Destructive cleanup erases the only copy of release work** — record SHA, unique-work decision, and ancestry/preservation proof before normal Git-managed removal.
2. **A successful manual dispatch is mistaken for schedule recovery** — require both a control run and an observed scheduled run with expected ref, permissions, summary, and artifact.
3. **Blocked release state is cleared by bypassing immutable policy** — verify PR/head/base, tags, Hex state, target ledger, and candidate/content digests; then retire or recover through the protected path only.
4. **A timeout fix masks a real PostgreSQL or browser defect** — reproduce first; retain the property's 1,000 executions/invariant and the gallery's discovered-cell, viewport, theme, stress, and overflow coverage.
5. **Docs or broad ignore cleanup destroys proof or perpetuates a false claim** — classify each deletion/ignore rule against tracked state and live workflow/release evidence.

## Implications for Roadmap

Based on the dependencies, use four phases.

### Phase 1: Canonical Workspace and Evidence Preservation

**Rationale:** Every later decision relies on knowing what local/release state exists. Cleanup before provenance review risks destroying unique commits, authorization evidence, or recoverable work.

**Delivers:** A canonical `main` and a written disposition for all worktrees, branches, stashes, and observed release residue; only evidence-backed retirement or preservation actions.

**Addresses:** Canonical workspace, all Git-state disposition, and the closeout evidence foundation.

**Avoids:** Force removal/deletion, history rewriting, and scope expansion. Verification must include worktree/status/stash/branch reachability and preservation evidence.

### Phase 2: Protected Release and Scheduled-Control Recovery

**Rationale:** Release PR disposition and post-publish recovery depend on settled target-ledger and immutable identity facts. Scheduled controls must become truthful without gaining release authority.

**Delivers:** Evidence-backed disposition for PR #222 and stale release state; release-please/repo-hygiene/post-publish recovery or an explicit inapplicable/blocked outcome; manual plus observed scheduled-run evidence where a schedule is applicable.

**Addresses:** Blocked PR, release-please, hygiene, post-publish, and exact-target release-state outcomes.

**Uses:** Existing workflow YAML, `release-target.json`, release-policy scripts/tests, hygiene JSON artifact, pinned actions, and least-privilege permissions.

**Avoids:** Manual merge/dispatch bypass, a `main`-based smoke retry, false green for unavailable GitHub data, or publication merely to clear status.

### Phase 3: Deterministic Release-Path Timeout Repairs

**Rationale:** The two known failures block/undermine protected CI, but their root causes are independent and belong in the existing focused test seams after reproduction. Group them as quality-signal restoration, not CI redesign.

**Delivers:** A narrow PostgreSQL property-test repair and a narrow gallery-matrix repair, each with focused repeated regression proof and unchanged behavioral coverage contract.

**Addresses:** SQLSTATE 57014 in the property path and the 30-second browser gallery matrix timeout.

**Implements:** Existing property fixture/session/isolation seam and existing Playwright test/configuration seam; no schema, UI, dependency, retry policy, or global deadline change.

**Avoids:** Seed-pinning/skipping properties, global/infinite timeout expansion, weakening generated specimen/matrix assertions, and cold-server time being mislabeled as test execution time.

### Phase 4: Repository Truth Reconciliation and Closeout Proof

**Rationale:** Documentation, artifacts, and ignore rules can be made truthful only after workspace and release decisions have settled. This phase converts the completed work into a reproducible, quiet maintenance posture.

**Delivers:** Reconciled maintenance/version/release guidance, tracked/generated artifact and ignore-rule truth, final hygiene/protected-CI evidence, and a disposition-complete clean-state record.

**Addresses:** Documentation/artifact/ignore accuracy and final closeout proof.

**Avoids:** Treating planning or release history as generated junk, broad `.planning/` ignores, cosmetic churn, and unsupported claims about green automation.

### Phase Ordering Rationale

- Inventory precedes irreversible cleanup; final docs must follow the dispositions they describe.
- The release ledger and immutable target govern both blocked-PR action and post-publish eligibility, so they must be reconciled before claiming automation recovery.
- The timeout repairs can proceed in parallel conceptually but should be planned as one bounded quality-signal phase with separate proofs, after their exact CI context is understood.
- Closeout is last because it verifies the combined state rather than assuming it.

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 1:** Inspect live worktree/stash/branch reachability and remote/PR associations before defining any deletion or preservation plan.
- **Phase 2:** Inspect current GitHub workflow runs, token visibility, branch protection, PR #222, Hex/tag state, and target-ledger lifecycle; hosted schedule behavior and remote state are time-sensitive.
- **Phase 3:** Reproduce both failures under the exact CI-relevant PostgreSQL and browser conditions before selecting the narrow repair seam.

Phases with standard patterns (skip research-phase unless new evidence appears):

- **Phase 4:** Existing repository hygiene, Git tracking, documentation, release-policy, and contract-check seams are well documented; use it to validate settled facts rather than redesign the system.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Repository-local versions, pinned actions, scripts, workflows, and test commands directly establish the permitted stack. |
| Features | HIGH | The approved v2.7 boundary in `PROJECT.md` and live repository state define observable outcomes and exclusions. |
| Architecture | HIGH | Existing workflow/policy/hygiene/test seams and observed failing runs give direct component and dependency evidence. |
| Pitfalls | HIGH | Most risks are repository-specific and validated by current state, existing controls, or the two observed failures; hosted schedule details are MEDIUM/LOW external corroboration. |

**Overall confidence:** HIGH

### Gaps to Address

- **Remote state can change after research:** Refresh PR, branch-protection, Actions-run, tag/Hex, and `release-target.json` evidence at the start of Phase 2; distinguish unavailable authority from pass/fail.
- **Exact timeout cause is not yet established:** Capture focused timing and failure evidence before changing test, fixture, session, or Playwright timeout behavior.
- **Disposition may expose unique local work:** Do not precommit to deletion; use a preservation ref or handoff when provenance cannot be proved cleanly.
- **Scheduled-run proof requires time:** A manual dispatch validates control wiring but cannot substitute for an observed cron execution; retain `cannot-check`/pending status honestly until it occurs.

## Sources

### Primary (HIGH confidence)

- Repository-local research: [STACK.md](STACK.md), [FEATURES.md](FEATURES.md), [ARCHITECTURE.md](ARCHITECTURE.md), and [PITFALLS.md](PITFALLS.md).
- `.planning/PROJECT.md` — approved v2.7 goal, target features, and exclusions.
- Existing GitHub workflow definitions, release-policy scripts/tests, `release-target.json`, the repo-hygiene Mix task, current Git inventory, property tests, Playwright configuration/gallery matrix, `MAINTAINING.md`, and `.gitignore`.

### Secondary (MEDIUM confidence)

- [GitHub Actions scheduled events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) and [concurrency](https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency) — default-branch schedule behavior and serialization.
- [Release Please action](https://github.com/googleapis/release-please-action) and [manifest releaser documentation](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) — proposal-only manifest behavior.
- [Git worktree documentation](https://git-scm.com/docs/git-worktree) — normal managed removal and stale metadata handling.

---
*Research completed: 2026-08-21*
*Ready for roadmap: yes*
