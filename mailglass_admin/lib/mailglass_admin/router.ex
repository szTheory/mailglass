defmodule MailglassAdmin.Router do
  @moduledoc """
  Dev-only preview dashboard mount.

  ## Usage

      import MailglassAdmin.Router

      if Application.compile_env(:my_app, :dev_routes) do
        scope "/dev" do
          pipe_through :browser
          mailglass_admin_routes "/mail"
        end
      end

  Restart `mix phx.server`, visit `/dev/mail`, done. Zero `endpoint.ex` edits.

  ## Options

    * `:mailables` — `:auto_scan` (default) or explicit list
      `[MyApp.UserMailer, ...]`. `:auto_scan` walks
      `:application.get_key/2` across loaded apps and keeps modules that
      `use Mailglass.Mailable`. Explicit lists bypass the scan.

    * `:on_mount` — Extra `on_mount` hooks appended BEFORE the internal
      `MailglassAdmin.Preview.Mount` hook.

    * `:live_session_name` — Name of the library-owned `live_session`
      (default `:mailglass_admin_preview`). Rename to resolve collisions
      with an adopter `live_session` of the same name.

    * `:as` — Route helper prefix (default `:mailglass_admin`).

  Every opt is a public API contract once shipped; the v0.1 schema is
  deliberately lean (four keys) per CONTEXT D-09. Added opts ship only
  when a concrete adopter asks.

  ## Dev-only enforcement

  The library does NOT enforce `:dev` — wrapping the mount in
  `if Application.compile_env(:my_app, :dev_routes) do ... end` is the
  ADOPTER's job, matching the Phoenix 1.8 `mix phx.new`-generated router
  idiom. `Mix.env()` is unreliable in release builds (always `:prod`);
  keeping dev-enforcement in adopter code means v0.5's prod-admin
  surface is a README change, not a breaking macro change.

  ## Does NOT do

    * `Mix.env()` checks in the macro body (unreliable in releases)
    * Pass `conn.private.plug_session` into LiveView assigns (would leak
      adopter cookies; `__session__/2` builds a whitelisted map)
    * Register any named GenServer (`name: __MODULE__` is banned in
      library code per CLAUDE.md)
  """

  # Plan 04 ships MailglassAdmin.Preview.Mount; Plan 05 ships
  # MailglassAdmin.Controllers.Assets; Plan 06 ships
  # MailglassAdmin.PreviewLive. Until they land, this suppresses the
  # compile-time warnings so --warnings-as-errors stays green from
  # Plan 03 onward.
  @compile {:no_warn_undefined,
            [
              MailglassAdmin.PreviewLive,
              MailglassAdmin.Preview.Mount,
              MailglassAdmin.Controllers.Assets
            ]}

  @opts_schema [
    mailables: [
      type: {:or, [{:in, [:auto_scan]}, {:list, :atom}]},
      default: :auto_scan,
      doc: "Mailable modules to expose. `:auto_scan` walks `Application.get_key/2`."
    ],
    on_mount: [
      type: {:list, :atom},
      default: [],
      doc: "Extra on_mount hooks appended BEFORE the internal Preview.Mount."
    ],
    live_session_name: [
      type: :atom,
      default: :mailglass_admin_preview,
      doc: "Name of the library-owned live_session. Rename to resolve collisions."
    ],
    as: [
      type: :atom,
      default: :mailglass_admin,
      doc: "Route helper prefix."
    ]
  ]

  @doc """
  Mounts the preview dashboard at `path`.

  Expands to a `scope` containing asset routes (compile-time served via
  `MailglassAdmin.Controllers.Assets`) and a `live_session` with
  `MailglassAdmin.PreviewLive`. Session isolation is provided by the
  whitelisted `__session__/2` callback.

  ## Example

      scope "/dev" do
        pipe_through :browser
        mailglass_admin_routes "/mail"
      end

  ## Unknown opts

  Raises `ArgumentError` at compile time with a message starting
  `invalid opts for mailglass_admin_routes/2`.
  """
  @doc since: "0.1.0"
  defmacro mailglass_admin_routes(path, opts \\ []) do
    opts = validate_opts!(opts)
    session_name = opts[:live_session_name]

    quote bind_quoted: [path: path, opts: opts, session_name: session_name] do
      scope path, alias: false, as: false do
        get "/css-:md5", MailglassAdmin.Controllers.Assets, :css
        get "/js-:md5", MailglassAdmin.Controllers.Assets, :js
        get "/fonts/:name", MailglassAdmin.Controllers.Assets, :font
        get "/logo.svg", MailglassAdmin.Controllers.Assets, :logo

        on_mount_hooks = opts[:on_mount] ++ [MailglassAdmin.Preview.Mount]

        live_session session_name,
          session: {MailglassAdmin.Router, :__session__, [opts]},
          on_mount: on_mount_hooks,
          root_layout: {MailglassAdmin.Layouts, :root} do
          live "/", MailglassAdmin.PreviewLive, :index
          live "/:mailable/:scenario", MailglassAdmin.PreviewLive, :show
        end
      end
    end
  end

  # Whitelisted session callback — the CONTEXT D-08 / T-05-01 load-bearing
  # security seam. Called by Phoenix `live_session` machinery on every
  # mount. The first arg is bound as `_conn` (underscore prefix) so any
  # future edit that tries to call `get_session(_conn, ...)` fails compile
  # — defense-in-depth against cookie pass-through regressions.
  #
  # Public because `live_session session: {M, F, A}` requires an exported
  # function, but `@doc false` because adopter code should never call it
  # directly.
  @doc false
  def __session__(_conn, opts) do
    %{
      "mailables" => opts[:mailables],
      "live_session_name" => opts[:live_session_name]
      # Add keys here ONLY when intentionally surfacing them to PreviewLive.
      # NEVER pass conn.private.plug_session through.
    }
  end

  defp validate_opts!(opts) do
    case NimbleOptions.validate(opts, @opts_schema) do
      {:ok, validated} ->
        validated

      {:error, %NimbleOptions.ValidationError{message: msg}} ->
        raise ArgumentError,
              "invalid opts for mailglass_admin_routes/2: " <> msg
    end
  end
end
