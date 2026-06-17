# Phase 108: Release Cut + Milestone Closeout — Research

**Researched:** 2026-06-17
**Domain:** Hex release ceremony, Release Please mechanics, linked-version publish pipeline, milestone audit/archive
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from locked decisions)

### Locked Decisions
- **D-28: ACTUALLY CUT the release.** Deliberate change from v1.7/v1.11 prepare-only precedent. The accumulated v1.7–v1.12 body of work must ship to Hex.
- **Target versions:** Release Please default → `1.7.0` for core (`mailglass`) and `1.7.0` for admin (`mailglass_admin`) (linked-versions group). Accept RP default; NO `Release-As` override.
- **Inbound target:** `mailglass_inbound` gets a `fix(inbound):` bump as part of the re-pin. The sed step in the RP workflow pre-syncs the pin on the release PR branch, but a separately committed `fix(inbound):` is required to actually ship the new pin to Hex.
- **REL-02 / D-13:** `mailglass_inbound/mix.exs` `mailglass_dep/0` must be updated to `{:mailglass, "== 1.7.0"}` and a `fix(inbound):` commit must land (before or on the release PR) to trigger an inbound release.

### Claude's Discretion
- Ordering within the ceremony (pre-flight vs. re-pin first vs. after PR merge) — research recommends the safest sequence.
- Whether reference baseline pin-bump (reference/host_app + demo_app from `~> 1.4` to `~> 1.7`) is in scope for this phase.

### Deferred Ideas (OUT OF SCOPE)
- New product capability, providers, transports, routes.
- Marketing email features.
- reference/host_app + demo_app pin-bump (recommended deferred — see Q8 answer below).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Real linked-version Hex release cut: CHANGELOG entries, admin-minor drags core+inbound, RP PR merges green, all three packages publish to Hex | Verified: RP linked-versions plugin covers core+admin; inbound NOT linked; publish fan-out is `publish-core` → `publish-inbound` → `publish-admin` |
| REL-02 | D-13 inbound exact-pin re-pin after merge: `{:mailglass, "== 1.7.0"}` committed as `fix(inbound):`, `mix deps.get` Hex resolution, post-publish-smoke verified green | Verified: `mailglass_inbound/mix.exs:127` carries the pin; RP sed pre-syncs the branch but does NOT ship to Hex without a `fix(inbound):` bump commit |
</phase_requirements>

---

## Summary

Phase 108 is a release ceremony, not a code-writing phase. Its job is to move the accumulated v1.7–v1.12 body of work (Phases 91–107 — brand adoption, admin UI polish, design-system uplift, installer DX hardening, onboarding docs, a11y parity) from `main` to Hex adopters. The ceremony is well-engineered: the pipeline is largely hands-free once started, but has four documented stall modes and one mandatory manual step (the inbound `fix(inbound):` commit).

The key architectural fact is that `mailglass_inbound` is NOT part of the `linked-versions` plugin group. Core and admin are linked (they move together as `1.7.0`); inbound is on its own version line. A `fix(inbound):` commit MUST land to bump inbound to whatever its next version is (currently `1.3.1` → `1.3.2` or `1.4.0` depending on scope), carrying the new `{:mailglass, "== 1.7.0"}` pin. Without this commit, the Release Please PR will only contain core+admin bumps, the sed step on the RP branch will pre-sync the pin in git but inbound will still ship `== 1.6.2` to Hex — breaking dependency resolution for any adopter who pins core at 1.7.0 and tries to use inbound.

The publish pipeline is idempotent and order-guaranteed (`publish-core` before `publish-inbound` before `publish-admin`). The gate-ci-green job self-heals the anti-recursion case (auto-merged RP commit gets no ci.yml run — the job dispatches ci.yml on the tag and waits). Three publish allowlist files (`mailglass-files.expected`, `mailglass-publish-summary.json`, etc.) are stale relative to v1.12's new files and MUST be regenerated with `mix mailglass.publish.check` before the release PR merges.

**Primary recommendation:** Run `fix(inbound):` commit first to ensure the Release Please PR contains all three package bumps. Then run the allowlist hygiene step. Then let the RP PR auto-merge and monitor the fan-out.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Version bump computation | Release Please (GitHub Action) | None | Reads commit history since last tag; linked-versions plugin enforces core+admin parity |
| inbound pin re-sync (branch) | release-please.yml sed step | None | Runs after RP action creates the PR branch; writes to `mailglass_inbound/mix.exs` and `mailglass_admin/mix.exs`; commits with `RELEASE_PLEASE_PAT` so ci.yml fires |
| inbound Hex publish | publish-hex.yml `publish-inbound` job | Maintainer fallback dispatch | Requires `fix(inbound):` commit to exist before RP PR is created so inbound @version is bumped |
| Publish allowlist gate | `mix mailglass.publish.check` (`prepublish-summary` job) | Maintainer pre-flight | Diffs against `.planning/publish/*-files.expected`; aborts if new files are not in the allowlist snapshot |
| CI green gate | `gate-ci-green` job (publish-hex.yml) | Self-heal via ci.yml dispatch | Self-heals anti-recursion case; gates on required lanes only; advisory lanes do not block |
| Milestone audit/archive | Maintainer (manual) | gsd-sdk `milestone.complete` CLI | CLI inflates counts; must be manually corrected before writing STATE.md/MILESTONES.md |

---

## Q&A: All Ten Research Questions

### Q1 — Bump derivation: what will Release Please propose?

**Bump-triggering commits since 1.6.2 (feat/fix, by package path):**

Core package (`lib/`, `mix.exs`, `guides/`):
- `feat(104-02)` — `194fc8b2` `feat(104-02): fail-closed validate_preflight/1 + format_error/1 clause` (touches `lib/mailglass/installer/apply.ex`)
- `feat(104-02)` — `29ae7bc4` `feat(104-02): add Mailglass.Installer.Doctor + mix mailglass.doctor static scan` (touches `lib/mix/tasks/mailglass.doctor.ex`)
- `feat(106-02)` — `90c7f562` `feat(106-02): register production-go-live-checklist and errors-and-troubleshooting in mix.exs docs` (touches `mix.exs`)

