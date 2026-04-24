---
phase: 04-webhook-ingest
reviewed: 2026-04-23T00:00:00Z
depth: standard
files_reviewed: 39
files_reviewed_list:
  - lib/mailglass/webhook/caching_body_reader.ex
  - lib/mailglass/webhook/ingest.ex
  - lib/mailglass/webhook/plug.ex
  - lib/mailglass/webhook/provider.ex
  - lib/mailglass/webhook/providers/postmark.ex
  - lib/mailglass/webhook/providers/sendgrid.ex
  - lib/mailglass/webhook/pruner.ex
  - lib/mailglass/webhook/reconciler.ex
  - lib/mailglass/webhook/router.ex
  - lib/mailglass/webhook/telemetry.ex
  - lib/mailglass/webhook/webhook_event.ex
  - lib/mailglass/tenancy.ex
  - lib/mailglass/tenancy/resolve_from_path.ex
  - lib/mailglass/tenancy/single_tenant.ex
  - lib/mailglass/errors/config_error.ex
  - lib/mailglass/errors/signature_error.ex
  - lib/mailglass/errors/tenancy_error.ex
  - lib/mailglass/events.ex
  - lib/mailglass/events/event.ex
  - lib/mailglass/events/reconciler.ex
  - lib/mailglass/idempotency_key.ex
  - lib/mailglass/config.ex
  - lib/mailglass/application.ex
  - lib/mailglass/repo.ex
  - lib/mailglass/migrations/postgres.ex
  - lib/mailglass/migrations/postgres/v02.ex
  - lib/mix/tasks/mailglass.reconcile.ex
  - lib/mix/tasks/mailglass.webhooks.prune.ex
  - docs/api_stability.md
  - guides/webhooks.md
  - test/mailglass/webhook/ingest_test.exs
  - test/mailglass/webhook/plug_test.exs
  - test/mailglass/webhook/reconciler_test.exs
  - test/mailglass/webhook/pruner_test.exs
  - test/mailglass/webhook/telemetry_test.exs
  - test/mailglass/webhook/router_test.exs
  - test/mailglass/webhook/caching_body_reader_test.exs
  - test/mailglass/webhook/providers/postmark_test.exs
  - test/mailglass/webhook/providers/sendgrid_test.exs
  - test/mailglass/webhook/core_webhook_integration_test.exs
  - test/mailglass/properties/webhook_idempotency_convergence_test.exs
  - test/mailglass/properties/webhook_signature_failure_test.exs
  - test/mailglass/properties/webhook_tenant_resolution_test.exs
  - test/mailglass/tenancy/resolve_from_path_test.exs
  - test/support/webhook_case.ex
  - test/support/webhook_fixtures.ex
findings:
  critical: 0
  warning: 6
  info: 9
  total: 15
status: issues_found
---

# Phase 4: Code Review Report

**Reviewed:** 2026-04-23
**Depth:** standard
**Files Reviewed:** 39 (source + support + docs)
**Status:** issues_found

## Summary

Phase 4 ships a clean, well-documented webhook ingest pipeline. The
security-critical paths are in order: Postmark Basic Auth uses
`Plug.Crypto.secure_compare/2` for both user and pass (D-04); SendGrid
ECDSA pattern-matches strictly on `true` from `:public_key.verify/4` and
collapses every DER/ASN.1 failure mode into `:bad_signature` /
`:malformed_key` atoms per D-03; the append-only discipline on
`mailglass_events` is respected (Reconciler APPENDS a `:reconciled`
event per D-18, never UPDATEs the orphan); PII is absent from every
emitted telemetry payload and Logger message I traced; idempotency is
belt-and-suspenders (UNIQUE `(provider, provider_event_id)` on the
webhook_events table PLUS the partial UNIQUE index on
`mailglass_events.idempotency_key`).

Findings below are either modest concurrency/consistency sharp edges
that are worth tightening before v0.1 ships (WR-01..WR-06) or
style/maintainability notes that don't block the release (IN-01..IN-09).
No Critical issues found. The most important warning is WR-01, which
flags `resolve_delivery_id/2` in `Ingest` running OUTSIDE the
`SET LOCAL statement_timeout` transaction (a DoS mitigation gap against
a slow `mailglass_deliveries` scan).

