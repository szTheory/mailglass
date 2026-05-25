---
phase: 49-inbound-runtime-operator-tooling
reviewed: 2026-05-25T00:00:00Z
depth: standard
files_reviewed: 33
files_reviewed_list:
  - mailglass_inbound/lib/mailglass_inbound/config.ex
  - mailglass_inbound/lib/mailglass_inbound/rate_limiter.ex
  - mailglass_inbound/lib/mailglass_inbound/rate_limiter/table_owner.ex
  - mailglass_inbound/lib/mailglass_inbound/application.ex
  - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
  - mailglass_inbound/lib/mailglass_inbound/telemetry.ex
  - mailglass_inbound/lib/mailglass_inbound/inbound_message.ex
  - mailglass_inbound/lib/mailglass_inbound/inbound_message/signals.ex
  - mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex
  - mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
  - mailglass_inbound/lib/mailglass_inbound/execution.ex
  - mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex
  - mailglass_inbound/priv/repo/migrations/20260525000000_add_suppression_flagged_to_inbound_records.exs
  - mailglass_inbound/lib/mailglass_inbound/operator/formatter.ex
  - mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex
  - mailglass_inbound/lib/mailglass_inbound/internal/prune.ex
  - mailglass_inbound/lib/mailglass_inbound/prune/worker.ex
  - mailglass_inbound/lib/mailglass_inbound/router/route.ex
  - mailglass_inbound/lib/mailglass_inbound/router.ex
  - mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex
  - mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex
  - mailglass_inbound/lib/mix/tasks/mailglass.inbound.prune.ex
  - mailglass_inbound/config/test.exs
  - mailglass_inbound/test/mailglass_inbound/config_test.exs
  - mailglass_inbound/test/mailglass_inbound/rate_limiter_test.exs
  - mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs
  - mailglass_inbound/test/mailglass_inbound/inbound_message_test.exs
  - mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs
  - mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs
  - mailglass_inbound/test/mailglass_inbound/internal/doctor_test.exs
  - mailglass_inbound/test/mailglass_inbound/internal/prune_test.exs
  - mailglass_inbound/test/mix/tasks/mailglass_inbound_doctor_test.exs
  - mailglass_inbound/test/mix/tasks/mailglass_inbound_replay_test.exs
  - mailglass_inbound/test/mix/tasks/mailglass_inbound_prune_test.exs
findings:
  critical: 2
  warning: 4
  info: 4
  total: 10
status: issues_found
---

# Phase 49: Code Review Report

**Reviewed:** 2026-05-25T00:00:00Z
**Depth:** standard
**Files Reviewed:** 33
**Status:** issues_found

## Summary

Phase 49 ships inbound runtime + operator tooling: validated config, an ETS
token-bucket rate limiter, a DNS-free doctor, a batched/advisory-locked retention
prune, the suppression-flag signal, and three mix tasks. The PII discipline is
carefully implemented and well-tested (telemetry whitelists, static 500 bodies,
S3FetchError mapping). The append-only and tenant-scoping invariants hold in the
read model.

However the **retention prune (`Internal.Prune`) contains two production-affecting
defects that the test suite masks**, both BLOCKER:

1. The `pg_try_advisory_lock` single-run guard acquires and releases the lock on
   *different pooled connections*, so the lock leaks and the guard does not work
   outside the shared-sandbox test. (CR-01)
2. The default retention windows prune `evidence` (30d) more aggressively than the
   `execution_runs` (90d) that reference it via an `on_delete: :nothing` FK, so the
   sweep crashes with a foreign-key violation on any realistic dataset. (CR-02)

Plus a documented-vs-actual rate-limit refill-rate mismatch, an unreachable
`--no-start` flag in the doctor task, a cross-repo call inside the inbound
transaction, and several smaller quality items.