`mailglass_admin/` package:
- `feat(107-01)` — `8feb0b1d` `feat(107-01): add Escape-to-close + real ids on inbound replay modal`
- `feat(107-01)` — `b9bfbfd5` `feat(107-01): add focus-management sibling span to inbound_live.ex`
- Multiple earlier `feat(9x-01..03)` and `fix(9x)` commits touching admin UI (Phase 97–103)

`mailglass_inbound/` (pre-existing since last real inbound release):
- `feat(99-01)` — `01aee8ec` — `feat(99-01): implement tenant-scoped inbound summary read model` — touches `mailglass_inbound/lib/`

**RP decision:**
- `mailglass` (core) → **minor bump** (feat commits touching `lib/` under `"."` scope, with `exclude-paths` covering `brandbook/`, `.planning/`, `prompts/`, `mailglass_admin/`, `mailglass_inbound/`) → `1.7.0` [VERIFIED: release-please-config.json]
- `mailglass_admin` → **minor bump** via linked-versions plugin dragging it to match core → `1.7.0` [VERIFIED: release-please-config.json, linked-versions plugin]
- `mailglass_inbound` → **will only bump if a `fix(inbound):` or `feat(inbound):` commit exists before the RP PR is created.** Without that commit, inbound stays at `1.3.1` on the PR and on Hex, and the sed step's pin update is only cosmetic (git changes not shipped). [VERIFIED: `mailglass_inbound/mix.exs:114-131` comment block; `release-please-config.json` — inbound NOT in linked-versions components array]

**Linked-versions config (verbatim from `release-please-config.json`):**
```json
"plugins": [
  {
    "type": "linked-versions",
    "groupName": "mailglass-sibling-group",
    "components": ["mailglass", "mailglass_admin"]
  }
]
```
`mailglass_inbound` is explicitly absent from this list. [VERIFIED: `release-please-config.json:24-30`]

**Exclude-paths for core:**
```json
"exclude-paths": ["brandbook", ".planning", "prompts", "mailglass_admin", "mailglass_inbound"]
```
[VERIFIED: `release-please-config.json:8`]

### Q2 — The mandatory inbound re-pin (REL-02 / D-13): exact mechanism

**Mechanism summary (three distinct things that must ALL happen):**

**Part A — The sed pre-sync (automatic, but git-only):**
After RP creates the PR branch, `release-please.yml` runs a sed step ("Sync sibling package -> mailglass dep pin on release-please branch") that rewrites:
- `mailglass_admin/mix.exs`: `{:mailglass, "== 1.6.2"}` → `{:mailglass, "== 1.7.0"}`
- `mailglass_inbound/mix.exs`: `{:mailglass, "== 1.6.2"}` → `{:mailglass, "== 1.7.0"}`
- README files and `mailglass_inbound/docs/inbound-install.md` for `~>` pins
- `.planning/publish/mailglass_inbound-publish-summary.json` version fields
This uses `RELEASE_PLEASE_PAT` so ci.yml fires on the branch. [VERIFIED: `release-please.yml:139-263`]

**This does NOT bump inbound's `@version`.** The sed step updates the `{:mailglass, "== X.Y.Z"}` dep pin inside the existing inbound release, but inbound's `@version` is only bumped by Release Please computing a new inbound release — which only happens if bump-triggering commits exist under the `mailglass_inbound` scope.

**Part B — The `fix(inbound):` commit (REQUIRED, must land BEFORE RP creates the PR):**
A commit with title `fix(inbound): re-pin {:mailglass, "== 1.7.0"} for core 1.7.0 release` must be squash-merged into `main` before the RP PR is created (or before the existing RP PR is updated). This commit:
- Touches `mailglass_inbound/mix.exs` line 127: change `{:mailglass, "== 1.6.2"}` → `{:mailglass, "== 1.7.0"}`
- Signals to Release Please that a `fix`-level inbound release is needed
- Result: RP will propose `mailglass_inbound` `1.3.1` → `1.3.2` (patch bump from `fix`)

**File and line:** `mailglass_inbound/mix.exs:127` — `{:mailglass, "== 1.6.2"}` inside `defp mailglass_dep do` / `if System.get_env("MIX_PUBLISH") == "true"` branch. [VERIFIED: `mailglass_inbound/mix.exs:125-131`]

**The critical gotcha — do NOT pre-bump on main before the RP PR:**
If you manually update the pin in `mailglass_inbound/mix.exs` on `main` without a semantic bump-triggering commit wrapper, or if you hand-edit the pin in a `chore:` commit, inbound's `@version` will NOT be bumped by RP. The published inbound tarball will still carry `== 1.6.2` (the previous `@version`'s compile-time value), even though git shows `== 1.7.0`. The `mailglass_dep/0` function reads a LITERAL string — it is NOT `@version` interpolated — and is only meaningful at publish time with `MIX_PUBLISH=true`. The published package's `mix.exs` must carry the new pin literal.

**Comment in `mailglass_inbound/mix.exs:114-118` explicitly documents this:**
> "Bumping this pin must land as a `fix(inbound):` commit — chore/docs commits do NOT trigger a Release Please inbound bump, which would leave adopters on a stale `== <prev>` pin while core advances."

**The safe sequence for REL-02:**
1. Land `fix(inbound): re-pin {:mailglass, "== 1.7.0"}` on `main` (touches line 127 of `mailglass_inbound/mix.exs`)
2. Push to `main` → triggers RP to create/update the release PR with all three packages bumped
3. The sed step in RP workflow runs again (idempotent — sees pin already == 1.7.0, no-ops or makes it explicit)
4. RP proposes: `mailglass` 1.7.0, `mailglass_admin` 1.7.0, `mailglass_inbound` 1.3.2
5. After RP PR merges → `publish-inbound` runs with `@version "1.3.2"` and `{:mailglass, "== 1.7.0"}` (MIX_PUBLISH=true)

**Expected resulting version:** `mailglass_inbound` `1.3.2` (patch from `fix`). [ASSUMED — depends on no other unaccounted inbound bump commits]

### Q3 — The CHANGELOG (REL-01)

**Per-package CHANGELOGs:** Yes. Each package has its own `CHANGELOG.md` at its root:
- `CHANGELOG.md` (core)
- `mailglass_admin/CHANGELOG.md` (admin)
- `mailglass_inbound/CHANGELOG.md` (inbound)
[VERIFIED: `release-please-config.json` `"changelog-path": "CHANGELOG.md"` per package; `mailglass_inbound-publish-summary.json` stability test asserts `inbound_changelog =~ "## [#{expected_version}]"`]