## Warnings

### WR-01: `Ingest.resolve_delivery_id/2` queries outside the 2s statement_timeout transaction

**File:** `lib/mailglass/webhook/ingest.ex:232-260, 393-412`
**Issue:** The `SET LOCAL statement_timeout = '2s'` (line 145) applies
only to statements executed inside the surrounding `Repo.transact/1`
closure. However, `resolve_delivery_id/2` is invoked from inside the
`Multi.run` callback (`append_events_for_each`, line 240), and that
callback is composed into the Multi, which is then handed to
`Repo.multi(multi)` — which internally runs its own `repo().transaction(multi)`.

Whether the inner `Multi.run`'s `Repo.one` (the SELECT against
`mailglass_deliveries`) inherits the outer `SET LOCAL` depends on
whether Ecto opens a nested savepoint with a fresh session setting or
reuses the surrounding transaction. In practice it reuses the outer
connection, so this works today — but it is implementation-dependent
behavior worth an explicit guard.

The DoS mitigation per D-29 says the statement_timeout must bound
ingest latency. A slow `mailglass_deliveries.provider_message_id` index
scan inside `resolve_delivery_id/2` is exactly the case it exists to
catch.

**Fix:** Add an assertion or a test that proves the timeout propagates.
Either:
1. Extract `resolve_delivery_id/2` into an explicit `Multi.run` step
   (so it is demonstrably inside the same transaction the SET LOCAL
   established), OR
2. Add an integration test that stubs `mailglass_deliveries` with
   `pg_sleep` and asserts the ingest fails-fast at 2s. The existing
   `@tag :slow` test on line 209-226 proves the primitive works but
   does not prove end-to-end propagation.

```elixir
# Option 1 — explicit Multi.run makes the scope unambiguous:
defp append_events_for_each(multi, events, provider, tenant_id) do
  events
  |> Enum.with_index()
  |> Enum.reduce(multi, fn {event, idx}, acc ->
    acc
    |> Multi.run({:resolve_delivery, idx}, fn _repo, _changes ->
      {:ok, resolve_delivery_id(provider, event)}
    end)
    |> Events.append_multi(event_step_name(idx), fn changes ->
      delivery_id = Map.fetch!(changes, {:resolve_delivery, idx})
      # ... rest unchanged
    end)
  end)
end
```

---

### WR-02: `Events.Reconciler.find_orphans/1` uses `DateTime.utc_now/0` instead of `Mailglass.Clock.utc_now/0`

**File:** `lib/mailglass/events/reconciler.ex:68`
**Issue:** `cutoff = DateTime.add(DateTime.utc_now(), -max_age_minutes * 60, :second)`
uses the OS wall clock directly. The rest of Phase 4 (Pruner,
Webhook.Reconciler, Ingest, WebhookEvent) correctly routes through
`Mailglass.Clock.utc_now/0`. The api_stability.md §Clock contract
explicitly calls out `Mailglass.Clock.utc_now/0` as the single
legitimate source of wall-clock time (TEST-05), and Phase 6 LINT-12
(`NoDirectDateTimeNow`) will flag this.

Concrete consequence: a test that freezes the clock via
`Mailglass.Clock.Frozen.freeze/1` and then calls `find_orphans/1` gets
an unfrozen cutoff — orphans whose `inserted_at` is before "real now"
but after "frozen now" are silently excluded from reconciliation in
tests. This can mask bugs.

**Fix:**
```elixir
cutoff = DateTime.add(Mailglass.Clock.utc_now(), -max_age_minutes * 60, :second)
```

Note: this module is not new in Phase 4 (shipped Phase 2), but it is
in-scope for this review per the config (`lib/mailglass/events/*`) and
because Phase 4's Reconciler wraps it. The fix is one line.

---

### WR-03: `Webhook.Reconciler.attempt_reconcile/1` nests `Repo.transact(fn -> Repo.multi(multi) end)` with ambiguous unwrapping

