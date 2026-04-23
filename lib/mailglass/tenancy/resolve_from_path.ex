defmodule Mailglass.Tenancy.ResolveFromPath do
  @moduledoc """
  Opt-in URL-prefix tenant resolver (D-12 sugar).

  Reads `context.path_params["tenant_id"]` and returns `{:ok, tid}` when
  present and non-empty, or `{:error, :missing_path_param}` otherwise.
  Adopters with a router shape that embeds the tenant identifier in the
  URL path (e.g. `/tenants/:tenant_id/webhooks/postmark`) compose this
  resolver to avoid hand-writing the same one-line extraction.

  ## Why this is a separate module

  `Mailglass.Tenancy.SingleTenant` is the zero-config default (always
  `{:ok, "default"}`). `ResolveFromPath` is the minimum viable
  multi-tenant resolver; adopters wire it by setting:

      config :mailglass, tenancy: Mailglass.Tenancy.ResolveFromPath

  ## Important: this module does NOT implement a real `scope/2`

  `ResolveFromPath` is SUGAR for webhook tenant extraction only. Its
  `scope/2` raises — the module fails CLOSED when mistakenly used as a
  complete Tenancy implementation. Adopters using it for the full
  Tenancy contract MUST configure their own module that delegates
  `resolve_webhook_tenant/1` to this module while implementing
  `scope/2` for their data layer:

      defmodule MyApp.Tenancy do
        @behaviour Mailglass.Tenancy

        @impl Mailglass.Tenancy
        def scope(query, context), do: # ...  WHERE tenant_id = ?  / repo prefix

        @impl Mailglass.Tenancy
        defdelegate resolve_webhook_tenant(context),
          to: Mailglass.Tenancy.ResolveFromPath
      end

  ## Threat mitigation (T-04-08)

  `ResolveFromPath` EXTRACTS `path_params["tenant_id"]` only — it does
  NOT validate that the tenant exists in any persistence layer.
  Cross-tenant data access is prevented downstream by the configured
  Tenancy module's `scope/2` (which adopters implement for their own
  data layer). Forged `tenant_id` values in the URL path can ONLY
  access whatever data the adopter Repo's Tenancy scope exposes for
  that ID — there is no implicit trust in this module. Mitigation
  verified by the `scope/2` raise behaviour + the documentation
  contract that composition with a real Tenancy is mandatory.
  """

  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(_query, _context) do
    raise """
    Mailglass.Tenancy.ResolveFromPath does not implement scope/2.

    This module is a SUGAR resolver for webhook tenant extraction
    only. To use it for the full Mailglass.Tenancy contract, configure
    your own module that delegates resolve_webhook_tenant/1 to this
    module while implementing scope/2 for your data layer. See the
    moduledoc example.
    """
  end

  @impl Mailglass.Tenancy
  def resolve_webhook_tenant(%{path_params: %{"tenant_id" => tid}})
      when is_binary(tid) and tid != "" do
    {:ok, tid}
  end

  def resolve_webhook_tenant(_context), do: {:error, :missing_path_param}
end
