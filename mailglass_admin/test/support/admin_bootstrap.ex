defmodule MailglassAdmin.TestSupport.AdminBootstrap do
  @moduledoc false

  @endpoint MailglassAdmin.TestAdopter.Endpoint
  @error_html MailglassAdmin.TestAdopter.ErrorHTML
  @default_server_ownership_timeout 10 * 60_000

  def endpoint, do: @endpoint

  def setup_all(opts \\ []) do
    {:ok, _} = Application.ensure_all_started(:phoenix)
    if Keyword.get(opts, :ensure_repo, false), do: ensure_repo_started!(opts)
    ensure_test_app_path!()
    configure_endpoint(opts)
    start_endpoint!()
    ensure_endpoint_config_table!()
    :ok
  end

  def configure_endpoint(opts \\ []) do
    port = Keyword.get(opts, :port, 4002)
    server = Keyword.get(opts, :server, false)

    Application.put_env(
      :mailglass_admin,
      @endpoint,
      http: [ip: {127, 0, 0, 1}, port: port],
      server: server,
      secret_key_base: String.duplicate("mailglass_admin_test_secret_key_base_0", 2),
      live_view: [signing_salt: "mailglass_admin_test_signing_salt_0123"],
      pubsub_server: Mailglass.PubSub,
      render_errors: [formats: [html: @error_html], layout: false]
    )
  end

  def start_endpoint! do
    case Process.whereis(@endpoint) do
      nil -> start_unlinked_endpoint!()
      _pid -> {:ok, @endpoint}
    end
  end

  def ensure_endpoint_config_table! do
    if endpoint_config_ready?() do
      :ok
    else
      restart_endpoint!()

      unless endpoint_config_ready?() do
        raise "#{inspect(@endpoint)} started without its Phoenix endpoint config table"
      end

      :ok
    end
  end

  def build_conn do
    ensure_endpoint_config_table!()
    Phoenix.ConnTest.build_conn()
  end

  def ensure_repo_started!(opts \\ []) do
    core_migrations_path =
      :code.priv_dir(:mailglass)
      |> Path.join("repo/migrations")

    # Inbound migrations land in the SAME admin test DB so the operator/preview
    # browser surface can query inbound rows (InboundRecord/ExecutionRun/replay)
    # against MailglassAdmin.TestRepo — config :mailglass_inbound, :repo,
    # MailglassAdmin.TestRepo (config/test.exs). Mirrors test/test_helper.exs;
    # without it the OperatorBrowserServer crashes on the first inbound query
    # (relation "mailglass_inbound_replay_runs" does not exist).
    inbound_migrations_path =
      :code.priv_dir(:mailglass_inbound)
      |> Path.join("repo/migrations")

    test_repo_config = Application.get_env(:mailglass, MailglassAdmin.TestRepo)
    pool_mode = Keyword.get(opts, :pool, :sandbox)

    runtime_pool =
      case pool_mode do
        :connection -> DBConnection.ConnectionPool
        _ -> Ecto.Adapters.SQL.Sandbox
      end

    Application.put_env(
      :mailglass,
      MailglassAdmin.TestRepo,
      Keyword.put(test_repo_config, :pool, runtime_pool)
    )

    {:ok, _, _} =
      Ecto.Migrator.with_repo(MailglassAdmin.TestRepo, fn repo ->
        Ecto.Migrator.run(repo, core_migrations_path, :up, all: true, log: false)
        Ecto.Migrator.run(repo, inbound_migrations_path, :up, all: true, log: false)
      end)

    Application.put_env(:mailglass, MailglassAdmin.TestRepo, test_repo_config)

    case Process.whereis(MailglassAdmin.TestRepo) do
      nil ->
        {:ok, _pid} = MailglassAdmin.TestRepo.start_link()

      _pid ->
        :ok
    end

    MailglassAdmin.TestSupport.CitextProbe.run([])

    if pool_mode == :sandbox do
      Ecto.Adapters.SQL.Sandbox.mode(MailglassAdmin.TestRepo, :manual)
    end
  end

  def start_server_owner!(opts \\ []) do
    Ecto.Adapters.SQL.Sandbox.start_owner!(
      MailglassAdmin.TestRepo,
      shared: true,
      ownership_timeout: Keyword.get(opts, :ownership_timeout, @default_server_ownership_timeout)
    )
  end

  defp ensure_test_app_path! do
    ebin_dir = Path.expand("../../_build/test/lib/mailglass_admin/ebin", __DIR__)
    priv_dir = Path.expand("../../_build/test/lib/mailglass_admin/priv", __DIR__)
    source_priv_dir = Path.expand("../../priv", __DIR__)
    app_file = Path.join(ebin_dir, "mailglass_admin.app")

    File.mkdir_p!(ebin_dir)

    unless File.exists?(app_file) do
      File.write!(app_file, "{application, mailglass_admin, [{vsn, \"0.0.0\"}]}.\n")
    end

    unless File.exists?(priv_dir) do
      _ = File.ln_s(source_priv_dir, priv_dir)
    end

    :code.add_patha(String.to_charlist(ebin_dir))
  end

  defp endpoint_config_ready? do
    _render_errors = @endpoint.config(:render_errors)
    true
  rescue
    ArgumentError -> false
  end

  defp restart_endpoint! do
    if pid = Process.whereis(@endpoint) do
      Process.exit(pid, :kill)
      wait_until_endpoint_stopped()
    end

    case start_unlinked_endpoint!() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  defp start_unlinked_endpoint! do
    case @endpoint.start_link() do
      {:ok, pid} = result ->
        Process.unlink(pid)
        result

      other ->
        other
    end
  end

  defp wait_until_endpoint_stopped(attempts \\ 50)
  defp wait_until_endpoint_stopped(0), do: :ok

  defp wait_until_endpoint_stopped(attempts) do
    if Process.whereis(@endpoint) do
      Process.sleep(10)
      wait_until_endpoint_stopped(attempts - 1)
    else
      :ok
    end
  end
end