**File:** `lib/mailglass/webhook/reconciler.ex:205-228`
**Issue:** The code wraps `Repo.multi(multi)` inside `Repo.transact/1`:

```elixir
case Repo.transact(fn -> Repo.multi(multi) end) do
  {:ok, {:ok, changes}} -> ...
  {:ok, {:error, _step, reason, _changes_so_far}} -> ...
  {:ok, changes} when is_map(changes) -> ...  # <-- suspicious
  {:error, reason} -> ...
end
```

Two concerns:

1. **Three-layer nesting is hard to reason about.** `Repo.transact/1`
   opens a transaction; `Repo.multi/1` opens a savepoint. On Multi
   failure the savepoint rolls back but the outer transact commits
   (because the closure returned `{:ok, {:error, ...}}` — a valid
   success shape from transact's perspective, just with an error-shaped
   payload). The comment at plan 04-06 says "flat Multi, no nested
   Repo.multi anti-pattern" (WR-04 ref), but Reconciler violates it.

2. **The `{:ok, changes} when is_map(changes)` branch on line 220 is
   dead code OR indicates confusion about the contract.** `Repo.multi/1`
   returns `{:ok, changes_map}` on success, `{:error, step, reason,
   changes_map}` on failure — it cannot return a bare `changes_map`.
   The only way to hit line 220 would be if the closure returned a map
   directly, which doesn't happen. The defensive clause suggests the
   author wasn't sure of the contract.

**Fix:** Simplify to a flat Multi call (no outer transact) since
`Repo.multi/1` already wraps in a transaction:

```elixir
case Repo.multi(multi) do
  {:ok, changes} ->
    maybe_broadcast(delivery, changes[:reconciled_event], orphan)
    {:ok, changes}

  {:error, _step, reason, _changes_so_far} ->
    {:error, reason}
end
```

If there's a reason to need the outer `Repo.transact/1` (e.g.
additional pre/post work in the closure), document it — otherwise
remove the nesting.

---

### WR-04: `extract_event_id/1` for Postmark can collide under low-cardinality timestamps

**File:** `lib/mailglass/webhook/providers/postmark.ex:255-270`
**Issue:** `extract_event_id/1` builds a synthetic provider_event_id
from `RecordType + (ID or MessageID) + first-available timestamp`.
For RecordTypes without a numeric `ID` (Delivery, Open, Click —
which use only `MessageID`), the id becomes
`"Delivery:<MessageID>:<DeliveredAt>"`. If Postmark ever emits two
distinct Delivery events for the same `MessageID` with the same
second-resolution `DeliveredAt` (e.g. a bounce and delivery both
derived from the same message), the UNIQUE
`(provider, provider_event_id)` constraint collapses them to one —
the second event is silently dropped as a "duplicate."

This is a narrow real-world risk (timestamps with 1-second resolution
rarely collide for the same MessageID), but the contract silently
loses data when it does.

**Fix:** Include RecordType-specific additional discriminators when
available (e.g. `ServerID`, `Recipient`, or an index in a batched
webhook). Alternatively, drop the timestamp and require the provider
to ship a distinct ID — which Postmark does for Bounce/SpamComplaint
but not for Delivery/Open/Click, so the workaround is:

```elixir
# Include a hash of the JSON payload as a tiebreaker so two identical-
# looking Delivery events derived from different server-side rows don't
# collapse on the UNIQUE index:
defp extract_event_id(payload) do
  record_type = payload["RecordType"] || "Unknown"
  id_part = # ... existing cond ...
  ts_part = # ... existing fallbacks ...

  # Cheap structural tiebreaker — 16 hex chars of sha256(JSON) ensures
  # distinct Postmark-side rows stay distinct at the UNIQUE index.
  hash_part =
    payload
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> binary_part(0, 16)

  "#{record_type}:#{id_part}:#{ts_part}:#{hash_part}"
end
```

If the narrow-collision risk is acceptable at v0.1, document it in
`docs/api_stability.md` and move on. Either way, the choice should
be intentional.

