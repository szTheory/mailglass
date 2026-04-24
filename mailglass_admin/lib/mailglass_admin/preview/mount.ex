defmodule MailglassAdmin.Preview.Mount do
  @moduledoc """
  `on_mount` hook the Router macro appends after any adopter-provided
  `:on_mount` hooks. Reads the whitelisted session `"mailables"` value
  populated by `MailglassAdmin.Router.__session__/2` and runs discovery
  before `MailglassAdmin.PreviewLive.mount/3` fires.

  ## Order (Phoenix LiveView 1.1)

      session callback (MailglassAdmin.Router.__session__/2)
        -> opts[:on_mount] hooks (adopter-provided, in order given)
        -> MailglassAdmin.Preview.Mount (this module)
        -> MailglassAdmin.PreviewLive.mount/3

  Adopter hooks run BEFORE this one so they can short-circuit
  (`{:halt, socket}`) without triggering discovery.

  ## v0.1 always-cont contract

  This hook returns `{:cont, socket}` unconditionally. The dev preview
  dashboard has no auth at v0.1 (CONTEXT D-01 dev-only scope). v0.5's
  prod-admin mount will ship a separate on_mount (or replace this one)
  with auth gating; keeping the v0.1 contract always-cont keeps the
  adopter-facing surface simple.

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
