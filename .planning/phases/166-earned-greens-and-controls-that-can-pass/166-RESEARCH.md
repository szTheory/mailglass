# Phase 166: Earned Greens and Controls That Can Pass - Research

**Researched:** 2026-09-17
**Domain:** CI/CD control integrity — GitHub Actions workflow gates, ExUnit/ExCoveralls test
infrastructure, GitHub API rate-limit handling, Hex advisory allowlist lifecycle.
**Confidence:** HIGH — nearly every load-bearing claim in 166-CONTEXT.md was independently
re-verified this session against the live tree (file reads, greps, and one live `mix test` run).

## Summary

166-CONTEXT.md (411 lines, 38 numbered decisions) already did the hard research work for this
phase and is unusually precise — it cites exact file:line locations for nearly every diff. This
research session's job was to **verify, not re-derive**, and it did: of ~40 spot-checked
file:line claims, all but one cluster held exactly or within 1-3 lines (test-date and doc-comment
drift, immaterial). The one real drift cluster is in **CTRL-01/D-17** (`post-publish-smoke.yml`
line citations `:263-265` and `:285-288` are wrong by 10-133 lines — see Correction 1 below); the
underlying mechanism claims are still correct, just re-locate by content, not by line number.

The single highest-value finding from this session is **new, not a re-verification**: this
research ran the actual widened GREEN-01 test command locally
(`MIX_ENV=test mix test --warnings-as-errors test/` in `mailglass_admin/`) and it passed clean
today — **510 tests, 0 failures, 1 excluded, exit 0** — with **zero compile-time warnings** across
the 32 previously-never-gated test files. CONTEXT.md's D-04 assumes "the first CI run of the
widened lane [will] fail on warnings rather than test outcomes" and instructs the planner to
"budget a warning-cleanup task." That assumption does not hold today (see Correction 2). This
changes PR-1's shape: no warning-cleanup task is needed to make GREEN-01's directory-scoped run
pass; the alias body swap is sufficient for the test-outcome half of GREEN-01, and GREEN-02
(coverage floor) is the only remaining new-code work in that PR.

**Primary recommendation:** Follow 166-CONTEXT.md's decisions and PR slicing (D-37/D-38)
verbatim, with three corrections: (1) re-locate the CTRL-01 edits in `post-publish-smoke.yml` by
content/grep, not by the cited line numbers; (2) drop the warning-cleanup task from PR-1's
estimate — measured zero warnings today, budget only a contingency check, not remediation work;
(3) for CTRL-04's "clock faked to 2026-12-01" acceptance criterion, use an OS-level time-faking
tool (`faketime`/libfaketime) to run the real `mix mailglass.audit --kind hex` binary unmodified —
do not add an in-process `--today` flag (D-32 already forbids this; this research supplies the
concrete mechanism).

## Architectural Responsibility Map

This phase is CI/control-plane work, not application-tier work — the "capabilities" here are
control mechanisms, not user-facing features.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Admin test execution truth (GREEN-01) | CI / Build | Mix (`mailglass_admin/mix.exs`) | Alias body lives in package mix.exs; CI just invokes it by name |
| Coverage floor enforcement (GREEN-02) | CI / Build | Mix + shell script | Mirrors existing `scripts/check_coverage_floor.sh` pattern |
| Suite-floor anti-vacuity (GREEN-03) | Test harness (ExUnit) | CI workflow env | `test/support/suite_floor.ex` reads env; `ci.yml` sets it |
| Demo Hex-pin proof (GREEN-04) | CI / Build | — | New isolated job/step; no app-tier change |
| Cache isolation proof (GREEN-05) | CI / Build (GitHub Actions cache) | — | External to app code entirely — `actions/cache` internals |
| Release schedule/dispatch resolution (CTRL-01) | CI / Release automation | `scripts/release_policy.exs` (Mix task, runtime shared with app) | Reuses existing exact-Hex-checksum proof code |
| Release-please rate-limit handling (CTRL-02/03) | CI / GitHub Actions workflow | GitHub REST API (external) | Bash + `gh api` + the vendored `release-please-action` |
| Hex advisory allowlist (CTRL-04) | Database/Storage-adjacent (data-only lib/ constant) | Mix task (`dev/mix/tasks/mailglass.audit.ex`) | D-31: explicit lib/ exemption, data fields only |
| Repo hygiene control (CTRL-05) | CI / Mix task | GitHub API (`gh pr list`) | `dev/mix/tasks/mailglass.repo.hygiene.ex` |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GREEN-01 | Full admin suite executes in CI (≥510 tests, 0 failures) | Verified locally: 510/0/1-excluded, exit 0, **zero compile warnings today** — see Correction 2 |
| GREEN-02 | Admin coverage floor enforced | ExCoveralls wiring pattern verified against `mailglass_inbound/mix.exs:22,129` and `scripts/check_coverage_floor.sh`; no `coveralls.json` config file exists anywhere in repo — none needed for admin either |
| GREEN-03 | `core_deterministic_suite` prints FULL SUITE floor | `test/support/suite_floor.ex` and `lane_classification_drift_test.exs` constants verified exact; `ci.yml:446-452` confirmed to lack `MAILGLASS_SUITE_FLOOR` today |
| GREEN-04 | Demo app exercises Hex pins in a CI lane | Confirmed `MAILGLASS_DEMO_DEPS` appears nowhere in `ci.yml` today; `reference/demo_app/mix.exs:60-76` dep-swap and `mix.lock` hex entries verified present |
| GREEN-05 | Trust-lane cache pollution resolved/refuted in writing | Confirmed both trust lanes cache `path: deps` only (no `reference/host_app/deps`); `actions/cache` version-hash-by-path-list mechanism confirmed via GitHub Actions cache internals (see below) |
| CTRL-01 | `post-publish-smoke` can pass on schedule between releases | Read full workflow; confirmed the `command="authorized-versions"` / `completed-versions` branch and the cron-guard JS gate exist, but at different line numbers than CONTEXT.md cites — see Correction 1 |
| CTRL-02 | No redundant re-run against already-tagged SHA | Confirmed dead `elif` branch and `Merge pull request #N` / `autorelease: tagged` skip both exist as described |
| CTRL-03 | Transient GitHub API failure retried, not reported as failure | Confirmed via GitHub's own rate-limit docs (WebSearch, this session) — 403/429 classification, `retry-after` priority, 60s floor, banning risk for continued requests |
| CTRL-04 | Hex Audit advisories re-verified before 2026-10-26 expiry | Confirmed `@entries`, `recheck_by` at exact lines 73/88, `expired_entries/1`/`unused_entries/1` at 189-202, test hardcodes at lines 156/160/169/178 (test at :169 currently asserts the negation of the target acceptance criterion — must move in lockstep, matches D-33) |
| CTRL-05 | `repo-hygiene` distinguishes non-verdict from alarm, predicate fixed | Confirmed exit-code collapse at line 47, PR field list missing `createdAt`/`statusCheckRollup` at line 287, `Enum.empty?(prs)` predicate at line 295 |
</phase_requirements>

