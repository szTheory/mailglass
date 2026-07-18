defmodule MailglassDemoWeb.StorybookRoutes do
  @moduledoc false

  defmacro maybe_storybook_assets do
    if Code.ensure_loaded?(PhoenixStorybook.Router) do
      quote do
        import PhoenixStorybook.Router

        scope "/" do
          storybook_assets()
        end
      end
    else
      quote(do: nil)
    end
  end

  defmacro maybe_live_storybook do
    if Code.ensure_loaded?(PhoenixStorybook.Router) do
      quote do
        import PhoenixStorybook.Router

        scope "/dev" do
          pipe_through(:browser)

          live_storybook("/storybook", backend_module: MailglassDemoWeb.Storybook)
        end
      end
    else
      quote(do: nil)
    end
  end
end

defmodule MailglassDemoWeb.Router do
  use Phoenix.Router

  import Phoenix.Controller
  import Phoenix.LiveView.Router
  import Plug.Conn
  import MailglassAdmin.Router
  require MailglassDemoWeb.StorybookRoutes

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
  # package). Dev-only because the dep is `only: :dev` — absent from test/prod
  # builds (T-118-01 mitigation).
  MailglassDemoWeb.StorybookRoutes.maybe_storybook_assets()

  scope "/dev" do
    pipe_through(:browser)

    mailglass_admin_routes("/mail",
      mailables: [
        MailglassDemoWeb.Mailers.AccountMailer,
        MailglassDemoWeb.Mailers.BillingMailer,
        MailglassDemoWeb.Mailers.OperationsMailer
      ],
      navigation: [
        overview_path: "/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar",
        deliveries_path:
          "/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar%26view%3Ddeliveries",
        inbound_path: "/demo/login?return_to=%2Fops%2Fmail%2Finbound%3Ftenant_id%3Dnorthstar"
      ]
    )
  end

  # Dev-only interactive component review surface (PROJECT D-06). Mounted strictly
  # inside this dev-only /dev scope so it is never prod-reachable (V4 access-control
  # mitigation T-118-01). Its sandbox CSS is the committed admin bundle served by
  # mailglass_admin_routes/2 above at /dev/mail/css-<md5>.
  MailglassDemoWeb.StorybookRoutes.maybe_live_storybook()

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
      navigation: [
        preview_path: "/dev/mail"
      ],
      account_labels: %{
        "northstar" => "Northstar Logistics",
        "fjordline-aps" => "Fjordline A/S",
        "helios-void" => "Helios Trial"
      },
      unauthorized_path: "/"
    )
  end

  scope "/inbound" do
    pipe_through(:webhooks)

    post("/:tenant_id/postmark", MailglassInbound.Ingress.Plug, provider: :postmark)
    post("/:tenant_id/sendgrid", MailglassInbound.Ingress.Plug, provider: :sendgrid)
  end
end