---

### WR-05: `resolve_tenant!/4` passes the full `conn` (including `raw_body`) to adopter callbacks — PII exfiltration surface

**File:** `lib/mailglass/webhook/plug.ex:250-269`
**Issue:** The context map passed to
`Tenancy.resolve_webhook_tenant(ctx)` contains both the full `Plug.Conn`
AND `raw_body`. If an adopter's `resolve_webhook_tenant/1`
implementation raises or Logs the context on the unhappy path, raw PII
bytes (the webhook body contains recipient email addresses, bounce
messages with display names, etc.) end up in adopter logs — in
violation of D-23's whitelist spirit.

Mailglass's own error handling does the right thing (the Plug's
`TenancyError` rescue at line 155 logs only provider + atom), but the
callback contract invites adopter mistakes. The footgun is subtle
because most adopters will just pattern-match `path_params` or
`headers` and never touch `raw_body`.

**Fix (docs-only at v0.1):** Add explicit guidance to
`guides/webhooks.md` §Multi-tenant patterns and to the
`@callback resolve_webhook_tenant` docstring warning adopters NOT to
pass `raw_body` or the full conn into Logger calls / error messages /
telemetry. A `## PII discipline` subheading with a concrete
anti-pattern would land the lesson.

**Fix (stronger, v0.5):** Reconsider whether `raw_body` needs to be
in the context at v0.5 when `verified_payload` is populated. If the
documented v0.5 use case is Stripe-Connect-style payload-field
strategies, `verified_payload` (the decoded JSON) is sufficient and
`raw_body` can be dropped — reducing the PII-exfiltration surface.

---

### WR-06: `Webhook.Ingest.build_multi/4` — `String.to_atom` on per-index step names is bounded but unusual

**File:** `lib/mailglass/webhook/ingest.ex:329-331`
**Issue:** `event_step_name/1` creates atoms like `:"event_0"`,
`:"event_1"`, ... `:"event_127"` via string interpolation. The comment
correctly notes this is bounded (≤128 atoms across the library's
lifetime, which is a rounding error). But the pattern reads as if it
could be attacker-influenced at first glance — there's no validation
that `idx` is under 128.

`idx` comes from `Enum.with_index(events)` where `events` is the
output of `Provider.normalize/2` — itself bounded by fixture size.
A malicious SendGrid payload with 10_000 events (if the provider
shipped one) would create 10_000 distinct atoms. Plug parsers cap
body size at 10 MB (documented), which bounds this at ~40k events per
request, but atoms are in BEAM atom table and never GC'd.

**Fix:** Defense in depth — cap the event count at normalize time.
SendGrid documents a 128-event batch max; anything beyond is malformed.

```elixir
# In lib/mailglass/webhook/providers/sendgrid.ex, normalize/2:
def normalize(raw_body, _headers) when is_binary(raw_body) do
  case Jason.decode(raw_body) do
    {:ok, events} when is_list(events) and length(events) <= 128 ->
      # ... existing happy path
    {:ok, events} when is_list(events) ->
      Logger.warning(
        "[mailglass] SendGrid normalize: batch exceeds 128 events " <>
          "(got #{length(events)}) — refusing to process"
      )
      []
    # ... other clauses
  end
end
```

Alternative: use a pre-allocated atom pool. `:"event_#{idx}"` for
`idx in 0..127` is already bounded, so a small static map keeps the
atom creation compile-time-bounded:

```elixir
@event_step_names for i <- 0..127, into: %{}, do: {i, :"event_#{i}"}

defp event_step_name(idx) when idx in 0..127 do
  Map.fetch!(@event_step_names, idx)
end
```

## Info

### IN-01: `parse_raw_payload/1` returns a non-map wrapped in a map shape with `_raw` key on JSON decode failure

**File:** `lib/mailglass/webhook/ingest.ex:381-387`
**Issue:** When `Jason.decode/1` fails or returns a non-map/list, the
fallback stores the raw binary under key `"_raw"`:

```elixir
_ -> %{"_raw" => raw_body}
```

