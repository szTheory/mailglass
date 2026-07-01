---
phase: 128-mix-ci-parity-completion-folds-in-pr-104
reviewed: 2026-07-01T18:40:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - scripts/preflight_postgres.sh
  - scripts/preflight_network.sh
  - mix.exs
  - mailglass_admin/mix.exs
  - mailglass_inbound/mix.exs
  - Makefile
  - CONTRIBUTING.md
  - test/support/ci_lanes.ex
  - test/scripts/ci_parity_drift_test.exs
  - test/scripts/required_checks_test.exs
  - .github/workflows/publish-hex.yml
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 128: Code Review Report

**Reviewed:** 2026-07-01T18:40:00Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Dev/CI-tooling-only phase (D-23, no product `lib/`, no new trust boundary). Reviewed the two new preflight shell scripts, the `ci.*` alias family across all three sibling `mix.exs` files, the `Makefile` wrappers, the rewritten `CONTRIBUTING.md`, the new `Mailglass.CILanes` shared source, and the two meta-tests (parity-drift MIXCI-03 + required-checks GATE-03).

Overall quality is high. Both meta-tests were executed and pass genuinely non-vacuously (10 tests, 0 failures); the anti-vacuity guards, negative control, and DET-02 seed guard are real (they scan actual alias step data, not comments). `shellcheck` is clean on both scripts. No secrets, no injection, no brand-voice "Oops!" leakage, no raw-stacktrace exposure — the two preflight scripts fail closed with a single actionable line each.

Three defects warrant fixing: an **unbounded `/dev/tcp` fallback** in both preflight scripts (the exact T-128-02 unbounded-hang footgun the phase set out to prevent), a **`CONTRIBUTING.md` inaccuracy** documenting a `ci.fast` step that was deliberately omitted, and a **`--seed 0` literal in a code comment** violating the phase's own comment-text-discipline rule. Four Info items cover redundancy and precision nits.

## Warnings

### WR-01: Unbounded `/dev/tcp` fallback defeats the bounded-timeout guarantee (T-128-02)

**File:** `scripts/preflight_postgres.sh:42-45`, `scripts/preflight_network.sh:37-40`
**Issue:** Both scripts bound their primary probes (`pg_isready -t 5`, `nc -w 5/8`, `curl --max-time 8`) but the final `/dev/tcp` fallback opens a raw TCP connection with **no timeout**:
```bash
elif (exec 3<>"/dev/tcp/$HOST/$PORT") 2>/dev/null; then
```
Against an unreachable or firewall-blackholed host (packets dropped, no RST), a bare `/dev/tcp` connect blocks for the OS default TCP connect timeout — commonly 75s+ on Linux, and can stack per-invocation (the postgres probe runs twice per `mix ci`, see IN-01). This is precisely the unbounded-hang DoS footgun (T-128-02) the phase's own charter names. It only triggers on hosts lacking both `pg_isready`/`nc` (postgres) or both `curl`/`nc` (network), so it is a fallback, but the bounded-timeout guarantee is stated unconditionally and this path violates it.
**Fix:** Wrap the `/dev/tcp` connect in a `timeout`:
```bash
elif command -v timeout >/dev/null 2>&1 && \
     timeout 5 bash -c "exec 3<>/dev/tcp/$HOST/$PORT" 2>/dev/null; then
  reachable=1
```
If `timeout` may be absent (macOS default), gate on it or drop the raw `/dev/tcp` branch entirely — `nc` is near-universal and already bounded. Either way, no probe path should be able to hang unbounded.

### WR-02: `CONTRIBUTING.md` documents an "unused-deps check" that `ci.fast` deliberately does not run

**File:** `CONTRIBUTING.md:34`
**Issue:** Line 34 tells contributors `mix ci.fast` "runs `mix format --check-formatted`, **unused-deps check**, `compile --warnings-as-errors` (with and without optional deps), and `mix credo --strict`." The actual `ci.fast` alias (`mix.exs:347-352`) contains no unused-deps step, and `mix.exs:345-346` explicitly documents the omission: "`deps.unlock --check-unused` is intentionally omitted: the lock carries orphaned transitive entries; cleaning them is a deferred follow-up." The docs describe a step that was consciously excluded, so a contributor reading this expects a check that never runs.
**Fix:** Remove "unused-deps check," from the `ci.fast` description in `CONTRIBUTING.md:34` so it matches the four real steps (format, compile, compile-no-optional-deps, credo).

