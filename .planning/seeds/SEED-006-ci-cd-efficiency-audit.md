---
id: SEED-006
status: archived
updated: 2026-07-31
note: Deferred at v2.2 close pending measured latency or runner-cost pull; retained as future reference.
planted: 2026-07-28
planted_during: v2.1 archived / v2.2 (CI Signal Integrity) being scoped
trigger_when: after v2.2 lands — when CI signal is trustworthy but wall-clock, runner cost, or contributor feedback latency becomes the felt problem
scope: large
---

# SEED-006: CI/CD Efficiency & Contributor Feedback Latency Audit

## Why This Matters

v2.2 (CI Signal Integrity) makes the pipeline *honest* — every green light will
mean what it says. This seed is the natural successor: once the signal is
trustworthy, the next question is whether it is **fast, cheap, and pleasant**.

Those are different problems and must not be conflated. Optimizing a pipeline
whose greens are lying just makes it lie faster. Hence the ordering: **v2.2 first,
this second.**

The felt problems today, in advance of measurement:

- **Wide, possibly over-broad matrices.** Core Full Suite alone runs 4 legs
  (Elixir 1.18/OTP 27 and 1.19/OTP 28, each × `public` and `mailglass` schema).
  Some lanes re-run lint-shaped work per matrix entry.
- **Heavy browser gates on the critical path.** Operator Browser Gate runs ~7m55s
  and Demo Browser Evidence spins a full Docker Compose stack. Both are valuable;
  neither has been evaluated for whether it belongs on *every* PR.
- **Three packages plus two frozen reference baselines.** `mailglass`,
  `mailglass_admin`, `mailglass_inbound`, plus `reference/host_app` and
  `reference/demo_app`. Compile and dependency work is likely duplicated across
  lanes in ways a shared-cache or job-graph change could collapse.
- **Known nondeterminism.** The full inbound suite intermittently fails with a DB
  pool `tcp recv:closed` traced to a phase-45 1000-iteration property test, and
  the citext probe race (being fixed in v2.2 Phase 142) shows the harness has
  concurrency sharp edges worth a systematic pass rather than one-off fixes.
- **Cache correctness is load-bearing and under-observed.** Cache keys are
  toolchain-hashed (v1.15 Phase 129), but hit rate, staleness behavior, and the
  `_build` reuse envelope across OTP/Elixir/`MIX_ENV` have never been measured.
- **Runner CPU utilization is unmeasured.** No evidence exists that ExUnit
  concurrency (`async: true` coverage, `max_cases`) is matched to actual runner
  core count.

## When to Surface

Surface this when **any** of these becomes true:

- v2.2 has shipped and CI greens are trustworthy
- PR feedback latency is the thing slowing a milestone down
- GitHub Actions minutes/cost become a concern
- A contributor (or future you) complains that reproducing CI locally is guesswork
- Flakiness recurs after the v2.2 harness fixes, suggesting a systemic rather
  than local cause

Do **not** surface this while advisory lanes are still red — measuring a pipeline
whose failures are unexplained produces a baseline you cannot trust.

## Known Local Context the Audit Must Respect

Load-bearing facts a naive optimizer would break:

- **`Mailglass.CILanes`** (`test/support/ci_lanes.ex`) is the single source of
  truth for required vs advisory lane identity, consumed by `ci_green.needs`, the
  MIXCI-03 parity test, and `scripts/setup_branch_protection.sh`. Lane changes
  must go through it, not around it.
- **Required contexts are exactly `{CI Green, Guard Release Trigger}`**, asserted
  by `test/scripts/required_checks_test.exs`. `CI Green` is an aggregate gate; do
  not require matrix children directly. (2026-07-28: live protection had drifted
  to the job *id* `guard-release-trigger` and blocked all 22 PRs for 24 days —
  never require a name a workflow does not actually report.)
- **Guard Release Trigger must have no `paths:`/`paths-ignore:` filter** (GATE-04,
  anti-vacuity) — a required check that can be skipped is a permanently pending PR.
- **`reference/host_app` and `reference/demo_app` are FROZEN deterministic
  baselines.** Bumping their mailglass pins is a coordinated 5-file change. Do not
  "simplify" them into normal dependents.