This is intentional (audit trail) but means the raw bytes land in
`mailglass_webhook_events.raw_payload` JSONB column verbatim, which is
already the design — but the `_raw` key name suggests internal-only
convention while being stored as queryable JSONB.

**Fix:** Either document the `_raw` key convention in the webhook_event
schema module + api_stability.md so adopters querying raw_payload know
what to expect, or rename to something more explicit like
`"_undecodable_raw_body"`.

---

### IN-02: `classify_rescue/1` for SendGrid uses message-string matching

**File:** `lib/mailglass/webhook/providers/sendgrid.ex:168-177`
**Issue:** The `classify_rescue(%ArgumentError{message: msg})` clause
pattern-matches on error messages via regex (`msg =~ ~r/non-alphabet/i`,
etc.). Per CLAUDE.md "Don't pattern-match errors by message string" —
this violates that rule even though it's internal to a single function.

The excuse is legitimate: `:public_key.der_decode/2` and friends raise
with opaque internal errors, and the only way to distinguish
"bad-base64 on the public key" from "bad-base64 on the signature" is
the message text. The practical impact is low because both collapse to
`:malformed_key` anyway. But adding OTP version pinning or a property
test that exercises OTP 27/28 side-by-side would prevent silent drift.

**Fix:** Add a note in the comment that this is a known rule exception,
tie it to an issue for follow-up at the next OTP bump, and ensure the
property test `WebhookSignatureFailureTest` covers the message-shape
drift risk.

---

### IN-03: `event_type_raw` field concatenates event types with `,` — fragile for adopter queries

**File:** `lib/mailglass/webhook/ingest.ex:363-372`
**Issue:** `derive_event_type_raw/1` joins per-event raw record types
with `,`:

```elixir
|> Enum.uniq()
|> Enum.join(",")
```

This produces strings like `"Delivery"`, `"Delivery,Bounce"`, or
`"processed,delivered,bounce,open,click"`. Adopters querying
`mailglass_webhook_events.event_type_raw` against enum values will
find it surprising that a single row can carry a multi-value string.

**Fix:** Either:
1. Store as an array column (`:text[]` at the DB level, `{:array, :string}`
   in Ecto) so adopters get structured queries like `'Delivery' = ANY(event_type_raw)`.
2. Store only the first event's type and document that SendGrid batches
   lose per-row granularity in this column (the per-event data lives
   in the `mailglass_events` table anyway).

Option 1 is the cleaner v0.5 migration; option 2 is a docs fix at v0.1.

---

### IN-04: `SignatureError` legacy atoms (`:missing`, `:malformed`, `:mismatch`) still in `__types__/0`

**File:** `lib/mailglass/errors/signature_error.ex:44-56`
**Issue:** The 3 Phase 1 legacy atoms are retained in the closed set
but marked as "aliases in all but name" in api_stability.md. Test
assertions at `test/mailglass/error_test.exs:62-80` pin the full
10-atom set including legacy. This bloats the contract's surface area.

**Fix:** At v0.1 this is intentional backward compatibility and should
stay. Add a `@deprecated` marker on the legacy atoms in docstrings
OR a `@doc since: "0.1.0-legacy"` for future removal. Document in
api_stability.md that Plan 05's "consolidates naming" promise means
the legacy set is removed at v1.0.

---

### IN-05: `past_grace?/1` returns `false` on nil inserted_at — silent filter

**File:** `lib/mailglass/webhook/reconciler.ex:165-174`
**Issue:** An orphan with `inserted_at == nil` is filtered out
silently. That shouldn't happen (the schema marks
`inserted_at` with `read_after_writes: true` and the DB sets a
`default: fragment("now()")`), but if it ever does — e.g. a malformed
raw-SQL insert like the one the reconciler_test.exs uses on line 234
— the orphan is invisibly dropped from reconciliation.

**Fix:** Add a `Logger.warning` in the `nil` branch so a surprising
data shape surfaces in logs:

```elixir
defp past_grace?(orphan) do
  case orphan.inserted_at do
    nil ->
      Logger.warning(
        "[mailglass] Reconciler skipping orphan=#{orphan.id} with nil inserted_at — " <>
          "schema invariant violated; check insert path"
      )
      false
    %DateTime{} = inserted_at -> ...
  end
end
```

---

### IN-06: `webhook_ingest_mode/0` uses `@doc false` + runtime raise for the `:async` gate

**File:** `lib/mailglass/config.ex:397-408`, `lib/mailglass/webhook/ingest.ex:132-139`
**Issue:** The `:async` mode is schema-validated (`{:in, [:sync, :async]}`)
at boot but runtime-raises in `ingest_multi/3` with a plain
`raise "..."` string. Per CLAUDE.md "Errors as a public API contract" +
"Don't pattern-match errors by message string," this should raise a
typed error.

**Fix:**
```elixir
:async ->
  raise Mailglass.ConfigError.new(:invalid,
    context: %{
      key: :webhook_ingest_mode,
      reason: "async mode is reserved for v0.5; v0.1 supports :sync only"
    }
  )
```

This keeps the error pattern-matchable by adopter telemetry / retry
middleware. Otherwise adopters surface a raw `RuntimeError` which
violates the structured-error contract.

---

### IN-07: Reconciler `@grace_seconds`, `@max_age_minutes`, `@batch_limit` are compile-time constants with no config hook

**File:** `lib/mailglass/webhook/reconciler.ex:79-81`
**Issue:** These knobs are reasonable defaults (60s grace, 7-day
orphan window, 1000-row batch). But they're hard-coded — adopters
with high-throughput systems may need smaller batches (memory) or
larger windows (eventual consistency across regions). No config
schema hook exposes them.

**Fix (v0.1 docs):** Document these as hard-coded defaults in
`guides/webhooks.md` §Orphan reconciliation, along with the message
that adjusting them requires forking or Oban cron job args
(`%{"limit" => 500}`).

**Fix (v0.5):** Expose via `config :mailglass, :webhook_reconciler,
grace_seconds: 60, max_age_minutes: 10080, batch_limit: 1000` with
NimbleOptions validation.

---

### IN-08: `insert_orphan_event/2` test helper uses raw `Ecto.UUID.dump` + positional SQL

**File:** `test/mailglass/webhook/reconciler_test.exs:234-264`
**Issue:** The test helper inserts orphans via raw SQL because the
45A01 trigger blocks UPDATE to backdate `inserted_at`. The SQL is
correct but uses hand-rolled `uuid_binary/1` and inline column lists
— brittle if V03 adds a non-null column later.

**Fix:** Either extract a shared `test/support/webhook_fixtures.ex`
helper (`insert_orphan_event_with_inserted_at!/2`) or accept the
brittleness with a `# v0.5 TODO` comment. v0.1 is fine as-is.

---

### IN-09: `Postmark.cidr_match?/2` is IPv4-only and silently returns false for IPv6 remote_ips

**File:** `lib/mailglass/webhook/providers/postmark.ex:145-153`
**Issue:** `ip_in_cidr?({a1, a2, a3, a4}, {b1, b2, b3, b4}, mask)` only
matches 4-tuples. An IPv6 remote_ip (`{a1, a2, ..., a8}`) falls through
to the fallthrough clause `defp ip_in_cidr?(_, _, _), do: false` and
the request is rejected with `:ip_disallowed`. Acceptable behavior
(fail-closed) but confusing if the allowlist is `["::1/128"]` and
Postmark ever IPv6s their webhooks.

Postmark's docs currently list only IPv4, so this is a narrow concern.

**Fix:** Document IPv4-only in `guides/webhooks.md` §IP allowlist
(already partially done — the code comment mentions "IPv4-only at v0.1").
At v0.5, add an IPv6 branch:

```elixir
defp ip_in_cidr?(remote_ip, base_ip, mask)
     when tuple_size(remote_ip) == 8 and tuple_size(base_ip) == 8 and
          mask >= 0 and mask <= 128 do
  # IPv6 CIDR match — bit operations on 128-bit values
  ...
end
```

---

_Reviewed: 2026-04-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
