---
status: complete
phase: 49-inbound-runtime-operator-tooling
source: [49-01-SUMMARY.md, 49-02-SUMMARY.md, 49-03-SUMMARY.md]
started: 2026-05-25T06:59:43Z
updated: 2026-05-25T06:59:43Z
verification: self-verified (Claude ran every check; no manual UAT)
---

## Current Test

[testing complete]

## Tests

### 1. Inbound runtime config validates and exposes typed retention + rate-limit accessors (49-01)
expected: `MailglassInbound.Config` reads the **`:mailglass_inbound`** app env (never core `Mailglass.Config`), `validate_at_boot!/0` raises `NimbleOptions.ValidationError` on a bad shape, and `retention/0` / `rate_limit/0` return typed defaults merged over overrides. Two code-review fixes are live: **WR-01** — advertised rates are the *sustained* rate (`per_minute == capacity`: tenant 1000/1000, recipient 500/500, sender_domain 200/200), not 60/min; **CR-02** — `retention/0` clamps any override UP so the FK lineage holds (`evidence_days >= max(execution_runs_days, replay_runs_days)`, `records_days >= evidence_days`, `:infinity` propagates to parents).
result: pass
evidence: "`mix test test/mailglass_inbound/config_test.exs --seed 0` green within the 98-test 49-01/49-02 run. WR-01 asserted at config_test.exs:148-153 (tenant capacity==per_minute==1000, recipient 500/500). CR-02 clamp + :infinity-propagation cases present. Negative-shape validation (negative capacity, bad retention) raises as expected. `MailglassInbound.Config` reads `:mailglass_inbound` per D-49-02 boundary law; credo --strict clean."

### 2. IOPS-04 — post-verify 3-bucket rate limiter returns HTTP 429 + Retry-After (49-01)
expected: `MailglassInbound.RateLimiter.check/3` is a leaky-bucket ETS limiter (tenant→recipient→sender_domain) wired into `Ingress.Plug.persist_and_respond/5` **after** verify + `resolve_tenant!`, **before** persist. On trip: HTTP 429 with a per-bucket `retry-after` header and `%{status: "rate_limited", bucket: "<type>"}` body — the branch **never raises** (mirrors the TenancyError 422 idiom). A forged request returns 401 before any budget is read (post-verify invariant). Rate-limit telemetry (`[:mailglass_inbound, :ingress, :rate_limit, :stop]`) carries bucket TYPE/limit/retry_after only — no recipient/sender/to/from/email.
result: pass
evidence: "`mix test test/mailglass_inbound/rate_limiter_test.exs test/mailglass_inbound/ingress/plug_test.exs --seed 0` green within the 98-test run. Tests cover: 3-bucket trip order with per-bucket Retry-After, forged→401-budget-intact, 429-never-raises, concurrent-load asserting exactly `capacity` successes (ETS atomicity), and PII-absence on the telemetry span. T-49-01/02/03 mitigations asserted."

### 3. IOPS-05 + IADM-02 — suppression flag persists, surfaces in admin list, reaches the mailbox, degrades OPEN, never auto-bounces (49-02)
expected: A suppressed-sender inbound message **still persists and still routes** (no gate, no auto-bounce — backscatter avoidance). Its `mailglass_inbound_records.suppression_flagged` column (NOT NULL DEFAULT false) is `true`, surfaces in the `list_records/2` admin read-model (IADM-02), and reaches mailbox callbacks via the framework-owned typed `%InboundMessage.Signals{suppression_flagged: …}` struct (field is `:signals`, never adopter-owned `:metadata`). Lookup **degrades OPEN** (false) on store `{:error,_}`, empty-from, AND any raised store exception. **WR-03**: the cross-repo suppression lookup now runs in `persist/2` BEFORE `repo.transact`, so it no longer holds a second pooled connection open across the inbound write transaction.
result: pass
evidence: "`mix test test/mailglass_inbound/inbound_message_test.exs test/mailglass_inbound/ingress/persist_test.exs test/mailglass_inbound/internal/operator/records_test.exs --seed 0` green within the 98-test run. 16 persist tests cover suppressed→true / non-suppressed→false / degrade-OPEN on {:error,_} + empty-from + raised-exception (flag false AND persist succeeds) / no-auto-bounce (route still matched) / PII-free `:suppression_flag` span. inbound_message_test asserts `:signals` default `%Signals{}`, `suppression_flagged?/1`, no `:metadata` field. records_test asserts IADM-02 select surfaces the flag. WR-03 refactor (compute-before-transact) verified by the same 16 persist tests passing post-fix. Migration up/down reversibility proven; T-49-06..10 mitigations asserted."

