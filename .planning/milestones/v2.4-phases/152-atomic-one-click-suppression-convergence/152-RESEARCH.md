# Phase 152: Atomic One-Click Suppression Convergence - Research

**Researched:** 2026-08-03
**Domain:** RFC 8058 one-click unsubscribe; Ecto/PostgreSQL transaction convergence; schema-prefix safety
**Confidence:** HIGH for repository integration; MEDIUM for library/database documentation

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Token authority and derived scope

- **D-01:** The signed one-click token identifies a Delivery; it does not carry independent authority for tenant, recipient, or stream. The server derives the tenant, normalized recipient address, and originating stream from the stored Delivery.
- **D-02:** The initial Delivery lookup remains the existing narrowly audited unscoped lookup by opaque Delivery ID only. After resolving the tenant, every event and suppression read/write runs inside restored tenant context and against the configured schema prefix.
- **D-03:** A missing Delivery, invalid/tampered token, or expired token is a privacy-preserving no-op. These cases retain the exact empty HTTP 200 response and reveal no delivery existence or token-validity distinction.

#### Atomic canonical convergence

- **D-04:** One database transaction must create or reuse both durable facts: the canonical `unsubscribed` event for the originating Delivery and one immutable `address_stream` suppression with reason `unsubscribe` for the derived tenant/address/stream. Neither fact may commit alone.
- **D-05:** Event identity remains delivery-based through the canonical `unsubscribe:<delivery_id>` idempotency key. Suppression identity is the existing tenant/address/scope/stream uniqueness contract. Implementation may use conflict-safe insertion plus refetch, but a uniqueness race must converge rather than become a false failure.
- **D-06:** Concurrent and replayed valid POSTs converge on the same event/suppression pair. Every successful convergence returns the required exact empty HTTP 200 response; it never produces duplicate durable facts.
- **D-07:** An actual database/convergence failure returns a non-success response and leaves no partial event/suppression pair. It must not be disguised as the privacy-preserving 200 used for invalid, expired, or absent-token targets.

#### Immediate enforcement and scope isolation

- **D-08:** The suppression address uses the project's canonical normalized-recipient representation, and the stream comes from the originating Delivery. No request parameter or token field may widen or substitute that scope.
- **D-09:** Once the transaction commits, the next preflight for the same tenant/address/stream is blocked. An `address_stream` unsubscribe must not block transactional mail or mail in unrelated streams.
- **D-10:** Immediate enforcement is proved through the real preflight/send boundary, not only by asserting that a suppression row exists.

#### Post-commit side effects

- **D-11:** Database mutation completes before any host lifecycle callback or broadcast. The existing one-click path's in-`Ecto.Multi` lifecycle behavior is superseded where necessary to enforce this ordering.
- **D-12:** Callbacks and broadcasts are best-effort post-commit effects. Their failure cannot roll back or partially alter the Mailglass event/suppression pair, and it cannot cause a valid committed unsubscribe to be reported as a failed database convergence.
- **D-13:** External/host side effects run only for the request that newly creates the convergence. Replays and uniqueness-race losers do not emit duplicate callbacks or broadcasts.
- **D-14:** Side-effect payloads contain only bounded, non-sensitive domain facts already appropriate for the host integration; the signed token and private message content are never forwarded.

#### Tenant and schema hardening

- **D-15:** Every operation added to an `Ecto.Multi`, including conflict resolution and refetch, receives the configured prefix explicitly where required by Ecto. Correctness must not depend on the connection's `search_path`.
- **D-16:** Hostile-`search_path` tests must include decoy or absent default-schema data and prove that both durable facts land only in the configured tenant-safe schema.
- **D-17:** Failure injection must prove rollback of the complete pair, a non-success response, and zero callback/broadcast effects.

#### Compatibility and evidence

