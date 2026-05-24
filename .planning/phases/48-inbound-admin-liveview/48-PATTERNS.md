# Phase 48: Inbound Admin LiveView - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 19 (15 new, 4 modified)
**Analogs found:** 17 exact/role-match + 2 NET-NEW (chrome reuse) / 19

This is a **clone-heavy plumbing phase**. Almost every new file has a shipped outbound analog inside `mailglass_admin/lib/mailglass_admin/operator/` (the `OperatorLive` surface). The only genuinely novel logic is one reflection function (`Router.Matcher.explain/2`) and two NET-NEW LiveComponents that reuse existing card/badge/timeline chrome. The planner should clone, not invent.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mailglass_admin/.../inbound_live.ex` | LiveView (controller) | request-response + event-driven | `mailglass_admin/.../operator_live.ex` | exact (clone shell) |
| `mailglass_admin/.../inbound/records_list.ex` | component | transform/render | `operator/deliveries_list.ex` | exact |
| `mailglass_admin/.../inbound/detail_header.ex` | component | transform/render | `operator/detail_header.ex` | exact (+ defensive read) |
| `mailglass_admin/.../inbound/timeline.ex` | component | transform/render | `operator/timeline.ex` | exact |
| `mailglass_admin/.../inbound/replay_modal.ex` | component | request-response | `operator/replay_modal.ex` | role-match (SIMPLIFIED) |
| `mailglass_admin/.../inbound/filters_form.ex` | component | transform/render | `operator/filters_form.ex` | exact |
| `mailglass_admin/.../inbound/routing_trace.ex` | component | transform/render | (timeline/card chrome) | NET-NEW |
| `mailglass_admin/.../inbound/evidence_card.ex` | component | transform/render | (card chrome) | NET-NEW |
| `mailglass_admin/.../inbound/destructive_action.ex` | utility (auth guard) | request-response | `operator/destructive_action.ex` | exact (re-shaped context) |
| `mailglass_admin/.../optional_deps/mailglass_inbound.ex` | config (gateway) | event-driven | `optional_deps/phoenix_live_reload.ex` + `lib/mailglass.ex:55-60` | exact |
| `mailglass_admin/.../components.ex` (MOD) | component lib | transform | `operator/deliveries_list.ex:98-121` (promote) | exact |
| `mailglass_admin/.../pub_sub/topics.ex` (MOD) | utility (topic builder) | pub-sub | `mailglass_inbound/.../pub_sub/topics.ex:33-34` | exact (string parity) |
| `mailglass_admin/.../router.ex` (MOD) | route macro | config | self (existing `mailglass_operator_routes/2`) | extend in place |
| `mailglass_admin/mix.exs` (MOD) | config | — | self (`mailglass_dep/0` l.126-132) | mirror, FLOATING |
| `mailglass_inbound/.../router/matcher.ex` (MOD) | utility (matcher) | transform | self (`defp` predicates l.45-48, l.37) | extend in place |
| `mailglass_inbound/.../internal/operator/records.ex` | service (read-model) | CRUD (read) | `lib/mailglass/operator/deliveries.ex:18-50` | exact |
| `mailglass_inbound/.../internal/operator/timeline.ex` | service (read-model) | CRUD (read) | `lib/mailglass/operator/timeline.ex` + `internal/replay.ex:84-93` | role-match |
| `mailglass_inbound/.../internal/operator/detail.ex` | service (read-model) | CRUD (read) | `internal/replay.ex:30-67` (load + resolve_mailbox) | role-match |
| `mailglass_admin/config/test.exs` + `test_helper.exs` (MOD, Wave 0) | test config | — | existing core-repo bootstrap | role-match |

---

## Pattern Assignments

### `inbound_live.ex` (LiveView, clone of `operator_live.ex`)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`

**`handle_params` URL-state shape** (operator_live.ex:68-81) — clone verbatim, swap `delivery_id`→`inbound_id`, default path `/operator`→`/inbound`:
```elixir
def handle_params(params, uri, socket) do
  filter_params = normalize_filter_params(params)
  {:noreply,
   socket
   |> assign(:base_path, URI.parse(uri).path || "/operator")
   |> assign(:filter_params, filter_params)
   |> assign(:filter_form, to_form(filter_params, as: :filters))
   |> assign_delivery_state(filter_params, blank_to_nil(params["delivery_id"]))
   |> close_replay_modal()}
end
```

