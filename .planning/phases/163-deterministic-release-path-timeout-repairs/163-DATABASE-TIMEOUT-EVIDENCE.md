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

## 163-04 immutable historical reconstruction (2026-08-26)

### Search scope and immutable identity

The retained local architecture evidence named CI run
[`32433156236`](https://github.com/szTheory/mailglass/actions/runs/32433156236).
Read-only GitHub Actions inspection confirmed its terminal identity without
persisting generated event values or raw exception text:

| Field | Recorded value |
| --- | --- |
| protected-run event | `pull_request` |
| run / job | `32433156236` / `96628985134` |
| terminal URLs | `https://github.com/szTheory/mailglass/actions/runs/32433156236` / `https://github.com/szTheory/mailglass/actions/runs/32433156236/job/96628985134` |
| `failing_sha` | `81e738e74d59d1ab36c3e1dc3adc03ad6d0c0b84` |
| job identity | `Core Deterministic Suite (Elixir 1.18 / OTP 27)` — failed in `Run deterministic core suite` |
| command / toolchain | `mix test --warnings-as-errors`; Elixir `1.18.4`, OTP `27.3.4.13`, PostgreSQL 16-alpine image pinned to `sha256:cf78e76683b9ca8c5733cbbdce6c9262b45b6767934dd0a95e671f9a0fc20685` |
| structured evidence available | `%Postgrex.Error{postgres: %{code: :query_canceled}}` / SQLSTATE `57014`; the hosted log did not expose structured severity or routine fields |
| historical property context | `Mailglass.Properties.WebhookIdempotencyConvergenceTest`, after 966 successful generated cases; the historical stack location was its per-iteration normalized shape `TRUNCATE TABLE mailglass_webhook_events CASCADE` |

The historical log also contained unrelated server-log entries and generated
values. They were deliberately excluded from this ledger. Its recorded
historical ExUnit seed was `674219`; it is retained only as a possible
reconstruction input and was not used for any proof run below.

### Bounded failed-run screening

The following ten most recent failed `CI` runs on `main` were screened
read-only. A run is not a database candidate when the deterministic job
succeeded, was absent, or never reached its test step. This screen therefore
does not treat a run-level failure as database evidence.

| Run | Head SHA | Deterministic-core observation | SQLSTATE 57014 authority |
| ---: | --- | --- | --- |
| 32865270291 | `fda6368bf43c49aab88e3f90da1d6af67ee77d35` | job succeeded | none |
| 32410997663 | `0f0b06861b1cbb2e89f44ea4f40db754effc4017` | failed before `Run deterministic core suite` | none |
| 32317995439 | `54aff6dc93f0b803f051d566e58c0dcae68d2ef1` | job succeeded | unrelated support-contract server log only |
| 30941753850 | `450dc6f4552863cec48d303209cc4e2a5ae8c1ae` | deterministic job absent | none |
| 30939432520 | `74baa55683b8ea779ceaa6c9d3c5ce838edf6e80` | deterministic job absent | none |
| 30728159087 | `f779a50fb2762eebc44f3dd5cdb4a3b53e606ab1` | deterministic job absent | none |
| 30726352828 | `313455a67b60c1b5221047190ed390f7449279f0` | deterministic job absent | none |
| 30656043835 | `1ca6bccacba364a33a5317b3268750852a406b3e` | deterministic job absent | none |
| 30642601790 | `34008138fdb779d01109da086dea0c468d5c75d9` | deterministic job absent | none |
| 30635221236 | `981b9343a8fec7eb82d0d7df3f3e06467b04f90a` | deterministic job absent | none |

### Disposable exact-SHA reconstruction

The exact SHA was fetched by object ID and checked out detached in a disposable
temporary worktree. The historical property source and current source retain
the same `SandboxOwnership.checkout!/1` ownership door, ten-minute owner
bound, cleanup/settle structure, generators, and `max_runs: 1000` contract.
No temporary operation labels or current source changes were needed.

Each attempt used the pinned `make toolchain` environment and only the affected
webhook property. All were unseeded, first-only attempts; no retry, exclusion,
reduced property count, deadline change, or global setting was used.

| Attempt | Command | Seed mode | Exit | Test elapsed | Structured 57014 | Cleanup |
| ---: | --- | --- | ---: | ---: | --- | --- |
| 1 | `make toolchain CMD='mix test test/mailglass/properties/webhook_idempotency_convergence_test.exs --warnings-as-errors'` | unseeded | 0 | 111900ms | not observed | disposable database reset by toolchain |
| 2 | same | unseeded | 0 | 262500ms | not observed | disposable database reset by toolchain |
| 3 | same | unseeded | 0 | 240000ms | not observed | disposable database reset by toolchain |

Effective transaction settings remained the historical finite local guards
inside `Repo.transact/1`: `statement_timeout = 2s` and `lock_timeout = 500ms`.
The original log's stack location is compatible with the per-iteration
`TRUNCATE` shape, but the reproduction captured no cancellation and the
available historical metadata lacks severity/routine. It therefore cannot
uniquely distinguish fixture cleanup, session contention, or query ownership.

### Search verdict

**Verdict: `inconclusive`.** The immutable run proves that a structured 57014
once occurred at the stated SHA and property, but all three allowed disposable
first attempts passed without a structured cancellation. No single current
fixture/session/isolation/query owner is attributed, and no repair, regression,
threshold, or post-repair three-run proof is authorized.

- **DTRM-01 boundary and precision remain flagged:** there is no reproduced
  cancellation from which to measure below/equal/above behavior; equality
  remains unproven and must not be treated as success.
- **DTRM-02 remains blocked:** the three passes above are historical
  reconstruction diagnostics, not post-repair proof.
- **Next action:** Task 2 requires a maintainer to either supply additional
  immutable structured evidence that enables a unique reproduction or explicitly
  re-scope/defer DTRM-01 through planning artifacts.