## Corrections to 166-CONTEXT.md (verified this session)

### Correction 1 — CTRL-01/D-17 line citations in `post-publish-smoke.yml` are stale

D-17 cites `post-publish-smoke.yml:263-265` for "the schedule path is unreachable today,
hard-branched on `EVENT_NAME` (chooses `completed-versions` only for `schedule`)" and `:285-288`
for the cron-guard predicate to widen. **Verified against the live file (891 lines):**

- The actual `EVENT_NAME`-branched command selection is at **lines 129-130**:
  ```bash
  command="authorized-versions"
  if [ "$EVENT_NAME" = "schedule" ]; then command="completed-versions"; fi
  ```
  `[VERIFIED: .github/workflows/post-publish-smoke.yml:129-130]` — quoted verbatim above.
  Lines 263-265 are actually the `cron-guard:` job header (`name`, `runs-on`) — unrelated content.

- The actual cron-guard schedule predicate to widen (`COMPLETED || BASELINE`) is at **line 296**:
  ```js
  if (eventName === 'schedule' && process.env.COMPLETED !== 'true') {
  ```
  `[VERIFIED: .github/workflows/post-publish-smoke.yml:296]` — quoted verbatim above. D-17 cited
  `:285-288`, which is 8-11 lines off.

- D-17's other citations verified as accurate: dispatch inputs `required: true` at lines 15-30
  `[VERIFIED: .github/workflows/post-publish-smoke.yml:15-30]`, and the 40-hex fail-closed guard
  at lines 73-77 (`if ! [[ "$INPUT_TARGET_REF" =~ ^[0-9a-f]{40}$ ]]; then ... exit 1; fi`)
  `[VERIFIED: .github/workflows/post-publish-smoke.yml:73-77]` — one line short of the cited `:78`
  but the same block.

