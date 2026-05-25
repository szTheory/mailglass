---
phase: 49-inbound-runtime-operator-tooling
fixed_at: 2026-05-25T06:50:28Z
review_path: .planning/phases/49-inbound-runtime-operator-tooling/49-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 49: Code Review Fix Report

**Fixed at:** 2026-05-25T06:50:28Z
**Source review:** .planning/phases/49-inbound-runtime-operator-tooling/49-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (CR-01, CR-02, WR-01, WR-02, WR-03, WR-04)
- Fixed: 6
- Skipped: 0

All fixes were applied in an isolated git worktree, each committed atomically,
verified with `mix format`, `mix compile --warnings-as-errors`, and the relevant
per-file test suites run with `--seed 0` (to avoid the known phase-45 1000-iter
property-test DB-pool flake). The four Info findings (IN-01..IN-04) were out of
scope (`critical_warning`) and were not attempted.

Combined verification run (all touched + adjacent files): **96 tests, 0 failures.**

## Fixed Issues

### CR-01: Advisory lock acquired and released on different pooled connections

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex`, `mailglass_inbound/test/mailglass_inbound/internal/prune_test.exs`
**Commit:** 4441547
**Status:** fixed
**Applied fix:** Wrapped the whole sweep in `repo.checkout(fn -> ... end)` so the
`pg_try_advisory_lock` acquire, the batched per-batch deletes, and the
`pg_advisory_unlock` release all run on one pinned session. Previously each
`query!`/`delete_all` could land on a different pooled connection, leaking the
session lock (unlock ran where no lock was held) and letting two concurrent
sweeps interleave. `Repo.checkout/2` preserves the batched-commit-per-delete
design (it keeps one connection across separate transactions). Added a
regression test that runs `prune/0` twice in sequence (no shared
single-connection trick) and asserts the second run is NOT `:locked_out`,
proving the first run actually released its lock.

### CR-02: Default retention windows prune evidence before referencing runs (FK violation)

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/config.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex`, `mailglass_inbound/test/mailglass_inbound/config_test.exs`, `mailglass_inbound/test/mailglass_inbound/internal/prune_test.exs`
**Commit:** a84be51
**Status:** fixed: requires human verification
**Applied fix:** Implemented the review's preferred fix — enforce the FK-lineage
invariant at the Config boundary. (1) Raised the `evidence_days` default from 30
to 90 so it is never shorter than the 90d `execution_runs` window that references
it via `on_delete: :nothing`. (2) Added `clamp_retention/1` in
`Config.retention/0` that clamps any configured override UP so
`evidence_days >= max(execution_runs_days, replay_runs_days)` and
`records_days >= evidence_days`, with `:infinity` treated as the maximum
(an `:infinity` child forces its parents to `:infinity`). Updated prune.ex's
moduledoc + fallback default to match, and documented the invariant. Added Config
clamp tests (evidence-up, records-up, `:infinity`-propagation) and a prune
regression that inserts a 45-day-old evidence row referenced by a 45-day-old
`:fresh` run and asserts `prune/0` returns `{:ok, _}` (no FK crash) with the
evidence preserved.

_Flagged for human verification:_ this embeds a semantic data-retention
invariant (the FK-ordering clamp). The clamp logic is unit-tested, but a human
should confirm the chosen clamp direction (parents widened up, never children
narrowed) matches the intended retention policy and that no operator workflow
expected evidence to be deleted before its referencing runs.

