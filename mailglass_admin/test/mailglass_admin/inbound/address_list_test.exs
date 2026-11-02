defmodule MailglassAdmin.Inbound.AddressListTest do
  use ExUnit.Case, async: true

  alias MailglassAdmin.Inbound.AddressList

  @moduletag :phase176

  defp addr(address, name \\ nil), do: %{address: address, name: name}

  describe "entries/1" do
    test "nil and [] yield no entries" do
      assert AddressList.entries(nil) == []
      assert AddressList.entries([]) == []
    end

    test "one address yields one address entry" do
      assert [%{kind: :address, address: "a@example.com", name: nil, spoof?: false}] =
               AddressList.entries([addr("a@example.com")])
    end

    test "reads atom keys, JSONB string keys and bare strings" do
      entries =
        AddressList.entries([
          %{address: "a@example.com", name: "A"},
          %{"address" => "b@example.com", "name" => "B"},
          "c@example.com"
        ])

      assert Enum.map(entries, &{&1.address, &1.name}) ==
               [{"a@example.com", "A"}, {"b@example.com", "B"}, {"c@example.com", nil}]
    end

    test "exact duplicates collapse; the domain is case-insensitive" do
      entries =
        AddressList.entries([
          addr("a@example.com"),
          addr("a@EXAMPLE.com"),
          addr("a@example.com")
        ])

      assert [%{address: "a@example.com"}] = entries
    end

    test "the local part is case-sensitive, so these stay distinct" do
      assert [_, _] = AddressList.entries([addr("User@x.example"), addr("user@x.example")])
    end

    test "header order is preserved and the first duplicate wins" do
      entries =
        AddressList.entries([addr("z@example.com"), addr("a@example.com"), addr("z@EXAMPLE.com")])

      assert Enum.map(entries, & &1.address) == ["z@example.com", "a@example.com"]
    end

    test "names are dropped when blank or equal to the address" do
      assert [%{name: nil}, %{name: nil}, %{name: "Ada"}] =
               AddressList.entries([
                 addr("a@example.com", "   "),
                 addr("b@example.com", "b@example.com"),
                 addr("c@example.com", "Ada")
               ])
    end

    test "a display name embedding a different address is flagged as spoofed" do
      assert [%{spoof?: true, name: "billing@paypal.example", address: "sender@mailer.example"}] =
               AddressList.entries([addr("sender@mailer.example", "billing@paypal.example")])
    end

    test "a display name embedding the same address is not spoofed" do
      assert [%{spoof?: false, name: "Sender <sender@MAILER.example>"}] =
               AddressList.entries([
                 addr("sender@mailer.example", "Sender <sender@MAILER.example>")
               ])
    end

    test "a name with a bare @ and no address-like token is not spoofed" do
      assert [%{spoof?: false}] = AddressList.entries([addr("a@example.com", "Ops @ Example")])
    end

    test "entries without a usable addr-spec are unparseable and keep the original" do
      entries =
        AddressList.entries([
          "not an address",
          %{"address" => "two@@example.com"},
          %{address: "@example.com"},
          %{address: "local@"},
          %{"display" => "no address key"}
        ])

      assert Enum.all?(entries, &(&1.kind == :unparseable))

      assert Enum.map(entries, & &1.original) ==
               ["not an address", "two@@example.com", "@example.com", "local@", nil]
    end

    test "Unicode addresses and long values are kept as stored" do
      long_local = String.duplicate("l", 70)
      long_domain = String.duplicate("d", 210) <> ".example"

      assert [%{address: "用户@例子.广告"}, %{address: long}] =
               AddressList.entries([addr("用户@例子.广告"), addr("#{long_local}@#{long_domain}")])

      assert long == "#{long_local}@#{long_domain}"
    end
  end

  describe "split/2" do
    test "more than the limit splits head and rest" do
      entries = for n <- 1..7, do: %{address: "u#{n}@example.com"}
      assert {head, rest} = AddressList.split(entries)
      assert {length(head), length(rest)} == {5, 2}
    end

    test "exactly the limit has no rest" do
      entries = for n <- 1..5, do: %{address: "u#{n}@example.com"}
      assert {head, []} = AddressList.split(entries)
      assert length(head) == 5
    end
  end
end
