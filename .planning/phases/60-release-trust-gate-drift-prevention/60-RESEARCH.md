# Phase 60: Release Trust Gate + Drift Prevention - Research

**Researched:** 2026-05-29
**Domain:** CI/release/ops plumbing (GitHub Actions YAML, shell scripts, Mix dep pins, maintainer docs) — NOT product Elixir source
**Confidence:** HIGH (everything verified against current files in this session)

## Summary

Phase 60 wires three already-built primitives together and closes a docs/reliability gap. Nothing
here is new product code: the deliverables are (1) a `trust_lane_clean_baseline` job added to
`ci.yml`, (2) the same trust journey attached to `post-publish-smoke.yml` for published-version
evidence plus a live hackney-regression guard in its `consumer-install` job, (3) a `~> 1.3` dep
bump on `reference/host_app`, and (4) `MAINTAINING.md` edits that make green trust evidence a
release gate and delete stale "approve the hex-publish deployment" instructions that describe a
gate which does not exist.

The single most important fact for the planner: **the trust runner lives in the root repo's `dev/`
tree and is never shipped to Hex.** [VERIFIED: `mix.exs:96-99`, `dev/mix/tasks/mailglass.trust.run.ex`]
Both Hex-baseline lanes therefore run the **repo-root runner as orchestrator** (`mix verify.reference_host.journey --host-root reference/host_app`, or the equivalent `mix mailglass.trust.run --host-root reference/host_app`) from the repo root, where `dev/` is compiled. They do NOT call a Mix task from inside `reference/host_app` — that path is impossible (aliases/tasks are not inherited from deps) and was the exact Phase 59 deferral cause. The Phase 59 pending-todo's "call the published Mix task directly / `working-directory: reference/host_app`" steps are **superseded** by D-01/D-03.

The enabling preconditions are all met as of today: `mailglass 1.3.0`, `mailglass_admin 1.3.0`,
`mailglass_inbound 0.3.0` are live on Hex [VERIFIED: hex.pm API], and the reference host already
resolves all three siblings via `:hex` source (currently pinned `~> 1.2`/`~> 1.2`/`~> 0.2`)
[VERIFIED: `reference/host_app/mix.lock:20-22`]. The bump is a one-line-per-dep edit + `mix.lock`
refresh — no path-dep migration is involved.

**Primary recommendation:** Mirror the existing `trust_lane_repo_head` job verbatim for the
clean-baseline lane (same prep, same validator, same artifact conventions); reuse
`post-publish-smoke.yml`'s existing version-resolution/wait lifecycle for EVID-03; and treat
`MAINTAINING.md` as the OPS-02 surface with one machine-checkable doc-contract test recommended.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Clean-baseline trust lane (EVID-02) | CI (`ci.yml`, PR/push) | publish gate (`gate-ci-green`) | Runs on PR; auto-gates publish because `gate-ci-green` inspects every non-advisory `ci.yml` job |
| Published-version trust journey (EVID-03) | Release/cron CI (`post-publish-smoke.yml`) | issue tracker (`notify-on-failure`) | Post-publish sentinel; publish is hands-free with no pre-publish gate, so evidence is collected after fan-out |
| hackney regression root-cause fix (OPS-01) | Product source (`lib/mailglass/installer/templates.ex`) — already shipped | — | The installer template emits `config :swoosh, :api_client, false`; this is the fix, kept under unit guard |
| hackney live regression guard (OPS-01) | Release/cron CI (`post-publish-smoke.yml` `consumer-install`) | unit test | Grep-on-compile/runtime guard on a fresh PUBLISHED host install |
| Release-gate doc requirement (OPS-02) | Maintainer docs (`MAINTAINING.md`) | optional doc-contract test | Human-facing release runbook; the only enforcement is an optional ExUnit string-assert |
| Dep pin bump (enabler) | Reference host (`reference/host_app/mix.exs` + `mix.lock`) | — | Makes both Hex-baseline lanes resolve the newly-shipped siblings |

## Standard Stack

This phase introduces **no new packages**. The "stack" is the existing CI/release toolchain.

### Core (already present, reused as-is)
| Asset | Location | Purpose | Why Standard |
|-------|----------|---------|--------------|
| Trust runner Mix task | `dev/mix/tasks/mailglass.trust.run.ex` | Orchestrates the 5-stage journey; emits checkpoint JSON | Canonical Phase 57 entrypoint; dev-only, repo-root orchestrator |
| `verify.reference_host.journey` alias | `mix.exs:229-231` (`["mailglass.trust.run"]`) | Semantic alias; passes `--host-root` through to the task | Single-task alias → trailing argv flows to the task |
| Hex-source guard | `scripts/check_clean_baseline_hex_only.sh` | Asserts all 3 siblings resolved via `:hex` in `mix.lock` | Shipped Phase 59 P01, shellcheck-clean, env-passed (injection-safe) |
| Checkpoint validator | `scripts/check_trust_runner_checkpoint.sh` | Validates schema/boundary/stage-order/SHA of checkpoint JSON | Shipped; reused by both lanes |
| Repo-head trust lane (template) | `ci.yml:806-878` (`trust_lane_repo_head`) | The job to mirror for clean-baseline | 4-of-4 convergent pattern; required check |
| Post-publish lifecycle | `post-publish-smoke.yml` | Version resolution, Hex-index/HexDocs waits, consumer host gen, retracted-check, issue tracker | EVID-03 extends this rather than rebuilding |
| Installer template | `lib/mailglass/installer/templates.ex:144-156` | Emits `config :swoosh, :api_client, false` into `runtime.exs` | The OPS-01 root-cause fix (already shipped) |
| Branch-protection script | `scripts/setup_branch_protection.sh:17-22` | `REQUIRED_CHECKS` source of truth | Do NOT add clean-baseline here (D-04) |
| Drift-contract test | `test/scripts/required_checks_test.exs` | Asserts array↔heredoc sync + Phase-27 lock entries | Name-agnostic; clean-baseline absence is compatible |
| Unit smoke guard | `test/mailglass/install/install_first_preview_smoke_test.exs` | REL-17 sentinel + workflow-string asserts | OPS-01 unit guard + doc-contract-test precedent |

