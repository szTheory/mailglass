# Phase 117: Release Cut + Milestone Closeout - Context

**Gathered:** 2026-06-21 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the v1.13 "Admin Design-System Stress Test & UX Uplift" body — already built and
verified on local `main` (Phases 109–116) — to Hex adopters, then audit and archive the
milestone. Scope is the **release ceremony + closeout only**: cut the linked-version Hex
release (admin-minor drags matched core + inbound), re-pin the D-13 inbound exact-pin to the
new core version, verify Hex resolution + post-publish smoke green, then audit (`status: passed`
on all 41 requirements) and archive v1.13.

NOT in scope: any product-capability, component, or doc change. No reference-baseline pin bump
(baselines resolve `~> 1.0`). Requirements: REL-02, REL-03.
</domain>

<decisions>
## Implementation Decisions

### Version Target (LOCKED by maintainer)
- **D-01:** Cut the release as a **MINOR — `mailglass 1.8.0` / `mailglass_admin 1.8.0`**
  (core+admin linked), NOT the `1.7.1` patch that the currently-open RP PR #87 proposes.
  Rationale: ~35 `feat` commits since `mailglass_admin-v1.7.0` touch `mailglass_admin/lib/`
  and add **new public component API** (Phase 110 canonical `stat_card` + 3-way theme-picker
  primitive, `data_state/1`, `<.card>`, public filter primitives). New public functions are
  semver-MINOR, and ROADMAP Phase 117 + REL-02 explicitly frame v1.13 as "admin-minor drags
  matched core + inbound."
