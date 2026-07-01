# Phase 124: Release Cut + Milestone Closeout - Context

**Gathered:** 2026-06-28 (assumptions mode + research validation)
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the v1.14 "Operator IA & Lived-Experience Redesign" body — already built and verified on
local `main` (Phases 118–123) — to Hex adopters, then audit and archive the milestone. Scope is
the **release ceremony + closeout only**: cut the linked-version Hex release (admin-minor drags
matched core + inbound), re-pin the D-13 inbound exact-pin to the new core version, verify Hex
resolution + consumer + post-publish smoke green, then audit (`status: passed` on all 15 v1.14
requirements) and archive v1.14.

NOT in scope: any product-capability, component, surface, or doc change. No reference-baseline
pin bump (baselines resolve `~> 1.0`). No new providers/transports/routes (D-23). Requirements:
REL-01, REL-02.
</domain>

<decisions>
## Implementation Decisions

### Version Targets (LOCKED by maintainer)
- **D-01:** Cut the release as a **MINOR — `mailglass 1.10.0` / `mailglass_admin 1.10.0`**
  (core+admin linked). Rationale: the v1.14 body (Phases 118–123) adds new public admin
  component/IA API (surface redesigns, new public component shapes) — semver-MINOR — and
  ROADMAP Phase 124 + REL-01 frame v1.14 as "admin-minor drags matched core + inbound." Current
  `@version` is `1.9.0` in both `./mix.exs` and `mailglass_admin/mix.exs`.
- **D-02:** **`mailglass_inbound` ships `1.5.2` — a PATCH** (currently `1.5.1`), re-pinned
  `{:mailglass, "== 1.10.0"}`. Inbound has **zero `lib/` changes** this cycle — the only delta is
  the exact-pin re-pin. A pure dependency-pin bump is semver-honestly a PATCH, and the documented
  re-pin idiom is a `fix(inbound):` commit which RP auto-scores to a patch. *(Maintainer chose
  1.5.2 over a cadence-only 1.6.0 — semver honesty over visual step-with-core.)*
