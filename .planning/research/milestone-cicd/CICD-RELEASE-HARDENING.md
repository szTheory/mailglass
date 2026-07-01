# CI/CD + Release-Engineering Hardening Plan — mailglass

> **Scope.** One-shot, decision-ready hardening plan for the 3-package mailglass repo
> (`mailglass` core, `mailglass_admin`, `mailglass_inbound`). Grounds every recommendation
> in (a) real workflow files from 10 flagship Elixir OSS libs and (b) multi-package
> linked-version release practice across release-please / Rust / JS / Elixir ecosystems.
> **Author:** release-engineering research pass, 2026-06-30.
> **Current live versions:** `mailglass` 1.10.1 / `mailglass_admin` 1.10.1 (linked) /
> `mailglass_inbound` 1.5.3 (own line; the 1.10.2/1.5.4 ceremony just ran).

---

## 0. Executive summary — top recommendations (P0/P1)

1. **P0 — Kill the inbound exact-pin re-pin trap.** Replace `{:mailglass, "== X.Y.Z"}` in
   BOTH siblings with `{:mailglass, "~> MAJOR.MINOR"}` (the idiomatic Elixir sibling pin —
   Ash, Phoenix LV, Nx all use `~>`, **none** use `==`). This deletes the sed-sync step, the
   transient-red-to-main dance, the paired-inbound-release-on-every-patch drag, and half the
   `stability_contract_test` assertions. **Locked redesign in §6.**
2. **P0 — Add a fan-in "all-green" gate job** and make it the SOLE required branch-protection
   context, replacing the 5 load-bearing leaf contexts. Fixes green-but-BLOCKED / admin-merge.
3. **P1 — Fix the inbound sandbox flake at the root** (shared-mode/async collision in
   `MailboxCase`), retiring `--seed 0`. §3.
4. **P1 — Correct the deps cache key** to include OTP+Elixir (matches 7/10 flagship repos);
   scope restore-keys; split/self-heal the PLT cache. §1.
5. **P1 — CI the release body per-phase**, not only at the ceremony (the v1.14 7-regression
   root cause). §5.4.
6. **P1 — Fix the `gate-self-test.yml` stale `"Tests ("` default** → `"Support Contract Core ("`. §5.3.
7. **P2 — Add `:mix_audit` + dependabot sibling-dir coverage**; formalize the cowlib
   allowlist lifecycle. §4.
8. **P2/P3 — Version-matrix policy:** keep single-version as the required lane; add a
   **latest Elixir advisory row** (28.x) on main/nightly only — do NOT add a min-supported
   row (mailglass floors at 1.18, nothing older is claimed). §2.

---

## 1. Ecosystem / competitor lessons (what to copy, what NOT)

Fetched from live default branches 2026-06-30. All snippets are literal.

| Repo | Cache key shape | Matrix policy | Fan-in all-green? | Supply chain | Notable |
|---|---|---|---|---|---|
| **phoenix** | `deps-${os}-${otp}-${elixir}-${lockhash}`, deps+_build together, restore drops lockhash | 3 rows (1.15/1.18/1.19), lint on newest via `lint: true` | No | none | SHA-pins actions (rare) |
| **ecto** | `${os}-${elixir}-${otp}-${lockhash}` | 5 rows incl 1.14 floor, `fail-fast:false`, lint newest | No | `deps.unlock --check-unused` | widest matrix |
| **oban** | `${os}-mix-${elixir}-${otp}-${lockhash}` | rows pin DB versions per `pair:`; `exclude_tags` per row | No | none | `mix test \|\| mix test --failed` retry idiom |
| **ash** | (inside `staple-actions`) `.tool-versions` | `sat_solver` only | No | **hex.audit + deps.audit + sobelow + Credo→SARIF + Scorecard** | only repo doing full scanning |
| **broadway** | `mix-${os}-${elixir}-${otp}-${lockhash}` | 2 rows (1.12 floor + 1.19 latest), lint+coverage newest | No | none | canonical-minimal template |
| **nx** | `${os}-Elixir-v${elixir}-OTP-${otp}-${lockhash}-v1`, **no restore-keys** | `working_directory × elixir` product; `detect-changes` path gating | No | none | manual `-v1` cache-buster |
| **req** | `mix-otp-${otp}-deps-${lockhash}` (Elixir dropped on purpose) | 2 rows, lint newest, `--no-optional-deps -Werror` on lint | No | none | tightest config |
| **bandit** | `test-${os}-${otp}-${elixir}-${lockhash}`; **separate PLT cache w/ self-healing eviction** | 3×3 w/ `exclude:` → 6; `re-run` job on failure | No (has `re-run`) | **dependabot (mix + actions)** | PLT eviction + auto-retry |
| **finch** | deps + `_build` split; PLT key NOT lock-hashed | 3 rows nested `pair:` | No | none | **footgun: PLT key uses `matrix.erlang` but matrix defines `matrix.pair.otp` → key silently collapses** |
| **livebook** | `${os}-mix-${elixir}-${otp}-${lockhash}` from a `versions` file | **no version matrix** — single pinned pair; matrixes OS instead | No | none | reads repo-root `versions` |

