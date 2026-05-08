defmodule MailglassAdmin.TestSupport.OperatorBrowserServer do
  @moduledoc false

  alias MailglassAdmin.TestSupport.{AdminBootstrap, OperatorFixtures}
  @server_ownership_timeout 10 * 60_000

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
    AdminBootstrap.setup_all(port: port, server: true, pool: :sandbox, ensure_repo: true)

    owner = AdminBootstrap.start_server_owner!(ownership_timeout: @server_ownership_timeout)
    IO.puts(
      "[operator-browser-server] sandbox owner started — timeout=#{@server_ownership_timeout} pid=#{inspect(owner)}"
    )

    IO.puts("[operator-browser-server] AdminBootstrap done — seeding fixtures")
    OperatorFixtures.seed_browser_scenario!()

    url =
      "http://127.0.0.1:#{port}/dev/mail/operator?tenant_id=#{OperatorFixtures.tenant_id()}"

    # Diagnose-on-boot: confirm the cowboy listener is actually bound to the
    # port before we print "ready". The previous CI runs reached the "ready"
    # print but Playwright still timed out on the webServer poll, which can
    # only happen if either (a) the cowboy listener never bound, or (b) the
    # specific URL Playwright polls (/ops/browser-login) differs from what
    # the endpoint serves. The probe below opens a TCP socket to 127.0.0.1:port
    # and reports the result in the boot log.
    case :gen_tcp.connect(~c"127.0.0.1", port, [:binary, active: false], 2_000) do
      {:ok, sock} ->
        :gen_tcp.close(sock)
        IO.puts("[operator-browser-server] tcp probe OK — port #{port} is bound")

      {:error, reason} ->
        IO.puts(
          "[operator-browser-server] FAIL tcp probe — port #{port} not bound (#{inspect(reason)})"
        )
    end

    # Also probe both URL paths Playwright might be polling so we can tell
    # whether the route is wired correctly.
    for path <- ["/ops/browser-ready", "/ops/browser-login?tenant_id=browser-tenant"] do
      probe_url = "http://127.0.0.1:#{port}#{path}"

      try do
        :inets.start()
        :ssl.start()

        case :httpc.request(:get, {String.to_charlist(probe_url), []}, [autoredirect: false], []) do
          {:ok, {{_, status, _}, _, _}} ->
            IO.puts("[operator-browser-server] http probe #{path} → status #{status}")

          {:error, reason} ->
            IO.puts("[operator-browser-server] http probe #{path} → ERROR #{inspect(reason)}")
        end
      rescue
        e ->
          IO.puts("[operator-browser-server] http probe #{path} crashed: #{inspect(e)}")
      end
    end

    IO.puts("[operator-browser-server] ready at #{url}")
    Process.sleep(:infinity)
  end
end
