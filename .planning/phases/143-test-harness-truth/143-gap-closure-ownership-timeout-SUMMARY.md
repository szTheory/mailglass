---
phase: 143
plan: gap-closure-ownership-timeout
subsystem: test-harness
tags: [sandbox-ownership, property-tests, ci-parity, toolchain, docker]
status: complete
requires:
  - "143-05 — SandboxOwnership.checkout!/1 (the sanctioned acquire, release registered first)"
  - "143-06 — setup :unsandboxed_module (the pool-wide :auto door this module leaves)"
  - "143-gap-closure-caller-resolution-regression — the ExUnit-context async guard checkout!/1 now uses"
provides:
  - "idempotency_convergence_test.exs runs under a shared, NON-transactional checkout with a per-module 10-minute :ownership_timeout — the last failing lane's defect, closed without shrinking the property"
  - "`make toolchain` — the gating Elixir 1.18.4 / OTP 27 toolchain, runnable locally on a 2-vCPU container, with a version-drift guard that refuses to report green for the wrong toolchain"
affects:
  - "test/support/sandbox_ownership.ex (doc only: the :auto-mode file count is eight, not nine)"
tech-stack:
  added:
    - "compose.toolchain.yml + dev/toolchain/Dockerfile (reuses reference/demo_app's existing hexpm pin)"
    - "scripts/assert_gating_toolchain.sh (POSIX sh, runs inside the container)"
  patterns:
    - "Per-owner :ownership_timeout via an explicit Sandbox checkout — Ecto's own documented remedy (sandbox.ex:262-264) — instead of a global config/test.exs bump"
    - "shared: true + sandbox: false — pool-wide reachability without a sandbox transaction, preserving committed-write semantics"
key-files:
  created:
    - compose.toolchain.yml
    - dev/toolchain/Dockerfile
    - scripts/assert_gating_toolchain.sh
  modified:
    - test/mailglass/properties/idempotency_convergence_test.exs
    - test/support/sandbox_ownership.ex
    - test/mailglass/test_support/sandbox_ownership_test.exs
    - Makefile
    - CONTRIBUTING.md
decisions:
  - "Chose neither (a) the sibling's transactional shared checkout nor (b) a global config/test.exs ownership_timeout, but the sanctioned door in a third configuration: checkout!(shared: true, sandbox: false, ownership_timeout: 10 * 60_000). It is option (b)'s intent — keep the committed, non-transactional semantics :auto gave this module — implemented through option (a)'s per-module seam."
  - "Kept checkout!/1's DEFAULT ~150ms release-settle bound rather than copying the sibling's 6s. Two consecutive gating-toolchain runs converged inside the default; widening an unexceeded verification bound only slows a future genuine leak's report."
  - "Capped the toolchain container at 2 vCPU / 4 GB (the GitHub-hosted runner size) rather than letting it run unthrottled — an 18-core laptop run under-reports every timing-sensitive bound by ~7x."
metrics:
  duration: "~4h"
  completed: "2026-07-30"
---

# Phase 143 Gap Closure: Ownership Timeout + Gating-Toolchain Parity — Summary

**The last red lane's failure was a clock disagreement, not an ownership leak: `@moduletag timeout: :infinity` lifted ExUnit's clock and left db_connection's 120s `:ownership_timeout` in place, and pool-wide `:auto` offers no per-module lever to raise it. The property now takes a shared, non-transactional checkout with its own ten-minute bound — full 1000 runs intact — and the gating 1.18.4/OTP 27 toolchain is now runnable locally, which is how every number in this summary was measured.**

---

## Task 1 — the last failing lane

### What was actually wrong

`Advisory Matrix` → `Core Full Suite Advisory (Elixir 1.18 / OTP 27 / schema mailglass)`, run `30564591156`, seed 961019:

```
** (DBConnection.ConnectionError) owner #PID<0.6174.0> (:erlang) timed out
   because it owned the connection for longer than 120000ms
   (set via the :ownership_timeout option)
```

514 of the property's 1000 runs in. The orchestrator's reading was right on both counts and is confirmed here:

- **Not an ownership leak.** `already_shared=0` on that run, and the exception is `proxy.ex:77-86`'s ownership timer, not `sandbox.ex:458`'s badmatch.
- **An inconsistency, not a defect in the code under test.** The module carried `@tag timeout: :infinity`, which is ExUnit's clock. Nothing ever addressed db_connection's.

The part that decided the fix is *why* nothing addressed it. Under pool-wide `:auto` there is **no per-module seam at all**:

| Fact | Source |
|---|---|
| In `:auto`, the manager builds the proxy itself for any caller with no owner | `manager.ex:225-227`, the `:not_found when mode == :auto` clause |
| …using `checkout_opts`, captured from the **repo's** pool options at manager init | `manager.ex:99` — `Keyword.take(pool_opts, [:ownership_timeout, ...])` |
| `config/test.exs` sets no `:ownership_timeout` | verified by grep |
| …so the bound is the 120s default | `proxy.ex:9` |