**`push_patch` selection event** (operator_live.ex:98-103) — clone; renames only:
```elixir
def handle_event("select_delivery", %{"id" => delivery_id}, socket) do
  {:noreply,
   push_patch(socket,
     to: build_path(socket.assigns.base_path, socket.assigns.filter_params, delivery_id))}
end
```

**Tenant-required-or-empty gate** (operator_live.ex:338) — the load-bearing security head; clone exactly:
```elixir
defp load_deliveries(%{"tenant_id" => ""}), do: []
defp load_deliveries(filter_params) do
  Deliveries.list_recent_deliveries(%{tenant_id: filter_params["tenant_id"], ...}, [])
end
```
For inbound: `defp load_inbound_records(%{"tenant_id" => ""}), do: []` then route through `apply/3` to the gateway (see Shared Pattern: Optional-Dep Gateway). NEVER call `MailglassInbound.*` by bare reference.

**Filter param normalization + enum casting** (operator_live.ex:326-336, 487-495) — clone. The inbound outcome filter casts against `ExecutionRun.__outcomes__/0` (`[:no_match, :accept, :ignore, :reject, :bounce, :failed]`) instead of `@status_values`. `cast_enum/2` (l.487) is the allow-list guard to reuse for V5 input validation.

**`assign_*_state` aggregation** (operator_live.ex:408-427) — the pattern that loads list + selected + timeline + detail in one pass; clone, replacing the outbound read-model calls with `apply(gateway_module, :list_records | :timeline | :detail, [...])`.

**Replay confirm flow** (operator_live.ex:142-187) — clone the `with`-chain shape. SIMPLIFY: no `selected_replay_target/2` branching (the replay target is the record itself, D-48-08). Critical addition (D-48-05): verify `selected_inbound_record.tenant_id == filter_params["tenant_id"]` BEFORE calling the un-scoped `Internal.Replay.replay/2`. Map structured errors to UI-SPEC copy (see Shared Pattern: Replay Error → Copy).

**Render shell** (operator_live.ex:190-314) — clone root `<div data-theme="mailglass-light">` → `<main class="mx-auto max-w-7xl ...">` → flash band → filter card → `lg:grid-cols-[minmax(22rem,28rem)_1fr]` master/detail split → modal outside `<main>`. UI-SPEC Screen Contract pins every class. Detail-pane order: header → timeline → routing-trace (only when outcome `:no_match`) → evidence card.

**Live-update subscribe + handle_info** — NET behavior, mount-side. Subscribe via `Phoenix.PubSub.subscribe(Mailglass.PubSub, MailglassAdmin.PubSub.Topics.inbound_record_inserted(tenant_id))`. Payload is id-only (`{:inbound_record_inserted, record_id, _meta}`); `handle_info/2` re-fetches TENANT-SCOPED through the read-model and prepends without stealing selection/filters (D-48-11, Pitfall 6).

---

### `inbound/records_list.ex` (component, clone of `deliveries_list.ex`)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`

**attr/empty-state/row structure** (deliveries_list.ex:10-69) — clone. Empty-state copy swaps to UI-SPEC: "No inbound records" / "No inbound records match these filters...".

**Selected-row treatment** (deliveries_list.ex:31-40, 71-78) — `aria-current`/`aria-selected` + `border-l-4 border-primary bg-base-100` (selected) vs `border-l-4 border-transparent bg-base-200 hover:bg-base-100`. Clone verbatim (Accessibility Contract requires it).

**Masking** — DO NOT clone the private `mask_recipient/1` (deliveries_list.ex:98-121). Call the promoted public `MailglassAdmin.Components.mask_recipient/1` (D-48-13). Row meta line: `tenant · PROVIDER · matched-mailbox-or-"no match" · received_at`.

---

### `inbound/detail_header.ex` (component, clone of `detail_header.ex`)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex`

**Header + `<dl>` grid** (detail_header.ex:14-57) — clone. Fields: Tenant, Provider, From (masked via `Components.mask_recipient/1`), Subject, Received, Matched mailbox.

**`suppression_flagged` defensive read** — CRITICAL (Pitfall 2): the field does NOT exist on any schema in Phase 48. Use `Map.get(record, :suppression_flagged, false)`, NEVER `record.suppression_flagged` (raises `KeyError`). Render the IOPS-05 copy only when truthy — it will simply never render until Phase 49 (forward-compatible scaffolding).