**What RP generates:** Release Please writes the `## [1.7.0]` heading with bullet entries grouped by `feat:` → "Features" and `fix:` → "Bug Fixes". For a milestone-spanning cut (v1.7–v1.12 work), RP computes the diff from `1.6.2` tag → HEAD so the generated CHANGELOG will be comprehensive — all feat/fix commits since the last tag appear. Docs, chore, test commits are omitted from the CHANGELOG.

**Hand-curation:** None required by the pipeline. The plan may include an optional step to review the RP-generated diff before merging (MAINTAINING.md step 2: "Review the release PR diff before merge. This repo uses a custom mailglass_admin dep-pin sync step, so the generated PR is load-bearing."). A milestone-spanning cut benefits from a quick editorial scan, but the pipeline does not gate on it.

**What the stability contract asserts:** `test/mailglass/stability_contract_test.exs:169` asserts `inbound_changelog =~ "## [#{expected_version}]"` — so the CHANGELOG entry is test-verified at the contract level. [VERIFIED: `stability_contract_test.exs:169`]

### Q4 — Pipeline stall modes and self-heals

Four documented stall modes:

**Stall Mode 1: Anti-recursion — auto-merge GITHUB_TOKEN suppression**
- **What happens:** The RP PR is auto-merged by GitHub-native squash merge (armed by the "Arm auto-merge" step in `release-please.yml:269-283`). The merge push is authored by `GITHUB_TOKEN`, which GitHub's anti-recursion rule suppresses — the `push` event does NOT re-trigger `release-please.yml`. Therefore RP never tags the commit, and `publish-hex.yml`'s `release: published` trigger never fires.
- **Self-healed?** YES, automatically. `release-please.yml` has a `schedule: cron: "17 * * * *"` (hourly) and `workflow_dispatch` trigger. The cron run picks up the merged-but-untagged state and completes the tag + GitHub Release creation, firing the `release: published` fan-out. Self-heal latency: up to 60 minutes. [VERIFIED: `release-please.yml:1-18`, comments at lines 3-17]
- **Recovery if needed immediately:** `workflow_dispatch` on `release-please.yml` (no inputs needed). This runs RP against HEAD, which detects the already-merged release PR and creates the tag/GitHub Release.

**Stall Mode 2: gate-ci-green "no ci.yml run on SHA"**
- **What happens:** The anti-recursion case (bot-merged commit) means the release tag's SHA has zero ci.yml runs. `gate-ci-green` job previously failed with "no ci.yml runs found for SHA X".
- **Self-healed?** YES, fully automated. The `gate-ci-green` job's "Ensure a completed ci.yml run exists on tagged SHA" step detects no run, dispatches `ci.yml` on the tag ref, and waits up to 30 minutes for it to complete. The subsequent "Verify CI is green" step then checks the result. [VERIFIED: `publish-hex.yml:142-189`]
- **Recovery if needed:** The self-heal is automatic. No manual action required unless the dispatched ci.yml itself fails.

**Stall Mode 3: Advisory-lane failures blocking publish**
- **What happens:** A red advisory lane (e.g., `Operator Browser Gate`, `Preview Capture Advisory`) could appear in the ci.yml run that `gate-ci-green` inspects.
- **Self-healed?** YES — advisory lanes do not block. `gate-ci-green` checks `ADVISORY_LANES = ['Operator Browser Gate']` explicitly plus any job matching `/ Advisory \(/.test(jobName)`. Non-advisory failures block; advisory failures emit a warning but allow publish to proceed. [VERIFIED: `publish-hex.yml:196-256`]
- **Known advisory:** `Operator Browser Gate` — already in the explicit ADVISORY_LANES list.

**Stall Mode 4: Racing fan-outs (idempotency)**
- **What happens:** Multiple `release: published` events (from partial state, or a retry) could cause multiple concurrent publish runs.
- **Self-healed?** YES — each publish job has an idempotency guard: `mix hex.info <package> <version>` check before `mix hex.publish`. If already published, the job skips with "already on Hex — skipping publish". [VERIFIED: `publish-hex.yml:291-297, 393-398, 472-479`]
- **Concurrency:** `concurrency: group: publish-hex-${{ github.ref }}` at job level prevents parallel runs on the same ref. [VERIFIED: `publish-hex.yml:37-39`]

**Stall Mode 5: publish-inbound depends on publish-core success**
- **What happens:** `publish-inbound` only runs when `publish-core.result == 'success'` (or in the inbound-only dispatch path). If core publish fails for any reason, inbound and admin are both skipped — preventing a state where inbound/admin are on Hex with a pinned core version not yet live.
- **Self-healed?** NO — manual recovery needed. Use `workflow_dispatch` on `publish-hex.yml` with the core release tag and `package=all`. Never dispatch from `main`.
- **Recovery command:** `gh workflow run publish-hex.yml --ref mailglass-v1.7.0 --field tag=mailglass-v1.7.0 --field dry_run=false --field package=all` [ASSUMED — gh CLI syntax; verify against actual GITHUB_REPOSITORY]

### Q5 — Publish allowlist hygiene

**New files added in v1.12 (Phases 104–107) NOT yet in `.planning/publish/mailglass-files.expected`:**

The `mailglass` package `:files` glob is:
```elixir
~w(lib priv/gettext guides mix.exs LICENSE README.md CHANGELOG.md MAINTAINING.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md)
```
[VERIFIED: `mix.exs:350-352`]

The glob includes `guides` (the full directory) and `lib` (the full directory). All new files in these directories are automatically included in the tarball by the glob. The publish check then diffs the actual tarball file list against the `.planning/publish/mailglass-files.expected` snapshot. Files absent from the snapshot will cause `mix mailglass.publish.check` to flag a discrepancy and block publish.

**Files confirmed absent from `mailglass-files.expected` and `mailglass-publish-summary.json`:**
- `guides/learning-path.md` (added Phase 105)
- `guides/production-go-live-checklist.md` (added Phase 106)
- `guides/errors-and-troubleshooting.md` (added Phase 106)
- `lib/mailglass/installer/doctor.ex` (added Phase 104)
- `lib/mix/tasks/mailglass.doctor.ex` (added Phase 104)
[VERIFIED: checked `mailglass-files.expected` contents against `ls guides/` and `ls lib/mailglass/installer/` and `ls lib/mix/tasks/`]

