# Stack Research

**Domain:** Repository stewardship and operational hygiene for an existing Phoenix/Elixir monorepo
**Researched:** 2026-08-21
**Confidence:** HIGH for repository-local stack; MEDIUM for hosted scheduled-workflow behavior

## Recommendation

**Add no runtime, development, CI, or SaaS dependencies.** v2.7 should repair and reconcile the
existing GitHub Actions + GitHub CLI + pinned Beam/Mix toolchain. It already has the exact mechanisms
needed to audit state, recover schedules, prove release identity, run the two affected test paths, and
close with a clean tree. Any package or service addition would be dependency churn outside the approved
maintenance boundary.

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Git + native worktrees/stash/branches | Local Git installation; repository currently uses Git worktrees | Inventory and recover/dispose temporary release worktrees, stashes, divergent branches, and release leftovers | Git already owns all relevant state. Use read-only `git worktree list --porcelain`, `git status --short`, `git branch -vv --all`, `git stash list`, reachability/log checks, then remove only evidence-backed residue. Do not introduce a worktree manager. |
| GitHub Actions | Hosted service; pinned action SHAs in workflow YAML | Scheduled release proposal, hygiene audit, post-publish canary, protected CI | All three affected automations already exist and run from `main`: release-please hourly at minute 17, repo hygiene daily at 12:30 UTC, and post-publish smoke daily at 12:00 UTC. GitHub scheduled workflows run from the default branch, so recovery is configuration/state validation—not a new scheduler. |
| Elixir + Erlang/OTP | Elixir 1.18.4; Erlang/OTP 27.3.4.13 (`.tool-versions`) | Execute existing Mix policy/audit tasks and deterministic test lanes | Existing workflows use `erlef/setup-beam` v1.24.1 in strict version-file mode. Preserve this pin and the root toolchain; do not upgrade Beam as incidental hygiene. |
| Mix + repository-local policy scripts | Existing; package versions from `mix.lock` | Release validation, repo hygiene, canonical `mix ci`, test execution | The repository already exposes `mix mailglass.repo.hygiene --check --format json`, `mix ci`, `mix ci.browser`, and `scripts/release_policy.exs` wrappers. These are the correct integration seams because their outputs are already used by CI and release workflows. |

### Supporting Libraries and Actions

| Library / action | Version pinned in repository | Purpose | When to Use |
|------------------|------------------------------|---------|-------------|
| `googleapis/release-please-action` | v5.0.0, commit `45996ed1f6d02564a971a2fa1b5860e934307cf7` | Manifest-driven release PR proposal; protected release dispatch is layered around it | Keep the existing action and custom release policy. Diagnose/repair the blocked proposal and schedule only through `.github/workflows/release-please.yml`, `release-please-config.json`, `.release-please-manifest.json`, and `.planning/release-target.json`. |
| `actions/checkout` | v7.0.1, commit `3d3c42e5aac5ba805825da76410c181273ba90b1` | Immutable/checkpointed workflow checkouts | Retain the existing SHA pin. Release and post-publish workflows deliberately select protected main, `github.workflow_sha`, proposal heads, or exact tag SHAs; do not replace these with floating tags. |
| `erlef/setup-beam` | v1.24.1, commit `54075bcc5e249e4758d363f27d099f55d843f124` | Strict Beam setup | Retain for all workflow recovery validation. |
| `actions/cache` | v6.1.0, commit `55cc8345863c7cc4c66a329aec7e433d2d1c52a9` | Mix dependency cache | Leave unchanged; cache redesign is explicitly out of scope. |
| `actions/upload-artifact` | v7.0.1, commit `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` | Preserve repo-hygiene JSON evidence | Retain the artifact as the audit closeout record; correct its inputs only if the existing workflow cannot produce the already-required JSON. |
| `rhysd/actionlint` | v1.7.12, commit `914e7df21a07ef503a81201c76d2b11c789d3fca` | Validate workflow syntax | Run the existing actionlint workflow after YAML changes; do not add another YAML linter. |
| PostgreSQL service image | PostgreSQL 16 Alpine, digest-pinned in CI | Existing property-test database backing | Reproduce and narrowly repair the observed statement timeout in the existing `mix test --only property` lane; no database product, ORM, pooler, or test framework addition is warranted. |
| Playwright + Axe | `@playwright/test` ^1.59.1; `@axe-core/playwright` ^4.11.2 | Existing advisory operator browser gallery test | Use `mailglass_admin`'s `npm run test:operator-browser`, already serialized with `--workers=1`; repair the observed gallery timeout at its existing runner/config/test boundary only. Do not add a browser service, visual-test vendor, or another e2e runner. |

