defmodule Mailglass.AdminCase do
  @moduledoc """
  Test case template for admin LiveView tests (TEST-02).

  Phase 3 ships this skeleton. Phase 5 (PREV-01..06) extends with:
  - `Phoenix.LiveViewTest` helpers for LiveView mounting + interaction
  - `mailglass_admin` endpoint stub + session cookie fixtures
  - Device width / dark mode toggle assertion helpers
  - Mailable auto-discovery test utilities

  Inherits the full `Mailglass.MailerCase` setup:
  - Ecto sandbox + Fake adapter + Tenancy stamp + PubSub subscribe + Clock freeze.
  - All `Mailglass.MailerCase` tags work (`@tag tenant:`, `@tag frozen_at:`, etc.)

  ## Usage (Phase 5+)

      defmodule MailglassAdmin.MailableSidebarLiveTest do
        use Mailglass.AdminCase, async: false

        test "sidebar lists all mailables with preview_props/0" do
          # Phase 5: use Phoenix.LiveViewTest helpers here
        end
      end
  """
  use ExUnit.CaseTemplate
  @external_resource Path.expand("../../mailglass_admin/test/support/fixtures/mailables.ex", __DIR__)

  unless Code.ensure_loaded?(MailglassAdmin.Controllers.Assets) do
    defmodule :"Elixir.MailglassAdmin.Controllers.Assets" do
      import Plug.Conn

      def init(action), do: action

      def call(conn, _action) do
        conn
        |> send_resp(404, "")
        |> halt()
      end
    end
  end

  unless Code.ensure_loaded?(MailglassAdmin.OptionalDeps.PhoenixLiveReload) do
    defmodule :"Elixir.MailglassAdmin.OptionalDeps.PhoenixLiveReload" do
      def available?, do: true
    end
  end

  for path <-
        [
          "../../mailglass_admin/lib/mailglass_admin.ex",
          "../../mailglass_admin/lib/mailglass_admin/components.ex",
          "../../mailglass_admin/lib/mailglass_admin/layouts.ex",
          "../../mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex",
          "../../mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex",
          "../../mailglass_admin/lib/mailglass_admin/preview/discovery.ex",
          "../../mailglass_admin/lib/mailglass_admin/preview/mount.ex",
          "../../mailglass_admin/lib/mailglass_admin/preview/sidebar.ex",
          "../../mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex",
          "../../mailglass_admin/lib/mailglass_admin/preview/device_frame.ex",
          "../../mailglass_admin/lib/mailglass_admin/preview/tabs.ex",
          "../../mailglass_admin/lib/mailglass_admin/preview_live.ex",
          "../../mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex",
          "../../mailglass_admin/lib/mailglass_admin/operator/detail_header.ex",
          "../../mailglass_admin/lib/mailglass_admin/operator/filters_form.ex",
          "../../mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex",
          "../../mailglass_admin/lib/mailglass_admin/operator/timeline.ex",
          "../../mailglass_admin/lib/mailglass_admin/operator_live.ex",
          "../../mailglass_admin/lib/mailglass_admin/router.ex"
        ],
      path = Path.expand(path, __DIR__) do
    Code.require_file(path)
  end

  Code.require_file("../../mailglass_admin/test/support/fixtures/mailables.ex", __DIR__)
  Code.require_file("../../mailglass_admin/test/support/endpoint_case.ex", __DIR__)
  Code.require_file("../../mailglass_admin/test/support/live_view_case.ex", __DIR__)

  unless Code.ensure_loaded?(MailglassAdmin.TestAdopter.ErrorHTML) do
    defmodule :"Elixir.MailglassAdmin.TestAdopter.ErrorHTML" do
      def render(template, _assigns) do
        Phoenix.Controller.status_message_from_template(template)
      end
    end
  end

  using opts do
    quote do
      use Mailglass.MailerCase, unquote(opts)
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      alias MailglassAdmin.TestAdopter.Router.Helpers, as: Routes
      @endpoint MailglassAdmin.TestAdopter.Endpoint
    end
  end

  setup_all do
    {:ok, _} = Application.ensure_all_started(:phoenix)

    ebin_dir = Path.expand("../../_build/test/lib/mailglass_admin/ebin", __DIR__)
    priv_dir = Path.expand("../../_build/test/lib/mailglass_admin/priv", __DIR__)
    source_priv_dir = Path.expand("../../mailglass_admin/priv", __DIR__)
    app_file = Path.join(ebin_dir, "mailglass_admin.app")

    File.mkdir_p!(ebin_dir)

    unless File.exists?(app_file) do
      File.write!(app_file, "{application, mailglass_admin, [{vsn, \"0.0.0\"}]}.\n")
    end

    unless File.exists?(priv_dir) do
      _ = File.ln_s(source_priv_dir, priv_dir)
    end

    :code.add_patha(String.to_charlist(ebin_dir))

    Application.put_env(
      :mailglass_admin,
      MailglassAdmin.TestAdopter.Endpoint,
      http: [port: 4002],
      server: false,
      secret_key_base: String.duplicate("mailglass_admin_test_secret_key_base_0", 2),
      live_view: [signing_salt: "mailglass_admin_test_signing_salt_0123"],
      pubsub_server: Mailglass.PubSub,
      render_errors: [formats: [html: MailglassAdmin.TestAdopter.ErrorHTML], layout: false]
    )

    _ = MailglassAdmin.TestAdopter.Endpoint.start_link()
    :ok
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
