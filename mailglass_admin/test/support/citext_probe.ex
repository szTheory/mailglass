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
    raise exhausted_message(repo, attempted, nil)
  end

  # Only the poisoned-OID surface is retried. Every other `Postgrex.Error` is
  # re-raised with its original message and stacktrace: retrying a permanent
  # fault (a missing relation, a bad credential, a syntax error) can only ever
  # end in the exhaustion message, which then reports "citext probe exhausted"
  # for a database that has nothing wrong with its citext type.
  defp do_probe(repo, remaining, attempted, probe_fun) do
    case attempt_probe(repo, probe_fun) do
      :ok ->
        :ok

      {:reraise, error, stacktrace} ->
        reraise(error, stacktrace)

      {:retry, error} ->
        if remaining == 1 do
          raise exhausted_message(repo, attempted, error)
        else
          do_probe(repo, remaining - 1, attempted, probe_fun)
        end
    end
  end

  defp attempt_probe(repo, probe_fun) do
    probe_fun.(repo)
    :ok
  rescue
    error in Postgrex.Error ->
      if poisoned_oid?(error) do
        {:retry, error}
      else
        {:reraise, error, __STACKTRACE__}
      end
  end

  # The stale-OID signal: after a drop/create or migration round-trip Postgres
  # assigns citext a new OID while pooled connections still hold the old one,
  # reported as `XX000 (internal_error) cache lookup failed for type NNNNNN`.
  defp poisoned_oid?(%Postgrex.Error{postgres: %{code: :internal_error}}), do: true

  defp poisoned_oid?(%Postgrex.Error{} = error) do
    error
    |> Exception.message()
    |> String.contains?("cache lookup failed")
  end

  defp exhausted_message(repo, attempted, nil) do
    "citext probe exhausted for #{inspect(repo)} after #{attempted} attempts"
  end

  defp exhausted_message(repo, attempted, error) do
    exhausted_message(repo, attempted, nil) <>
      "; last error: " <> Exception.message(error)
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