### Existing Integration Surfaces

| Work item | Canonical surfaces | Stewardship approach |
|-----------|-------------------|----------------------|
| Canonical workspace and residue | `git worktree`, `git stash`, branch graph/remotes, root `.gitignore`, package `.gitignore` files | Audit unique commits and untracked/ignored artifacts before pruning. The current root worktree is `main`; five temporary release worktrees and one legacy stash are observable repository state, not proof of junk. |
| Release proposal recovery | `.github/workflows/release-please.yml`; `release-please-config.json`; `.release-please-manifest.json`; `.planning/release-target.json`; `scripts/release_policy*.{exs,sh}` | Keep proposal mode (`skip-github-release` when digest is absent), the existing exact-candidate authorization, and SHA-pinned actions. Disposition the release PR only after checking policy lifecycle, required checks, release labels/tags, and candidate/content identity. |
| Scheduled hygiene recovery | `.github/workflows/repo-hygiene.yml`; `dev/mix/tasks/mailglass.repo.hygiene.ex`; workflow artifact `repo-hygiene.json` | Validate the existing schedule/dispatch, token availability, compile, JSON output, summary, and artifact upload. Its non-cancelling `repo-hygiene-${{ github.ref }}` group is appropriate for an audit that should serialize rather than be cancelled. |
| Post-publish recovery | `.github/workflows/post-publish-smoke.yml`; `scripts/check_post_publish_target.sh`; `scripts/verify_published_release.sh` | Preserve exact immutable target/ref binding and the non-cancelling linked-release concurrency group. Scheduled smoke requires a completed target, so a red schedule can be a truthful invalid-state signal—not something to paper over. |
| Property-test timeout | `.github/workflows/ci.yml` property lane; `mix ci.full`; `mailglass_inbound/test/mailglass_inbound/properties/inbound_idempotency_convergence_test.exs` | Keep the 1000-run StreamData property lane and its existing `timeout: :infinity`; identify the database statement that exceeds its server limit, then make a deterministic fixture/query/config correction with a focused regression proof. Do not raise every job/test timeout or weaken iteration count. |
| Browser-gallery timeout | `.github/workflows/ci.yml` browser lane; `mix ci.browser`; `mailglass_admin/package.json`; `mailglass_admin/playwright.config.cjs` | Keep the current single-worker Playwright command and advisory status. Diagnose the gallery's awaited readiness/request and alter only the deterministic cause or that test's bounded timeout. Do not make the whole CI job broadly longer. |
| Docs and artifact truth | package `mix.exs` `@version` and `package.files`; README/CHANGELOG/MAINTAINING docs; `git ls-files`; `.gitignore` | Reconcile tracked artifacts with package allowlists and generated/untracked artifacts with ignore rules. The tracked `.github/.DS_Store` is demonstrable cleanup evidence (`git ls-files -ci` and `.gitignore` both identify it); apply the same evidence threshold to every proposed deletion. |

## Installation

No installation is recommended.

```bash
# Use the repository's locked, existing toolchain.
asdf install
mix deps.get --check-locked
mix ci

# Existing targeted proofs when investigating the two observed failures.
cd mailglass_inbound && mix test --only property
cd ../mailglass_admin && npm ci && npm run test:operator-browser
```

