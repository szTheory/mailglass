# Architecture Research: v2.7 Repository Stewardship & Operational Hygiene

**Domain:** repository stewardship and release-operation recovery for the Mailglass Phoenix/Elixir sibling-package repository
**Researched:** 2026-08-21
**Confidence:** HIGH for repository seams and observed failures; MEDIUM for GitHub scheduled-trigger behavior.

## Recommendation

Treat v2.7 as a recovery-and-evidence pass over the existing control plane. Do not add a maintenance service, release path, CI topology, or product code boundary. The canonical `main` worktree is the only integration root; the repo-hygiene Mix task is the inventory/reporting seam; protected-main release policy plus `.planning/release-target.json` is the release-state authority; and the three existing scheduled workflows are the recovery proofs.

The milestone should first preserve and classify state, then make the smallest deterministic repairs, then invoke existing manual/scheduled workflow entry points to establish current evidence. A clean git state is the final outcome, not an assumption made before examining temporary worktrees, branches, stashes, the open release PR, and release-ledger status.

## Existing System Overview

```
                         protected main (canonical workspace)
                                      │
             ┌────────────────────────┼────────────────────────┐
             │                        │                        │
       repository truth          release policy           product-package proof
             │                        │                        │
  dev/mix/tasks/...hygiene   scripts/release_policy.exs     CI / browser / DB tests
             │                        │                        │
  git + gh inventory          release-target.json       root, admin, inbound
             │                        │                        │
       repo-hygiene.yml ──────┼────── publish-hex.yml ────┘
             │                │             │
             │                │             └─ protected publish only
             │                │
             └──────────── release-please.yml
                              proposal/capture only
                                      │
                         post-publish-smoke.yml
                         immutable completed target
```

### Ownership Boundaries

| Boundary | Existing owner / authority | v2.7 responsibility | Status |
|---|---|---|---|
| Canonical checkout | root `main`, Git worktree metadata | Audit all auxiliary worktrees/branches/stashes for unique commits before removing; retain or preserve only evidence-backed work | Modified state, no new component |
| Repository inventory | `dev/mix/tasks/mailglass.repo.hygiene.ex` | Use `--check --format json` as the reusable disposition report; only use its `--apply` preservation-branch action if local state requires it | Existing component, possibly narrow check correction |
| Protected merge proof | `.github/workflows/ci.yml` and `Guard Release Trigger` | Preserve `CI Green` / `Guard Release Trigger` semantics; repair only the two demonstrated test failures that prevent the release path | Existing workflows and focused tests |
| Release proposal | `.github/workflows/release-please.yml`, Release Please config/manifest | Recover proposal capture against valid ledger state; do not let scheduled retries authorize or publish | Existing workflow, modified only if diagnosis proves it |
| Release authorization/publication | `.planning/release-target.json`, `scripts/release_policy.exs`, `publish-hex.yml` | Keep protected-main policy as executable authority; disposition stale/captured/authorized state rather than manufacture a new release | Existing artifacts, state reconciliation |
| Post-publication proof | `post-publish-smoke.yml`, `check_post_publish_target.sh`, consumer/trust scripts | Recover scheduled/manual proof only against an immutable completed target; keep failure issue lifecycle as evidence | Existing workflow, modified only if exact defect is established |
| Documentation/artifacts | `MAINTAINING.md`, release ledger/candidate records, `.gitignore`, tracked generated files | Correct only claims/artifacts contradicted by current state; retain planning history | Existing docs/config, modified selectively |

## Evidence and Data Flow

### 1. Recovery inventory

```
git status / worktree list / refs / stash list / GH PR + runs
                  ↓
unique-work audit and explicit disposition record
                  ↓
canonical main + no unexplained auxiliary state
                  ↓
mix mailglass.repo.hygiene --check --format json
                  ↓
scheduled repo-hygiene artifact + workflow summary
```

The task already reports git alignment, CI state at `HEAD`, branch protection, open PRs, local branch age, and textual release-workflow readiness. It must remain a read-only reporter in CI. Its `--apply` mode merely creates a preservation branch for dirty/ahead state; it is not a branch/worktree deletion mechanism and should not be expanded into one.

### 2. Release-state recovery

```
release-please schedule/manual proposal
  → protected-main checkout + policy compile
  → proposal identity / candidate capture
  → .planning/release-target.json (captured → authorized → published)
  → protected workflow_dispatch of publish-hex
  → exact tags and Hex state
  → dispatch post-publish-smoke with immutable SHA + three exact versions
```

