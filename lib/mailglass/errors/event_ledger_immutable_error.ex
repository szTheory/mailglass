defmodule Mailglass.EventLedgerImmutableError do
  @moduledoc """
  Raised when the `mailglass_events` append-only immutability trigger fires.

  The event ledger is append-only by design (D-15 project-level, D-06 phase-level).
  A Postgres `BEFORE UPDATE OR DELETE` trigger on `mailglass_events` raises
  `SQLSTATE 45A01` for every mutation attempt. `Mailglass.Repo.transact/1`
  translates that `%Postgrex.Error{}` into this struct so callers pattern-match
  a mailglass-owned error, never the raw Postgrex one.

  ## Types

  - `:update_attempt` — an UPDATE statement hit the trigger
  - `:delete_attempt` — a DELETE statement hit the trigger

  Never retryable — an immutability violation is a bug in the calling code.

  See `Mailglass.Error` for the shared contract and `docs/api_stability.md`
  for the locked `:type` atom set.
  """

  @behaviour Mailglass.Error

  @types [:update_attempt, :delete_attempt]

  @derive {Jason.Encoder, only: [:type, :message, :context, :pg_code]}
  defexception [:type, :message, :cause, :context, pg_code: "45A01"]

  @type t :: %__MODULE__{
          type: :update_attempt | :delete_attempt,
          message: String.t(),
          cause: Exception.t() | nil,
          context: %{atom() => term()},
          pg_code: String.t()
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
  Build a `Mailglass.EventLedgerImmutableError` struct.

  ## Options

  - `:cause` — the underlying `%Postgrex.Error{}` (kept out of JSON output).
  - `:context` — a map of non-PII metadata. `:pg_code` is propagated into
    the `:pg_code` struct field.
  - `:pg_code` — the SQLSTATE code; defaults to `"45A01"`.
  """
  @doc since: "0.1.0"
  @spec new(atom(), keyword()) :: t()
  def new(type, opts \\ []) when type in @types do
    ctx = opts[:context] || %{}
    pg_code = opts[:pg_code] || "45A01"

    %__MODULE__{
      type: type,
      message: format_message(type, ctx),
      cause: opts[:cause],
      context: ctx,
      pg_code: pg_code
    }
  end

  defp format_message(:update_attempt, _ctx),
    do: "Event ledger is append-only: UPDATE attempted on mailglass_events (SQLSTATE 45A01)"

  defp format_message(:delete_attempt, _ctx),
    do: "Event ledger is append-only: DELETE attempted on mailglass_events (SQLSTATE 45A01)"
end
