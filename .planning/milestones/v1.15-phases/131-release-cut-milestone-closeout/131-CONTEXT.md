# Phase 131: Release cut + milestone closeout — Context

**Gathered:** 2026-07-02
**Status:** Ready for planning
**Source:** Orchestrator investigation (repo-verified live state; discuss-phase-equivalent). Roadmap
declared "research: none — plan directly from the v1.13/v1.14 precedent," but direct investigation
surfaced two pin-migration landmines the v1.14 (124) precedent never faced — captured below as D-05/D-11.

<domain>
## Phase Boundary

Cut the real linked **v1.15** Hex release through the pipeline hardened across Phases 125–130, prove
consumer + post-publish smoke against the published packages, and audit + archive the milestone —
validating the whole "CI-the-body" method end-to-end (LD-1, SHIP-01..03).

This is a **release-ceremony + closeout** phase. It writes essentially NO product/source code. The only
source edits are the two pre-flight infra fixes (D-05, D-11) that Phase 125's pin loosening left behind
and that block/degrade this release. Decisions of record for the milestone: `.planning/research/
milestone-cicd/SYNTHESIS.md` (LD-1..13).

**Why this ceremony is SIMPLER than v1.14's (124):**
- **No rebase/reconcile.** Local `main` is **70 commits ahead / 0 behind** `origin/main` — a clean
  fast-forward push (v1.14 had a divergent origin needing a rebase).
- **No `fix(inbound): re-pin ==` dance.** This is the v1.15 keystone payoff (LD-2). Sibling pins are
  already `~>` (inbound `~> 1.10 and >= 1.10.2`, admin `~> 1.10` — landed by `feat(125-01)`), and
  `mix mailglass.publish.check` already REJECTS `==` pins (publish.check.ex:814). Inbound's minor bump
  is **already banked** from the `feat(125-01)` pin-loosening commit — no deliberate re-pin commit is
  needed to cut it.

**Why this ceremony is HARDER than v1.14's:** two pin-migration landmines (D-05, D-11) must be fixed
in Wave 0 before the push, or the release blocks / silently degrades.
</domain>

<decisions>
## Implementation Decisions (locked)

