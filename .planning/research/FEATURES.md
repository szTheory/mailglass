# Feature Research

**Domain:** Repository stewardship and operational hygiene for a protected Phoenix/Elixir package monorepo
**Project:** mailglass v2.7
**Researched:** 2026-08-21
**Confidence:** HIGH for repository mechanisms and scope; MEDIUM for external scheduling/worktree guidance.

## Scope Principle

v2.7 is an operational closeout, not a product increment. A capability belongs only when it produces a directly observable recovery or truth outcome for the already-shipped packages, protected release path, canonical workspace, or release evidence. The existing protected `mix ci` path and published 2.5.0/2.5.0/2.2.0 package family are baselines to preserve.

## Feature Landscape

### Table Stakes (Required Observable Outcomes)

| Maintenance outcome | Why expected | Complexity | Depends on existing mechanisms |
|---|---|---:|---|
| **One canonical, clean `main` workspace** — `main` has an explained ahead/behind state, no uncommitted residue, and is the documented starting point for maintenance. | Maintainers must be able to identify the authoritative checkout and reproduce closeout evidence. | MEDIUM | `git status`, branch/upstream metadata, `.planning/config.json` (`use_worktrees: false`), current `main` policy. |
| **Every temporary worktree, stash, local/remote divergent branch, and release leftover receives a written disposition** — retain/handoff, merge, archive, or remove only after checking it for unique commits and local changes. | Current inventory has five `/private/tmp` linked worktrees, a detached candidate worktree, archival branches, and a stash; silent deletion risks losing authorization/recovery evidence. | MEDIUM | `git worktree list --porcelain`, `git stash list`, reachability/diff inspection, existing release branches and protected release ledger. |
| **Scheduled `release-please` is recovered or has an explicit, evidence-backed no-op/failed disposition** — a scheduled/manual run can create/synchronize only a proposal; protected exact-digest dispatch remains the sole merge/tag boundary. | `release-please.yml` already encodes proposal-vs-protected behavior and hourly recovery. A missing/red scheduled run must not become an unexplained release-state gap. | MEDIUM | `.github/workflows/release-please.yml`, `.planning/release-target.json`, `scripts/release_policy*.{sh,exs}`, protected CI checks. |
| **Scheduled repository hygiene produces an inspectable, non-ambiguous outcome** — each audit reports pass, genuine policy block, or cannot-check; workflow logs and JSON artifact agree. | The existing `mix mailglass.repo.hygiene --check --format json` and daily workflow were specifically built to distinguish operational truth from a false green. | LOW–MEDIUM | `dev/mix/tasks/mailglass.repo.hygiene.ex`, its tests, `repo-hygiene.yml`, branch-protection credentials/API access. |
| **Post-publish automation is recovered from its exact immutable target, or explicitly shown inapplicable** — retries use the protected target versions and 40-character tag SHA; success/failure tracker state is reconciled. | Published package claims require the existing exact-Hex trust journey, not a generic run on `main`. | MEDIUM | `post-publish-smoke.yml`, `publish-hex.yml` dispatch handoff, release-target state, Hex/HexDocs evidence and tracker automation. |
| **Blocked release PR and stale automation are resolved to explicit evidence** — each is merged only through the protected path, closed/retired with a reason, or retained with a named recovery condition; no stale check/auto-merge ambiguity remains. | The release ledger is `authorized` with publication `not_started`, while several release-related worktrees/branches remain. Unexplained limbo is incompatible with a trustworthy release posture. | MEDIUM | GitHub PR/check state, `release-please` protected dispatch, release policy lifecycle tests, branch-protection policy. |
| **The observed PostgreSQL property-test statement timeout has a narrow deterministic fix with a focused regression proof** — the release-path suite completes without loosening global test/database timeouts or hiding the property. | v2.6 records serial/isolated database handling as technical debt; CI and migrations already use bounded statement/lock timeouts. The correct outcome is stable proof of the specific contested path. | MEDIUM | property-test sandbox ownership/isolation support, `Mailglass.Migrations.Postgres.SessionTimeouts`, canonical `mix ci`; no schema/API change. |
| **The observed browser-gallery timeout has a narrow deterministic fix with focused browser proof** — the gallery test completes at its documented matrix without weakening its non-vacuity/overflow contract or changing admin UI. | `gallery-matrix.spec.js` intentionally discovers all specimens and checks 320/390/768/1440 × themes; `operator_browser_gate` is bounded and advisory. | MEDIUM | Playwright gallery matrix, `operator_browser_gate`, existing test IDs and CI Node/Chromium setup. |
| **Documentation, release artifacts, and ignore rules match actual repository state** — version/release guidance, tracked generated evidence, and ignored local artifacts are each demonstrably correct; remove only proven stale/junk items. | `MAINTAINING.md` defines exact recovery paths and `.gitignore` deliberately protects generated local outputs while retaining planning/release artifacts. Drift can produce unsafe release instructions or hide evidence. | MEDIUM | `MAINTAINING.md`, `CHANGELOG.md`, manifests, `.planning/publish/`, `mix mailglass.publish.check`, `.gitignore`, git tracking status. |
| **Closeout proof is reproducible and quiet** — canonical workspace clean, required protected CI remains green, scheduled/recovery workflow results are explained, and the disposition ledger covers every audited object. | The milestone goal is trustworthy maintenance posture, not merely a collection of edits. | MEDIUM | All outcomes above; existing `mix ci`, workflow artifacts, GitHub checks, repository metadata. |

