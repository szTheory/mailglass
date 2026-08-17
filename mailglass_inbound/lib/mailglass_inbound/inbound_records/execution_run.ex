defmodule MailglassInbound.InboundRecords.ExecutionRun do
  @moduledoc """
  Append-only execution lineage row shared by fresh ingress and replay.

  Execution runs always point back to the immutable canonical inbound record
  and stored evidence row they processed.
  """

  use MailglassInbound.Schema

  import Ecto.Changeset

  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord

  @sources [:fresh, :replay]
  @outcomes [:no_match, :accept, :ignore, :reject, :bounce, :failed]

  @type source :: :fresh | :replay
  @type outcome :: :no_match | :accept | :ignore | :reject | :bounce | :failed

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          tenant_id: String.t() | nil,
          inbound_record_id: Ecto.UUID.t() | nil,
          inbound_evidence_id: Ecto.UUID.t() | nil,
          source: source() | nil,
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
    field(:source, Ecto.Enum, values: @sources)
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

  @required ~w[tenant_id inbound_record_id inbound_evidence_id source]a
  @cast @required ++ ~w[mailbox outcome outcome_reason failure executed_at metadata]a

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

  @spec __sources__() :: [source()]
  def __sources__, do: @sources

  @spec __outcomes__() :: [outcome()]
  def __outcomes__, do: @outcomes

  defp validate_outcome_shape(changeset) do
    outcome = get_field(changeset, :outcome)
    failure = get_field(changeset, :failure) || %{}
    mailbox = get_field(changeset, :mailbox)

    cond do
      outcome == :no_match and is_nil(mailbox) and map_size(failure) == 0 ->
        changeset

      outcome in [:accept, :ignore] and present_string?(mailbox) and map_size(failure) == 0 ->
        changeset

      outcome in [:reject, :bounce] and present_string?(mailbox) and
        present_string?(get_field(changeset, :outcome_reason)) and map_size(failure) == 0 ->
        changeset

      outcome == :failed and map_size(failure) > 0 ->
        validate_failed_mailbox(changeset, mailbox)

      true ->
        add_error(
          changeset,
          :outcome,
          "must be :no_match, :accept, :ignore, {:reject, reason}, {:bounce, reason}, or :failed with failure metadata"
        )
    end
  end

  defp validate_failed_mailbox(changeset, mailbox) do
    outcome = get_field(changeset, :outcome)

    cond do
      outcome != :failed ->
        changeset

      is_nil(mailbox) ->
        changeset

      present_string?(mailbox) ->
        changeset

      true ->
        add_error(changeset, :mailbox, "must be nil or a non-empty mailbox identity")
    end
  end

  defp present_string?(value), do: is_binary(value) and String.trim(value) != ""
end
