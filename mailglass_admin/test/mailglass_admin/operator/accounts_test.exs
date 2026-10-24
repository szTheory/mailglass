defmodule MailglassAdmin.Operator.AccountsTest do
  use ExUnit.Case, async: true

  alias MailglassAdmin.Operator.Accounts

  test "labels preserve account identity when configuration is absent or blank" do
    assert Accounts.normalize_labels(nil) == %{}
    assert Accounts.normalize_labels(:invalid) == %{}

    assert Accounts.normalize_labels(alpha: "  Acme  ", beta: " ", gamma: nil, delta: 42) ==
             %{"alpha" => "Acme", "beta" => "beta", "gamma" => "gamma", "delta" => "42"}

    assert Accounts.label("alpha", nil) == "alpha"
    assert Accounts.title("alpha", %{"alpha" => " Acme "}) == "Acme (tenant_id: alpha)"
    assert Accounts.title("unknown", []) == "unknown"

    for id <- [nil, ""] do
      assert Accounts.label(id, %{}) == ""
      assert Accounts.title(id, %{}) == ""
    end
  end

  test "selector drops unusable and duplicate IDs but retains the current account" do
    options = [
      %{id: "beta", label: "Beta"},
      %{id: "alpha", label: ""},
      %{id: "beta", label: "Duplicate"},
      %{id: " ", label: "Blank"},
      %{id: nil, label: "Missing"}
    ]

    assert Accounts.apply_labels(options, %{"alpha" => "Acme"}) ==
             [%{id: "alpha", label: "Acme"}, %{id: "beta", label: "Beta"}]

    assert Accounts.field_options(options, "hidden", %{"hidden" => "Current"}) ==
             [{"Current", "hidden"}, {"alpha", "alpha"}, {"Beta", "beta"}]

    assert Accounts.field_options([], nil, []) == []
    assert Accounts.field_options([], "", []) == []
    assert Accounts.field_options(options, "beta", []) == [{"alpha", "alpha"}, {"Beta", "beta"}]
  end
end