- **D-18:** Preserve the public one-click route and exact empty success-body contract. Internal lifecycle seams may evolve to post-commit execution, but unrelated public callback compatibility should be retained where it does not conflict with D-11 through D-13.
- **D-19:** Contract tests must cover first POST, serial replay, true concurrent replay, uniqueness races, invalid/expired/missing targets, transaction rollback, post-commit effect failure, suppression preflight enforcement, stream isolation, tenant isolation, and hostile schema search paths.

### the agent's Discretion

- Internal module/function names for the convergence service and post-commit effect runner.
- Whether concurrency is implemented with conflict-target inserts, locks, or a compatible combination, provided D-04 through D-07 hold under real concurrent database tests.
- Exact non-success HTTP status for a genuine convergence failure, provided it is stable, documented, and never an empty success.
- The minimal compatibility adapter needed to move the current lifecycle hook out of `Ecto.Multi` while preserving unaffected host integrations.
- Exact broadcast topic/event name where the existing projector convention already supplies a compatible choice.

### Deferred Ideas (OUT OF SCOPE)

- Generated Phoenix host, production-shaped Oban proof, broad executable adopter journey, and release ceremony — Phase 153.
- New suppression scopes, unsubscribe preference centers, GET-based unsubscribe semantics, or token-format redesign.
- Phase 151 provider-dispatch and private-payload lifecycle changes.
- Exactly-once guarantees for arbitrary external host systems; Phase 152 guarantees no duplicate invocation from Mailglass replays/concurrency within its process boundary.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| UNSUB-07 | Valid POST atomically creates/reuses canonical event and `address_stream` suppression. | One `Ecto.Multi` with two conflict-safe inserts and canonical-row resolution. |
| UNSUB-08 | Concurrent/replayed POSTs converge with empty success and no duplicate effects. | Unique indexes are the concurrency authority; created flags gate post-commit effects. |
| UNSUB-09 | Committed suppression blocks next matching preflight only. | Exercise `Outbound.do_send`/`do_deliver_later` preflight, not just storage. |
| UNSUB-10 | DB completes before callbacks/broadcasts. | Run effects after `Repo.multi/1` returns `{:ok, changes}`. |
| UNSUB-11 | Hostile `search_path` stays tenant/prefix safe and failed convergence is non-success/atomic. | Prefix every Multi callback operation/refetch and add decoy-schema + injected-failure integration tests. |
</phase_requirements>

## Summary

The repository already has the correct durable identities: `Events.append_multi/3` uses the partial unique `unsubscribe:<delivery_id>` event key, while `mailglass_suppressions` has a unique tenant/address/scope/stream identity and `Entry.changeset/1` normalizes the address. The controller currently stops halfway: it creates/refetches the event but not the suppression, and invokes `Mailglass.Lifecycle.handle_event/2` inside the `Ecto.Multi`. [VERIFIED: codebase grep]

