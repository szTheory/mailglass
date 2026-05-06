# Phase 40: Postmark Ingress and Replayable Persistence - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 8 likely Phase 40 files
**Analogs found:** 8 / 8

This map stays focused on the likely internal implementation seams implied by `40-CONTEXT.md`: raw-body capture, verify-first ingress, Postmark-only normalization into `%MailglassInbound.InboundMessage{}`, one transaction for canonical plus evidence rows, and narrow route-compatibility proof with no mailbox execution.

## File Classification

| Likely Phase 40 File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` | middleware | request-response | `lib/mailglass/webhook/plug.ex` | exact-flow |
| `mailglass_inbound/lib/mailglass_inbound/ingress/caching_body_reader.ex` | utility | file-I/O | `lib/mailglass/webhook/caching_body_reader.ex` | exact |
| `mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex` | service | request-response | `lib/mailglass/webhook/providers/postmark.ex` | exact-provider |
| `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex` | service | transform | `lib/mailglass/webhook/provider.ex` | exact-shape |
| `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` | service | CRUD | `lib/mailglass/webhook/ingest.ex` | exact-transaction |
| `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex` | service | CRUD | `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex` | extend-existing |
| `mailglass_inbound/priv/repo/migrations/*_postmark_ingress_idempotency.exs` | migration | batch | `mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs` | exact-store |
| `mailglass_inbound/test/mailglass_inbound/ingress/*_test.exs` | test | request-response | `test/mailglass/webhook/plug_test.exs`, `test/mailglass/webhook/providers/postmark_test.exs`, `mailglass_inbound/test/mailglass_inbound/router_test.exs`, `mailglass_inbound/test/mailglass_inbound/persistence_test.exs` | composite |

## Pattern Assignments

### `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`

**Analog:** `lib/mailglass/webhook/plug.ex`

**Copy this orchestration pattern**

- verify first, then tenant resolution, then normalize, then persist
- keep the provider contract `conn`-free
- map failures to explicit HTTP statuses instead of raising through the request

**Anchor lines**

- module contract and lifecycle: `lib/mailglass/webhook/plug.ex:1`
- `call/2` wrapper: `lib/mailglass/webhook/plug.ex:100`
- ordered request body: `lib/mailglass/webhook/plug.ex:119`
- raw-body failure path: `lib/mailglass/webhook/plug.ex:211`
- Postmark config extraction: `lib/mailglass/webhook/plug.ex:230`
- verify wrapper: `lib/mailglass/webhook/plug.ex:283`
- post-verify ingest handoff: `lib/mailglass/webhook/plug.ex:327`

**Concrete excerpt to mirror**

```elixir
case verify_with_telemetry!(provider, raw_body, headers, config) do
  :ok ->
    tenant_id = resolve_tenant!(provider, conn, raw_body, headers)

    Tenancy.with_tenant(tenant_id, fn ->
      events =
        provider
        |> provider_module()
        |> apply(:normalize, [raw_body, headers])

      ingest_and_respond(conn, provider, raw_body, events, tenant_id)
    end)
end
```

**Phase 40 adaptation**

- Replace `%Mailglass.Events.Event{}` normalization with pure `%MailglassInbound.InboundMessage{}` normalization plus evidence facts.
- Preserve the same ordering. `40-CONTEXT.md` explicitly locks verify before tenant resolution and persistence.
- Response outcomes should stay explicit: success, duplicate, rejected auth, tenant unresolved, config error.

---

### `mailglass_inbound/lib/mailglass_inbound/ingress/caching_body_reader.ex`

**Analog:** `lib/mailglass/webhook/caching_body_reader.ex`

**Copy this exact raw-body capture pattern**

- store bytes in `conn.private[:raw_body]`
- accumulate chunked reads as iodata and flatten only on final chunk
- keep the reader local to the inbound ingress path, not global

**Anchor lines**

- module contract: `lib/mailglass/webhook/caching_body_reader.ex:1`
- `read_body/2`: `lib/mailglass/webhook/caching_body_reader.ex:52`

**Concrete excerpt to mirror**

```elixir
case Plug.Conn.read_body(conn, opts) do
  {:ok, body, conn} ->
    raw = IO.iodata_to_binary([conn.private[:raw_body] || <<>>, body])
    {:ok, body, Plug.Conn.put_private(conn, :raw_body, raw)}

  {:more, body, conn} ->
    raw = [conn.private[:raw_body] || <<>>, body]
    {:more, body, Plug.Conn.put_private(conn, :raw_body, raw)}
end
```

**Phase 40 adaptation**

- Keep the storage key the same unless there is a strong package-local reason to diverge.
- The plug should fail loudly if `conn.private[:raw_body]` is absent, matching the webhook plug posture.

---

### `mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex`

**Analog:** `lib/mailglass/webhook/providers/postmark.ex`

**Copy these provider-seam rules**

- verify with Basic Auth first and fail closed
- keep optional IP allowlisting separate from default auth
- keep normalization pure and provider-shaped parsing isolated here
- log unmapped provider facts with warnings, not silent fallbacks

**Anchor lines**

- module boundary: `lib/mailglass/webhook/providers/postmark.ex:1`
- `verify!/3`: `lib/mailglass/webhook/providers/postmark.ex:38`
- `fetch_basic_auth!/1`: `lib/mailglass/webhook/providers/postmark.ex:49`
- `verify_basic_auth!/3`: `lib/mailglass/webhook/providers/postmark.ex:64`
- `verify_ip_allowlist!/1`: `lib/mailglass/webhook/providers/postmark.ex:94`
- `normalize/2`: `lib/mailglass/webhook/providers/postmark.ex:158`
- event builder split: `lib/mailglass/webhook/providers/postmark.ex:173`
- stable provider id derivation: `lib/mailglass/webhook/providers/postmark.ex:254`

**Concrete excerpt to mirror**

```elixir
def verify!(_raw_body, headers, %{} = config) when is_list(headers) do
  {user, pass} = fetch_basic_auth!(config)
  verify_basic_auth!(headers, user, pass)
  verify_ip_allowlist!(config)
  :ok
end
```

**Phase 40 adaptation**

- Change the pure output to a normalized `%MailglassInbound.InboundMessage{}` plus provider evidence facts needed by persistence.
- Preserve the distinction from `40-CONTEXT.md`:
  - `MessageID` -> `provider_message_id`
  - RFC `Message-Id` header -> `message_id`
  - `OriginalRecipient` -> `envelope_recipient`
- Build recipient/sender fields from structured Postmark contact data, not only legacy flat strings.
- Keep stripped-body helpers and attachment bytes out of the canonical struct; store those in evidence or warnings.

---

### `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex`

**Analog:** `lib/mailglass/webhook/provider.ex`

**Copy this sealed internal behaviour shape**

- one internal provider behaviour
- conn-free callback arguments
- separate verify from normalize
- keep it internal; reachability is not public API

**Anchor lines**

- module and sealed/internal posture: `lib/mailglass/webhook/provider.ex:1`
- `@callback verify!`: `lib/mailglass/webhook/provider.ex:24`
- `@callback normalize`: `lib/mailglass/webhook/provider.ex:45`

**Concrete excerpt to mirror**

```elixir
@callback verify!(
            raw_body :: binary(),
            headers :: [{String.t(), String.t()}],
            config :: map()
          ) :: :ok | {:ok, :replay}

@callback normalize(
            raw_body :: binary(),
            headers :: [{String.t(), String.t()}]
          ) :: [Mailglass.Events.Event.t()]
```

**Phase 40 adaptation**

- Same shape, but return a single normalized inbound payload shape rather than event lists.
- Keep this module internal. `mailglass_inbound/docs/api_stability.md:35` marks persistence and wiring modules as internal, and Phase 40 should not widen that contract.

---

### `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex`

**Analog:** `lib/mailglass/webhook/ingest.ex`

**Copy this transaction pattern**

- one transaction boundary
- duplicate check inside the same transaction snapshot
- build the multi in one internal function
- return a compact result the caller can map to HTTP outcomes

**Anchor lines**

- module contract: `lib/mailglass/webhook/ingest.ex:1`
- `ingest_multi/3`: `lib/mailglass/webhook/ingest.ex:121`
- multi builder: `lib/mailglass/webhook/ingest.ex:181`
- conflict insert: `lib/mailglass/webhook/ingest.ex:216`
- final status/update pass: `lib/mailglass/webhook/ingest.ex:225`
- caller result shaping: `lib/mailglass/webhook/ingest.ex:464`

**Concrete excerpt to mirror**

```elixir
result =
  Repo.transact(fn ->
    multi = build_multi(provider, raw_body, events, tenant_id)

    case Repo.multi(multi) do
      {:ok, changes} -> {:ok, finalize_changes(changes, events)}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end)
```

**Concrete duplicate/idempotency pattern to mirror**

```elixir
Multi.run(Multi.new(), :duplicate_check, fn _repo, _changes ->
  duplicate_query =
    from(w in WebhookEvent,
      where: w.provider == ^provider_str and w.provider_event_id == ^provider_event_id,
      select: true,
      limit: 1
    )

  exists? = Repo.one(Tenancy.scope(duplicate_query, tenant_id)) == true
  {:ok, exists?}
end)
```

**Phase 40 adaptation**

- The transactional writes become:
  - insert canonical inbound record
  - insert linked evidence row
  - optionally compute route-match proof before returning
- Use the same `Repo.transact(fn -> Repo.multi(multi) end)` posture rather than ad hoc sequential inserts.
- Implement dedupe around `(tenant_id, provider, provider_message_id)` as locked by `40-CONTEXT.md`.
- Do not insert replay lineage here. `40-CONTEXT.md` explicitly forbids `ReplayRun` creation on fresh ingress.

---

### `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex`

**Analog:** existing `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex`

**Copy this package-local persistence boundary**

- expose small `change_*` and `insert_*` helpers
- centralize outcome shaping in one boundary module
- keep replay normalization logic package-local

**Anchor lines**

- record helpers: `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex:13`
- evidence helpers: `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex:26`
- replay helpers: `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex:39`
- attr normalization hook: `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex:54`

**Phase 40 adaptation**

- Extend this module with a transaction helper rather than bypassing it from the ingress layer.
- If a new multi-based insert helper is added, keep canonical/evidence shaping here so the ingress plug stays orchestration-only.

---

### `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex`

**Analog:** existing `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex`

**Copy this canonical-row boundary exactly**

- canonical row stores adopter-facing normalized truth only
- raw payload and verification data stay out of this schema
- tenant, provider, and `received_at` are required

**Anchor lines**

- module contract: `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex:1`
- schema: `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex:40`
- required fields: `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex:65`
- changeset: `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex:71`

**Concrete excerpt to preserve**

```elixir
@required ~w[tenant_id provider received_at]a
@cast @required ++
        ~w[provider_message_id message_id envelope_recipient from to cc bcc reply_to subject
           headers sent_at text_body html_body attachments]a
```

**Phase 40 adaptation**

- Do not widen this schema for Postmark-only helpers or attachment bytes.
- If idempotency needs a new unique index, add it in migration space, not by changing this canonical boundary’s purpose.

---

### `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex`

**Analog:** existing `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex`

**Copy this evidence-row boundary exactly**

- one evidence row per canonical record
- evidence owns `raw_payload`, `raw_headers`, `raw_mime`, `verification_facts`, `parse_warnings`, `attachment_blobs`
- foreign key stays package-local

**Anchor lines**

- module contract: `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex:1`
- schema: `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex:31`
- required fields: `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex:47`
- changeset and FK constraint: `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex:51`

**Concrete excerpt to preserve**

```elixir
@required ~w[tenant_id inbound_record_id provider]a
@cast @required ++ ~w[raw_payload raw_headers raw_mime verification_facts parse_warnings attachment_blobs]a
```

**Phase 40 adaptation**

- Store Postmark attachment bytes here, not in `InboundMessage.attachments`.
- `raw_mime` may remain `nil`; do not reconstruct MIME from parsed fields.
- Selected raw request headers should land in `raw_headers`, with verification outcomes in `verification_facts`.

---

### `mailglass_inbound/lib/mailglass_inbound/ingress/route_proof.ex` or equivalent

**Analog:** `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex`

**Copy this narrow compatibility-proof seam**

- matching evaluates the normalized message only
- returns `{:ok, route}` or `:no_match`
- no mailbox execution and no side effects

**Anchor lines**

- module and return shape: `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex:1`
- `match/2`: `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex:8`
- route predicate: `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex:15`
- header matching: `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex:21`

**Concrete excerpt to mirror**

```elixir
@spec match([Route.t()], InboundMessage.t()) :: {:ok, Route.t()} | :no_match
def match(routes, %InboundMessage{} = message) when is_list(routes) do
  Enum.find_value(routes, :no_match, fn route ->
    if matches_route?(route, message), do: {:ok, route}, else: false
  end)
end
```

**Phase 40 adaptation**

- If the ingress transaction returns internal route-proof info, keep it at this same semantic level: matched route or no match.
- Do not call `Mailbox.process/1`. `40-CONTEXT.md` explicitly says route compatibility proof only.

---

### `mailglass_inbound/priv/repo/migrations/*_postmark_ingress_idempotency.exs`

**Analog:** `mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs`

**Copy this migration style**

- package-local tables and FKs only
- explicit tenant indexes
- unique indexes used to express lifecycle constraints

**Anchor lines**

- canonical table: `mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs:6`
- canonical indexes: `mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs:29`
- evidence table: `mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs:32`
- one-to-one evidence uniqueness: `mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs:51`
- replay table: `mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs:54`
- replay uniqueness: `mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs:76`

**Phase 40 adaptation**

- Add the ingress idempotency index here, likely on `mailglass_inbound_records` using `(tenant_id, provider, provider_message_id)` with a `WHERE provider_message_id IS NOT NULL` partial unique index.
- Keep evidence uniqueness one-to-one with the canonical row.
- Do not add any fresh-ingress writes to `mailglass_inbound_replay_runs`.

## Shared Patterns

### Verify-first ingress ordering

**Source:** `lib/mailglass/webhook/plug.ex:119`, `:211`, `:230`, `:283`, `:327`

Apply to all inbound ingress entrypoints:

1. extract exact raw bytes
2. verify Postmark auth
3. resolve tenant
4. normalize to `%MailglassInbound.InboundMessage{}`
5. persist canonical plus evidence in one transaction
6. compute route compatibility proof only

### Sealed internal provider seam

**Source:** `lib/mailglass/webhook/provider.ex:1`, `:24`, `:45`

Apply to provider wiring:

- provider contracts stay internal
- callbacks are conn-free
- verification and normalization stay separate

### Canonical row vs evidence row split

**Source:** `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex:1`, `:40`, `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex:1`, `:31`

Apply to persistence:

- canonical row contains normalized adopter-facing truth
- evidence row contains replay/debug/security material
- do not contaminate the public `%InboundMessage{}` contract with provider-only evidence

### Route compatibility proof, not execution

**Source:** `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex:8`, `mailglass_inbound/test/mailglass_inbound/router_test.exs:83`, `mailglass_inbound/docs/api_stability.md:100`

Apply to routing work:

- no-match is explicit and non-exceptional
- first-match-wins remains the rule
- mailbox identity may be surfaced internally, but mailbox execution does not occur in Phase 40

## Test Patterns To Copy

### Ingress plug tests

**Analogs:** `test/mailglass/webhook/plug_test.exs:48`, `:139`, `:173`, `:197`

Copy the pattern of asserting:

- exact status codes by failure class
- log discipline with atom-only failure metadata
- missing raw-body reader fails as config error
- tenant unresolved stays distinct from auth failure

### Provider tests

**Analogs:** `test/mailglass/webhook/providers/postmark_test.exs:18`, `:26`, `:224`, `:247`

Copy the pattern of asserting:

- each auth failure maps to a closed error type
- normalization maps provider payloads deterministically
- malformed or unmapped provider input warns explicitly

### Router/persistence boundary tests

**Analogs:** `mailglass_inbound/test/mailglass_inbound/router_test.exs:52`, `:72`, `:83`; `mailglass_inbound/test/mailglass_inbound/persistence_test.exs:12`, `:44`

Copy the pattern of asserting:

- route matching works on normalized `%InboundMessage{}` only
- no-match returns `:no_match`
- canonical/evidence boundaries stay separate
- package-local FKs and required tenant scope remain enforced

## Strongest Reusable Patterns

- `Mailglass.Webhook.Plug` is the primary analog for the full Phase 40 ingress sequence. Copy its ordering and explicit outcome mapping, not its `%Event{}` payload shape.
- `Mailglass.Webhook.Providers.Postmark` is the primary analog for Postmark auth posture and provider-local parsing. Copy its fail-closed verification and pure normalization split.
- `Mailglass.Webhook.Ingest` is the primary analog for one-transaction durable truth and ingress idempotency. Copy the transaction structure and duplicate-check posture, then swap in canonical/evidence row inserts.
- `MailglassInbound.InboundRecord` and `InboundEvidence` are already the correct storage boundary. Phase 40 should populate them, not redesign them.
- `MailglassInbound.Router.Matcher` is the exact route-compatibility proof seam. Reuse it directly or wrap it thinly; do not introduce mailbox execution here.

## Metadata

**Analog search scope:** `lib/mailglass/webhook/**`, `mailglass_inbound/lib/mailglass_inbound/**`, `mailglass_inbound/priv/repo/migrations/**`, `test/mailglass/webhook/**`, `mailglass_inbound/test/mailglass_inbound/**`
**Pattern extraction date:** 2026-05-06
