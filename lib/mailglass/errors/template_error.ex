defmodule Mailglass.TemplateError do
  @moduledoc """
  Raised when a template cannot be compiled or rendered.

  ## Types

  - `:heex_compile` — HEEx compilation failed (syntax, unclosed tag, etc.)
  - `:missing_assign` — a required assign was not provided to `render/3`
  - `:helper_undefined` — a helper function referenced in the template is not defined
  - `:inliner_failed` — Premailex (or alternative CSS inliner) raised

  See `Mailglass.Error` for the shared contract and `docs/api_stability.md`
  for the locked `:type` atom set.
  """

  @behaviour Mailglass.Error

  @types [:heex_compile, :missing_assign, :helper_undefined, :inliner_failed]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context]

  @type t :: %__MODULE__{
          type: :heex_compile | :missing_assign | :helper_undefined | :inliner_failed,
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
  Build a `Mailglass.TemplateError` struct.

  ## Options

  - `:cause` — an underlying exception to wrap (kept out of JSON output).
  - `:context` — a map of non-PII metadata; `:assign` is used to fill in
    the missing-assign message.
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

  defp format_message(:heex_compile, _ctx), do: "Template error: HEEx compilation failed"

  defp format_message(:missing_assign, ctx) do
    name = ctx[:assign] || "unknown"
    "Template error: required assign @#{name} is missing"
  end

  defp format_message(:helper_undefined, _ctx), do: "Template error: helper function is not defined"
  defp format_message(:inliner_failed, _ctx), do: "Template error: CSS inlining failed"
end