### WR-03: Literal `--seed 0` appears in a code comment (comment-text-discipline rule)

**File:** `mailglass_inbound/mix.exs:53`
**Issue:** The phase's stated comment-text-discipline rule is that the literal `--seed 0` string must not appear in any code comment. The inbound `ci.fast` comment reads: `# is `test --exclude property` with NO --seed 0 — Phase 127 (DET-02)...`. This is the only remaining occurrence in a changed source file. It has no functional impact (comments are stripped before reaching alias data, so it does not trip the DET-02 guard), but it violates the rule as written and risks a future grep/`docs.check`-style literal scan false-positive.
**Fix:** Reword to avoid the literal token, e.g. `# is `test --exclude property` with NO fixed-seed pin — Phase 127 (DET-02) made the suite deterministic via serial MailboxCase; a seed pin regresses it.`

## Info

### IN-01: `mix ci` runs the Postgres preflight twice

**File:** `mix.exs:358` and `mix.exs:338-339`
**Issue:** The root `ci` alias runs `cmd bash scripts/preflight_postgres.sh` at line 358, then calls `ci.setup` (line 360) which runs the same preflight again at line 339. The probe is idempotent and (currently) bounded, so this is harmless, but it doubles the worst-case wait if WR-01's unbounded fallback is hit, and is redundant work.
**Fix:** Drop the standalone preflight at `mix.exs:358` and rely on `ci.setup`'s copy (which runs before the first DB task), or drop it from `ci.setup` and keep only the root-alias probe. One probe per run is sufficient.

### IN-02: DET-02 seed guard only covers the core `ci` alias, not `ci.browser` or the inbound package

**File:** `test/scripts/ci_parity_drift_test.exs:223-231`
**Issue:** The durable determinism guard filters `ci_steps()` (core root `ci` only). It does not scan `ci_browser_steps()`, and — because it runs inside the core Mix project reading `Mix.Project.config()[:aliases]` — it cannot see `mailglass_inbound/mix.exs`'s aliases at all. The very comment that carries the `--seed 0` reference (WR-03) lives in the inbound alias, which this guard does not protect. Both currently have no seed pin, so this is a coverage-scope gap, not an active regression.
**Fix:** Optionally extend the guard to also assert `ci_browser_steps()` pins no seed, and note in the moduledoc that inbound's alias is guarded by inbound's own suite (or add an equivalent guard there) so the DET-02 claim's scope is explicit.

### IN-03: "Mix Task Tests" lane is covered by a looser matcher than the "by identity" claim implies

**File:** `test/scripts/ci_parity_drift_test.exs:115-116`
**Issue:** The matcher for `"Mix Task Tests (Elixir 1.18 / OTP 27)"` matches the substring `"test --warnings-as-errors --exclude flaky"` — which resolves to the root `ci` alias's **full-suite** step (`mix.exs:362`), not `verify.mix_tasks` (the command the CI job actually runs, `test test/mix/tasks/`). The full suite does include `test/mix/tasks/`, so the lane's tests genuinely run in `mix ci` and the parity claim holds semantically. But the module doc and matcher-table comments advertise coverage "by IDENTITY + flag-set (NOT a loose substring)"; this particular matcher is a coarse full-suite match rather than an identity match on the lane's own command.
**Fix:** No behavior change needed. Either add a brief note that the Mix Task Tests lane is covered transitively by the full-suite step (not by a `verify.mix_tasks` invocation), or tighten the matcher/alias if per-lane identity is desired.

### IN-04: Anti-vacuity bijection test hardcodes a second literal copy of the 15 lane names

**File:** `test/scripts/ci_parity_drift_test.exs:179-196`
**Issue:** The `matcher_lanes` MapSet literally re-lists all 15 lane display names, while `matcher_for/1` (line 93) and the module doc claim the matcher keys are "never a second copy of the lane list." For the stale-matcher (`matcher_lanes − known`) direction this literal set is arguably necessary, but it is a genuine second copy: renaming a lane in `Mailglass.CILanes` now requires editing this literal set too, or the bijection assertion fails. The "never duplicated" comment is imprecise given this block.
**Fix:** Derive `matcher_lanes` from the matcher table itself (e.g. build the `%{...}` map once, take `Map.keys/1`) so the stale-matcher check reads the real matcher keys instead of a maintained duplicate — or soften the "never a second copy" comment to acknowledge this deliberate bijection anchor.

---

_Reviewed: 2026-07-01T18:40:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