- **The `--no-optional-deps` compile lane is a real compatibility promise**, not
  redundant with the normal compile lane.
- **The zero-Node constraint is adopter-facing only.** A `only: :dev` tool that
  needs Node does not violate it. Do not over-apply this to CI tooling.
- **`mix ci` alias family already exists** (v1.15 Phase 128) with a parity-drift
  test. Extend it rather than inventing a parallel local-command story.
- **Docs-only PRs already skip `CI Green`** via `Detect Non-Doc Changes`. Verify
  any trigger change preserves that without creating pending-check traps.

## Explicit Non-Goals

- Do not trade trustworthiness for speed. A faster pipeline that hides risk is a
  regression, and must at minimum be labeled a tradeoff and tiered as optional.
- Do not delete slow tests merely for being slow — classify first.
- Do not answer flakiness with blanket retries. Retry is a quarantine tool, not a fix.
- Do not build a clever bespoke CI system. Boring and legible beats ingenious.

## Scope Sketch (pre-ceremony, non-binding)

1. **Baseline & observability** — measure before changing anything: per-job
   durations, p95, cache hit rate, cold vs warm, critical path, rerun/flake rate.
2. **Test value classification** — every suite sorted into keep-in-PR /
   optimize / move-to-scheduled / quarantine-and-fix / delete, with evidence.
3. **Concurrency & partitioning** — `async: true` audit, `max_cases` vs actual
   runner cores, `--partitions` only where measurement justifies it.
4. **Cache & matrix policy** — key precision, `_build` reuse envelope, matrix
   shape justified per compatibility promise; broad matrices moved to scheduled.
5. **Trigger topology** — PR fast path / main / nightly / release, with the
   browser and Docker gates placed deliberately.
6. **DX & release polish** — job summaries, slowest-test reporting, actionable
   failure output, local reproduction parity.

---

## The Audit Prompt

Run this when the seed is promoted. Adapted from the user's CI/CD performance
boilerplate (`ci/cd performance prompt.txt`), specialized for mailglass.

