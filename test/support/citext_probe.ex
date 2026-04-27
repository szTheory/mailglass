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

  @default_max_attempts 5

  @spec run(keyword()) :: :ok
  def run(opts \\ []) do
    repo = Keyword.get(opts, :repo, Mailglass.TestRepo)
    max_attempts = Keyword.get(opts, :max_attempts, @default_max_attempts)
    do_probe(repo, max_attempts)
  end

  defp do_probe(_repo, 0), do: :ok

  defp do_probe(repo, remaining) do
    try do
      repo.query!("SELECT 'probe'::citext")
      :ok
    rescue
      Postgrex.Error -> do_probe(repo, remaining - 1)
    end
  end
end