### D-01 — Target versions: 1.11.0 / 1.11.0 / 1.6.0 (RP scores; verify, don't hardcode)
Release Please path-attributes conventional commits since the last release (manifest 1.10.2/1.10.2/1.5.4):
- **core (`.`)** — the CI/DX `feat(...)` commits (feat 128/129/130 touching `.github/`, root `mix.exs`,
  `Makefile`, `lib/mailglass/ci_lanes.ex`, `scripts/`, `guides/` — none in core's exclude-paths) score a
  **minor → 1.11.0**.
- **admin** — linked to core via the linked-versions plugin → **1.11.0**.
- **inbound** — `feat(125-01)` (pin loosening, touched `mailglass_inbound/mix.exs`) scores a **minor →
  1.6.0** (matches the roadmap's "inbound a minor bump for the dependency-policy change").
Let RP re-score after the body reaches origin; **verify** the regenerated PR shows 1.11.0/1.11.0/1.6.0.
`Release-As: 1.11.0` is a FALLBACK only, applied per MAINTAINING.md if RP scores a patch despite the
feat body being on origin. Do NOT hand-edit `.release-please-manifest.json` or `@version`.

### D-02 — No re-pin dance; pins stay `~>` (keystone payoff, LD-2)
Do NOT add any `fix(inbound): re-pin` commit. Inbound stays `{:mailglass, "~> 1.10 and >= 1.10.2"}`,
admin stays `{:mailglass, "~> 1.10"}`. The release-please.yml `==` sed rewrites were deleted in Phase 125
(PIN-03) — a core bump no longer touches sibling pin lines.

### D-03 — Keep inbound floor `>= 1.10.2`; do NOT bump to `>= 1.11.0`
Even though core ships 1.11.0 this cycle, keep inbound's floor at `>= 1.10.2` (the V05 deliveries-migration
fix floor). Bumping the floor to `>= 1.11.0` would FORCE every inbound adopter onto core 1.11.0, re-coupling
exactly what LD-2 decoupled. `~> 1.10` already admits 1.11.x. The mix.exs comment's aspirational
"floor-bump asserting verified against 1.11" is SUPERSEDED here by LD-2's decoupling goal — record the
"verified against core 1.11" assertion in the inbound CHANGELOG/release notes, NOT the floor.

### D-04 — Clean fast-forward push; NEVER --force
Local `main` (HEAD f42eb7fa) is 70 ahead / 0 behind `origin/main` (c34e54e6). Push with a plain
`git push origin main` (fast-forward). No rebase, no force. If a non-ff rejection appears, origin advanced
(new dependabot merge) — `git fetch && git rebase origin/main` then re-push; NEVER force. The pushed HEAD
is what RP tags and what `gate-ci-green` requires a green `ci.yml` run on (human-authored push DOES trigger
ci.yml, so gate-ci-green is satisfied on that SHA).

### D-05 — LANDMINE A (BLOCKING pre-flight fix): inbound `docs_contract_test` contract break
`mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` (the `README and install guide pins
match…` test, ~line 446) is **RED against the loosened pin** (verified: `mix test … --seed 0` → 1 failure,
"mailglass_inbound/mix.exs is missing the MIX_PUBLISH mailglass pin"). Two coupled problems:
  1. **Regex (line ~458)** hardcodes the old `==` form: `~r/\{:mailglass,\s*"==\s*(\d+\.\d+)\.\d+"/` — it
     no longer matches `{:mailglass, "~> 1.10 and >= 1.10.2"}`, so it flunks.
  2. **Invariant break (line ~466–471):** the test asserts the README/install-guide core pin
     (`{:mailglass, "~> X.Y"}`) equals the value it extracts from the inbound `mix.exs` mailglass pin.
     But on the RP release branch, `release-please.yml`'s sed (line ~188) rewrites the README core pin to
     the CORE major.minor (**1.11**), while inbound's mix.exs floor intentionally stays **1.10**. So a
     naive regex fix still fails on the release branch (1.11 ≠ 1.10).

  **Resolution direction (planner to implement, plan-checker to validate):** re-derive the expected core
  pin from the **CORE RELEASE version** (read `.release-please-manifest.json` `.["."]` at repo root, or the
  core `../../../mix.exs` `@version`), NOT from inbound's mix.exs floor pin — because the README tracks
  "what adopters install alongside" (core 1.11) while the mix.exs floor is the decoupled compatibility floor
  (1.10). Additionally KEEP a positive assertion that the inbound floor pin exists and **admits** the core
  version (e.g. `Version.match?(core_version, floor_constraint)`), so the decoupling stays intentional, not
  accidental. This must pass BOTH on `main` today (core 1.10.2, README `~> 1.10`) AND on the RP release
  branch (core 1.11.0, README `~> 1.10`→`~> 1.11` via sed, floor still 1.10).

  Land as a Wave-0 pre-flight commit BEFORE the push. Commit type `test(inbound):` (test-only change;
  inbound's minor is already banked from `feat(125-01)`, so the type does not affect versioning). Scope is
  **inbound-only** — verified core (`test/mailglass/docs_contract_test.exs`) and demo docs_contract tests do
  NOT compare a self-pin this way (no `==`-mailglass regex present).

### D-06 — Publish allowlist fail-closed check (Milestone-1 gap: allowlist gate only runs at release)
Run `mix mailglass.publish.check --package {mailglass,mailglass_admin,mailglass_inbound}` in Wave 0; each
must exit 0. Unlike the v1.14 cycle, Phases 125–130 added NEW tracked files (e.g.
`lib/mailglass/ci_lanes.ex`, mix_audit wiring). The allowlist gate ONLY runs at release, not in PR CI (the
1.10.2 recovery lost 3 tag-move cycles to exactly this). So EXPECT a possible legitimate allowlist update
this cycle — if `publish.check` rewrites any `.planning/publish/*` snapshot, review the diff, `git checkout`
any reference `mix.lock` drift, stage ONLY the `.planning/publish/*` files, and commit as `chore:` (no
version bump). Do NOT run `mix compile --no-optional-deps --force` on the shared `_build` (CLAUDE.md).

### D-07 — Reference baselines are OUT OF SCOPE (pins already `~> 1.0`)
The reference/host_app + demo_app baselines pin `~> 1.0` (de-hardcoded 2026-06-18), which resolves any 1.x
bump. Do NOT touch the 5-file baseline-coupling set. `phoenix_storybook` lives only in
`reference/demo_app/mix.exs` (`only: :dev`) and the demo is never published — no allowlist action.

### D-08 — One human go/no-go gate (Wave 2); hands-free publish after
The single irreversible authorization is the maintainer go/no-go on merging the linked release PR. After
"approved", the publish fan-out is hands-free (prepublish-summary → gate-ci-green → publish-core →
publish-inbound → publish-admin; publish-admin `needs: [publish-core, publish-inbound]`). Document stall
recovery (anti-recursion: `gh workflow run release-please.yml`; publish re-dispatch from the RELEASE TAG,
never main) as non-default paths.

### D-09 — Consumer + post-publish smoke within the 60-minute window (SHIP-02)
Run `scripts/consumer_install_smoke.sh` with DEP_MODE=hex VERSION=1.11.0 VERSION_INBOUND=1.6.0
INCLUDE_INBOUND=true, and monitor `post-publish-smoke.yml`. The consumer smoke pins the consumer app's deps
`== 1.11.0`/`== 1.6.0` (consumer's choice — fine), which forces mix to resolve inbound 1.6.0's
`~> 1.10 and >= 1.10.2` against core 1.11.0 → this is the REL/keystone proof that the `~>` pin admits the
newer core. The issue #32 swoosh/hackney OPS-01 false-positive is the ONLY acceptable red; any other red is
a real regression (evaluate against the MAINTAINING.md Retract Decision Tree).

### D-10 — Milestone audit scope: 7 phases (125–131), 26 requirements; archive + tag v1.15
Audit ALL 26 v1.15 REQ-IDs status: passed — PIN-01..05, GATE-01..04, DET-01..02, MIXCI-01..05,
CACHE-01..02, SUPPLY-01..05, SHIP-01..03 (23 already complete; SHIP-01..03 close in this phase). Hand-count
to true scope — do NOT trust `gsd-sdk milestone.complete` (it sweeps the 999.1/999.2 backlog dirs and
inflates counts). Archive ROADMAP/REQUIREMENTS to `.planning/milestones/v1.15-*`, write
`v1.15-MILESTONE-AUDIT.md` (status: passed), update `.planning/MILESTONES.md`, PROJECT.md, ROADMAP.md,
append RETROSPECTIVE.md, update STATE.md, and `git tag v1.15` + push. (MILESTONES.md lives at
`.planning/MILESTONES.md`, not `.planning/milestones/`.)

### D-11 — LANDMINE B (pre-flight infra fix): post-publish-smoke inbound-compat `==` grep
`.github/workflows/post-publish-smoke.yml:356` decides `include_inbound` via
`grep -F "mailglass == ${VERSION}"` against `mix hex.info mailglass_inbound`. Under the new `~>` pin,
`hex.info` shows `mailglass ~> 1.10 and >= 1.10.2` — the `== ${VERSION}` grep will NOT match → sets
`include_inbound=false` → the post-publish smoke **silently SKIPS the inbound compatibility test**, which is
exactly the `~>`-resolves-from-Hex proof SHIP-02 wants. Fix the check to be `~>`-aware (e.g. match
`mailglass ~>` / `mailglass .* >=`, or use a Version.match against the published core) so inbound smoke
actually runs. Land in Wave 0 alongside D-05 (commit type `ci:` / `fix:` — root/CI path, does not affect
sibling versioning materially; verify it doesn't perturb the intended 1.11.0 core score). `consumer_install_smoke.sh`
injects consumer `==` pins (fine, unchanged).

### Claude's Discretion
- Exact wave structure (recommend mirroring 124-01-PLAN's 6-wave shape: Wave 0 pre-flight incl. D-05/D-06/D-11
  fixes → Wave 1 ff-push + verify regenerated RP PR → Wave 2 maintainer go/no-go → Wave 3 confirm Hex live →
  Wave 4 smoke within 60-min window → Wave 5 audit/archive/tag).
- CHANGELOG hand-curation depth (RP-generated entries are sufficient for a routine infra/DX cycle; a short
  human-curated summary of the v1.15 pipeline hardening is nice-to-have).
- Whether the D-05 and D-11 fixes are one commit each or bundled (recommend separate: `test(inbound):` for
  D-05, `ci:`/`fix:` for D-11, for clean attribution).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Decisions of record
- `.planning/research/milestone-cicd/SYNTHESIS.md` — LD-1..13 (LD-1 release dogfood, LD-2 `~>` pins).
- `.planning/ROADMAP.md` — Phase 131 goal + success criteria (SHIP-01..03); Phase 125 keystone details.
- `.planning/REQUIREMENTS.md` — SHIP-01..03 + the full 26-ID v1.15 traceability (audit scope, D-10).

### The near-verbatim ceremony precedent (retarget from this)
- `.planning/milestones/v1.14-phases/124-release-cut-milestone-closeout/124-01-PLAN.md` — the 6-wave
  linked-release ceremony. RETARGET it: DROP the rebase-reconcile (D-04 clean ff) and DROP the
  `fix(inbound): re-pin ==` step (D-02 keystone payoff); ADD the D-05/D-11 Wave-0 fixes; retarget versions
  to 1.11.0/1.11.0/1.6.0 and the inbound pin to `~> 1.10 and >= 1.10.2`.
- `.planning/milestones/v1.14-phases/124-release-cut-milestone-closeout/124-CONTEXT.md` — the CONTEXT shape.

### Release machinery
- `MAINTAINING.md` — Release Runbook (line ~274), Release-As fallback (~line 319), Retract Decision Tree,
  required-vs-advisory lanes, Publish Summary Snapshot Protocol.
- `.github/workflows/release-please.yml` — README/install pin sed sync (lines ~153–207; note it sets the
  README core pin to CORE_MM = 1.11, the root of the D-05 invariant break); auto-merge arming; cron self-heal.
  Confirm the `==` sed rewrites were deleted in Phase 125 (PIN-03).
- `.github/workflows/publish-hex.yml` — gate-ci-green SHA-bound requirement; publish ordering core →
  inbound → admin; publish-admin `needs: [publish-core, publish-inbound]`; idempotency guards.
- `.github/workflows/post-publish-smoke.yml` — smoke chain; the D-11 inbound-compat grep at line ~356.
- `scripts/consumer_install_smoke.sh` — DEP_MODE=hex consumer smoke (SHIP-02 Hex-resolution proof).
- `lib/mix/tasks/mailglass.publish.check.ex` — `verify_deps` (line ~814 REJECTS `==` pins),
  `verify_linked_constraint` (~836); confirms pins are correctly `~>`.
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` — the D-05 blocker (test ~line 446–472).
- `mailglass_inbound/mix.exs` — the loosened `mailglass_dep` (`~> 1.10 and >= 1.10.2`) + the forward-guidance
  comment D-03 supersedes.
</canonical_refs>

<specifics>
## Specific Ideas / Verified Live State (use these facts)

- **Versions now:** mailglass 1.10.2 / mailglass_admin 1.10.2 / mailglass_inbound 1.5.4 (manifest matches).
- **Pins now:** inbound `{:mailglass, "~> 1.10 and >= 1.10.2"}` (mix.exs:143), admin `{:mailglass, "~> 1.10"}`
  (mailglass_admin/mix.exs:147). Dev/test uses the local path dep.
- **Git:** local `main` f42eb7fa is 70 ahead / 0 behind `origin/main` c34e54e6 — clean ff (D-04).
- **No open "chore: release main" RP PR** (PR #96 is an unrelated dependabot igniter bump). RP regenerates
  AFTER the body reaches origin.
- **Expected targets (RP-scored, verify):** 1.11.0 / 1.11.0 / 1.6.0 (D-01).
- **Confirmed RED now:** `mix test mailglass_inbound/.../docs_contract_test.exs --seed 0` → 1 failure (D-05).
- **26 v1.15 REQ-IDs**, 23 complete, SHIP-01..03 open (D-10 audit scope).
- **RP config** (`release-please-config.json`): core excludes brandbook/.planning/prompts/admin/inbound;
  linked-versions groups core+admin; inbound is its own line.
</specifics>

<deferred>
## Deferred Ideas
- **Postgres schema isolation (v2.0)** — SCHEMA-01/02; the V01 events-immutability trigger hard-bound to
  `public` collides under a non-public prefix. Explicitly the NEXT milestone; this phase must not touch schema.
- **DET-A1** (Option A honest-async inbound suite), **SUPPLY-A1** (`dependency-review.yml` on PRs) — deferred
  post-v1.15 hardening, not blocking.
- **`dependency-review.yml`, sobelow, min-floor matrix row, test partitioning** — out of scope (see
  REQUIREMENTS.md Out of Scope).
</deferred>

---

*Phase: 131-release-cut-milestone-closeout*
*Context gathered: 2026-07-02 via orchestrator investigation (repo-verified)*