### 4. IOPS-01 + MIME-03 — `mix mailglass.inbound.doctor` DNS-free three-state config doctor (49-03)
expected: `mix mailglass.inbound.doctor` runs entirely DNS-free reflection checks (router configured/compiles, ≥1 route, each mailbox compiled + `process/1` exported, provider signing-key **presence only** — never verifies a signature, MIME backend via `Mailglass.OptionalDeps.GenSmtp.available?/0` + `Application.spec(:gen_smtp, :vsn)`). Route-conflict detection **reuses** `Router.Matcher.matches_route?/2` (structural subsumption + witness-probe → `:fail`, regex overlap → `:warn`) and names `router.ex:LINE`. Three-state exit via `exit({:shutdown, N})`: 2 cannot-diagnose → 1 fail/strict-warn → 0; `--format human|json`, `--strict`, `--verbose`. Two fixes live: **WR-02** — `--no-start` is now a declared strict flag (parsed, not rejected); **WR-04** — a cannot-diagnose finding is tallied separately ("0 pass, 0 warn, 0 fail, 1 cannot diagnose"), not as `1 fail`.
result: pass
evidence: "`mix test test/mailglass_inbound/internal/doctor_test.exs test/mix/tasks/mailglass_inbound_doctor_test.exs --seed 0` green within the 43-test 49-03 run. WR-02 asserted at doctor_test.exs:135 (`--no-start` parses, exit 0). WR-04 asserted at doctor_test.exs:91 (no-router run prints '0 fail' AND 'cannot diagnose'). Three-state exit (0/1/2), MIME-03 `Application.spec(:gen_smtp)` report, matcher-reuse route-conflict, and json/human formats covered. Matcher reuse confirmed: `matches_route?` referenced in internal/doctor.ex."

### 5. IOPS-02 — `mix mailglass.inbound.replay` selector-driven single-record replay (49-03)
expected: `mix mailglass.inbound.replay` resolves `--record-id` / `--since <iso8601>` / `--tenant <id>` (AND-combinable) into an id list via a **parameterized** query (selectors never interpolated), then iterates the shipped single-record `Internal.Replay.replay/2` (appends `source: :replay`, append-only — never mutates the original run). `[y/N]` defaults **No**; `--yes`/`-y` skips the prompt; `--dry-run` reports count + scope without replaying; zero matches → exit `0` with "nothing to replay."
result: pass
evidence: "`mix test test/mix/tasks/mailglass_inbound_replay_test.exs --seed 0` green within the 43-test run. Query log shows real append-only `:replay` INSERTs into mailglass_inbound_replay_runs. Selector resolution, dry-run, [y/N]-default-No, --yes, and zero-match→exit-0 paths covered."

