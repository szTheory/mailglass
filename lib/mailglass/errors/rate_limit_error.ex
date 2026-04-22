defmodule Mailglass.RateLimitError do
  @moduledoc """
  Raised when a rate limit is exceeded.

  Rate-limit errors are always retryable — the caller should wait
  `:retry_after_ms` milliseconds before attempting the send again.

  ## Types

  - `:per_domain` — the recipient domain is over its rate limit
  - `:per_tenant` — the sending tenant is over its rate limit
  - `:per_stream` — the delivery stream (transactional / operational / bulk)
    is over its rate limit

  ## Per-kind Fields

  - `:retry_after_ms` — non-negative integer milliseconds the caller should
    wait before retrying. Defaults to `0` when the caller did not supply it.

  See `Mailglass.Error` for the shared contract and `docs/api_stability.md`
  for the locked `:type` atom set.
  """

  @behaviour Mailglass.Error

  @types [:per_domain, :per_tenant, :per_stream]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context, retry_after_ms: 0]

  @type t :: %__MODULE__{
          type: :per_domain | :per_tenant | :per_stream,
          message: String.t(),
          cause: Exception.t() | nil,
          context: %{atom() => term()},
          retry_after_ms: non_neg_integer()
        }

  @doc "Returns the closed set of valid `:type` atoms. Tested against `docs/api_stability.md`."
  @doc since: "0.1.0"
  @spec __types__() :: [atom()]
  def __types__, do: @types

  @impl Mailglass.Error
  def type(%__MODULE__{type: t}), do: t

  @impl Mailglass.Error
  def retryable?(%__MODULE__{}), do: true

  @impl true
  def message(%__MODULE__{type: type, context: ctx}) do
    format_message(type, ctx || %{})
  end

  @doc """
  Build a `Mailglass.RateLimitError` struct.

  ## Options

  - `:cause` — an underlying exception to wrap (kept out of JSON output).
  - `:context` — a map of non-PII metadata; `:retry_after_ms` is also read
    from context when formatting the message.
  - `:retry_after_ms` — milliseconds to wait before retrying. When provided,
    overrides the struct's default `0`.
  """
  @doc since: "0.1.0"
  @spec new(atom(), keyword()) :: t()
  def new(type, opts \\ []) when type in @types do
    ctx = opts[:context] || %{}

    %__MODULE__{
      type: type,
      message: format_message(type, ctx),
      cause: opts[:cause],
      context: ctx,
      retry_after_ms: opts[:retry_after_ms] || 0
    }
  end

  defp format_message(:per_domain, ctx) do
    ms = ctx[:retry_after_ms] || 0
    "Rate limit exceeded: retry after #{ms}ms"
  end

  defp format_message(:per_tenant, ctx) do
    ms = ctx[:retry_after_ms] || 0
    "Rate limit exceeded for tenant: retry after #{ms}ms"
  end

  defp format_message(:per_stream, ctx) do
    ms = ctx[:retry_after_ms] || 0
    "Rate limit exceeded for stream: retry after #{ms}ms"
  end
end
