# Compile-guarded on Igniter (an optional dep) so a fresh mailglass install
# stays HTTP-client-agnostic. Igniter pulls req/finch/mint; gating the module
# on `Code.ensure_loaded?(Igniter.Mix.Task)` keeps consumers who don't run
# this generator from carrying that chain, and keeps the
# `mix compile --no-optional-deps` lane green. Mirrors the Oban guard in
# `Mailglass.Oban.TenancyMiddleware`. Adopters add Igniter to run this task.
if Code.ensure_loaded?(Igniter.Mix.Task) do
  defmodule Mix.Tasks.Mailglass.Gen.InboundRouter do
    @shortdoc "Scaffolds a new MailglassInbound.Router module"

    @moduledoc """
    Scaffolds a new inbound router module.

    The generated module declares `use MailglassInbound.Router` and a single
    sample `route/2` so the file compiles and serves as a copy-edit starting
    point. Add real routes with `mix mailglass.gen.inbound_route` or by editing
    the file directly.

    ## Examples

        mix mailglass.gen.inbound_router InboundRouter
        mix mailglass.gen.inbound_router MyApp.InboundRouter

    `--dry-run` is supported as the framework-provided global switch (it is *not*
    in this task's option schema); it previews the diff and writes nothing.
    """

    use Boundary, classify_to: Mailglass
    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        schema: [],
        positional: [:router]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      router_arg = igniter.args.positional.router
      app_module = Igniter.Project.Application.app_module(igniter) || Test

      module_name =
        if String.contains?(router_arg, ".") do
          Module.concat([router_arg])
        else
          Module.concat([app_module, router_arg])
        end

      Igniter.Project.Module.create_module(igniter, module_name, router_body())
    end

    defp router_body do
      """
      use MailglassInbound.Router

      # Routes are matched top-to-bottom, first-match-wins. Replace this sample
      # route with your own, or add more with `mix mailglass.gen.inbound_route`.
      #
      # `SampleMailbox` is a PLACEHOLDER — it points at a module that does not
      # exist yet. Routing only stores the alias as an atom, so this file compiles,
      # but the route resolves to nothing until you create the mailbox (e.g. with
      # `mix mailglass.gen.mailbox MyApp.Inbound.Support`) and rename the route.
      route SampleMailbox, recipient: "support@example.com"
      """
    end
  end
end