**Installation:** None. No `npm`/`mix`/`pip` package added.

### Dep pin bump (the one enabling edit)
`reference/host_app/mix.exs:32-34` — currently:
```elixir
{:mailglass, "~> 1.2"},
{:mailglass_admin, "~> 1.2"},
{:mailglass_inbound, "~> 0.2"}
```
D-02 target (now live on Hex):
```elixir
{:mailglass, "~> 1.3"},
{:mailglass_admin, "~> 1.3"},
{:mailglass_inbound, "~> 0.3"}
```
Then refresh `reference/host_app/mix.lock` (`mix deps.update mailglass mailglass_admin mailglass_inbound` or `mix deps.get` after editing pins). **Verified-current Hex versions** [VERIFIED: hex.pm API, 2026-05-29]:
- `mailglass` → `1.3.0` (also 1.2.0, 1.0.0, 0.3.2, 0.1.1, 0.1.0)
- `mailglass_admin` → `1.3.0`
- `mailglass_inbound` → `0.3.0`

Both `mix.exs` and `mix.lock` for the reference host are git-tracked [VERIFIED: `git ls-files`].

## Package Legitimacy Audit

> Not applicable — Phase 60 installs **no external packages**. The only dependency change is a
> version-pin bump on three **first-party sibling packages already published by this repo** to its
> own Hex account (`mailglass`, `mailglass_admin`, `mailglass_inbound`), confirmed live at the
> target versions via the hex.pm API. No slopcheck/registry-confusion risk exists for self-published
> siblings whose source is this monorepo.

## Architecture Patterns

### System Architecture Diagram (data/trigger flow)

```
                    ┌──────────────────────────────────────────────┐
   PR / push  ─────▶│ ci.yml                                       │
                    │  trust_lane_repo_head  (EXISTS, required)    │
                    │  trust_lane_clean_baseline (NEW, D-03)       │──┐
                    │    cd reference/host_app && mix deps.get      │  │ all non-advisory
                    │      && mix compile   (Hex-sourced dev build) │  │ ci.yml jobs feed
                    │    bash check_clean_baseline_hex_only.sh      │  │ the publish gate
                    │    mix verify.reference_host.journey          │  │
                    │      --host-root reference/host_app  (REPO ROOT)  │
                    │    bash check_trust_runner_checkpoint.sh      │  │
                    │    upload trust-runner-clean-baseline-<run_id>│  │
                    └──────────────────────────────────────────────┘  │
                                                                       ▼
   release: published ─┐                              ┌────────────────────────────┐
   workflow_dispatch ──┼─▶ publish-hex.yml            │ gate-ci-green               │
   (release-please     │     gate-ci-green ───────────│ inspects ALL ci.yml jobs;   │
    auto-merges on     │     publish-core/admin/inbound│ blocks publish if any       │
    green, hands-free) │   (hands-free, no env gate)   │ non-advisory job failed     │
                       │                               └────────────────────────────┘
                       │
   release: published ─┤
   schedule (cron 12:00)┼─▶ post-publish-smoke.yml
   workflow_dispatch ──┘     cron-guard (resolves published version, 7-day window)
                              └▶ wait-for-index ▶ wait-for-hexdocs
                                  └▶ consumer-install  (Phoenix host, == published version)
                                      ├ mix mailglass.install
                                      ├ compile --warnings-as-errors | grep UndefinedFunctionError  (EXISTS)
                                      ├ [NEW D-07] hackney/api_client regression guard
                                      └ boot + curl /dev/mail/
                                  └▶ [NEW D-05] published-version trust journey job
                                      (mirror clean-baseline; --host-root reference/host_app)
                              └▶ retracted-check
                              └▶ notify-on-failure  ──▶ opens/updates issue "publish-smoke failure tracker" (#32)
```

### Recommended file touch map
```
.github/workflows/ci.yml                 # + trust_lane_clean_baseline job
.github/workflows/post-publish-smoke.yml # + published-version trust journey job; + hackney guard in consumer-install
reference/host_app/mix.exs               # bump 3 pins ~>1.2/~>1.2/~>0.2 -> ~>1.3/~>1.3/~>0.3
reference/host_app/mix.lock              # refresh to 1.3.0/1.3.0/0.3.0
MAINTAINING.md                           # OPS-02 gate item + Required Checks reconcile + delete stale approval-gate lines
test/.../<new doc-contract test>.exs     # OPTIONAL (Claude's discretion per D-08)
```

