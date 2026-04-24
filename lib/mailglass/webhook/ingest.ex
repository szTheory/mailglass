defmodule Mailglass.Webhook.Ingest do
  @moduledoc """
  Webhook ingest — the single `Ecto.Multi` that HOOK-06 reduces to.

  `Mailglass.Webhook.Plug` calls `ingest_multi/3` after signature
  verification + tenant resolution pass. One transaction writes:

    1. One `mailglass_webhook_events` row (raw payload + audit)
    2. N `mailglass_events` rows (one per normalized `%Event{}`)
    3. N projector updates (only for events whose `provider_event_id`
       matches a live `mailglass_deliveries.provider_message_id` —
       orphans skip the projector step per Pitfall 4)
    4. Status flip on the webhook_event row to `:succeeded`

  ## Composition (CONTEXT D-15 amended HOOK-06)

  Inside `Mailglass.Repo.transact/1`:

    1. `SET LOCAL statement_timeout = '2s'` (D-29 — DoS bound)
    2. `SET LOCAL lock_timeout = '500ms'` (D-29)
    3. `Multi.run(:duplicate_check, ...)` — deterministic pre-insert
       lookup against UNIQUE(provider, provider_event_id) inside the
       same snapshot as the upcoming insert. Per revision B5.
    4. `Multi.insert(:webhook_event, ...)` with
       `on_conflict: :nothing, conflict_target: [:provider, :provider_event_id]`
       — UNIQUE collision is a structural no-op.
    5. For each `%Event{}` in the input list:
         a. `Events.append_multi({:event, idx}, fn changes -> attrs end)`
            — function form resolves `delivery_id` lazily by looking up
            `mailglass_deliveries` on `provider_message_id`.
         b. `Multi.run({:projector_categorize, idx}, ...)` classifies the
            inserted event as matched / orphan / no-event-row (per
            revision W4 flat Multi, no nesting anti-pattern).
         c. `Multi.run({:projector_apply, idx}, ...)` calls
            `Projector.update_projections/2` only on `:matched`; orphans
            fall through. The outer Multi owns the rollback scope.
    6. `Multi.update_all(:flip_status, ...)` flips
       `mailglass_webhook_events.status = :succeeded` +
       `processed_at = Clock.utc_now/0`.

  ## Replay semantics

  UNIQUE collision on `(provider, provider_event_id)` is a structural
  no-op. Per revision B5 (dropped the `is_nil(webhook_event.id)`
  heuristic — Ecto's `on_conflict: :nothing, returning: true` returns
  the conflict-target row with its existing id, so id is never nil
  after insert/conflict). The deterministic duplicate signal comes
  from the `:duplicate_check` step's pre-insert lookup; Plan 04's Plug
  returns 200 either way.

  ## Orphan path

  A normalized event whose `message_id` / `sg_message_id` doesn't
  match any `mailglass_deliveries.provider_message_id` is an "orphan"
  — the webhook arrived before the Delivery row committed (empirical
  5-30s race window for SendGrid + Postmark). Per CONTEXT D-15 +
  Pitfall 4: the `mailglass_events` row inserts with
  `delivery_id: nil + needs_reconciliation: true` AND the projector
  step is SKIPPED for that event (`Projector.update_projections/2`
  pattern-matches `%Delivery{}` and would `FunctionClauseError` on
  nil).

  Plan 04-07's `Mailglass.Webhook.Reconciler` Oban cron sweeps these
  orphans and appends a `:reconciled` event when the matching
  Delivery later commits (D-18 — append, never UPDATE).

  ## Output shape

      {:ok, %{
        webhook_event: %WebhookEvent{},
        duplicate: true | false,
        events_with_deliveries: [{event, delivery_or_nil, orphan?}, ...],
        orphan_event_count: non_neg_integer()
      }}

  The 3-tuple `events_with_deliveries` shape (per revision B7) lets
  Plan 04-04's Plug drive post-commit broadcast without set-difference
  recomputation: `{event, delivery, false}` triggers
  `Projector.broadcast_delivery_updated/3`; `{event, nil, true}`
  skips (Plan 04-07 Reconciler emits `:reconciled` when the matching
  Delivery surfaces — broadcasting twice would confuse LiveView
  subscribers).

  Returns `{:error, reason}` if the transact/1 raises (SQLSTATE
  45A01 from append-only ledger violation, statement_timeout
  firing, etc.).
  """

  import Ecto.Query

  alias Ecto.Multi
  alias Mailglass.{Clock, Config, Events, IdempotencyKey, Repo}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.{Delivery, Projector}
  alias Mailglass.Tenancy
  alias Mailglass.Webhook.WebhookEvent

  @doc """
  Ingest a verified webhook into the persistence layer.

  ## Args

    * `provider` — `:postmark | :sendgrid`
    * `raw_body` — verified raw bytes (Plug ensures `verify!/3` returned `:ok`
      before this call)
    * `events` — list of `%Mailglass.Events.Event{}` from `Provider.normalize/2`

  ## Returns

  See module doc for the full output shape. Caller (Plug) iterates
  `:events_with_deliveries` to call `Projector.broadcast_delivery_updated/3`
  AFTER this function returns `{:ok, _}` (Phase 3 D-04 — broadcast
  post-commit).
  """
  @doc since: "0.1.0"
  @spec ingest_multi(atom(), binary(), [Event.t()]) ::
          {:ok, map()} | {:error, term()}
  def ingest_multi(provider, raw_body, events)
      when provider in [:postmark, :sendgrid] and is_binary(raw_body) and is_list(events) do
    # Tenancy.tenant_id!/0 is the fail-loud accessor — raises %TenancyError{:unstamped}
    # when the process-dict key is absent. Unlike Tenancy.current/0 (which falls back
    # to the SingleTenant "default" literal), tenant_id!/0 never auto-defaults. The
    # Plug's with_tenant/2 block form stamps the tenant BEFORE calling ingest_multi/3,
    # so reaching ingest without a stamped process is a programmer error.
    tenant_id = Tenancy.tenant_id!()

    # Per revision B2 + CONTEXT D-11: guard against :async at v0.1. The
    # NimbleOptions schema entry (Plan 04-05) enforces {:in, [:sync, :async]}
    # at boot; this runtime raise catches the reserved knob path so adopters
    # get a clear error rather than a silent :sync fallback.
    case Config.webhook_ingest_mode() do
      :sync ->
        :ok

      :async ->
        raise "webhook_ingest_mode: :async is reserved for v0.5 (CONTEXT D-11); " <>
                "v0.1 supports :sync only"
    end

    Repo.transact(fn ->
      # CONTEXT D-29: SET LOCAL inside the transaction (Pitfall 6 — outside
      # a transaction these are no-ops).
      _ = Repo.query!("SET LOCAL statement_timeout = '2s'", [])
      _ = Repo.query!("SET LOCAL lock_timeout = '500ms'", [])

      multi = build_multi(provider, raw_body, events, tenant_id)

      case Repo.multi(multi) do
        {:ok, changes} ->
          {:ok, finalize_changes(changes, events)}

        {:error, _step, reason, _changes} ->
          {:error, reason}
      end
    end)
  end

  # ---- Multi composition ----------------------------------------------

  defp build_multi(provider, raw_body, events, tenant_id) do
    provider_event_id = derive_webhook_provider_event_id(provider, raw_body, events)
    provider_str = Atom.to_string(provider)

    # Step 0 (per revision B5): deterministic duplicate signal via pre-insert
    # lookup. Runs INSIDE the same transaction (Multi.run) so the read sees
    # the same snapshot as the subsequent insert. If the row already exists,
    # on_conflict: :nothing below is a no-op AND this flag surfaces via
    # finalize_changes/2 so Plan 04's Plug returns 200 without resuming work.
    duplicate_check_step =
      Multi.run(Multi.new(), :duplicate_check, fn _repo, _changes ->
        exists? =
          Repo.one(
            from(w in WebhookEvent,
              where: w.provider == ^provider_str and w.provider_event_id == ^provider_event_id,
              select: true,
              limit: 1
            )
          ) == true

        {:ok, exists?}
      end)

    webhook_event_attrs = %{
      tenant_id: tenant_id,
      provider: provider_str,
      provider_event_id: provider_event_id,
      event_type_raw: derive_event_type_raw(events),
      event_type_normalized: derive_event_type_normalized(events),
      status: :processing,
      raw_payload: parse_raw_payload(raw_body),
      received_at: Clock.utc_now()
    }

    duplicate_check_step
    |> Multi.insert(
      :webhook_event,
      WebhookEvent.changeset(webhook_event_attrs),
      on_conflict: :nothing,
      conflict_target: [:provider, :provider_event_id],
      returning: true
    )
    |> append_events_for_each(events, provider, tenant_id)
    |> update_projections_for_each(events)
    |> Multi.update_all(
      :flip_status,
      &flip_status_query(&1, provider_str),
      set: [status: :succeeded, processed_at: Clock.utc_now()]
    )
  end

  # Step 2: for each %Event{} in the normalized list, append an Events.append_multi
  # step that resolves delivery_id lazily from prior changes. Function-form
  # append_multi (Phase 3 I-03) matches Multi.insert/4 + Oban.insert/2 shape.
  defp append_events_for_each(multi, events, provider, tenant_id) do
    events
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {event, idx}, acc ->
      # Events.append_multi/3 guards `is_atom(name)` — convert the tuple key
      # to an atom via String.to_atom/1. Bounded atom creation: idx is bounded
      # by the event count (Postmark: 1; SendGrid: ≤128 per batch), so atom
      # table growth is O(128) across the library's lifetime — safe.
      Events.append_multi(acc, event_step_name(idx), fn _changes ->
        delivery_id = resolve_delivery_id(provider, event)

        %{
          type: event.type,
          tenant_id: tenant_id,
          delivery_id: delivery_id,
          needs_reconciliation: is_nil(delivery_id),
          idempotency_key:
            IdempotencyKey.for_webhook_event(
              provider,
              extract_event_provider_id(event),
              idx
            ),
          metadata: event.metadata || %{},
          reject_reason: event.reject_reason,
          occurred_at: Clock.utc_now()
        }
      end)
    end)
  end

  # Step 3 (per revision W4 — flat Multi, no nested Repo.multi anti-pattern):
  # Multi.run :projector_categorize classifies the inserted event row; then
  # Multi.run :projector_apply conditionally updates the projection on the
  # OUTER multi's Repo handle. The earlier nested-Multi pattern (Repo.multi
  # inside Multi.run) broke transaction scoping — the outer transaction
  # couldn't roll back the inner writes if a later step failed. This keeps
  # everything in one transaction.
  defp update_projections_for_each(multi, events) do
    events
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {_event, idx}, acc ->
      acc =
        Multi.run(acc, {:projector_categorize, idx}, fn _repo, changes ->
          inserted_event = Map.get(changes, event_step_name(idx))

          cond do
            is_nil(inserted_event) ->
              {:ok, :no_event_row}

            is_nil(inserted_event.delivery_id) ->
              {:ok, :orphan_skipped}

            true ->
              case Repo.get(Delivery, inserted_event.delivery_id) do
                nil -> {:ok, :orphan_skipped}
                %Delivery{} = delivery -> {:ok, {:matched, delivery, inserted_event}}
              end
          end
        end)

      Multi.run(acc, {:projector_apply, idx}, fn repo, changes ->
        case Map.get(changes, {:projector_categorize, idx}) do
          {:matched, delivery, inserted_event} ->
            changeset = Projector.update_projections(delivery, inserted_event)

            case repo.update(changeset) do
              {:ok, _projected} -> {:ok, {delivery, inserted_event}}
              {:error, reason} -> {:error, reason}
            end

          other ->
            # :no_event_row or :orphan_skipped — pass through
            {:ok, other}
        end
      end)
    end)
  end

  # Step 4: flip webhook_event.status := :succeeded. Uses update_all against
  # the just-inserted row's id (available via the :webhook_event Multi change).
  defp flip_status_query(changes, provider_str) do
    webhook_event = Map.fetch!(changes, :webhook_event)

    from(w in WebhookEvent,
      where: w.id == ^webhook_event.id and w.provider == ^provider_str
    )
  end

  # ---- Helpers --------------------------------------------------------

  # Events.append_multi/3 guards `is_atom(name)` for parity with the Phase 2/3
  # single-insert shape (and to keep change-map keys inspectable). We synthesize
  # the step name as `:"event_#{idx}"` — atom creation is bounded by the input
  # batch size (Postmark: 1; SendGrid: ≤128 per batch), so atom table growth
  # is O(128) across the library's lifetime (safe; not an attacker-controlled
  # input).
  @spec event_step_name(non_neg_integer()) :: atom()
  defp event_step_name(idx) when is_integer(idx) and idx >= 0 do
    :"event_#{idx}"
  end

  # Per revision B6 — SendGrid batch idempotency requires the raw_body SHA-256
  # hash discriminator. Plain "first event id" would be incorrect: SendGrid
  # retries the SAME batch (identical bytes) keyed on its first-event-id, but
  # a SECOND batch with a DIFFERENT first event happening to share that id
  # (e.g. batch A: [evt_X, evt_Y]; batch B: [evt_X, evt_Z]) would collide on
  # "evt_X" and mask the second batch's events as a duplicate. A SHA-256 hash
  # of the raw body is content-addressable and deterministic for replays.
  defp derive_webhook_provider_event_id(:sendgrid, raw_body, _events) when is_binary(raw_body) do
    :crypto.hash(:sha256, raw_body)
    |> Base.encode16(case: :lower)
    |> binary_part(0, 32)
  end

  # Postmark sends one event per webhook; provider_event_id from
  # Event.metadata["provider_event_id"] is canonical.
  defp derive_webhook_provider_event_id(:postmark, _raw_body, [first | _]) do
    extract_event_provider_id(first) || ""
  end

  defp derive_webhook_provider_event_id(_provider, _raw_body, []), do: ""

  # Per revision W9 — Plans 02 + 03 normalize/2 emit STRING keys in
  # Event.metadata for JSONB roundtrip safety. Read string keys; retain
  # atom-key fallback for defensive compatibility (never the happy path).
  defp extract_event_provider_id(%Event{metadata: meta}) when is_map(meta) do
    meta["provider_event_id"] || Map.get(meta, :provider_event_id)
  end

  defp extract_event_provider_id(_), do: nil

  defp derive_event_type_raw(events) do
    events
    |> Enum.map(fn e ->
      meta = e.metadata || %{}
      meta["event"] || meta["record_type"] ||
        Map.get(meta, :event) || Map.get(meta, :record_type) || "unknown"
    end)
    |> Enum.uniq()
    |> Enum.join(",")
  end

  defp derive_event_type_normalized(events) do
    events
    |> Enum.map(&Atom.to_string(&1.type))
    |> Enum.uniq()
    |> Enum.join(",")
  end

  defp parse_raw_payload(raw_body) when is_binary(raw_body) do
    case Jason.decode(raw_body) do
      {:ok, payload} when is_map(payload) -> payload
      {:ok, payload} when is_list(payload) -> %{"_batch" => payload}
      _ -> %{"_raw" => raw_body}
    end
  end

  # Look up the matching `%Delivery{}` id by (provider, provider_message_id).
  # Per revision W9 — reads STRING keys ("message_id", "sg_message_id") first;
  # atom-key fallback retained for defensive compatibility. Plans 04-02 +
  # 04-03 normalize/2 standardized on string keys, so this is the happy path.
  defp resolve_delivery_id(provider, %Event{metadata: meta}) when is_map(meta) do
    message_id =
      meta["sg_message_id"] || meta["message_id"] ||
        Map.get(meta, :sg_message_id) || Map.get(meta, :message_id)

    case message_id do
      id when is_binary(id) and id != "" ->
        from(d in Delivery,
          where: d.provider == ^Atom.to_string(provider) and d.provider_message_id == ^id,
          select: d.id,
          limit: 1
        )
        |> Repo.one()

      _ ->
        nil
    end
  end

  defp resolve_delivery_id(_provider, _event), do: nil

  # Build the final result map for the Plug. Per revision B7 — 3-tuples
  # {inserted_event, delivery_or_nil, orphan?} give downstream consumers
  # (Plan 04-04 broadcast_post_commit/1, Plan 04-08 emit_per_event_signals/2)
  # an explicit orphan? flag without recomputing set differences.
  defp finalize_changes(changes, events) do
    webhook_event = Map.get(changes, :webhook_event)

    # Per revision B5 — the duplicate signal is the pre-insert Repo.exists?
    # lookup (Multi step :duplicate_check). The prior heuristic
    # `is_nil(webhook_event.id)` was structurally broken: Ecto's
    # `on_conflict: :nothing, returning: true` returns the conflict-target
    # row WITH its id populated (not nil), so that check never triggered.
    duplicate? = Map.get(changes, :duplicate_check, false) == true

    events_with_deliveries =
      events
      |> Enum.with_index()
      |> Enum.flat_map(fn {input_event, idx} ->
        case Map.get(changes, {:projector_apply, idx}) do
          {delivery, inserted_event} ->
            # Matched — projector ran.
            [{inserted_event, delivery, false}]

          _other ->
            # :orphan_skipped, :no_event_row, or missing. Fall back to the
            # inserted event row (orphan path inserts with delivery_id: nil)
            # so Plan 04-04's broadcast loop still receives a sensible shape
            # even on the orphan branch. Orphans are knowingly skipped for
            # broadcast by Plan 04-04 — Plan 07 Reconciler re-emits when
            # matching Delivery surfaces.
            inserted_event = Map.get(changes, event_step_name(idx), input_event)
            [{inserted_event, nil, true}]
        end
      end)

    orphan_event_count =
      Enum.count(events_with_deliveries, fn {_event, _delivery, orphan?} -> orphan? end)

    %{
      webhook_event: webhook_event,
      duplicate: duplicate?,
      events_with_deliveries: events_with_deliveries,
      orphan_event_count: orphan_event_count
    }
  end
end
