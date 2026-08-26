---
phase: 163
plan: 01
artifact: database-timeout-evidence
status: unattributed
append_only: true
---

# Database Timeout Evidence

## Scope and capture rules

This record contains commands, integer-millisecond elapsed observations,
structured PostgreSQL metadata when a failure is captured, and normalized query
shapes only. It deliberately excludes webhook bodies, provider event IDs,
recipient/message content, tenant secrets, and raw exception text.

The diagnostic budget is at most three unseeded invocations per property. No
seed, retry, property exclusion, reduced `max_runs`, global timeout, CI/job
deadline, worker, or product setting was changed during these captures.

## Unmodified local diagnostic invocations

The local database was concurrently serving unrelated repository checks. These
two first attempts were started unmodified and unseeded, but the execution
harness detached before it returned each process's terminal exit code or
monotonic duration. They are retained as non-authoritative observations and are
not used as release-path proof.

| Property | Command | First-attempt terminal observation | SQLSTATE 57014 |
| --- | --- | --- | --- |
| `Mailglass.Properties.IdempotencyConvergenceTest` | `MIX_ENV=test mix test test/mailglass/properties/idempotency_convergence_test.exs --warnings-as-errors` | terminal exit and elapsed milliseconds not observable after harness detachment; no `query_canceled` metadata appeared before detachment | not captured |
| `Mailglass.Properties.WebhookIdempotencyConvergenceTest` | `MIX_ENV=test mix test test/mailglass/properties/webhook_idempotency_convergence_test.exs --warnings-as-errors` | terminal exit and elapsed milliseconds not observable after harness detachment; no `query_canceled` metadata appeared before detachment | not captured |

## Pinned gating-toolchain diagnostic invocations

Toolchain: `make toolchain` — Elixir 1.18.4, OTP 27, 2-vCPU container and
containerized PostgreSQL. Every invocation was unseeded and used its first and
only attempt.

| Property | Command | Repetition | Exit | Monotonic elapsed | Test elapsed | SQLSTATE 57014 |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| `Mailglass.Properties.IdempotencyConvergenceTest` | `make toolchain CMD='mix test test/mailglass/properties/idempotency_convergence_test.exs --warnings-as-errors'` | 1 | 0 | capture wrapper failed after the passing test while assigning zsh's readonly `status`; no authoritative wrapper duration | 81.2s | not captured |
| `Mailglass.Properties.WebhookIdempotencyConvergenceTest` | `make toolchain CMD='mix test test/mailglass/properties/webhook_idempotency_convergence_test.exs --warnings-as-errors'` | 1 | 0 | 107671ms | 102.4s | not captured |
| `Mailglass.Properties.IdempotencyConvergenceTest` | `make toolchain CMD='mix test test/mailglass/properties/idempotency_convergence_test.exs --warnings-as-errors'` | 2 | 0 | 73294ms | 65.7s | not captured |

The two passing properties each retained `max_runs: 1000`. The idempotency
property retained `sandbox: false`, its per-owner `10 * 60_000` ownership
timeout, committed-write behavior, generator range, convergence assertions, and
cleanup shape. The webhook property retained its per-owner `10 * 60_000`
ownership timeout, shared checkout, settle behavior, generator range,
convergence assertions, and cleanup shape.

## Structured PostgreSQL attribution

No `%Postgrex.Error{postgres: %{code: :query_canceled}}` was captured in the
diagnostic budget. Consequently there is no structured `code`, `severity`, or
`routine`, affected operation label, or failure query shape to persist.

The known webhook transaction configuration remains an **unproven hypothesis**:

| Candidate boundary | Effective setting | Normalized query shape | Result |
| --- | --- | --- | --- |
| `Ingest.ingest_multi/3` transaction session | `SET LOCAL statement_timeout = '2s'`; `SET LOCAL lock_timeout = '500ms'` | `SET LOCAL <timeout>; transaction-local webhook ingest multi` | No SQLSTATE 57014 was observed, so neither setting is attributed. |

Other candidate labels (`setup truncate`, `per-iteration truncate`, `aggregate`,
`snapshot`, and `cleanup`) are likewise un-attributed: no cancellation was
observed at any of them.

## Diagnosis verdict

**Verdict: `unattributed`.** The required PostgreSQL SQLSTATE 57014 was not
reproduced on an unseeded pinned-toolchain invocation, and no single
fixture/session/query owner can be selected honestly. The local runs were
non-authoritative because their terminal observations were not returned while
unrelated checks shared the local database. Under the phase plan, this verdict
blocks Task 2: no fixture, isolation, query, transaction-local timeout, source,
or regression change is authorized.

## Boundary and precision status

- **FLAGGED-UNVERIFIED — DTRM-01 boundary:** No attributed timeout exists from
  which to derive a minimum, maximum, threshold, or one-millisecond-below/above
  case.
- **FLAGGED-UNVERIFIED — DTRM-01 precision:** PostgreSQL cancellation rounding
  and equality/tie behavior were not measured because no SQLSTATE 57014 was
  captured.

## Append-only local verification addendum

After the diagnostic capture, the plan's exact local focused-pair verification
completed unseeded on its first attempt:

| Command | Exit | Monotonic elapsed | Result |
| --- | ---: | ---: | --- |
| `MIX_ENV=test mix test test/mailglass/properties/idempotency_convergence_test.exs test/mailglass/properties/webhook_idempotency_convergence_test.exs --warnings-as-errors` | 0 | 126865ms | 2 properties, 0 failures; no `query_canceled`/SQLSTATE 57014 captured. |

This confirms the tracer verification but does not alter the `unattributed`
verdict or authorize Task 2.
