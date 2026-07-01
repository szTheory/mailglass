defmodule MailglassInbound.MailboxCase do
  @moduledoc since: "0.2.0"
  @moduledoc """
  The shipped `ExUnit.CaseTemplate` adopters `use` to test inbound mailboxes
  the inbound analog of outbound's `Mailglass.MailerCase`, and the
  keystone that ties the inbound Testing helpers together.

  `use MailglassInbound.MailboxCase` injects `import MailglassInbound.TestAssertions`
  and the `Fixtures`/`Test` aliases, checks out an Ecto sandbox on the adopter's
  configured repo, sets tenancy, resets the only process-global state the inbound
  fixtures touch, and tears the sandbox down on exit.

  ## Ships in `lib/` (not `test/support/`)

  Like the other inbound Testing helpers, this case template ships in the
  `mailglass_inbound` Hex package via the `files: ~w(lib …)` manifest so adopters
  can `use` it from their own suites. Because it ships in `lib/` it references
  ONLY core/runtime modules — never `Oban`, `ExAws`, or `Plug.Test` (Pitfall 6),
  so it compiles cleanly under `mix compile --no-optional-deps --warnings-as-errors`.

  ## The adopter's repo is resolved from app-env

  The sandbox is checked out on the repo resolved from
  `Application.get_env(:mailglass_inbound, :repo)`, exactly like the
  `MailglassInbound.Repo` facade. The case template NEVER references the
  package's own test repo literal — the package does not own a repo (Pitfall 1).
  Adopters configure one in `config/test.exs`:

      config :mailglass_inbound, :repo, MyApp.Repo

  If unset, setup raises with that exact instruction. (The package's own
  self-tests work because `config/test.exs` points `:repo` at the support repo
  under `test/support`.)

  ## It snapshots NO app-env

  Unlike `Mailglass.MailerCase` (which snapshots/restores its async-mode
  application-env keys so `deliver_later/2` runs inline), this case template
  writes and restores **no** application-env key. Inbound achieves synchronous
  execution **structurally**: `MailglassInbound.Test.Ingress` drives
  `MailglassInbound.Execution.execute/2` (SYNC) directly — there is no
  async-mode app-env key to flip and therefore no leak surface across tests
  The only teardown is `Sandbox.stop_owner/1`; the only
  shared-state hygiene is the per-setup ETS / process-dict reset below.

  ## Default setup

  - `Ecto.Adapters.SQL.Sandbox.start_owner!(repo)` — plain ownership checkout; the suite runs serial by default (`async: false`)
  - `Mailglass.Tenancy.put_current("test-tenant")` (unless `@tag tenant: :unset`)
  - resets `Mailglass.Webhook.Providers.SES.CertCache` (process-global ETS)
  - resets `MailglassInbound.S3Fetcher.Fake` (process-dict)
  - best-effort `Phoenix.PubSub.subscribe/2` on the **core** `Mailglass.PubSub`
    server (the inbound plug broadcasts there); the send-based capture from
    `MailglassInbound.Test.Ingress` is the primary assertion path
  - `on_exit` → `Sandbox.stop_owner/1`

  ## Supported tags

  - `@tag tenant: "acme"` — override the default `"test-tenant"`
  - `@tag tenant: :unset` — disable tenancy stamping
  - `@tag async: false` — always set; `MailboxCase` defaults serial execution

  ## Example

      defmodule MyApp.WelcomeMailboxTest do
        use MailglassInbound.MailboxCase, async: false

        test "accepts a welcome message" do
          message = Fixtures.build_inbound_message(subject: "Welcome")

          {:ok, %{outcome: %{outcome: :accept}, route: %{mailbox: MyApp.WelcomeMailbox}}} =
            Test.Ingress.receive_inbound(message, routes: my_routes())

          # ONE assertion per drive: each `assert_inbound_*` reads the captured
          # tuple with `assert_received`, which CONSUMES it from the process
          # mailbox. To run a second assertion, drive a second message (with a
          # distinct `provider_message_id` so it is a fresh receive).
          assert_inbound_received(subject: "Welcome")
        end
      end
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      import MailglassInbound.TestAssertions
      alias MailglassInbound.{Fixtures, Test}
    end
  end

  setup tags do
    # Repo resolves from app-env — never the package's own test-repo literal
    # (Pitfall 1, T-47-14). The package does not own a repo; the adopter
    # configures one in config/test.exs.
    repo =
      Application.get_env(:mailglass_inbound, :repo) ||
        raise "config :mailglass_inbound, :repo must be set for MailglassInbound.MailboxCase"

    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(repo)

    tenant_id =
      case Map.get(tags, :tenant, "test-tenant") do
        :unset -> nil
        t when is_binary(t) -> t
      end

    if tenant_id, do: Mailglass.Tenancy.put_current(tenant_id)

    # Reset the ONLY process-global state the inbound fixtures touch. Called for
    # every test (cheap, prevents cross-test bleed even for non-SES tests):
    #   CertCache — process-global ETS cert cache (T-47-16)
    #   S3Fetcher.Fake — process-dict body seam
    Mailglass.Webhook.Providers.SES.CertCache.reset()
    MailglassInbound.S3Fetcher.Fake.reset()

    # Best-effort PubSub subscription on the CORE server (the inbound plug
    # broadcasts on `Mailglass.PubSub`, NOT a nonexistent `MailglassInbound.PubSub`).
    # The send-based capture from `Test.Ingress` is the primary assertion path, so
    # a missing PubSub server (e.g. adopters who do not run one) must not fail setup.
    if tenant_id do
      try do
        Phoenix.PubSub.subscribe(
          Mailglass.PubSub,
          MailglassInbound.PubSub.Topics.inbound_record_inserted(tenant_id)
        )
      rescue
        _ -> :ok
      catch
        _, _ -> :ok
      end
    end

    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    :ok
  end
end