Implement a small internal convergence service which receives only a trusted persisted `%Delivery{}`. Within restored tenant context, build one flat `Ecto.Multi`: append/refetch the event, conflict-safe insert/refetch the immutable suppression, determine whether this request newly completed a missing part of the pair, and return canonical rows. Apply `Repo.multi_opts()` to every direct Ecto operation and every raw callback-repo query. Then, and only after `Repo.multi/1` returns success, run a compatibility-aware lifecycle adapter and `Projector.broadcast_delivery_updated/3`; rescue/log their failures. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] [CITED: https://ecto.hexdocs.pm/multi-tenancy-with-query-prefixes.html]

RFC 8058 requires the sender to handle an HTTPS POST and prohibits an HTTPS redirect; it specifies request encodings but does not prescribe a response status or body. Therefore the byte-empty HTTP 200 is Mailglass's locked privacy/compatibility contract, not an RFC-derived status requirement. [CITED: https://www.rfc-editor.org/rfc/rfc8058]

**Primary recommendation:** Use one prefix-explicit `Ecto.Multi` with database uniqueness plus canonical refetches; gate best-effort post-commit effects on `completed?` (at least one previously missing fact was inserted), never on merely receiving HTTP POST.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Verify opaque token and resolve Delivery | API / Backend | Database / Storage | Token has delivery identity only; the stored row is the trusted scope source. [VERIFIED: `unsubscribe_controller.ex`] |
| Event + suppression convergence | Database / Storage | API / Backend | Unique indexes and transaction boundary decide replay/concurrency correctness. [CITED: https://www.postgresql.org/docs/current/sql-insert.html] |
| Scope-aware send block | API / Backend | Database / Storage | Outbound preflight queries suppression immediately before persistence/dispatch. [VERIFIED: `outbound.ex`, `suppression.ex`] |
| Lifecycle and broadcast | API / Backend | External host/PubSub | They consume committed facts and must not participate in durable convergence. [VERIFIED: `projector.ex`, locked D-11..D-13] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---|---|---|
| Elixir/Ecto | `~> 3.13` [VERIFIED: `mix.exs`] | Named transaction operations, changesets, prefix-aware Repo calls | Existing repository transaction facade and all target persistence use Ecto. [VERIFIED: codebase grep] |
| PostgreSQL | `14+` [VERIFIED: `guides/compatibility-and-deprecations.md`] | Partial/functional unique indexes and conflict arbitration | The existing event and suppression identities are enforced here. [VERIFIED: migrations and `events.ex`] |
| Phoenix/Plug | `~> 1.8` [VERIFIED: `guides/compatibility-and-deprecations.md`] | Existing public POST route and exact HTTP response | Preserve route/controller compatibility rather than introducing a new endpoint. [VERIFIED: `router.ex`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| Phoenix.PubSub | existing optional runtime [VERIFIED: `projector.ex`] | Best-effort committed-event fan-out | Invoke only after the database success result. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Unique-index conflict convergence | Application locks | Locks add coordination and do not replace existing database identity; use the uniqueness contracts already present. [VERIFIED: existing event/suppression indexes] |
| `ON CONFLICT DO NOTHING` + refetch | `ON CONFLICT DO UPDATE` | PostgreSQL guarantees UPSERT atomicity, but an update risks mutating an immutable unsubscribe row and firing update semantics. The locked requirement permits conflict-safe insert/refetch, which preserves the original fact. [CITED: https://www.postgresql.org/docs/current/sql-insert.html] |

**Installation:** No new external packages. [VERIFIED: phase scope]

## Package Legitimacy Audit

No external package installation is in scope. [VERIFIED: phase scope]

## Architecture Patterns

### System Architecture Diagram

```text
HTTPS POST /unsubscribe/:token
        |
        v
verify token -> narrow unscoped Delivery lookup
        | invalid/expired/missing --------> empty 200 (privacy no-op)
        v
derive tenant + normalized address + stream from Delivery
        |
        v
Tenancy.with_tenant -> one prefix-explicit Ecto.Multi
        |             |-- event insert/reuse -> canonical event
        |             |-- suppression insert/reuse -> canonical suppression
        |             '-- failure -> rollback both -> stable non-success
        v
commit success
        |-- newly converged? -> lifecycle compatibility adapter (best effort)
        '-- newly converged? -> Projector broadcast (best effort)
        v
empty 200

Next send -> Outbound preflight -> SuppressionStore.Ecto.check -> address_stream block only
```

### Recommended Project Structure

```text
lib/mailglass/compliance/
├── unsubscribe_controller.ex   # HTTP classification only
├── unsubscribe.ex              # token/URL service; unchanged authority model
└── unsubscribe_convergence.ex  # internal transaction + canonical result/effect gate

test/mailglass/compliance/
└── unsubscribe_controller_test.exs  # controller, rollback, effect, prefix/concurrency integration
```

### Pattern 1: Flat conflict-safe convergence Multi

**What:** Append the event and insert the suppression in one `Ecto.Multi`; after each `DO NOTHING` sentinel, issue a prefix-explicit `Multi.run` canonical refetch. A failed `run` returns `{:error, reason}` and causes the enclosing Multi to roll back. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html]

**When to use:** Every valid built-in one-click POST after trusted Delivery resolution. Never use it for invalid/expired/missing targets.

```elixir
# Source: existing Repo.multi_opts/1 / Events.append_multi/3 patterns, adapted for Phase 152
multi =
  Ecto.Multi.new()
  |> Events.append_multi(:unsubscribe_event, event_attrs)
  |> Ecto.Multi.run(:event, fn repo, %{unsubscribe_event: event} ->
    {:ok, canonical_event(repo, event, delivery)} # query uses Repo.multi_opts()
  end)
  |> Ecto.Multi.insert(:suppression, Entry.changeset(suppression_attrs),
    Repo.multi_opts(on_conflict: :nothing, conflict_target: @suppression_target, returning: true)
  )
  |> Ecto.Multi.run(:suppression_record, fn repo, %{suppression: row} ->
    {:ok, canonical_suppression(repo, row, suppression_attrs)} # prefix explicit
  end)
```

The suppressions table's existing `record/2` is unsuitable as the direct transaction step because it uses replace-on-conflict mutable admin semantics and does not attach a prefix in `insert_opts/0`; do not call it inside this Multi until its API is made prefix-safe and immutable for this use. [VERIFIED: `suppression_store/ecto.ex`]

### Pattern 2: Newly-completed-pair post-commit effects

**What:** Derive `completed?` from insert sentinels, not canonical rows: it is true when this request inserts at least one of the previously missing event or suppression facts, including repair of a legacy event-only state. Return `{:completed, event, suppression}` for that request and `{:already_converged, event, suppression}` only when both facts pre-existed. The controller runs effects only for `:completed` after commit.

**When to use:** Every successful convergence response.

```elixir
case Convergence.run(delivery) do
  {:ok, :completed, event, suppression} ->
    Effects.after_commit(delivery, event, suppression) # rescue/log internally
    send_resp(conn, 200, "")

  {:ok, :already_converged, _event, _suppression} ->
    send_resp(conn, 200, "")

  {:error, _reason} ->
    send_resp(conn, 500, "")
end
```

**Compatibility adapter:** Preserve the callback signature by invoking `configured_lifecycle().handle_event(Ecto.Multi.new(), attrs)` only after the primary convergence has committed, then execute the returned Multi as a separate, best-effort transaction. Its result is logged/ignored for the already-successful POST. This preserves the callback's composition shape while ensuring it cannot roll back or partially alter the canonical event/suppression pair. It does change legacy callback work from same-transaction to post-commit ordering, which is required by D-11 and must be proven with a regression. [VERIFIED: `lifecycle.ex`; locked D-11/D-12/D-18]

### Anti-Patterns to Avoid

- **Call lifecycle in the Multi:** any external/host work is then ordered before commit and can make the request fail after partial outside effects. [VERIFIED: `unsubscribe_controller.ex`; locked D-11]
- **Use request fields/token claims for recipient or stream:** violates the delivery-only token authority and permits scope substitution. [VERIFIED: locked D-01/D-08]
- **Treat unique conflicts as HTTP 500:** conflicts are the normal replay/concurrency convergence path. [CITED: https://www.postgresql.org/docs/current/sql-insert.html]
- **Trust ambient `search_path`:** callback-repo calls do not inherit the facade's prefix injection. [VERIFIED: `repo.ex`; CITED: https://ecto.hexdocs.pm/multi-tenancy-with-query-prefixes.html]
- **Assert only row existence:** UNSUB-09 requires the actual send/preflight gate to block the next matching message. [VERIFIED: `outbound.ex`, locked D-10]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Replay/concurrent identity | In-memory mutex or process-local dedupe | Existing PostgreSQL unique indexes plus conflict handling | Works across requests/processes and is already the domain identity authority. [CITED: https://www.postgresql.org/docs/current/sql-insert.html] |
| Atomic durable pair | Two sequential `Repo.insert` calls | One Ecto.Multi executed by `Repo.multi/1` | Multi reports a named failure and rolls prior operations back. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| Address normalization | A controller-local lowercase function | `Suppression.Entry.changeset/1`/stored Delivery recipient model | Keeps write and preflight lookup semantics aligned. [VERIFIED: `entry.ex`, `suppression_store/ecto.ex`] |
| Notifications | Custom PubSub handling | `Projector.broadcast_delivery_updated/3` | Existing best-effort/PubSub topic semantics already match the post-commit need. [VERIFIED: `projector.ex`] |

**Key insight:** Postgres identity decides convergence; Ecto provides transaction composition; the controller only classifies trust and response semantics. [CITED: https://www.postgresql.org/docs/current/sql-insert.html]

## Common Pitfalls

### Pitfall 1: `DO NOTHING` is not a canonical row

**What goes wrong:** An event or suppression insert conflict can return a struct without database-populated fields, or no returned row, while the canonical record exists. The implementation incorrectly marks failure or duplicates effects.

**How to avoid:** Use `inserted_at` only for the existing event sentinel and use a dedicated suppression created sentinel; then refetch by the exact identity with `Repo.multi_opts()` inside the Multi. PostgreSQL's `RETURNING` returns successfully inserted/updated rows, so `DO NOTHING` needs the refetch. [VERIFIED: `events.ex`; CITED: https://www.postgresql.org/docs/current/sql-insert.html]

### Pitfall 2: Half-converged legacy state

**What goes wrong:** A prior version may have written the event but no suppression. A naïve `event created?` flag makes every later request a replay and never inserts the missing suppression.

**How to avoid:** Treat the result as `created` when this transaction creates the missing convergence fact(s), while run at most one post-commit effect for the successful completing request. Add a targeted fixture with pre-existing unsubscribe event/no suppression and specify whether it is repaired without duplicate effects. This edge is implied by the present controller gap. [VERIFIED: current controller only writes event]

### Pitfall 3: Prefix loss in `Multi.run`

**What goes wrong:** `repo.one(query)` in a callback follows connection prefix/search path unless given options; a hostile default/decoy schema can satisfy or receive the wrong data.

**How to avoid:** `repo.one(query, Repo.multi_opts())`, `repo.insert(..., Repo.multi_opts(...))`, and `Ecto.Multi.*(..., Repo.multi_opts(...))` for each target-table operation. Ecto documents explicit prefix precedence above connection prefix for schema operations. [VERIFIED: `repo.ex`; CITED: https://ecto.hexdocs.pm/multi-tenancy-with-query-prefixes.html]

### Pitfall 4: False RFC claim

**What goes wrong:** Tests or docs assert that RFC 8058 itself requires empty 200.

**How to avoid:** Test non-redirect HTTPS POST compliance separately; label empty 200 as the established Mailglass privacy/route contract. [CITED: https://www.rfc-editor.org/rfc/rfc8058]

### Pitfall 5: Serial tests mistaken for concurrency proof

**What goes wrong:** Repeated calls in one test process do not exercise waiting/unique arbitration between separate DB connections.

**How to avoid:** Use real concurrent tasks/connections with sandbox ownership explicitly permitted, coordinate a barrier, collect both responses, and assert one event/suppression plus exactly one effect. Include an injected uniqueness-race case if a deterministic barrier can reach it. [VERIFIED: existing property test is serial; locked D-19]

## Code Examples

### Prefix-explicit canonical refetch

```elixir
# Source: Ecto prefix precedence + repository `Repo.multi_opts/1` pattern
defp canonical_suppression(repo, %Entry{inserted_at: %DateTime{}} = entry, _attrs), do: entry

defp canonical_suppression(repo, _conflicted, attrs) do
  query =
    from entry in Entry,
      where: entry.tenant_id == ^attrs.tenant_id,
      where: entry.address == ^attrs.address,
      where: entry.scope == :address_stream,
      where: entry.stream == ^attrs.stream,
      limit: 1

  case repo.one(query, Repo.multi_opts()) do
    %Entry{} = entry -> {:ok, entry}
    nil -> {:error, :suppression_conflict_refetch_failed}
  end
end
```

The exact conflict sentinel for a UUIDv7 suppression must be verified in a focused test; do not assume `id == nil`, because the event writer documents UUIDs are client-generated. [VERIFIED: `events.ex`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| One-click event-only transaction + in-Multi lifecycle | Pair convergence transaction + post-commit effects | Phase 152 | Meets durable suppression and ordering requirements without changing the public route. [VERIFIED: current code and locked decisions] |
| Ambient schema/test `search_path` convenience | Explicit operation `prefix:` | v2.0/v2.1 repository policy | Target operations resist decoy/default schema selection. [VERIFIED: `repo.ex`, `.planning/MILESTONES.md`] |

**Deprecated/outdated:** Treating `Mailglass.Lifecycle.handle_event/2` as the one-click post side-effect mechanism is incompatible with locked D-11; retain it only where its transaction-composition contract remains applicable. [VERIFIED: `lifecycle.ex`; locked D-11/D-18]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | A legacy lifecycle implementation can be adapted to post-commit behavior without a public breaking change. | Architecture Patterns | Existing adopters may need a documented migration/adapter. |
| A2 | `inserted_at` is a suitable suppression insert sentinel under its current schema/adapter. | Code Examples | Created-only effect gating could be wrong; prove before implementation. |

## Open Questions (RESOLVED)

1. **Does executing the legacy lifecycle-returned Multi separately preserve every supported adopter use? — Resolved for Phase 152**
   - What we know: its sole callback accepts/returns `Ecto.Multi`; `Repo.multi/1` can execute a new Multi after primary commit. [VERIFIED: `lifecycle.ex`, `repo.ex`]
   - Resolution: use the separate best-effort transaction as the minimal signature/config compatibility adapter. Phase 152's locked D-11/D-12 ordering supersedes the former co-commit semantics; update every public config/doc claim and add a regression demonstrating that lifecycle failure leaves canonical facts committed and returns empty 200.

2. **Which suppression insert result reliably marks conflict for this Ecto/Postgrex combination? — Resolved contract**
   - What we know: event uses DB-default `inserted_at` due client-generated UUIDs. [VERIFIED: `events.ex`]
   - Resolution: use the suppression row's DB-defaulted, `read_after_writes` `inserted_at` as the provisional insert/conflict sentinel, matching the event convention. Plan 01 must first pin the actual adapter result under `on_conflict: :nothing, returning: true`; if the focused test disproves that representation, implement a deterministic insert-result helper while preserving the locked semantic: `completed?` is true when this transaction inserts either missing fact, and false only when both canonical facts pre-existed.

3. **What response status should an actual convergence failure use? — Resolved as HTTP 500**
   - What we know: current controller uses 500 and D-07 leaves status to discretion.
   - Resolution: retain byte-empty HTTP 500 for every genuine convergence/transaction failure in this phase. Do not introduce a new public error taxonomy without a separately reviewed contract.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir/OTP | Compile and ExUnit | ✓ | OTP 28 [VERIFIED: local probe] | — |
| PostgreSQL CLI | Schema/hostile-path diagnosis | ✓ | 14.17 [VERIFIED: local probe] | Ecto test repo for suite execution |
| Node | Not required by implementation | ✓ | v22.14.0 [VERIFIED: local probe] | — |

**Missing dependencies with no fallback:** None observed. [VERIFIED: local probe]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit / Mix [VERIFIED: `mix.exs`, test files] |
| Config file | `test/test_helper.exs`, `config/test.exs` [VERIFIED: repository files] |
| Quick run command | `mix test test/mailglass/compliance/unsubscribe_controller_test.exs test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs test/mailglass/suppression_test.exs test/mailglass/suppression_store/ecto_test.exs --warnings-as-errors` |
| Full suite command | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| UNSUB-07 | Event/suppression atomic first convergence and half-state repair | integration + DB | focused quick command | ✅ extend controller test |
| UNSUB-08 | Serial and genuine concurrent replay; one effect | integration + concurrent DB | focused quick command | ✅ extend property/controller tests |
| UNSUB-09 | Matching stream send blocks; transactional/unrelated stream send proceeds | end-to-end preflight/send | focused quick command | ✅ `suppression_test.exs`, add controller-to-send path |
| UNSUB-10 | Effects happen after commit and failures are non-fatal | integration | focused quick command | ✅ extend controller test |
| UNSUB-11 | Decoy/absent default schema, rollback injection, no effects | hostile-path integration | `mix verify.schema_prefix` plus focused test | ✅ helpers/alias exist; phase test is new |

### Sampling Rate

- **Per task commit:** focused quick command above.
- **Per wave merge:** `mix verify.schema_prefix` and the focused quick command.
- **Phase gate:** `mix test --warnings-as-errors` green before verification.

### Wave 0 Gaps

- [ ] Add a phase-focused helper/test that establishes the suppression conflict-return sentinel under `on_conflict: :nothing`.
- [ ] Add a two-connection barrier helper using sanctioned sandbox ownership for true concurrent POSTs.
- [ ] Add hostile `search_path` fixture with decoy `mailglass_events` and `mailglass_suppressions`, then assert configured-prefix-only rows.
- [ ] Add injectable lifecycle/broadcast failure probes with zero rollback and no duplicate replay effect.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | Token is capability-like delivery authority, not interactive authentication. [VERIFIED: locked D-01] |
| V3 Session Management | yes | No cookies, authorization, or web-session context participates in one-click scope. [CITED: https://www.rfc-editor.org/rfc/rfc8058] |
| V4 Access Control | yes | Derive tenant/address/stream exclusively from persisted Delivery after token verification. [VERIFIED: locked D-01/D-02/D-08] |
| V5 Input Validation | yes | Verify signed opaque token; do not consume POST parameters as scope authority. [CITED: https://www.rfc-editor.org/rfc/rfc8058] |
| V6 Cryptography | yes | Continue existing Phoenix.Token verification/secret-rotation mechanism; do not hand-roll token crypto. [VERIFIED: `unsubscribe.ex`] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Token tampering or guessed scope | Tampering / Elevation | Verify signed token; derive all scope from Delivery; privacy no-op invalid targets. [VERIFIED: locked D-01..D-03] |
| Race creates duplicate fact/effect | Tampering / Repudiation | DB unique constraints, one transaction, newly-completed-pair effect gate, concurrent test. [CITED: https://www.postgresql.org/docs/current/sql-insert.html] |
| Wrong-schema decoy write/read | Tampering / Information Disclosure | Explicit `prefix:` for every operation/refetch; hostile-path test. [CITED: https://ecto.hexdocs.pm/multi-tenancy-with-query-prefixes.html] |
| Callback failure causes false failure/rollback | Denial of Service | Commit first; rescue/log best-effort effects; preserve empty 200 after success. [VERIFIED: `projector.ex`, locked D-12] |

## Sources

### Primary (HIGH confidence)

- [RFC 8058](https://www.rfc-editor.org/rfc/rfc8058) - POST, no-redirect, opaque-token, and no-cookie requirements.
- [Ecto query-prefix documentation](https://ecto.hexdocs.pm/multi-tenancy-with-query-prefixes.html) - operation/query prefix precedence.
- [Ecto.Multi documentation](https://ecto.hexdocs.pm/Ecto.Multi.html) - ordered named transaction operations and failure semantics.
- [PostgreSQL INSERT documentation](https://www.postgresql.org/docs/current/sql-insert.html) - `ON CONFLICT`, `RETURNING`, and atomic UPSERT semantics.

### Secondary (MEDIUM confidence)

- Current source and tests: `unsubscribe_controller.ex`, `events.ex`, `suppression_store/ecto.ex`, `entry.ex`, `outbound.ex`, and Phase 11/12/149/151 artifacts. [VERIFIED: codebase inspection]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing project dependencies and paths inspected.
- Architecture: HIGH - locked decisions map directly onto existing code seams.
- Pitfalls: HIGH - current controller/replay/prefix gaps were inspected; external database mechanics are officially documented.

**Research date:** 2026-08-03
**Valid until:** 2026-09-02
