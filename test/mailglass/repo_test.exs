defmodule Mailglass.RepoTest do
  use ExUnit.Case, async: false

  # CORE-04: `Mailglass.Repo.transact/1` delegates to the adopter-configured
  # Ecto.Repo resolved via `Application.get_env(:mailglass, :repo)`. Phase 1
  # lands only the facade (`transact/1` + `repo/0` resolver); the
  # SQLSTATE 45A01 immutability translation lands with the events ledger in
  # Phase 2.

  describe "transact/1 — :repo not configured" do
    setup do
      original = Application.get_env(:mailglass, :repo)
      Application.put_env(:mailglass, :repo, nil)
      on_exit(fn -> Application.put_env(:mailglass, :repo, original) end)
      :ok
    end

    test "raises ConfigError when :repo is not configured" do
      assert_raise Mailglass.ConfigError, fn ->
        Mailglass.Repo.transact(fn -> {:ok, :done} end)
      end
    end

    test "the raised ConfigError carries :missing type and :repo context" do
      err =
        try do
          Mailglass.Repo.transact(fn -> {:ok, :done} end)
        rescue
          e -> e
        end

      assert %Mailglass.ConfigError{type: :missing, context: %{key: :repo}} = err
    end
  end

  describe "transact/1 — :repo configured" do
    defmodule FakeRepo do
      @moduledoc false
      # Minimal in-memory stand-in for an Ecto.Repo. Phase 1 only exercises
      # the `transact/2` delegation contract; real transactions land in
      # Phase 2 against a live Postgres repo.
      def transact(fun, _opts) when is_function(fun, 0) do
        case fun.() do
          {:ok, _} = ok -> ok
          {:error, _} = err -> err
          other -> {:ok, other}
        end
      end
    end

    setup do
      original = Application.get_env(:mailglass, :repo)
      Application.put_env(:mailglass, :repo, __MODULE__.FakeRepo)
      on_exit(fn -> Application.put_env(:mailglass, :repo, original) end)
      :ok
    end

    test "delegates to the configured repo and returns its result" do
      assert {:ok, :done} = Mailglass.Repo.transact(fn -> {:ok, :done} end)
    end

    test "propagates {:error, reason} from the inner function" do
      assert {:error, :rolled_back} =
               Mailglass.Repo.transact(fn -> {:error, :rolled_back} end)
    end
  end
end