The full suite passing (323 tests + 3 properties) is not evidence of correctness
here: both critical prune defects are only exercised through code paths the
fixtures never construct (CR-01 is hidden by shared-sandbox single-connection
pinning; CR-02 is hidden because every test deletes all referencing runs before
the evidence delete runs).

## Structural Findings (fallow)

No `<structural_findings>` block was provided with this review; none to reconcile.

## Critical Issues

### CR-01: Advisory lock acquired and released on different pooled connections — single-run guard is broken in production

**File:** `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex:118-130`

**Issue:** PostgreSQL session-level advisory locks (`pg_try_advisory_lock` /
`pg_advisory_unlock`, the non-`_xact_` variants) are bound to the database
*session* (connection). `with_advisory_lock/2` issues three independent
`repo.query!` / `repo.delete_all` calls with no `Repo.checkout/2` or
`Repo.transaction/2` wrapping them:

```elixir
defp with_advisory_lock(repo, fun) do
  case repo.query!("SELECT pg_try_advisory_lock($1)", [@prune_lock_key]) do  # conn A
    %{rows: [[true]]} ->
      try do
        fun.()                                                                # conns B, C, ...
      after
        repo.query!("SELECT pg_advisory_unlock($1)", [@prune_lock_key])       # conn D
      end
    ...
```

Outside an explicit checkout, Ecto/DBConnection hands each call a (possibly)
different pooled connection. Consequences in production:

- The lock is taken on connection A but `pg_advisory_unlock` runs on connection D,
  where no lock is held — it returns `false` (does **not** raise, since `query!`
  only raises on SQL errors). The lock on A is **never released** until A is
  recycled/closed.
- Leaked locks accumulate. Once every pooled connection that ever ran a prune holds
  a stale lock, future `pg_try_advisory_lock` calls succeed only if they happen to
  land on a fresh connection; eventually prune can wedge or behave
  nondeterministically.
- The batched deletes inside `fun.()` run on connections that do **not** hold the
  lock, so two concurrent sweeps (cron tick + ops `mix` run, the exact scenario
  the lock exists to prevent — see moduledoc lines 11-13, 38-40) can interleave.

The `Internal.PruneTest` masks this: it uses `Sandbox.checkout(TestRepo,
sandbox: false)` + `Sandbox.mode({:shared, self()})`, which pins **one** connection
for the whole test, so lock/unlock/deletes all share a connection. The
"advisory-lock single-run guard" test only proves the *locked-out* branch via a
separate Postgrex connection — it never asserts the lock is released, nor that a
*second sequential* `prune/0` succeeds after the first releases.

**Fix:** Pin a single connection for the whole sweep so the lock, the deletes, and
the unlock all share one session. `Repo.checkout/2` keeps one connection across
multiple separate transactions (so the batched-commit-per-delete design is
preserved):

```elixir
defp with_advisory_lock(repo, fun) do
  repo.checkout(fn ->
    case repo.query!("SELECT pg_try_advisory_lock($1)", [@prune_lock_key]) do
      %{rows: [[true]]} ->
        try do
          fun.()
        after
          repo.query!("SELECT pg_advisory_unlock($1)", [@prune_lock_key])
        end

      %{rows: [[false]]} ->
        {:ok, :locked_out}
    end
  end)
end
```

Add a regression test that runs `prune/0` twice in sequence (no shared
single-connection trick) and asserts the second call is NOT `:locked_out`, i.e.
the lock was actually released.

### CR-02: Default retention windows prune `evidence` (30d) before the `execution_runs` (90d) that reference it — prune crashes on FK violation

**File:** `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex:79-97` (window
selection) and `:149-156` (`delete_window`)

**Issue:** The default windows are records 90d, **evidence 30d**, execution_runs
(fresh) 90d, replay_runs 30d (`Config` defaults, `prune.ex:80-83`). The
`mailglass_inbound_replay_runs` lineage table has FKs to both
`mailglass_inbound_records` and `mailglass_inbound_evidence` with
`on_delete: :nothing` (migration `20260506163000_...:66,70`), and the moduledoc
explicitly relies on `:nothing` "failing loudly" as a safety net (lines 21-24).