The only lever on that path is `config/test.exs`, which would raise the leak-detection ceiling for all 1500+ tests to accommodate one module — and `assert_manual!/3`'s own docs already warn against edging toward "the 120s `ownership_timeout` at which a genuine leak self-heals".

An **explicit** checkout does have the seam: `sandbox.ex:556-557` merges a caller's `:ownership_timeout` over the pool options for that owner alone. Ecto documents precisely this remedy at `sandbox.ex:262-264`: *"if this is an issue for only a handful of long-running tests, you can pass an `:ownership_timeout` option when calling `Ecto.Adapters.SQL.Sandbox.checkout/2` instead of setting a longer timeout globally in your config."*

### The choice: neither (a) nor (b) exactly — the sanctioned door in a third configuration

```elixir
SandboxOwnership.checkout!(
  repo: TestRepo,
  shared: true,
  sandbox: false,
  context: context,
  ownership_timeout: 10 * 60_000
)
```

This is option **(b)'s intent** — keep the committed, non-transactional semantics `:auto` gave this module — implemented through option **(a)'s per-module seam**. `shared: true` keeps the connection reachable from ExUnit's `on_exit` process (a separate process that would otherwise have no owner to borrow, since the pool sits at `:manual` between modules); `sandbox: false` means no sandbox transaction, so writes commit exactly as they do today.

**The moduledoc's deadlock claim was tested, not assumed.** The old comment said DataCase-style transactional sandboxing "thrashes the sandbox transaction or deadlocks on connection reuse". The sibling's plain `checkout!(shared: true, ...)` shape was implemented here first and **passes** — 1000 runs, 0 failures, on both boxes. The claim is false and has been deleted rather than carried forward. That shape was still rejected, for two reasons in this order:

1. **It changes the semantics of the code under test.** Every `Events.append/1` here commits today; inside a sandbox transaction they become nested and are discarded wholesale at checkin. Preferring the shape that changes the least about what the property exercises is the primary reason.
2. **It costs 1.5x–1.9x.** The property issues 3 TRUNCATEs per iteration (3000 total), and inside a transaction block Postgres cannot truncate in place — it writes a fresh relfilenode per TRUNCATE and holds the previous one until the transaction ends.

### Measurements behind the bound

All at seed 961019, `MAILGLASS_SCHEMA=mailglass`, full 1000 runs, 0 failures:

| Shape | 1.19.5 / OTP 28 host (18-core, host PG) | Gating toolchain (1.18.4 / OTP 27, 2 vCPU, containerized PG) |
|---|---|---|
| pre-fix, pool-wide `:auto` | 34.8s | 74.8s |
| (a) shared **+** sandbox transaction | 64.0s | 96.6s |
| **chosen:** shared **+** `sandbox: false` | **33.4s** | **62.4s / 66.1s / 73.4s** (three runs) |

The chosen shape costs nothing against the pre-fix baseline; the transactional shape costs 1.5x–1.9x.

**Headroom for the 10-minute bound, stated as multiples:**

- The failing GitHub runner completed 514 runs inside its 120s bound = **233 ms/run**, which projects the full property at **~233s** there. `600s / 233s = 2.6x`.
- Against the slowest of three measured gating-toolchain runs: `600s / 73.4s = 8.2x`.
- It is also the bound `webhook_idempotency_convergence_test.exs` already uses for its own 1000-run property, so the two siblings now share one number and one rationale.

**The seam is proven live, not assumed.** Re-running the property with the bound temporarily set to `2_000` on the gating toolchain fails in **2.0s** with the identical exception — `owner #PID<0.671.0> ({:sql_sandbox_owner, ...}) timed out because it owned the connection for longer than 2000ms (set via the :ownership_timeout option)`. Only the number differs from the CI log. The option demonstrably governs this owner, which the `:auto` path had no way to express.