### 6. IOPS-03 — `mix mailglass.inbound.prune` batched, advisory-locked, FK-safe retention sweep (49-03)
expected: `mix mailglass.inbound.prune` reads windows from `Config.retention/0` and deletes in batches of 1000 (`DELETE WHERE id IN (SELECT id … LIMIT 1000 FOR UPDATE SKIP LOCKED)` looped), child-first (replay_runs → fresh_runs → evidence → records), the whole sweep serialized by a session `pg_try_advisory_lock` (concurrent run → `{:ok, :locked_out}`, deletes nothing). `:infinity` on a class disables that window. Runs **synchronously with or without Oban**; destructive tier is `--dry-run` + typed `yes` + `--yes` for cron. Two critical fixes live: **CR-01** — the lock acquire, batched deletes, and release all run on **one pinned connection** (`repo.checkout/2`), so the lock is actually released; **CR-02** — the FK-lineage clamp means a fresh run + evidence aged 30–90d no longer trips the `on_delete: :nothing` FK.
result: pass
evidence: "`mix test test/mailglass_inbound/internal/prune_test.exs test/mix/tasks/mailglass_inbound_prune_test.exs --seed 0` green within the 43-test run (real non-sandboxed connection + separate Postgrex conn for the cross-session lock probe). CR-01 regression asserted at prune_test.exs:156 ('two sequential prune/0 runs both acquire the lock … the first released'; second run refute-locked_out). CR-02 regression asserted at prune_test.exs:77 ('a fresh run + evidence aged 30-90d does not trip the FK; evidence survives'). `:infinity`-disables-window, child-first order, batched FOR UPDATE SKIP LOCKED, and Oban-present/absent paths covered."

## Cross-cutting gates (verified, not part of the 6 deliverable tests)

- Full inbound suite: `cd mailglass_inbound && mix test --seed 0` → **330 tests + 3 properties, 0 failures** (no regression from the new `suppression_flagged` schema column; the slow phase-45 1000-iter convergence property runs ~65s — known, green).
- Phase-49 file subset (the 11 touched/new test files): **141 tests, 0 failures** (98 for 49-01/49-02 + 43 for 49-03), `--seed 0`.
- Credo: `mix credo --strict` (repo root, covers `mailglass_inbound/lib/`) → **no issues** (426 files, 3354 mods/funs). PII denylist + 4-segment `TelemetryEventConvention` both green for the new inbound events.
- Inbound optional-dep compile: `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` → **green** (Oban-gated prune worker + gen_smtp-via-gateway doctor compile with optional deps stripped; no bare optional-dep refs). Dev build restored with optional deps afterward.
- All 6 in-scope code-review findings (CR-01, CR-02, WR-01, WR-02, WR-03, WR-04) carry named regression tests that pass; commits 4441547, a84be51, 700e85d, 12a392d, e729756, c878803 are on `main`.

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none — all 6 deliverables verified green by direct execution]

## Notes (non-blocking, surfaced to maintainer)

- **Pre-existing repo-wide format violation (NOT phase 49):** `mix format --check-formatted` fails on `test/mailglass/credo/credo_config_sentinel_test.exs` (an over-100-char `test "…"` head needs wrapping). The file was committed by **Phase 45** (`66ffcaa test(45-09): add .credo.exs config sentinel for CR-01/WR-02 keys`), is committed as-is (not working-tree drift), and is outside Phase 49's file set. A repo-wide `mix format --check-formatted` CI gate would currently fail on `main` because of this. Worth a one-line `mix format` fixup commit, independent of Phase 49.
- **Deferred code-review Info findings (out of scope, `fix_scope: critical_warning`):** IN-01 (`Module.concat` atom-minting fallback in `execution.ex` `decode_route`), IN-02 (`bucket_type/1` collapses unkeyed `:per_domain` → `:recipient`), IN-03 (rate-limit hot path re-validates config and can raise), IN-04 (doctor `:basic_auth` presence check accepts any non-nil shape). All four are latent (unreachable on the live path today) per `49-REVIEW.md`; none block the phase, but they are real hardening items if/when an inbound polish pass happens.
- **CR-02 / WR-01 semantic confirmation (flagged by the code-fixer for human review):** CR-02 widens parent retention windows UP (never narrows children) to satisfy the FK lineage — confirm no operator workflow expected evidence deleted before its referencing runs. WR-01 raises the sustained ingress rate from 60/min to the advertised capacity (tenant 1000/min, recipient 500/min, sender_domain 200/min) — confirm that ceiling matches production ingress sizing. Both are unit-tested; the flags are about *intended policy*, not code correctness.
