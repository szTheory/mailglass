defmodule MailglassAdmin.TestSupport.OperatorBrowserServer do
  @moduledoc false

  alias MailglassAdmin.TestSupport.{AdminBootstrap, OperatorFixtures}

  # Step-by-step IO.puts so a CI hang surfaces the exact stage that blocks
  # (DB create, migration, endpoint start, fixtures). Without these prints
  # the lane appears to silently freeze for 120s before Playwright's
  # webServer poller times out.
  def run! do
    IO.puts("[operator-browser-server] booting")

    port =
      System.get_env("BROWSER_SERVER_PORT", "4101")
      |> String.to_integer()

    IO.puts("[operator-browser-server] port=#{port} — starting :mailglass app")
    {:ok, _} = Application.ensure_all_started(:mailglass)

    IO.puts("[operator-browser-server] :mailglass started — running AdminBootstrap.setup_all")
    AdminBootstrap.setup_all(port: port, server: true, pool: :connection, ensure_repo: true)

    IO.puts("[operator-browser-server] AdminBootstrap done — seeding fixtures")
    OperatorFixtures.seed_browser_scenario!()

    url =
      "http://127.0.0.1:#{port}/dev/mail/operator?tenant_id=#{OperatorFixtures.tenant_id()}"

    IO.puts("[operator-browser-server] ready at #{url}")
    Process.sleep(:infinity)
  end
end
