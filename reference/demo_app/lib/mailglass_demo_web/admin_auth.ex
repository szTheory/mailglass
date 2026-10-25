defmodule MailglassDemoWeb.AdminAuth do
  @moduledoc """
  Demo policy for the mounted MailglassAdmin dashboard.

  This adapter grants every operator action to any logged-in demo operator so
  the demo can show each flow. It is not a recommended production policy. Real
  hosts decide each action themselves and deny by default, as the catch-all
  clause here does.
  """

  @behaviour MailglassAdmin.Auth

  @impl true
  def authorize(:operator_access, %{actor: %{subject_id: subject_id}}) when is_binary(subject_id) do
    {:ok, %{subject_id: subject_id, role: :support_lead}}
  end

  def authorize(:destructive_action, %{actor: %{subject_id: subject_id}}) when is_binary(subject_id) do
    {:ok, %{subject_id: subject_id, role: :support_lead}}
  end

  def authorize(:replay_inbound, %{actor: %{subject_id: subject_id}}) when is_binary(subject_id) do
    {:ok, %{subject_id: subject_id, role: :support_lead}}
  end

  def authorize(:reveal_raw, %{actor: %{subject_id: subject_id}}) when is_binary(subject_id) do
    {:ok, %{subject_id: subject_id, role: :support_lead}}
  end

  def authorize(_action, _context),
    do: {:error, :unauthorized, %{message: "demo operator login required"}}
end
