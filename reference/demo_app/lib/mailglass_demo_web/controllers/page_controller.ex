defmodule MailglassDemoWeb.PageController do
  use Phoenix.Controller, formats: [:html]

  alias MailglassDemo.DemoData
  def health(conn, _params), do: text(conn, "ok")

  def home(conn, _params) do
    summary = DemoData.summary()

    html(conn, """
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Mailglass Demo</title>
        <style>
          :root {
            --ink: #0d1b2a;
            --paper: #f8fbfd;
            --mist: #eaf6fb;
            --glass: #277b96;
            --ice: #a6eaf2;
            --slate: #5c6b7a;
            --line: rgba(13, 27, 42, 0.14);
          }
          * { box-sizing: border-box; }
          body {
            margin: 0;
            color: var(--ink);
            background:
              linear-gradient(90deg, rgba(39,123,150,.08) 1px, transparent 1px),
              linear-gradient(0deg, rgba(39,123,150,.08) 1px, transparent 1px),
              var(--paper);
            background-size: 28px 28px;
            font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          }
          main { max-width: 1120px; margin: 0 auto; padding: 56px 24px 72px; }
          .mast { display: grid; gap: 18px; grid-template-columns: minmax(0, 1.3fr) minmax(280px, .7fr); align-items: end; }
          h1 { margin: 0; max-width: 760px; font-size: clamp(2.4rem, 5vw, 5.4rem); line-height: .94; letter-spacing: 0; }
          .sub { margin: 0; color: var(--slate); font-size: 1.02rem; line-height: 1.6; }
          .panel { border: 1px solid var(--line); background: rgba(248,251,253,.86); border-radius: 8px; padding: 18px; box-shadow: 0 20px 60px rgba(13,27,42,.08); }
          .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin: 34px 0; }
          .stat { border: 1px solid var(--line); border-radius: 8px; background: var(--mist); padding: 16px; }
          .num { display: block; font-size: 2rem; font-weight: 800; }
          .label { color: var(--slate); font-size: .78rem; text-transform: uppercase; letter-spacing: .08em; }
          .grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 14px; }
          a.card, button.card {
            display: block;
            width: 100%;
            min-height: 170px;
            border: 1px solid var(--line);
            border-radius: 8px;
            padding: 18px;
            text-align: left;
            text-decoration: none;
            color: inherit;
            background: rgba(248,251,253,.94);
            cursor: pointer;
          }
          a.card:hover, button.card:hover { outline: 3px solid rgba(166,234,242,.74); border-color: var(--glass); }
          .kicker { font-size: .76rem; text-transform: uppercase; color: var(--glass); font-weight: 800; letter-spacing: .08em; }
          h2 { margin: 8px 0; font-size: 1.25rem; }
          .card p { margin: 0; color: var(--slate); line-height: 1.5; }
          form { margin: 0; }
          @media (max-width: 820px) {
            .mast, .grid { grid-template-columns: 1fr; }
            .stats { grid-template-columns: repeat(2, 1fr); }
          }
        </style>
      </head>
      <body>
        <main>
          <section class="mast">
            <div>
              <p class="kicker">Northstar Ops · B2B SaaS demo</p>
              <h1>Northstar Ops</h1>
            </div>
            <div class="panel">
              <p class="sub">Tenant <strong>northstar</strong> contains deterministic preview, delivery, suppression, inbound record, routing trace, and replay evidence.</p>
              <p class="sub">What to inspect: invite and sign-in, receipt and payment failure, usage alert and suppression, support reply, refund request, spam reject, no-match routing, and stored-truth replay.</p>
            </div>
          </section>

          <section class="stats" aria-label="Seeded demo data">
            <div class="stat"><span class="num">#{summary.deliveries}</span><span class="label">Deliveries</span></div>
            <div class="stat"><span class="num">#{summary.events}</span><span class="label">Ledger Events</span></div>
            <div class="stat"><span class="num">#{summary.inbound}</span><span class="label">Inbound Records</span></div>
            <div class="stat"><span class="num">#{summary.suppressions}</span><span class="label">Suppressions</span></div>
          </section>

          <section class="grid">
            <a class="card" href="/dev/mail">
              <span class="kicker">Preview</span>
              <h2>Preview mailables</h2>
              <p>Invite, magic link, receipt, payment failure, usage alert, and incident scenarios.</p>
            </a>
            <a class="card" href="/demo/login?return_to=/ops/mail?tenant_id=#{summary.tenant_id}">
              <span class="kicker">Outbound</span>
              <h2>Outbound operator</h2>
              <p>Delivery detail, timeline, suppression state, and exact webhook replay evidence.</p>
            </a>
            <a class="card" href="/demo/login?return_to=/ops/mail/inbound?tenant_id=#{summary.tenant_id}">
              <span class="kicker">Inbound</span>
              <h2>Inbound operator</h2>
              <p>Stored source evidence, routing trace, fresh execution, and replay lineage.</p>
            </a>
            <form method="post" action="/demo/reset">
              <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}">
              <button class="card" type="submit">
                <span class="kicker">Reset</span>
                <h2>Reset seed data</h2>
                <p>Destructive: truncates and reseeds deterministic demo evidence tables for tenant northstar.</p>
              </button>
            </form>
          </section>
        </main>
      </body>
    </html>
    """)
  end

  def login(conn, params) do
    return_to = safe_return_to(Map.get(params, "return_to"))

    conn
    |> put_session("demo_subject_id", "demo-operator")
    |> put_session("demo_tenant_id", DemoData.tenant_id())
    |> put_session("demo_auth_method", "demo")
    |> put_session("demo_recent_auth_at", DateTime.utc_now() |> DateTime.to_iso8601())
    |> redirect(to: return_to)
  end

  def reset(conn, _params) do
    DemoData.reset!()

    conn
    |> put_flash(:info, "Demo data reset.")
    |> redirect(to: "/")
  end

  def evidence_reset(conn, _params) do
    if authorized_evidence_reset?(conn) do
      DemoData.reset!()

      conn
      |> put_status(:ok)
      |> json(%{
        status: "ok",
        warning: "Destructive demo reset endpoint: truncates and reseeds demo evidence tables.",
        summary: DemoData.summary()
      })
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "forbidden"})
    end
  end

  defp safe_return_to(nil), do: default_operator_path()

  defp safe_return_to(return_to) when is_binary(return_to) do
    uri = URI.parse(return_to)

    if is_nil(uri.scheme) and is_nil(uri.host) and operator_path?(uri.path) do
      return_to
    else
      default_operator_path()
    end
  end

  defp safe_return_to(_return_to), do: default_operator_path()

  defp operator_path?("/ops/mail"), do: true
  defp operator_path?("/ops/mail/" <> _rest), do: true
  defp operator_path?(_path), do: false

  defp default_operator_path, do: "/ops/mail?tenant_id=#{DemoData.tenant_id()}"

  defp authorized_evidence_reset?(conn) do
    expected_token = System.get_env("DEMO_EVIDENCE_RESET_TOKEN")

    provided_token =
      conn
      |> Plug.Conn.get_req_header("x-mailglass-demo-reset-token")
      |> List.first()

    secure_token_match?(provided_token, expected_token)
  end

  defp secure_token_match?(provided_token, expected_token)
       when is_binary(provided_token) and is_binary(expected_token) and expected_token != "" do
    byte_size(provided_token) == byte_size(expected_token) and
      Plug.Crypto.secure_compare(provided_token, expected_token)
  end

  defp secure_token_match?(_provided_token, _expected_token), do: false
end
