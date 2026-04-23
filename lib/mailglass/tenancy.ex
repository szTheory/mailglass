defmodule Mailglass.Tenancy do
  @moduledoc """
  Tenancy behaviour + process-dict helpers.

  Adopters implement `@behaviour Mailglass.Tenancy` and configure it via:

      config :mailglass, tenancy: MyApp.Tenancy

  The behaviour exposes ONE callback: `scope/2`. Non-callback helpers
  live on this module for tenant-context plumbing.

  ## Default resolver

  `Mailglass.Tenancy.SingleTenant` is the shipped default — a no-op
  `scope/2` and a `"default"` literal tenant_id from `current/0` when
  no stamping has occurred.

  ## Process-dict convention (D-30)

  `put_current/1` writes `tenant_id :: String.t()` under the
  namespaced key `:mailglass_tenant_id`. `current/0` reads it. The
  `with_tenant/2` block form wraps + restores. `tenant_id!/0` raises
  `Mailglass.TenancyError` when the key is unset — the fail-loud
  variant for callers that assert they hold context.

  ## Phoenix 1.8 `%Scope{}` interop (D-32)

  Core does NOT pattern-match `%Phoenix.Scope{}`. Adopters write a
  two-line Plug / on_mount callback:

      def on_mount(_name, _params, _session, socket) do
        scope = socket.assigns.current_scope
        Mailglass.Tenancy.put_current(scope.organization.id)
        {:cont, socket}
      end

  Documented in `guides/multi-tenancy.md` (Phase 7 DOCS-02).
  """

  @callback scope(queryable :: Ecto.Queryable.t(), context :: term()) :: Ecto.Queryable.t()

  @optional_callbacks tracking_host: 1

  @doc """
  Optional: return a per-tenant tracking host override (D-32).

  Default adopter resolution: `:default` (use the global
  `config :mailglass, :tracking, host:` value). Adopters returning
  `{:ok, host}` get per-tenant subdomains (`track.tenant-a.example.com`)
  for strict cookie/origin isolation.
  """
  @callback tracking_host(context :: term()) :: {:ok, String.t()} | :default

  @process_dict_key :mailglass_tenant_id

  @doc """
  Returns the current tenant_id or the configured resolver's default.

  Reads the process-dict first; falls back to the configured resolver's
  default when nothing has been stamped. With the default
  `Mailglass.Tenancy.SingleTenant` resolver active and no explicit
  stamping, returns the literal `"default"`. With an adopter resolver
  configured, returns `nil` unless the adopter's own fallback is wired
  in via `put_current/1`.
  """
  @doc since: "0.1.0"
  @spec current() :: String.t() | nil
  def current do
    Process.get(@process_dict_key) || default_tenant()
  end

  @doc """
  Stamps the current tenant in the process dictionary.

  Subsequent `current/0` calls return this value (until the process
  exits or `put_current/1` is called again). Passing `nil` deletes the
  stamp; `current/0` then falls back to the resolver's default.
  """
  @doc since: "0.1.0"
  @spec put_current(String.t() | nil) :: :ok
  def put_current(tenant_id) when is_binary(tenant_id) do
    Process.put(@process_dict_key, tenant_id)
    :ok
  end

  def put_current(nil) do
    Process.delete(@process_dict_key)
    :ok
  end

  @doc """
  Runs `fun` with `tenant_id` stamped as the current tenant, then
  restores whatever was stamped before (nil if nothing).

  Useful for tests and for Oban middleware serializing context across
  job boundaries (see `Mailglass.Oban.TenancyMiddleware`). The prior
  value is restored even when `fun` raises.
  """
  @doc since: "0.1.0"
  @spec with_tenant(String.t(), (-> any())) :: any()
  def with_tenant(tenant_id, fun) when is_binary(tenant_id) and is_function(fun, 0) do
    prior = Process.get(@process_dict_key)
    put_current(tenant_id)

    try do
      fun.()
    after
      if is_nil(prior) do
        Process.delete(@process_dict_key)
      else
        put_current(prior)
      end
    end
  end

  @doc """
  Returns the current tenant_id or raises `Mailglass.TenancyError`.

  Unlike `current/0`, this does NOT fall back to the SingleTenant
  default. Use this when the caller is certain it holds tenant context
  (e.g. inside an Oban worker after the middleware has run) and wants
  to fail loud on the "forgot to stamp" programmer error.
  """
  @doc since: "0.1.0"
  @spec tenant_id!() :: String.t()
  def tenant_id! do
    case Process.get(@process_dict_key) do
      nil -> raise Mailglass.TenancyError.new(:unstamped)
      tenant_id when is_binary(tenant_id) -> tenant_id
    end
  end

  @doc """
  Raises `%Mailglass.TenancyError{type: :unstamped}` if no tenant is
  stamped in the current process. Returns `:ok` otherwise.

  Unlike `current/0`, does NOT fall back to the `SingleTenant` default.
  This is the SEND-01 precondition (D-18) — ensures
  `Events.append_multi/3` auto-capture via `Tenancy.current/0` does not
  silently default to `"default"` in a multi-tenant adopter.
  """
  @doc since: "0.1.0"
  @spec assert_stamped!() :: :ok
  def assert_stamped! do
    _ = tenant_id!()
    :ok
  end

  @doc """
  Scopes `queryable` to the current (or supplied) tenant context via
  the configured resolver.

  With `Mailglass.Tenancy.SingleTenant`, this is a no-op. With an
  adopter resolver, this injects a `WHERE tenant_id = ?` clause (or
  equivalent) into the query.
  """
  @doc since: "0.1.0"
  @spec scope(Ecto.Queryable.t(), term()) :: Ecto.Queryable.t()
  def scope(queryable, context \\ current()) do
    resolver().scope(queryable, context)
  end

  defp resolver do
    case Application.get_env(:mailglass, :tenancy) do
      nil -> Mailglass.Tenancy.SingleTenant
      mod when is_atom(mod) -> mod
    end
  end

  defp default_tenant do
    case resolver() do
      Mailglass.Tenancy.SingleTenant -> "default"
      _ -> nil
    end
  end
end