**Planner action:** when writing PR-5's CTRL-01 task, locate the edit points by `grep -n
'command="authorized-versions"'` and `grep -n "eventName === 'schedule' && process.env.COMPLETED"`
rather than trusting the CONTEXT.md line numbers. The four-edit shape D-17 describes (a
`baseline-versions` resolution verb; a new `workflow_dispatch` mode input; a `baseline=true`
signal widening the schedule branch to `COMPLETED || BASELINE`; a baseline-mode target check that
skips the `publishable_content.digest` requirement) is otherwise sound and matches the file's
actual control flow — only the line numbers were wrong.

### Correction 2 — D-04's warning-cleanup task is not needed (measured, not asserted)

D-04 states: *"the other 32 files' compile warnings have never been fatal anywhere... the plan
must budget a warning-cleanup task over admin test files before the lane can be green. Expect the
first CI run of the widened lane to fail on warnings rather than test outcomes."*

**This was measured directly this session and refuted.** Running the exact widened command
locally with the pinned toolchain (`ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`):

```
$ MIX_ENV=test mix test --warnings-as-errors test/
Finished in 3.7 seconds (1.8s async, 1.9s sync)
510 tests, 0 failures, 1 excluded
```
`[VERIFIED: local mix test run, 2026-09-17, mailglass_admin/, seed 681510]`

Exit code 0, no `ERROR! Test suite aborted ... due to warnings` message. A sanity probe confirmed
`--warnings-as-errors` *does* work — deliberately injecting an unused-variable warning into
`router_test.exs` and re-running produced the expected `ERROR! Test suite aborted after
successful execution due to warnings while using the --warnings-as-errors option`
`[VERIFIED: local mix test run, deliberately-injected warning, reverted after]`. So the flag is
live; there are simply zero compile-time warnings to catch across the 32 files today.

The warnings CONTEXT.md's authors likely anticipated **are runtime warnings, not compile
warnings**, and `--warnings-as-errors` never catches them:
- `Detected a form with phx-change but missing id` — a `Phoenix.LiveViewTest` runtime logger
  warning from `voice_test.exs:35,59` and `preview_live_test.exs` (11 occurrences), governed by
  `config :phoenix_live_view, :test_warnings` — not the Elixir compiler.
- `:aliases option in eval is deprecated` / `:requires option` / `:functions option` — runtime
  deprecation warnings from `Code.eval_quoted/3`, triggered by `mix_config_test.exs:82`'s use of
  `Code.eval_quoted` — also not compiler warnings.

Neither class is a compile-time warning, so neither is caught by `mix test --warnings-as-errors`
(which only fails the build on compiler warnings, exercised and confirmed above). These are
pre-existing, non-fatal, and out of scope for GREEN-01's acceptance criterion (which is about test
*count* and *failures*, not runtime log noise).

**Planner action:** Do not size a warning-cleanup task into PR-1. Budget instead a single
verification step — "run the widened alias locally before merging PR-1 and confirm 0 failures" —
which this research has already done once. If a *future* CI run (different seed, different
toolchain patch) surfaces a genuine new compile warning, fix it in the test file directly (D-04's
"never by relaxing the flag" instruction still applies) — but do not pre-allocate cleanup effort
for a problem that does not currently exist.

## Standard Stack

No new external dependencies for GREEN-01/03/04/05 or any CTRL requirement — all are CI
workflow / Mix alias / Elixir module changes using tooling already in the repo. GREEN-02 adds one
dependency to one package.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `excoveralls` | `~> 0.18` | Coverage reporting, mirrored into `mailglass_admin` | `[VERIFIED: mailglass_inbound/mix.exs:22,129]` — identical pin already used by core (`mix.exs:34,183`, `~> 0.18`) and inbound. Not a new library choice — literally the same dep the sibling packages already carry. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `faketime` (libfaketime) | any recent (e.g. Debian `faketime` package, or `brew install libfaketime` locally) | Run `mix mailglass.audit --kind hex` under a spoofed system clock for CTRL-04's "faked to 2026-12-01" acceptance proof, without any in-process `--today` flag | CTRL-04 verification step only — not a runtime dependency of any package `[ASSUMED]` — well-known Unix LD_PRELOAD tool for this exact use case, not previously used in this repo; verify installability in the CI runner image (`apt-get install -y faketime` on `ubuntu-latest`) before committing to it in a workflow step. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `faketime` for CTRL-04 clock proof | A local Docker container with `--net=none` and hardware clock override, or a script that manipulates `TZ`/system date | `faketime` is lower-friction (no container, no root date change) and is the documented approach for "run this one command under a different apparent date" without root; system-date changes are riskier in a shared runner and require sudo. |
| ExCoveralls admin wiring as a separate `coveralls.json` config file | Command-line flags only (`mix coveralls.json --output-dir coverage/admin test/`) | Core and inbound use **no `coveralls.json` config file anywhere in the repo** `[VERIFIED: grep across mix.exs/inbound/ci.yml — no coveralls.json file found]` — admin should follow the same command-line-only pattern for consistency, not introduce a new config-file convention. |

**Installation:**
```bash
# mailglass_admin/mix.exs — add to deps(), test-only, mirroring inbound
{:excoveralls, "~> 0.18", only: [:test]}
```

**Version verification:** `excoveralls ~> 0.18` is already resolved and locked in both
`mix.lock` (core) and `mailglass_inbound/mix.lock` — no new registry lookup needed; this is an
internal mirror of an already-vetted, already-in-use dependency, not a new external package.
`[VERIFIED: mix.lock, mailglass_inbound/mix.lock — both contain excoveralls entries]`

## Package Legitimacy Audit

No new *external* package is introduced by this phase — `excoveralls` is already vetted,
in-repo, and used by two of the three sibling packages at the exact same version constraint. The
Package Legitimacy Gate does not apply (no new registry lookup, no new supply-chain surface).
`faketime` is a system package (`apt`/`brew`), not a Hex/npm dependency, and is a CI-verification
tool only, never shipped in any package's `mix.lock`.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| excoveralls | Hex | Already in use (core + inbound) | N/A — internal mirror | github.com/parroty/excoveralls | OK | Approved — same version already locked elsewhere in this repo |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram

```
git push / PR event
        │
        ▼
┌────────────────────┐     ┌──────────────────────────┐
│  ci.yml (required)  │────▶│ Support Contract Admin   │──▶ mix.exs verify.support_contract.admin
│  Core Deterministic │     │  (GREEN-01/02: widen to  │      (redefined alias body, D-01/D-02)
│  Suite (GREEN-03)   │     │   directory-scoped run + │
│                      │     │   coverage floor)        │
└────────────────────┘     └──────────────────────────┘
        │
        ▼
  MAILGLASS_SUITE_FLOOR=1 env
        │
        ▼
  test/support/suite_floor.ex ── reads env, enforces
  @executed_floors / @skipped_ceiling / :already_shared==0
        │
        ▼
  lane_classification_drift_test.exs ── asserts the env
  entry's OCCURRENCE COUNT in ci.yml (new guard, D-08)


release-please.yml (push/schedule)
        │
        ▼
  proposal-mode preflight ── CANDIDATE_DIGEST empty?
        │                         │
        │ yes (push, no digest)   │ no (protected dispatch)
        ▼                         ▼
  early exit (CTRL-02 removes    expected_tags_text branch
  this early return so the       (unrelated to CTRL-02)
  dead already-tagged-SHA
  skip below becomes reachable)
        │
        ▼
  gh api tag-exists checks (:119, retry+classify, CTRL-03)
        │
        ▼
  Merge PR # parse + `autorelease: tagged` label check
  (:145-167) ── skip re-run if already tagged
        │
        ▼
  googleapis/release-please-action step (the ONE
  non-continue-on-error API call; CTRL-03 wraps it in
  continue-on-error + one guarded backoff re-run)
        │
        ▼
  gate: [ RESULT_STATUS = pass ] || { pending && no_open_proposal }
  (D-21: byte-for-byte unchanged — cannot-check never passes)


post-publish-smoke.yml (schedule / workflow_dispatch)
        │
        ▼
  resolve-completed-target job
        │
        ├─ EVENT_NAME=schedule ──▶ command=completed-versions
        │                          reads .planning/release-target.json
        │                          status=="inactive" today ──▶ FAILS
        │                          (CTRL-01: add baseline-versions verb
        │                           that succeeds here using `baselines`
        │                           + historical_tag_sha)
        │
        └─ EVENT_NAME=workflow_dispatch ──▶ command=authorized-versions
                                             (unaffected by CTRL-01)
        │
        ▼
  cron-guard job ── widen schedule branch to accept
  baseline=true OR completed=true (never reuse completed=true
  for an inactive ledger — D-17 item 3)
        │
        ▼
  downstream jobs (wait-for-index, consumer-install, ...)
  run against the historical published baseline