- **D-02:** **Mechanism is a clean push, not an override.** PR #87 scored a patch (1.7.1)
  ONLY because the v1.13 body is not on `origin/main` — `origin/main` is frozen at `766edf89`
  (PR #86 merge, 2026-06-18) while local `main` carries the full 227-commit v1.13 body. Push
  the v1.13 body to `origin/main`; Release Please re-evaluates and **regenerates PR #87 as
  `1.8.0/1.8.0`** from the now-visible `feat` commits. Do NOT reach for `Release-As:` — only
  use that as a fallback if the natural re-score is somehow blocked.
- **D-03:** Before authorizing the merge, **re-verify the regenerated PR** shows `1.8.0` in the
  manifest + all three `@version` attrs, and the inbound re-pin `{:mailglass, "== 1.8.0"}`
  (RP sed step), with `1.8.0`/`1.4.x` CHANGELOG entries. The version target must reflect the
  pushed body, not the stale PR #87 snapshot.

### Publish Allowlist Hygiene (Wave-0 blocker)
- **D-04:** **Regenerate and commit `.planning/publish/mailglass_admin-files.expected` (and the
  core/inbound snapshots) BEFORE the RP PR merges.** The admin snapshot is stale — at least 4
  new admin/lib files since v1.12 are missing (`theme_controller.ex`, `mount_path.ex`,
  `mount_path_hook.ex`, `operator/tenants.ex`). `publish-hex.yml`'s `prepublish-summary` runs
  `mix mailglass.publish.check`, which **fails closed** on a file delta — this was the real
  Wave-0 blocker in 108. Use only `mix mailglass.publish.check --package <pkg>`; do NOT run
  `mix compile --no-optional-deps --force` on the shared `_build` (pollutes the compile-gated
  /inbound route).

### Inbound Version Line (scope-lock confirmation)
- **D-05:** `mailglass_inbound` ships a **paired release driven solely by the D-13 exact-pin
  re-pin** (`{:mailglass, "== 1.8.0"}`). v1.13 is admin+demo only; inbound's `lib/` changes
  since v1.12 are `docs:` moduledoc strips, not features — no `feat(inbound)`/`fix(inbound)`.
  Verify on the regenerated PR that RP includes an inbound bump (the exact-pin drag forces a
  paired publish); if a pin-only change doesn't score a release, a `fix(inbound):` re-pin
  commit advances its own line. Inbound is currently `1.4.0`.

### Release Ceremony + Closeout (follows the 108 playbook)
- **D-06:** **Reuse the v1.12 Phase 108 6-wave structure verbatim**, retargeted to 1.8.0:
  (Wave 0) green-CI confirm + regenerate stale allowlist; (Wave 1) verify the open/regenerated
  RP PR — versions, inbound re-pin, CHANGELOGs, auto-merge armed; (Wave 2) **maintainer
  go/no-go** human checkpoint authorizing the irreversible merge/publish; (Wave 3) confirm all
  three packages live on Hex at target versions + correct inbound pin; (Wave 4) consumer smoke
  + `post-publish-smoke.yml` **within the 60-minute revert window**; (Wave 5) milestone audit,
  archive, git tag `v1.13`.
- **D-07:** **No reference-baseline pin bump.** `reference/host_app` and `reference/demo_app`
  pin all three packages at `~> 1.0`, which resolves any 1.x bump — baseline change is OUT of
  scope (matching the 108 precedent). Do not touch the 5-file baseline-coupling set.
- **D-08:** **Milestone audit uses corrected scope counts** — **9 phases (109–117)** and **41
  requirements** (FND 5, PRIM 7, FORM 3, SHELL 6, DATA 5, GROUP 3, FLOW 4, RATCHET 5, REL 3 = 41).
  *(Corrected 2026-06-21: the original "36" was an arithmetic error — the per-prefix breakdown sums
  to 41, and REQUIREMENTS.md enumerates 41 distinct REQ-IDs; maintainer-confirmed scope is all 41,
  including REL-01 the PR #86 precondition.)* Do NOT trust
  `gsd-sdk milestone.complete` — it sweeps in 999.x backlog dirs and inflates the matrix.
  Archive artifact set mirrors 108: `v1.13-ROADMAP.md`, `v1.13-REQUIREMENTS.md`,
  `v1.13-MILESTONE-AUDIT.md` (all 41 REQ-IDs `status: passed`), update
  `MILESTONES.md`/`PROJECT.md`/`ROADMAP.md`/`STATE.md`, append `RETROSPECTIVE.md`, then tag
  `v1.13` (a milestone marker, distinct from the RP-created `*-v1.8.0` Hex release tags).
- **D-09:** **Known smoke noise is a non-blocker.** The issue #32 swoosh/hackney OPS-01
  false-positive in `consumer-install` is acceptable; any OTHER red is a real regression to
  evaluate against the MAINTAINING.md Retract Decision Tree.

### Claude's Discretion
- Exact CHANGELOG hand-curation (RP-generated entries are sufficient for a routine ceremony;
  light phrasing cleanup optional).
- Whether the v1.13 body reaches `origin/main` via a direct `git push origin main` (108
  precedent) or a fast-forward path — planner to confirm branch-protection allows it; the
  binding requirement is that the full body is on `origin/main` so RP re-scores to 1.8.0.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/milestones/v1.12-phases/108-release-cut-milestone-closeout/108-01-PLAN.md` — the
  canonical 6-wave release-ceremony template to retarget for v1.13.
- `.planning/milestones/v1.12-phases/108-release-cut-milestone-closeout/108-RESEARCH.md` /
  `108-VALIDATION.md` — supporting research + per-wave validation criteria.
- `MAINTAINING.md` — Release Runbook (5 steps), Retract Decision Tree, required-vs-advisory
  lanes, Publish Summary Snapshot Protocol.
- `.github/workflows/release-please.yml` — sed dep-pin sync step, auto-merge arming, cron
  self-heal.
- `.github/workflows/publish-hex.yml` — `gate-ci-green`, publish ordering
  (core → inbound → admin), idempotency guards, fallback dispatch.
- `.github/workflows/post-publish-smoke.yml` — smoke job chain + inbound compatibility check.
- `scripts/consumer_install_smoke.sh` — `DEP_MODE=hex` consumer smoke (REL-02 Hex-resolution
  proof).
- `.planning/PROJECT.md` (D-13 inbound exact-pin), `.planning/ROADMAP.md` (Phase 117 success
  criteria), `.planning/REQUIREMENTS.md` (REL-02, REL-03).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The entire 108 release ceremony (plan, research, validation, summary) is a near-verbatim
  template — only version numbers (1.8.0 vs 1.7.0), the milestone tag (v1.13), and the audit
  scope counts change.
- `mix mailglass.publish.check --package <pkg>` regenerates allowlist snapshots and is the
  fail-closed gate that `prepublish-summary` enforces.
- RP linked-versions plugin + the sed sync step already encode the inbound re-pin automatically
  on the PR branch — no manual mix.exs edit needed.

### Established Patterns
- **core+admin are linked** (RP `separate-pull-requests: false` + linked-versions); inbound is
  on its own version line but exact-pinned `== <core>`, forcing a paired publish each core bump.
- Publish is **fully hands-free** once the maintainer authorizes the merge (auto-merge armed by
  RP; `hex-publish` environment has no required reviewers).
- Releases are cut from a **protected ref / release tag only** — never dispatch `publish-hex.yml`
  from `main`.

### Integration Points
- RP recomputes versions from `origin/main` HEAD — **the push of the v1.13 body is what flips
  PR #87 from patch to minor.** This is the load-bearing integration moment.
- `.planning/publish/*-files.expected` snapshots ↔ `prepublish-summary` job ↔ `mix
  mailglass.publish.check`.
- Inbound publish pin (`== 1.8.0`) ↔ `post-publish-smoke.yml` inbound compatibility grep.
</code_context>

<specifics>
## Specific Ideas

- The currently-open RP PR is **#87** ("chore: release main"). It will be **regenerated** once
  the body is pushed — re-read it after the push; do not act on its stale 1.7.1 snapshot.
- `origin/main` is at `766edf89`; local `main` at `39613052` carries the 227-commit v1.13 body
  that must be pushed.
</specifics>

<deferred>
## Deferred Ideas

- Registering `guard-release-trigger.yml` as a required branch-protection check — informational
  follow-up noted in 108, not a v1.13 closeout task.
- Reference-baseline pin bump beyond `~> 1.0` — out of scope; only revisit if a future release
  changes the baseline's resolution contract.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
