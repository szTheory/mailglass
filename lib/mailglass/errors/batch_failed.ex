defmodule Mailglass.Error.BatchFailed do
  @moduledoc """
  Raised by `Mailglass.Outbound.deliver_many!/2` when one or more
  deliveries in the batch have `status: :failed`.

  Never raised by `deliver_many/2` — that variant returns
  `{:ok, [%Delivery{}]}` where each delivery carries its own
  `:status` and `:last_error`. The bang variant is opt-in for callers
  who prefer exceptions.

  ## Types

  - `:partial_failure` — at least one Delivery succeeded AND at least one failed
  - `:all_failed` — every Delivery failed

  ## Fields

  - `:failures` — list of `%Mailglass.Outbound.Delivery{}` rows with `status: :failed`.
    Successful rows are NOT included (caller can retrieve them via `deliver_many/2`
    directly if needed).
  """

  @behaviour Mailglass.Error

  @types [:partial_failure, :all_failed]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context, failures: []]

  @type t :: %__MODULE__{
          type: :partial_failure | :all_failed,
          message: String.t(),
          cause: Exception.t() | nil,
          context: %{atom() => term()},
          failures: [Mailglass.Outbound.Delivery.t()]
        }

  @doc "Returns the closed set of valid `:type` atoms."
  @doc since: "0.1.0"
  @spec __types__() :: [atom()]
  def __types__, do: @types

  @impl Mailglass.Error
  def type(%__MODULE__{type: t}), do: t

  @impl Mailglass.Error
  def retryable?(%__MODULE__{}), do: true

  @impl true
  def message(%__MODULE__{type: type, context: ctx}), do: format_message(type, ctx || %{})

  @doc """
  Build a `Mailglass.Error.BatchFailed` struct.

  ## Options

  - `:cause` — an underlying exception to wrap (kept out of JSON output).
  - `:context` — a map of non-PII metadata; `:count` = total deliveries attempted,
    `:failed_count` = number that failed.
  - `:failures` — list of `%Mailglass.Outbound.Delivery{}` rows that failed.
  """
  @doc since: "0.1.0"
  @spec new(atom(), keyword()) :: t()
  def new(type, opts \\ []) when type in @types do
    ctx = opts[:context] || %{}
    failures = opts[:failures] || []

    %__MODULE__{
      type: type,
      message: format_message(type, ctx),
      cause: opts[:cause],
      context: ctx,
      failures: failures
    }
  end

  defp format_message(:partial_failure, ctx) do
    failed = length(ctx[:failures] || []) |> then(fn 0 -> ctx[:failed_count] || "some" end)
    total = ctx[:count] || "the"
    "Batch send partially failed: #{failed} of #{total} deliveries failed"
  end

  defp format_message(:all_failed, ctx) do
    total = ctx[:count] || "all"
    "Batch send failed: all #{total} deliveries failed"
  end
end
