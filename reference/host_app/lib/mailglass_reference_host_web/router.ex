defmodule MailglassReferenceHostWeb.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router
  import MailglassAdmin.Router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  pipeline :mailglass_webhooks do
    plug :accepts, ["json"]
  end

  # HOST-02 stable seam references:
  # - MailglassAdmin.Router.mailglass_admin_routes/2
  # - MailglassAdmin.Router.mailglass_operator_routes/2
  # - MailglassInbound.Ingress.Plug
  scope "/inbound" do
    pipe_through :mailglass_webhooks
    post "/:tenant_id/postmark", MailglassInbound.Ingress.Plug, provider: :postmark
    post "/:tenant_id/sendgrid", MailglassInbound.Ingress.Plug, provider: :sendgrid
  end

  if Application.compile_env(:mailglass_reference_host, :dev_routes, false) do
    scope "/dev" do
      pipe_through :browser
      mailglass_admin_routes "/mail"

      mailglass_operator_routes "/mail-ops",
        auth: MailglassReferenceHostWeb.AdminAuth,
        session: [
          subject_id: "current_user_id",
          tenant_id: "current_tenant_id",
          auth_method: "current_auth_method",
          recent_auth_at: "recent_auth_at"
        ],
        unauthorized_path: "/"
    end
  end
end