**Action required:** Run `mix mailglass.publish.check --package mailglass` (from repo root) to regenerate `mailglass-publish-summary.json` and `mailglass-files.expected`. Then review the diff. Commit the updated snapshots as part of the pre-release checklist — before the RP PR is created or as a standalone commit on `main`.

**Note:** `mailglass_admin` and `mailglass_inbound` allowlists do not appear to have new files from v1.12 (admin changes were to existing `lib/mailglass_admin/live/` files, not new files; inbound had no v1.12 additions). Verify by running `mix mailglass.publish.check --package mailglass_admin` and `mix mailglass.publish.check --package mailglass_inbound` for completeness.

### Q6 — Pre-flight green-main requirement

**What gate-ci-green needs:** A completed ci.yml run on the tagged SHA with all required lanes green. [VERIFIED: `publish-hex.yml:115-257`]

**Required lanes (branch-protection context names, from MAINTAINING.md):**
- `Support Contract Core (Elixir 1.18 / OTP 27)`
- `Support Contract Admin (Elixir 1.18 / OTP 27)`
- `Compile No Optional Deps (Elixir 1.18 / OTP 27)`
- `Trust Lane Repo Head (Elixir 1.18 / OTP 27)`
- `Installer Host Smoke`
[VERIFIED: `MAINTAINING.md:154-159`]

**Is main currently green?** The most recent commit is `684ab7bd docs(state): phase 107 complete` — a `.planning/`-only commit. ci.yml has `paths-ignore: [".planning/**", "prompts/**"]` so this commit triggered NO ci.yml run. [VERIFIED: `ci.yml:6-13`]

The last commit that would have triggered ci.yml is `b9bfbfd5 feat(107-01): add focus-management sibling span to inbound_live.ex` — which touches `mailglass_admin/lib/`. Whether that run is green should be confirmed via:
```
gh run list --workflow ci.yml --branch main --limit 5
```

**Pre-release step to force a green run:** The self-heal in `gate-ci-green` covers the anti-recursion case automatically. However, for confidence before triggering the RP PR creation, optionally dispatch ci.yml on main manually:
```
gh workflow run ci.yml --ref main
```
Then confirm all required lanes green before proceeding.

**Note:** `.planning/`-only pushes skip ci.yml entirely. If the last non-docs commit to `lib/` or `guides/` was green, main is publishable. The `gate-ci-green` self-heal handles the rest.

### Q7 — Post-publish smoke (REL-02)

**What `post-publish-smoke.yml` verifies:**
1. `cron-guard` — resolves version from release event / dispatch tag / latest GitHub release; gates on 7-day recency window for scheduled runs
2. `wait-for-index` — polls `mix hex.info mailglass/mailglass_admin/mailglass_inbound` until each version is indexed on Hex.pm (5-minute timeout per package)
3. `wait-for-hexdocs` — polls `https://hexdocs.pm/mailglass/<version>/` until HexDocs builds each package (10-minute timeout per package)
4. `consumer-install` — runs `scripts/consumer_install_smoke.sh` in `DEP_MODE=hex` mode: `phx.new sandbox` → injects `== 1.7.0` deps → `mix deps.get` → `mix mailglass.install` → OPS-01 guard (no hackney/finch in lock) → `mix compile --warnings-as-errors` → boot → `GET /dev/mail/` → 200
5. `published-trust-journey` — runs `mix verify.reference_host.journey` against `reference/host_app` checking Hex-sourced deps; validates trust-runner checkpoint artifact
6. `retracted-check` — confirms none of the three packages carry a "Retired" status on Hex
[VERIFIED: `post-publish-smoke.yml:31-645`]

**The `mix deps.get` Hex-resolution check (REL-02):** The `consumer-install` job's `DEP_MODE=hex` path injects `{:mailglass, "== 1.7.0"}`, `{:mailglass_admin, "== 1.7.0"}`, and optionally `{:mailglass_inbound, "== 1.3.2"}` into a fresh Phoenix app's mix.exs, then runs `mix deps.get`. Successful resolution proves Hex indexes the new versions. [VERIFIED: `scripts/consumer_install_smoke.sh:47-76`]

**Inbound compatibility check in smoke:** The `check-published-inbound-compatibility` step greps `mix hex.info mailglass_inbound 1.3.2` output for `mailglass == 1.7.0`. If the pin matches, `include_inbound=true` and the smoke installs inbound alongside core. If not (e.g., inbound publish was delayed), it skips inbound and only smokes core+admin. [VERIFIED: `post-publish-smoke.yml:341-362`]

