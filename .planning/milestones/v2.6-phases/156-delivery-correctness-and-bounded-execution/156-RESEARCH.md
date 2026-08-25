# Phase 156: Delivery Correctness and Bounded Execution - Research

**Researched:** 2026-08-16
**Domain:** Elixir/OTP concurrent execution, ETS resource bounds, Ecto/Oban transactional dispatch, and privacy-safe delivery observability
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Core and inbound use one private atomic compare-and-swap token-bucket engine behind their existing public/package façades; independently released packages must remain usable on their own.
- Refill math uses monotonic fixed-point time so concurrent callers cannot overspend and sub-token elapsed time is retained.
- Default maximum cardinality is 100,000 keys, idle expiry is one hour, and sweep cadence is 60 seconds.
- At capacity, purge eligible idle entries first and fail closed if bounded capacity is still exhausted.
- Oban remains the durable default. Delivery projection, event, private payload, and job insertion commit in one database transaction or the caller receives an error with no stranded queued row.
- Task-supervisor fallback remains supported but is explicitly bounded to ten concurrent children per application by default. Every spawn result is inspected; saturation or supervisor failure is returned honestly and must never be reported as queued.
- `Mailglass.SendError` gains the additive reason `:dispatch_unavailable` and additive `retry_class: :transient | :permanent | nil`; existing serialized fields remain compatible.
- Transport errors, timeouts, HTTP 429, and HTTP 5xx retry. Permanent failures are discarded. Any provider-specific exceptional 4xx behavior must be explicit and adapter-aware rather than inferred by a broad fallback.
- Serializable error context contains no provider response preview, recipient, or message content.
- Tracking remains fail-open at the HTTP boundary, but `recorded` telemetry is emitted only after a successful ledger write; failures receive distinct privacy-safe telemetry.
- A provider dispatch has one authoritative span; remove the duplicate Swoosh façade/adapter span.
- Persisted and job strings map through finite explicit lookup functions. No unbounded `String.to_atom/1` conversion is permitted.

### the agent's Discretion
- Internal module placement, transaction composition, fixed-point scale, sweep implementation, and test fixture organization may follow the simplest existing package conventions that preserve compatibility.
- Tighten internal APIs where useful, but preserve documented core and inbound public façades.

### Deferred Ideas (OUT OF SCOPE)
- Inbound certificate/S3/dead-evidence hardening, database lifecycle work, broad architecture factoring, repository-wide quality gates, release certification, and all admin/operator UI work belong to later phases or remain explicitly out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| EXEC-01 | Concurrent core/inbound token refills cannot overspend or lose sub-token time. | Private CAS bucket engine, monotonic fixed-point state, barriers, and exact-success tests. |
| EXEC-02 | ETS storage expires idle keys, caps cardinality, and fails closed. | Owner-mediated admission/sweeping and explicit capacity result. |
| EXEC-03 | Batch delivery commits delivery/event/private payload/Oban job atomically. | One `Ecto.Multi` with `Oban.insert_all/…` before `Repo.multi/1`. |
| EXEC-04 | Task fallback bounds concurrency and reports spawn saturation/failure honestly. | Both application supervisors use `max_children: 10`; each dispatch result gates queued success. |
| EXEC-05 | Retry classification is closed and provider-aware. | Add `retry_class` to `SendError`, map adapter statuses/reasons, and have worker discard permanent outcomes. |
| EXEC-06 | Serialized errors contain no body preview, recipient, or message content. | Remove body-derived context/cause summaries and test JSON plus `last_error`. |
| EXEC-07 | Tracking telemetry records only successful writes while HTTP remains fail-open. | Branch on `Events.append/1` result; emit separate sanitized failure event and retain response behavior. |
| EXEC-08 | Persisted/job closed-set strings use explicit mappings. | Replace inbound source/provider and webhook-replay conversion with finite decoders. |
</phase_requirements>

## Summary

