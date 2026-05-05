defmodule MailglassAdmin.TestSupport.OperatorBrowserServer do
  @moduledoc false

  alias MailglassAdmin.TestSupport.{AdminBootstrap, OperatorFixtures}

  def run! do
    port =
      System.get_env("BROWSER_SERVER_PORT", "4101")
      |> String.to_integer()

    {:ok, _} = Application.ensure_all_started(:mailglass)

    AdminBootstrap.setup_all(port: port, server: true, pool: :connection, ensure_repo: true)
    OperatorFixtures.seed_browser_scenario!()

    url =
      "http://127.0.0.1:#{port}/dev/mail/operator?tenant_id=#{OperatorFixtures.tenant_id()}"

    IO.puts("Operator browser server ready at #{url}")
    Process.sleep(:infinity)
  end
end
