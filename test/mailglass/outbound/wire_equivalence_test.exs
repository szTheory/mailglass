defmodule Mailglass.Outbound.WireEquivalenceTest do
  use Mailglass.DataCase, async: false

  import Ecto.Query

  alias Mailglass.{Events.Event, Message, Outbound, TestRepo}
  alias Mailglass.Outbound.Delivery

  setup do
    Mailglass.TestSupport.SandboxOwnership.with_app_env!(:mailglass)

    prior_adapter = Application.get_env(:mailglass, :adapter)
    prior_async_adapter = Application.get_env(:mailglass, :async_adapter)

    Application.put_env(
      :mailglass,
      :adapter,
      {Mailglass.Outbound.WireEquivalenceTest.CapturingAdapter, [test_pid: self()]}
    )

    on_exit(fn ->
      Application.put_env(:mailglass, :adapter, prior_adapter)
      Application.put_env(:mailglass, :async_adapter, prior_async_adapter)
    end)

    :ok
  end

  @tag phase_151_task: "t151_01_01"
  test "sync and the actual queued job hand the adapter equivalent prepared input" do
    if not Code.ensure_loaded?(Mailglass.Outbound.Worker) do
      :skip
    else
      Application.put_env(:mailglass, :async_adapter, :oban)

      start_supervised!(
        {Oban, testing: :disabled, repo: TestRepo, queues: [mailglass_outbound: 10]}
      )

      markers = private_markers()

      sync_message =
        fully_featured_message(markers)
        |> Message.put_metadata(:delivery_id, Ecto.UUID.generate())

      async_message =
        fully_featured_message(markers)
        |> Message.put_metadata(:delivery_id, Ecto.UUID.generate())

      assert {:ok, %Delivery{} = sync_delivery} = Outbound.deliver(sync_message)
      assert_receive {:adapter_input, captured_sync_message, sync_opts}

      # The public idempotency key intentionally deduplicates equal recipient
      # and body content. Release this first fixture's key only so the actual
      # durable path can exercise the same wire payload independently.
      sync_delivery =
        TestRepo.update!(
          Ecto.Changeset.change(sync_delivery,
            idempotency_key: "wire-equivalence-#{System.unique_integer([:positive])}"
          )
        )

      assert {:ok, %Delivery{} = queued_delivery} = Outbound.deliver_later(async_message)

      job =
        TestRepo.one!(
          from(j in Oban.Job,
            where: j.queue == "mailglass_outbound" and j.args["delivery_id"] == ^queued_delivery.id
          )
        )

      assert job.args == %{
               "delivery_id" => queued_delivery.id,
               "mailglass_tenant_id" => "test-tenant"
             }

      assert :ok = Mailglass.Outbound.Worker.perform(job)
      assert_receive {:adapter_input, captured_async_message, async_opts}

      assert canonical_adapter_input(captured_sync_message, sync_opts) ==
               canonical_adapter_input(captured_async_message, async_opts)

      for surface <- public_surfaces(sync_delivery, queued_delivery, job) do
        inspected = inspect(surface)

        Enum.each(private_surface_markers(markers), fn marker ->
          refute inspected =~ marker
        end)
      end
    end
  end

  defp canonical_adapter_input(%Message{} = message, opts) do
    email = message.swoosh_email

    %{
      recipient_fields: %{to: email.to, cc: email.cc, bcc: email.bcc},
      from: email.from,
      reply_to: email.reply_to,
      subject: email.subject,
      html_body: email.html_body,
      text_body: email.text_body,
      headers: email.headers,
      attachments: Enum.map(email.attachments, &Map.from_struct/1),
      provider_options: email.provider_options,
      tags: message.tags,
      metadata: Map.drop(message.metadata, [:delivery_id, "delivery_id"]),
      tenant_id: message.tenant_id,
      stream: message.stream,
      adapter_opts: Keyword.delete(opts, :test_pid)
    }
  end

  defp public_surfaces(sync_delivery, queued_delivery, job) do
    sync_event = TestRepo.get_by!(Event, delivery_id: sync_delivery.id, type: :dispatched)
    queued_event = TestRepo.get_by!(Event, delivery_id: queued_delivery.id, type: :dispatched)

    [
      sync_delivery.metadata,
      sync_event.metadata,
      sync_event.normalized_payload,
      queued_delivery.metadata,
      queued_event.metadata,
      queued_event.normalized_payload,
      job.args
    ]
  end

  defp fully_featured_message(markers) do
    attachment =
      Swoosh.Attachment.new({:data, markers.attachment},
        filename: "#{markers.attachment}.txt",
        content_type: "text/plain"
      )

    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Wire Sender", "#{markers.from}@example.com"})
      |> Swoosh.Email.cc({"Wire Recipient", "#{markers.recipient}@example.com"})
      |> Swoosh.Email.reply_to({"Wire Reply", "#{markers.reply_to}@example.com"})
      |> Swoosh.Email.subject(markers.subject)
      |> Swoosh.Email.html_body("<p>#{markers.html}</p>")
      |> Swoosh.Email.text_body(markers.text)
      |> Map.put(:headers, [
        {"X-Wire-Order", markers.header_one},
        {"X-Wire-Order", markers.header_two}
      ])
      |> Map.put(:attachments, [attachment])
      |> Map.put(:provider_options, %{"wire_option" => markers.option})

    Message.build(email,
      mailable: Mailglass.FakeFixtures.TestMailer,
      tenant_id: "test-tenant",
      stream: :transactional,
      tags: [markers.tag_one, markers.tag_two],
      metadata: %{wire_metadata: markers.metadata}
    )
  end

  defp private_markers do
    unique = Integer.to_string(System.unique_integer([:positive]))

    %{
      from: "wire-from-#{unique}",
      recipient: "wire-recipient-#{unique}",
      reply_to: "wire-reply-#{unique}",
      subject: "wire-subject-#{unique}",
      html: "wire-html-#{unique}",
      text: "wire-text-#{unique}",
      header_one: "wire-header-one-#{unique}",
      header_two: "wire-header-two-#{unique}",
      attachment: "wire-attachment-#{unique}",
      option: "wire-option-#{unique}",
      tag_one: "wire-tag-one-#{unique}",
      tag_two: "wire-tag-two-#{unique}",
      metadata: "wire-metadata-#{unique}"
    }
  end

  # Message metadata is an intentionally adopter-visible, PII-free projection;
  # it is compared in the adapter oracle but is not a private-content sentinel.
  defp private_surface_markers(markers), do: Map.values(Map.delete(markers, :metadata))
end

defmodule Mailglass.Outbound.WireEquivalenceTest.CapturingAdapter do
  @moduledoc false
  @behaviour Mailglass.Adapter

  @impl Mailglass.Adapter
  def deliver(%Mailglass.Message{} = message, opts) do
    send(Keyword.fetch!(opts, :test_pid), {:adapter_input, message, opts})
    {:ok, %{message_id: "captured", provider_response: %{captured: true}}}
  end
end