### Differentiators (Only If They Fall Out of Required Work)

No new differentiators are justified. The differentiator is disciplined evidence: a bounded, fail-closed recovery of the current operational system. Do not build a dashboard, generic cleanup framework, new notification channel, or CI observability product to make this milestone feel larger.

| Possible follow-on | Value | Complexity | Decision for v2.7 |
|---|---|---:|---|
| Machine-readable closeout/disposition record | Makes audited state easier to re-check later. | LOW | Accept only if it is the minimal artifact needed to prove the table-stakes dispositions; otherwise record in existing planning/release evidence. |
| One targeted regression test per timeout fix | Prevents the exact observed failure from returning. | LOW–MEDIUM | Required as proof, not a broader test-framework expansion. |

### Anti-Features (Explicit Exclusions)

| Anti-feature | Why it may be requested | Why problematic here | Do instead |
|---|---|---|---|
| **Automatic bulk deletion of worktrees, branches, or stashes** | Fast apparent cleanup. | Can destroy unique, unpushed release authorization or recovery work; current inventory includes active linked worktrees. | Inventory and compare first; use Git-managed removal only after a recorded disposition. |
| **Force-push/rebase/reset to make `main` look clean** | Removes divergence quickly. | Rewrites evidence and can invalidate exact release candidate identity. | Explain and reconcile divergence through ordinary commits/PR disposition; preserve immutable candidate facts. |
| **A ceremonial new Hex release** | Makes maintenance look complete. | Project scope expressly forbids publishing without an adopter-facing correction; publication is irreversible after the short retract window. | Reconcile release state and recover only an already-authorized, evidence-backed path. |
| **CI speed/topology redesign or broad timeout increases** | Makes timeouts less visible. | Masks root causes, expands risk, and violates bounded scope. | Diagnose the one PostgreSQL property and one browser gallery timeout; preserve existing job deadlines and gate classifications. |
| **Changing product APIs, schemas, UI, provider behavior, or dependencies** | Opportunistic cleanup while touching the repo. | Invalidates the v2.6 release baseline and introduces new adopter risk unrelated to stewardship. | Constrain changes to deterministic test/automation/documentation/metadata repairs. |
| **Ignoring broad `.planning/` or generated-artifact paths** | Stops local noise. | Could hide tracked publish summaries, release target evidence, or planning truth that the release policy consumes. | Keep ignores narrowly scoped to demonstrably local/reproducible outputs, as the existing `.planning/research/**/.cache/` rule does. |
| **Treating a missing scheduled run as success** | Keeps status green without access/credentials. | Recreates the prior false-green failure class. | Report `cannot-check` or a hard failure with the missing authority/tooling stated. |

## Feature Dependencies

```text
Canonical workspace + inventory
    └──requires──> unique-work audit for every worktree/stash/branch
                           └──enables──> safe retirement or handoff

Release PR disposition
    └──requires──> release-target lifecycle + exact-candidate policy
                           └──requires──> protected CI evidence
                                  └──enables──> release-please/publish recovery decision

Post-publish recovery
    └──requires──> immutable published target identity
                           └──requires──> completed/authorized release policy state

Targeted timeout repairs
    └──require──> failing-test reproduction
                           └──require──> focused regression proof
                                  └──feed──> canonical closeout proof

Docs/artifact/ignore reconciliation
    └──requires──> final dispositions and verified repository state
```

### Dependency Notes