**Replay action row** (detail_header.ex:59-76) — clone the bottom action row + `btn btn-error min-h-11` Replay button. Disable when displayed outcome is `:no_match` (Pitfall 1 — replay always fails there).

---

### `inbound/timeline.ex` (component, clone of `timeline.ex`)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/timeline.ex`

**Vertical timeline structure** (timeline.ex:13-65) — clone the `<ol>` of nodes: dot + connector line + bordered `bg-base-100` card per row. Rows are **`ExecutionRun`** records (NOT `ReplayRun` — Pitfall 7), ordered chronologically by `executed_at`.

**Source badge** — `source: :replay` → `badge badge-outline` (mirrors the outbound replay event badge at timeline.ex:122-126: `"badge badge-outline badge-error"`). Render `Fresh`/`Replay` text. Show `outcome` label, `outcome_reason` inline when present (`ExecutionRun.outcome_reason`), `executed_at` + run id in mono.

**Outcome → dot color** (timeline.ex:148-154 pattern) — re-map to inbound outcomes per UI-SPEC Color table: `:accept`→`bg-success`, `:no_match`→`bg-warning`, `:reject|:bounce|:failed`→`bg-error`, `:ignore`→`bg-secondary`.

---

### `inbound/replay_modal.ex` (component, clone-simplified of `replay_modal.ex`)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex`

**Modal chrome** (replay_modal.ex:17-35, 89-102) — clone the `fixed inset-0 z-50 ... bg-base-content/40` overlay, `max-w-2xl rounded-box ... shadow-2xl` card, Close button, and Cancel/`Confirm replay btn btn-error min-h-11` footer.

**SIMPLIFY** — DELETE the entire `case @replay_targets do` block (replay_modal.ex:36-87) and the `target_card`/`confirm_enabled?` helpers (l.109-142). Inbound replay has no ambiguous-multi target (IADM-03 — target is the record itself). Single confirmation body using UI-SPEC copy: "Replay inbound: This re-runs mailbox routing against the stored message and records a new replay run in the append-only ledger. Confirm to replay." `Confirm replay` always enabled when modal open.

---

### `inbound/filters_form.ex` (component, clone of `filters_form.ex`)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex`

**Field structure** (filters_form.ex:13-91) — clone. Each control: `min-h-11`, label `text-xs font-bold uppercase tracking-[0.08em] text-secondary`. Inbound filters (UI-SPEC): tenant (text), provider (text), **mailbox outcome** (select over `ExecutionRun.__outcomes__/0` — replaces the `status`+`event` selects), time window (24h/7d/30d select), search (text). Reuse the `<option>` loop pattern at l.49-55.

---

### `inbound/destructive_action.ex` (utility, clone of `destructive_action.ex`)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex`

**Authorize seam** (destructive_action.ex:15-31) — clone the structure but RE-SHAPE the context (D-48-10): action `:destructive_action`→`:replay_inbound`; context key `:delivery`/`:replay_target`→`:inbound_record`. Do NOT pass an inbound record under `:delivery` (adopter `Auth` may pattern-match `%Mailglass.Outbound.Delivery{}`). Keep the shipped outbound module untouched — this is a sibling, not a refactor.
```elixir
# RE-SHAPED for inbound (D-48-10):
def authorize(%Socket{} = socket, adapter, inbound_record) when is_atom(adapter) do
  case Auth.authorize(adapter, :replay_inbound, %{
         actor: socket.assigns.operator_actor,
         inbound_record: inbound_record          # inbound key, NOT :delivery
       }) do
    {:ok, %{actor: actor, assigns: extra}} -> {:ok, assign(socket, :operator_actor, actor)}
    {:error, _reason, details} ->
      {:error, {:auth, Map.get(details, :message,
         "Replay blocked: this action is not authorized for the current operator.")}}
  end
end
```
The `:reveal_raw` capability gate (evidence card) rides the SAME `Auth.authorize/3` seam with action `:reveal_raw` — no new auth module/plug/behaviour (D-48-09; `auth.ex:33` already types `action :: :operator_access | :destructive_action | atom()`).

---

### `optional_deps/mailglass_inbound.ex` (gateway, clone of `phoenix_live_reload.ex`)

**Analog:** `mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex` + `lib/mailglass.ex:55-60`

