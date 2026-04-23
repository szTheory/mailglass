defmodule Mailglass.RepoMultiTest do
  use Mailglass.DataCase, async: false

  @moduletag :phase_03_uat

  test "multi/1 executes an Ecto.Multi via the configured repo and returns {:ok, changes}" do
    multi = Ecto.Multi.run(Ecto.Multi.new(), :step1, fn _repo, _changes -> {:ok, 42} end)
    assert {:ok, %{step1: 42}} = Mailglass.Repo.multi(multi)
  end

  test "multi/1 returns {:error, step, reason, changes} on step failure" do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:step1, fn _repo, _changes -> {:ok, :ok} end)
      |> Ecto.Multi.run(:step2, fn _repo, _changes -> {:error, :boom} end)

    assert {:error, :step2, :boom, %{step1: :ok}} = Mailglass.Repo.multi(multi)
  end

  test "multi/1 raises %ConfigError{type: :missing} when :repo is unset" do
    prev = Application.get_env(:mailglass, :repo)
    Application.delete_env(:mailglass, :repo)
    on_exit(fn -> Application.put_env(:mailglass, :repo, prev) end)

    assert_raise Mailglass.ConfigError, ~r/:repo/, fn ->
      Mailglass.Repo.multi(Ecto.Multi.new())
    end
  end
end