- **Inventory precedes cleanup:** Git's own `worktree remove` refuses an unclean worktree without force, so the repository must first determine whether every listed worktree or stash contains unique work. Removal and branch deletion are separate decisions.
- **Protected release recovery precedes PR disposition:** the current ledger pins candidate versions, source/proposal SHAs, and a content digest. Any action that changes package content must be treated as a new candidate rather than repaired around that identity.
- **Exact immutable target precedes post-publish smoke:** `post-publish-smoke.yml` requires package versions and a 40-character target SHA for dispatch and uses the release-target policy to verify them. A `main`-based retry is not equivalent evidence.
- **Reproduction precedes timeout adjustment:** v2.6 already certifies explicit workflow timeouts and documents serial/isolated database handling. A timeout fix must identify contention/fixture/readiness behavior and preserve meaningful execution—not skip, seed-pin, or globally extend it.
- **Truth reconciliation is last:** documentation and ignore rules can be evaluated accurately only after release/workspace artifacts have a disposition.

## MVP Definition

### Launch With (v2.7 Closeout)

- [ ] Canonical workspace inventory and recorded disposition of all temporary Git state.
- [ ] Evidence-backed resolution of the blocked release PR, release-please, repo-hygiene, and post-publish automation state.
- [ ] One narrow, reproducible fix and regression proof for each observed release-path timeout.
- [ ] Reconciled maintenance/release docs, tracked artifacts, and ignore rules.
- [ ] Final clean-state, protected-CI, and workflow-evidence closeout record.

### Add After Validation (Only if a v2.7 Required Outcome Exposes a Gap)

- [ ] Minimal machine-readable disposition artifact — only when existing workflow/release evidence cannot name every audited item.
- [ ] A targeted recovery-contract test — only when the repaired automation path lacks a focused regression assertion.

### Future Consideration (Out of Scope)

- [ ] CI/CD efficiency audit — already sequenced separately as `SEED-006`; no speed redesign belongs here.
- [ ] Generic worktree/repository management tooling — support a future multi-worktree workflow only after v2.7 establishes the canonical baseline.
- [ ] New product/release work — require an adopter-facing change and its own milestone.

## Feature Prioritization Matrix

| Outcome | User/maintainer value | Cost | Priority |
|---|---:|---:|---|
| Canonical workspace + safe Git-state disposition | HIGH | MEDIUM | P1 |
| Recovery/disposition of scheduled release and hygiene automation | HIGH | MEDIUM | P1 |
| Exact-target post-publish recovery/disposition | HIGH | MEDIUM | P1 |
| Blocked release PR and stale check disposition | HIGH | MEDIUM | P1 |
| Narrow property/browser timeout repairs with proof | HIGH | MEDIUM | P1 |
| Docs/artifacts/ignore truth | HIGH | MEDIUM | P1 |
| Minimal closeout ledger if needed | MEDIUM | LOW | P2 |
| Generic automation dashboard/tooling | LOW | HIGH | P3 / exclude |

## Evidence Base

### Repository evidence (HIGH)

- `.planning/PROJECT.md` defines the v2.7 bounded maintenance goal and explicitly excludes product expansion, dependency churn, CI-efficiency redesign, cosmetic work, and ceremonial release.
- `git worktree list --porcelain`, `git branch -vv`, and `git stash list` (2026-08-21) show the canonical checkout plus five linked release worktrees, one detached candidate worktree, divergent/archival branches, and one stash.
- `.github/workflows/release-please.yml` separates proposal triggers from the exact-candidate protected merge path; `.planning/release-target.json` records `authorized` / `publication: not_started` identity.
- `.github/workflows/repo-hygiene.yml` invokes `mix mailglass.repo.hygiene --check --format json`, summarizes each check, and uploads its artifact; its task/test pair is already present.
- `.github/workflows/post-publish-smoke.yml` requires immutable package versions and target SHA for dispatch, while `publish-hex.yml` dispatches the exact smoke handoff.
- `test/mailglass/properties/*`, `mailglass_admin/e2e/gallery-matrix.spec.js`, `.github/workflows/ci.yml`, and the v2.6 audit establish the two timeout targets and the existing bounded test/gate posture.
- `MAINTAINING.md`, `.gitignore`, `release-please-config.json`, manifests, and `mix mailglass.publish.check` define the release/document/artifact truth surfaces.

### External guidance (MEDIUM/LOW; used only to confirm the local policy)

- [Git worktree documentation](https://git-scm.com/docs/git-worktree) — `remove` protects unclean worktrees unless forced; cleanup must be deliberate. **MEDIUM** (official primary source, independently aligned with local inventory).
- [GitHub Actions events documentation](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) — scheduled workflows can be delayed and `workflow_dispatch` is an intentional recovery trigger. **MEDIUM** (official primary source).
- Research-plan web-search digests were classified **LOW** by the configured source-confidence seam and are not used for authoritative repository claims.

---
*Feature research for: mailglass v2.7 repository stewardship and operational hygiene*
*Researched: 2026-08-21*