### WR-01: Rate-limit defaults documented "N/min" but refilled only `per_minute` (60) tokens/min

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/config.ex`, `mailglass_inbound/config/test.exs`, `mailglass_inbound/test/mailglass_inbound/config_test.exs`
**Commit:** 700e85d
**Status:** fixed: requires human verification
**Applied fix:** Chose Option A (match the core `Mailglass.RateLimiter`
convention `capacity == per_minute`). Verified the design intent first:
49-CONTEXT.md D-49-13, 49-RESEARCH.md, and 49-PATTERNS.md all advertise "tenant
1000/min, recipient 500/min, sender_domain 200/min" as the *sustained* rate, and
the core convention (`default_limits_for` 100/100, 1000/1000, 500/500) is
`capacity == per_minute` — so `per_minute: 60` was the defect, not an intentional
design. Set `tenant: 1000/1000`, `sender_domain: 200/200`, `recipient: 500/500`
in config.ex; reconciled `config/test.exs` to `per_minute == capacity`
(`1_000_000`, keeping the limiter inert for incidental test traffic); updated the
default-bucket test assertions; clarified the docs (capacity = burst,
`per_minute` = sustained refill). No change needed in rate_limiter.ex — its
`per_minute / 60_000` math now yields the correct sustained rate.

_Flagged for human verification:_ this changes runtime throughput behavior
(sustained rate rises from 60/min to the advertised capacity). A human should
confirm the higher sustained ceiling is intended for production ingress sizing.

### WR-02: Doctor mix task `--no-start` flag unreachable

**Files modified:** `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex`, `mailglass_inbound/test/mix/tasks/mailglass_inbound_doctor_test.exs`
**Commit:** 12a392d
**Status:** fixed
**Applied fix:** Added `no_start: :boolean` to the doctor task's `OptionParser`
strict spec (matching the replay and prune tasks), so the `--no-start` flag the
`run/1` body already branches on parses instead of being rejected as an unknown
option. Added a regression test asserting `--no-start` parses cleanly and the run
completes with the normal three-state exit code.

### WR-03: Suppression-flag store check runs a cross-repo query inside the inbound transaction

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex`
**Commit:** e729756
**Status:** fixed
**Applied fix:** Moved `compute_suppression_flag/3` out of the write transaction:
it now runs in `persist/2` BEFORE `repo.transact`, and the resulting boolean is
threaded through `persist_in_transaction/6` into `insert_record/5`. The flag
needs only `tenant_id` + the message's first `from` address, none of which
require the transaction, so the cross-repo (core suppression store) lookup no
longer holds a second pooled connection open for the duration of the inbound
write — removing the pool-exhaustion/deadlock surface on the ingress hot path.
The `:suppression_flag` telemetry span and the degrade-open semantics (D-49-23)
are preserved. The commit also includes `mix format` line-wrapping of
pre-existing over-100-char function heads in the same file (required by the
project formatter once the file was edited). All 16 persist tests pass,
including the suppressed/non-suppressed/degrade-open and the PII-free
`:suppression_flag` span assertions.

### WR-04: Doctor summary counts cannot-diagnose findings as `fail`

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex`, `mailglass_inbound/lib/mailglass_inbound/operator/formatter.ex`, `mailglass_inbound/test/mix/tasks/mailglass_inbound_doctor_test.exs`
**Commit:** c878803
**Status:** fixed
**Applied fix:** `summarize/1` now counts a cannot-diagnose finding ONLY under
`:cannot_diagnose`, not under `:fail` (the finding keeps `status: :fail` for the
per-finding render). The formatter `summary_line/1` appends `", N cannot diagnose"`
when the summary carries a non-zero count, so a no-router run prints
"0 pass, 0 warn, 0 fail, 1 cannot diagnose" instead of the misleading
"0 pass, 0 warn, 1 fail". Exit-code-2 ordering is unchanged (it already checked
`cannot_diagnose` first). Added a regression test asserting a no-router run
reports "0 fail" and "cannot diagnose" in the human output.

## Skipped Issues

None — all in-scope findings were fixed.

The four Info findings were out of scope (`fix_scope: critical_warning`) and not
attempted: IN-01 (`Module.concat` atom-minting fallback in `decode_route`),
IN-02 (`bucket_type/1` collapses unkeyed `:per_domain` to `:recipient`),
IN-03 (rate-limit hot path re-validates config and can raise), IN-04 (doctor
`:basic_auth` presence check accepts any non-nil shape).

---

_Fixed: 2026-05-25T06:50:28Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
