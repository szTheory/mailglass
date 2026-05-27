defmodule MailglassReferenceHostWeb.AdminAuth do
  @behaviour MailglassAdmin.Auth

  @impl true
  def authorize(:operator_access, %{actor: actor}) when is_map(actor) do
    case Map.get(actor, :subject_id) do
      nil ->
        {:error, :unauthorized, %{message: "operator subject is required"}}

      _subject_id ->
        {:ok, actor}
    end
  end

  def authorize(_action, _context) do
    {:error, :unauthorized, %{message: "operator access denied"}}
  end
end
