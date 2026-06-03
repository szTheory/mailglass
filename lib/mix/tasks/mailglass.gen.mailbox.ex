# Compile-guarded on Igniter (an optional dep) so a fresh mailglass install
# stays HTTP-client-agnostic. Igniter pulls req/finch/mint; gating the module
# on `Code.ensure_loaded?(Igniter.Mix.Task)` keeps consumers who don't run
# this generator from carrying that chain, and keeps the
# `mix compile --no-optional-deps` lane green. Mirrors the Oban guard in
# `Mailglass.Oban.TenancyMiddleware`. Adopters add Igniter to run this task.
if Code.ensure_loaded?(Igniter.Mix.Task) do
  defmodule Mix.Tasks.Mailglass.Gen.Mailbox do
    @shortdoc "Scaffolds an inbound mailbox, a route stub, and a MailboxCase test stub"

    @moduledoc """
    Scaffolds an inbound mailbox and wires it into your router.

    Generates three things:

      1. A mailbox module implementing `MailglassInbound.Mailbox` with a default
         `process/1` that returns the neutral `:accept` outcome.
      2. A route stub in the configured router, inserted idempotently via the same
         helper that backs `mix mailglass.gen.inbound_route`.
      3. An ExUnit test stub that `use MailglassInbound.MailboxCase`.

    If the configured router module is not found, an actionable notice is emitted
    instead of auto-creating one — run `mix mailglass.gen.inbound_router` first.

    ## Examples

        mix mailglass.gen.mailbox MyApp.Inbound.Support
        mix mailglass.gen.mailbox MyApp.Inbound.Support --recipient support@example.com
        mix mailglass.gen.mailbox MyApp.Inbound.Support --router MyApp.InboundRouter

    ## Positional arguments

      * `mailbox` - the mailbox module to create.

    ## Options

      * `--router` - the router to add the route stub to. Defaults to `<App>.InboundRouter`.
      * `--recipient` - the recipient matcher for the route stub. Defaults to
        `<underscored-mailbox-name>@example.com`.

    `--dry-run` is supported as the framework-provided global switch (it is *not*
    in this task's option schema); it previews the diff and writes nothing.
    """

    use Boundary, classify_to: Mailglass
    use Igniter.Mix.Task

    alias Mix.Tasks.Mailglass.Gen.InboundRoute

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        schema: [router: :string, recipient: :string],
        positional: [:mailbox]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      mailbox_arg = igniter.args.positional.mailbox
      options = igniter.args.options

      mailbox = InboundRoute.parse_module(mailbox_arg)
      router = InboundRoute.router_module(igniter, options[:router])
      recipient = options[:recipient] || default_recipient(mailbox)

      # Resolve the test-file location from the source location BEFORE creating
      # the module so ordering against `create_module/3` cannot perturb the path.
      test_path =
        igniter
        |> Igniter.Project.Module.proper_location(mailbox, :source_folder)
        |> String.replace_prefix("lib/", "test/")
        |> String.replace_suffix(".ex", "_test.exs")

      test_module = test_module(mailbox)

      igniter
      |> Igniter.Project.Module.create_module(mailbox, mailbox_body())
      |> Igniter.create_new_file(test_path, test_stub_body(test_module, mailbox, router))
      # Reuse the shared idempotent add-route helper (route stub). When the router
      # is missing, the helper emits the actionable "run gen.inbound_router" notice.
      |> InboundRoute.add_route(router, mailbox, recipient: recipient)
    end

    # Conventional ExUnit test-module name: suffix `Test` on the LAST segment
    # (`Foo.Bar` -> `Foo.BarTest`), which keeps igniter from relocating the file
    # into a nested `bar/test.exs` based on a `Foo.Bar.Test` module name.
    defp test_module(mailbox) do
      mailbox
      |> Module.split()
      |> List.update_at(-1, &(&1 <> "Test"))
      |> Module.concat()
    end

    defp default_recipient(mailbox) do
      name =
        mailbox
        |> Module.split()
        |> List.last()
        |> Macro.underscore()

      "#{name}@example.com"
    end

    defp mailbox_body do
      """
      @behaviour MailglassInbound.Mailbox

      @impl MailglassInbound.Mailbox
      def process(%MailglassInbound.InboundMessage{} = _message) do
        # Inspect the message and return one of the locked mailbox outcomes:
        # :accept | :ignore | {:reject, reason} | {:bounce, reason}.
        :accept
      end
      """
    end

    defp test_stub_body(test_module, _mailbox, router) do
      """
      defmodule #{inspect(test_module)} do
        use MailglassInbound.MailboxCase

        # MailboxCase imports TestAssertions and aliases Fixtures / Test, builds an
        # %InboundMessage{} fixture, drives the real persist + route + execute path
        # via Test.Ingress, and asserts the captured outcome. Replace the body with
        # assertions for your routing and process/1 behavior.
        test "accepts an inbound message" do
          # Route through your compiled router (the `route` stub this task added to
          # #{inspect(router)}) via the `:router` option — the same `use
          # MailglassInbound.Router` module your endpoint mounts. Build a message
          # whose envelope_recipient matches the route's recipient matcher.
          #
          # message = Fixtures.build_inbound_message(subject: "hi")
          #
          # {:ok, _} =
          #   Test.Ingress.receive_inbound(message, router: #{inspect(router)})
          #
          # # Each assert_inbound_* consumes ONE captured tuple, so drive one
          # # message per assertion.
          # assert_inbound_accepted()
        end
      end
      """
    end
  end
end
