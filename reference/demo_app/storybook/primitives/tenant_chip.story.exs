defmodule Storybook.Primitives.TenantChip do
  @moduledoc false
  # Read-only tenant context chip. Theme-sensitive (border + base-content tone).
  # Template-level data-theme bridge per PROJECT D-08. Covers the gallery's
  # chip states: with-tenant / no-tenant / long-tenant / non-ascii-tenant.
  use PhoenixStorybook.Story, :component

  def function, do: &MailglassAdmin.Components.tenant_chip/1

  def template do
    """
    <div data-theme="mailglass-light" class="mg-admin-root bg-base-100 text-base-content p-md">
      <.psb-variation/>
    </div>
    """
  end

  @dark_template """
  <div data-theme="mailglass-dark" class="mg-admin-root bg-base-100 text-base-content p-md">
    <.psb-variation/>
  </div>
  """

  def variations do
    [
      %Variation{id: :with_tenant_light, attributes: %{tenant: "northstar"}},
      %Variation{
        id: :with_tenant_dark,
        template: @dark_template,
        attributes: %{tenant: "northstar"}
      },
      %Variation{id: :no_tenant_light, attributes: %{tenant: nil}},
      %Variation{id: :no_tenant_dark, template: @dark_template, attributes: %{tenant: nil}},
      %Variation{
        id: :long_tenant,
        attributes: %{tenant: "fjordline-aps-operations-and-billing-eu-west-1"}
      },
      %Variation{id: :non_ascii_tenant, attributes: %{tenant: "fjörðlinje-aps-Ø"}}
    ]
  end
end