Caller inputs remain data: `publish-hex.yml` separately checks out protected `main` controls and validates the candidate/content digest before any live job. `post-publish-smoke.yml` resolves either the completed target for schedule or matching immutable target and control-plane identities for dispatch. Preserve those double-checkouts and digest checks. A release event is intentionally a no-op for smoke; scheduled/manual recovery is the designed proof path.

The current ledger is `authorized` for 2.5.0/2.5.0/2.2.0 while those tags already exist, and scheduled `release-please` fails proposal capture because the target status is unsupported. Therefore ledger disposition is a prerequisite to restoring schedule health; changing cron, bypassing policy, or cutting a ceremonial 2.5.1 is not.

### 3. Focused failure repair and proof

```
observed failed CI run
  → exact failing test + bounded correction
  → focused local reproduction
  → protected CI on resulting SHA
  → release PR disposition / scheduled workflow recovery
  → hygiene JSON, workflow URLs, clean git state
```

The only observed release-path defects belong to existing test boundaries:

- `test/mailglass/properties/webhook_idempotency_convergence_test.exs` failed after 966 generated cases with PostgreSQL SQLSTATE 57014. The repair belongs in that property’s transaction/session-timeout isolation or deterministic test fixture, with the actual application `SET LOCAL statement_timeout = '2s'` behavior left intact.
- `mailglass_admin/e2e/gallery-matrix.spec.js` executes a full all-cell × viewport × theme loop and hit Playwright’s 30-second test limit twice. The separately focused stress test passed. The repair belongs in the one matrix test’s bounded execution budget or deterministic loop mechanics, while retaining every discovered-cell assertion and fail-closed overflow invariant. It is not a gallery/UI redesign.

## Exact Integration Points

| Area | Concrete files / seam | Modified vs. new | Dependency / recovery constraint |
|---|---|---|---|
| Workspace truth | Git worktree metadata; root `.gitignore`; existing branches/worktrees | State cleanup; no new files required | Audit commit ancestry/untracked work first; remove only duplicates or explicitly preserved work |
| Hygiene proof | `dev/mix/tasks/mailglass.repo.hygiene.ex`, `.github/workflows/repo-hygiene.yml` | Reuse; modify only a proven false readiness assertion or missing evidence | Run after workspace/PR disposition; preserve JSON artifact and step summary |
| Blocked PR | PR #222 / `release-please--branches--main` | Remote-state disposition, no code component | The PR remains blocked because `CI Green` saw the property timeout; resolve/close only after exact replacement evidence or explicit stale-PR decision |
| Release proposal schedule | `.github/workflows/release-please.yml`; `.release-please-manifest.json`; `release-please-config.json` | Existing workflow/policy; narrow fix only if ledger lifecycle lacks a valid terminal path | First reconcile `.planning/release-target.json`; never make schedule publish-capable |
| Release authorization | `.planning/release-target.json`; `scripts/release_policy.exs`; `scripts/reconcile_release_versions.exs`; policy contract tests | State/documentation reconciliation, perhaps tests | Preserve immutable tags, package payload digest, and three-package atomic unit |
| Protected publication | `.github/workflows/publish-hex.yml`; `scripts/release_policy_validate_target.sh` | No change expected | Do not dispatch/cut a release merely to turn automation green |
| Published smoke | `.github/workflows/post-publish-smoke.yml`; `scripts/check_post_publish_target.sh`; `scripts/consumer_install_smoke.sh` | Existing workflow; narrow diagnosis-driven recovery | Requires a completed immutable target; manual input must agree with control policy |
| Deterministic core proof | `test/mailglass/properties/webhook_idempotency_convergence_test.exs` and its test setup | Focused test change | Validate failure/reproduction under Postgres; retain 1,000-case property and invariant |
| Browser proof | `mailglass_admin/e2e/gallery-matrix.spec.js`, `mailglass_admin/playwright.config.cjs` | Focused test/config change | Keep retry, trace, all-cell discovery, widths, themes, and overflow checks; no UI surface work |
| Documentation and artifacts | `MAINTAINING.md`, release records/ledger, `.gitignore`, tracked generated artifacts | Selective modifications only | Every claim must point to current manifest/tag/run/working-tree evidence; do not delete archived GSD records |

## Dependency-Aware Build Order