[VERIFIED: codebase] The phase can be delivered without adding a dependency. Core already exposes the durable seams (`Mailglass.Outbound`, `Mailglass.Repo.multi/2`, `Mailglass.OptionalDeps.Oban`) and inbound already depends on core through its path/Hex dependency while retaining its own public façades and configuration. The present risks are concrete: both rate limiters use a stale lookup followed by `:ets.update_counter/4`; batch persistence commits before the unchecked `Oban.insert_all/1`; core and inbound Task supervisors are unbounded; Swoosh serializes `body_preview`; tracking emits success telemetry after ignored append failures; and inbound plus webhook replay construct atoms from stored/job strings. [VERIFIED: codebase]

[CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] `Ecto.Multi` executes ordered operations in one repository transaction and rolls back the transaction on a failed operation. [CITED: https://oban.hexdocs.pm/Oban.html] Oban provides `insert` and `insert_all` forms that add job operations to an `Ecto.Multi`, including function forms that consume earlier changes. Therefore the durable default must construct all batch rows, events, private payload records (where applicable), and jobs before the single `Repo.multi/1` commit; the post-commit `insert_all` side effect cannot meet EXEC-03.

**Primary recommendation:** Implement a small, core-owned private CAS token-bucket engine used by each package façade; then make durable batch dispatch one transaction, treat fallback admission as an explicit result, and centralize closed retry/error decoding before touching any UI.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Token consumption and bounded ETS state | API / Backend | — | Node-local admission state belongs with supervised backend runtime processes. [VERIFIED: codebase] |
| ETS table lifecycle and sweep timing | API / Backend | — | Existing `TableOwner` GenServers own the named ETS tables. [VERIFIED: codebase] |
| Delivery/event/payload/job atomicity | Database / Storage | API / Backend | Ecto transaction commits mailglass and Oban rows together. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| Durable execution and retry outcome | API / Backend | Database / Storage | Worker classifies a normalized `SendError`; Oban persists/retries its job. [VERIFIED: codebase] |
| Best-effort task admission | API / Backend | — | `Task.Supervisor` is a runtime resource boundary, not a client concern. [CITED: https://hexdocs.pm/elixir/1.18.0/Task.Supervisor.html] |
| Tracking response behavior | API / Backend | Database / Storage | Plug always returns image/redirect while ledger result controls telemetry. [VERIFIED: codebase] |
| Error serialization and finite decoders | API / Backend | — | Provider/job/database values must be normalized before they affect retry or atoms. [VERIFIED: codebase] |

## Standard Stack

### Core

| Library | Version in lockfile | Purpose | Why Standard |
|---|---:|---|---|
| Elixir/OTP `:ets`, `Task.Supervisor`, `DynamicSupervisor` | Elixir `~> 1.18`, local OTP 28 | Atomic in-node state and bounded fallback tasks | Existing runtime primitives; no new package required. [VERIFIED: codebase] |
| Ecto / Ecto SQL | 3.14.0 | Ordered transactional persistence | Existing host-repo façade exposes `Repo.multi/2` and per-step schema prefix options. [VERIFIED: codebase] |
| Oban | 2.23.1 | Optional durable background jobs | Existing optional gateway already wraps `Oban.insert/…`; official API supports Multi insertion. [VERIFIED: codebase; CITED: https://oban.hexdocs.pm/Oban.html] |
| Telemetry | existing project dependency | One authoritative dispatch span and outcome counters | Existing named helper surface keeps metadata checks centralized. [VERIFIED: codebase] |

### Supporting

| Library | Purpose | When to Use |
|---|---|---|
| ExUnit / `Task.async_stream` | Deterministic concurrency and transaction tests | Use barriers/acknowledgements for concurrent buckets and supervisor saturation, never timing sleeps. [VERIFIED: codebase] |
| Jason | Existing error serialization proof | Assert encoded errors and persisted `last_error` omit sensitive response data. [VERIFIED: codebase] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| ETS CAS engine | A GenServer-serialized limiter | Serializes hot-path traffic through one mailbox and contradicts the locked private atomic engine direction. [ASSUMED] |
| Oban Multi insertion | Post-commit job insertion | Cannot provide all-or-nothing durable batch semantics. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| Explicit finite decoding | `String.to_existing_atom/1` for values known to be loaded | Existing-atom conversion prevents allocation but accepts an accidentally pre-existing unrelated atom; finite mappings enforce the closed contract. [ASSUMED] |

**Installation:** None — use currently locked dependencies. [VERIFIED: codebase]

## Architecture Patterns

### System Architecture Diagram

```text
core Message / inbound request
          |
          v
existing package façade and package-local config/error shaping
          |
          v
private CAS token bucket ----> owner-mediated new-key admission / idle sweep
          |                                   |
      allow | deny                         full + no idle => fail closed
          v
preflight / durable route
          |
          +-- Oban available --> one Ecto.Multi:
          |                    delivery + event + private payload + Oban jobs
          |                              |
          |                           commit or rollback
          |
          +-- fallback -------> bounded Task.Supervisor.start_child
                                      |
                          {:ok, pid} => queued / {:error, _} => dispatch_unavailable

Oban worker -> one dispatch span -> adapter -> SendError(retry_class)
                                  |                  |
                                  v                  +-- permanent => discard
                            persistence outcome      +-- transient => retry

tracking Plug -> ledger append -> success telemetry OR failure telemetry -> unchanged HTTP reply
```

### Recommended Project Structure

```text
lib/mailglass/rate_limiter/
  atomic_bucket.ex       # private shared engine and pure state helpers
  table_owner.ex         # table ownership, admission, scheduled sweep
lib/mailglass/outbound/
  dispatch_error.ex      # closed retry/error normalization if separation improves clarity
  async_adapter/task_supervisor.ex
mailglass_inbound/lib/mailglass_inbound/
  rate_limiter.ex        # package-local façade/config/error shape only
  execution.ex           # finite source/provider decoders and fallback handling
```

Keep `Mailglass.RateLimiter` and `MailglassInbound.RateLimiter` public signatures intact. Inbound may call a private core engine because inbound already declares a core dependency, but its table name, configuration interpretation, error type/context, and application child remain package-local. [VERIFIED: codebase]

### Pattern 1: Exact-match CAS bucket state

**What:** Store each bucket as `{key, tokens_scaled, last_monotonic_unit, remainder}` (or equivalent fixed-point integer state). Recalculate from the exact observed tuple, then use `:ets.select_replace/2` with an exact-match guard to replace it; retry a bounded CAS loop when another caller won the race. [VERIFIED: codebase; ASSUMED]

**When to use:** Every existing bucket consumption. New-key creation and table-capacity admission must not race through `:ets.insert_new/2` alone; send those through the owner/admission primitive so cardinality is enforced. [VERIFIED: codebase; ASSUMED]

**Implementation rules:**

- Use `System.monotonic_time/1` and integer fixed-point units; do not use float refill arithmetic or `round/1`, which loses fractional accumulation. [VERIFIED: codebase]
- On every successful state transition, advance the stored timestamp/remainder from the exact state used in the CAS. [ASSUMED]
- When `select_replace` returns zero, re-read and recompute; do not decrement from a stale tuple. [ASSUMED]
- Preserve named ETS tables and current table-owner supervision to avoid a public API change. [VERIFIED: codebase]

### Pattern 2: Bounded admission with predictable expiration

**What:** Owner process tracks periodic sweep scheduling and exposes a synchronous admission operation for missing keys. On `max_keys`, delete only entries whose `last_seen` is older than one hour, then retry admission once; if still full return a typed denied result. [ASSUMED]

**When to use:** Attacker-controlled core recipient/domain and inbound recipient keys. [VERIFIED: codebase]

**Anti-patterns to avoid:**

- **Stale read + `update_counter`:** Current core and inbound code lookup `{tokens,last}`, compute a refill, then mutate later; this permits overspend under concurrent refill. [VERIFIED: codebase]
- **Unbounded local ETS:** Node-local does not make memory growth harmless when keys derive from requester input. [VERIFIED: codebase]
- **Sweep on every hot-path request:** It makes capacity control expensive and still races without owner admission. [ASSUMED]

### Pattern 3: One durable batch transaction

**What:** Build a single `Ecto.Multi`: bulk delivery rows, queued events for inserted rows, required private payload rows, and an `Oban.insert_all` Multi operation generated only from the rows that need execution. Execute once through `Mailglass.Repo.multi/1`; only construct the return projection after success. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html; CITED: https://oban.hexdocs.pm/Oban.html]

**Current fit:** `insert_batch/1` currently commits deliveries/events at `lib/mailglass/outbound.ex:564-607`; `enqueue_batch_jobs/1` then calls `Mailglass.OptionalDeps.Oban.insert_all/1` and discards its result at `:631-680`. `deliver_later/2` already demonstrates the correct single-delivery shape by adding `Mailglass.OptionalDeps.Oban.insert(:job, ...)` to its Multi. [VERIFIED: codebase]

**Implementation rules:**

- Extend the optional Oban gateway with a Multi-capable `insert_all` wrapper rather than directly referencing Oban in `Outbound`. [VERIFIED: codebase]
- Keep all mailglass database steps decorated with `Repo.multi_opts()` because the repo façade does not inject prefix into inner Multi steps. [VERIFIED: codebase]
- Treat an unavailable optional Oban dependency as selecting the explicit fallback before durable persistence; do not silently omit a job step from a claimed durable route. [VERIFIED: codebase; ASSUMED]
- If a private outbound payload table is part of the existing deployment contract, include its write in this same Multi; verify actual schema/model location before implementation because this checkout's `Outbound` currently persists rendered content in delivery metadata. [VERIFIED: codebase]

### Pattern 4: Honest bounded fallback

**What:** Start both application Task supervisors with `max_children: 10`, and normalize every `start_child` result to `{:ok, queued}` or a `SendError(:dispatch_unavailable)`. [CITED: https://hexdocs.pm/elixir/1.18.0/Task.Supervisor.html]

**Current fit:** Core starts `{Task.Supervisor, name: Mailglass.TaskSupervisor}`; inbound starts `{Task.Supervisor, name: MailglassInbound.TaskSupervisor}`; neither gives a limit. Core `enqueue_task_supervisor/3` and batch fallback ignore `AsyncAdapter.dispatch/2` results, while inbound currently returns its result but has no bound. [VERIFIED: codebase]

**Implementation rules:**

- Keep fallback best-effort and do not claim durable enqueue. [VERIFIED: codebase]
- Catch supervisor exits/raises around admission only if normalized into the honest unavailable result; never return queued after an exception. [ASSUMED]
- In tests, occupy all children with a barrier, then attempt one extra admission and assert error; release through messages, not `Process.sleep/1`. [ASSUMED]

### Pattern 5: Closed retry and privacy normalization

**What:** Add `retry_class` to `SendError` as a field that is available to in-process code but preserve existing JSON fields (`type`, `message`, `context`). Set it only via finite adapter mappings: timeout/transport → transient; status 429 or 500..599 → transient; 400..499 → permanent unless that adapter explicitly documents a distinct condition. [VERIFIED: codebase; ASSUMED]

**Current fit:** `SendError.retryable?/1` currently makes every `:adapter_failure` retryable; Swoosh maps any 4xx to `:client_error`, includes `body_preview`, and builds a cause message containing the preview. Worker returns `{:error, err}` for every failed dispatch, so Oban retries permanent errors. [VERIFIED: codebase]

**Implementation rules:**

- Add `:dispatch_unavailable` to the closed type list and stability tests/docs. [VERIFIED: codebase]
- Do not derive `retry_class` from untrusted arbitrary reason text; map only known reason/status shapes. [ASSUMED]
- Remove `body_preview/1`, eliminate response-body text from `context` and cause-message construction, and assert both `Jason.encode!` and persisted `last_error` omit recipient, subject, rendered bodies, and provider body sentinel text. [VERIFIED: codebase]
- Make worker return Oban's documented discard result for permanent failures and an error only for transient failures; confirm the exact tuple supported by locked Oban 2.23 during implementation with its local docs/source. [ASSUMED]

### Pattern 6: Outcome-coupled telemetry and finite values

**What:** Tracking calls `Events.append/1`, emits `:recorded` only for `{:ok, _}`, emits a separate failure event for `{:error, _}`/rescues, and then returns the same GIF/redirect response. Each event metadata map contains only delivery ID, tenant ID, and an allowlisted failure class. [VERIFIED: codebase; ASSUMED]

**Current fit:** `Tracking.Plug` currently assigns append output but unconditionally emits `:recorded`; the rescue returns `:ok`. `Outbound.call_adapter/2` and `Adapters.Swoosh.deliver/2` each wrap the same provider call in `dispatch_span`, producing duplicate spans. [VERIFIED: codebase]

**Finite decoder rules:**

- `MailglassInbound.Execution.Worker.source_from_args/1`: map only `"fresh"` and the other documented source literals, default/reject invalid input. [VERIFIED: codebase]
- `MailglassInbound.Execution.normalize_provider/1`: map only package-supported provider strings. [VERIFIED: codebase]
- `Mailglass.Webhook.Replay.build_success_result/4`: map stored webhook provider strings through the same finite core provider decoder. [VERIFIED: codebase]
- Do not broaden this phase into UI-only `String.to_atom` usages, installer parsing, or bounded compile-time atom construction unless they are persisted/job values in the execution path. [VERIFIED: codebase]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Transactional jobs | A separate “commit then enqueue” compensating path | `Oban.insert_all` inside `Ecto.Multi` | Existing Oban API gives jobs the same database commit boundary. [CITED: https://oban.hexdocs.pm/Oban.html] |
| Fallback lifecycle | Custom process registry/counter | `Task.Supervisor` with `max_children` | Existing supervised dynamic task primitive provides lifecycle and capacity enforcement. [CITED: https://hexdocs.pm/elixir/1.18.0/Task.Supervisor.html] |
| Retry state storage | New retry table | Oban worker result plus closed `SendError` classification | Oban already owns durable attempts. [VERIFIED: codebase] |
| Error redaction | Generic string scrubber | Allowlist error context at construction | Scrubbing is incomplete; never serialize body/message fields in the first place. [ASSUMED] |

## Common Pitfalls

### Pitfall 1: CAS only protects updates, not missing-key capacity

**What goes wrong:** Exact replacement fixes concurrent decrements but concurrent first hits can still exceed `max_keys`. [ASSUMED]

**How to avoid:** Route missing-key creation through the owner/admission path, perform idle purge there, and make a full table an explicit deny. [ASSUMED]

### Pitfall 2: A successful delivery insert is not a successful durable queue

**What goes wrong:** The existing batch can return queued after `Oban.insert_all` errors because its result is discarded. [VERIFIED: codebase]

**How to avoid:** Put the jobs in the same Multi and test an induced job-step error rolls back rows/events. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html]

### Pitfall 3: Retrying all adapter errors turns invalid recipients into retry storms

**What goes wrong:** Current `SendError.retryable?/1` conflates 422 and 500. [VERIFIED: codebase]

**How to avoid:** Classify concrete provider status/reason into transient or permanent, then have worker outcome follow that class. [ASSUMED]

### Pitfall 4: PII can leak even when forbidden context keys are absent

**What goes wrong:** A provider body is currently allowed under `:body_preview`, and `last_error` derives an exception message. [VERIFIED: codebase]

**How to avoid:** Assert a unique provider-body sentinel is absent from `SendError.context`, JSON, exception message, and persisted map. [ASSUMED]

### Pitfall 5: Sleep-based async tests prove timing, not correctness

**What goes wrong:** Existing rate refill and task tests use sleeps/accept queued-or-sent outcomes. [VERIFIED: codebase]

**How to avoid:** Inject clock/engine parameters where needed and use barriers, receive assertions, worker stubs, and Multi failure injection. [ASSUMED]

## Code Examples

### Transactional batch job insertion

```elixir
# Sources: https://ecto.hexdocs.pm/Ecto.Multi.html
#          https://oban.hexdocs.pm/Oban.html
multi =
  Ecto.Multi.new()
  |> Ecto.Multi.insert_all(:deliveries, Delivery, rows, Repo.multi_opts(returning: true))
  |> Ecto.Multi.run(:events, &insert_events_for_inserted_rows/2)
  |> Mailglass.OptionalDeps.Oban.insert_all(:jobs, fn %{deliveries: {_count, rows}} ->
    Enum.map(rows, &Mailglass.Outbound.Worker.new(job_args(&1)))
  end)

case Repo.multi(multi) do
  {:ok, %{deliveries: {_count, rows}}} -> {:ok, rows}
  {:error, _step, reason, _changes} -> {:error, to_error(reason)}
end
```

### Finite job value decoder

```elixir
# Source: project closed-set requirement; no runtime atom construction.
defp source_from_args(%{"source" => "fresh"}), do: {:ok, :fresh}
defp source_from_args(%{"source" => "replay"}), do: {:ok, :replay}
defp source_from_args(_), do: {:error, :invalid_job_args}
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | `:ets.select_replace/2` is the simplest acceptable CAS primitive for the exact tuple state. | Pattern 1 | Engine API or match-spec details may need adjustment. |
| A2 | Owner-mediated admission plus periodic sweep is simpler than lock-free cardinality accounting. | Pattern 2 | Could affect hot-path first-key latency, not public behavior. |
| A3 | Locked Oban worker version accepts a discard result for permanent errors. | Pattern 5 | Must verify exact result before worker edit. |
| A4 | Fixed-point scale and clock injection can be internal without public API impact. | Patterns 1 and 5 | Test seam may need a package-private option instead. |

## Open Questions (RESOLVED)

1. **Where is the private outbound payload write in the current delivery deployment?**
   - What we know: this checkout stores rendered values in delivery metadata and contains no obvious `OutboundPayload` schema. [VERIFIED: codebase]
   - **Accepted answer:** Existing rendered delivery metadata is the current private outbound payload representation. Keep that write in the same Multi and do not invent a new schema. [RESOLVED: Phase 156 planning]
2. **Which non-Swoosh adapters have a documented exceptional 4xx retry case?**
   - What we know: Phase decision permits exceptions only when explicit and adapter-aware. [VERIFIED: CONTEXT.md]
   - **Accepted answer:** Swoosh 4xx outcomes are permanent by default. Add no exceptional retryable 4xx without provider-specific evidence and a regression test. [RESOLVED: Phase 156 planning]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Elixir/Mix | compile/test | ✓ | Elixir ~1.18, OTP 28 | — [VERIFIED: local environment] |
| PostgreSQL | Ecto atomic integration tests | ✓ | localhost accepts connections | Existing test repo [VERIFIED: local environment] |
| Oban | durable Multi and worker tests | ✓ | 2.23.1 lockfile | Test gateway/stub for selected failure paths [VERIFIED: codebase] |

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit, existing core/inbound test suites [VERIFIED: codebase] |
| Core quick run | `mix test test/mailglass/rate_limiter_test.exs test/mailglass/adapters/swoosh_test.exs test/mailglass/tracking/plug_test.exs --warnings-as-errors` |
| Inbound quick run | `cd mailglass_inbound && mix test test/mailglass_inbound/rate_limiter_test.exs test/mailglass_inbound/async_execution_test.exs --warnings-as-errors` |
| Full suite | `mix ci` and `cd mailglass_inbound && mix ci` [VERIFIED: codebase] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| EXEC-01 | Exact concurrent capacity and fractional refill | deterministic concurrency/unit | core + inbound rate limiter files | ✅ extend |
| EXEC-02 | idle eviction, full-table deny, sweep | owner/ETS integration | rate limiter supervision files | ✅ extend |
| EXEC-03 | rollback when job insertion fails; no queued stranding | Ecto/Oban integration | `mix test test/mailglass/outbound/deliver_many_test.exs` | ✅ extend |
| EXEC-04 | max ten and rejected 11th task | supervisor barrier test | core/inbound async tests | ✅ extend |
| EXEC-05 | timeout/429/5xx retry; 4xx discard | adapter + worker unit | Swoosh/worker tests | ✅ extend/new worker test |
| EXEC-06 | JSON and persisted error redaction | unit/integration | Swoosh/error/outbound tests | ✅ extend |
| EXEC-07 | only success emits recorded; failure has distinct event | Plug telemetry | tracking plug test | ✅ extend |
| EXEC-08 | bad persisted/job provider/source never creates atom | decoder unit/regression | inbound execution + webhook replay tests | ✅ extend |

### Wave 0 Gaps

- [ ] Deterministic rate-limit engine clock/barrier fixture — covers EXEC-01 and EXEC-02.
- [ ] Oban Multi failure gateway or test adapter — covers EXEC-03 without a real post-commit race.
- [ ] Supervisor occupancy barrier helper — covers EXEC-04.
- [ ] Worker outcome tests for transient/permanent classifications — covers EXEC-05.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V5 Input Validation | yes | finite decoding of persisted/job strings; reject invalid values. [VERIFIED: codebase] |
| V7 Error Handling and Logging | yes | allowlisted serialization and PII-free telemetry. [VERIFIED: codebase] |
| V8 Data Protection | yes | never persist provider response preview or message/recipient content in error state. [VERIFIED: CONTEXT.md] |
| V10 Malicious Code | no | No dynamic evaluation or package install is in scope. [VERIFIED: phase scope] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Unique requester keys exhaust ETS | Denial of Service | cardinality cap, idle eviction, fail-closed admission. [VERIFIED: CONTEXT.md] |
| Concurrent stale bucket update overspends quota | Elevation of Privilege | exact-match CAS and deterministic race test. [VERIFIED: codebase] |
| Provider error body leaks data | Information Disclosure | no body-derived serializable context/cause; JSON/persistence tests. [VERIFIED: codebase] |
| Stored/job string creates atoms | Denial of Service | finite literal mapping and invalid-input error. [VERIFIED: codebase] |
| Task overload is reported as queued | Repudiation/DoS | supervisor cap and explicit failure result. [VERIFIED: CONTEXT.md] |

## Likely Plan Decomposition

1. **Rate-limit engine and table ownership:** core private CAS engine, core/inbound façades, config defaults, table owner sweep/admission, deterministic concurrency/capacity tests (EXEC-01, EXEC-02).
2. **Atomic durable dispatch:** extend Oban gateway for Multi `insert_all`, fold batch jobs/private persistence into the one `Ecto.Multi`, make job failure rollback observable, preserve idempotency replay semantics (EXEC-03).
3. **Bounded fallback dispatch:** max-children core/inbound supervisors, normalize/inspect all core batch/single and inbound task spawn results, barrier saturation tests (EXEC-04).
4. **Retry/privacy/telemetry correctness:** additive `SendError` contract and docs, Swoosh classification/redaction, worker discard behavior, one dispatch span, tracking success/failure telemetry (EXEC-05, EXEC-06, EXEC-07).
5. **Finite persisted/job decoders:** inbound execution worker/provider and core webhook replay mappings with invalid-value regression tests (EXEC-08).

The executable dependency order is 1 → 2 → 3 → 4 → 5: Plans 2 and 3 both edit `Mailglass.Outbound`, while Plan 5 consumes the worker outcome convention established by Plan 4. Final focused validation covers core and inbound. [RESOLVED: Phase 156 planning]

## Sources

### Primary
- [Ecto.Multi v3.14.1](https://ecto.hexdocs.pm/Ecto.Multi.html) — transaction and failure semantics.
- [Ecto.Repo v3.14.1](https://ecto.hexdocs.pm/Ecto.Repo.html) — Multi transaction result/rollback semantics.
- [Oban v2.23.0](https://oban.hexdocs.pm/Oban.html) — `insert`/`insert_all` Multi APIs.
- [Elixir Task.Supervisor v1.18](https://hexdocs.pm/elixir/1.18.0/Task.Supervisor.html) — supervised task and `max_children` configuration.
- Live codebase — current limiter, dispatcher, error, tracking, and decoder seams. [VERIFIED: codebase]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing locked dependencies and local source confirmed.
- Architecture: HIGH — current code paths and official Ecto/Oban/Task contracts align with locked decisions.
- Pitfalls: HIGH — each primary failure is reproduced by current source shape; implementation mechanics marked assumed where no local proof exists.

**Research date:** 2026-08-16
**Valid until:** 2026-09-15