Consider any tenant with traffic between 30 and 90 days old (universal in a
running deployment):

- A `:fresh` execution run inserted 45 days ago **survives** (45 < 90d fresh window).
- Its evidence row, also ~45 days old, **is selected for deletion** (45 > 30d
  evidence window).
- `delete_window(repo, InboundEvidence, 30)` issues a DELETE that violates the
  `inbound_evidence_id` FK from the surviving fresh run → Postgres raises
  `23503 foreign_key_violation` → `repo.delete_all/2` raises `Postgrex.Error` →
  the entire `sweep/2` crashes. Prune never completes, retention is never enforced,
  and (under the Oban worker path) the job retries and crashes forever.

Every fresh ingress creates record + evidence + (on dispatch) an execution_run all
referencing each other (`Persist.insert_evidence/5`, `Execution.execute/2`), so the
defaults guarantee this collision the first time prune runs against >30-day-old data.

`Internal.PruneTest` never constructs the dangerous shape: in the main retention
test the evidence (120d), fresh run (120d), and replay run (45d) are all over their
windows, so every referencing run is deleted *before* the evidence delete (correct
child-first), and the FK is never tripped. The case "fresh run 30–90d old + evidence
>30d old" is untested.

**Fix:** The retention contract must guarantee a child's window is never shorter
than its parents that reference it via `:nothing`. Either:

- **(preferred)** Make evidence retention ≥ max(execution_runs, replay_runs)
  windows. Since evidence is referenced by both source classes, evidence must
  outlive the longest run window. With defaults that means evidence ≥ 90d, or
  derive it: `evidence_days = max(evidence_days, fresh_days, replay_days)` (and
  records ≥ evidence). Document the constraint and validate it in `Config`
  (raise/clamp on a window inversion at boot); or
- Switch the run→evidence/record FKs to `on_delete: :cascade` *only if* the
  child-first ordering is dropped — but the moduledoc forbids CASCADE, so the
  window-ordering invariant is the right fix.

Add a regression test: insert a 45-day-old evidence row referenced by a 45-day-old
`:fresh` run, then assert `prune/0` returns `{:ok, _}` (no raise) and the evidence
row survives.

## Warnings

### WR-01: Rate-limit defaults document "N/min" but the bucket only refills `per_minute` (60) tokens/min — sustained throughput is 60/min, not the advertised capacity

**File:** `mailglass_inbound/lib/mailglass_inbound/config.ex:33-43` and
`mailglass_inbound/lib/mailglass_inbound/rate_limiter.ex:6-10, 116-123`

**Issue:** The core `Mailglass.RateLimiter` convention is `capacity == per_minute`
(e.g. `default_limits_for(:tenant_recipient) -> [capacity: 100, per_minute: 100]`),
so "N/min" is literally true: the bucket refills its full capacity each minute. The
inbound defaults break that invariant — `tenant: [capacity: 1000, per_minute: 60]`,
`sender_domain: [capacity: 200, per_minute: 60]`, `recipient: [capacity: 500,
per_minute: 60]`. With `refill_per_ms = per_minute / 60_000`, a `per_minute: 60`
bucket refills only `60` tokens per minute regardless of capacity. So the tenant
bucket allows a one-time burst of 1000, then throttles to a **sustained 60/min** —
not the "tenant 1000/min" the Config moduledoc (lines 36-37, 66) and the
RateLimiter moduledoc (lines 8-10) both claim. `retry_after_ms` for one token is
`ceil(1 / 0.001) = 1000ms`, consistent with 60/min, not 1000/min.

This is a correctness/contract defect: operators reading "1000/min" will size for
1000 sustained and silently get 60, throttling legitimate inbound mail.

