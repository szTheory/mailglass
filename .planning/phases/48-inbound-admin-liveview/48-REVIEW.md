---
phase: 48-inbound-admin-liveview
reviewed: 2026-05-24T00:00:00Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound/destructive_action.ex
  - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
  - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex
  - mailglass_admin/lib/mailglass_admin/inbound/timeline.ex
  - mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex
  - mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex
  - mailglass_admin/lib/mailglass_admin/router.ex
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_inbound/lib/mailglass_inbound/internal/operator/detail.ex
  - mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex
  - mailglass_inbound/lib/mailglass_inbound/internal/operator/timeline.ex
  - mailglass_inbound/lib/mailglass_inbound/router/matcher.ex
findings:
  critical: 0
  warning: 5
  info: 5
  total: 10
status: issues_found
---

# Phase 48: Code Review Report

**Reviewed:** 2026-05-24
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

Reviewed the Phase 48 inbound admin LiveView surface plus the three inbound
read-models, the routing-trace matcher reflection, the runtime optional-dep
gateway, and the supporting components. The security-sensitive spine of this
phase is sound:

- **Tenant isolation is correctly enforced.** All three read-models
  (`Records`, `Timeline`, `Detail`) apply BOTH an explicit `tenant_id`
  where-clause AND `Mailglass.Tenancy.scope/2` on every query, and a
  blank/missing tenant short-circuits to `[]`/`nil` (`:blank`). The LiveView
  adds defense-in-depth short-circuit heads (`load_inbound_records(%{"tenant_id"
  => ""})`, etc.).
- **The replay gate order is correct** (tenant gate → `:replay_inbound`
  capability gate → replay), the tenant gate rejects a blank active tenant, and
  replay preserves append-only semantics (a new `ExecutionRun` with
  `source: :replay`; no UPDATE).
- **The optional-dep gateway discipline holds** — the LiveView reaches inbound
  ONLY through `MailglassAdmin.OptionalDeps.MailglassInbound` via `apply/3`, the
  gateway module is conditionally compiled, and `gateway_available?/0` gates
  every call.
- **PubSub topic parity is exact** (`"mailglass:inbound:" <> tenant_id` in both
  packages) and the live-update payload is id-only/PII-free, re-fetched
  tenant-scoped before prepending.
- **Brand voice is clean** — no banned phrases; error copy is composed and
  specific. No debug artifacts, secrets, or dangerous calls.

The findings below are functional correctness defects in the read/display layer
(stale or wrong displayed fields, a non-functional filter) plus robustness gaps
around adopter-supplied auth return shapes. No tenant leak, PII leak, or replay
bypass was found.

## Warnings

### WR-01: Records list always renders "Pending" outcome badge and "no match" mailbox

**File:** `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex:47-57`
(consumed by `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex:88-94`)

**Issue:** `Records.list_records/2` `select/3` projects only
`id, tenant_id, provider, provider_message_id, message_id, envelope_recipient,
subject, received_at, inserted_at` — it does NOT include `outcome` or `mailbox`.
`RecordsList` reads these defensively with `Map.get(record, :outcome)` (→ always
`nil`) and `Map.get(record, :mailbox)` (→ always `nil`). The result: every row
in the list renders the neutral "Pending" badge and the "no match" mailbox
label regardless of the record's actual outcome. The outcome *filter* works
correctly (it uses a subquery), but a list filtered to `:accept` will still show
every row as "Pending" — directly contradicting the moduledoc's promise of a
meta line with "matched-mailbox-or-'no match'" and an outcome badge.

**Fix:** Join/subquery the latest fresh `ExecutionRun` outcome + mailbox into the
projection so the list reflects real disposition. For example, add a correlated
subquery selecting the latest fresh run's `outcome`/`mailbox` per record:

```elixir
|> select([record], %{
  id: record.id,
  # ...existing fields...,
  outcome:
    subquery(
      from r in ExecutionRun,
        where: r.inbound_record_id == parent_as(:rec).id and r.source == :fresh,
        order_by: [desc: r.inserted_at],
        limit: 1,
        select: r.outcome
    ),
  mailbox: # same shape for mailbox
})
```

(name the outer record binding with `from(record in InboundRecord, as: :rec)`).
Alternatively, drop the badge/mailbox from the list rows until the projection
carries them, rather than rendering a misleading constant.

### WR-02: Detail header "From" field shows the masked recipient, not the sender

**File:** `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex:63-66`

**Issue:** The "From" definition-list cell renders
`Components.mask_recipient(@record.envelope_recipient)` — i.e. the *recipient*,
not the sender. `InboundRecord` has a dedicated `from` field
(`{:array, :map}`), which is never read. The result is that the "From" row
duplicates the recipient already shown in the H2 title (line 38) and the actual
sender is never displayed. This is misleading to an operator triaging inbound
mail ("who sent this?").

