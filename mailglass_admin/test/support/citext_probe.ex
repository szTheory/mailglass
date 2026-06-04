defmodule MailglassAdmin.TestSupport.CitextProbe do
  @moduledoc false

  # Boundary: declared as a top-level ignored boundary so that cross-boundary calls to
  # Mailglass internal modules (SuppressionStore.Ecto, Suppression.Entry) are not checked.
  # Test support legitimately needs internal Mailglass access for real DB round-trip probes;
  # `check: [in: false, out: false]` is the Boundary-idiomatic pattern for test support
  # (see Boundary docs §"Ignoring checks can be useful for test support modules").
  use Boundary, top_level?: true, check: [in: false, out: false]

  import Ecto.Query

  alias Mailglass.Suppression.Entry
  alias Mailglass.SuppressionStore.Ecto, as: SuppressionStore

  def run(opts \\ []) do
    repo = Keyword.get(opts, :repo, MailglassAdmin.TestRepo)

    max_attempts =
      Keyword.get_lazy(opts, :max_attempts, fn ->
        pool_size =
          repo.config()
          |> Keyword.get(:pool_size, 5)

        max(pool_size + 1, 5)
      end)

    probe_fun = Keyword.get(opts, :probe_fun, &default_probe/1)
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