**Conditional-compile wrapper** (phoenix_live_reload.ex:7-43) — clone the `if Code.ensure_loaded?(...) do defmodule ... end` envelope, `@compile {:no_warn_undefined, [...]}`, and `available?/0 -> true`:
```elixir
if Code.ensure_loaded?(MailglassInbound) do
  defmodule MailglassAdmin.OptionalDeps.MailglassInbound do
    @compile {:no_warn_undefined,
              [MailglassInbound, MailglassInbound.Internal.Operator.Records,
               MailglassInbound.Internal.Operator.Timeline, MailglassInbound.Internal.Operator.Detail,
               MailglassInbound.Router.Matcher, MailglassInbound.Internal.Replay]}
    @spec available?() :: boolean()
    def available?, do: true
  end
end
```
This gateway should ALSO house the `apply/3` call wrappers (read-model, reflection, replay) so InboundLive never references `MailglassInbound.*` directly. Callers guard via `Code.ensure_loaded?(MailglassAdmin.OptionalDeps.MailglassInbound)` (the same pattern as core's Oban gate `lib/mailglass.ex:55-60`: `@oban_exports if Code.ensure_loaded?(Oban.Worker), do: ..., else: []`). Leave Boundary decl `mailglass_admin.ex:45-47` UNCHANGED (D-48-02; absent app in `deps:` → `unknown_dep`, breaks `--no-optional-deps` lane).

---

### `mailglass_inbound/.../router/matcher.ex` (MODIFY — add `explain/2`)

**Analog:** self — reuse the existing `defp` predicates.

**Existing predicates to reuse** (matcher.ex:31-48, verified) — `matches_route?/2` is public (l.31); `matches_headers?/2` (l.37) and `matches_matcher?/2` (l.45-48, the 4 clauses: nil-wildcard PASS, nil-actual FAIL, regex, exact-equality) are `defp` and already co-located. Add `@doc false explain/2` in the SAME module so it calls these clauses directly (single source of truth, D-48-06):
```elixir
@doc false
@spec explain(Route.t(), InboundMessage.t()) :: [tuple()]
def explain(%Route{} = route, %InboundMessage{} = message) do
  [
    {:recipient, route.recipient, message.envelope_recipient,
       matches_matcher?(route.recipient, message.envelope_recipient)},
    {:subject, route.subject, message.subject,
       matches_matcher?(route.subject, message.subject)}
    | Enum.map(route.headers, fn {name, matcher} ->
        actual = Map.get(message.headers, name, [])
        {:header, name, matcher, actual, Enum.any?(actual, &matches_matcher?(matcher, &1))}
      end)
  ]
end
```
**Critical reuse rule:** do NOT copy the equality/regex logic into the view — call `matches_matcher?/2`. The property invariant (V3): `Enum.all?(explain(route, msg), &elem(&1, tuple_size(&1)-1)) == matches_route?(route, msg)`. Data model: `Route` has exactly 4 fields (`route.ex:14`: `mailbox`, `recipient`, `subject`, `headers: []`); `InboundMessage.headers :: %{name => [String.t()]}` (inbound_message.ex:52) — header "actual" is a LIST, missing header renders `[]`.

---

### `inbound/routing_trace.ex` (component, NET-NEW — chrome reuse)

**Analog:** none structural; reuse timeline/card chrome (`timeline.ex` bordered-card + check/x marker language).

**Spec:** UI-SPEC "Routing-trace card". Card `card rounded-box border border-base-300 bg-base-200 p-6`, heading "Routing trace" + sub-label "Why this message did not match". Rendered ONLY when displayed outcome is `:no_match`. One bordered sub-card per route from `inbound_router.__mailglass_inbound_routes__()` (threaded via `:inbound_router` opt — D-48-07). Per-route clause table (Dimension / Expected / Actual) built from `Router.Matcher.explain/2` verdicts. Pass marker `hero-check-circle text-success`, fail `hero-x-circle text-error`; first failing clause gets `border-l-4 border-error pl-3` + composed reason copy (UI-SPEC). Expected/Actual columns in `.mono`; recipient actual masked via `Components.mask_recipient/1`; wildcard `nil` rendered as `any`. Reuses ONLY existing primitives (no charts, no JS).

---

### `inbound/evidence_card.ex` (component, NET-NEW — chrome reuse)

**Analog:** none structural; reuse card chrome.

**Spec:** UI-SPEC "Evidence card". Card `card rounded-box border border-base-300 bg-base-200 p-6`, heading "Raw provider source". Default state: REDACTED + collapsed. `raw_payload`/`raw_mime` are `redact: true` in the schema (inbound_evidence.ex:34,36) — render only `verification_facts` + a redacted summary (provider, byte size, header count) by default; raw body shows the masked placeholder copy. `Reveal raw source` button gated by `Auth.authorize/3` action `:reveal_raw` (same seam as replay). On grant, render raw in `<pre class="mono text-xs">` scroll region; on deny, keep placeholder + brand-voice line. Raw source is read-only, never editable. `raw_headers`/`verification_facts`/`parse_warnings` are NOT redacted (safe to show).

---

### `mailglass_inbound/.../internal/operator/records.ex` (read-model, clone of `Operator.Deliveries`)

**Analog:** `lib/mailglass/operator/deliveries.ex:18-50`

**Tenant-required + scope + projection** (deliveries.ex:18-50) — clone the whole shape: `fetch_tenant_id!/1` raises on blank tenant (l.55-58), `where tenant_id == ^tenant_id` + `maybe_filter_*` + `order_by desc` + `limit` + `select` map projection, then the load-bearing `|> Tenancy.scope(tenant_id) |> Repo.all()` (l.48-49):
```elixir
# Source: lib/mailglass/operator/deliveries.ex:23-49 (clone for InboundRecord)
InboundRecord
|> where([r], r.tenant_id == ^tenant_id)
|> maybe_filter_provider(normalized[:provider])
|> maybe_filter_outcome(normalized[:outcome])    # join/subquery on ExecutionRun
|> maybe_filter_window(normalized[:window_hours])
|> order_by([r], desc: r.received_at, desc: r.inserted_at, desc: r.id)
|> limit(^limit)
|> select([r], %{id: r.id, tenant_id: r.tenant_id, provider: r.provider,
                 envelope_recipient: r.envelope_recipient, subject: r.subject,
                 received_at: r.received_at, inserted_at: r.inserted_at})
|> Tenancy.scope(tenant_id)    # ◄── inbound has ZERO Tenancy.scope today — this is the new line
|> MailglassInbound.Repo.all()
```
Module is `@moduledoc false` (D-48-04). Queries run through `MailglassInbound.Repo` host-repo facade (`all/2`, `one/3`, `get/3`). `Tenancy.scope/2` is `Mailglass.Tenancy.scope/2` (tenancy.ex:269-273).

---

### `mailglass_inbound/.../internal/operator/timeline.ex` (read-model, mirror)

**Analog:** `lib/mailglass/operator/timeline.ex` + `internal/replay.ex:84-93`

The `ExecutionRun` query shape already exists in `Internal.Replay` (replay.ex:84-93, `latest_fresh_run` — `from(run in ExecutionRun, where: run.inbound_record_id == ^id, order_by: [desc: run.inserted_at])`). Mirror it for "all runs for a record" (drop the `limit: 1`, ascending order for chronological display). Add `tenant_id` where-clause + `Tenancy.scope/2`. Select `source`, `mailbox`, `outcome`, `outcome_reason`, `executed_at`, `id`. Build the outcome filter allow-list from `ExecutionRun.__outcomes__/0` (execution_run.ex:76-77).

---

### `mailglass_inbound/.../internal/operator/detail.ex` (read-model, mirror)

**Analog:** `internal/replay.ex:30-67` (`load_record`, `load_evidence`, `resolve_mailbox`)

Reuse the exact query shapes already in `Internal.Replay`: `load_record/2` (replay.ex:30-38), `load_evidence/2` (l.40-48), and the matched-mailbox resolution `resolve_mailbox/2`/`latest_matched_fresh_run/2` (l.50-82). For the detail read-model, ADD the tenant where-clause + `Tenancy.scope/2` (replay's versions load by id only — that's why admin tenant-gates first, D-48-05). Returns canonical `InboundRecord` + `InboundEvidence` (redacted fields handled by the evidence card) + matched mailbox/outcome from the latest fresh `ExecutionRun`. Open Question 2 (research): detail header shows latest *fresh* run's mailbox/outcome; timeline shows all runs.

---

## Shared Patterns

### Optional-Dep Gateway (compile + runtime gate)
**Source:** `mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex` + `lib/mailglass.ex:55-60`
**Apply to:** EVERY inbound access from admin (read-model, reflection, replay) + InboundLive module body + `/inbound` route + nav link.
- Conditional `defmodule` wrapped in `if Code.ensure_loaded?(MailglassInbound)`.
- `@compile {:no_warn_undefined, [...]}` lists every inbound module touched.
- `available?/0 -> true`; callers `Code.ensure_loaded?(MailglassAdmin.OptionalDeps.MailglassInbound)` first.
- All inbound calls via `apply/3` — NO bare `MailglassInbound.*` reference escapes the gateway (else `--no-optional-deps --warnings-as-errors` lane breaks).
- Boundary decl `mailglass_admin.ex:45-47` stays UNCHANGED (D-48-02).

### Tenant-required-or-empty (two layers)
**Source:** `operator_live.ex:338` (LiveView head) + `lib/mailglass/operator/deliveries.ex:48,55-58` (read-model)
**Apply to:** every inbound query + the replay path.
- LiveView: `defp load_*(%{"tenant_id" => ""}), do: []` head before any data call.
- Read-model: `fetch_tenant_id!` raises on blank; `|> Tenancy.scope(tenant_id) |> Repo.all()` is the load-bearing line.
- Replay (D-48-05): admin verifies `record.tenant_id == active_tenant` BEFORE calling un-scoped `Internal.Replay.replay/2` (replay.ex:30-38 loads by id only).

### Capability Gate (no new auth surface)
**Source:** `mailglass_admin/lib/mailglass_admin/auth.ex:33,55` + `operator/destructive_action.ex:15-31`
**Apply to:** `:replay_inbound` (replay modal) and `:reveal_raw` (evidence card).
- `auth.ex:33` types `action :: :operator_access | :destructive_action | atom()` — arbitrary atoms already accepted.
- New inbound `DestructiveAction` sibling passes context under `:inbound_record` (NOT `:delivery`).
- Zero new module/plug/behaviour callback (D-48-09).
- Assigns arrive from the operator Mount hook (`operator/mount.ex:33-38`): `:operator_actor` + `:operator_auth` (with `adapter: opts[:auth]`). InboundLive reads `socket.assigns.operator_auth[:adapter]` for the authorize call — identical to operator_live.ex:150.

### PubSub Topic Builder (string parity, LINT-06)
**Source:** `mailglass_inbound/lib/mailglass_inbound/pub_sub/topics.ex:33-34` (already shipped, Phase 45)
**Apply to:** the new `MailglassAdmin.PubSub.Topics.inbound_record_inserted/1`.
- Inbound side ALREADY exists and broadcasts: `def inbound_record_inserted(tenant_id) when is_binary(tenant_id), do: "mailglass:inbound:" <> tenant_id`.
- Admin builder must produce the IDENTICAL string (V8 parity test).
- Add to `MailglassAdmin.PubSub.Topics` (currently only has `admin_reload/0` at topics.ex:33) following the same `@spec`/`@doc since:` shape. LINT-06 only flags literal topic strings at call sites — always subscribe via the builder.

### Replay Error → Composed Copy
**Source:** `internal/replay.ex:25-27,57-64` structured tuples → UI-SPEC Copywriting Contract
**Apply to:** the replay confirm flow + the `:no_match` disable.
- `{:error, :not_found}` (replay.ex:25) → generic load-error copy.
- `{:error, {:replay_mailbox_missing, %{reason: :no_prior_match}}}` (replay.ex:58,64) → "Replay blocked: mailbox module not found." (a `:no_match` record can NEVER replay — Pitfall 1; disable the button AND map defensively for the render→click race).
- Match the STRUCT/tuple, never the message string (CLAUDE.md rule 7).

### PII Masking (one promoted definition)
**Source:** `operator/deliveries_list.ex:98-121` (the `mask_recipient/1` + `mask_email/2` + `mask_value/1` trio)
**Apply to:** records list, detail header (From), routing-trace recipient "actual".
- PROMOTE `mask_recipient/1` from `defp` (deliveries_list.ex:98-100) to a public `MailglassAdmin.Components.mask_recipient/1` (D-48-13). Move the helpers `mask_email/2` (l.107-112) and `mask_value/1` (l.114-121) with it. ONE audited definition — `deliveries_list.ex` should then call the promoted version too (no duplication).
- `Components.flash/1` (components.ex:75) and `Components.icon/1` (components.ex:44) are reusable AS-IS.

### Router Macro Threading (`:inbound_router` opt)
**Source:** `mailglass_admin/lib/mailglass_admin/router.ex:143-175,236-254,291-302`
**Apply to:** the `mailglass_operator_routes/2` macro + `/inbound` live route.
- Add `:inbound_router` (type `:atom`) to `@operator_opts_schema` (router.ex:143).
- Thread it into both `__operator_session__/2` (l.291-302) AND the `{MailglassAdmin.Operator.Mount, opts}` on_mount tuple (l.244) — the Mount hook already receives the full `opts` (mount.ex:21) and can surface it to assigns.
- Add `live "/inbound", MailglassAdmin.InboundLive, :index` inside the existing operator `live_session` (l.246-251) — same `live_session`, same `Operator.Mount` + Auth gate (D-48-12). Gate via `available?/0` (D-48-03).
- Mirror the existing `@compile {:no_warn_undefined, [...]}` precedent (router.ex:87-94) — add `MailglassAdmin.InboundLive`.

### mix.exs FLOATING optional dep
**Source:** `mailglass_admin/mix.exs:126-132` (`mailglass_dep/0` MIX_PUBLISH branch)
**Apply to:** the new inbound dep helper.
- Mirror `mailglass_dep/0` STRUCTURE but FLOATING, never `==` (D-48-01, Pitfall 4):
```elixir
{:mailglass_inbound, "~> 0.2", optional: true},   # plain entry in deps/0
defp mailglass_inbound_dep do
  if System.get_env("MIX_PUBLISH") == "true",
    do: {:mailglass_inbound, "~> 0.2", optional: true},
    else: {:mailglass_inbound, path: "../mailglass_inbound", optional: true}
end
```
- Add as a SEPARATE line; leave `mailglass_dep/0` untouched (its `== X.Y.Z` shape is the release-please sed anchor — REL-05 exit-1 guard).
- Keep the inbound dep OUT of the release-please `PINS` array (it tracks the 0.x line, excluded from the linked group).

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `inbound/routing_trace.ex` | component | transform/render | The one novel surface (IADM-04). No outbound analog exists; built from `card`/`badge`/timeline chrome + `Router.Matcher.explain/2` output. Spec fully pinned in UI-SPEC "Routing-trace card". |
| `inbound/evidence_card.ex` | component | transform/render | No outbound analog (outbound has no raw-payload evidence surface). Reuses card chrome + the `:reveal_raw` capability gate. Spec in UI-SPEC "Evidence card". Default-redacted driven by schema `redact: true`. |

Both reuse ONLY existing primitives (card, badge, heroicons, mono) — NET-NEW means new component file, not new design tokens (UI-SPEC: zero new tokens, expect no `priv/static/` bundle diff).

---

## Metadata

**Analog search scope:**
- `mailglass_admin/lib/mailglass_admin/operator/` (clone targets) + `operator_live.ex`, `components.ex`, `pub_sub/topics.ex`, `router.ex`, `auth.ex`, `optional_deps/`, `mix.exs`
- `mailglass_inbound/lib/mailglass_inbound/` (`router/matcher.ex`, `router/route.ex`, `router.ex`, `internal/replay.ex`, `pub_sub/topics.ex`, `inbound_records/{inbound_record,inbound_evidence,execution_run}.ex`, `inbound_message.ex`)
- `lib/mailglass/operator/deliveries.ex`, `lib/mailglass/tenancy.ex`, `lib/mailglass.ex` (Oban gate)

**Files scanned (read in full or targeted):** 19

**Key cross-cutting findings:**
- The inbound PubSub topic builder ALREADY exists (Phase 45, `pub_sub/topics.ex:33-34`) — admin only adds the consumer-side mirror, exact string.
- The `ExecutionRun` query shapes for replay (`load_record`, `load_evidence`, `latest_*_run`) ALREADY exist in `Internal.Replay` (replay.ex:30-93) — the read-model mirrors them + adds tenant scoping.
- The matcher `defp` predicates are co-located in `Router.Matcher` — `explain/2` reuses them in-module (no copy).
- `Mailglass.Tenancy.scope/2` is the single load-bearing tenancy call; inbound has ZERO usage today (the read-model introduces the first).

**Pattern extraction date:** 2026-05-24
