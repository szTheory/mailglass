defmodule MailglassInbound.InboundRecords do
  @moduledoc """
  Package-local persistence boundary for canonical inbound rows, raw evidence,
  and execution lineage.
  """

  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
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

  @spec change_execution_run(map()) :: Ecto.Changeset.t()
  def change_execution_run(attrs \\ %{}) when is_map(attrs) do
    attrs
    |> normalize_execution_attrs()
    |> ExecutionRun.changeset()
  end

  @spec insert_execution_run(map(), keyword()) ::
          {:ok, ExecutionRun.t()} | {:error, Ecto.Changeset.t()}
  def insert_execution_run(attrs, opts \\ []) when is_map(attrs) and is_list(opts) do
    attrs
    |> normalize_execution_attrs()
    |> ExecutionRun.changeset()
    |> Repo.insert(opts)
  end

  @spec change_replay_run(map()) :: Ecto.Changeset.t()
  def change_replay_run(attrs \\ %{}) when is_map(attrs) do
    attrs
    |> ensure_replay_source()
    |> change_execution_run()
  end

  @spec insert_replay_run(map(), keyword()) ::
          {:ok, ExecutionRun.t()} | {:error, Ecto.Changeset.t()}
  def insert_replay_run(attrs, opts \\ []) when is_map(attrs) and is_list(opts) do
    attrs
    |> ensure_replay_source()
    |> insert_execution_run(opts)
  end

  defp normalize_execution_attrs(attrs) do
    execution_failure = Map.get(attrs, :execution_failure)
    mailbox_outcome = Map.get(attrs, :mailbox_outcome)
    attrs = move_replay_id_to_metadata(attrs)

    cond do
      is_map(execution_failure) and execution_failure != %{} ->
        attrs
        |> Map.put(:outcome, :failed)
        |> Map.put(:failure, execution_failure)

      mailbox_outcome == :no_match ->
        attrs
        |> Map.put(:outcome, :no_match)
        |> Map.put(:mailbox, nil)
        |> Map.put_new(:failure, %{})

      mailbox_outcome in [:accept, :ignore] ->
        attrs
        |> Map.put(:outcome, mailbox_outcome)
        |> Map.put_new(:failure, %{})

      match?({outcome, _reason} when outcome in [:reject, :bounce], mailbox_outcome) ->
        {outcome, reason} = mailbox_outcome

        attrs
        |> Map.put(:outcome, outcome)
        |> Map.put(:outcome_reason, format_reason(reason))
        |> Map.put_new(:failure, %{})

      true ->
        attrs
    end
  end

  defp ensure_replay_source(attrs) do
    Map.put_new(attrs, :source, :replay)
  end

  defp move_replay_id_to_metadata(attrs) do
    replay_id = Map.get(attrs, :replay_id) || Map.get(attrs, "replay_id")

    if is_binary(replay_id) and replay_id != "" do
      metadata =
        attrs
        |> Map.get(:metadata, %{})
        |> Map.put_new(:replay_id, replay_id)

      attrs
      |> Map.put(:metadata, metadata)
      |> Map.delete(:replay_id)
      |> Map.delete("replay_id")
    else
      attrs
    end
  end

  defp format_reason(reason) when is_binary(reason), do: reason
  defp format_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp format_reason(reason), do: inspect(reason)
end