Do not update `mix.lock`, npm dependencies, action versions, PostgreSQL image digests, or the Beam version
as part of v2.7 unless a proven in-scope defect requires the exact change.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Native Git audit and selective cleanup | Worktree-management CLI / repository-cleanup SaaS | Never for this milestone. Consider only if recurring multi-worktree administration becomes a separately approved operational capability. |
| Existing GitHub Actions schedules | External cron, queue, or monitoring service | Only after evidence that GitHub Actions cannot meet an approved availability requirement. No such requirement exists here. |
| Existing release-please v5 + custom policy | Replace release-please or build a new release orchestrator | Only for a separately scoped release-process redesign. Current controls intentionally handle proposal-only and protected publication boundaries. |
| Existing StreamData/PostgreSQL lane | New property testing library, DB proxy, or global timeout increase | Only if a root-cause investigation proves a product bug that cannot be fixed within the existing test/query/config seam. |
| Existing Playwright single-worker runner | Visual-regression vendor, second browser framework, retries-as-policy | Only for an approved test-strategy expansion. The observed work is a narrow release-path timeout repair. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| New Hex packages, npm packages, GitHub Actions, or third-party SaaS | Adds supply-chain surface and maintenance burden without covering a missing capability | Existing Mix scripts, GitHub Actions, `gh`, Git, Playwright, and PostgreSQL test service |
| Beam/Elixir, dependency, action-SHA, Docker-image, or lockfile upgrades | Dependency churn is expressly excluded and would confound recovery evidence | Current strict `.tool-versions`, lockfiles, and SHA pins |
| Global CI timeout increases or blanket retries | Converts a specific failure into a longer/more ambiguous signal and undermines deterministic quality lanes | Targeted root-cause repair plus bounded regression proof |
| CI topology/cache/concurrency redesign | Existing workflow architecture is validated and redesign is out of scope | Minimal repair of failing triggers, credentials, checks, or state assumptions |
| Force deletion of worktrees, stashes, branches, or artifacts | Could destroy unique release evidence or unmerged work | Evidence-backed disposition after reachability, diff, remote/PR, and artifact checks |
| Ceremonial release / manifest bump | Publication without an adopter-facing correction is explicitly out of scope | Explicitly close or retain the release PR based on audited release-policy evidence |

## Version Compatibility

| Package / tool | Compatible With | Notes |
|----------------|-----------------|-------|
| Elixir 1.18.4 | Erlang/OTP 27.3.4.13 | Repository-local source of truth is `.tool-versions`; workflows enforce it through `erlef/setup-beam` strict version-file mode. |
| `mailglass` 2.5.0 | `mailglass_admin` 2.5.0 | Linked core/admin version pair, enforced by release policy. Preserve the currently shipped release state unless an in-scope correction creates a justified proposal. |
| `mailglass` 2.x | `mailglass_inbound` 2.2.0 | Inbound remains independently versioned with an existing floating `~> 2.0` core compatibility declaration; do not re-pin it during hygiene. |
| release-please action v5.0.0 | Existing manifest/config and protected policy wrapper | The repository already pins v5 by full commit. Its manifest workflow and `skip-github-release` support the existing proposal-vs-publication separation. |
| Playwright ^1.59.1 | Current `mailglass_admin` browser test script | Use the lockfile-resolved installation via `npm ci`; do not bump Playwright merely to address a test timeout. |

## Evidence and Sources

### Repository-local evidence (HIGH)

- `.tool-versions` pins Erlang 27.3.4.13 and Elixir 1.18.4.
- Root, admin, and inbound `mix.exs`; their lockfiles; and `mailglass_admin/package.json` establish the existing package/test toolchains.
- `.github/workflows/release-please.yml`, `repo-hygiene.yml`, `post-publish-smoke.yml`, `ci.yml`, `actionlint.yml`, and the local composite action establish the existing automation seams and pinned action revisions.
- `scripts/release_policy.exs`, `scripts/check_post_publish_target.sh`, and `scripts/verify_published_release.sh` establish the existing release-identity and post-publish proof model.
- Live local audit at research time found root `main`, five temporary `/private/tmp/mailglass-release-*` worktrees, one stash, and several release-related branches; these are inputs to an audit, not authorization for deletion.

### External documentation (MEDIUM; verified official sources)

- [GitHub Actions scheduled events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) — scheduled workflows use the default branch/latest default-branch commit; runs can be delayed/dropped under load and public-repository schedules can be disabled after inactivity.
- [GitHub Actions concurrency](https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency) — concurrency groups serialize conflicting runs.
- [release-please action README](https://github.com/googleapis/release-please-action) and [manifest releaser documentation](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) — manifest configuration, proposal-only `skip-github-release`, and PAT-trigger behavior.

---
*Stack research for: Mailglass v2.7 Repository Stewardship & Operational Hygiene*
*Researched: 2026-08-21*