> You are acting as a combined principal Elixir maintainer, OSS library
> maintainer, GitHub Actions expert, SRE/DevOps engineer, test architect,
> DX-focused staff engineer, release engineer, security/supply-chain reviewer,
> and practical software economist.
>
> Audit the mailglass CI/CD pipeline. The goal is not to make CI look fancy. Make
> it fast, deterministic, trustworthy, resource-efficient, maintainable, and
> pleasant for contributors, while preserving or increasing actual quality signal.
>
> Preserve this taste/context:
> - fast feedback for developers
> - reliable deterministic gates
> - no wasting maintainer time or CI runner time
> - keep high-value tests; remove or demote low-signal, redundant, flaky, or
>   poorly scoped checks
> - use available runner CPU/cores intelligently without overcomplicating
> - do not "optimize" by hiding risk
> - prefer boring, idiomatic, least-surprise CI
> - optimize for OSS contributor DX and maintainer sanity
>
> Do not give generic CI advice. Make concrete, repo-specific recommendations.
> It is fine to boil the ocean here — be comprehensive, identify every bottleneck,
> and address them systematically. Adopt the lens of someone optimizing for all of
> this at once and enumerate what they would find.
>
> **Operating mode.** Treat this as a serious one-shot architecture/research pass.
> Use subagents; if unavailable, simulate separate expert passes and merge them
> explicitly. Minimum lenses: (1) Actions topology & critical path, (2) Elixir/
> Mix/ExUnit performance, (3) Phoenix/Plug/Ecto specifics, (4) test quality /
> flakiness / determinism, (5) caching & artifacts, (6) OSS maintainer DX,
> (7) security / supply chain / release, (8) lessons from respected Elixir OSS
> (Phoenix, Ecto, Plug, Broadway, Nx, Oban, Livebook, Ash, Tesla, Finch),
> (9) a simplicity reviewer whose only job is deleting cleverness, (10) a final
> integrator who makes every recommendation coherent with the others.
>
> **Inputs.** Read before recommending: `.github/workflows/*`, `.github/actions/*`,
> `.github/dependabot.yml`, reusable workflows, live branch protection,
> `scripts/setup_branch_protection.sh`, `test/support/ci_lanes.ex`,
> `test/scripts/*`, root + `mailglass_admin/` + `mailglass_inbound/` `mix.exs` and
> `mix.lock`, `.tool-versions`, `.formatter.exs`, `.credo.exs`, dialyzer config,
> `config/test.exs`, `test/test_helper.exs`, `test/support/*`, `Makefile`,
> `scripts/*`, `mailglass_admin/scripts/*`, `reference/host_app`,
> `reference/demo_app`, `reference/demo_app/assets/e2e/*`, admin Playwright specs,
> `CONTRIBUTING.md`, and the recent 20–50 workflow runs with per-job timings,
> rerun rate, and cache hit/miss logs. If a file cannot be inspected, say so and
> state the assumption. Do not hallucinate repo contents.
>
> **North star, in priority order:** (1) correctness/trustworthiness of gates,
> (2) deterministic non-flaky feedback, (3) fast PR feedback on likely
> regressions, (4) efficient runner/cache use, (5) maintainable workflow YAML,
> (6) contributor friendliness, (7) security posture, (8) presentation.
>
> **Baseline first.** Before recommendations, produce a current-state table:
> workflow, trigger, job, runner, matrix dims, services, commands, avg duration,
> p95, failure/rerun rate, cache usage, required-for-merge, quality signal, likely
> bottleneck, notes. Then compute the critical path and separate the PR fast path,
> main path, scheduled path, release path, docs path, and security path. Where
> data is missing, give the exact command or API call to obtain it. Useful
> diagnostics: `mix test --slowest 20`, `mix test --profile-require`,
> `MIX_ENV=test mix compile --profile time`,
> `mix xref graph --label compile-connected`, `mix deps.unlock --check-unused`,
> `mix deps.get --check-locked`, `mix hex.audit`, `mix deps.audit`,
> `elixir -e "IO.inspect(System.schedulers_online())"`, plus cache hit/miss
> reporting in job summaries.
>
> **Test value classification.** For each suite/check answer: what bug class does
> it catch, how often does it fail usefully, is it deterministic, is it fast
> enough for PR, is it redundant, does it test behavior or implementation trivia,
> does it need network/time/randomness/global state, could it move to nightly,
> could it shard, could it be async-safe, is its failure output actionable? Sort
> into: (A) must remain in PR gate, (B) keep in PR but optimize, (C) move to
> scheduled/main/release, (D) quarantine and fix before trusting, (E) delete or
> rewrite. Be conservative about deletion — evidence only.
>
> **Elixir-specific depth.** Audit `async: true` coverage and precisely why each
> non-async module is non-async (DB sandbox, Application env, ETS named tables,
> registered processes, ports, time, randomness, Mox global mode, Bypass, Logger
> capture, telemetry handlers). Splitting huge modules can raise concurrency since
> tests within a module still serialize. Only tune `max_cases` after measuring
> against `System.schedulers_online()` and real runner cores. Evaluate
> `--partitions` honestly, including duplicated setup/compile, service contention,
> per-partition DB isolation, and coverage merge complexity. Check Ecto sandbox
> config and pool sizes against async count, LiveView/channel ownership and
> allowances, port conflicts, and deterministic service readiness instead of
> sleeps. Audit compile time via `--profile time` and `xref` for compile-connected
> chains and macro-heavy modules. For Dialyzer, ensure PLT cache keys include OS,
> OTP, Elixir, lockfile and config, use restore/save split so a failing run still
> persists the PLT, and decide PR vs main vs scheduled by runtime and value.
>
> **Actions-specific depth.** Evaluate triggers (`pull_request`, `push`,
> `merge_group`, `workflow_dispatch`, `schedule`, tags, path filters) for
> pending-check traps — a required check that gets skipped blocks PRs forever, a
> lesson this repo has already paid for. Use concurrency groups to cancel stale PR
> runs without cancelling main/release. Justify each matrix dimension against a
> stated compatibility promise; move broad matrices to scheduled. Run lint-shaped
> work once, not per matrix entry. Audit cache key dimensions (OS, arch, OTP,
> Elixir, `MIX_ENV`, lockfile hash, cache buster) and restore-key breadth; never
> restore `_build` across incompatible OTP/Elixir/`MIX_ENV`, never skip
> `mix deps.get` after a partial restore. Keep required-check names stable and
> prefer a single aggregate gate over requiring matrix children.
>
> **Security/release.** Review top-level and per-job `permissions`, `GITHUB_TOKEN`
> scope, third-party action pinning, secrets exposure to forks,
> `pull_request_target` usage, shell injection from untrusted PR metadata, and the
> Hex publish path (metadata, docs build, changelog/version/tag semantics,
> dry-run, scoped keys, publish only from trusted tags after full verification).
> Note the existing `GITHUB_TOKEN` anti-recursion behavior that forces the
> release-please hourly dead-man's-switch, and say whether it can be removed.
>
> **DX.** Verify a single local command reproduces CI (`mix ci` family already
> exists — extend it, don't fork it), that it is documented in CONTRIBUTING, that
> logs are grouped and failures actionable, that slowest tests are reported, that
> flaky failures print a reproduction seed, that service failures are
> distinguishable from test failures, and that job names read clearly
> (`test / elixir 1.19 / otp 28`).
>
> **Output format.** (1) Executive summary with top 5 changes, impact, risk, and
> the first PR to make. (2) Current pipeline map. (3) Baseline metrics with
> critical path and cold/warm cache notes. (4) Findings by category: correctness,
> performance, determinism, caching, matrix policy, suite quality, security,
> release, DX. (5) Prioritized recommendations, each with title, P0–P3, category,
> current issue, proposed change, why it is idiomatic, pros, cons, expected
> impact, risk, how to implement, how to verify, rollback plan. (6) Proposed
> target pipeline (PR / main / nightly / release / docs / security). (7) Concrete
> minimal patches, staged as sequential PRs: observability → cache/version cleanup
> → concurrency/partitioning → matrix/trigger refinement → release/security
> polish. (8) Test cleanup plan. (9) Validation plan with before/after metrics.
> (10) Final recommended local command. (11) Only those open questions that
> genuinely change decisions.
>
> **Score every recommendation 1–5** on runtime impact, reliability impact,
> quality-signal impact, maintainer complexity, security impact, contributor DX,
> and reversibility. Prefer high impact + low complexity + easy rollback + strong
> idiomatic fit. Be skeptical of clever, small-speedup, hard-to-debug,
> fragile-cache, or hard-to-reproduce recommendations.
>
> **Dark corners to check explicitly:** required checks stuck pending from path/
> branch/commit-message filtering; matrix explosion across OS × OTP × Elixir ×
> schema × partition; lint duplicated per matrix entry; `ubuntu-latest` drift;
> `_build` restored across incompatible toolchains; broad restore keys serving
> stale deps; `mix deps.get` skipped after partial restore; PLT cache not saved on
> Dialyzer failure; PLT key missing OTP/Elixir/lock dimensions; tests marked async
> while mutating global state; Mox global mode blocking async; sandbox ownership
> across processes; partitions sharing a database; fixed ports in async tests;
> `Process.sleep` masking races; real network calls in PR tests; unseeded
> randomness; oversized test modules capping concurrency; coverage taxing every PR
> without gate value; doctests dragging in heavy compiles; integration containers
> dominating PR wall-clock; network-dependent security scans flaking;
> overprivileged `GITHUB_TOKEN`; secrets reachable from fork contexts; release
> workflows not depending on CI; publishing without dry-run; branch protection
> requiring unstable job names; local commands diverging from CI; opaque logs with
> no actionable guidance.
>
> Be opinionated but evidence-based. Say "do this", "do not do this", "this is not
> worth it", "this is worth it despite cost because…". Surface tradeoffs honestly.
> No vague "use caching" — give exact keys, paths, and failure modes. No vague
> "consider optimizing tests" — name the concrete files and patterns. The final
> output should read as one integrated CI/CD design, not a pile of tips.

## Related

- Successor to **v2.2 CI Signal Integrity & Supply-Chain Hygiene** (phases 141-144)
- Builds on **v1.15 Release-Pipeline Efficiency & Contributor DX** (phases 125-131),
  which introduced the `mix ci` alias family, `Mailglass.CILanes`, and
  toolchain-hashed cache keys
