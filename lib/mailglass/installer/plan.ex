defmodule Mailglass.Installer.Plan do
  @moduledoc """
  Deterministic installer plan builder.
  """

  alias Mailglass.Installer.Operation
  alias Mailglass.Installer.Templates

  @doc """
  Builds the installer operation list for the current host app context.
  """
  @spec build(keyword(), map()) :: [Operation.t()]
  def build(opts, context \\ %{}) do
    no_admin? = Keyword.get(opts, :no_admin, false)
    template_opts = [app_module: Keyword.get(opts, :app_module, "MyApp")]

    oban_available? =
      Map.get(context, :oban_available?, Mailglass.OptionalDeps.Oban.available?())

    base_ops = [
      %Operation{
        kind: :create_file,
        path: "lib/my_app/mail_context.ex",
        payload: Templates.mail_context_module(template_opts)
      },
      %Operation{
        kind: :create_file,
        path: "lib/my_app/mail/default_mailable.ex",
        payload: Templates.default_mailable(template_opts)
      },
      %Operation{
        kind: :create_file,
        path: "lib/my_app_web/components/layouts/mailglass.html.heex",
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
    |> maybe_add_router_mount(no_admin?, template_opts)
    |> maybe_add_oban_worker(oban_available?, template_opts)
  end

  defp maybe_add_router_mount(ops, true, _template_opts), do: ops

  defp maybe_add_router_mount(ops, false, template_opts) do
    ops ++
      [
        %Operation{
          kind: :ensure_snippet,
          path: "lib/my_app_web/router.ex",
          payload: %{
            anchor: Templates.router_anchor(),
            snippet: Templates.router_mount_snippet(template_opts)
          }
        }
      ]
  end

  defp maybe_add_oban_worker(ops, true, template_opts) do
    ops ++
      [
        %Operation{
          kind: :create_file,
          path: "lib/my_app/mail/worker.ex",
          payload: Templates.oban_worker_stub(template_opts)
        }
      ]
  end

  defp maybe_add_oban_worker(ops, false, _template_opts), do: ops
end
