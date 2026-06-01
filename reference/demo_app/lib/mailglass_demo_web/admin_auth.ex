defmodule MailglassDemoWeb.AdminAuth do
  @behaviour MailglassAdmin.Auth

  @impl true
  def authorize(:operator_access, %{actor: %{subject_id: subject_id}}) when is_binary(subject_id) do
    {:ok, %{subject_id: subject_id, role: :support_lead}}
  end

  def authorize(:replay_webhook, %{actor: %{subject_id: subject_id}}) when is_binary(subject_id) do
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