(Incidentally, the CI log's `(:erlang)` owner label versus this run's `{:sql_sandbox_owner, ...}` is itself confirmation: the pre-fix owner was the manager's own implicit `:auto` proxy, created for an unlabeled caller, not a `start_owner!` owner.)

### Release verification deliberately stays at the default bound

No `:settle_attempts` / `:settle_interval_ms` override. The sibling needs 600/10ms (~6s) because its checkin unwinds a large transaction before the ownership manager can process the owner's `:DOWN`; this checkout has no transaction to unwind. `checkout!/1`'s default ~150ms bound converged on **two consecutive** gating-toolchain runs with no `LeakError`. Widening a verification bound that is not being exceeded would only make a future genuine leak slower to report.

### What did NOT change

- `max_runs: 1000` — unchanged.
- Generators, `@event_types`, both assertions — unchanged.
- No `@tag :skip`, no exclusion, no serialization, no weakened assertion.
- `probe/1` and `baseline_tables_present?/1` — untouched, still read-only.
- `.dialyzer_ignore.exs` — untouched, still 15 entries.
- No file's `async:` value changed (SEED-007).

---

## Task 2 — the 1.18.4/OTP 27 toolchain, locally

**It works.** `asdf` is installed (`/opt/homebrew/bin/asdf`, v0.16.4) but has **no** Elixir or Erlang versions installed, and building OTP 27 from source on macOS is a 20–40 minute proposition — so Docker was the route, as suggested.

The image the orchestrator named (`hexpm/elixir:1.18.4-erlang-27.3.4.3-debian-bookworm-20250630`) does not exist on Docker Hub (`manifest unknown`). It did not need to: **`reference/demo_app/Dockerfile` already pins `hexpm/elixir:1.18.4-erlang-27.3.4-debian-bookworm-20250520-slim`** — the gating toolchain, arm64-native. `dev/toolchain/Dockerfile` reuses that exact `FROM`, so the repo has one gating-toolchain string to keep current, not two.

### How to invoke it

```bash
make toolchain                                   # full core suite, schema public
make toolchain MAILGLASS_SCHEMA=mailglass        # the second D-06 axis
make toolchain CMD='mix test path/to_test.exs --seed 961019'
make toolchain CMD='mix dialyzer'                # MIX_ENV=test, as CI runs it
make toolchain-shell                             # interactive, deps + fresh DB ready
make toolchain-version                           # prove the pin, ~2s
make toolchain-down / make toolchain-clean
```

Documented in CONTRIBUTING.md under "Verifying on the gating toolchain".

### Three load-bearing properties

- **`deps/` and `_build/` are container-private named volumes.** The host tree is compiled by the maintainer's Elixir; sharing either directory would let the two toolchains overwrite each other's artifacts, so every switch would be a full rebuild **and** the host's `mix test` could silently run 1.18-built beams. Cost is one cold compile (~4 min at 2 vCPU), cached after.
- **Capped at 2 vCPU / 4 GB** — the GitHub-hosted `ubuntu-latest` runner's size. This is what makes a locally measured duration a usable predictor of the CI clock. Every timing number in this summary was taken at that cap.
- **`scripts/assert_gating_toolchain.sh` runs first and refuses to continue** unless the container really is the Elixir/OTP pair `.tool-versions` declares. Without it, a future version bump leaving `dev/toolchain/Dockerfile` behind would let `make toolchain` keep reporting green for a toolchain nothing gates on — a check that cannot observe its subject reporting success. Elixir is compared exactly; Erlang on the **major** only, because CI itself pins `otp-version: "27"` and lets setup-beam choose the patch, so asserting more than CI pins would fail on a difference no gating lane would notice.

Reuse and isolation: the compose file mirrors the demo stack's conventions (own project name `mailglass-toolchain`, loopback-bound env-overridable ports, named cache volumes) and shares no namespace with `make demo`. The toolchain variables are deliberately **not** `export`ed at Makefile scope — they are set on the compose invocation, so `make ci` / `make demo` keep the environment they had before (in particular `MAILGLASS_SCHEMA` stays unset for non-toolchain targets, which `config/runtime.exs` reads as "use the `config/test.exs` pin").

### Negative control

The guard was verified in **both** directions, not just the passing one: it exits `1` on the 1.19.5/OTP 28 host with a message naming both versions and the file to edit, and prints `gating toolchain confirmed: Elixir 1.18.4 / OTP 27.x` inside the container.

### Honest limitation

**The container does not reproduce the original CI timeout.** It is faster than the GitHub runner that failed (62–73s for the full property vs a ~233s projection there), so the pre-fix `:auto` shape *passes* in it (74.8s, under the 120s bound). Throttling the app container to 0.5 vCPU did not help — the work is DB-bound in a separate, unthrottled Postgres container (77.9s). The failure was therefore reproduced **at a scaled bound instead**: `ownership_timeout: 2_000` produces the identical exception at 2.0s on the gating toolchain, which proves the mechanism and proves the fix's lever governs it. That is weaker than a full-clock reproduction and is stated as such.

---

## Verification — raw `mix test` / `mix dialyzer` / `mix credo` output only

Every suite run below was preceded by `mix ecto.drop -r Mailglass.TestRepo && mix ecto.create -r Mailglass.TestRepo`. No SuiteFloor ledger or formatter output was used as evidence (the ledger lines are reproduced only as incidental context).

**Host — Elixir 1.19.5 / OTP 28**, `mix test --warnings-as-errors --exclude requires_workspace`:

| Axis | Seed | Result |
|---|---|---|
| `MAILGLASS_SCHEMA=mailglass` | 961019 | `23 properties, 1559 tests, 0 failures, 7 skipped (14 excluded)` — 122.0s |
| `MAILGLASS_SCHEMA=mailglass` | 374117 | `23 properties, 1559 tests, 0 failures, 7 skipped (14 excluded)` — 105.8s |
| `MAILGLASS_SCHEMA=public` | 783091 | `23 properties, 1560 tests, 0 failures, 7 skipped (13 excluded)` — 102.7s |

**Gating toolchain — Elixir 1.18.4 / OTP 27, 2 vCPU** (`make toolchain`), same command:

| Axis | Seed | Result |
|---|---|---|
| `MAILGLASS_SCHEMA=mailglass` | 961019 | `23 properties, 1573 tests, 0 failures, 14 excluded, 7 skipped` — 177.1s |
| `MAILGLASS_SCHEMA=public` | 783091 | `23 properties, 1573 tests, 0 failures, 13 excluded, 7 skipped` — 180.2s |
| `MAILGLASS_SCHEMA=mailglass` | 374117 | `23 properties, 1573 tests, 0 failures, 14 excluded, 7 skipped` — 162.2s |

All three seed/axis combinations pass on **both** toolchains — six full-suite runs, 0 failures.

The 1573-vs-1559 difference is a **formatting** difference between Elixir versions, not a coverage difference: 1.18 prints the total inclusive of exclusions (`1573 tests, ... 14 excluded`), 1.19 prints it exclusive (`1559 tests, ... (14 excluded)`). 1559 + 14 = 1573. The gating-toolchain line at seed 961019 is therefore **character-for-character the failing CI job's own count line, with `1 failure` replaced by `0 failures`.**

**Static gates (host):**

- `MIX_ENV=test mix dialyzer` → `Total errors: 16, Skipped: 16, Unnecessary Skips: 0` / `done (passed successfully)`
- `mix format --check-formatted` → clean
- `mix credo --strict` → `3903 mods/funs, found no issues` (78 checks, 494 files)

**Targeted spot-check** after the doc-only edits, `MAILGLASS_SCHEMA=mailglass`, both convergence properties plus the `SandboxOwnership` unit tests: `2 properties, 40 tests, 0 failures`.

---

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 1 — Bug] Stale `:auto`-mode file count in two live docs**

