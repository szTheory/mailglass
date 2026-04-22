defmodule Mailglass.ConfigError do
  @moduledoc """
  Raised when mailglass is misconfigured.

  Configuration errors are never retryable — the host application must
  fix the configuration and restart. `Mailglass.Config.validate_at_boot!/0`
  (lands in Plan 03) raises this at application startup.

  ## Types

  - `:missing` — a required configuration key is not set
  - `:invalid` — a key is present but the value is invalid
  - `:conflicting` — two or more keys contradict each other
  - `:optional_dep_missing` — an optional dependency is required for the
    selected configuration but is not loaded

  See `Mailglass.Error` for the shared contract and `docs/api_stability.md`
  for the locked `:type` atom set.
  """

  @behaviour Mailglass.Error

  @types [:missing, :invalid, :conflicting, :optional_dep_missing]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context]

  @type t :: %__MODULE__{
          type: :missing | :invalid | :conflicting | :optional_dep_missing,
          message: String.t(),
          cause: Exception.t() | nil,
          context: %{atom() => term()}
        }

  @doc "Returns the closed set of valid `:type` atoms. Tested against `docs/api_stability.md`."
  @doc since: "0.1.0"
  @spec __types__() :: [atom()]
  def __types__, do: @types

  @impl Mailglass.Error
  def type(%__MODULE__{type: t}), do: t

  @impl Mailglass.Error
  def retryable?(%__MODULE__{}), do: false

  @impl true
  def message(%__MODULE__{type: type, context: ctx}) do
    format_message(type, ctx || %{})
  end

  @doc """
  Build a `Mailglass.ConfigError` struct.

  ## Options

  - `:cause` — an underlying exception to wrap (kept out of JSON output).
  - `:context` — a map of non-PII metadata; `:key` is used for `:missing` /
    `:invalid` messages, `:dep` for `:optional_dep_missing`.
  """
  @doc since: "0.1.0"
  @spec new(atom(), keyword()) :: t()
  def new(type, opts \\ []) when type in @types do
    ctx = opts[:context] || %{}

    %__MODULE__{
      type: type,
      message: format_message(type, ctx),
      cause: opts[:cause],
      context: ctx
    }
  end

  defp format_message(:missing, ctx) do
    key = ctx[:key] || "unknown"
    "Configuration error: required key :#{key} is not set"
  end

  defp format_message(:invalid, ctx) do
    key = ctx[:key] || "unknown"
    "Configuration error: invalid value for :#{key}"
  end

  defp format_message(:conflicting, _ctx), do: "Configuration error: conflicting options"

  defp format_message(:optional_dep_missing, ctx) do
    dep = ctx[:dep] || "unknown"
    "Configuration error: optional dependency #{dep} is not loaded"
  end
end
