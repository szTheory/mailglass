defmodule MailglassReferenceHostWeb.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router
  import Mailglass.Webhook.Router
  import MailglassAdmin.Router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  pipeline :mailglass_webhooks do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :mailglass_webhooks
    mailglass_webhook_routes "/webhooks"
  end

  if Application.compile_env(:mailglass_reference_host, :dev_routes, false) do
    scope "/dev" do
      pipe_through :browser
      mailglass_admin_routes "/mail"
    end
  end
end
