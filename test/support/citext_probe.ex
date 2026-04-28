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
    max_attempts =
      Keyword.get_lazy(opts, :max_attempts, fn ->
        pool_size =
          repo.config()
          |> Keyword.get(:pool_size, 5)

        max(pool_size + 1, 5)
      end)

    do_probe(repo, max_attempts)
  end

  defp do_probe(_repo, 0), do: :ok

  defp do_probe(repo, remaining) do
    try do
      case SuppressionStore.check(%{tenant_id: "__probe__", address: "probe@example.test"}) do
        :not_suppressed -> :ok
        {:suppressed, _entry} -> :ok
        {:error, _reason} -> :ok
      end

      repo.delete_all(from e in Entry, where: e.tenant_id == "__probe__")

      {:ok, inserted} =
        %{
          tenant_id: "__probe__",
          address: "probe@example.test",
          scope: :address,
          reason: :manual,
          source: "probe"
        }
        |> Entry.changeset()
        |> repo.insert()

      _ = repo.delete(inserted)

      :ok
    rescue
      Postgrex.Error -> do_probe(repo, remaining - 1)
    end
  end
end
