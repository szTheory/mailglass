defmodule MailglassDemo.Personas do
  @moduledoc """
  Single source of truth for the multi-tenant persona stress-fixture cohort
  (RATCHET-01 / CONTEXT D-06, D-08).

  The cohort is defined **once** here as a declarative spec (`spec/0`) and
  materialized by three thin mechanical builders so they cannot diverge:

    1. **Demo seed** — `MailglassDemo.DemoData.reset!/0` calls `seed!/1`.
    2. **Admin e2e** — `mailglass_admin/test/support/operator_fixtures.ex`
       `seed_persona_cohort!/0` reads `spec/0` via a test-only path dep.
    3. **Gallery** — the admin gallery mirrors the long-ID / non-ASCII / null
       *values* (exposed here as named module constants) as static specimens.

  A drift-guard (`persona_drift_guard_test.exs`, D-07) asserts the three
  materializations agree on persona names, edge-case assignments, and the
  shared literal values — defeating the triplication-drift failure mode.

  ## The three personas (D-08)

    * `northstar` — the existing full-lifecycle tenant. Edge cases:
      **many / high-count / error**. Seeded by the existing `DemoData`
      lifecycle body (kept as-is). Selectable (has deliveries).
    * `fjordline-aps` — a single-Delivery tenant. Edge cases:
      **one / long-ID / non-ASCII / null**. Non-ASCII recipient display
      names, a ULID-class long delivery id, a `>= 60`-char Mailable module
      name, and one `:delivered` event with `reject_reason: nil` (a
      legitimate null branch, not an error). Selectable (has one delivery).
    * `helios-void` — a **zero-delivery** tenant. Edge case: **no-data**.
      Realized by *absence*: it inserts no `Delivery` rows, so
      `Mailglass.Operator.Tenants.list_tenants/2` (which keys off distinct
      non-null `Delivery.tenant_id`) correctly omits it from the switcher.

  With `northstar` + `fjordline-aps` both deliveries-bearing there are
  `>= 2` selectable tenants, so the Phase-112 tenant picker has a real reason
  to render (it only appears at `>= 2` tenants).

  This module is demo-app code. The library `lib/` never depends on it; only
  test support crosses the boundary (CONTEXT D-06).
  """

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery

  # --- Persona names (canonical, drift-guarded) -------------------------------

  @northstar "northstar"
  @fjordline "fjordline-aps"
  @helios_void "helios-void"

  # --- Shared stress-specimen literals (D-08 / 116-UI-SPEC) -------------------
  #
  # These EXACT values are mirrored by the admin gallery specimens. The
  # drift-guard asserts byte-consistency between these constants and the
  # gallery, so the gallery and the demo persona stay identical.

  @nonascii_name_latin "Bjørn Hansen"
  @nonascii_name_cjk "山田太郎"
  @long_delivery_id "del_01JXW9ZQKB3V1N4P2RMT7FHCG"
  @long_mailable "Mailglass.Demo.Mailables.TransactionalEmailWithVeryLongModuleName"

  @doc "Canonical persona name: the existing full-lifecycle tenant."
  def northstar, do: @northstar

  @doc "Canonical persona name: the single-Delivery edge-case tenant."
  def fjordline, do: @fjordline

  @doc "Canonical persona name: the zero-delivery (no-data) tenant."
  def helios_void, do: @helios_void

  @doc """
  Shared stress-specimen literals (D-08 / 116-UI-SPEC \"Gallery Stress Specimen
  Values\"). Returned as a map so the gallery and the drift-guard read the
  single source of truth instead of re-typing the literals.
  """
  @spec specimen_literals() :: %{
          nonascii_name_latin: String.t(),
          nonascii_name_cjk: String.t(),
          long_delivery_id: String.t(),
          long_mailable: String.t()
        }
  def specimen_literals do
    %{
      nonascii_name_latin: @nonascii_name_latin,
      nonascii_name_cjk: @nonascii_name_cjk,
      long_delivery_id: @long_delivery_id,
      long_mailable: @long_mailable
    }
  end

  @doc """
  The declarative cohort spec: a list of three persona maps, each
  `%{name, edge_cases, payload}`.

    * `:name` — the tenant id / persona name.
    * `:edge_cases` — a `MapSet` drawn from the 8 canonical edge cases
      (`:no_data`, `:one`, `:many`, `:long_id`, `:non_ascii`, `:null`,
      `:high_count`, `:error`).
    * `:payload` — the minimal data each materializer needs to reproduce the
      persona (the canonical literals for `fjordline-aps`; `:lifecycle` for
      `northstar` which is seeded by the existing `DemoData` body; an empty
      payload for `helios-void` which is realized by absence).

  `spec/0` is side-effect free so admin test-support can consume it without
  running the seed.
  """
  @spec spec() :: [
          %{name: String.t(), edge_cases: MapSet.t(atom()), payload: map()}
        ]
  def spec do
    [
      %{
        name: @northstar,
        edge_cases: MapSet.new([:many, :high_count, :error]),
        payload: %{kind: :lifecycle}
      },
      %{
        name: @fjordline,
        edge_cases: MapSet.new([:one, :long_id, :non_ascii, :null]),
        payload: %{
          kind: :single_delivery,
          long_delivery_id: @long_delivery_id,
          long_mailable: @long_mailable,
          from: [
            %{"name" => @nonascii_name_latin, "address" => "bjorn@fjordline-aps.example"},
            %{"name" => @nonascii_name_cjk, "address" => "yamada@fjordline-aps.example"}
          ],
          recipient: "bjorn.hansen@fjordline-aps.example",
          # The null branch: a :delivered event with reject_reason: nil.
          event_type: :delivered,
          reject_reason: nil
        }
      },
      %{
        name: @helios_void,
        edge_cases: MapSet.new([:no_data]),
        payload: %{kind: :no_deliveries}
      }
    ]
  end

  @doc """
  Materializes the whole cohort into `repo`.

  `northstar` is seeded by the caller's existing lifecycle body (so this only
  seeds the NEW personas) — see `MailglassDemo.DemoData.reset!/0`, which runs
  the northstar lifecycle and then calls `seed!/1` for `fjordline-aps` and
  `helios-void`. `helios-void` is realized by absence (no insert).
  """
  @spec seed!(Ecto.Repo.t()) :: :ok
  def seed!(repo) do
    Enum.each(spec(), fn persona -> materialize!(repo, persona) end)
    :ok
  end

  # northstar is materialized by the existing DemoData lifecycle, not here.
  defp materialize!(_repo, %{name: @northstar}), do: :ok

  # helios-void is realized by ABSENCE — zero Delivery rows (D-08).
  defp materialize!(_repo, %{name: @helios_void}), do: :ok

  defp materialize!(repo, %{name: @fjordline, payload: payload}) do
    occurred_at = DateTime.truncate(DateTime.utc_now(), :second)

    delivery =
      %{
        tenant_id: @fjordline,
        mailable: payload.long_mailable,
        stream: :transactional,
        recipient: payload.recipient,
        adapter_ref: Delivery.default_adapter_ref(),
        provider: "postmark",
        provider_message_id: payload.long_delivery_id,
        status: :sent,
        last_event_type: payload.event_type,
        last_event_at: occurred_at,
        terminal: false,
        idempotency_key: "demo-delivery-#{payload.long_delivery_id}",
        metadata: %{
          "persona" => @fjordline,
          # Non-ASCII display names live in metadata because the outbound
          # Delivery schema has no structured `from` field. The gallery and
          # drift-guard read these same literals.
          "from" => payload.from
        }
      }
      |> Delivery.changeset()
      |> repo.insert!()

    # One event: a :delivered with reject_reason: nil (the legitimate null
    # branch, distinct from a populated :rejected reject_reason).
    %{
      tenant_id: @fjordline,
      delivery_id: delivery.id,
      type: payload.event_type,
      occurred_at: occurred_at,
      reject_reason: payload.reject_reason,
      idempotency_key:
        "demo-event-#{payload.long_delivery_id}-#{payload.event_type}-#{DateTime.to_unix(occurred_at)}",
      metadata: %{"provider" => "postmark", "source" => "webhook"},
      normalized_payload: %{"recipient" => delivery.recipient}
    }
    |> Event.changeset()
    |> repo.insert!()

    :ok
  end
end
