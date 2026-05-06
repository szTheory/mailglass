defmodule MailglassAdmin.Preview.Mount do
  @moduledoc """
  `on_mount` hook the Router macro appends after any adopter-provided
  `:on_mount` hooks. Reads the whitelisted session `"mailables"` value
  populated by the router's preview session callback and runs discovery
  before the preview LiveView finishes mounting.

  ## Order (Phoenix LiveView 1.1)

      preview session callback
        -> opts[:on_mount] hooks (adopter-provided, in order given)
        -> MailglassAdmin.Preview.Mount (this module)
        -> preview LiveView mount

  Adopter hooks run BEFORE this one so they can short-circuit
  (`{:halt, socket}`) without triggering discovery.

  ## v0.1 always-cont contract

  This hook returns `{:cont, socket}` unconditionally. The dev preview
  dashboard remains discovery-only, while the production operator
  surface now uses the separate `MailglassAdmin.Operator.Mount`
  authorization hook.

  ## Boundary classification

  Submodule auto-classifies into the `MailglassAdmin` root boundary
  declared in `lib/mailglass_admin.ex`; `classify_to:` is reserved for
  mix tasks and protocol implementations and is not used here.
  """

  import Phoenix.Component, only: [assign: 3]

  alias MailglassAdmin.Preview.Discovery

  @doc """
  Runs `Discovery.discover/1` using the session-supplied `mailables`
  value and assigns `:mailables` on the socket.

  Phoenix's `on_mount` machinery passes the module as-is (no stage atom),
  so the first arg is `:default`.
  """
  @spec on_mount(atom(), map() | :not_mounted_at_router, map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()}
  def on_mount(:default, _params, session, socket) do
    mailables_opt = Map.get(session, "mailables", :auto_scan)
    mailables = Discovery.discover(mailables_opt)

    {:cont, assign(socket, :mailables, mailables)}
  end
end