**Fix:** Render the sender from `@record.from` (masking each address), e.g.:

```elixir
defp sender_display(%{from: [%{} = addr | _]}), do: Components.mask_recipient(addr["address"] || addr[:address])
defp sender_display(_record), do: "Unavailable"
```

and use `{sender_display(@record)}` in the "From" cell. If displaying the sender
is genuinely out of Phase 48 scope, relabel the cell "Recipient" so it is not a
falsehood.

### WR-03: "Search" filter is dead UI — input is collected but never applied

**File:** `mailglass_admin/lib/mailglass_admin/inbound_live.ex:457-472`,
`mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex:78-89`

**Issue:** `default_filter_params/0` and `normalize_filter_params/1` carry a
`"search"` key, `FiltersForm.fields/1` renders a "Search" text input with
placeholder "subject or recipient", and `build_path/3` round-trips it through the
URL. But `load_inbound_records/1` never passes `search` to the gateway, and
`Records.list_records/2` has no search clause. The search box does nothing — the
operator types a query, submits, the URL changes, and the result set is
unaffected. This is broken UX and a maintenance trap (a future reader will
assume search is wired).

**Fix:** Either implement the search filter in the read-model (an `ILIKE` on
`subject`/`envelope_recipient`, cast safely) and thread it through
`load_inbound_records/1`, or remove the `search` field from
`default_filter_params/0`, `normalize_filter_params/1`, and the `FiltersForm`
markup until it is implemented. Do not ship a control that silently no-ops.

### WR-04: `DestructiveAction.authorize/3` crashes on a nil adapter instead of denying

**File:** `mailglass_admin/lib/mailglass_admin/inbound/destructive_action.ex:22-36`
(call site `mailglass_admin/lib/mailglass_admin/inbound_live.ex:163-168`)

**Issue:** The first `authorize/3` head guards `when is_atom(adapter)`. In
Elixir `nil` is an atom, so a `nil` adapter matches this head and calls
`Auth.authorize(nil, :replay_inbound, ...)`, which runs
`Code.ensure_loaded?(nil)` → `false` and then `raise ArgumentError, "operator
auth module nil must implement authorize/2"`. This raise is NOT inside the
`with/else` mapping in `confirm_replay`, so it crashes the LiveView process
instead of producing a brand-voice denial. The intended fallback head
(`authorize(%Socket{}, _adapter, _inbound_record)` → `{:error, {:auth, ...}}`)
is unreachable for `nil`.

In production this path is shielded because `Operator.Mount` always sets
`operator_auth.adapter` before `InboundLive` mounts (the route mounts inside the
operator `live_session`), so adapter is non-nil in practice. But the helper is a
public `authorize/3` whose contract claims `module() | nil` for the adapter
(`@spec ... module() | nil ...`), and the sibling `authorize_reveal/1` in the
LiveView correctly guards `is_atom(adapter) and not is_nil(adapter)`. The
inconsistency is a latent crash that any test harness or future caller passing
`nil` will trip.

**Fix:** Tighten the success head to exclude `nil`, matching `authorize_reveal/1`:

```elixir
def authorize(%Socket{} = socket, adapter, inbound_record)
    when is_atom(adapter) and not is_nil(adapter) do
  # ...
end

def authorize(%Socket{}, _adapter, _inbound_record),
  do: {:error, {:auth, @default_denial}}
```

so a `nil` adapter falls through to the composed denial tuple instead of raising.

### WR-05: Reveal/replay authorization can crash on a non-standard adopter error tuple

**File:** `mailglass_admin/lib/mailglass_admin/inbound_live.ex:521-534`
(via `mailglass_admin/lib/mailglass_admin/auth.ex:85-92`)

**Issue:** `authorize_reveal/1` maps `{:error, _reason, _details} -> :denied`,
intending to treat any denial as `:denied`. But `MailglassAdmin.Auth.authorize/3`
normalizes results through `normalize_result/1`, whose error clause only accepts
`reason in [:unauthorized, :stale_auth]`. Any other error shape — e.g. an
adopter returning `{:error, :forbidden, %{}}` or `{:error, :rate_limited, %{}}`
for the `:reveal_raw`/`:replay_inbound` actions — falls to
`normalize_result(other)` which `raise`s `ArgumentError` *before returning*. The
catch-all clause in `authorize_reveal/1` (and the `{:error, {:auth, _}}` arm in
`DestructiveAction`) never sees it, so the LiveView crashes. The reveal/replay
actions are new action atoms an adopter may not have anticipated when writing
their `authorize/2`, making a non-`:unauthorized` denial reason plausible.