- **Found during:** Task 1, after removing `setup :unsandboxed_module` from this module.
- **Issue:** `test/support/sandbox_ownership.ex:582` and `test/mailglass/test_support/sandbox_ownership_test.exs:145` both asserted "the nine `:auto`-mode files". There are now **eight** (`grep -rln unsandboxed_module test/`). A doc that states a checkable count and states it wrongly is the same defect class this phase exists to remove.
- **Fix:** Both updated to eight, each naming why the ninth left and how to re-derive the list. `143-MECHANISM.md` was deliberately **left alone** — it is a dated diagnostic record of what was true at diagnosis time, not a live claim.
- **Commit:** `16babeb4`

**2. [Rule 3 — Blocking] `scripts/assert_gating_toolchain.sh` used `set -o pipefail`**

- **Found during:** Task 2, first in-container run — `Illegal option -o pipefail`.
- **Issue:** the toolchain image's `/bin/sh` is dash.
- **Fix:** rewritten as POSIX `sh` with `set -eu`; there are no pipelines in the script, so nothing is lost. Re-verified in both directions afterward.
- **Commit:** `b3fc2ad3`

### Not deviations, but worth recording

- The image tag the orchestrator reported as pulled does not exist upstream; the repo's existing demo pin was used instead (see Task 2).
- `asdf` is present but empty, contradicting one prior executor's report that it was unavailable *and* the assumption that it was ready to use. Neither was accurate; Docker was the workable route.

---

## Known Stubs

None.

## Threat Flags

None. No network surface, auth path, or trust-boundary schema change. `scripts/assert_gating_toolchain.sh` is read-only and executes no untrusted input. `compose.toolchain.yml` binds its only host port to `127.0.0.1` and carries the same throwaway `postgres/postgres` test credentials the CI service container and `compose.demo.yml` already use.

---

## Still Open

1. **No full-clock reproduction of the original 120s timeout.** Reproduced at a scaled bound only — see "Honest limitation" above.
2. **The toolchain harness is not wired into any CI lane.** It is a maintainer tool by design (it would be redundant in CI, which already *is* the gating toolchain). The drift guard is what keeps it honest between version bumps.
3. **`SuiteFloor`'s `executed_nudge` warning fires on every run** (`1575 above the pinned floor of 0`). Pre-existing, advisory-only, and out of scope for this pass — the floor has never been pinned. Left alone rather than re-pinned as a side effect of an unrelated fix.
