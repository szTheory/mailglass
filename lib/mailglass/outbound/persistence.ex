defmodule Mailglass.Outbound.Persistence do
  @moduledoc false

  @compile {:no_warn_undefined, [Mailglass.Outbound.Worker]}

  alias Mailglass.{Clock, Events, Message, Repo, Telemetry, Tenancy}
  alias Mailglass.Outbound.{Delivery, Preflight, Projector}

  def persist_queued(%Message{} = rendered, adapter_ref) do
    idempotency_key = idempotency_key(rendered)
    tenant_id = rendered.tenant_id

    attrs = %{
      tenant_id: tenant_id,
      mailable: inspect(rendered.mailable),
      stream: rendered.stream,
      recipient: Preflight.primary_recipient(rendered),
      recipient_domain: recipient_domain(rendered),
      adapter_ref: adapter_ref,
      status: :queued,
      last_event_type: :queued,
      last_event_at: Clock.utc_now(),
      metadata: rendered.metadata || %{},
      idempotency_key: idempotency_key
    }

    result =
      Telemetry.persist_outbound_multi_span(
        %{step_name: :persist_queued, tenant_id: tenant_id},
        fn ->
          rendered
          |> queued_multi(idempotency_key, attrs)
          |> Repo.multi()
        end
      )

    normalize_multi_result(result)
  end

  def persist_dispatched(
        %Delivery{} = delivery,
        %{message_id: provider_message_id, provider_response: _response}
      ) do
    event_occurred_at = Clock.utc_now()

    event_attrs = %{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      type: :dispatched,
      occurred_at: event_occurred_at,
      normalized_payload: %{provider_message_id: provider_message_id}
    }

    event_for_projection = %Events.Event{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      type: :dispatched,
      occurred_at: event_occurred_at
    }

    result =
      Telemetry.persist_outbound_multi_span(
        %{step_name: :persist_dispatched, tenant_id: delivery.tenant_id},
        fn ->
          Repo.multi(
            Ecto.Multi.new()
            |> Ecto.Multi.update(
              :delivery,
              Projector.update_projections(delivery, event_for_projection)
              |> Ecto.Changeset.change(%{
                status: :sent,
                last_event_type: :dispatched,
                provider_message_id: provider_message_id,
                dispatched_at: event_occurred_at
              }),
              Repo.multi_opts()
            )
            |> Events.append_multi(:event_dispatched, event_attrs)
          )
        end
      )

    normalize_multi_result(result)
  end

  def enqueue_oban(%Message{} = rendered, adapter_ref) do
    idempotency_key = idempotency_key(rendered)
    tenant_id = rendered.tenant_id

    result =
      rendered
      |> queued_multi(idempotency_key, base_delivery_attrs(rendered, idempotency_key, adapter_ref))
      |> Mailglass.OptionalDeps.Oban.insert(:job, fn %{delivery: delivery} ->
        Mailglass.Outbound.Worker.new(%{
          "delivery_id" => delivery.id,
          "mailglass_tenant_id" => tenant_id
        })
      end)
      |> Repo.multi()

    queued_result(result)
  end

  def persist_task_queued(%Message{} = rendered, adapter_ref) do
    idempotency_key = idempotency_key(rendered)

    rendered
    |> queued_multi(idempotency_key, base_delivery_attrs(rendered, idempotency_key, adapter_ref))
    |> Repo.multi()
    |> queued_result()
  end

  def insert_batch([], _dispatch_mode), do: {:ok, [], :oban}

  def insert_batch(messages_with_refs, dispatch_mode) when is_list(messages_with_refs) do
    now = Clock.utc_now()

    rows =
      Enum.map(messages_with_refs, fn {%Message{} = message, adapter_ref} ->
        idempotency_key = idempotency_key(message)

        base_delivery_attrs(message, idempotency_key, adapter_ref)
        |> Map.put(:id, Preflight.delivery_id!(message))
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
      end)

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.insert_all(
        :deliveries,
        Delivery,
        rows,
        Repo.multi_opts(
          on_conflict: :nothing,
          conflict_target:
            {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"},
          returning: true
        )
      )
      |> Ecto.Multi.run(:events, fn repo, %{deliveries: {_count, inserted}} ->
        event_rows =
          Enum.map(inserted, fn delivery ->
            %{
              id: Ecto.UUID.generate(),
              tenant_id: delivery.tenant_id,
              delivery_id: delivery.id,
              type: :queued,
              occurred_at: now,
              idempotency_key: delivery.idempotency_key,
              normalized_payload: %{},
              metadata: %{},
              needs_reconciliation: false,
              inserted_at: now
            }
          end)

        {count, _} =
          repo.insert_all(
            Events.Event,
            event_rows,
            Repo.multi_opts(
              on_conflict: :nothing,
              conflict_target:
                {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"},
              returning: false
            )
          )

        {:ok, count}
      end)
      |> maybe_insert_batch_jobs(dispatch_mode)
      |> Repo.multi()

    case result do
      {:ok, %{deliveries: {_count, _inserted_rows}}} ->
        {:ok, fetch_batch_rows(rows), dispatch_mode}

      {:error, _step, error, _changes} ->
        {:error, normalize_error(error)}
    end
  end

  def persist_failed_by_id(delivery_id, %{__exception__: true} = error) do
    case fetch_delivery(delivery_id) do
      {:ok, delivery} -> persist_failed(delivery, error)
      {:error, _} -> missing_delivery_error(delivery_id)
    end
  end

  def fetch_delivery(id) do
    import Ecto.Query

    query = from(delivery in Delivery, where: delivery.id == ^id, limit: 1)

    case Repo.one(Tenancy.scope(query)) do
      nil ->
        {:error,
         Mailglass.SendError.new(:adapter_failure,
           context: %{reason_class: :delivery_not_found}
         )}

      %Delivery{} = delivery ->
        {:ok, delivery}
    end
  end

  def rehydrate_message(%Delivery{} = delivery) do
    case delivery.mailable do
      nil ->
        unresolvable_mailable(delivery, :nil_mailable)

      module_name when is_binary(module_name) ->
        resolve_mailable(delivery, module_name)
    end
  end

  def build_failed_delivery(%Message{} = message, error) do
    %Delivery{
      id: Ecto.UUID.generate(),
      tenant_id: message.tenant_id,
      mailable: inspect(message.mailable),
      stream: message.stream,
      recipient: Preflight.primary_recipient(message),
      status: :failed,
      last_event_type: :failed,
      last_error: serialize_error(error),
      last_event_at: Clock.utc_now(),
      metadata: %{}
    }
  end

  defp base_delivery_attrs(%Message{} = rendered, idempotency_key, adapter_ref) do
    %{
      tenant_id: rendered.tenant_id,
      mailable: inspect(rendered.mailable),
      stream: rendered.stream,
      recipient: Preflight.primary_recipient(rendered),
      recipient_domain: recipient_domain(rendered),
      adapter_ref: adapter_ref,
      status: :queued,
      last_event_type: :queued,
      last_event_at: Clock.utc_now(),
      metadata:
        Map.merge(rendered.metadata || %{}, %{
          rendered_html: rendered.swoosh_email.html_body,
          rendered_text: rendered.swoosh_email.text_body,
          subject: rendered.swoosh_email.subject,
          headers: rendered.swoosh_email.headers || %{}
        }),
      idempotency_key: idempotency_key
    }
  end

  defp idempotency_key(%Message{} = message) do
    content_hash =
      :crypto.hash(:sha256, [
        message.swoosh_email.text_body || "",
        message.swoosh_email.html_body || ""
      ])
      |> Base.encode16(case: :lower)

    :crypto.hash(:sha256, [
      message.tenant_id || "",
      "|",
      inspect(message.mailable),
      "|",
      Preflight.primary_recipient(message),
      "|",
      content_hash
    ])
    |> Base.encode16(case: :lower)
  end

  defp queued_multi(rendered, idempotency_key, attrs) do
    tenant_id = rendered.tenant_id

    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :delivery,
      Delivery.changeset(%Delivery{id: Preflight.delivery_id!(rendered)}, attrs),
      Repo.multi_opts()
    )
    |> Events.append_multi(:event_queued, fn %{delivery: delivery} ->
      %{
        tenant_id: tenant_id,
        delivery_id: delivery.id,
        type: :queued,
        occurred_at: Clock.utc_now(),
        idempotency_key: idempotency_key,
        normalized_payload: %{}
      }
    end)
  end

  defp queued_result({:ok, %{delivery: delivery}}) do
    {:ok, %{delivery | status: :queued, last_event_type: :queued}}
  end

  defp queued_result({:error, _step, error, _changes}), do: {:error, normalize_error(error)}

  defp normalize_multi_result({:ok, _changes} = result), do: result

  defp normalize_multi_result({:error, _step, error, _changes}),
    do: {:error, normalize_error(error)}

  defp fetch_batch_rows(rows) do
    import Ecto.Query

    idempotency_keys = Enum.map(rows, & &1.idempotency_key) |> Enum.reject(&is_nil/1)

    all_rows =
      if idempotency_keys == [] do
        []
      else
        query = from(delivery in Delivery, where: delivery.idempotency_key in ^idempotency_keys)
        Repo.all(Tenancy.scope(query))
      end

    rows_by_idempotency_key = Map.new(all_rows, &{&1.idempotency_key, &1})
    Enum.map(rows, &Map.fetch!(rows_by_idempotency_key, &1.idempotency_key))
  end

  defp maybe_insert_batch_jobs(multi, :oban) do
    Mailglass.OptionalDeps.Oban.insert_all(multi, :jobs, fn %{deliveries: {_count, inserted}} ->
      Enum.map(inserted, fn %Delivery{id: id, tenant_id: tenant_id} ->
        Mailglass.Outbound.Worker.new(%{
          "delivery_id" => id,
          "mailglass_tenant_id" => tenant_id
        })
      end)
    end)
  end

  defp maybe_insert_batch_jobs(multi, :task_supervisor), do: multi

  defp persist_failed(%Delivery{} = delivery, error) do
    event_occurred_at = Clock.utc_now()

    event = %Events.Event{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      type: :failed,
      occurred_at: event_occurred_at
    }

    case Repo.multi(
           Ecto.Multi.new()
           |> Ecto.Multi.update(
             :delivery,
             Projector.update_projections(delivery, event)
             |> Ecto.Changeset.change(%{
               status: :failed,
               last_error: serialize_error(error)
             }),
             Repo.multi_opts()
           )
           |> Events.append_multi(:event_failed, %{
             tenant_id: delivery.tenant_id,
             delivery_id: delivery.id,
             type: :failed,
             occurred_at: event_occurred_at,
             normalized_payload: %{error_type: error.__struct__}
           })
         ) do
      {:ok, %{delivery: updated}} -> {:ok, updated}
      {:error, _step, persist_error, _changes} -> {:error, normalize_error(persist_error)}
    end
  end

  defp missing_delivery_error(delivery_id) do
    require Logger
    Logger.warning("[mailglass] persist_failed_by_id: delivery #{delivery_id} not found")

    {:error,
     Mailglass.SendError.new(:dispatch_unavailable,
       retry_class: :transient,
       context: %{reason_class: :delivery_not_found},
       delivery_id: delivery_id
     )}
  end

  defp serialize_error(%{__exception__: true, __struct__: module} = error) do
    base = %{module: Atom.to_string(module), message: Exception.message(error)}

    case error do
      %{type: type} when is_atom(type) -> Map.put(base, :type, type)
      _ -> base
    end
  end

  defp resolve_mailable(delivery, module_name) do
    case existing_module("Elixir." <> module_name) do
      {:ok, module} ->
        if Code.ensure_loaded?(module) do
          {:ok, build_rehydrated_message(delivery, module)}
        else
          case existing_module(module_name) do
            {:ok, fallback} -> {:ok, build_rehydrated_message(delivery, fallback)}
            {:error, :missing} -> unresolvable_mailable(delivery, module_name, :module_not_loaded)
          end
        end

      {:error, :missing} ->
        case existing_module(module_name) do
          {:ok, module} -> {:ok, build_rehydrated_message(delivery, module)}
          {:error, :missing} -> unresolvable_mailable(delivery, module_name, :atom_not_found)
        end
    end
  end

  defp existing_module(module_name) do
    {:ok, String.to_existing_atom(module_name)}
  rescue
    ArgumentError -> {:error, :missing}
  end

  defp build_rehydrated_message(%Delivery{} = delivery, module) do
    metadata = rehydrated_metadata(delivery.metadata || %{})

    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to(delivery.recipient)
      |> Swoosh.Email.subject(get_in(delivery.metadata, ["subject"]) || "")
      |> Swoosh.Email.html_body(get_in(delivery.metadata, ["rendered_html"]))
      |> Swoosh.Email.text_body(get_in(delivery.metadata, ["rendered_text"]))
      |> put_rehydrated_headers(Map.get(delivery.metadata || %{}, "headers", %{}))

    %Message{
      swoosh_email: email,
      mailable: module,
      tenant_id: delivery.tenant_id,
      stream: delivery.stream,
      metadata: metadata
    }
  end

  defp unresolvable_mailable(delivery, reason) do
    {:error,
     Mailglass.SendError.new(:adapter_failure,
       context: %{
         reason_class: :mailable_unresolvable,
         delivery_id: delivery.id,
         why: reason
       }
     )}
  end

  defp unresolvable_mailable(delivery, module_name, reason) do
    {:error,
     Mailglass.SendError.new(:adapter_failure,
       context: %{
         reason_class: :mailable_unresolvable,
         delivery_id: delivery.id,
         mailable: module_name,
         why: reason
       }
     )}
  end

  defp rehydrated_metadata(metadata) when is_map(metadata) do
    case Map.get(metadata, "delivery_id") do
      delivery_id when is_binary(delivery_id) -> Map.put_new(metadata, :delivery_id, delivery_id)
      _ -> metadata
    end
  end

  defp put_rehydrated_headers(%Swoosh.Email{} = email, headers)
       when is_map(headers) or is_list(headers) do
    Enum.reduce(headers, email, fn {key, value}, acc ->
      Swoosh.Email.header(acc, key, value)
    end)
  end

  defp put_rehydrated_headers(%Swoosh.Email{} = email, _headers), do: email

  defp normalize_error(%{__exception__: true} = error), do: error

  defp normalize_error(%Ecto.Changeset{} = changeset) do
    Mailglass.SendError.new(:adapter_failure,
      context: %{reason_class: :persistence_failed, changeset: inspect(changeset.errors)}
    )
  end

  defp normalize_error(other) do
    Mailglass.SendError.new(:adapter_failure, context: %{wrapped: inspect(other)})
  end

  defp recipient_domain(message) do
    case String.split(Preflight.primary_recipient(message), "@", parts: 2) do
      [_, domain] -> String.downcase(domain)
      _ -> ""
    end
  end
end