```

### Recommended Project Structure

No new directories. All work lands in existing locations:
```
mailglass_admin/
├── mix.exs                          # D-01/D-02/D-04/D-05: alias body + ExCoveralls dep
├── mix.lock                         # D-05: new excoveralls entry (clean, intentional)
└── test/mailglass_admin/            # unchanged file set — the same 41 test files, just all run

config/coverage_baselines/
├── core.json                        # existing — shape to mirror
└── admin.json                       # NEW — GREEN-02, measured triple + report_sha256

test/support/suite_floor.ex          # unchanged code, MAILGLASS_SUITE_FLOOR now actually set
test/scripts/lane_classification_drift_test.exs  # extended: new @ci_yml_suite_floor_occurrences

.github/workflows/
├── ci.yml                           # GREEN-02 coverage step, GREEN-03 env line, GREEN-04 new isolated demo build step
├── post-publish-smoke.yml           # CTRL-01: baseline-versions verb + mode input + cron-guard widen
├── release-please.yml               # CTRL-02/03: restore preflight skip + retry/backoff
└── repo-hygiene.yml                 # unchanged (D-36) — logic lives in the Mix task

lib/mailglass/supply_chain/accepted_advisories.ex  # CTRL-04: data-only reason/recheck_by edit (D-31 exemption)
dev/mix/tasks/mailglass.repo.hygiene.ex            # CTRL-05: exit-code split + predicate widen
```

### Pattern 1: Alias-name-matched parity (reuse, no new pattern)
**What:** `test/scripts/ci_parity_drift_test.exs` asserts CI invokes lanes by **alias name**, not
by inspecting the alias body.
**When to use:** Any time a lane's underlying implementation changes but its name/contract stays
stable — redefine the alias body freely without touching the CI workflow or the parity test.
**Example:**
```elixir
# Source: test/scripts/ci_parity_drift_test.exs:184 [VERIFIED]
"Support Contract Admin (Elixir 1.18 / OTP 27)" => ["verify.support_contract.admin"],
```
This is why GREEN-01's fix requires zero `ci.yml` edits (confirmed: `ci.yml:916-917` invocation
`cd mailglass_admin && mix verify.support_contract.admin` needs no change).

### Pattern 2: Measured-ratchet coverage floor (reuse, no new pattern)
**What:** A coverage baseline is a measured JSON triple (`covered_lines`, `relevant_lines`,
`percentage`) plus `report_sha256` and an exact-toolchain string, never a hand-picked percentage.
**When to use:** GREEN-02's `config/coverage_baselines/admin.json`.
**Example:**
```json
// Source: config/coverage_baselines/core.json [VERIFIED — quoted verbatim]
{
  "package": "mailglass",
  "cohort": "test/mailglass",
  "covered_lines": 5357,
  "relevant_lines": 8469,
  "percentage": 63.254221,
  "toolchain": "1.18.4/27",
  "image": "hexpm/elixir:1.18.4-erlang-27.3.4-debian-bookworm-20250520-slim",
  "command": "make toolchain CMD='mix coveralls.json test/mailglass --warnings-as-errors'",
  "report_sha256": "c5ca06e889aba2d0db8be79103e7f98db7c7fb9eb8b3d0b12e4f72b5df49ffc0",
  "measured_at": "2026-08-17"
}
```
Admin's baseline must be measured from a green run of the **widened** 510-test suite (D-06) —
generate it in the same PR that widens the alias, not before.

### Pattern 3: Occurrence-count drift guard (reuse, extend — D-08)
**What:** A constant pins how many times a load-bearing string appears in a specific file, with
an anti-vacuity test (file is non-empty and contains the string) and a negative control (deleting
one occurrence changes the count).
**When to use:** GREEN-03's second half — guarding `MAILGLASS_SUITE_FLOOR: "1"` in `ci.yml` the
same way `@suite_floor_env_occurrences` already guards it in `advisory-matrix.yml`.
**Example:**
```elixir
# Source: test/scripts/lane_classification_drift_test.exs:43-56 [VERIFIED — quoted verbatim]
@advisory_matrix_path Path.join(@repo_root, ".github/workflows/advisory-matrix.yml")
@suite_floor_env_entry ~s(MAILGLASS_SUITE_FLOOR: "1")
@suite_floor_env_occurrences 2
```
Mirror this trio with a new `@ci_yml_path`, and a new `@ci_yml_suite_floor_occurrences 1` constant
(one occurrence — the single `core_deterministic_suite` step), plus its own anti-vacuity +
negative-control test pair.

### Anti-Patterns to Avoid
- **Bumping `@suite_floor_env_occurrences` from 2 to 3:** `[VERIFIED]` this constant counts
  occurrences in `advisory-matrix.yml` only (default `@advisory_matrix_path`); adding the env line
  to `ci.yml` does not change that count. A bare 2→3 bump makes the *existing* test assert a false
  count against the unchanged file and turns it red. This is the roadmap instruction D-07
  explicitly flags as wrong.
- **Adding a `--today` override to `mix mailglass.audit`:** would ship a maintainer-settable
  expiry bypass — exactly the class of gate-weakening this milestone's standing prohibition names.
  Use OS-level time faking instead (see Correction 2 / CTRL-04 section below).
- **Pointing `verify.support_contract.admin` at `verify.preview`:** `verify.preview` runs
  `mailglass_admin.assets.build` + `git diff --exit-code priv/static/` — a Tailwind/daisyUI
  rebuild that is a documented landmine (Token-parity bundle memory: a fresh build emits raw
  daisyUI theme blocks that break `token_parity_test`). This would red the lane on unrelated
  asset drift. D-01 already rejects this; confirmed correct by reading both aliases.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Coverage floor enforcement | A new percentage-threshold script for admin | `scripts/check_coverage_floor.sh` (already generic — takes baseline path, report path, toolchain string as args) | It already exists, is toolchain-pinned, and enforces the full measured triple, not just percentage. Zero new code needed beyond the CI step + baseline JSON. |
| GitHub API retry/backoff | A custom polling loop with fixed sleep | GitHub's documented `retry-after` → `x-ratelimit-reset` (only if remaining==0) → 60s-floor fallback, escalating ×2 per failure, 3 attempts max | This is GitHub's own prescribed algorithm (confirmed via WebSearch this session against current docs). A naive fixed-delay loop either under-waits (still gets 403'd) or over-waits (slows every push unnecessarily). |
| Clock faking for CTRL-04 proof | An in-process `--today` CLI flag on `mix mailglass.audit` | OS-level `faketime` wrapping the real binary | D-32 explicitly forbids an in-process override (it's a maintainer-settable expiry bypass — the exact gate-weakening this milestone prohibits). `faketime` proves the real code path, unmodified, under a spoofed clock, at the OS/libc level — no application code changes at all. |
| Suite-floor drift detection | A YAML parser for `ci.yml` | The existing string-occurrence-counting technique (`String.split(source, entry) |> length() - 1`) | Matches the established pattern exactly (D-08); a real YAML parser is unnecessary complexity for "does this exact string appear N times." |

**Key insight:** Every one of this phase's ten requirements is solvable by extending an existing,
already-battle-tested mechanism in this codebase (measured-ratchet baselines, occurrence-count
guards, classify-then-gate evidence handling, alias-name-matched parity) rather than inventing a
new one. The research risk in this phase is not "what pattern to use" — CONTEXT.md already
answered that — it is "does the existing evidence still match the live tree," which this session
spent its budget verifying.

## Common Pitfalls

### Pitfall 1: Assuming the widened admin lane will surface compile warnings
**What goes wrong:** Sizing a warning-cleanup task into PR-1 that turns out to be unnecessary,
inflating scope inside a 5-day hard timebox.
**Why it happens:** `--warnings-as-errors` was previously scoped to only 9 files, so nobody had
looked at whether the other 32 carry compile warnings — a reasonable worst-case assumption to
make without measuring.
**How to avoid:** Measured this session — 0 compile warnings, 510/0/1-excluded, exit 0. Trust the
measurement over the assumption.
**Warning signs:** If a *future* CI run does fail on warnings (e.g., after other phase work adds
new admin test files), the fix is a normal one-file edit in the offending test file — not a
reason to relax `--warnings-as-errors`.

### Pitfall 2: Trusting stale line-number citations without re-locating by content
**What goes wrong:** Editing the wrong lines in `post-publish-smoke.yml` (e.g., editing job
metadata at :263-265 when the actual command-selection logic is at :129-130), silently no-op'ing
the intended fix while CI still reports success on unrelated lines.
**Why it happens:** CONTEXT.md's citations are precise for ~95% of the file but drifted for this
one file — likely because the citations were gathered before a subsequent edit shifted line
numbers, or because two similar-shaped `if [ "$EVENT_NAME" = ... ]` branches exist in the file and
got conflated.
**How to avoid:** `grep -n` for the literal string being changed (`command="authorized-versions"`,
`eventName === 'schedule' && process.env.COMPLETED`) before editing, every time — regardless of
what line number a planning document cites.
**Warning signs:** A diff that doesn't touch the code you expected it to touch, or a test that
still fails after the "fix" lands.

### Pitfall 3: `unused_entries/1` and `expired_entries/1` interact — editing recheck_by without moving test dates
**What goes wrong:** Bumping `recheck_by` from `~D[2026-10-26]` to `~D[2027-03-17]` (D-30) without
also rewriting `test/mailglass/supply_chain/accepted_advisories_test.exs` lines 156/160/169/178
produces a deterministic core-suite red — the test at line ~169 currently asserts **both entries
ARE expired at `~D[2026-12-01]`**, which becomes false the moment `recheck_by` moves past that
date.
**Why it happens:** This is the Phase 125 pin-drift shape (D-33 names it as the third occurrence)
— a literal value asserted verbatim by a test, split across two files.
**How to avoid:** Land both files in the same commit. Verified this session: the four hardcoded
dates (`2026-10-26`, `2026-10-27`, `2026-12-01`, `2026-07-28`) are at test file lines 156, 160,
169, 178 respectively — `[VERIFIED: test/mailglass/supply_chain/accepted_advisories_test.exs:156,160,169,178]`.
**Warning signs:** `mix test test/mailglass/supply_chain/accepted_advisories_test.exs` red
immediately after an `accepted_advisories.ex` edit and nothing else.

### Pitfall 4: GitHub secondary rate limits give no pre-flight signal
**What goes wrong:** Building a "check if we're rate-limited before calling" probe (D-24
explicitly forbids this).
**Why it happens:** Intuitive to want to avoid a failed call rather than retry after one, but
GitHub's primary `x-ratelimit-*` buckets read full even during an active secondary-limit 403 (the
documented reason all 15 buckets read full in this repo's own evidence) — there is no header or
endpoint that reports secondary-limit status ahead of time.
**How to avoid:** Classify on the response (403/429 + body regex `/secondary rate/i`), never
pre-check. Unconditional timed waiting after a classified failure is the only correct mechanism
per GitHub's own guidance (confirmed via WebSearch this session).
**Warning signs:** A new workflow step that calls the rate-limit API before doing real work — this
is itself an extra API call that counts against the same budget it's trying to protect.

## Code Examples

### GREEN-03: mirroring the ci.yml suite-floor env line
```yaml
# Source: .github/workflows/ci.yml:444-452 [VERIFIED — quoted verbatim, current state]
      - name: Run deterministic core suite
        # Full root suite: no directory filter, exclusions, fixed seed, or
        # advisory continuation. Suite-floor and skip-ledger contracts run as
        # part of this invocation and reject silent scope erosion.
        id: deterministic-core
        env:
          MAILGLASS_TIMEOUT_EVIDENCE_PATH: tmp/timeout-evidence/database.ndjson
          MAILGLASS_TIMEOUT_EVIDENCE_COMMAND: mix test --warnings-as-errors
        run: mix test --warnings-as-errors