**Fix:** Either set the defaults so `per_minute` equals the advertised rate (e.g.
`tenant: [capacity: 1000, per_minute: 1000]`, matching the core convention), or
rewrite the docs to state the true model: "capacity = burst size, `per_minute` =
sustained refill rate," and pick `per_minute` values that reflect intended
sustained throughput. The `config/test.exs` block (lines 36-39) has the same
`per_minute: 60` shape and should be reconciled with whichever model is chosen.

### WR-02: Doctor mix task `--no-start` flag is unreachable — `app.start` always runs

**File:** `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex:41-48`

**Issue:** `run/1` guards the app boot with
`unless Keyword.get(opts, :no_start, false) do Mix.Task.run("app.start") end`, but
the `OptionParser.parse` strict spec is
`[format: :string, strict: :boolean, verbose: :boolean]` — it does **not** declare
`no_start`. So `--no-start` would be rejected as an unknown option by
`validate_cli!` (→ `Mix.raise`), and `Keyword.get(opts, :no_start, false)` is always
`false`. The escape hatch the code appears to provide cannot be used. (Contrast the
replay and prune tasks, which both declare `no_start: :boolean`.) The doctor test
works around this by `Mix.Task.reenable("app.start")` rather than passing the flag,
confirming the flag is dead.

**Fix:** Add `no_start: :boolean` to the doctor task's strict option spec so the
flag the code already branches on is actually parseable (matching replay/prune), or
remove the dead `unless`/`no_start` branch if booting the app is always required.

### WR-03: Suppression-flag store check runs a cross-repo query inside the inbound DB transaction

