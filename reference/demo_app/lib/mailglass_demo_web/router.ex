defmodule MailglassDemoWeb.Router do
  use Phoenix.Router

  import Phoenix.Controller
  import Phoenix.LiveView.Router
  import Plug.Conn
  import MailglassAdmin.Router
  import PhoenixStorybook.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, false)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :webhooks do
    plug(:accepts, ["json"])
  end

  scope "/", MailglassDemoWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
    get("/health", PageController, :health)
    get("/demo/login", PageController, :login)
    post("/demo/reset", PageController, :reset)
  end

  scope "/demo", MailglassDemoWeb do
    pipe_through(:webhooks)

    post("/evidence/reset", PageController, :evidence_reset)
  end

  # Serves phoenix_storybook's OWN prebuilt explorer assets (shipped in the hex
  # package). Dev-only because the dep is `only: :dev` — absent from the compiled
  # prod build entirely (T-118-01 mitigation).
  scope "/" do
    storybook_assets()
  end

  scope "/dev" do
    pipe_through(:browser)

    mailglass_admin_routes("/mail",
      mailables: [
        MailglassDemoWeb.Mailers.AccountMailer,
        MailglassDemoWeb.Mailers.BillingMailer,
        MailglassDemoWeb.Mailers.OperationsMailer
      ]
    )

    # Dev-only interactive component review surface (PROJECT D-06). Mounted strictly
    # inside this dev-only /dev scope so it is never prod-reachable (V4 access-control
    # mitigation T-118-01). Its sandbox CSS is the committed admin bundle served by
    # mailglass_admin_routes/2 above at /dev/mail/css-<md5>.
    live_storybook("/storybook", backend_module: MailglassDemoWeb.Storybook)
  end

  scope "/ops" do
    pipe_through(:browser)

    mailglass_operator_routes("/mail",
      auth: MailglassDemoWeb.AdminAuth,
      inbound_router: MailglassDemoWeb.InboundRouter,
      session: [
        subject_id: "demo_subject_id",
        tenant_id: "demo_tenant_id",
        auth_method: "demo_auth_method",
        recent_auth_at: "demo_recent_auth_at"
      ],
      unauthorized_path: "/"
    )
  end

  scope "/inbound" do
    pipe_through(:webhooks)

    post("/:tenant_id/postmark", MailglassInbound.Ingress.Plug, provider: :postmark)
    post("/:tenant_id/sendgrid", MailglassInbound.Ingress.Plug, provider: :sendgrid)
  end
end
