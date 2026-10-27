defmodule MailglassDemo.QuickViewScenarios do
  @moduledoc """
  Pure synthetic quick-view projections shared by the demo Storybook and admin
  test build. The JSON file is the small source of scenario metadata and facts;
  builders add only the production component's route/assign contract.

  `inbound/1` describes supported Inbound component assigns for the next plan.
  Those projections are intentionally absent from `scenarios/0` and from the
  current Storybook until their production story is retained.
  """

  @manifest_path Path.expand("quick_view_scenarios.json", __DIR__)
  @external_resource @manifest_path
  @manifest @manifest_path |> File.read!() |> Jason.decode!()

  @doc "Returns the declarative scenarios currently produced by Storybook or a connected route."
  def scenarios, do: @manifest["scenarios"]

  @doc "Builds production `MailglassAdmin.Operator.QuickView` assigns from a retained Delivery id."
  def delivery(scenario_id) when is_atom(scenario_id) do
    variation_id = Atom.to_string(scenario_id)

    scenario =
      Enum.find(@manifest["scenarios"], fn entry ->
        entry["rendered"] == true and entry["variation_id"] == variation_id and
          String.starts_with?(entry["id"], "qv-delivery-")
      end)

    if is_nil(scenario),
      do: raise(ArgumentError, "unknown retained Delivery scenario #{variation_id}")

    projection = scenario["projection"]
    delivery = projection["delivery"]
    tenant_id = scenario["cohort"]
    list_path = delivery_list_path(tenant_id)

    %{
      delivery: %{
        id: delivery["id"],
        tenant_id: tenant_id,
        recipient: delivery["recipient"],
        subject: delivery["subject"],
        status: status_atom(delivery["status"]),
        last_event_type: event_atom(delivery["last_event_type"]),
        last_event_at: datetime(delivery["last_event_at"]),
        provider: delivery["provider"],
        provider_message_id: delivery["provider_message_id"],
        mailable: delivery["mailable"]
      },
      account_labels: MailglassDemo.Personas.account_labels(),
      full_path: list_path <> "&delivery_id=#{URI.encode_www_form(delivery["id"])}&full=1",
      close_path: list_path,
      previous_path: neighbor_path(list_path, projection["previous_id"]),
      next_path: neighbor_path(list_path, projection["next_id"]),
      position: position(projection["position"]),
      keyboard?: false
    }
  end

  @doc "Builds supported Inbound quick-view assigns for the following plan only."
  def inbound(:northstar_normal), do: inbound_assigns(:northstar, "phase174-inbound-normal", 2, 16)
  def inbound(:northstar_first), do: inbound_assigns(:northstar, "phase174-inbound-first", 1, 16)
  def inbound(:northstar_last), do: inbound_assigns(:northstar, "phase174-inbound-last", 16, 16)

  def inbound(:fjordline_single_unicode) do
    fjordline = fjordline_persona()
    contact_names = Enum.map_join(fjordline.payload.from, " / ", & &1["name"])

    inbound_assigns(
      :fjordline,
      fjordline.payload.long_delivery_id,
      1,
      1,
      record: %{
        id: fjordline.payload.long_delivery_id,
        tenant_id: "fjordline-aps",
        envelope_recipient: fjordline.payload.recipient,
        subject: "Welcome to Fjordline A/S — #{contact_names}",
        outcome: :matched,
        received_at: ~U[2026-10-26 12:00:00Z],
        provider: "postmark",
        mailbox: "MailglassDemo.Inbound.Mailboxes.Support"
      }
    )
  end

  def inbound(:selected_unavailable) do
    %{
      record: nil,
      detail_error: :read_unavailable,
      outside_results?: false,
      account_labels: MailglassDemo.Personas.account_labels(),
      full_path: "/ops/mail/inbound?tenant_id=northstar&inbound_id=phase174-unavailable&full=1",
      close_path: "/ops/mail/inbound?tenant_id=northstar",
      previous_path: nil,
      next_path: nil,
      position: nil,
      keyboard?: false
    }
  end

  defp inbound_assigns(cohort, id, index, total, options \\ []) do
    tenant_id = if cohort == :fjordline, do: "fjordline-aps", else: "northstar"
    list_path = "/ops/mail/inbound?tenant_id=#{tenant_id}"

    record =
      Keyword.get(options, :record, %{
        id: id,
        tenant_id: tenant_id,
        envelope_recipient: "help@northstar.example",
        subject: "Question about the latest account activity",
        outcome: :matched,
        received_at: ~U[2026-10-26 12:00:00Z],
        provider: "postmark",
        mailbox: "MailglassDemo.Inbound.Mailboxes.Support"
      })

    %{
      record: record,
      detail_error: nil,
      outside_results?: false,
      account_labels: MailglassDemo.Personas.account_labels(),
      full_path: list_path <> "&inbound_id=#{URI.encode_www_form(id)}&full=1",
      close_path: list_path,
      previous_path: if(index > 1, do: list_path <> "&inbound_id=phase174-inbound-prev"),
      next_path: if(index < total, do: list_path <> "&inbound_id=phase174-inbound-next"),
      position: %{index: index, total: total},
      keyboard?: false
    }
  end

  defp delivery_list_path(tenant_id) do
    "/ops/mail?tenant_id=#{URI.encode_www_form(tenant_id)}&view=deliveries&window_hours=168"
  end

  defp neighbor_path(_list_path, nil), do: nil
  defp neighbor_path(list_path, id), do: list_path <> "&delivery_id=#{URI.encode_www_form(id)}"

  defp position(nil), do: nil
  defp position(%{"index" => index, "total" => total}), do: %{index: index, total: total}

  defp datetime(value) do
    {:ok, parsed, _offset} = DateTime.from_iso8601(value)
    parsed
  end

  defp status_atom("sent"), do: :sent
  defp status_atom("failed"), do: :failed

  defp event_atom("delivered"), do: :delivered
  defp event_atom("bounced"), do: :bounced

  defp fjordline_persona do
    Enum.find(MailglassDemo.Personas.spec(), &(&1.name == "fjordline-aps"))
  end
end
