# Compile-guarded on Igniter (an optional dep) so a fresh mailglass install
# stays HTTP-client-agnostic. Igniter pulls req/finch/mint; gating the module
# on `Code.ensure_loaded?(Igniter.Mix.Task)` keeps consumers who don't run
# this generator from carrying that chain, and keeps the
# `mix compile --no-optional-deps` lane green. Mirrors the Oban guard in
# `Mailglass.Oban.TenancyMiddleware`. Adopters add Igniter to run this task.
if Code.ensure_loaded?(Igniter.Mix.Task) do
  defmodule Mix.Tasks.Mailglass.Gen.Mailable do
    @moduledoc """
    Scaffolds a new Mailable module and its associated HEEx template.

    ## Examples

        mix mailglass.gen.mailable Notification
        mix mailglass.gen.mailable MyApp.Mail.Welcome
    """
    use Boundary, classify_to: Mailglass
    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        schema: [],
        positional: [:mailable]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      mailable_arg = igniter.args.positional.mailable
      app_module = Igniter.Project.Application.app_module(igniter) || Test

      module_name =
        if String.contains?(mailable_arg, ".") do
          Module.concat([mailable_arg])
        else
          Module.concat([app_module, "Mail", mailable_arg])
        end

      mailable_basename = module_name |> Module.split() |> List.last()
      lowercase_name = mailable_basename |> Macro.underscore()

      module_code = """
        use Mailglass.Mailable, stream: :transactional
        import Phoenix.Component

        embed_templates "#{lowercase_name}/*"

        def #{lowercase_name}(assigns \\\\ []) do
          new()
          |> Mailglass.Message.subject("#{mailable_basename}")
          |> Mailglass.Message.html_body(#{lowercase_name}_template(assigns))
          |> Mailglass.Message.put_function(:#{lowercase_name})
        end
      """

      module_path = Igniter.Project.Module.proper_location(igniter, module_name)
      module_dir = Path.rootname(module_path)

      template_path = Path.join(module_dir, "#{lowercase_name}_template.html.heex")

      template_code =
        "<Mailglass.Components.heading>#{mailable_basename}</Mailglass.Components.heading>\n"

      igniter
      |> Igniter.Project.Module.create_module(module_name, module_code)
      |> Igniter.create_new_file(template_path, template_code)
    end
  end
end
