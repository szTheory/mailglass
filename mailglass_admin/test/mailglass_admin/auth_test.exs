defmodule MailglassAdmin.AuthTest do
  use ExUnit.Case, async: true

  alias MailglassAdmin.Auth

  test "normalizes authorized actor metadata" do
    recent_auth_at = DateTime.utc_now() |> DateTime.truncate(:second)

    assert {:ok, %{actor: actor, assigns: %{operator_access_checked?: true}}} =
             Auth.authorize(MailglassAdmin.TestOperatorAuth, :operator_access, %{
               actor: %{
                 subject_id: "operator-1",
                 tenant_id: "tenant-a",
                 recent_auth_at: recent_auth_at
               }
             })

    assert actor.subject_id == "operator-1"
    assert actor.tenant_id == "tenant-a"
    assert actor.recent_auth_at == recent_auth_at
  end

  test "returns unauthorized for missing operator access context" do
    assert {:error, :unauthorized, %{message: "Operator access requires a signed-in actor."}} =
             Auth.authorize(MailglassAdmin.TestOperatorAuth, :operator_access, %{
               actor: %{subject_id: nil}
             })
  end

  test "returns stale_auth for missing recent authentication" do
    assert {:error, :stale_auth, %{message: "Recent authentication is required."}} =
             Auth.authorize(MailglassAdmin.TestOperatorAuth, :destructive_action, %{
               actor: %{subject_id: "operator-1", recent_auth_at: nil}
             })
  end

  test "session_actor normalizes ISO8601 recent_auth_at" do
    recent_auth_at = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    actor =
      Auth.session_actor(%{
        "subject_id" => "operator-1",
        "recent_auth_at" => recent_auth_at
      })

    assert %DateTime{} = actor.recent_auth_at
  end
end
