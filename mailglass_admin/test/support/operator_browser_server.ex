defmodule MailglassAdmin.TestSupport.OperatorBrowserServer do
  @moduledoc false

  alias MailglassAdmin.TestSupport.{AdminBootstrap, OperatorFixtures}
  alias MailglassAdmin.TestSupport.BrowserTimeoutEvidence
  # Phase 163 protected evidence: the 11.6-minute one-worker suite outlived the
  # former 10-minute sandbox owner after two measured matrix retries, causing
  # downstream ownership failures. Keep a finite owner below the 30-minute job.
  @server_ownership_timeout 20 * 60_000

  # Step-by-step IO.puts so a CI hang surfaces the exact stage that blocks
  # (DB create, migration, endpoint start, fixtures). Without these prints
  # the lane appears to silently freeze for 120s before Playwright's
  # webServer poller times out.
  def run! do
    started_at_ms = System.monotonic_time(:millisecond)
    log_stage(started_at_ms, "booting")

    port =
      System.get_env("BROWSER_SERVER_PORT", "4101")
      |> String.to_integer()

    log_stage(started_at_ms, "starting_mailglass_app", "port=#{port}")
    {:ok, _} = Application.ensure_all_started(:mailglass)

    log_stage(started_at_ms, "mailglass_started")
    AdminBootstrap.setup_all(port: port, server: true, pool: :sandbox, ensure_repo: true)

    owner = AdminBootstrap.start_server_owner!(ownership_timeout: @server_ownership_timeout)

    log_stage(
      started_at_ms,
      "sandbox_owner_started",
      "ownership_timeout_ms=#{@server_ownership_timeout} pid=#{inspect(owner)}"
    )

    log_stage(started_at_ms, "admin_bootstrap_complete")
    OperatorFixtures.seed_browser_scenario!()
    log_stage(started_at_ms, "fixtures_seeded")

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
        log_stage(started_at_ms, "tcp_probe_ok", "port=#{port}")

      {:error, reason} ->
        log_stage(started_at_ms, "tcp_probe_failed", "reason=#{inspect(reason)}")
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
            log_stage(started_at_ms, "http_probe", "path=#{path} status=#{status}")

          {:error, reason} ->
            log_stage(
              started_at_ms,
              "http_probe_failed",
              "path=#{path} reason=#{inspect(reason)}"
            )
        end
      rescue
        e ->
          log_stage(started_at_ms, "http_probe_crashed", "path=#{path} reason=#{inspect(e)}")
      end
    end

    log_stage(started_at_ms, "ready", "url=#{url}")
    Process.sleep(:infinity)
  end

  defp log_stage(started_at_ms, stage, details \\ nil) do
    elapsed_ms = System.monotonic_time(:millisecond) - started_at_ms
    suffix = if details, do: " #{details}", else: ""

    BrowserTimeoutEvidence.record(stage, elapsed_ms)
    IO.puts("[operator-browser-server] stage=#{stage} elapsed_ms=#{elapsed_ms}#{suffix}")
  end
end