1. **Preserve and inventory local/remote state.** Record the canonical `main` SHA, worktrees, stashes, divergent refs, open PR #222, and workflow runs. Create preservation branches only where the existing hygiene action dictates. This makes later cleanup reversible.
2. **Classify release ledger and PR state.** Reconcile the authorized-but-already-published v2.6 target with immutable tags and the stale 2.5.1 Release Please proposal. Decide explicit close/retire/recover outcomes before changing a workflow, because the recurring schedule failures originate at this boundary.
3. **Repair the two observed deterministic test failures.** Work independently in the root property test and admin gallery test. Each must retain its semantic invariant and have a focused reproduction before broader CI.
4. **Prove protected CI and then recover scheduled control-plane checks.** First obtain a green `CI Green` on the exact `main` SHA; then run/observe repo-hygiene, release-please proposal mode, and post-publish-smoke according to their immutable-input contracts. A scheduled run is evidence, not authority.
5. **Reconcile docs, generated/tracked artifacts, and ignores.** Make this follow corrected state, so docs do not freeze an intermediate branch or candidate. Remove only demonstrably stale/generated junk after proving it has no unique work or evidence role.
6. **Close out from the canonical workspace.** Capture workflow URLs/JSON artifacts, exact release-PR outcome, remaining intentional exceptions, `git status`, worktree list, and upstream alignment. Re-run repo hygiene last.

## Anti-Patterns

### Treating schedule recovery as release authorization

**Why it is wrong:** GitHub schedules execute from default-branch workflow state and may be delayed/dropped. Mailglass’s policy intentionally makes schedules proposal/canary paths and makes live publication a digest-bound protected dispatch.

**Do this instead:** Reconcile ledger status and dispatch the existing workflow only with its validated immutable inputs. Record the run, but do not relax policy or create a release just to make the scheduled history green.

### Deleting worktrees or branches before provenance review

**Why it is wrong:** the auxiliary worktrees contain recovery/freshness/retirement commits that may be unique relative to `main`; deletion destroys the only local evidence or fix.

**Do this instead:** compare each ref to `main`, inspect worktree dirtiness and remote status, then retain, merge, archive/preserve, or remove with an explicit outcome.

### Raising global timeouts or weakening assertions

**Why it is wrong:** it hides a property-test session leak or turns the gallery matrix into incomplete proof. The current evidence identifies one PostgreSQL timeout and one 30-second all-cell Playwright loop, not an architectural need for slower CI.

**Do this instead:** change only the isolated test boundary after confirming the invariant is still fully exercised; retain the existing required/advisory topology.

### Treating historical planning records as generated junk

**Why it is wrong:** archived GSD artifacts explain policy and release-state decisions. The repo’s ignores already scope screenshot cache exclusion tightly under research `.cache` directories.

**Do this instead:** remove only artifacts demonstrably regenerated, unreferenced, and not evidence; update ignores narrowly, preserving tracked policy/ledger/history.

## Scalability / Operational Posture

This is a single-repository maintenance operation, not a scaling project. At the current scale, the useful guard is a complete disposition ledger plus existing workflow artifacts. Do not introduce a database, service, dashboard, or orchestration layer. The first operational bottleneck is stale/contradictory release state; the second is test proof that is correct but not reliably bounded in CI. Both have local owners and existing executable seams.

## Sources

- Local: [`dev/mix/tasks/mailglass.repo.hygiene.ex`](../../dev/mix/tasks/mailglass.repo.hygiene.ex), [`.github/workflows/release-please.yml`](../../.github/workflows/release-please.yml), [`.github/workflows/repo-hygiene.yml`](../../.github/workflows/repo-hygiene.yml), [`.github/workflows/publish-hex.yml`](../../.github/workflows/publish-hex.yml), [`.github/workflows/post-publish-smoke.yml`](../../.github/workflows/post-publish-smoke.yml), [`.planning/release-target.json`](../release-target.json), [`MAINTAINING.md`](../../MAINTAINING.md). HIGH: direct repository configuration and 2026-08-21 workflow/PR evidence.
- Local observed failures: `CI` run 32433156236 (Core Deterministic Suite SQLSTATE 57014; Operator Browser Gate 30-second gallery matrix timeout), `release-please` run 32523718397 (unsupported authorized target state), and scheduled `repo-hygiene` / `post-publish-smoke` runs on 2026-08-21. HIGH: direct run logs.
- [GitHub Actions event documentation](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [manual workflow inputs](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow). MEDIUM: official behavior cross-checked through the research seam; confirms default-branch scheduling, potential schedule delay/drop, and dispatch inputs.

---
*Architecture research for: Mailglass v2.7 repository stewardship and operational hygiene*
*Researched: 2026-08-21*