```
Add `MAILGLASS_SUITE_FLOOR: "1"` to the `env:` block above (D-09: this is expected to pass on
today's numbers with no re-pinning — floors are 1576/1575, `@skipped_ceiling` is 7, matching the
measured values `[VERIFIED: test/support/suite_floor.ex:286-289 (@executed_floors), :307
(@skipped_ceiling 7)]`).

### GREEN-02: the coverage-floor step pattern to mirror
```yaml
# Source: .github/workflows/ci.yml:292-296 [VERIFIED — quoted verbatim]
      - name: Collect and enforce core coverage floor
        run: |
          mix coveralls.json --output-dir coverage/core test/mailglass --warnings-as-errors
          bash scripts/check_coverage_floor.sh config/coverage_baselines/core.json coverage/core/excoveralls.json 1.18.4/27
```
The admin equivalent (new CI step, runs inside `mailglass_admin/`):
```yaml
      - name: Collect and enforce admin coverage floor
        working-directory: mailglass_admin
        run: |
          mix coveralls.json --output-dir ../coverage/admin test/ --warnings-as-errors
          bash ../scripts/check_coverage_floor.sh ../config/coverage_baselines/admin.json ../coverage/admin/excoveralls.json 1.18.4/27
```
(Path adjustments are illustrative — verify actual relative paths when writing the PLAN, since
`mailglass_admin/` is a sibling package with its own `mix.exs` working directory in CI.)

### CTRL-04: OS-level clock faking for the audit proof (new mechanism this research supplies)
```bash
# Not present in this repo today — proposed verification mechanism.
# Debian/Ubuntu runner:
sudo apt-get install -y faketime
faketime '2026-12-01 00:00:00' mix mailglass.audit --kind hex
```
This runs the real, unmodified `dev/mix/tasks/mailglass.audit.ex` binary with `Date.utc_today()`
(and any other OS clock read) resolving to 2026-12-01, satisfying the acceptance criterion without
adding a `--today` flag or any other in-process override. `[ASSUMED]` — `faketime` itself is a
well-known LD_PRELOAD tool; its installability inside the `ubuntu-latest` GitHub Actions runner
image was not verified this session (network-restricted sandbox) and should be confirmed as a
`checkpoint:human-verify` or a cheap CI dry-run before being relied upon in the actual PR.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| 9-file hand-enumerated admin test allowlist | Directory-scoped `test --warnings-as-errors` run | This phase (GREEN-01) | 325 previously-never-executed tests join CI; all pass today (measured) |
| `advisory-matrix.yml`-only suite-floor guard | Same guard extended to `ci.yml`'s required lane | This phase (GREEN-03) | The required lane, not just the advisory lane, now rejects silent scope erosion |
| `octokit`/`actions/github-script` default retry (403 in `doNotRetry`, quadratic 1s/4s/9s, all <14s) | A project-specific outer retry loop with a 60s floor and escalating ×2 backoff | This phase (CTRL-02/03) | The only retry shape that actually respects GitHub's documented secondary-limit floor; the vendored `release-please-action`'s own retry logic is confirmed insufficient (D-23) |

**Deprecated/outdated:**
- The `:reason` text "no upstream fix as of cowlib 2.19.0" on both accepted-advisory entries is
  now stale (the tree is on cowlib 2.20.0, and upstream has permanently declined the fix on
  principle rather than merely "not yet fixed") — CTRL-04 replaces this with the permanent-refusal
  framing D-29 drafts.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `faketime` (or equivalent libfaketime-based tool) installs cleanly on the `ubuntu-latest` GitHub Actions runner image via `apt-get install -y faketime` | Code Examples / CTRL-04 | Low-medium: if unavailable, the fallback is a local-only verification (`faketime` on the maintainer's macOS/Linux dev machine via `brew install libfaketime`) plus a rewritten unit test at the new dates — CTRL-04's acceptance criterion can still be demonstrated without a CI step, since the criterion says "clock faked to 2026-12-01" not "verified in CI." |
| A2 | CONTEXT.md's D-26/D-27's cited upstream facts (OSV re-confirmation dated 2026-09-09, ninenines/cowlib PR closures, the maintainer's security-strategy article) are accurate | Common Pitfalls / CTRL-04 | These dates are in this session's near-future and could not be independently re-fetched this session (no network fetch attempted for forward-dated web content); treat as carried forward from the prior research session's verification, not re-verified here. If wrong, CTRL-04's drafted `:reason` text (D-29) would need revision, but the mechanical fix (recheck_by bump + test lockstep) is unaffected. |

**All other claims in this research were verified this session against the live tree** (file
reads, greps with exact line numbers, or a live `mix test` run) — no additional confirmation
needed for those.

## Open Questions

1. **Does `faketime` work correctly with BEAM/Erlang's clock reads?**
   - What we know: `faketime` uses `LD_PRELOAD` to intercept libc time syscalls; Erlang's VM
     sometimes reads time via lower-level syscalls that bypass libc interception on some
     platforms/versions.
   - What's unclear: whether `Date.utc_today()` (which ultimately calls `:calendar.universal_time/0`
     or similar BEAM primitives) respects a `faketime`-spoofed clock on the OTP 27 build used in
     CI, or whether it reads the kernel clock directly.
   - Recommendation: verify with a one-line local smoke test — `faketime '2026-12-01 00:00:00'
     elixir -e 'IO.inspect(Date.utc_today())'` — before committing to this mechanism in the actual
     plan. If it does not respect the fake, the fallback is a rewritten test asserting
     `expired_entries(~D[2026-12-01])` returns `[]` (proving the *logic* is correct post-bump)
     plus a real un-faked `mix mailglass.audit --kind hex` run (proving the *current* date passes)
     — together satisfying the spirit of the acceptance criterion without a literal system-clock
     fake.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir 1.18.4 / OTP 27 (pinned via asdf) | All requirements — exact-toolchain assertions throughout | ✓ (after exporting `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`) | 1.18.4 / Erlang/OTP 27 [erts-15.2.7.11] | None needed — confirmed installed and working this session |
| PostgreSQL (for admin/core test suites) | GREEN-01/02/03 local verification | Not probed this session (the widened admin run that was executed did not require DB — no test in the 510 hit a DB-dependent path in the seed run) | — | If DB-dependent tests are added later, standard `pg_isready` + `mix ecto.create` pattern already used throughout `ci.yml` applies |
| `faketime` / libfaketime | CTRL-04 clock-fake proof | Not verified this session (sandboxed, no `apt-get`/`brew` attempted) | — | See Open Question 1 — fallback is date-boundary unit test + real-date audit run |
| `gh` CLI | CTRL-02/03/05 verification (workflow inspection, PR queries) | Not directly exercised this session (workflow files read via `Read`/`grep`, not `gh api`) | — | None needed for planning; execution phase will need `gh` for live verification, already used throughout the existing CI workflows |

**Missing dependencies with no fallback:** none identified.

**Missing dependencies with fallback:** `faketime` (see Open Question 1).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (all three packages), ExCoveralls for coverage reporting |
| Config file | Per-package `test/test_helper.exs` — no central config file |
| Quick run command | `cd mailglass_admin && MIX_ENV=test mix test --warnings-as-errors test/` (verified this session: 3.7s, 510 tests) |
| Full suite command | `mix ci` (root) fans out to `verify.support_contract.core`, admin, inbound |

### Phase Requirements → Test Map

Most of this phase's acceptance criteria are **CI-signal observations**, not unit-testable
behaviors — the "test" for a requirement is often "does the named CI job/log report X," which
this table makes explicit rather than hand-waving into an automated command that doesn't exist.

| Req ID | Behavior | Test Type | Automated Command | Locally Verifiable? |
|--------|----------|-----------|-------------------|---------------------|
| GREEN-01 | Admin lane runs ≥510 tests, 0 failures | integration (full suite) | `cd mailglass_admin && mix test --warnings-as-errors test/` | ✅ — verified this session |
| GREEN-02 | Admin coverage floor fails on regression | unit + script | `mix coveralls.json ... && bash scripts/check_coverage_floor.sh ...` then deliberately lower a covered-line count to prove the floor fires | ✅ — script logic is generic and testable locally; the "fails when it should" half needs a deliberate regression drill |
| GREEN-03 | `core_deterministic_suite` log line changes | integration (log-text assertion) + unit (`lane_classification_drift_test.exs`) | `MAILGLASS_SUITE_FLOOR=1 mix test --warnings-as-errors` (per D-10, run this unfiltered locally first) | ✅ — D-10 explicitly recommends this before pushing |
| GREEN-04 | A CI lane resolves Hex deps for the demo | integration | `MAILGLASS_DEMO_DEPS=hex mix deps.get --check-locked && mix compile` in `reference/demo_app/` | ✅ — fully local, per D-12 no lock edit needed |
| GREEN-05 | Cache keys/paths don't cross-contaminate | **structural analysis + documented proof**, not a runnable test | A key-space table (D-15 part 1); a CI step listing `reference/host_app/deps` before `deps.get` (D-15 part 2, needs a real CI run); a `mix deps.tree`/lock-diff proof of 2.0.0 resolution (D-15 part 3, local) | ⚠️ Partial — parts 1 and 3 are local/static; part 2 needs a pushed CI run to observe actual cache-restore behavior |
| CTRL-01 | `workflow_dispatch` of schedule path exits 0 against `inactive` ledger | integration (needs a real dispatch) | `gh workflow run post-publish-smoke.yml -f mode=<new-mode> ...` (or however the new mode input is invoked) | ❌ — inherently needs a pushed workflow + `workflow_dispatch` on `main`; cannot be verified pre-merge except by reading the bash logic for correctness |
| CTRL-02 | No redundant re-run against tagged SHA | integration (needs a real `chore: release main` merge) | Observe next `chore: release main` PR merge's `release-please` run | ❌ — inherently a post-merge observation |
| CTRL-03 | 3 consecutive pushes green, push/schedule agree | integration (needs 3 real pushes) | Observe `push` and `schedule` workflow runs at the same SHA across 3 consecutive merges | ❌ — inherently post-merge; D-37 PR slicing already accounts for this (PR-5 and Phase 167's PRs supply the 3 observations "for free") |
| CTRL-04 | `mix mailglass.audit --kind hex` passes at faked 2026-12-01 | unit (date-boundary test) + manual/scripted clock-fake run | `faketime '2026-12-01 00:00:00' mix mailglass.audit --kind hex` (see Open Question 1 caveat) + `mix test test/mailglass/supply_chain/accepted_advisories_test.exs` | ✅ (rewritten test) / ⚠️ (faketime mechanism unverified — see A1) |
| CTRL-05 | 2 consecutive scheduled `repo-hygiene` runs `success`+`pass`, healthy PR doesn't red it | unit (`mailglass.repo.hygiene_test.exs`, pins current + new behavior) + integration (2 real scheduled runs) | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs` for the predicate logic; the "2 consecutive runs" half is inherently post-merge | ✅ (predicate logic) / ❌ (the 2-run observation) |

