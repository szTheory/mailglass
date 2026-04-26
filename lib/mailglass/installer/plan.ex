defmodule Mailglass.Installer.Plan do
  @moduledoc """
  Deterministic installer plan builder.

  Resolves the host app's OTP name (e.g. `:my_app`) by reading `mix.exs`
  from the current working directory, then substitutes that name into
  every Operation path so the installer patches the adopter's actual
  files instead of literal `lib/my_app/...` placeholders.
  """

  alias Mailglass.Installer.Operation
  alias Mailglass.Installer.Templates

  @doc """
  Builds the installer operation list for the current host app context.

  The OTP app name is resolved in this order:

  1. `opts[:otp_app]` (explicit override; used by tests)
  2. `context[:otp_app]` (also for tests)
  3. `mix.exs` in `File.cwd!()` (real adopter use)
  4. fallback to `:my_app` (preserves prior behavior if mix.exs is absent)
  """
  @spec build(keyword(), map()) :: [Operation.t()]
  def build(opts, context \\ %{}) do
    no_admin? = Keyword.get(opts, :no_admin, false)
    otp_app = resolve_otp_app(opts, context)
    app_module = otp_app_to_module(otp_app)
    otp_app_str = to_string(otp_app)
    web_dir = otp_app_str <> "_web"

    template_opts = [app_module: app_module]

    oban_available? =
      Map.get(context, :oban_available?, Mailglass.OptionalDeps.Oban.available?())

    base_ops = [
      %Operation{
        kind: :create_file,
        path: "lib/#{otp_app_str}/mail_context.ex",
        payload: Templates.mail_context_module(template_opts)
      },
      %Operation{
        kind: :create_file,
        path: "lib/#{otp_app_str}/mail/default_mailable.ex",
        payload: Templates.default_mailable(template_opts)
      },
      %Operation{
        kind: :create_file,
        path: "lib/#{web_dir}/components/layouts/mailglass.html.heex",
        payload: Templates.default_layout()
      },
      %Operation{
        kind: :ensure_block,
        path: "config/runtime.exs",
        payload: %{
          start_marker: Templates.runtime_block_start(),
          end_marker: Templates.runtime_block_end(),
          body: Templates.runtime_config_body(),
          anchor: "import Config"
        }
      },
      %Operation{
        kind: :run_task,
        path: "mix mailglass.gen.migration",
        payload: %{task: "mailglass.gen.migration", args: []}
      }
    ]

    base_ops
    |> maybe_add_router_mount(no_admin?, web_dir, template_opts)
    |> add_webhook_mount(web_dir, template_opts)
    |> add_webhook_endpoint_parser(web_dir)
    |> maybe_add_oban_worker(oban_available?, otp_app_str, template_opts)
  end

  @doc """
  Resolves the host OTP app name. Public so the mix task can pass the
  result through; tests can also call it directly to assert behaviour.

  Reads `mix.exs` in `File.cwd!()` and extracts the `app: :foo` keyword.
  Returns the atom (e.g. `:my_app`). Falls back to `:my_app` if the
  file is absent or the field can't be parsed — preserves prior
  hardcoded-placeholder behaviour rather than crashing.
  """
  @spec detect_otp_app() :: atom()
  def detect_otp_app do
    mix_path = Path.join(File.cwd!(), "mix.exs")

    with true <- File.exists?(mix_path),
         contents when is_binary(contents) <- File.read!(mix_path),
         [_, app] <- Regex.run(~r/app:\s*:([a-z_][a-z0-9_]*)/, contents) do
      String.to_atom(app)
    else
      _ -> :my_app
    end
  end

  defp resolve_otp_app(opts, context) do
    cond do
      app = Keyword.get(opts, :otp_app) -> app
      app = Map.get(context, :otp_app) -> app
      true -> detect_otp_app()
    end
  end

  defp otp_app_to_module(otp_app) do
    otp_app
    |> to_string()
    |> Macro.camelize()
  end

  defp maybe_add_router_mount(ops, true, _web_dir, _template_opts), do: ops

  defp maybe_add_router_mount(ops, false, web_dir, template_opts) do
    ops ++
      [
        %Operation{
          kind: :ensure_snippet,
          path: "lib/#{web_dir}/router.ex",
          payload: %{
            anchor: Templates.router_anchor(),
            snippet: Templates.router_mount_snippet(template_opts)
          }
        }
      ]
  end

  defp maybe_add_oban_worker(ops, true, otp_app_str, template_opts) do
    ops ++
      [
        %Operation{
          kind: :create_file,
          path: "lib/#{otp_app_str}/mail/worker.ex",
          payload: Templates.oban_worker_stub(template_opts)
        }
      ]
  end

  defp maybe_add_oban_worker(ops, false, _otp_app_str, _template_opts), do: ops

  defp add_webhook_mount(ops, web_dir, template_opts) do
    ops ++
      [
        %Operation{
          kind: :ensure_snippet,
          path: "lib/#{web_dir}/router.ex",
          payload: %{
            anchor: Templates.router_anchor(),
            snippet: Templates.webhook_mount_snippet(template_opts)
          }
        }
      ]
  end

  defp add_webhook_endpoint_parser(ops, web_dir) do
    ops ++
      [
        %Operation{
          kind: :ensure_block,
          path: "lib/#{web_dir}/endpoint.ex",
          payload: %{
            start_marker: Templates.endpoint_webhook_block_start(),
            end_marker: Templates.endpoint_webhook_block_end(),
            body: Templates.endpoint_webhook_parser_body(),
            anchor: "use Phoenix.Endpoint"
          }
        }
      ]
  end
end
