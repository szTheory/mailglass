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
    raise exhausted_message(repo, attempted, nil)
  end

  # Only the poisoned-OID surface is retried. Every other `Postgrex.Error` is
  # re-raised with its original message and stacktrace: retrying a permanent
  # fault (a missing relation, a bad credential, a syntax error) can only ever
  # end in the exhaustion message, which then reports "citext probe exhausted"
  # for a database that has nothing wrong with its citext type. That misdirection
  # is expensive — it hides the real fault behind a retry loop and a stack that
  # points at this module instead of the actual failure.
  #
  # Reraise happens *outside* the rescue block so Credo's `RaiseInsideRescue`
  # check stays satisfied while diagnostics stay honest.
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

  # The stale-OID signal. After `ecto.drop && ecto.create` (or a migration
  # down/up round-trip) Postgres assigns citext a new OID while pooled
  # connections and the shared TypeServer still hold the old one. Postgres
  # reports that as `XX000 (internal_error) cache lookup failed for type NNNNNN`.
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

    # Schema-aware: under the CI schema-isolation axis (MAILGLASS_SCHEMA=mailglass)
    # the `mailglass_suppressions` table lives in the `mailglass` schema, not
    # `public`. `SuppressionStore.check/1` already routes through the facade
    # (which injects `prefix: Config.schema()`), but the raw-repo delete_all /
    # insert / delete below bypass the facade, so they must inject the same
    # prefix explicitly — otherwise they hit an unqualified `mailglass_suppressions`
    # (resolving via public search_path) and raise 42P01, which the probe would
    # mistake for a poisoned-OID Postgrex.Error and retry until exhaustion.
    prefix = Mailglass.Config.schema()

    case SuppressionStore.check(%{tenant_id: "__probe__", address: "probe@example.test"}) do
      :not_suppressed -> :ok
      {:suppressed, _entry} -> :ok
      {:error, _reason} -> :ok
    end

    repo.delete_all(from(e in Entry, where: e.tenant_id == "__probe__"), prefix: prefix)

    {:ok, inserted} =
      %{
        tenant_id: "__probe__",
        address: probe_address,
        scope: :address,
        reason: :manual,
        source: "probe"
      }
      |> Entry.changeset()
      |> repo.insert(prefix: prefix)

    _ = repo.delete(inserted, prefix: prefix)

    :ok
  end
end