### Sampling Rate
- **Per task commit:** the targeted `mix test` command for the file(s) touched (e.g.
  `mix test test/mailglass/supply_chain/accepted_advisories_test.exs` for CTRL-04).
- **Per PR merge:** the full `mix ci` fan-out (already required by every PR in this repo).
- **Phase gate:** all locally-verifiable criteria above green; post-merge-only criteria (CTRL-01
  dispatch, CTRL-02/03's 3-push observation, CTRL-05's 2-run observation) tracked explicitly as
  **pending post-merge evidence**, not silently assumed passing. The plan should include an
  explicit "post-merge verification" checklist item for each ❌/⚠️ row above, distinct from the
  PR's own merge-gate tests.

### Wave 0 Gaps
- `config/coverage_baselines/admin.json` does not exist yet — must be generated from a green run
  of the widened suite in the same PR that widens it (D-06), not before.
- The `@ci_yml_suite_floor_occurrences` constant and its anti-vacuity/negative-control test trio
  (D-08) do not exist yet in `lane_classification_drift_test.exs` — net-new test code, small
  (mirrors an existing ~50-line pattern).
- No existing test exercises `dev/mix/tasks/mailglass.repo.hygiene.ex`'s new predicate (open
  >14d or failing a required check) — `test/mix/tasks/mailglass.repo.hygiene_test.exs` needs new
  cases alongside the ones it already pins (D-35).
