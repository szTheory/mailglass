defmodule MailglassDemoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :mailglass_demo

  @session_options [
    store: :cookie,
    key: "_mailglass_demo_key",
    signing_salt: "mailglass-demo-session"
  ]

  plug(Plug.Static,
    at: "/",
    from: :mailglass_demo,
    gzip: false,
    only: ~w(favicon.ico robots.txt)
  )

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(MailglassDemoWeb.Router)
end
