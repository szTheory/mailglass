defmodule MailglassInbound.InboundRecords.ReplayRun do
  @moduledoc """
  Append-only replay execution history row.

  Replay runs always point back to the original canonical inbound record and the
  stored evidence row they reprocessed, so they cannot be mistaken for a fresh
  provider receive.
  """

  use MailglassInbound.Schema

  import Ecto.Changeset

  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord

  @outcomes [:accept, :ignore, :reject, :bounce, :failed]

  @type outcome :: :accept | :ignore | :reject | :bounce | :failed

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          tenant_id: String.t() | nil,
          inbound_record_id: Ecto.UUID.t() | nil,
          inbound_evidence_id: Ecto.UUID.t() | nil,
          replay_id: String.t() | nil,
          mailbox: String.t() | nil,
          outcome: outcome() | nil,
          outcome_reason: String.t() | nil,
          failure: map(),
          executed_at: DateTime.t() | nil,
          metadata: map(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "mailglass_inbound_replay_runs" do
    field(:tenant_id, :string)
    field(:replay_id, :string)
    field(:mailbox, :string)
    field(:outcome, Ecto.Enum, values: @outcomes)
    field(:outcome_reason, :string)
    field(:failure, :map, default: %{})
    field(:executed_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})

    belongs_to(:inbound_record, InboundRecord)
    belongs_to(:inbound_evidence, InboundEvidence)

    timestamps()
  end

  @required ~w[tenant_id inbound_record_id inbound_evidence_id replay_id mailbox]a
  @cast @required ++ ~w[outcome outcome_reason failure executed_at metadata]a

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) when is_map(attrs) do
    attrs =
      attrs
      |> Map.put_new(:executed_at, DateTime.utc_now())
      |> Map.put_new(:failure, %{})
      |> Map.put_new(:metadata, %{})

    %__MODULE__{}
    |> cast(attrs, @cast)
    |> validate_required(@required)
    |> validate_outcome_shape()
    |> foreign_key_constraint(:inbound_record_id)
    |> foreign_key_constraint(:inbound_evidence_id)
  end

  @spec __outcomes__() :: nonempty_list(outcome())
  def __outcomes__, do: @outcomes

  defp validate_outcome_shape(changeset) do
    outcome = get_field(changeset, :outcome)
    failure = get_field(changeset, :failure) || %{}

    cond do
      outcome in [:accept, :ignore] and map_size(failure) == 0 ->
        changeset

      outcome in [:reject, :bounce] and present_string?(get_field(changeset, :outcome_reason)) and
          map_size(failure) == 0 ->
        changeset

      outcome == :failed and map_size(failure) > 0 ->
        changeset

      true ->
        add_error(
          changeset,
          :outcome,
          "must be :accept, :ignore, {:reject, reason}, {:bounce, reason}, or :failed with failure metadata"
        )
    end
  end

  defp present_string?(value), do: is_binary(value) and String.trim(value) != ""
end