- No existing test proves GREEN-05's cache-isolation claim structurally — the committed note
  itself (D-15) is the "test" here, since `actions/cache` internals aren't Elixir-testable code.

## Security Domain

`workflow.nyquist_validation` / `security_enforcement` config keys were not found as explicit
overrides in `.planning/config.json` for this phase — treating as enabled per the default.

### Applicable ASVS Categories

This phase touches CI/CD control-plane configuration and one Hex advisory allowlist, not
application authentication/authorization/input-validation surfaces. Most ASVS categories are not
applicable; the relevant ones are supply-chain and access-control adjacent.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | No auth surface touched |
| V3 Session Management | No | No session surface touched |
| V4 Access Control | Partial | CTRL-01's `workflow_dispatch` inputs already require exact 40-hex SHA + exact SemVer triples (fail-closed guard, `[VERIFIED: post-publish-smoke.yml:73-77]`) — do not loosen this validation when adding the new mode input |
| V5 Input Validation | Partial | Same fail-closed guards on CTRL-01's new mode input; GitHub Actions workflow inputs should stay `required: true` and regex-validated as the existing ones are |
| V6 Cryptography | No | No cryptographic primitive touched |
| V14 Configuration | Yes | This entire phase is configuration-hardening — CI workflow permissions, allowlist data, and gate logic. The `permissions: contents: read` minimal-scope pattern already used in `post-publish-smoke.yml`/`repo-hygiene.yml` should be preserved, not widened, by any new step. |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overly permissive `GITHUB_TOKEN` / `gh` CLI scope creep when adding new API calls for CTRL-02/03/05 | Elevation of Privilege | Keep `permissions:` blocks minimal (`contents: read`, `pull-requests: read` as already declared); do not add `write` scopes to satisfy a retry loop — read-only API calls (tag lookups, PR label reads) never need write access |
| A retry loop that retries indefinitely on 403/429 | Denial of Service (self-inflicted, against GitHub's own infra) | GitHub explicitly documents banning risk for continued requests while rate-limited (confirmed via WebSearch) — bound retries to 3 attempts, escalating backoff, hard-fail after |
| A `faketime`-wrapped CI step accidentally left running in a job that also does real time-sensitive work (e.g., cache timestamps, Hex publish timing) | Tampering (of build provenance) | Scope `faketime` invocation to a single, isolated verification step/job — never wrap an entire job or one that also touches release/publish machinery |

## Sources

### Primary (HIGH confidence)
- Live repository read (this session): `mailglass_admin/mix.exs`, `mix.exs` (root), `mailglass_inbound/mix.exs`, `test/support/suite_floor.ex`, `test/scripts/lane_classification_drift_test.exs`, `test/scripts/ci_parity_drift_test.exs`, `.github/workflows/ci.yml`, `.github/workflows/post-publish-smoke.yml`, `.github/workflows/release-please.yml`, `.github/workflows/repo-hygiene.yml`, `lib/mailglass/supply_chain/accepted_advisories.ex`, `test/mailglass/supply_chain/accepted_advisories_test.exs`, `dev/mix/tasks/mailglass.repo.hygiene.ex`, `dev/mix/tasks/mailglass.audit.ex`, `reference/demo_app/mix.exs`, `reference/demo_app/mix.lock`, `config/coverage_baselines/core.json`, `scripts/check_coverage_floor.sh` — all quoted verbatim where cited.
- Live `mix test` execution (this session): `mailglass_admin/` widened suite, plus a deliberate warning-injection sanity check.
- [GitHub Docs — Rate limits for the REST API](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api) — secondary rate limit behavior, `retry-after` semantics.
- [GitHub Docs — Best practices for using the REST API](https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api?apiVersion=2026-03-10) — exponential backoff, request spacing, banning risk.

### Secondary (MEDIUM confidence)
- `.planning/phases/166-earned-greens-and-controls-that-can-pass/166-CONTEXT.md` — the source of nearly every claim in this document; treated as primary-quality evidence given how much of it verified exactly, with the two corrections noted above.

### Tertiary (LOW confidence)
- D-26/D-27's specific upstream cowlib OSV/ninenines-PR facts (carried forward from CONTEXT.md, not independently re-fetched this session — see Assumption A2).
- `faketime`'s compatibility with BEAM clock reads (Open Question 1) — not tested this session.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new external packages; ExCoveralls mirroring is a copy of an
  already-proven in-repo pattern.
- Architecture: HIGH — every pattern reused is already implemented and verified in the live tree.
- Pitfalls: HIGH — two of the four pitfalls were discovered and confirmed by direct measurement
  this session (warning count, CTRL-01 line drift), not inferred.

**Research date:** 2026-09-17
**Valid until:** Short — this document embeds exact line numbers and a live test-run snapshot
against a fast-moving repo (75 plans/72min-plus already executed this milestone cycle alone).
Treat line-number citations as approximate if more than a few days pass before planning executes;
re-grep by content per Correction 1's guidance regardless of elapsed time.