### Pattern 1: Mirror the repo-head trust lane verbatim (clean-baseline, D-03)
**What:** The clean-baseline job is the repo-head job with one extra guard step and Hex-sourced deps.
**When to use:** The `trust_lane_clean_baseline` job and the EVID-03 post-publish job.
**The repo-head template** [VERIFIED: `ci.yml:806-878`]:
```yaml
trust_lane_repo_head:
  name: Trust Lane Repo Head (Elixir 1.18 / OTP 27)
  runs-on: ubuntu-latest
  # NO needs: — runs unconditionally on PR/push (so it can be a required check)
  # NO if: — Pitfall 2 (a skipped required check can false-green)
  services: { postgres: postgres:16-alpine ... }   # full DB service block
  env: { MIX_ENV: test, POSTGRES_HOST: localhost, ... }
  steps:
    - checkout@<sha>
    - erlef/setup-beam@<sha> (1.18 / 27)
    - actions/cache@<sha> (deps)
    - run: mix deps.get
    - "Wait for postgres + create test DB": mix ecto.create -r Mailglass.TestRepo --quiet
    - "Build reference host (dev)":
        working-directory: reference/host_app
        env: { MIX_ENV: dev }
        run: mix deps.get && mix compile          # <-- clean-baseline: Hex deps now resolve 1.3.0
    - "Run reference-host trust journey":
        run: mix verify.reference_host.journey     # repo root; defaults --host-root to reference/host_app
    - "Validate trust checkpoint contract":
        run: bash scripts/check_trust_runner_checkpoint.sh
    - "Print checkpoint SHA": jq into $GITHUB_STEP_SUMMARY
    - actions/upload-artifact@<sha>:
        name: trust-runner-repo-head-${{ github.run_id }}
        if-no-files-found: error
        retention-days: 90
        path: tmp/mailglass_trust_runner/checkpoint.json
```
**Clean-baseline delta:** insert one step after the reference-host build —
`bash scripts/check_clean_baseline_hex_only.sh` run **from `reference/host_app/`** (CWD matters; the
script defaults `LOCK_PATH=mix.lock` relative to CWD) — and rename the artifact to
`trust-runner-clean-baseline-${{ github.run_id }}`. Everything else is identical.

**Important CWD/path facts** [VERIFIED]:
- The runner's checkpoint default is `tmp/mailglass_trust_runner/checkpoint.json` expanded against
  `File.cwd!()` [`mailglass.trust.run.ex:32,50-53`]. Run from **repo root** → checkpoint lands at
  repo-root `tmp/...`, which is exactly the validator's default path. The old todo's
  `reference/host_app/tmp/...` checkpoint path (todo step 3) belongs to the superseded
  `working-directory: reference/host_app` shape and does NOT apply under D-03.
- `--host-root reference/host_app` is the explicit, recommended spelling. The repo-head job omits it
  (relies on the default), but for clarity/parity the clean-baseline + EVID-03 jobs should pass it
  explicitly per D-01/D-03.

### Pattern 2: gate-ci-green auto-gates any new ci.yml job (D-04 mechanism)
**What:** `gate-ci-green` does NOT whitelist required-check names; it fetches **all jobs** of the
latest `ci.yml` run on the tagged SHA and blocks publish if any job whose name does NOT start with
an `ADVISORY_LANES` prefix has a non-success, non-skipped conclusion [VERIFIED: `publish-hex.yml:131-191`].
`ADVISORY_LANES = ['Operator Browser Gate']` [VERIFIED: `publish-hex.yml:139-141`].
**Consequence:** Adding `trust_lane_clean_baseline` to `ci.yml` makes it **publish-gate-only
automatically** — it blocks publish on failure but is NOT a branch-protection required check unless
explicitly added to `REQUIRED_CHECKS`. This is precisely D-04 ("A1 lock") and needs **zero** edits
to `publish-hex.yml` or `setup_branch_protection.sh`. Do NOT add the lane to `REQUIRED_CHECKS`.

