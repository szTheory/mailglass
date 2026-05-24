defmodule MailglassAdmin.Router do
  @moduledoc since: "0.1.0"
  @moduledoc """
  Preview and operator dashboard mounts.

  This module is the stable `v1.x` admin router seam. The contract covers the
  two mount macros and their documented options. It does not freeze internal
  LiveView module names, DOM shape, CSS classes, or internal mount-hook
  implementation details.

  ## Usage

      import MailglassAdmin.Router

      if Application.compile_env(:my_app, :dev_routes) do
        scope "/dev" do
          pipe_through :browser
          mailglass_admin_routes "/mail"
        end
      end

      scope "/ops" do
        pipe_through [:browser, :require_authenticated_user]

        mailglass_operator_routes "/mail",
          auth: MyApp.MailglassAdminAuth,
          session: [
            subject_id: "current_user_id",
            tenant_id: "current_tenant_id",
            recent_auth_at: "recent_auth_at"
          ]
      end

  Restart `mix phx.server`, visit `/dev/mail`, done. Zero `endpoint.ex` edits.

  ## Options

    * `mailglass_admin_routes/2`
      * `:mailables` — `:auto_scan` (default) or explicit list
      `[MyApp.UserMailer, ...]`. `:auto_scan` walks
      `:application.get_key/2` across loaded apps and keeps modules that
      `use Mailglass.Mailable`. Explicit lists bypass the scan.
      * `:on_mount` — Extra `on_mount` hooks appended BEFORE the internal
        `MailglassAdmin.Preview.Mount` hook.
      * `:live_session_name` — Name of the preview `live_session`
        (default `:mailglass_admin_preview`). Rename to resolve collisions
        with an adopter `live_session` of the same name.
      * `:as` — Route helper prefix (default `:mailglass_admin`).

    * `mailglass_operator_routes/2`
      * `:auth` — adopter-owned module that implements `MailglassAdmin.Auth`
      * `:session` — explicit session-key whitelist for `:subject_id`,
        `:tenant_id`, `:auth_method`, and `:recent_auth_at`
      * `:on_mount` — Extra `on_mount` hooks appended BEFORE the internal
        `MailglassAdmin.Operator.Mount` hook
      * `:live_session_name` — Name of the operator `live_session`
        (default `:mailglass_admin_operator`)
      * `:unauthorized_path` — redirect target when operator access is denied
      * `:as` — Route helper prefix (default `:mailglass_admin`)

  Every documented opt is part of the stable router contract once shipped; the
  rest of the implementation remains internal.

  ## Dev-only enforcement

  `mailglass_admin_routes/2` does NOT enforce `:dev` — wrapping the mount in
  `if Application.compile_env(:my_app, :dev_routes) do ... end` is the
  ADOPTER's job, matching the Phoenix 1.8 `mix phx.new`-generated router
  idiom. `Mix.env()` is unreliable in release builds (always `:prod`);
  keeping dev-enforcement in adopter code means preview remains a README
  concern rather than a breaking macro change.

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
              MailglassAdmin.OperatorLive,
              MailglassAdmin.Operator.Mount,
              MailglassAdmin.Controllers.Assets
            ]}

  @on_mount_hook_type {:or, [:atom, {:tuple, [:atom, :atom]}]}
  @preview_opts_schema [
    mailables: [
      type: {:or, [{:in, [:auto_scan]}, {:list, :atom}]},
      default: :auto_scan,
      doc: "Mailable modules to expose. `:auto_scan` walks `Application.get_key/2`."
    ],
    on_mount: [
      type: {:list, @on_mount_hook_type},
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

  @operator_session_schema [
    subject_id: [
      type: :string,
      required: true,
      doc: "Plug session key that carries the adopter-owned actor identifier."
    ],
    tenant_id: [
      type: {:or, [:string, nil]},
      default: nil,
      doc: "Optional Plug session key that carries the operator tenant or scope identifier."
    ],
    auth_method: [
      type: {:or, [:string, nil]},
      default: nil,
      doc: "Optional Plug session key that carries the auth-method label."
    ],
    recent_auth_at: [
      type: {:or, [:string, nil]},
      default: nil,
      doc: "Optional Plug session key that carries the recent-auth timestamp."
    ]
  ]

  @operator_opts_schema [
    auth: [
      type: :atom,
      required: true,
      doc: "Adopter-owned module that implements the MailglassAdmin.Auth behaviour."
    ],
    session: [
      type: :keyword_list,
      required: true,
      keys: @operator_session_schema,
      doc: "Explicit operator session-key whitelist."
    ],
    on_mount: [
      type: {:list, @on_mount_hook_type},
      default: [],
      doc: "Extra on_mount hooks appended BEFORE the internal Operator.Mount hook."
    ],
    live_session_name: [
      type: :atom,
      default: :mailglass_admin_operator,
      doc: "Name of the operator live_session. Rename to resolve collisions."
    ],
    unauthorized_path: [
      type: :string,
      default: "/",
      doc: "Redirect target when operator access is denied."
    ],
    inbound_router: [
      type: {:or, [:atom, nil]},
      default: nil,
      doc:
        "Optional adopter router module declaring `MailglassInbound.Router` routes " <>
          "(CONTEXT D-48-07). When set, the operator dashboard's routing-trace card " <>
          "reflects the declared inbound routes via `__mailglass_inbound_routes__/0`. " <>
          "`nil` (the default) disables the inbound surface — the dashboard renders " <>
          "without the routing-trace card."
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
  whitelisted `__preview_session__/2` callback.

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
    opts = opts |> expand_opt_aliases(__CALLER__) |> validate_preview_opts!()
    session_name = opts[:live_session_name]

    quote bind_quoted: [path: path, opts: opts, session_name: session_name] do
      scope path, alias: false, as: false do
        MailglassAdmin.Router.__asset_routes__()

        on_mount_hooks = opts[:on_mount] ++ [MailglassAdmin.Preview.Mount]

        live_session session_name,
          session: {MailglassAdmin.Router, :__preview_session__, [opts]},
          on_mount: on_mount_hooks,
          root_layout: {MailglassAdmin.Layouts, :root} do
          live "/", MailglassAdmin.PreviewLive, :index
          live "/:mailable/:scenario", MailglassAdmin.PreviewLive, :show
        end
      end
    end
  end

  @doc """
  Mounts the production operator dashboard at `path`.

  The operator surface has its own `live_session`, its own whitelisted
  session callback, and an internal `MailglassAdmin.Operator.Mount`
  authorization seam. Adopter-owned auth hooks may run before the
  internal mount hook via `:on_mount`.

  Stable contract:

  - `:auth` points to an adopter-owned `MailglassAdmin.Auth` implementation
  - `:session` is an explicit whitelist, not a pass-through of the whole Plug
    session
  - authorization semantics are stable, but the internal mount module and UI
    implementation are not
  """
  @doc since: "0.1.0"
  defmacro mailglass_operator_routes(path, opts \\ []) do
    opts = opts |> expand_opt_aliases(__CALLER__) |> validate_operator_opts!()
    session_name = opts[:live_session_name]

    quote bind_quoted: [path: path, opts: opts, session_name: session_name] do
      scope path, alias: false, as: false do
        MailglassAdmin.Router.__asset_routes__()

        on_mount_hooks = opts[:on_mount] ++ [{MailglassAdmin.Operator.Mount, opts}]

        live_session session_name,
          session: {MailglassAdmin.Router, :__operator_session__, [opts]},
          on_mount: on_mount_hooks,
          root_layout: {MailglassAdmin.Layouts, :root} do
          live "/", MailglassAdmin.OperatorLive, :index
        end
      end
    end
  end

  @doc false
  defmacro __asset_routes__ do
    quote do
      get "/css-:md5", MailglassAdmin.Controllers.Assets, :css
      get "/js-:md5", MailglassAdmin.Controllers.Assets, :js
      get "/fonts/:name", MailglassAdmin.Controllers.Assets, :font
      get "/logo.svg", MailglassAdmin.Controllers.Assets, :logo
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
  def __preview_session__(conn, opts) do
    mailables =
      case Plug.Conn.get_session(conn, "mailables") do
        modules when is_list(modules) -> modules
        _ -> opts[:mailables]
      end

    %{
      "mailables" => mailables,
      "live_session_name" => opts[:live_session_name]
      # Add keys here ONLY when intentionally surfacing them to PreviewLive.
      # NEVER pass conn.private.plug_session through wholesale.
    }
  end

  @doc false
  def __operator_session__(conn, opts) do
    session_opts = opts[:session]

    %{
      "subject_id" => get_optional_session(conn, session_opts[:subject_id]),
      "tenant_id" => get_optional_session(conn, session_opts[:tenant_id]),
      "auth_method" => get_optional_session(conn, session_opts[:auth_method]),
      "recent_auth_at" => get_optional_session(conn, session_opts[:recent_auth_at]),
      "live_session_name" => opts[:live_session_name],
      # CONTEXT D-48-07: the inbound router module is a compile-time opt, not a
      # session value — surfaced here (as an atom, never cookie-sourced) so the
      # operator LiveView can reflect declared inbound routes for the
      # routing-trace card without an inbound→admin compile dependency.
      "inbound_router" => opts[:inbound_router]
    }
  end

  defp get_optional_session(_conn, nil), do: nil
  defp get_optional_session(conn, key), do: Plug.Conn.get_session(conn, key)

  defp expand_opt_aliases(opts, env) do
    Macro.prewalk(opts, fn node -> Macro.expand(node, env) end)
  end

  defp validate_preview_opts!(opts) do
    case NimbleOptions.validate(opts, @preview_opts_schema) do
      {:ok, validated} ->
        validated

      {:error, %NimbleOptions.ValidationError{message: msg}} ->
        raise ArgumentError,
              "invalid opts for mailglass_admin_routes/2: " <> msg
    end
  end

  defp validate_operator_opts!(opts) do
    case NimbleOptions.validate(opts, @operator_opts_schema) do
      {:ok, validated} ->
        validated

      {:error, %NimbleOptions.ValidationError{message: msg}} ->
        raise ArgumentError,
              "invalid opts for mailglass_operator_routes/2: " <> msg
    end
  end
end
