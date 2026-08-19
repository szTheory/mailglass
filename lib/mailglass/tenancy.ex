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

  ## Process-dict convention

  `put_current/1` writes `tenant_id :: String.t()` under the
  namespaced key `:mailglass_tenant_id`. `current/0` reads it. The
  `with_tenant/2` block form wraps + restores. `tenant_id!/0` raises
  `Mailglass.TenancyError` when the key is unset — the fail-loud
  variant for callers that assert they hold context.

  ## Phoenix 1.8 `%Scope{}` interop

  Core does NOT pattern-match `%Phoenix.Scope{}`. Adopters write a
  two-line Plug / on_mount callback:

      def on_mount(_name, _params, _session, socket) do
        scope = socket.assigns.current_scope
        Mailglass.Tenancy.put_current(scope.organization.id)
        {:cont, socket}
      end

  Documented in `guides/multi-tenancy.md`.
  """

  @callback scope(queryable :: Ecto.Queryable.t(), context :: term()) :: Ecto.Queryable.t()

  @type outbound_adapter_ref :: atom() | String.t()

  @optional_callbacks tracking_host: 1,
                      compliance_host: 1,
                      resolve_webhook_tenant: 1,
                      resolve_outbound_adapter_ref: 1

  @doc """
  Optional: return a per-tenant tracking host override.

  Default adopter resolution: `:default` (use the global
  `config :mailglass, :tracking, host:` value). Adopters returning
  `{:ok, host}` get per-tenant subdomains (`track.tenant-a.example.com`)
  for strict cookie/origin isolation.
  """
  @callback tracking_host(context :: term()) :: {:ok, String.t()} | :default

  @doc """
  Optional: return a per-tenant unsubscribe host override.

  Mirrors `tracking_host/1`, but applies specifically to RFC 8058 URL
  generation so multi-tenant adopters can keep unsubscribe origins
  tenant-scoped without forking the core URL builder.
  """
  @callback compliance_host(context :: term()) :: {:ok, String.t()} | :default

  @doc """
  Optional: resolve a per-send outbound adapter ref for the current tenant.

  Returning `{:ok, adapter_ref}` selects a named route from
  `config :mailglass, adapters:`. Returning `:default` keeps the global
  `config :mailglass, adapter` path.

  The callback stays narrowly scoped to outbound routing decisions:

    * `:tenant_id` — stamped tenant id for the current send
    * `:message` — the `%Mailglass.Message{}` being delivered
    * `:mode` — `:sync` or `:async`
  """
  @callback resolve_outbound_adapter_ref(
              context :: %{
                tenant_id: String.t() | nil,
                message: Mailglass.Message.t(),
                mode: :sync | :async
              }
            ) :: {:ok, outbound_adapter_ref()} | :default

  @doc """
  Optional: resolve the tenant from a verified webhook context.

  Called by `Mailglass.Webhook.Plug` AFTER `Provider.verify!/3` returns
  `:ok` — 's "verify-first, tenant-second" ordering closes the
  Stripe-Connect chicken-and-egg trap (a forged request cannot spoof its
  way into a tenant's suppression list because the signature gate runs
  on the global key material before any tenant-scoped work).

  Adopters returning `{:ok, tenant_id}` stamp tenant context for the
  rest of the ingest pipeline (normalize + persist + broadcast).
  `{:error, reason}` causes `Mailglass.Webhook.Plug` to raise
  `%Mailglass.TenancyError{type: :webhook_tenant_unresolved}` and
  return HTTP 422.

  ## Context map fields

    * `:provider` — `:postmark | :sendgrid` (the atom the router
      dispatched against)
    * `:conn` — the `Plug.Conn` for header / IP / path-param
      introspection
    * `:raw_body` — verified raw bytes (signature passed before this
      callback fires)
    * `:headers` — `[{name, value}]` list as produced by the verifier
    * `:path_params` — adopter route's path params
      (e.g. `%{"tenant_id" => "..."}`)
    * `:verified_payload` — reserved compatibility field; remains `nil`
    * `:decoded_payload` — the verified request's decoded outer JSON map or
      list, or `nil` when decoding failed. Signature verification still uses
      `:raw_body`; SES nested `Message` JSON is not exposed here.

  ## Examples

      # SingleTenant default — everything is "default"
      def resolve_webhook_tenant(_), do: {:ok, "default"}

      # Per-shop Shopify-style header lookup
      def resolve_webhook_tenant(%{headers: headers}) do
        case List.keyfind(headers, "x-shopify-shop-domain", 0) do
          {_, shop_domain} -> {:ok, shop_domain}
          nil -> {:error, :missing_shop_domain}
        end
      end

  Adopters not implementing this callback get SingleTenant default
  behaviour (`{:ok, "default"}`) via the dispatcher's
  `function_exported?/3` fallback. `Mailglass.Tenancy.ResolveFromPath`
  ships as opt-in sugar for URL-prefix tenant resolution.
  """
  @callback resolve_webhook_tenant(
              context :: %{
                provider: atom(),
                conn: Plug.Conn.t(),
                raw_body: binary(),
                headers: [{String.t(), String.t()}],
                path_params: map(),
                verified_payload: nil,
                decoded_payload: map() | list() | nil
              }
            ) :: {:ok, String.t()} | {:error, term()}

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
  Clear any tenant scope set in the current process dictionary.

  Returns `:ok`. Primarily used by test `on_exit` cleanup — encapsulates
  the internal process-dict key so tests don't need to know the exact
  atom (`:mailglass_tenant_id`). Production code should rely on
  `with_tenant/2` block scoping (Pitfall 7), which auto-restores prior
  scope even on raise.
  """
  @doc since: "0.1.0"
  @spec clear() :: :ok
  def clear do
    Process.delete(@process_dict_key)
    :ok
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
  This is the SEN precondition — ensures
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

  @doc """
  Emits an audit breadcrumb when a call intentionally opts into
  `scope: :unscoped` access.

  This keeps the bypass path explicit and machine-searchable
  reviews.
  """
  @doc since: "0.1.0"
  @spec audit_unscoped_bypass(keyword() | map()) :: :ok
  def audit_unscoped_bypass(metadata \\ %{}) do
    base_metadata =
      metadata
      |> normalize_unscoped_audit_metadata()
      |> Map.put_new(:tenant_id, current())

    Mailglass.Telemetry.execute(
      [:mailglass, :tenant, :scope, :unscoped_bypass],
      %{count: 1},
      base_metadata
    )
  end

  @doc """
  Dispatch to the configured tenancy module's `resolve_webhook_tenant/1`
  callback (  — the optional callback  formally declares).

  Returns `{:ok, tenant_id}` on success or `{:error, reason}` when the
  adopter's tenancy module cannot map the verified webhook context to a
  known tenant. `Mailglass.Webhook.Plug` rescues the latter as a 422 via
  `%Mailglass.TenancyError{type: :webhook_tenant_unresolved}`.

  The `context` map shape is documented in CONTEXT :

      %{
        provider: :postmark | :sendgrid,
        conn: Plug.Conn.t(),
        raw_body: binary(),
        headers: [{String.t(), String.t()}],
        path_params: map(),
        verified_payload: nil,
        decoded_payload: map() | list() | nil
      }

  ## Fallback behaviour

  `Mailglass.Tenancy.SingleTenant` ships a concrete
  `resolve_webhook_tenant/1` impl that returns `{:ok, "default"}` — the
  zero-config single-tenant default. Adopter tenancy modules that do
  not implement the optional callback also fall through to
  `{:ok, "default"}` via the dispatcher's `function_exported?/3`
  check; multi-tenant adopters MUST implement the callback to get
  meaningful tenant routing.
  """
  @doc since: "0.1.0"
  @spec resolve_webhook_tenant(map()) :: {:ok, String.t()} | {:error, term()}
  def resolve_webhook_tenant(context) when is_map(context) do
    module = resolver()

    if function_exported?(module, :resolve_webhook_tenant, 1) do
      module.resolve_webhook_tenant(context)
    else
      {:ok, "default"}
    end
  end

  @doc """
  Dispatch to the configured tenancy module's optional `compliance_host/1`
  callback.

  Adopters returning `{:ok, host}` override the global
  `config :mailglass, :compliance, host:` value for the current tenant.
  Returning `:default` keeps the global host.
  """
  @doc since: "0.1.0"
  @spec compliance_host(term()) :: {:ok, String.t()} | :default
  def compliance_host(context) do
    module = resolver()

    if function_exported?(module, :compliance_host, 1) do
      module.compliance_host(context)
    else
      :default
    end
  end

  @doc """
  Dispatch to the configured tenancy module's optional
  `resolve_outbound_adapter_ref/1` callback.

  Adopters returning `{:ok, adapter_ref}` select a named route from the
  validated adapter registry. Returning `:default` keeps the global
  default adapter path. Adopters not implementing the callback fall back
  to `:default`.
  """
  @doc since: "0.4.0"
  @spec resolve_outbound_adapter_ref(%{
          tenant_id: String.t() | nil,
          message: Mailglass.Message.t(),
          mode: :sync | :async
        }) :: {:ok, outbound_adapter_ref()} | :default
  def resolve_outbound_adapter_ref(%{message: %Mailglass.Message{}, mode: mode} = context)
      when mode in [:sync, :async] do
    module = resolver()

    if function_exported?(module, :resolve_outbound_adapter_ref, 1) do
      module.resolve_outbound_adapter_ref(context)
    else
      :default
    end
  end

  defp resolver do
    case Mailglass.Config.tenancy() do
      nil -> Mailglass.Tenancy.SingleTenant
      mod when is_atom(mod) -> mod
    end
  end

  defp normalize_unscoped_audit_metadata(metadata) when is_map(metadata), do: metadata

  defp normalize_unscoped_audit_metadata(metadata) when is_list(metadata) do
    if Keyword.keyword?(metadata), do: Enum.into(metadata, %{}), else: %{}
  end

  defp normalize_unscoped_audit_metadata(_metadata), do: %{}

  defp default_tenant do
    case resolver() do
      Mailglass.Tenancy.SingleTenant -> "default"
      _ -> nil
    end
  end
end