- **D-03:** **Mechanism is push-the-body-and-let-RP-re-score** — NOT `Release-As:`. No open
  Release-Please PR exists yet; it regenerates once the v1.14 body reaches `origin/main` and
  should self-score `1.10.0/1.10.0` from the now-visible admin `feat` commits. `Release-As: 1.10.0`
  is a **fallback only**, used solely if Wave 1 shows RP scored a patch despite the body being on
  origin (the v1.13 failure mode, where the body wasn't yet pushed).

### Origin-Divergence Reconciliation (the one structural delta vs the 117 precedent)
- **D-04:** **Reconcile by `git rebase origin/main`, then an ordinary fast-forward `git push
  origin main`. NEVER `--force`.** Local `main` (`043521a7`) is 124 commits ahead of `origin/main`
  (`63c3f4c3`) AND 1 behind — origin carries one commit local lacks: `63c3f4c3 chore(deps): bump
  actions/checkout from 6.0.3 to 7.0.0 (#88)`, a dependabot squash-merge. A plain push is a
  non-fast-forward rejection. The v1.14 body is 124 **individual conventional commits with zero
  merge commits**, so rebasing replays them atop the dependabot commit → clean linear history (the
  shape RP and the runbook assume) and a normal fast-forward push (no force needed, since the
  replayed commits descend from current origin HEAD). Prefer rebase over a merge commit (which
  would permanently break `main`'s linear-history invariant for only a cosmetic SHA-preservation
  gain).
- **D-05:** **The rebased HEAD SHA is what RP tags and what `gate-ci-green` requires a green
  `ci.yml` run on.** Because `63c3f4c3` modified **`ci.yml` itself**, the body MUST be replayed on
  top of it (rebase does this) so the released ancestry carries the correct CI definition. After
  the push, **confirm `ci.yml` runs and goes green on the new `origin/main` HEAD before authorizing
  the RP-PR merge.** This push is human-authored (admin direct push), so it *does* trigger
  `ci.yml` — the "no ci.yml runs found for SHA" anti-recursion gap bites only the *later*
  bot-auto-merged release SHA (covered by `gate-ci-green`'s self-heal), not this push.
- **D-06:** **Re-fetch immediately before the rebase** (`git fetch origin && git rebase
  origin/main` as a unit, close to push time) — origin could gain another dependabot merge before
  the ceremony. If a non-fast-forward rejection appears *after* rebasing, origin advanced again:
  re-fetch and re-rebase, **never force**. Stale `.planning/` SHA references after the rebase are
  cosmetic — do not "fix" them by force-pushing old SHAs.

### Inbound Pin-Drag Paired Release (will NOT auto-cut — must be deliberate)
- **D-07:** **The sed-rewritten inbound pin does NOT auto-cut an inbound release.** Inbound is not
  in the linked-versions component list, there is no Elixir dependency-propagation plugin, and the
  RP sed pin-sync lands as a non-releasable `chore` on the PR branch. Land a deliberate
  **`fix(inbound): re-pin to == 1.10.0`** commit on `origin/main` **before the RP PR merges** so RP
  folds the inbound `1.5.2` bump into the same linked release PR. Publish ordering
  (`publish-admin needs: [publish-core, publish-inbound]`) means a missing/absent inbound release
  **blocks the admin publish** — this is not optional. Do NOT merge an inbound-less RP PR.

### Publish Allowlist Hygiene (Wave-0 confirm — expected clean this cycle)
- **D-08:** **The publish allowlist is NOT stale this cycle.** `comm` diffs show zero deltas across
  all three `.planning/publish/*-files.expected` snapshots, and zero untracked files under admin
  `lib/priv/docs`. Still run `mix mailglass.publish.check --package <pkg>` as the fail-closed Wave-0
  confirmation (the recurring 108/117 blocker), but expect a clean no-op. Do NOT run
  `mix compile --no-optional-deps --force` on the shared `_build` (pollutes the compile-gated
  /inbound route).
- **D-09:** **`phoenix_storybook` cannot leak into any published package.** It lives ONLY in
  `reference/demo_app/mix.exs` as `{:phoenix_storybook, "~> 1.2", only: :dev}` — entirely absent
  from `mailglass_admin/mix.exs`, and the demo_app is never published. It is structurally incapable
  of appearing as a runtime dep or in the admin Hex tarball.

### No Reference-Baseline Bump (matches 117 D-07)
- **D-10:** **No reference-baseline pin bump.** `reference/host_app` and `reference/demo_app` pin
  all three packages at `~> 1.0`, which resolves any 1.x bump — the 5-file baseline-coupling set is
  untouched. Out of scope.

### Release Ceremony + Closeout (reuse the 108/117 6-wave playbook verbatim → 1.10.0)
- **D-11:** **Reuse the 6-wave ceremony structure**, retargeted to 1.10.0/1.10.0/1.5.2:
  - **Wave 0** — green-CI confirm on the new origin HEAD + allowlist `publish.check` no-op (D-05, D-08).
  - **Wave 1** — verify the regenerated RP PR: `1.10.0` in the manifest + all three `@version`,
    inbound `1.5.2` present in the SAME PR with `== 1.10.0` pin (sed sync), CHANGELOGs, auto-merge
    armed, required CI checks reporting (not "no checks"). If RP scored a patch → apply the
    `Release-As: 1.10.0` fallback. If inbound is absent → land the `fix(inbound):` commit and let
    RP regenerate.
  - **Wave 2** — **maintainer go/no-go** human checkpoint authorizing the irreversible merge/publish.
  - **Wave 3** — confirm all three packages live on Hex at target versions + correct inbound pin.
  - **Wave 4** — consumer smoke (`DEP_MODE=hex`) + `post-publish-smoke.yml` **within the 60-minute
    revert window**.
  - **Wave 5** — milestone audit, archive, git tag `v1.14`.
- **D-12:** **Milestone audit scope is 7 phases (118–124) and 15 requirements**: METHOD 2,
  STORY 2, SHELL 3, DELIV 1, INB 1, PREV 1, COH 2, SEED 1, REL 2. Literal IDs (verify verbatim):
  COH-01/02, DELIV-01, INB-01, METHOD-01/02, PREV-01, REL-01/02, **SEED-003** (NOT SEED-01),
  SHELL-01/02/03, STORY-01/02. Note REL has only **two** IDs this milestone (unlike v1.13's three).
  All 15 → `status: passed`. Do NOT trust `gsd-sdk milestone.complete` — it sweeps the 999.x backlog
  dirs and inflates the matrix; hand-count to true scope. Archive artifact set mirrors 117:
  `v1.14-ROADMAP.md`, `v1.14-REQUIREMENTS.md`, `v1.14-MILESTONE-AUDIT.md` (all 15 REQ-IDs passed),
  update `MILESTONES.md`/`PROJECT.md`/`ROADMAP.md`/`STATE.md`, append `RETROSPECTIVE.md`, then tag
  `v1.14` (a milestone marker, distinct from the RP-created `*-v1.10.0` Hex release tags).
- **D-13:** **Known smoke noise is a non-blocker.** The issue #32 swoosh/hackney OPS-01
  false-positive in `consumer-install`, and advisory lanes going red, do not block `gate-ci-green`.
  Any OTHER red is a real regression to evaluate against the MAINTAINING.md Retract Decision Tree.

### Claude's Discretion
- Exact CHANGELOG hand-curation (RP-generated entries are sufficient for a routine ceremony; light
  phrasing cleanup optional).
- Exact wording of the `fix(inbound):` re-pin commit body, and whether to land it before or
  simultaneously with the body push (binding requirement: it is on `origin/main` before the RP PR
  merges).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/milestones/v1.13-phases/117-release-cut-milestone-closeout/117-CONTEXT.md` — the
  closest precedent; mirror its decision structure (retarget 1.8.0→1.10.0, v1.13→v1.14).
- `.planning/milestones/v1.12-phases/108-release-cut-milestone-closeout/108-01-PLAN.md` — the
  canonical 6-wave release-ceremony template to retarget.
- `.planning/milestones/v1.12-phases/108-release-cut-milestone-closeout/108-RESEARCH.md` /
  `108-VALIDATION.md` — supporting research + per-wave validation criteria.
- `MAINTAINING.md` — Release Runbook (5 steps), Retract Decision Tree, required-vs-advisory lanes,
  Publish Summary Snapshot Protocol, `Release-As:` fallback (~line 296).
- `.github/workflows/release-please.yml` — sed dep-pin sync step (PINS array, ~lines 139–263,
  rewrites both admin and inbound core pins), auto-merge arming, cron self-heal.
- `.github/workflows/publish-hex.yml` — `gate-ci-green` (SHA-bound green-CI requirement), publish
  ordering (core → inbound → admin; `publish-admin needs: [publish-core, publish-inbound]`),
  idempotency guards, fallback dispatch.
- `.github/workflows/post-publish-smoke.yml` — smoke job chain + inbound compatibility check.
- `scripts/consumer_install_smoke.sh` — `DEP_MODE=hex` consumer smoke (REL-01 Hex-resolution proof).
- `mailglass_inbound/mix.exs` (~lines 114–136) — the exact-pin + `fix(inbound):` re-pin idiom + the
  recovery note.
- `.planning/PROJECT.md` (D-13 inbound exact-pin, D-23 no-capability-growth, D-28 ship-to-Hex),
  `.planning/ROADMAP.md` (Phase 124 success criteria), `.planning/REQUIREMENTS.md` (REL-01, REL-02
  + the 15 v1.14 REQ-IDs).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The entire 108/117 release ceremony (plan, research, validation, summary) is a near-verbatim
  template — only version numbers (1.10.0 vs 1.8.0; inbound 1.5.2), the milestone tag (v1.14), and
  the audit scope counts (7 phases / 15 reqs) change.
- `mix mailglass.publish.check --package <pkg>` is the fail-closed allowlist gate that
  `prepublish-summary` enforces — expected clean no-op this cycle.
- The RP sed/PINS step already encodes the inbound + admin pin re-write automatically on the PR
  branch — no manual mix.exs pin edit needed (but the inbound *release* still needs a deliberate
  `fix(inbound):` commit — D-07).

### Established Patterns
- **core+admin are linked** (RP `separate-pull-requests: false` + linked-versions); inbound is on
  its own version line but exact-pinned `== <core>`, forcing a paired publish each core bump.
- Publish is **fully hands-free** once the maintainer authorizes the merge (auto-merge armed by RP;
  `hex-publish` environment has no required reviewers).
- Releases are cut from a **protected ref / release tag only** — never dispatch `publish-hex.yml`
  from `main`.
- `main` history is **linear** (squash-merge) — the runbook and RP changelog assume this; the
  rebase reconciliation (D-04) preserves it.

### Integration Points
- RP recomputes versions from `origin/main` HEAD — **the push of the v1.14 body is what makes RP
  re-score to 1.10.0.** This is the load-bearing integration moment (D-03).
- The rebased HEAD SHA ↔ `gate-ci-green` (a green `ci.yml` run must exist on it) ↔ the RP release
  tag (D-05).
- `.planning/publish/*-files.expected` snapshots ↔ `prepublish-summary` job ↔
  `mix mailglass.publish.check`.
- Inbound publish pin (`== 1.10.0`) ↔ `publish-admin needs: [publish-core, publish-inbound]` ↔
  `post-publish-smoke.yml` inbound compatibility grep.
</code_context>

<specifics>
## Specific Ideas

- `origin/main` is at `63c3f4c3` (carries lone dependabot `#88` actions/checkout 6→7); local `main`
  at `043521a7` carries the 124-commit v1.14 body. No RP PR is open yet — it regenerates after the
  body reaches origin.
- Of the 124 body commits, ~29 are releasable `feat`/`fix`; the rest are `docs:`/`chore:` (and
  `docs(state):` STATE updates). Zero merge commits on the body — rebase keeps it clean.
- Inbound's version line history is patch-per-repin in spirit; 1.5.1 → 1.5.2 is the honest step
  this cycle (maintainer-confirmed).
</specifics>

<deferred>
## Deferred Ideas

- Making the inbound pin-sed change a deterministic RP release trigger (extra-files / a propagation
  plugin) — no clean Elixir-native solution exists; the deliberate `fix(inbound):` commit is the
  accepted idiom. Not a v1.14 closeout task.
- Registering `guard-release-trigger.yml` as a required branch-protection check — informational
  follow-up carried since 108, not a closeout task.
- Reference-baseline pin bump beyond `~> 1.0` — out of scope; only revisit if a future release
  changes the baseline's resolution contract.

### Reviewed Todos (not folded)
None — no pending todos matched this phase (no todo tooling configured).
</deferred>