**Fix:** Document in `MailglassAdmin.Auth` that custom actions MUST deny with
`{:error, :unauthorized | :stale_auth, map()}`, OR broaden `normalize_result/1`
to pass through arbitrary `{:error, reason, details}` for non-standard actions
(treating unknown reasons as denials), so an adopter's reasonable error shape
degrades to a denial rather than a 500. At minimum, wrap the `Auth.authorize`
calls for `:reveal_raw`/`:replay_inbound` in a `try/rescue ArgumentError ->
:denied` so a misbehaving adopter cannot crash the operator surface.

## Info

### IN-01: `EvidenceCard` declares an unused `can_reveal?` attr

**File:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:27`

**Issue:** `attr :can_reveal?, :boolean, default: true` is declared but never
referenced in the template — the "Reveal raw source" button visibility is driven
solely by `@evidence && @reveal_state != :revealed`. `InboundLive` never passes
`can_reveal?` (only `evidence` and `reveal_state`). Dead attribute. (Functionally
the reveal button always shows; clicking without the capability shows the denied
message, which is acceptable UX, but the attr implies a gating that does not
exist.)

**Fix:** Either wire `can_reveal?` to suppress the button when the operator
lacks `:reveal_raw` (compute capability in `InboundLive` and pass it through), or
remove the unused attr.

### IN-02: `raw_headers` is not `redact: true` on the evidence schema the card relies on

**File:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:9,126`
(schema: `MailglassInbound.InboundRecords.InboundEvidence`, `raw_headers` field)

**Issue:** The EvidenceCard's redaction contract rests on `raw_payload` and
`raw_mime` being `redact: true`. `raw_headers` (which can carry `To`/`From`/
`Subject` header values — PII) is NOT marked `redact: true`. The card itself only
exposes `map_size(raw_headers)` (a count), so no leak occurs here. But any other
code path that `inspect`s an `%InboundEvidence{}` (a crash report, a log line, a
`dbg`) will dump full header content, undermining the "evidence is
redacted-by-default" guarantee this phase advertises.

**Fix:** Add `redact: true` to the `raw_headers` field on `InboundEvidence` (the
schema file is outside this review's file set but is the linchpin of the
evidence-redaction promise). The header count display continues to work; only
`inspect` output is protected.

### IN-03: Subject rendered unmasked in detail header and routing trace

**File:** `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex:69`,
`mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex:153,192`

**Issue:** The selected-record subject is rendered verbatim (`present(@record.
subject)`), and the routing-trace "Actual" subject + the composed
`subject_reason` copy also render the raw subject. Subjects can contain PII
(names, order numbers, OTP-adjacent text). This is operator-facing UI behind the
Auth gate (not telemetry), so it is consistent with the masked-recipient-but-
visible-subject pattern and likely intentional for triage. Flagging for explicit
confirmation that subject is in-scope for operator visibility under the phase's
PII policy.

**Fix:** If subjects are meant to be operator-visible, document the decision (PII
policy: recipient masked, subject visible-to-authorized-operator). If not,
truncate/mask the subject as is done for recipients.

### IN-04: Live-update prepend can grow the list past its limit and re-runs the full query

**File:** `mailglass_admin/lib/mailglass_admin/inbound_live.ex:424-451`

**Issue:** `prepend_live_record/2` prepends a new tenant-scoped record without
trimming the list back to the read-model's limit (`@default_limit 50` /
`@max_limit 100`), so a stream of inbound mail grows the in-memory list
unbounded across a long-lived LiveView session. It also calls
`load_inbound_records/1` (the full filtered list query) just to locate one
record by id. Correctness is fine (filters/tenant are honored, dedup by id is
present); this is a robustness/efficiency note. (Performance proper is out of v1
scope; flagged because unbounded growth in a persistent process is a latent
resource concern, not just speed.)

**Fix:** After prepending, cap the list to the configured limit
(`Enum.take(records, @max_limit)` with a shared constant), and consider a
single-record tenant-scoped fetch helper in the gateway rather than reloading
the full list.

### IN-05: `routing_trace` recomputed on every selection even for non-`:no_match` records

**File:** `mailglass_admin/lib/mailglass_admin/inbound_live.ex:347,359-369`

**Issue:** `assign_inbound_state/3` always calls `routing_trace_for/2`. For any
outcome other than `:no_match` it returns `[]` cheaply, and for `:no_match` it
reflects routes via the gateway — correct behavior. Minor: the routing trace is
only rendered when `@detail[:outcome] == :no_match` (render line 318), so the
guard is duplicated (compute-side guard + render-side `:if`). Harmless, but the
two guards must stay in sync; a future edit to one without the other could render
a stale or empty trace. Consider deriving the render `:if` from
`@routing_trace != []` so there is one source of truth.

**Fix:** Render `RoutingTrace` with `:if={@routing_trace != []}` instead of
re-deriving `@detail[:outcome] == :no_match`, collapsing the two guards into one.

---

_Reviewed: 2026-05-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
