defmodule Mailglass.SuppressionStore.Ecto do
  @moduledoc """
  Default Ecto-backed `Mailglass.SuppressionStore` implementation.

  `check/2` performs the union lookup from CONTEXT.md §specifics:

      SELECT 1 FROM mailglass_suppressions
      WHERE tenant_id = $tenant_id
        AND (
          (scope = 'address' AND address = $recipient) OR
          (scope = 'domain' AND address = $recipient_domain) OR
          (scope = 'address_stream' AND address = $recipient AND stream = $stream)
        )
        AND (expires_at IS NULL OR expires_at > now())
      LIMIT 1

  The UNIQUE index on `(tenant_id, address, scope, COALESCE(stream, ''))`
  plus the secondary `(tenant_id, address)` index serve the OR-union
  efficiently (Postgres chooses per-branch plans).

  `record/2` uses `on_conflict: {:replace, [...]}` to make admin
  re-adds idempotent.
  """

  @behaviour Mailglass.SuppressionStore

  import Ecto.Query

  alias Mailglass.Clock
  alias Mailglass.Suppression.Entry
  alias Mailglass.Tenancy
  alias Postgrex.Error, as: PostgrexError

  @returning_fields [
    :id,
    :tenant_id,
    :scope,
    :stream,
    :reason,
    :source,
    :expires_at,
    :metadata,
    :inserted_at
  ]

  @impl Mailglass.SuppressionStore
  def check(key, opts \\ [])

  def check(%{tenant_id: tenant_id, address: address} = key, _opts)
      when is_binary(tenant_id) and is_binary(address) do
    stream = Map.get(key, :stream)
    address = String.downcase(address)
    recipient_domain = extract_domain(address)

    Mailglass.Telemetry.persist_span(
      [:suppression, :check],
      %{tenant_id: tenant_id},
      fn ->
        now = Clock.utc_now()

        base =
          from(e in Entry,
            where: e.tenant_id == ^tenant_id,
            where: is_nil(e.expires_at) or e.expires_at > ^now,
            limit: 1,
            select: %{
              id: e.id,
              tenant_id: e.tenant_id,
              scope: e.scope,
              stream: e.stream,
              reason: e.reason,
              source: e.source,
              expires_at: e.expires_at,
              metadata: e.metadata,
              inserted_at: e.inserted_at
            }
          )

        query = union_predicates(base, address, recipient_domain, stream)

        case with_stale_type_retry(fn ->
               Mailglass.Repo.one(Tenancy.scope(query, tenant_id))
             end) do
          nil -> :not_suppressed
          entry when is_map(entry) -> {:suppressed, entry_from_row(entry)}
        end
      end
    )
  end

  # Fallback clause for malformed keys (missing :tenant_id / :address, or
  # non-binary values). Returns the behaviour's documented `{:error, term()}`
  # shape so 's `Outbound.preflight` can log/handle instead of
  # surfacing a FunctionClauseError stacktrace from a mis-wired adopter
  # helper (WR-03).
  def check(_key, _opts), do: {:error, :invalid_key}

  @impl Mailglass.SuppressionStore
  def check_many(keys, opts \\ []) when is_list(keys) and is_list(opts) do
    Mailglass.Telemetry.persist_span(
      [:suppression, :check_many],
      %{count: length(keys)},
      fn ->
        normalized = Enum.map(keys, &normalize_key/1)

        entries_by_tenant =
          normalized
          |> Enum.flat_map(fn
            {:ok, key} -> [key]
            {:error, _} -> []
          end)
          |> Enum.uniq()
          |> Enum.group_by(& &1.tenant_id)
          |> Map.new(fn {tenant_id, tenant_keys} ->
            {tenant_id, fetch_entries(tenant_id, tenant_keys, Clock.utc_now())}
          end)

        Enum.map(normalized, fn
          {:error, reason} -> {:error, reason}
          {:ok, key} -> result_for(key, Map.fetch!(entries_by_tenant, key.tenant_id))
        end)
      end
    )
  end

  # The address_stream branch is only included when a stream was passed.
  # Ecto refuses `e.stream == ^nil` at build time ("comparing with nil is
  # forbidden"), and a stream-less caller has no basis to match stream-
  # scoped entries anyway.
  defp union_predicates(base, address, recipient_domain, nil) do
    from(e in base,
      where:
        (e.scope == :address and e.address == ^address) or
          (e.scope == :domain and e.address == ^recipient_domain)
    )
  end

  defp union_predicates(base, address, recipient_domain, stream) when is_atom(stream) do
    from(e in base,
      where:
        (e.scope == :address and e.address == ^address) or
          (e.scope == :domain and e.address == ^recipient_domain) or
          (e.scope == :address_stream and e.address == ^address and
             e.stream == ^stream)
    )
  end

  @impl Mailglass.SuppressionStore
  def record(attrs, opts \\ [])

  def record(attrs, _opts) when is_map(attrs) do
    Mailglass.Telemetry.persist_span(
      [:suppression, :record],
      %{tenant_id: Map.get(attrs, :tenant_id)},
      fn ->
        with_stale_type_retry(fn ->
          attrs
          |> Entry.changeset()
          |> Mailglass.Repo.insert(insert_opts())
        end)
      end
    )
  end

  # Fallback clause for non-map attrs — mirrors the `check/2` treatment
  # (WR-03). Map input with invalid field values still flows through the
  # changeset and returns `{:error, %Ecto.Changeset{}}`; only non-map
  # input takes this path.
  def record(_attrs, _opts), do: {:error, :invalid_attrs}

  # UPSERT shape — admin re-adds of the same (tenant_id, address, scope,
  # stream-or-empty) update the mutable fields but keep `:id`, `:inserted_at`,
  # `:tenant_id`, `:address`, `:scope`, `:stream` stable.
  defp insert_opts do
    [
      on_conflict: {:replace, [:reason, :source, :expires_at, :metadata]},
      conflict_target: {:unsafe_fragment, "(tenant_id, address, scope, COALESCE(stream, ''))"},
      returning: @returning_fields
    ]
  end

  defp extract_domain(email) when is_binary(email) do
    case String.split(email, "@", parts: 2) do
      [_local, domain] -> String.downcase(domain)
      # Malformed email — degenerate domain won't match anything.
      _ -> ""
    end
  end

  defp normalize_key(%{tenant_id: tenant_id, address: address} = key)
       when is_binary(tenant_id) and is_binary(address) do
    {:ok, %{tenant_id: tenant_id, address: String.downcase(address), stream: Map.get(key, :stream)}}
  end

  defp normalize_key(_key), do: {:error, :invalid_key}

  defp fetch_entries(tenant_id, keys, now) do
    predicate =
      Enum.reduce(keys, dynamic(false), fn key, dynamic ->
        address = key.address
        recipient_domain = extract_domain(address)

        key_predicate =
          case key.stream do
            stream when is_atom(stream) ->
              dynamic(
                [e],
                e.tenant_id == ^tenant_id and
                  ((e.scope == :address and e.address == ^address) or
                     (e.scope == :domain and e.address == ^recipient_domain) or
                     (e.scope == :address_stream and e.address == ^address and e.stream == ^stream))
              )

            _ ->
              dynamic(
                [e],
                e.tenant_id == ^tenant_id and
                  ((e.scope == :address and e.address == ^address) or
                     (e.scope == :domain and e.address == ^recipient_domain))
              )
          end

        dynamic([e], ^dynamic or ^key_predicate)
      end)

    query =
      from(e in Entry,
        where: is_nil(e.expires_at) or e.expires_at > ^now,
        where: ^predicate,
        select: %{
          id: e.id,
          tenant_id: e.tenant_id,
          address: e.address,
          scope: e.scope,
          stream: e.stream,
          reason: e.reason,
          source: e.source,
          expires_at: e.expires_at,
          metadata: e.metadata,
          inserted_at: e.inserted_at
        }
      )

    with_stale_type_retry(fn -> Mailglass.Repo.all(Tenancy.scope(query, tenant_id)) end)
  end

  defp result_for(key, entries) do
    case Enum.find(entries, &matches_key?(&1, key)) do
      nil -> :not_suppressed
      entry -> {:suppressed, entry_from_row(entry)}
    end
  end

  defp matches_key?(%{scope: :address, address: address}, %{address: address}), do: true

  defp matches_key?(%{scope: :domain, address: domain}, %{address: address}),
    do: domain == extract_domain(address)

  defp matches_key?(%{scope: :address_stream, address: address, stream: stream}, %{
         address: address,
         stream: stream
       })
       when is_atom(stream),
       do: true

  defp matches_key?(_entry, _key), do: false

  defp entry_from_row(attrs) when is_map(attrs) do
    struct(Entry, Map.put_new(attrs, :address, nil))
  end

  # `migration_test.exs` drops and recreates `citext`, which changes the type
  # OID behind `mailglass_suppressions.address`. Postgrex may raise
  # `XX000 cache lookup failed for type NNNNN` on one stale pooled connection.
  # Test config disconnects that connection on `:internal_error`; a single retry
  # then uses a fresh checkout with rebuilt type metadata.
  @stale_type_retry_attempts 8

  defp with_stale_type_retry(fun, attempts_left \\ @stale_type_retry_attempts)
       when is_function(fun, 0) and is_integer(attempts_left) do
    fun.()
  rescue
    error in PostgrexError ->
      if stale_type_cache_error?(error) and attempts_left > 1 do
        with_stale_type_retry(fun, attempts_left - 1)
      else
        reraise error, __STACKTRACE__
      end
  end

  defp stale_type_cache_error?(%PostgrexError{postgres: %{code: :internal_error}}), do: true

  defp stale_type_cache_error?(%PostgrexError{postgres: %{code: code}}) when code == "XX000",
    do: true

  defp stale_type_cache_error?(%PostgrexError{postgres: %{code: :feature_not_supported}}),
    do: true

  defp stale_type_cache_error?(%PostgrexError{postgres: %{code: code}}) when code == "0A000",
    do: true

  defp stale_type_cache_error?(_error), do: false
end