### Cross-cutting lessons

- **Cache key: 7/10 include OTP+Elixir; NOBODY includes MIX_ENV** (it's a global `env:`, so
  a per-env prefix like `deps-`/`test-` is the substitute). **mailglass's `${{runner.os}}-mix-${{hashFiles}}`
  is an outlier** — it omits OTP+Elixir. Safe *today* only because there's one version.
- **Fan-in all-green job: ZERO of 10 flagship Elixir libs use one.** This is a
  GitHub-general branch-protection ergonomics pattern, not an Elixir-idiom. mailglass should
  adopt it **deliberately** (it has 5 required leaf contexts — the exact pain the pattern
  solves), but the plan must justify it on ergonomics, not "Phoenix does it" (Phoenix doesn't).
- **Matrix: lowest-supported + latest, `fail-fast:false`, lint gated to newest row** is the
  dominant idiom (7/10). **NOBODY uses `continue-on-error` nightly rows** and **NOBODY reduces
  the matrix on PR vs cron** — the full matrix runs every PR. Livebook (single pinned pair) is
  the precedent for mailglass's current single-version stance.
- **Test partitioning (`--partitions`/`MIX_TEST_PARTITION`): ZERO of 10 use it.** Parallelism
  comes from the version matrix + async ExUnit, not partitioning. Don't add it.
- **Supply chain: only Ash scans in-CI** (hex.audit + mix_audit + sobelow). Everyone else
  relies on `deps.unlock --check-unused` + SHA-pinned actions + dependabot. **Only Bandit ships
  a committed `dependabot.yml`.** mailglass's `publish.check` audit posture is closer to **Ash**
  than to Dashbit minimalism — cite Ash as precedent for "a serious lib runs audits."
- **Flake mitigation idiom: Oban's `mix test \|\| mix test --failed`** (retry-once) and Bandit's
  `re-run` job are the ecosystem answers — NOT seed-pinning. Seed-pinning masks; it never fixes.
- **setup-beam:** inline `elixir-version`/`otp-version` from matrix (8/10). SHA-pin (Phoenix, Ash)
  is the security-conscious choice — matches mailglass's own "pin actions to SHA" rule. ✓ already done.

---

## 2. Prioritized recommendations

Each: **current issue / proposed change / why-idiomatic / pros / cons / impact / effort / risk / how-to-verify.**

### P0-A — Fan-in "all-green" summary gate (branch-protection simplification)

- **Current issue.** 5 required leaf contexts (`Support Contract Core/Admin`, `Compile No
  Optional Deps`, `Trust Lane Repo Head`, `Installer Host Smoke`). PRs show green-but-BLOCKED and
  need admin-merge; adding/renaming a lane means editing `setup_branch_protection.sh` +
  re-applying the ruleset; the `gate-ci-green` advisory-classifier has to re-derive "required
  vs advisory" by name-matching.
- **Proposed change.** Add one terminal job to `ci.yml`:
  ```yaml
  ci-green:
    name: CI Green
    runs-on: ubuntu-latest
    needs:
      - format_check
      - compile_warnings
      - compile_no_optional_deps
      - support_contract_core
      - support_contract_admin
      - installer_host_smoke
      - trust_lane_repo_head
      # ...every lane that must be green to merge (NOT the advisory browser lanes)
    if: always()
    steps:
      - name: Assert no required lane failed
        run: |
          result='${{ join(needs.*.result, ' ') }}'
          echo "needs results: $result"
          if grep -qE 'failure|cancelled'; then :; fi
          for r in $result; do
            if [ "$r" != "success" ] && [ "$r" != "skipped" ]; then
              echo "Delivery blocked: a required CI lane concluded '$r'."; exit 1
            fi
          done
          echo "All required lanes green."
  ```
  Then set branch protection to require **only** `CI Green` (plus `guard-release-trigger`).
- **Why idiomatic.** Not an Elixir-lib idiom (0/10), but the canonical GitHub answer for
  "many required checks" — justified here purely by the 5-context admin-merge pain.
- **Pros.** One required context; adding a lane never touches branch-protection; green-but-BLOCKED
  disappears (the aggregate reports one clear status); `gate-ci-green` can gate on this single
  run conclusion instead of re-classifying job names.
- **Cons.** `if: always()` + explicit `needs` list must be maintained (a forgotten lane silently
  isn't gated). The `skipped`-is-ok rule is required so path-filtered/omitted lanes don't false-fail.
- **Impact.** High (removes the #1 day-to-day release-ceremony friction).
- **Effort.** Low (1 job + 1 branch-protection edit + update `gate-self-test` `check_name` default).
- **Risk.** Low-Med — the classic footgun is a lane missing from `needs` being silently ungated.
  Mitigate with a tiny meta-test (`ci_green_covers_required_lanes_test.exs`) that parses `ci.yml`
  and asserts every required lane name appears in `ci-green.needs`.
- **How to verify.** Run `gate-self-test.yml` with `check_name: "CI Green"` — the synthetic
  `assert false` PR must show `CI Green` = FAILURE and be blocked.

### P0-B — Loosen sibling pins (the inbound re-pin trap) → **full redesign in §6.**

### P1-A — Cache-key correctness

- **Current issue.** Every job uses `key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}`
  with restore-key `${{ runner.os }}-mix-`. No OTP/Elixir dimension; the broad `-mix-` restore-key
  can pull a `_build`/PLT built under a *different* toolchain. Latent stale-`_build` risk, masked
  only because there's one version today (adding the §2 advisory row would expose it immediately).
  Note mailglass mostly caches `deps` only (not `_build`), so the risk is concentrated in the
  **PLT cache** (`dialyzer` job) and any `_build` reuse.
- **Proposed change.** Adopt the Phoenix/Ecto/Oban shape. Per-env prefix + full toolchain dims:
  ```yaml
  # deps cache (test lanes)
  - uses: actions/cache@<sha>  # v5.0.5
    with:
      path: |
        deps
        _build
      key: mix-${{ runner.os }}-otp27-ex1.18-${{ env.MIX_ENV || 'dev' }}-${{ hashFiles('**/mix.lock') }}
      restore-keys: |
        mix-${{ runner.os }}-otp27-ex1.18-${{ env.MIX_ENV || 'dev' }}-
  ```
  For the **PLT cache** (dialyzer job), adopt Bandit's self-healing eviction:
  ```yaml
  - name: Cache PLT
    uses: actions/cache@<sha>
    with:
      path: _build/dev/*.plt
      key: plt-${{ runner.os }}-otp27-ex1.18-${{ hashFiles('**/mix.lock') }}
      restore-keys: plt-${{ runner.os }}-otp27-ex1.18-
  - name: Run Dialyzer
    id: dialyzer
    continue-on-error: true
    run: mix dialyzer --format github
  - name: Evict stale PLT + retry
    if: steps.dialyzer.outcome == 'failure'
    run: rm -rf _build/dev/*.plt && mix dialyzer --plt && mix dialyzer --format github
  ```
  Publish jobs (`publish-hex.yml`) use `key: ...` with **no** restore-keys (they want an exact
  match or a clean fetch — a partial restore under a stale toolchain is worse than a cold fetch).
- **Why idiomatic.** OTP+Elixir in the key = 7/10 flagship repos. Per-env prefix substitutes for
  MIX_ENV (nobody keys on MIX_ENV directly). Bandit's PLT eviction is the most robust Dialyzer
  cache pattern in the ecosystem.
- **Pros.** Removes the cross-toolchain stale-cache class of failure permanently; makes the §2
  advisory row safe to add; PLT no longer wedges CI on a stale-beam Dialyzer error.
- **Cons.** Cache churn on the first run after the key change (one cold build); a hardcoded
  `otp27-ex1.18` string must track any toolchain bump (acceptable — it's one string, and a
  version bump is a deliberate act).
- **Impact.** Medium now, High once a second version row exists.
- **Effort.** Low-Med (mechanical across ~15 cache blocks — do it with a scripted edit + a
  `ci_cache_key_test.exs` that greps every `actions/cache` block for the `otp`+`ex` dims).
- **Risk.** Low.
- **How to verify.** Push a no-op; confirm cache keys in the Actions logs carry the new dims;
  intentionally corrupt the PLT and confirm the eviction step recovers.

### P1-B — Inbound determinism (retire `--seed 0`) → **root-cause fix in §3.**

### P1-C — CI the release body per-phase → **§5.4.**

### P1-D — `gate-self-test.yml` stale default → **§5.3.**

### P2-A — Supply chain: `:mix_audit`, dependabot siblings, cowlib lifecycle → **§4.**

### P2-B / P3 — Version-matrix policy

- **Current issue.** Single pinned 1.18/OTP-27 everywhere, no matrix. The 1-combo `matrix.include`
  trick is used to keep required check names stable (adding a real row appends ` (1.18, 27)` and
  breaks the required-context match — a real constraint driving current design). `advisory-matrix.yml`
  already exists as the home for extra rows but currently has only the one 1.18/27 row (1.17 was
  removed as never-supported).
- **Proposed change.** Keep the single required lane. Add **one latest-Elixir advisory row**
  (Elixir 1.19 / OTP 28, matching Phoenix/Broadway/Ecto's "latest" row) to `advisory-matrix.yml`
  (`Core Full Suite Advisory`), running on push+cron, `fail-fast: false`, **non-blocking**. Do NOT
  add a min-supported floor row — mailglass declares `elixir: "~> 1.18"`; nothing below 1.18 is a
  supported target, so a floor row would be testing an unclaimed contract (the exact reasoning that
  retired the 1.17 row — REL-06). The `ci-green` gate (§P0-A) makes required-context naming
  independent of matrix suffixes, which *also* frees future required lanes to matrix if ever needed.
- **Why idiomatic.** "latest advisory, non-blocking on a separate lane" mirrors the ecosystem's
  lint-on-newest pattern; declining a floor row below the declared `elixir:` floor matches Livebook's
  single-pinned stance and mailglass's own REL-06 decision.
- **Pros.** Early warning on the next Elixir/OTP before it becomes the required version, at zero PR
  latency (advisory + cron only).
- **Cons.** More CI minutes on main/cron; advisory red is chronic-noise-prone (must stay genuinely
  non-blocking — never wire it into `ci-green`).
- **Impact.** Low-Med (forward-looking).
- **Effort.** Low (one matrix row in the existing advisory workflow).
- **Risk.** Low.
- **How to verify.** Confirm the new row runs on cron, is absent from `ci-green.needs` and from
  `REQUIRED_CHECKS`, and a red on it does not block a PR or the publish `gate-ci-green`.

---

## 3. Determinism — the RIGHT fix for the inbound flake

### Root cause (diagnosed, not the `--seed 0` symptom)

`mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex:101`:
```elixir
setup tags do
  async? = Map.get(tags, :async, true)
  ...
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(repo, shared: not async?)
```
The suite mixes **18 `async: true` files** and **32 `async: false` files** on a **single shared
Postgres `MailglassInbound.TestRepo`**. With `shared: not async?`, every `async: false` test checks
out the sandbox in **shared mode**, which makes its connection **globally visible to all processes**.
When an `async: false` (shared) test runs *concurrently with* any `async: true` (non-shared) test —
which ExUnit will do, because async tests run in parallel with the scheduler's other partitions and
the boundaries between an async module finishing and a sync module starting are not serialized — the
async test can observe or contend on the shared global connection. That is the textbook
**"shared-mode + async collision"** isolation flake: it surfaces as the intermittent
`recv: closed` / duplicate-fingerprint / pool-contention failures the audit noted, and it is
**ordering-sensitive**, which is exactly why pinning `--seed 0` "fixes" it (a fixed order happens to
never interleave a shared checkout with an async one). `Process.sleep` is NOT implicated here — the
inbound test tree has **zero** `Process.sleep` calls (they live in 10 core + 2 admin files, unrelated).

### The fix (root cause)

**You cannot safely mix shared-mode and non-shared checkouts against one repo in one run.** Two
correct options:

**Option A (recommended — make the suite honestly async).** Keep `async: true` files async; ensure
they NEVER need cross-process DB visibility (each test owns its connection). For the tests that DO
need a foreign process to see their writes (the ingress plug broadcasts / worker paths), use
**explicit ownership allowance** instead of shared mode:
```elixir
# in MailboxCase setup, for async tests that spawn a helper process needing the conn:
Ecto.Adapters.SQL.Sandbox.allow(repo, self(), other_pid)
```
and mark ONLY the genuinely-serial tests `async: false`. Critically: **do not let an `async: false`
test check out in shared mode while async tests run.** The clean rule is *either* the whole suite is
`async: false` (serial, shared or not — no collision) *or* every `async: true` test is
self-contained and the few sync ones use `allow/3`, never `shared: true`.

**Option B (lowest-effort, deterministic, keeps parallelism off).** Make the inbound suite fully
serial: default `async: false` in `MailboxCase` and drop `shared:` entirely (plain ownership
checkout). The inbound suite is small; the wall-clock cost is seconds. This removes the collision by
construction and lets you delete `--seed 0`:
```elixir
# mailbox_case.ex
setup _tags do
  repo = Application.get_env(:mailglass_inbound, :repo) || raise ...
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(repo)
  # no shared: — every test owns its own conn, run serially
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.checkin(repo) end)
  ...
end
```
and set `use ExUnit.Case, async: false` in the `__using__` default. Then the CI step becomes plain
`mix test --exclude property` (no `--seed 0`), and the property step stays as-is.

**Recommendation: ship Option B now** (deletes the flake and the `--seed 0` workaround with minimal
risk), and treat Option A as an optional later optimization if inbound test wall-clock ever matters.
Either way the CI change is: **remove `--seed 0` from `ci.yml:320`**, add the Oban retry-idiom as a
belt-and-suspenders (`mix test --exclude property || mix test --failed`).

- **How to verify.** Run the inbound suite 20× with random seeds locally
  (`for i in $(seq 20); do mix test --exclude property --seed $RANDOM || break; done`) — must be
  green every time. Then remove `--seed 0` and confirm CI green across several runs.

### `Process.sleep` sites (10 core + 2 admin files)

Not the inbound flake, but a latent flake class. Audit each site: replace fixed-duration sleeps that
wait for an async condition with **polling / `assert_receive` / telemetry-event `assert_receive`**
(ExUnit's `assert_receive timeout` is the idiomatic replacement for "sleep then assert"). Sleeps that
are genuinely modeling wall-clock (e.g. rate-limit windows) can stay but should use the smallest
viable duration. Track as a P3 sweep, one commit per file, gated by re-running the touched suite 10×.

### Async ratio

The inbound suite is 18 async / 32 sync. After Option B it is fully sync (correct, deterministic).
The core suite's async ratio is out of scope here but the same shared-mode rule applies — audit any
`Sandbox.mode(_, {:shared, ...})` or `shared: true` against async modules on the same repo.

---

## 4. Supply chain

### 4.1 `:mix_audit` (mix_audit / `mix deps.audit`) and Sobelow

- **Current state.** CI runs `mix hex.audit` (retired-package + advisory check via the Hex
  registry). `publish.check` also runs `hex.audit` with the cowlib allowlist. There is **no**
  `:mix_audit` (which reads the community `mix_audit` DB, catches CVEs `hex.audit` can miss and vice
  versa) and **no** Sobelow.
- **Recommendation.**
  - **Add `:mix_audit`** as a dev/test dep and a `mix deps.audit` step in `ci.yml` (advisory or
    required — recommend required for core, since Ash treats it as blocking). It is complementary to
    `hex.audit`: `hex.audit` covers retirements + Hex-published advisories; `mix_audit` covers the
    GitHub-advisory-sourced DB. Running both closes the gap the v1.14 saga exposed (local `hex.audit`
    couldn't see fresh advisories — see 4.3).
  - **Sobelow: SKIP for the libraries.** Sobelow is a Phoenix-*app* security scanner (checks
    router pipelines, CSRF, config secrets); mailglass ships libraries, not an app. The one place it
    could add value is `reference/host_app` / `demo_app`, but those are frozen baselines. Low value,
    high false-positive noise for a lib. Ash runs it because Ash generates app-level code; mailglass
    does not. Revisit only if a shipped app surface appears.
- **Effort.** Low (one dep + one CI step). **Impact.** Medium (defense-in-depth on the exact class
  that paused v1.14). **Risk.** Low.

### 4.2 Dependabot sibling-dir coverage

- **Current issue.** `.github/dependabot.yml` watches only `mix` + `github-actions` at `/`. It does
  **NOT** watch `mailglass_admin/mix.lock` or `mailglass_inbound/mix.lock` — the two sibling locks
  that carried the vulnerable `mint`/`req`/`decimal` versions in the v1.14 wave. Dependabot silently
  ignores those locks today.
- **Proposed change.**
  ```yaml
  version: 2
  updates:
    - package-ecosystem: "mix"
      directory: "/"
      schedule: { interval: "weekly" }
    - package-ecosystem: "mix"
      directory: "/mailglass_admin"
      schedule: { interval: "weekly" }
    - package-ecosystem: "mix"
      directory: "/mailglass_inbound"
      schedule: { interval: "weekly" }
    - package-ecosystem: "github-actions"
      directory: "/"
      schedule: { interval: "weekly" }
  ```
  Do NOT add `reference/host_app` or `reference/demo_app` (frozen baselines — bumping them is the
  coordinated multi-file change).
- **Why idiomatic.** Bandit is the ecosystem precedent for a committed dependabot config; per-package
  `directory:` entries are the documented multi-manifest pattern.
- **Pros.** Sibling-lock CVEs surface as PRs proactively instead of ambushing the publish gate.
  **Cons.** More dependabot PR volume (3 lockfiles); the known `Compile No Optional Deps` dep-cache
  race on stale dependabot branches (documented) will now appear for sibling PRs too — mitigate with
  `gh pr update-branch`. **Effort.** Trivial. **Impact.** Medium. **Risk.** Low.

### 4.3 cowlib-allowlist lifecycle

- **Current state.** `mailglass.publish.check.ex` `@accepted_advisories` allowlists 2 unfixable
  cowlib EEF-CVEs (43966/43969), accepted 2026-06-30, "revisit and remove when upstream ships a fix."
  There is no forcing function to revisit — it will silently outlive its justification.
- **The v1.14 lesson to encode.** Local `mix hex.audit` (hex 2.4.2) **cannot see fresh advisories** —
  only the CI/publish runner has current advisory data. So the allowlist is the ONLY thing standing
  between "clean local publish.check" and "blocked publish gate." Two hardening moves:
  1. **Add a staleness check to `publish.check`**: for each `@accepted_advisories` entry, query OSV
     (`https://api.osv.dev/v1/query`) for the affected package at the locked version and **fail the
     step if a `fixed` event now exists** (i.e., a patch shipped and the allowlist entry is stale).
     This turns "revisit each entry" from a hope into an enforced gate. Guard behind a
     network-available check so offline runs degrade to a warning.
  2. **Add a dated review comment convention + a CI reminder**: the allowlist already carries an
     "Accepted 2026-06-30" date; add a lightweight test asserting no entry is older than, say, 180
     days without a re-affirmation date — forces a human to re-confirm or remove.
- **Also encode the "audit only shows on the runner" fact** in `MAINTAINING.md` /
  release-pipeline thread: **never trust a clean local `publish.check`; a pushed CI run is the only
  authoritative audit.** (This is already learned; make it a written pre-flight step.)
- **Effort.** Low-Med (OSV query + one test). **Impact.** Medium (prevents both stale-allowlist rot
  and the "surprised at the gate" failure mode). **Risk.** Low.

---

## 5. Release-engineering hardening (highest priority)

### 5.1 The inbound-pin trap — see the dedicated §6.

### 5.2 Making green-but-BLOCKED not require admin-merge

Covered by **§P0-A (fan-in gate)** — a single `CI Green` required context reports one clear status,
so a fully-green PR is mergeable without `--admin`. The current 5-context set is what produces the
BLOCKED-despite-green state (branch protection waits on all 5 contexts to *report*, and any naming/
matrix-suffix drift or a never-reported context wedges it). Collapsing to one context removes the
failure mode. Keep `guard-release-trigger` as the only other required check.

### 5.3 `gate-self-test.yml` stale default (concrete fix)

- **Current issue.** `gate-self-test.yml:23` defaults `check_name: "Tests ("`. **No job named
  `Tests (...)` exists** — the canonical required lane is `Support Contract Core (Elixir 1.18 / OTP 27)`.
  A default run of the self-test polls a non-existent check and times out (25 min) → false "gate
  regressed" signal.
- **Fix.** Change the default to the real gate. After §P0-A lands, default to the aggregate:
  ```yaml
  check_name:
    description: "Required-check name prefix to poll"
    type: string
    default: "CI Green"   # was "Tests (" (no such job); pre-fan-in use "Support Contract Core ("
  ```
- **Effort.** Trivial. **Impact.** Low-Med (restores the self-test's usefulness). **Risk.** None.
- **Verify.** Run `gate-self-test.yml` with defaults; the synthetic-failure PR must show the polled
  check FAILURE and report `result=blocked`.

### 5.4 CI the body per-phase, not only at release (the v1.14 root cause)

- **Current issue.** The entire v1.14 body (128 commits) ran only in local phase execution and was
  never pushed/CI'd until the release ceremony, which became the first integration test — surfacing
  7 Operator Browser Gate regressions. Backlog item
  `ui-browser-gate-during-phases-not-only-at-release.md` captures this.
- **Proposed change (process + light tooling).**
  1. **Per-phase push checkpoint.** Each phase (or each wave) pushes to a `phase/NN` branch that
     runs full `ci.yml` (including the Operator Browser Gate, which reproduces locally in ~1.7 min /
     160 tests — the "demo unrunnable in-env" assumption was wrong). Make green CI on the phase branch
     a phase-completion precondition, so regressions are caught by the phase that introduces them.
  2. **Pre-ceremony "first real CI on the body" gate.** Before opening the release ceremony, push the
     assembled body to a staging branch and require a full green `ci.yml` run — so the ceremony is a
     confirmation, not a discovery. This is a `/gsd`-method change, not a workflow change.
  3. Optionally add the Operator Browser Gate to the **required** set (via `ci-green.needs`) once the
     demo-boot-in-env flake is resolved — currently it's advisory (`Operator Browser Gate` is in
     `publish-hex.yml`'s `ADVISORY_LANES`). Promoting it makes UI regressions block PRs.
- **Effort.** Low (process) + Low (promote a lane). **Impact.** High (this was the single largest
  release-ceremony cost source). **Risk.** Med — promoting the browser gate to required re-introduces
  its Docker/Chromium flake risk into the blocking path; only promote after §3-style determinism work
  on that lane, and keep the Oban retry idiom.

### 5.5 Reduce the release-please sed footprint

The 120-line sed-sync step in `release-please.yml` rewrites: sibling `== X.Y.Z` pins (2), inbound
README `~>` pin, core/admin README `~>` pins, inbound install-guide pins, and the publish-summary
JSON. **§6's `~>` change deletes the two `== X.Y.Z` sed rewrites and the associated
`stability_contract` derivations entirely.** The `~>` README pins (major.minor) genuinely need
rewriting only on **minor** bumps, not patches — after §6, a patch release touches zero pin lines,
shrinking the sed step to README-major.minor sync that no-ops on patches. This is the highest-leverage
simplification: it removes the class of "sed anchor drifted / matched zero lines" release-breakers.

---

## 6. LOCKED redesign: the inbound paired-release mechanism

### The trap today (precise mechanics)

`stability_contract_test.exs:150-159` (+ `publish.check` `verify_deps`/`verify_linked_constraint`)
assert the inbound `{:mailglass, "== X"}` pin **equals core's current `@version`**. Core's `@version`
only becomes the new value **inside** the release-please PR (via the sed-sync step). Therefore:

- A standalone `fix(inbound): re-pin == NEW` PR is **inconsistent on its own branch** — core's
  `@version` on main is still OLD, so the contract test fails. (This is what bit the ceremony.)
- The ONLY way it works today is pushing the re-pin **directly to main**, accepting a **transient
  contract-red** on that bare SHA, so release-please folds inbound into the release PR where core's
  `@version` has advanced and the pin is finally consistent. Fragile, undocumented-as-process, and it
  *requires shipping a knowingly-red commit to main*.

### Why the alternatives lose

Research across ecosystems (release-please node/cargo/maven workspace plugins, Rust
cargo-release/release-plz, JS changesets/Lerna/`workspace:` protocol) yields three families:

| Family | Example | Fits mailglass? |
|---|---|---|
| Auto-rewrite the pin in the release PR, operator-preserving | cargo-release `set_comparator`, release-plz, release-please `node-workspace` | **No native Elixir tool exists.** release-please's generic `extra-files` updater always writes the *owning* package's version, never a sibling's — confirmed in `src/updaters/generic.ts`. Would require building a custom `elixir-workspace` plugin. |
| Placeholder resolved at publish | JS `workspace:*` (pnpm substitutes at pack time) | **Hex has no workspace protocol.** Impossible. |
| Loosen the constraint so no per-patch rewrite is needed | Elixir `~> X.Y` (Ash, Phoenix LV, Nx) | **Yes — native, zero tooling, ecosystem-idiomatic.** |

**No surveyed Elixir project pins a sibling with `==`.** Ash uses `{:ash, "~> 3.5 and >= 3.5.13"}`;
phoenix_live_view uses `{:phoenix, "~> 1.6.15 or ~> 1.7.0 or ~> 1.8.0"}`; axon→nx uses `{:nx, "~> 0.10"}`.
The `==` pin is the sole source of the trap and it buys nothing the `linked-versions` plugin +
`~>` don't already give.

### LOCKED recommendation

**Replace the exact pin with the pessimistic operator in BOTH siblings, and drop the standalone
paired-release requirement.**

1. **`mailglass_inbound/mix.exs` `mailglass_dep/0`:**
   ```elixir
   defp mailglass_dep do
     if System.get_env("MIX_PUBLISH") == "true" do
       # Was: {:mailglass, "== 1.10.2"} — the exact pin created the re-pin trap.
       # ~> 1.10 admits any 1.10.x core; the linked-versions plugin keeps core+admin
       # in lockstep, and inbound tracks the same minor line without per-patch re-pinning.
       {:mailglass, "~> 1.10"}
     else
       {:mailglass, path: "..", override: true}
     end
   end
   ```
   Choose the granularity by how tightly inbound couples to core internals:
   - **`~> 1.10`** (`>= 1.10.0 and < 1.11.0`) — recommended default. Any 1.10.x core resolves;
     inbound only needs a release when *it* changes or when it wants a new **minor** floor.
   - **`~> 1.10 and >= 1.10.2`** — if inbound requires a specific bugfix floor (e.g. the V05
     deliveries-migration fix), express it as a floor, not an exact pin. Still no per-patch rewrite.

   Apply the same change to `mailglass_admin` (`{:mailglass, "~> 1.10"}`). Admin is linked to core by
   the `linked-versions` plugin, so its published version always shares core's minor anyway.

2. **Relax `stability_contract_test.exs`** to assert the pin **admits** core's `@version` rather than
   equalling it:
   ```elixir
   # Was: assert pin == "== #{core_version}"
   # Now: the sibling pin's requirement must be satisfied by core @version.
   assert Version.match?(expected_core_version, sibling_requirement),
          "sibling pin #{sibling_requirement} does not admit core @version #{expected_core_version}"
   # And assert it is a ~> (pessimistic) constraint, not == (regression guard):
   assert sibling_requirement =~ ~r/^~>/,
          "sibling pin must be pessimistic (~>), not exact (==) — see §6 of CICD-RELEASE-HARDENING"
   ```
   Update `publish.check` `verify_deps`/`verify_linked_constraint` symmetrically: accept any `~>`
   requirement that `Version.match?`-es core's version; reject `==` and reject a `~>` that excludes
   the current core.

3. **Delete** the two `== X.Y.Z` sed rewrites from `release-please.yml` (the
   `mailglass_admin/mix.exs:mailglass` and `mailglass_inbound/mix.exs:mailglass` PINS entries and the
   summary-JSON `mailglass_inbound_publish_pin` field, which becomes `"~> 1.10"`). Keep only the
   README-`~>`-major.minor sync (which already no-ops on patch releases).

4. **Process change:** inbound no longer *must* release on every core patch. It releases when inbound
   code changes OR when a new core **minor** requires a floor bump. Core+admin patch releases ship
   independently; the published inbound's `~> 1.10` keeps resolving against 1.10.2, 1.10.3, … with no
   action. This eliminates the transient-red-to-main dance entirely.

### Why this is the locked call (reversibility + idiomatic)

- **Reversible:** loosening `==` → `~>` is a non-breaking constraint widening for adopters (a wider
  range can only *admit more* resolutions). If exact lockstep is ever genuinely required, you can
  re-tighten — but every surveyed Elixir maintainer chose `~>`, and the `linked-versions` plugin
  already provides release-time lockstep for core+admin.
- **Deletes the failure mode by construction:** there is no longer a value on the sibling that must
  equal core's not-yet-bumped `@version`, so no bare SHA is ever transiently red, so no direct-to-main
  red-commit dance is needed.
- **Shrinks the release machinery:** removes 2 sed rewrites, ~30 lines of `stability_contract`
  derivation, and the "must land fix(inbound) BEFORE the linked PR merges" ordering rule.

### Optional belt-and-suspenders (only if exact lockstep is later mandated)

If a future decision demands exact `==` lockstep across all three, the correct mechanism is **NOT**
the manual dance but a small **release-please `elixir-workspace` plugin** modeled on `cargo-workspace`
(reads `.release-please-manifest.json`, rewrites the sibling `{:mailglass, "== ..."}` line inside the
release PR atomically with the bump). That's a real engineering task (~a day), justified only if `~>`
proves insufficient. Not recommended now — `~>` is strictly simpler and idiomatic.

**How to verify §6.** (a) `mix deps.get` in both siblings with `MIX_PUBLISH=true` resolves core from
Hex under the `~>` range; (b) the relaxed `stability_contract_test` passes on a bare main SHA where
core `@version` is unchanged (the exact scenario that was red before); (c) a core patch release cut
via release-please produces a PR that touches **zero** sibling pin lines; (d) `publish.check` for all
3 packages passes with the `~>` pins.

---

## 7. Proposed target pipeline shape

| Trigger | Lanes | Blocking? |
|---|---|---|
| **PR** | Required: `format_check`, `compile_warnings`, `compile_no_optional_deps`, `support_contract_core`, `support_contract_admin`, `installer_host_smoke`, `trust_lane_repo_head`, `credo_strict`, `dialyzer` (all fed into **`CI Green`** aggregate). Advisory (non-blocking, reported separately): `operator_browser_gate`, `demo_browser_evidence`, `preview_capture_advisory`. Cache keyed `mix-${os}-otp27-ex1.18-${env}-${lockhash}`. `mix deps.audit` (mix_audit) added as required. | `CI Green` + `guard-release-trigger` are the ONLY required branch-protection contexts |
| **push→main** | Same as PR + `advisory-matrix.yml` (Core Full Suite Advisory + Provider Compatibility, `--exclude requires_workspace`) | Advisory non-blocking |
| **nightly cron** | `advisory-matrix.yml` **+ new latest-Elixir row (1.19/OTP 28)** + `provider-live.yml` (real-provider sandbox) | Advisory only, never blocks |
| **release (release-please PR → auto-merge → tag → publish-hex)** | `prepublish-summary` (publish.check w/ OSV-staleness-checked allowlist) → `gate-ci-green` (gates on the single `CI Green` conclusion of the tagged SHA; keeps anti-recursion self-heal) → `publish-core` → `publish-inbound` → `publish-admin`. Sibling pins are `~>` (no sed re-pin; no paired-inbound-per-patch). | publish gated on `CI Green` green |

### Sequenced adoption (dependency-ordered)

1. **§6 `~>` pins + relaxed contract tests** (P0 — unblocks every future release; independent).
2. **§P0-A `CI Green` fan-in gate + branch-protection collapse to 1 context** (P0 — fixes
   green-but-BLOCKED; also simplifies `gate-ci-green` and `gate-self-test`).
3. **§5.3 `gate-self-test` default fix** (rides on #2).
4. **§3 inbound sandbox fix + drop `--seed 0`** (P1 — independent).
5. **§1 cache-key correctness + PLT eviction** (P1 — precondition for #7).
6. **§4 mix_audit + dependabot siblings + cowlib OSV-staleness** (P2 — independent).
7. **§2 latest-Elixir advisory row** (P2/P3 — after #5 so the cache is toolchain-scoped).
8. **§5.4 per-phase CI-the-body process change** (P1 process — fold into next UI milestone method).

---

## Appendix — key file references

- `.github/workflows/ci.yml` — 21 jobs, single 1.18/27, `${{runner.os}}-mix-${{lockhash}}` cache,
  `--seed 0` at line 320 (inbound_test).
- `.github/workflows/release-please.yml` — sed-sync step (lines 139-263), linked-versions + auto-merge.
- `.github/workflows/publish-hex.yml` — `gate-ci-green` anti-recursion self-heal (lines 115-259),
  `ADVISORY_LANES` classifier.
- `.github/workflows/gate-self-test.yml:23` — stale `"Tests ("` default.
- `.github/workflows/advisory-matrix.yml` — home for the proposed latest-Elixir row.
- `.github/dependabot.yml` — root-only; needs 2 sibling `directory:` entries.
- `lib/mix/tasks/mailglass.publish.check.ex` — `@accepted_advisories` cowlib allowlist (lines 60-65),
  `verify_deps`/`verify_linked_constraint` (assert `== root_version`).
- `test/mailglass/stability_contract_test.exs:150-159` — the `pin == core @version` assertion to relax.
- `mailglass_inbound/mix.exs:137-143` — `mailglass_dep/0` exact pin to loosen; the trap is documented
  in the `defp mailglass_dep` comment (lines 114-136).
- `mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex:101` — `shared: not async?` flake source.
- `scripts/setup_branch_protection.sh:17-22` — the 5 `REQUIRED_CHECKS` to collapse to `CI Green`.