**Known swoosh hackney false-positive (issue #32):** Issue #32 (now CLOSED) was the `post-publish-smoke failure tracker` issue — the smoke was failing on `swoosh 1.26.0` / hackney interaction in the consumer-install OPS-01 guard. The issue is CLOSED (all 33 comments resolved). The current `scripts/consumer_install_smoke.sh` OPS-01 guard checks for `hackney` or `finch` in `mix.lock`, which was the symptom. This is now resolved in the pipeline and does not apply to fresh 1.7.0 installs.

**Distinguishing real failure from noise:** The OPS-01 guard (`config/runtime.exs` must have `config :swoosh, :api_client, false` and must NOT have `Swoosh.ApiClient.Finch` uncommented, and `mix.lock` must have no hackney/finch) is the specific check. If the smoke fails on the OPS-01 guard and shows hackney in the lock, it is a real installer regression. If it fails on a network timeout (Hex not yet indexed), that is transient — retry.

**Fallback dispatch:** If smoke does not fan out automatically, use `workflow_dispatch` on `post-publish-smoke.yml` with `inputs.tag=mailglass-v1.7.0`. The 60-minute revert window (Retract Decision Tree rule 4) must be considered when timing the manual smoke. [VERIFIED: `MAINTAINING.md:308-340`]

### Q8 — Reference baseline coupling

**Current pins in reference baselines:**
- `reference/host_app/mix.exs:32-34`: `{:mailglass, "~> 1.4"}`, `{:mailglass_admin, "~> 1.4"}`, `{:mailglass_inbound, "~> 1.1"}`
- `reference/demo_app/mix.exs:45,50,56`: same `~> 1.4` / `~> 1.1` pattern
[VERIFIED: reading both files]

**The coordinated 5-file change (from project memory):** Bumping reference baselines requires: 2 `mix.exs` + 2 `mix.lock` + `scripts/check_clean_baseline_hex_only.sh` + `test/mailglass/stability_contract_test.exs` — a non-trivial coordinated change that also involves regenerating `mix.lock` files.

**The Trust Lane Repo Head lane runs against reference/host_app with the current Hex-pinned versions.** After a 1.7.0 publish, `~> 1.4` will still resolve (because `~> 1.4` allows any `1.x` where `x >= 4`). So the baseline will continue to work correctly without any pin-bump — `~> 1.4` includes `1.7.0`.

**Recommendation: DEFER baseline pin-bump.** The `~> 1.4` pins in reference baselines already satisfy `1.7.0` (semantic minor-only floor, not upper-bounded). Bumping to `~> 1.7` is cosmetic and adds coordination overhead with no behavioral change. The Trust Lane will pass without it. Defer until a genuine breaking floor change requires it (e.g., a `2.0.0` major release).

**Rationale:** The post-publish-smoke's `published-trust-journey` step runs `check_clean_baseline_hex_only.sh` which verifies that reference/host_app resolves mailglass from Hex, not from a local path dep. With `~> 1.4` and mailglass 1.7.0 on Hex, this check will succeed. [VERIFIED: `post-publish-smoke.yml:430-432`, `check_clean_baseline_hex_only.sh`]

### Q9 — Milestone closeout

**What the milestone audit step requires:**

The STATE.md (line 301 session continuity) documents the prior v1.11 milestone archive pattern:
> "Archived `milestones/v1.11-ROADMAP.md` + `v1.11-REQUIREMENTS.md` + `v1.11-MILESTONE-AUDIT.md`; MILESTONES.md/PROJECT.md/ROADMAP.md/RETROSPECTIVE.md evolved; `REQUIREMENTS.md` removed (fresh for next milestone); tagged `v1.12`."

**gsd-sdk `milestone.complete` count-inflation gotcha (from project memory):** The CLI counts ALL `.planning/phases/` directories including leftover backlog phases (`999.1`, `999.2`). This inflates phase/plan/task stats. The correction: manually count only the true v1.12 scope (Phases 104–108, 5 phases, ~12 plans) and write the corrected numbers directly to `MILESTONES.md` and `STATE.md`. Run `/gsd-cleanup` separately if name-collision risk appears but do NOT let the CLI numbers drive the milestone record.

**True v1.12 scope for the audit:**
- 5 phases (104–108)
- 13 requirements (INSTALL-01..04, DOCS-01..04, OPS-01/02, A11Y-01, REL-01/02)
- Phases 104–107 all complete; Phase 108 is the release

**Artifacts to archive/evolve:**
1. Create `.planning/milestones/v1.12-ROADMAP.md` — copy of current `ROADMAP.md`
2. Create `.planning/milestones/v1.12-REQUIREMENTS.md` — copy of current `REQUIREMENTS.md`
3. Create `.planning/milestones/v1.12-MILESTONE-AUDIT.md` — per-requirement pass/fail matrix
4. Update `MILESTONES.md` — add v1.12 row with true scope stats
5. Update `.planning/PROJECT.md` — advance current milestone notation
6. Update `.planning/ROADMAP.md` — clear v1.12 phases, add v1.12 to history section
7. Remove `.planning/REQUIREMENTS.md` (or replace with stub for next milestone)
8. Update `RETROSPECTIVE.md` — brief v1.12 retrospective
9. Tag `v1.12` in git (`git tag v1.12 && git push origin v1.12`)

**Note on the `guard-release-trigger` follow-up (from REQUIREMENTS.md "Future Requirements"):**
> "Register `guard-release-trigger` as a required branch-protection check once a PR has exercised it (carried v1.10 follow-up; naturally exercised by the REL-01 release PR)."
The release PR will exercise `guard-release-trigger.yml`. After the PR merges successfully, registering it as a required branch-protection check is a low-effort follow-up — add to the milestone closeout checklist.

### Q10 — Ordering / dependency graph

**Recommended ceremony order:**

```
WAVE 0 — Pre-flight (before any RP trigger)
  [0.1] git pull origin main; confirm clean worktree
  [0.2] gh run list --workflow ci.yml --branch main --limit 5 → confirm last non-docs CI run is green
  [0.3] mix mailglass.publish.check --package mailglass → update mailglass-files.expected + mailglass-publish-summary.json
  [0.4] mix mailglass.publish.check --package mailglass_admin → verify no drift
  [0.5] mix mailglass.publish.check --package mailglass_inbound → verify no drift
  [0.6] Commit updated publish-summary artifacts: "chore: refresh publish allowlist snapshots for v1.7.0 release"
        *** chore: commits do NOT trigger RP bump ***

WAVE 1 — Land the inbound re-pin (MUST precede RP PR creation)
  [1.1] Edit mailglass_inbound/mix.exs line 127: {mailglass, "== 1.6.2"} → {mailglass, "== 1.7.0"}
  [1.2] Commit: "fix(inbound): re-pin {:mailglass, \"== 1.7.0\"} for core 1.7.0 linked release (REL-02)"
  [1.3] git push origin main → triggers RP to create/update the release PR
  [1.4] Wait for RP to create the release PR (~2 min for the action to run)

WAVE 2 — Monitor and merge the Release Please PR
  [2.1] Review the RP PR diff:
        - mailglass @version "1.6.2" → "1.7.0"
        - mailglass_admin @version "1.6.2" → "1.7.0"
        - mailglass_inbound @version "1.3.1" → "1.3.2"
        - CHANGELOG.md entries for all three packages
        - sed sync step ran: mailglass_admin/mix.exs + mailglass_inbound/mix.exs pins → "== 1.7.0"
        - README pins updated to ~> 1.7 (core/admin), ~> 1.3 (inbound)
        - .planning/publish/mailglass_inbound-publish-summary.json version fields updated
  [2.2] Confirm auto-merge is armed (release-please.yml arms it automatically)
  [2.3] Wait for required CI checks to go green on the RP branch (auto-merge fires on green)
  [2.4] Observe merge → monitor anti-recursion recovery: cron runs within ~60 min to tag + fire release: published
        OR: immediately run `gh workflow run release-please.yml` for instant recovery

*** IRREVERSIBLE BOUNDARY: after 2.4, Hex publish begins ***

WAVE 3 — Monitor publish fan-out
  [3.1] Watch publish-hex.yml run triggered by release: published event
  [3.2] Confirm prepublish-summary job passes (allowlist checks)
  [3.3] Confirm gate-ci-green passes (may self-dispatch ci.yml if needed; waits up to 30 min)
  [3.4] Confirm publish-core completes (mailglass 1.7.0 on Hex)
  [3.5] Confirm publish-inbound completes (mailglass_inbound 1.3.2 on Hex, dep {mailglass, "== 1.7.0"})
  [3.6] Confirm publish-admin completes (mailglass_admin 1.7.0 on Hex, dep {mailglass, "== 1.7.0"})
  [3.7] Verify Hex URLs live: hexdocs.pm/mailglass/1.7.0 + hexdocs.pm/mailglass_admin/1.7.0 + hexdocs.pm/mailglass_inbound/1.3.2

*** 60-MINUTE REVERT WINDOW STARTS at [3.4] ***

WAVE 4 — 60-minute window manual smoke + Hex resolution
  [4.1] Run consumer smoke manually (60-min window; pipeline smoke runs post-HexDocs build):
        VERSION=1.7.0 DEP_MODE=hex WORK_DIR=$(mktemp -d) INCLUDE_INBOUND=true VERSION_INBOUND=1.3.2 bash scripts/consumer_install_smoke.sh
  [4.2] Confirm: mix deps.get resolves {mailglass, "~> 1.7"} → 1.7.0 and {mailglass_inbound, "~> 1.3"} → 1.3.2
  [4.3] 60-min decision: smoke green → proceed; smoke fails → evaluate Retract Decision Tree (MAINTAINING.md)

WAVE 5 — Post-publish smoke + verification (automated)
  [5.1] Monitor post-publish-smoke.yml fan-out (triggered automatically by release: published)
  [5.2] If smoke does not fan out: gh workflow run post-publish-smoke.yml --field tag=mailglass-v1.7.0
  [5.3] Confirm all smoke jobs pass (wait-for-index, wait-for-hexdocs, consumer-install, published-trust-journey, retracted-check)
  [5.4] Confirm guard-release-trigger exercised by the RP PR → register it as required branch-protection check (follow-up)

WAVE 6 — Milestone audit/archive
  [6.1] Run mix verify.stability_contract → confirm all required checks pass on v1.7.0 codebase
  [6.2] Create .planning/milestones/v1.12-ROADMAP.md (archive copy)
  [6.3] Create .planning/milestones/v1.12-REQUIREMENTS.md (archive copy)
  [6.4] Create .planning/milestones/v1.12-MILESTONE-AUDIT.md (per-req pass/fail, scope stats)
  [6.5] Update MILESTONES.md — add v1.12 row with CORRECTED counts (5 phases, 13 reqs; do NOT use gsd-sdk milestone.complete raw counts)
  [6.6] Update .planning/PROJECT.md — advance milestone notation
  [6.7] Update .planning/ROADMAP.md — move v1.12 phases to history
  [6.8] Update RETROSPECTIVE.md
  [6.9] git tag v1.12 && git push origin v1.12
  [6.10] Commit state/docs artifacts: "docs(state): v1.12 complete — 1.7.0/1.7.0/1.3.2 on Hex"
```

**Irreversible steps:**
- Step 3.4 (`publish-core` completes): After `mailglass 1.7.0` is on Hex and 60 minutes pass, it cannot be unpublished. Only retire-then-patch or retire-only remain as remediation options.
- Steps 3.5 and 3.6: Same 60-minute window applies to admin and inbound.
- The 60-minute window is per-publish, not global — core publish starts the window for core; inbound/admin follow shortly after.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version bump computation | Manual version editing | Release Please | RP reads commit history; hand-editing `.release-please-manifest.json` is explicitly documented as wrong (MAINTAINING.md: "Do not hand-edit") |
| Publish ordering guarantee | Custom publish script | `publish-hex.yml` fan-out | Core-before-inbound-before-admin ordering is enforced by `needs:` chains with idempotency |
| Anti-recursion recovery | Sleep-and-retry loop | `workflow_dispatch` on `release-please.yml` or the hourly cron self-heal | Built into the pipeline |
| Hex indexing wait | Ad-hoc polling | `publish-core`'s "Wait for Hex.pm to index" step (built in) + `wait-for-index` smoke job | Handles the 5-minute indexing lag automatically |
| Publish allowlist update | Hand-editing files.expected | `mix mailglass.publish.check` | The task regenerates the snapshot; hand-editing is error-prone and misses tarball_size updates |

---

## Common Pitfalls

### Pitfall 1: Skipping the `fix(inbound):` commit
**What goes wrong:** The RP PR only bumps core+admin. Inbound stays at `1.3.1` on Hex. The sed step updates `mailglass_inbound/mix.exs` on the RP branch, but since inbound is not in the linked-versions group and has no bump commit, its `@version` stays `1.3.1`. Adopters on core 1.7.0 who try to add `mailglass_inbound` hit a dependency resolution failure because the published `1.3.1` carries `{:mailglass, "== 1.6.2"}`.
**How to avoid:** Land `fix(inbound):` commit on `main` BEFORE the RP action runs. Verify the RP PR shows three package bumps.
**Warning signs:** RP PR shows only `mailglass` and `mailglass_admin` in the version table, not `mailglass_inbound`.

### Pitfall 2: Stale publish allowlist causes `prepublish-summary` failure
**What goes wrong:** The `prepublish-summary` job runs `mix mailglass.publish.check`. It diffs the actual tarball against `mailglass-files.expected`. The three new guides (`learning-path.md`, `production-go-live-checklist.md`, `errors-and-troubleshooting.md`) and two new lib files (`installer/doctor.ex`, `mix/tasks/mailglass.doctor.ex`) are in the tarball (covered by the `guides` and `lib` glob) but absent from the snapshot. The task exits non-zero, blocking publish.
**How to avoid:** Run `mix mailglass.publish.check --package mailglass` before the release and commit the updated snapshot in Wave 0.
**Warning signs:** `prepublish-summary` job logs show "unexpected files in tarball" or "files.expected diff".

### Pitfall 3: Pinning the inbound dep before the RP PR with a non-bump commit type
**What goes wrong:** Committing `{:mailglass, "== 1.7.0"}` in a `chore:` or `docs:` commit on `main` updates git but does NOT trigger an inbound Release Please bump. The RP PR then contains inbound's CHANGELOG but not a `@version` bump, and the published inbound tarball carries the `== 1.7.0` pin but at version `1.3.1`. However, the `stability_contract_test.exs` assertion at line 154-157 would catch this at CI time before it ships.
**How to avoid:** Use `fix(inbound):` as the commit type. This is the ONLY bump-triggering commit type that is appropriate here (no feat-level change is being made to inbound).
**Warning signs:** ci.yml `Support Contract Core` run fails with "inbound publish pin in mailglass_dep/0 does not match core @version".

### Pitfall 4: Triggering ci.yml with `mix compile --no-optional-deps --force` during pre-flight
**What goes wrong (from project memory):** Running `mix compile --no-optional-deps --force` on the shared main `_build` during the ceremony pollutes the build artifacts; the `/inbound` route is compile-time-gated and order-sensitive. Don't do this during the ceremony.
**How to avoid:** Use targeted `mix mailglass.publish.check` (which is a task-level run, not a full compile of the optional-deps-free tree) and let CI handle the compile checks.

### Pitfall 5: Using gsd-sdk `milestone.complete` raw counts for the audit
**What goes wrong:** The CLI counts ALL `.planning/phases/` directories including leftover `999.1` and `999.2` backlog dirs, inflating phase/plan/task stats. The written record becomes inaccurate.
**How to avoid:** Manually count true v1.12 scope (5 phases, 13 requirements) and write corrected numbers directly to MILESTONES.md.

### Pitfall 6: Dispatching publish-hex.yml from `main` in a fallback
**What goes wrong:** Dispatching `publish-hex.yml` without a tag uses `main` HEAD, which may not match the reviewed release commit. Version resolution in the workflow is tag-based.
**How to avoid:** Always dispatch fallback with the explicit release tag: `--ref mailglass-v1.7.0 --field tag=mailglass-v1.7.0`. [VERIFIED: `publish-hex.yml:14-17`, MAINTAINING.md step 3 fallback note]

---

## Validation Architecture

Phase 108 is a release ceremony. "Validation" here means verifiable release-gate checks, not ExUnit tests. Each check has a binary pass/fail and a specific command.

### Release Gate Checks (in order)

| Gate | Phase | Command / Verification | Pass Condition |
|------|-------|------------------------|----------------|
| REG-01: main CI green | Wave 0 | `gh run list --workflow ci.yml --branch main --limit 3` | All required lanes green on last non-docs commit |
| REG-02: allowlist clean (core) | Wave 0 | `mix mailglass.publish.check --package mailglass` | Exits 0; no unexpected-files error |
| REG-03: allowlist clean (admin) | Wave 0 | `mix mailglass.publish.check --package mailglass_admin` | Exits 0 |
| REG-04: allowlist clean (inbound) | Wave 0 | `mix mailglass.publish.check --package mailglass_inbound` | Exits 0 |
| REG-05: inbound re-pin committed | Wave 1 | `grep '== 1.7.0' mailglass_inbound/mix.exs` | Literal `{:mailglass, "== 1.7.0"}` present |
| REG-06: RP PR proposes 3 packages | Wave 2 | Review RP PR diff | mailglass 1.7.0, mailglass_admin 1.7.0, mailglass_inbound 1.3.2 all shown |
| REG-07: sed sync present in PR | Wave 2 | Review RP PR diff | `mailglass_admin/mix.exs` and `mailglass_inbound/mix.exs` show `== 1.7.0` |
| REG-08: core on Hex | Wave 3 | `mix hex.info mailglass 1.7.0` | Output contains "Released:" |
| REG-09: inbound on Hex with correct pin | Wave 3 | `mix hex.info mailglass_inbound 1.3.2` | Output contains `mailglass == 1.7.0` |
| REG-10: admin on Hex | Wave 3 | `mix hex.info mailglass_admin 1.7.0` | Output contains "Released:" |
| REG-11: consumer smoke green | Wave 4 | `DEP_MODE=hex VERSION=1.7.0 ... bash scripts/consumer_install_smoke.sh` | Exits 0; GET /dev/mail/ → 200 |
| REG-12: post-publish-smoke green | Wave 5 | Monitor `post-publish-smoke.yml` GitHub Actions run | All jobs pass (wait-for-index, consumer-install, published-trust-journey, retracted-check) |
| REG-13: milestone audit written | Wave 6 | `ls .planning/milestones/v1.12-*` | Three files exist (ROADMAP, REQUIREMENTS, MILESTONE-AUDIT) |
| REG-14: v1.12 tag created | Wave 6 | `git tag -l v1.12` | Tag exists on origin |

### Per-task sampling
- **Per-wave commit:** Run the gate checks listed for that wave
- **Phase gate:** REG-08 through REG-12 all green before closing Phase 108

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual inbound pin bump (sed on main) | `fix(inbound):` commit + RP workflow sed step on PR branch | Phase 93 / v1.10 | Pin update is now test-verified and ceremony-documented |
| Prepare-only milestones (v1.7, v1.11) | D-28: actually cut | v1.12 scope lock | First real multi-milestone-spanning release cut since 1.6.2 |
| Anti-recursion stall required manual tag | Hourly cron + `gate-ci-green` self-dispatch self-heal | Phase 13 release engineering | Stall mode is now fully automated |
| Allowlist maintained by hand | `mix mailglass.publish.check` regenerates snapshot | Phase 8 | Tarball audit is automated; snapshot is committed proof |
| Reference baseline `~> 1.4` pins (current) | `~> 1.4` still resolves 1.7.0 | — | No bump needed; defer cosmetic update |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mailglass_inbound` will bump to `1.3.2` (patch) from the `fix(inbound):` commit | Q1, Q2 | If other feat-level inbound commits are discovered, it might bump to `1.4.0` instead — still correct, just a different version number |
| A2 | Issue #32 (swoosh/hackney false-positive in post-publish-smoke) is fully resolved | Q7 | If the issue resurfaces on 1.7.0, distinguish by checking the OPS-01 guard output; it's a known footgun not a new regression |
| A3 | `reference/host_app` `~> 1.4` constraint satisfies `1.7.0` (no upper bound) | Q8 | If Hex applies a different constraint interpretation, the Trust Lane might fail — unlikely given standard SemVer semantics |

---

## Open Questions

1. **Is there an open Release Please PR already?**
   - What we know: The last RP trigger was the `fix(inbound):` commit at `8dfc26ab` ("fix(inbound): release the mailglass == 1.6.1 pin") — but that was for the 1.3.1 ceremony. The current HEAD has no RP PR open (the 1.6.2 ceremony is closed).
   - What's unclear: Whether the RP action already ran on the Phase 107 `feat(107-01):` commits and created a draft PR. Check with: `gh pr list --head release-please--branches--main --state open`
   - Recommendation: Check before running Wave 1. If a PR already exists, the `fix(inbound):` commit on `main` will trigger the RP sync step to update the existing PR (idempotent).

2. **Should the admin `mailglass_inbound_dep()` floating pin (`~> 1.1`) be updated to `~> 1.3`?**
   - What we know: `mailglass_admin/mix.exs:164-169` has `{:mailglass_inbound, "~> 1.1", optional: true}` — deliberately floating (not `==`), deliberately absent from the PINS array. The `1.1` lower floor satisfies `1.3.x` so no resolution failure.
   - What's unclear: Whether the floor should be advanced for documentation accuracy.
   - Recommendation: This is cosmetic at 1.7.0. Leave at `~> 1.1` unless a specific inbound API that only exists in `>= 1.3` is being depended on. [VERIFIED: `mailglass_admin/mix.exs:153-170` — "deliberately ABSENT from the release-please PINS array"]

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix hex.publish` | Publishing to Hex | ✓ | Bundled with Elixir 1.18 | — |
| `HEX_API_KEY` secret | publish-hex.yml | ✓ (from project memory) | — | — |
| `RELEASE_PLEASE_PAT` secret | release-please.yml | ✓ (from existing releases) | — | — |
| GitHub Actions | Full ceremony | ✓ | — | Manual `mix hex.publish --yes` from local (last resort) |
| Postgres 16 | prepublish-summary job | ✓ (GitHub Actions service) | 16-alpine | — |

---

## Project Constraints (from CLAUDE.md)

- **Hex publish only from protected ref, via `hex-publish` GitHub Environment.** `HEX_API_KEY` must not be visible to PR jobs. The ceremony uses the existing `hex-publish` environment in publish-hex.yml (no required reviewers — hands-free). [VERIFIED: `CLAUDE.md` "Commit & Branch Conventions"]
- **Releases are fully hands-free** after green CI: RP auto-merges → `gate-ci-green` → publish fan-out. No human approval gate (by design, intentionally documented in MAINTAINING.md "Bus Factor & Continuity").
- **All third-party GitHub Actions pinned to commit SHA.** Already satisfied in all workflows (verified: `release-please.yml` uses `googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7`). Do not bump action versions during this ceremony.
- **Conventional Commits enforced.** The `fix(inbound):` commit type for the re-pin is correct and must not be a `chore:` (which would not trigger RP).
- **Do NOT hand-edit `.release-please-manifest.json` to force a version.** MAINTAINING.md step 2 explicitly prohibits this.
- **Inbound exact-pin `{:mailglass, "== <version>"}` in `mailglass_dep/0`.** Not `@version` interpolation — a literal that the sed step rewrites.
- **`docs(state):` commit type for STATE.md updates.** CI path filters skip them (no ci.yml trigger on `.planning/**`).

---

## Sources

### Primary (HIGH confidence — verified from live codebase)
- `release-please-config.json` — linked-versions config, exclude-paths, inbound NOT in linked group
- `.release-please-manifest.json` — current versions 1.6.2 / 1.6.2 / 1.3.1
- `.github/workflows/release-please.yml` — full sed sync step (lines 139-263), auto-merge arming (lines 269-283), cron self-heal (lines 19-21)
- `.github/workflows/publish-hex.yml` — gate-ci-green self-dispatch (lines 142-189), advisory-lane filter (lines 196-256), publish job ordering (publish-core → publish-inbound → publish-admin), idempotency guards
- `.github/workflows/ci.yml` — paths-ignore `.planning/**` (lines 6-13), required lane names
- `.github/workflows/guard-release-trigger.yml` — RELH-01 guard, NOT yet a required check
- `.github/workflows/post-publish-smoke.yml` — full smoke job chain; inbound compatibility check
- `mailglass_inbound/mix.exs:114-131` — mailglass_dep/0, the exact pin literal, comment block documenting the fix(inbound): requirement
- `mailglass_admin/mix.exs:140-169` — mailglass_dep/0 and mailglass_inbound_dep/0
- `mix.exs:350-352` — `:files` glob (includes `guides` directory)
- `.planning/publish/mailglass-files.expected` — confirmed missing new v1.12 guides and installer/doctor modules
- `test/mailglass/stability_contract_test.exs:77-179` — sibling-package release contract assertions
- `MAINTAINING.md` — Release Runbook (5 steps), Retract Decision Tree, required-vs-advisory lanes
- `scripts/consumer_install_smoke.sh` — DEP_MODE=hex path; OPS-01 guard
- `reference/host_app/mix.exs:32-34` — `~> 1.4` pins

### Secondary (MEDIUM confidence)
- `git log` output — bump-triggering commits by package path since 1.6.2
- `gh issue view 32` — post-publish-smoke failure tracker issue CLOSED (no active hackney false-positive)

---

## Metadata

**Confidence breakdown:**
- Release pipeline mechanics: HIGH — verified directly from workflow files
- Bump derivation: HIGH — verified from config + commit log
- Inbound re-pin sequence: HIGH — verified from mix.exs comments and stability_contract_test
- Publish allowlist gap: HIGH — confirmed by direct file comparison
- Milestone closeout: HIGH — verified from STATE.md v1.11 precedent
- Reference baseline scope recommendation: HIGH — verified both mix.exs files and check_clean_baseline_hex_only.sh

**Research date:** 2026-06-17
**Valid until:** The ceremony should execute within days; pipeline mechanics are stable.

---

## RESEARCH COMPLETE

Phase 108 research complete. All ten questions answered from live workflow files and codebase inspection. The plan can now specify a precise, gotcha-aware ceremony: land `fix(inbound):`, refresh allowlist snapshots, let RP PR auto-merge, monitor the hands-free fan-out, run the 60-minute consumer smoke, confirm post-publish-smoke green, then audit/archive the v1.12 milestone.
