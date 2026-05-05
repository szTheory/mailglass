defmodule Mailglass.TestSupport.CitextProbe do
  @moduledoc """
  Drains stale citext OIDs from the sandbox-checked-out connection.

  Background: `migration_test.exs` drops + recreates the citext extension to
  prove the down/up round-trip. Postgres assigns a fresh OID on recreate; pool
  workers retain the pre-drop OID and surface `Postgrex.Error XX000 (internal_error)
  cache lookup failed for type NNNNNN` on the next citext query.

  `disconnect_on_error_codes: [:internal_error]` in `config/test.exs` converts
  the error into a pool reconnect; the reconnected worker re-bootstraps its
  type cache. This module loops the probe up to `max_attempts` times to handle
  the worst case where successive workers were also poisoned.

  ## Usage

      # In a CaseTemplate `setup` block:
      Mailglass.TestSupport.CitextProbe.run(repo: Mailglass.TestRepo)

      # In `test_helper.exs` after migrations:
      Mailglass.TestSupport.CitextProbe.run([])
  """

  import Ecto.Query

  alias Mailglass.Suppression.Entry
  alias Mailglass.SuppressionStore.Ecto, as: SuppressionStore

  @spec run(keyword()) :: :ok
  def run(opts \\ []) do
    repo = Keyword.get(opts, :repo, Mailglass.TestRepo)
    probe_fun = Keyword.get(opts, :probe_fun, &default_probe/1)

    max_attempts =
      Keyword.get_lazy(opts, :max_attempts, fn ->
        pool_size =
          repo.config()
          |> Keyword.get(:pool_size, 5)

        max(pool_size + 1, 5)
      end)

    do_probe(repo, max_attempts, max_attempts, probe_fun)
  end

  defp do_probe(repo, 0, attempted, _probe_fun) do
    raise "citext probe exhausted for #{inspect(repo)} after #{attempted} attempts"
  end

  defp do_probe(repo, remaining, attempted, probe_fun) do
    try do
      probe_fun.(repo)
      :ok
    rescue
      Postgrex.Error ->
        if remaining == 1 do
          raise "citext probe exhausted for #{inspect(repo)} after #{attempted} attempts"
        else
          do_probe(repo, remaining - 1, attempted, probe_fun)
        end
    end
  end

  defp default_probe(repo) do
    probe_address = "probe-#{System.unique_integer([:positive])}@example.test"

    case SuppressionStore.check(%{tenant_id: "__probe__", address: "probe@example.test"}) do
      :not_suppressed -> :ok
      {:suppressed, _entry} -> :ok
      {:error, _reason} -> :ok
    end

    repo.delete_all(from(e in Entry, where: e.tenant_id == "__probe__"))

    {:ok, inserted} =
      %{
        tenant_id: "__probe__",
        address: probe_address,
        scope: :address,
        reason: :manual,
        source: "probe"
      }
      |> Entry.changeset()
      |> repo.insert()

    _ = repo.delete(inserted)

    :ok
  end
end