### Pattern 3: Live regression guard = grep-on-compile-log (OPS-01, D-07)
**What:** The existing G-1 guard greps the compile log for a failure signature [VERIFIED: `post-publish-smoke.yml:403-411`]:
```yaml
- name: Compile, fail on warnings
  working-directory: ${{ runner.temp }}/sandbox
  run: |
    set -o pipefail
    mix compile --warnings-as-errors 2>&1 | tee compile.log
    if grep -F "UndefinedFunctionError" compile.log; then
      echo "Smoke failed: UndefinedFunctionError detected ..."
      exit 1
    fi
```
**Mirror for hackney (recommended placement — see Common Pitfalls #4):** add a step in
`consumer-install` (after `mix mailglass.install`, alongside the compile grep) that asserts the
generated `config/runtime.exs` set `config :swoosh, :api_client, false` and did NOT pull
hackney/finch into the resolved dep tree. Two complementary, deterministic signals:
- **Generated-config assertion** (matches the unit guard at `install_first_preview_smoke_test.exs:16-20`):
  `grep -F "config :swoosh, :api_client, false" config/runtime.exs` (fail if absent), and
  `! grep -Eq '^\s*config :swoosh, :api_client, Swoosh\.ApiClient\.Finch' config/runtime.exs`.
- **Resolved-dep assertion** (catches a transitive reintroduction the config can't): after
  `mix deps.get`, `! grep -qE '"(hackney|finch)":' mix.lock` on the `--no-mailer` sandbox. (A
  `--no-mailer` Phoenix host has neither in its lock unless mailglass.install reintroduces one.)

### Anti-Patterns to Avoid
- **Calling a Mix task from inside `reference/host_app`** — the runner is not in the published deps;
  the task/alias is not inherited. This is the Phase 59 deferral cause; do not reintroduce it.
- **`working-directory: reference/host_app` for the journey step** — superseded shape (59-02 Task 1
  Edit B). Run the journey from repo root with `--host-root`.
- **Adding `trust_lane_clean_baseline` to `REQUIRED_CHECKS`** — violates D-04; would make PR merges
  depend on a Hex-baseline reference-host build.
- **Adding an `if:` to the new ci.yml job** — a skipped job reports neutral, which `gate-ci-green`
  treats as non-blocking; an unconditional job is the safe form (Pitfall 2 from Phase 59).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hex-source verification | A `grep` on `mix.lock` for `:path` | `scripts/check_clean_baseline_hex_only.sh` (CWD `reference/host_app`) | Already shipped, injection-safe, asserts all 3 siblings positively are `:hex`, not just absence of `:path` |
| Checkpoint validation | Re-implement JSON schema checks in YAML | `scripts/check_trust_runner_checkpoint.sh` | Validates schema/boundary/stage-order/PII-forbidden-keys/deterministic SHA in one place |
| Published-version resolution + Hex/HexDocs waits | New version-discovery logic | `post-publish-smoke.yml` `cron-guard` + `wait-for-index` + `wait-for-hexdocs` | Already handles release/cron/dispatch triggers, semver validation, 7-day window, Hex-presence check |
| Failure notification | New issue-opening action | `post-publish-smoke.yml` `notify-on-failure` | Already opens/updates the `publish-smoke failure tracker` (#32) idempotently |
| Drift detection on required checks | Manual review | `test/scripts/required_checks_test.exs` | Name-agnostic array↔heredoc contract |

**Key insight:** Phase 59 deliberately shipped every reusable building block and deferred only the
wiring. This phase is assembly, not construction. The danger is re-deriving a primitive that already
exists in a subtly-wrong way (e.g., a `:path`-absence grep that misses a `:git` leak).

## Runtime State Inventory

> This phase has a meaningful refactor/migration surface (CI workflows + maintainer docs + dep pins),
> so the inventory below is explicit.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no database, datastore key, or collection name changes in scope. (The trust checkpoint JSON is regenerated each run, not stored.) | None — verified by reading the runner + validator; no persistent state keyed on any renamed string. |
| Live service config (in a UI/DB, not git) | **GitHub branch protection** on `main` is live server-side state set by `scripts/setup_branch_protection.sh`. D-04 means it is NOT touched this phase. **GitHub issue #32** ("publish-smoke failure tracker", OPEN, label `publish-smoke-failed`) is live state. | issue #32: close ONLY after a green post-publish-smoke run with the new guard (D-07) — manual `gh issue close 32`. Branch protection: no change (D-04). |
| OS-registered state | None — no Task Scheduler / pm2 / systemd / launchd registrations involve any phase string. The only scheduled job is `post-publish-smoke.yml`'s `cron: "0 12 * * *"`, defined in-repo. | None — verified by reading the cron trigger; it resolves the latest release at runtime, no embedded version string. |
| Secrets/env vars | `HEX_API_KEY` (hex-publish environment), `BRANCH_PROTECTION_PAT`, `RELEASE_PLEASE_TOKEN`, `GITHUB_TOKEN`. None are renamed or read by new code. | None — the new jobs reuse `secrets.GITHUB_TOKEN` (issues:write already granted in `post-publish-smoke.yml:23-25`). No new secret needed. |
| Build artifacts / installed packages | `reference/host_app/_build/dev/lib/*/ebin` — the sibling beams the runner loads via `Path.expand("../../../reference/host_app/_build/dev/lib/#{app}/ebin", __DIR__)` [VERIFIED: `webhook_operator_proof.ex:160`]. After the `~> 1.3` bump, this build is stale until recompiled. | Both lanes already `cd reference/host_app && mix deps.get && mix compile` (dev) before the journey, repopulating the beams with Hex-sourced 1.3.0 code. No extra step needed; just ensure the bump lands before the journey runs. |

**The canonical question — after every repo file is updated, what runtime state still has old data?**
Only **GitHub issue #32** (live, manual close per D-07) and the live **branch-protection ruleset**
(intentionally untouched per D-04). Everything else is regenerated from source at run time.

## Common Pitfalls

### Pitfall 1: False-green from a skipped or missing job in gate-ci-green
**What goes wrong:** A new `ci.yml` job with an `if:` condition that evaluates false reports `skipped`;
`gate-ci-green` ignores `skipped` jobs, so a lane that "didn't run" silently passes the publish gate.
**Why it happens:** `gate-ci-green` filters `j.conclusion !== 'success' && j.conclusion !== 'skipped'`
[VERIFIED: `publish-hex.yml:175`].
**How to avoid:** Add the `trust_lane_clean_baseline` job with **no `if:`** (mirror `trust_lane_repo_head`,
which has none). It must run on every PR/push so failure → red → publish blocked.
**Warning signs:** The job shows "skipped" in the Actions UI on a normal PR.

### Pitfall 2: Wrong CWD for the Hex-source guard
**What goes wrong:** `scripts/check_clean_baseline_hex_only.sh` defaults `LOCK_PATH=mix.lock` relative
to CWD [VERIFIED: script line 7]. Run from repo root without an arg, it inspects the **root** `mix.lock`
(which has path-sourced siblings during dev) and false-fails or false-passes.
**How to avoid:** Run it **from `reference/host_app/`** (`working-directory: reference/host_app` on
THAT step only — not the journey step), or pass the explicit path
`bash scripts/check_clean_baseline_hex_only.sh reference/host_app/mix.lock` from repo root.
**Warning signs:** The guard reports siblings missing, or reports `:path` for the root build.

### Pitfall 3: Artifact upload conventions drift (Pitfall 6 carried forward)
**What goes wrong:** Omitting `if-no-files-found: error` makes a missing checkpoint a silent green;
omitting `retention-days: 90` or using a glob path produces inconsistent evidence.
**How to avoid:** Copy the repo-head upload block exactly: `if-no-files-found: error`,
`retention-days: 90`, exact `path: tmp/mailglass_trust_runner/checkpoint.json`, name
`trust-runner-clean-baseline-${{ github.run_id }}` (and `trust-runner-published-${{ github.run_id }}`
or similar for EVID-03) [VERIFIED: `ci.yml:872-878`].

### Pitfall 4: hackney guard placed where it can't see the failure
**What goes wrong:** Putting the guard only as a `mix.lock` grep BEFORE `mix mailglass.install` runs
misses a reintroduction the installer causes; putting it only as a runtime-boot check misses a
compile-time pull.
**How to avoid:** Place the config-assertion + lock-assertion **after `mix mailglass.install`**, in
`consumer-install`, next to the existing `UndefinedFunctionError` compile grep
[VERIFIED location: `post-publish-smoke.yml:400-411`]. This is exactly the "idiomatic spot" CONTEXT's
Claude's-Discretion note calls out.

### Pitfall 5: Third-party action SHA pins
**What goes wrong:** A new step using `actions/upload-artifact@v4` (tag, not SHA) trips the
SHA-pin policy (Dependabot + CLAUDE.md rule).
**How to avoid:** Reuse the exact pinned SHAs already in the file:
`actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd`,
`erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93`,
`actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae`,
`actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02`,
`actions/github-script@3a2844b7e9c422d3c10d287c895573f7108da1b3` [VERIFIED: present in both workflows].

### Pitfall 6: Closing issue #32 prematurely
**What goes wrong:** Closing #32 on the strength of the local unit test (the completed-todo path) —
the live published-host failure mode is what #32 actually tracks.
**How to avoid:** Close #32 ONLY after the next `post-publish-smoke` run is GREEN with the new guard
in place (D-07). The unit test is necessary but not sufficient. This is a `checkpoint:human-action`
(needs a real post-publish run + `gh issue close 32`), not an automated step.

### Pitfall 7: MAINTAINING.md stale-line surface is larger than two lines
**What goes wrong:** D-10 cites "two stale lines (~24, ~260)"; the actual stale approval-gate surface
is **three regions** in the current file [VERIFIED]:
- **Line 24:** "The `publish-hex` workflow is environment-gated and requires manual approval in the GitHub Actions UI." — FALSE (no required reviewers).
- **Lines 178-188 ("Bus Factor & Continuity"):** describes "a GitHub Environment (`hex-publish`) with a single required reviewer (`szTheory`)" and a "one-eye pause." — describes a gate that no longer exists.
- **Lines 260-266 (Release Runbook step 3):** "Approve the `hex-publish` deployment in the GitHub Environment UI ... BEFORE clicking Approve ... Record ... approver identity, and approval timestamp." — FALSE; there is no approval step.
**How to avoid:** Reconcile all three regions to the hands-free reality (release-please auto-merges
on green; `gate-ci-green` is the gate; the `hex-publish` environment has no reviewers). The runbook's
5-step structure should collapse the dead "approve" step into a "monitor the hands-free publish
fan-out" step. Also note the smoke-step deps at line 277 still say `~> 1.2` — bump to `~> 1.3`/`~> 0.3`
for consistency while editing.

### Pitfall 8: `mix.lock` integration drift on the bump
**What goes wrong:** Refreshing `reference/host_app/mix.lock` can pull transitive updates beyond the
three siblings, polluting the diff (per the user's mix.lock-resolution memory).
**How to avoid:** Bump only the three sibling lines; prefer `mix deps.update mailglass mailglass_admin
mailglass_inbound` (scoped) over a blanket `mix deps.get`/`mix deps.update --all`. Review the diff —
the three sibling entries should move 1.2.0→1.3.0 / 0.2.0→0.3.0; flag any unrelated transitive churn.

## Code Examples

### EVID-03 published-version trust journey job (post-publish-smoke.yml) — shape
```yaml
# Source: mirror of ci.yml:806-878 (repo-head) adapted to the post-publish chain.
published-trust-journey:
  name: Published-version trust journey
  runs-on: ubuntu-latest
  needs: [cron-guard, consumer-install]          # gate on the consumer install proof
  if: ${{ needs.cron-guard.outputs.should_run == 'true' }}   # OK here: this is NOT a required check
  timeout-minutes: 20
  services: { postgres: { image: postgres:16-alpine, ... } }  # journey loads Ecto-backed siblings
  env: { MIX_ENV: test, POSTGRES_HOST: localhost, ... }
  steps:
    - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd  # v6.0.2 (release ref)
      with: { ref: ${{ needs.cron-guard.outputs.release_ref }} }
    - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93  # v1.24.0
      with: { elixir-version: "1.18", otp-version: "27" }
    - run: mix deps.get
    - run: mix ecto.create -r Mailglass.TestRepo --quiet     # if the journey needs the test DB
    - name: Build reference host (dev, Hex-sourced)
      working-directory: reference/host_app
      env: { MIX_ENV: dev }
      run: mix deps.get && mix compile
    - name: Hex-first guard
      working-directory: reference/host_app
      run: bash ../../scripts/check_clean_baseline_hex_only.sh
    - name: Run published-version trust journey
      run: mix verify.reference_host.journey --host-root reference/host_app
    - name: Validate checkpoint
      run: bash scripts/check_trust_runner_checkpoint.sh
    - uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02  # v4
      with:
        name: trust-runner-published-${{ github.run_id }}
        if-no-files-found: error
        retention-days: 90
        path: tmp/mailglass_trust_runner/checkpoint.json
```
> **Note (Claude's Discretion D-08, resolved):** The full 5-stage runner CAN run in the post-publish
> context. The runner loads sibling beams from `reference/host_app/_build/dev/lib/*/ebin`
> [VERIFIED: `webhook_operator_proof.ex:160`], which the `cd reference/host_app && mix compile` step
> populates from Hex-sourced 1.3.0 code. The checkpoint validator requires the full webhook + operator
> evidence [VERIFIED: `check_trust_runner_checkpoint.sh:161-200`], so a **bounded subset would FAIL the
> validator**. Recommendation: run the **full** journey (it's the same green/red signal the repo-head
> and clean-baseline lanes already produce).

### OPS-01 hackney live guard (consumer-install step) — shape
```yaml
# Source: mirror of post-publish-smoke.yml:403-411 (UndefinedFunctionError grep).
# Insert AFTER "Run mix mailglass.install", in consumer-install, working-directory ${{ runner.temp }}/sandbox
- name: Guard against hackney/api_client regression on published install
  working-directory: ${{ runner.temp }}/sandbox
  run: |
    set -euo pipefail
    if ! grep -F "config :swoosh, :api_client, false" config/runtime.exs; then
      echo "OPS-01 regression: generated runtime.exs did NOT set Swoosh api_client to false on a published install."
      exit 1
    fi
    if grep -Eq '^[[:space:]]*config :swoosh, :api_client, Swoosh\.ApiClient\.Finch' config/runtime.exs; then
      echo "OPS-01 regression: uncommented Swoosh.ApiClient.Finch line present (reintroduces an HTTP client dep)."
      exit 1
    fi
    if grep -Eq '"(hackney|finch)":' mix.lock; then
      echo "OPS-01 regression: a --no-mailer published host pulled hackney/finch into mix.lock."
      exit 1
    fi
    echo "OPS-01 guard passed: no hackney/finch reintroduced on published install."
```

### OPTIONAL OPS-02 doc-contract test (recommended) — precedent pattern
```elixir
# Source/precedent: test/mailglass/install/install_first_preview_smoke_test.exs:24-39
# (reads a workflow file and asserts literal strings). Apply the same to MAINTAINING.md.
test "MAINTAINING.md release gate requires green trust evidence and has no stale approval gate" do
  doc = File.read!(Path.expand("../../MAINTAINING.md", __DIR__))
  assert doc =~ "Trust Lane Repo Head (Elixir 1.18 / OTP 27)"
  assert doc =~ ~r/trust-runner-(repo-head|clean-baseline|published)/
  refute doc =~ "requires manual approval in the GitHub Actions UI"
  refute doc =~ ~r/Approve the `hex-publish` deployment/
end
```

## State of the Art

| Old Approach (pre-Phase 60) | Current Approach | When Changed | Impact |
|------------------------------|------------------|--------------|--------|
| Clean-baseline lane impossible (published siblings predated the trust runner) | Repo-root `dev/` runner orchestrates against Hex-sourced reference host via `--host-root` | This phase (unblocked by 1.3.0 publish) | EVID-02 lane finally landable |
| Reference host pinned `~> 1.2`/`~> 0.2` | `~> 1.3`/`~> 0.3` (live on Hex) | D-02 | Both Hex-baseline lanes resolve current code |
| `MAINTAINING.md` describes a `hex-publish` approval gate | Hands-free publish; `gate-ci-green` is the gate | D-10 | Runbook stops instructing a non-existent click |
| hackney failure tracked only by one-time local test | Live grep guard on a fresh published install | D-07 | Regression-protected; #32 closeable |

**Deprecated/outdated (do NOT follow):**
- 59-02-PLAN.md Task 1 Edit B (`working-directory: reference/host_app` + bare task call) — superseded by D-01/D-03.
- The pending-todo's "call the published Mix task directly" / "via a `reference/host_app/mix.exs` alias" (todo lines 41-43) — impossible (D-01).
- The pending-todo's `reference/host_app/tmp/mailglass_trust_runner/checkpoint.json` checkpoint path (todo line 44) — only valid for the superseded `working-directory` shape; under D-03 the checkpoint is at repo-root `tmp/`.

## Validation Architecture

> Nyquist validation is enabled (`.planning/config.json` → `workflow.nyquist_validation: true`).
> Most deliverables are YAML/shell/docs, so this maps each requirement to the most deterministic
> checkable signal and is explicit about what runs locally vs only-in-CI.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.18 / OTP 27) — bundled, no install |
| Config file | `test/test_helper.exs`; `mix.exs` aliases route `verify.*` to `:test` |
| Quick run command | `MIX_ENV=test mix test test/scripts/required_checks_test.exs test/mailglass/install/install_first_preview_smoke_test.exs` |
| Full suite command | `MIX_ENV=test mix test` (note: ~57 unrelated Oban failures in worktrees per project memory; scope per-file for green) |
| Workflow lint | `actionlint` (not installed locally; CI parses on push). Shell: `shellcheck` (scripts already clean). |

### Phase Requirements → Test/Signal Map
| Req ID | Behavior | Signal Type | Deterministic command / check | Where it runs | File Exists? |
|--------|----------|-------------|-------------------------------|---------------|--------------|
| EVID-02 | Clean-baseline lane enforces Hex-first resolution, blocks path leakage | shell exit-code | `cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh` → exit 0 (happy) / exit 1 (path leak or missing sibling) | local + CI (`ci.yml` job) | ✅ script exists; ❌ ci.yml job (Wave 0) |
| EVID-02 | Lane stays OUT of REQUIRED_CHECKS (D-04) | ExUnit | `mix test test/scripts/required_checks_test.exs` must stay green WITHOUT a clean-baseline entry; assert `parse_required_checks/1` does NOT contain "Trust Lane Clean Baseline" | local + CI | ✅ test exists |
| EVID-02/03 | Checkpoint contract holds | shell exit-code | `bash scripts/check_trust_runner_checkpoint.sh --checkpoint tmp/mailglass_trust_runner/checkpoint.json` → exit 0 | local (after a journey run) + CI | ✅ |
| EVID-03 | Published-version journey runs post-publish before trust claims accepted | CI job green | `published-trust-journey` job green in `post-publish-smoke.yml`; checkpoint artifact uploaded | CI-only (release/cron/dispatch) | ❌ job (Wave 0) |
| OPS-01 | Installer sets `api_client false` (root-cause) | ExUnit | `mix test test/mailglass/install/install_first_preview_smoke_test.exs` (REL-17 sentinel lines 16-20) | local + CI | ✅ |
| OPS-01 | No hackney/finch reintroduced on a fresh PUBLISHED host | CI grep exit-code | new guard step in `consumer-install` (config + mix.lock grep) → exit 1 on regression | CI-only (post-publish-smoke) | ❌ guard (Wave 0) |
| OPS-02 | MAINTAINING.md requires green trust evidence; no stale approval gate | ExUnit (optional, RECOMMENDED) | doc-contract test asserting trust-evidence strings present + approval-gate strings absent | local + CI | ❌ (optional, Wave 0) |

### What is deterministically local vs CI-only
- **Local & deterministic:** the two shell guards (`check_clean_baseline_hex_only.sh`,
  `check_trust_runner_checkpoint.sh`), `required_checks_test.exs`, `install_first_preview_smoke_test.exs`,
  and (recommended) the new MAINTAINING.md doc-contract test. These give the planner a phase gate that
  runs in seconds without CI.
- **CI-only (cannot run locally without a live publish):** the EVID-03 `published-trust-journey` job
  and the OPS-01 live hackney guard both depend on a real published version + a generated Phoenix host.
  Assert these **without flakiness** by (a) gating on `cron-guard.outputs.should_run`, (b) reusing the
  deterministic wait-for-index/HexDocs steps already in the workflow, (c) `timeout-minutes` bounds, and
  (d) `concurrency: cancel-in-progress: false` (already set). They are validated by **observing one
  green post-publish-smoke run** (which is also the D-07 gate for closing #32) — a
  `checkpoint:human-action`, not an automated phase test.
- **Seed determinism:** No property/iteration tests are in this phase's scope, so the inbound-suite
  `--seed 0` flake (project memory) is not triggered. If running the full suite as a phase gate, scope
  per-file to avoid the ~57 unrelated Oban failures and the `voice_test.exs` "Oops" dep-JS noise.

### Wave 0 Gaps (test/guard infra to add before/with implementation)
- [ ] `ci.yml` `trust_lane_clean_baseline` job — covers EVID-02 (mirror of `trust_lane_repo_head`)
- [ ] `post-publish-smoke.yml` `published-trust-journey` job — covers EVID-03
- [ ] `post-publish-smoke.yml` `consumer-install` hackney guard step — covers OPS-01 live signal
- [ ] (RECOMMENDED) `test/.../maintaining_release_gate_contract_test.exs` — covers OPS-02 doc contract
- [ ] (optional hardening) extend `required_checks_test.exs` with an explicit `refute` that the
      clean-baseline name is absent from REQUIRED_CHECKS, locking D-04 against future drift

*Framework install: none needed — ExUnit, shellcheck-clean scripts, and python3 (validator) are all present.*

## Security Domain

> `security_enforcement` is absent from `.planning/config.json` (treat as enabled). This phase has
> essentially no product attack surface — it edits CI/release plumbing and docs, adds no endpoints,
> parsers, or data handling. The relevant controls are CI/supply-chain hygiene, already established.

| ASVS Category | Applies | Standard Control (already in place) |
|---------------|---------|-------------------------------------|
| V1 Secure SDLC / supply chain | yes | All third-party Actions pinned to commit SHA (CLAUDE.md rule); Dependabot watches `.github/workflows/`. Reuse existing pins; add none unpinned. |
| V5 Input Validation | minor | `check_clean_baseline_hex_only.sh` passes the lock path via env var (single-quoted `-e`) to prevent shell-meta injection [VERIFIED: script lines 14-17]. New shell steps must keep `set -euo pipefail` and avoid interpolating untrusted values into `run:`. |
| V6 Cryptography | no | No crypto in scope. |
| Secrets handling | yes | hands-free publish: `HEX_API_KEY` lives only in the `hex-publish` environment, never visible to PR jobs. Do NOT echo secrets in new steps. `post-publish-smoke.yml` already declares minimal `permissions: { contents: read, issues: write }`. |

| Threat Pattern | STRIDE | Standard Mitigation |
|----------------|--------|---------------------|
| False-green trust lane lets a broken release publish | Repudiation/Tampering | `if-no-files-found: error`, unconditional job (no `if:`), `gate-ci-green` non-advisory inclusion |
| Unpinned action lets a compromised tag run in CI | Tampering | SHA-pin every action (reuse existing pins) |
| Shell injection via lock path | Tampering | env-var passing + single-quoted heredoc (existing pattern) |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The post-publish trust journey needs the postgres service + `mix ecto.create` (because `WebhookOperatorProof`/`OperatorDiagnosisProof` exercise Ecto-backed sibling code). The repo-head lane provisions postgres, so I carried it forward. | Code Examples (EVID-03 job) | If the journey is fully fixture-only and needs no DB, the postgres block is harmless overhead. If it DOES need DB and the job omits it, the journey fails. Repo-head includes it → low risk to keep it. |
| A2 | `mix verify.reference_host.journey --host-root reference/host_app` forwards `--host-root` to `mailglass.trust.run` because it is a single-task alias (Mix appends trailing argv to the last/only task). The equivalent `mix mailglass.trust.run --host-root reference/host_app` is unambiguous. | Standard Stack / Pattern 1 | If alias arg-forwarding misbehaves, call the task directly. Both spellings are documented in the task moduledoc (`mailglass.trust.run.ex:22`), so the direct form is a guaranteed fallback. |

**Net:** Only two low-risk operational assumptions; everything else in this research was verified
against current files or the live Hex API.

## Open Questions

1. **Does the EVID-03 post-publish journey require the postgres service?**
   - What we know: the repo-head lane runs it with postgres + `mix ecto.create`; the runner's
     webhook/operator stages load Ecto-backed sibling beams.
   - What's unclear: whether those stages actually touch a live DB or use fakes (the evidence
     mentions `FakePersistence`/`FakeExecution` at `webhook_operator_proof.ex:194-196`).
   - Recommendation: mirror the repo-head lane (include postgres) — it's the proven-green config; the
     planner can trim later if a dry observation shows no DB use.

2. **Exact final structure of the MAINTAINING.md Release Runbook after deleting the approval step.**
   - What we know: step 3 ("Approve the hex-publish deployment") is dead; release-please auto-merges
     on green and publish fans out with no gate.
   - What's unclear: whether to renumber to 4 steps or replace step 3 with "monitor the hands-free
     fan-out + verify `gate-ci-green` passed."
   - Recommendation: replace (don't delete) step 3 with a "monitor hands-free publish" step so the
     5-step / 60-minute-timer numbering and the Phase 38 record forms stay aligned. Planner judgment.

3. **Whether to ship the optional OPS-02 doc-contract test (D-08 / Claude's Discretion).**
   - What we know: repo precedent exists (`install_first_preview_smoke_test.exs:24-39`); it's a
     cheap, deterministic, local guard against the stale lines ever reappearing.
   - Recommendation: **ship it.** It converts OPS-02 from a docs-only claim into a verifiable contract
     at near-zero cost and matches the project's "self-verify, shift-left" posture.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Live Hex packages 1.3.0/1.3.0/0.3.0 | D-02 dep bump; both Hex-baseline lanes | ✓ | 1.3.0 / 1.3.0 / 0.3.0 | — (none needed; the whole phase was blocked until this shipped) |
| Elixir 1.18 / OTP 27 | runner, journey, tests | ✓ (CI pinned via setup-beam; assumed local) | 1.18 / 27 | — |
| python3 | `check_trust_runner_checkpoint.sh` validator | ✓ (used in this session) | 3.x | — |
| GitHub Actions runners (ubuntu-latest) | all CI jobs | ✓ | — | — |
| `gh` CLI (authed) | closing issue #32 (D-07) | ✓ (verified `gh issue view 32`) | — | manual close in web UI |
| `BRANCH_PROTECTION_PAT` | branch-protection re-assert | not needed this phase (D-04 = no REQUIRED_CHECKS change) | — | n/a |

**Missing dependencies with no fallback:** None — the 1.3.0 publish (the sole blocker) is live.

## Sources

### Primary (HIGH confidence — verified in this session)
- `.github/workflows/ci.yml:806-878` — `trust_lane_repo_head` template (job name, no `needs:`/`if:`, prep, validator, artifact)
- `.github/workflows/post-publish-smoke.yml` — triggers (release/schedule/dispatch), `cron-guard`, `wait-for-index`, `wait-for-hexdocs`, `consumer-install:310-438`, `UndefinedFunctionError` grep `:403-411`, `retracted-check`, `notify-on-failure:495-571`
- `.github/workflows/publish-hex.yml:115-191` — `gate-ci-green` inspects ALL ci.yml jobs; `ADVISORY_LANES = ['Operator Browser Gate']`
- `.github/workflows/release-please.yml:215-232` — hands-free auto-merge (confirmed, unchanged)
- `scripts/check_clean_baseline_hex_only.sh` — CWD-relative `mix.lock`, asserts all 3 siblings `:hex`, injection-safe
- `scripts/check_trust_runner_checkpoint.sh` — default path, `--checkpoint`, full 5-stage + evidence contract
- `scripts/setup_branch_protection.sh:17-22` — REQUIRED_CHECKS (4 entries incl. `Trust Lane Repo Head`; no clean-baseline)
- `dev/mix/tasks/mailglass.trust.run.ex` — `--host-root` default `reference/host_app`, checkpoint default `tmp/...` vs `File.cwd!()`, dev-only
- `dev/mailglass/reference_host/webhook_operator_proof.ex:160` — beam load path `../../../reference/host_app/_build/dev/lib/#{app}/ebin`
- `reference/host_app/mix.exs:32-34` + `reference/host_app/mix.lock:20-22` — current `~> 1.2`/`~> 0.2`, already `:hex`-sourced at 1.2.0/1.2.0/0.2.0
- `mix.exs:96-99,229-231` — `dev/` excluded from package `:files`; `verify.reference_host.journey` alias
- `MAINTAINING.md` — line 24, 123-176 (Required Checks + advisory split), 178-188 (Bus Factor stale gate), 228-287 (Release Runbook, stale step 3 at 260-266, `~> 1.2` at 277)
- `test/mailglass/install/install_first_preview_smoke_test.exs` — REL-17 sentinel `:16-20`, workflow-string asserts `:24-39`
- `test/scripts/required_checks_test.exs` — array↔heredoc drift contract, Phase-27 lock entries
- `lib/mailglass/installer/templates.ex:144-156` — emits `config :swoosh, :api_client, false`
- `.planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md` — superseded steps 2/4
- `.planning/phases/59-ci-trust-lanes-checkpoint-evidence/59-VERIFICATION.md` — `gaps_found`, EVID-02 deferral root cause, wiring confirmations
- hex.pm API (`/api/packages/{mailglass,mailglass_admin,mailglass_inbound}`) — live versions 1.3.0/1.3.0/0.3.0
- `gh issue view 32` — OPEN, label `publish-smoke-failed`, from v0.1.0 scheduled failure

### Secondary (MEDIUM)
- Project memory: mix.lock integration resolution, inbound-suite seed-0 flake, voice_test dep-JS noise, self-verify/shift-left, hands-free release state.

### Tertiary (LOW)
- None. All claims verified against current files or the live registry.

## Metadata

**Confidence breakdown:**
- Standard stack (reused assets): HIGH — every asset read in-session at current line numbers.
- Architecture (lane wiring, gate-ci-green mechanism, D-04 posture): HIGH — `gate-ci-green` logic read directly; auto-gating confirmed.
- Pitfalls: HIGH — derived from the read source + Phase 59 verification record + project memory.
- Dep bump enabling condition: HIGH — live Hex versions confirmed = D-02 targets.

**Research date:** 2026-05-29
**Valid until:** 2026-06-28 (stable; the only volatile input is live Hex versions, already at target — re-verify only if a new release ships before planning)