**File:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex:30-33,
238, 268-307`

**Issue:** `persist/2` opens `repo.transact(...)`; inside it, `insert_record/4`
calls `compute_suppression_flag/3` → `suppressed_sender?/2` →
`store.check/1` on the **core** suppression store
(`Application.get_env(:mailglass, :suppression_store,
Mailglass.SuppressionStore.Ecto)`), which queries the **core** `Mailglass.Repo` — a
different repo/connection pool than the inbound `repo`. This means a second pooled
connection is checked out while the inbound transaction is still open. Under a
constrained pool or a slow/blocking suppression store, this lengthens the inbound
write transaction and adds a pool-exhaustion/deadlock surface on the ingress hot
path. The code does degrade OPEN on error (rescue/catch at lines 303-307), so it is
not a data-loss bug, but holding an external lookup inside the write transaction is
a robustness hazard for a path that runs on every inbound message.

**Fix:** Compute the suppression flag **before** `repo.transact` (it needs only
`tenant_id` + the message's first `from` address, none of which require the
transaction), and pass the resulting boolean into `insert_record/4`. This keeps the
external lookup out of the DB transaction while preserving the
degrade-open-and-set-once semantics and the `:suppression_flag` span.

### WR-04: Doctor summary counts cannot-diagnose findings as `fail`, mislabeling the human tally

**File:** `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex:72-84,
409-421`

**Issue:** A "router not configured / does not compile" finding is emitted with
`status: :fail` and `evidence: %{cannot_diagnose: true}`. `summarize/1` does
`Map.update!(acc, finding.status, &(&1 + 1))` (incrementing `fail`) **and**
separately increments `cannot_diagnose`. The exit-code logic checks
`cannot_diagnose` first so the exit code is correct (2). But the human summary line
`Operator.Formatter.summary_line/1` renders only "N pass, N warn, N fail", so a
no-router run prints "0 pass, 0 warn, **1 fail**" while the real disposition is
"cannot diagnose." This is misleading operator output — a cannot-diagnose state is
not the same as a failed check, and the tally now conflates them.

**Fix:** Give cannot-diagnose findings a distinct status (or exclude them from the
`fail` tally) and surface a `cannot_diagnose` count in the summary line, e.g.
"0 pass, 0 warn, 0 fail, 1 cannot diagnose"; or have `summarize/1` not increment
`:fail` when `evidence.cannot_diagnose` is set.

## Info

### IN-01: `Module.concat/1` fallback in `decode_route` can create new atoms from job args

**File:** `mailglass_inbound/lib/mailglass_inbound/execution.ex:248-257`

**Issue:** `mailbox_module/1` uses `String.to_existing_atom` for the
`"Elixir." <> _` case (safe) but falls back to
`mailbox |> String.split(".") |> Module.concat()` otherwise, which **creates** atoms.
In normal operation the persisted `"mailbox"` job arg is always
`Atom.to_string(module)` (i.e. `"Elixir.Foo"`), so the safe clause always matches
and the fallback is effectively dead. But job args are read from the DB / Oban
queue on the replay/execution path; a corrupted or hand-edited arg without the
`Elixir.` prefix would route into `Module.concat` and mint atoms — a (small) atom
table growth vector on an otherwise validation-light path.

**Fix:** Drop the `Module.concat` fallback and route all decoding through
`String.to_existing_atom` (rescuing `ArgumentError` → `{:error, :invalid_job_args}`,
which `decode_route/2` already does for the surrounding clause), so an unknown
mailbox string is rejected rather than materialized.

### IN-02: `bucket_type/1` fallback collapses an unkeyed `:per_domain` error to `:recipient`

**File:** `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:246-251`

**Issue:** `RateLimitError` of `type: :per_domain` is used for **both** the
recipient and the sender_domain buckets. `bucket_type/1`'s primary clause reads the
PII-free `context[:bucket]` (always set by the limiter, so this is the live path),
but the defensive fallback `bucket_type(%{type: ...})` maps any non-`:per_tenant`
error to `:recipient` — so a sender_domain trip with a missing `:bucket` context
would be mislabeled `recipient` in the 429 body and telemetry. Not reachable today
(the limiter always stamps `:bucket`), but the fallback silently picks the wrong
one rather than a neutral value.

**Fix:** If the context bucket is absent, prefer a neutral label (e.g. `:domain`)
over guessing `:recipient`, or assert the context is always present and drop the
type-only fallback.

### IN-03: Rate-limit hot path re-validates config (and can raise) on every check/trip

**File:** `mailglass_inbound/lib/mailglass_inbound/rate_limiter.ex:116-123,
129-138`

**Issue:** `limits_for/1` calls `MailglassInbound.Config.rate_limit()` which runs
`NimbleOptions.validate!/2` on the app env. This happens once per bucket per
`check/3`, plus again in `build_error/2` on a trip (so 4× on a tenant trip). Beyond
the redundant work, `validate!` **raises** on invalid runtime config — and the plug
comment (plug.ex:188-190) asserts the limiter "NEVER raises." Config is
boot-validated, so this is latent, but a runtime `Application.put_env` of a bad
shape would turn a rate-limit check into an uncontrolled 500 that escapes the plug
rescue allowlist.

**Fix:** Read the validated buckets once per `check/3` (pass them into
`check_bucket`/`build_error`), and/or have the limiter use a non-raising accessor
(`Config.rate_limit/0` returning defaults on invalid env) so a misconfiguration
degrades rather than crashes the ingress span.

### IN-04: Doctor signing-key presence check treats any non-nil `:basic_auth` tuple as "present" without shape validation

**File:** `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex:381-405`

**Issue:** `present?/1` returns `true` for any non-nil, non-binary value
(`present?(value), do: not is_nil(value)`), so a malformed `:basic_auth` such as
`{"user"}` or `[]`-ish config passes the presence check even though the plug's
`verify!` would reject the request at runtime. The doctor's promise is a DNS-free
pre-deploy sanity check; a misshapen credential that "looks present" defeats it.

**Fix:** For `:basic_auth`, validate the expected `{user, pass}` tuple shape (both
non-empty binaries) rather than mere non-nil-ness, so the doctor catches a
malformed credential before deploy.

---

_Reviewed: 2026-05-25T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
