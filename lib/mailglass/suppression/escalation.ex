if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Suppression.Escalation do
    @moduledoc """
    Oban worker for async soft-bounce escalation.
    """

    use Oban.Worker,
      queue: :mailglass_suppression_escalation,
      max_attempts: 5,
      unique: [
        period: 300,
        fields: [:args],
        keys: [:recipient, :mailglass_tenant_id]
      ]

    import Ecto.Query

    alias Mailglass.{Clock, Config, Repo, Tenancy}
    alias Mailglass.Events.Event
    alias Mailglass.Outbound.Delivery
    alias Mailglass.Suppression.Entry

    @default_threshold 5
    @default_window_days 7
    @default_action :hard_suppress
    @source "webhook:soft_bounce_escalation"
    @conflict_target {:unsafe_fragment, "(tenant_id, address, scope, COALESCE(stream, ''))"}

    @type action :: :hard_suppress | {:suppress_for, [days: pos_integer()]}

    @doc since: "0.1.0"
    @spec available?() :: true
    def available?, do: true

    @doc """
    Enqueues a soft-bounce escalation job through the optional-dep gateway.
    """
    @doc since: "0.1.0"
    @spec enqueue(Ecto.Multi.t(), map()) :: Ecto.Multi.t()
    def enqueue(multi, %{tenant_id: tenant_id, recipient: recipient})
        when is_binary(tenant_id) and is_binary(recipient) do
      Mailglass.OptionalDeps.Oban.insert(multi, :soft_bounce_escalation, fn _changes ->
        new(%{
          "recipient" => String.downcase(recipient),
          "mailglass_tenant_id" => tenant_id
        })
      end)
    end

    @doc """
    Evaluates whether recent deferred events warrant suppression.
    """
    @doc since: "0.1.0"
    @spec evaluate(String.t(), String.t(), keyword()) ::
            {:ok, Entry.t() | :below_threshold}
            | {:error, Ecto.Changeset.t() | term()}
    def evaluate(tenant_id, recipient, opts \\ [])
        when is_binary(tenant_id) and is_binary(recipient) and is_list(opts) do
      threshold = Keyword.get(opts, :threshold, threshold())
      window_days = Keyword.get(opts, :window_days, window_days())
      action = Keyword.get(opts, :action, action())
      recipient = String.downcase(recipient)

      if deferred_count(tenant_id, recipient, window_days) < threshold do
        {:ok, :below_threshold}
      else
        attrs = suppression_attrs(tenant_id, recipient, threshold, window_days, action)
        insert_suppression(attrs)
      end
    end

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"recipient" => recipient}} = job) when is_binary(recipient) do
      Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
        tenant_id = Map.fetch!(job.args, "mailglass_tenant_id")

        case evaluate(tenant_id, recipient) do
          {:ok, _result} -> :ok
          {:error, reason} -> {:error, reason}
        end
      end)
    end

    defp deferred_count(tenant_id, recipient, window_days) do
      cutoff = DateTime.add(Clock.utc_now(), -window_days * 24 * 60 * 60, :second)

      query =
        from(event in Event,
          join: delivery in Delivery,
          on: delivery.id == event.delivery_id,
          where: event.tenant_id == ^tenant_id,
          where: delivery.tenant_id == ^tenant_id,
          where: delivery.recipient == ^recipient,
          where: event.type == :deferred,
          where: event.occurred_at >= ^cutoff,
          select: count(event.id)
        )

      query
      |> Tenancy.scope(tenant_id)
      |> Repo.one()
      |> Kernel.||(0)
    end

    defp suppression_attrs(tenant_id, recipient, threshold, window_days, action) do
      %{
        tenant_id: tenant_id,
        address: recipient,
        scope: :address,
        reason: :hard_bounce,
        source: @source,
        expires_at: expires_at_for(action),
        metadata: %{
          "action" => action_name(action),
          "threshold" => threshold,
          "window_days" => window_days
        }
      }
    end

    defp insert_suppression(attrs) do
      changeset = Entry.changeset(attrs)

      case Repo.insert(changeset,
             on_conflict: :nothing,
             conflict_target: @conflict_target,
             returning: true,
             prefix: Config.schema()
           ) do
        {:ok, %Entry{id: nil}} ->
          {:ok, fetch_existing!(attrs.tenant_id, attrs.address)}

        {:ok, %Entry{} = entry} ->
          {:ok, entry}

        {:error, reason} ->
          {:error, reason}
      end
    end

    defp fetch_existing!(tenant_id, address) do
      query =
        from(entry in Entry,
          where: entry.tenant_id == ^tenant_id,
          where: entry.address == ^address,
          where: entry.source == ^@source,
          limit: 1
        )

      query
      |> Tenancy.scope(tenant_id)
      |> Repo.one()
      |> case do
        %Entry{} = entry -> entry
        nil -> raise "expected escalation suppression row to exist after conflict"
      end
    end

    defp threshold do
      Keyword.get(config(), :threshold, @default_threshold)
    end

    defp window_days do
      Keyword.get(config(), :window_days, @default_window_days)
    end

    defp action do
      case Keyword.get(config(), :action, @default_action) do
        :hard_suppress ->
          :hard_suppress

        {:suppress_for, action_opts} when is_list(action_opts) ->
          days = Keyword.get(action_opts, :days)

          if is_integer(days) and days > 0 do
            {:suppress_for, days: days}
          else
            @default_action
          end

        _ ->
          @default_action
      end
    end

    defp config do
      Application.get_env(:mailglass, :soft_bounce_escalation, [])
    end

    defp expires_at_for(:hard_suppress), do: nil

    defp expires_at_for({:suppress_for, days: days}) do
      DateTime.add(Clock.utc_now(), days * 24 * 60 * 60, :second)
    end

    defp action_name(:hard_suppress), do: "hard_suppress"
    defp action_name({:suppress_for, days: days}), do: "suppress_for:#{days}"
  end
end
