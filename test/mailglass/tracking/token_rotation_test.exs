defmodule Mailglass.Tracking.TokenRotationTest do
  use ExUnit.Case, async: false

  alias Mailglass.Tracking.Token

  @endpoint "mailglass-test-rotation-endpoint"

  setup do
    original = Application.get_env(:mailglass, :tracking)

    on_exit(fn ->
      if original do
        Application.put_env(:mailglass, :tracking, original)
      else
        Application.delete_env(:mailglass, :tracking)
      end
    end)

    :ok
  end

  # Test 7: Salts rotation — tokens signed with old salt still verify when old salt in list
  test "verify succeeds when signing salt is still in the salts list" do
    # Sign with config that has "q2-2026" as head
    Application.put_env(:mailglass, :tracking,
      salts: ["q2-2026", "q1-2026"],
      max_age: 86_400
    )

    token = Token.sign_open(@endpoint, "d-abc", "tenant-1")

    # Rotate: prepend new salt, "q2-2026" still present
    Application.put_env(:mailglass, :tracking,
      salts: ["q3-2026", "q2-2026"],
      max_age: 86_400
    )

    # Token signed with "q2-2026" should still verify (all salts are tried)
    assert {:ok, %{delivery_id: "d-abc", tenant_id: "tenant-1"}} =
             Token.verify_open(@endpoint, token)
  end

  # Test 8: Salts rotation — drop old salt causes verification failure
  test "verify fails when signing salt has been removed from the list" do
    # Sign with salts list containing "q2-2026" as head
    Application.put_env(:mailglass, :tracking,
      salts: ["q2-2026", "q1-2026"],
      max_age: 86_400
    )

    token = Token.sign_open(@endpoint, "d-abc", "tenant-1")

    # Completely rotate out "q2-2026"
    Application.put_env(:mailglass, :tracking,
      salts: ["q4-2026", "q3-2026"],
      max_age: 86_400
    )

    # Token signed with "q2-2026" should now fail (salt not in list)
    assert :error = Token.verify_open(@endpoint, token)
  end
end
