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
            limit: 1
          )

        query = union_predicates(base, address, recipient_domain, stream)

        case Mailglass.Repo.one(Tenancy.scope(query, tenant_id)) do
          nil -> :not_suppressed
          %Entry{} = entry -> {:suppressed, entry}
        end
      end
    )
  end

  # Fallback clause for malformed keys (missing :tenant_id / :address, or
  # non-binary values). Returns the behaviour's documented `{:error, term()}`
  # shape so Phase 3's `Outbound.preflight` can log/handle instead of
  # surfacing a FunctionClauseError stacktrace from a mis-wired adopter
  # helper (WR-03).
  def check(_key, _opts), do: {:error, :invalid_key}

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
        attrs
        |> Entry.changeset()
        |> Mailglass.Repo.insert(insert_opts())
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
      returning: true
    ]
  end

  defp extract_domain(email) when is_binary(email) do
    case String.split(email, "@", parts: 2) do
      [_local, domain] -> String.downcase(domain)
      # Malformed email — degenerate domain won't match anything.
      _ -> ""
    end
  end
end
