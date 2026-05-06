defmodule MailglassInbound.InboundRecords do
  @moduledoc """
  Package-local persistence boundary for canonical inbound rows, raw evidence,
  and replay lineage.
  """

  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.InboundRecords.ReplayRun
  alias MailglassInbound.Repo

  @spec change_inbound_record(map()) :: Ecto.Changeset.t()
  def change_inbound_record(attrs \\ %{}) when is_map(attrs) do
    InboundRecord.changeset(attrs)
  end

  @spec insert_inbound_record(map(), keyword()) ::
          {:ok, InboundRecord.t()} | {:error, Ecto.Changeset.t()}
  def insert_inbound_record(attrs, opts \\ []) when is_map(attrs) and is_list(opts) do
    attrs
    |> InboundRecord.changeset()
    |> Repo.insert(opts)
  end

  @spec change_inbound_evidence(map()) :: Ecto.Changeset.t()
  def change_inbound_evidence(attrs \\ %{}) when is_map(attrs) do
    InboundEvidence.changeset(attrs)
  end

  @spec insert_inbound_evidence(map(), keyword()) ::
          {:ok, InboundEvidence.t()} | {:error, Ecto.Changeset.t()}
  def insert_inbound_evidence(attrs, opts \\ []) when is_map(attrs) and is_list(opts) do
    attrs
    |> InboundEvidence.changeset()
    |> Repo.insert(opts)
  end

  @spec change_replay_run(map()) :: Ecto.Changeset.t()
  def change_replay_run(attrs \\ %{}) when is_map(attrs) do
    ReplayRun.changeset(attrs)
  end

  @spec insert_replay_run(map(), keyword()) ::
          {:ok, ReplayRun.t()} | {:error, Ecto.Changeset.t()}
  def insert_replay_run(attrs, opts \\ []) when is_map(attrs) and is_list(opts) do
    attrs
    |> ReplayRun.changeset()
    |> Repo.insert(opts)
  end
end
