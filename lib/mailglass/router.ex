defmodule Mailglass.Router do
  @moduledoc """
  Router macro for mounting Mailglass unsubscribe endpoints in an adopter
  Phoenix router.

  ## Usage

      defmodule MyAppWeb.Router do
        use Phoenix.Router
        import Mailglass.Router

        scope "/" do
          pipe_through :browser
          mailglass_router_routes "/mailglass"
        end
      end

  Generates one GET and one POST route at the configured unsubscribe mount
  path, ending in `/:token`.

  ## Options

    * `:as` - route helper prefix. Default: `:mailglass_unsubscribe`
    * `:mount_path` - explicit absolute mount path override. Intended for
      test-only compile scenarios; normal callers should rely on
      `Mailglass.Config.compliance_mount_path/0`.
  """

  @opts_schema [
    as: [
      type: :atom,
      default: :mailglass_unsubscribe,
      doc: "Route helper prefix."
    ],
    mount_path: [
      type: {:or, [:string, nil]},
      default: nil,
      doc: "Explicit absolute mount path override for compile-time tests."
    ]
  ]

  @doc """
  Mounts the core unsubscribe GET and POST routes.
  """
  @doc since: "0.2.0"
  defmacro mailglass_router_routes(path, opts \\ []) do
    opts = validate_opts!(opts)
    configured_mount_path = normalize_mount_path(Mailglass.Config.compliance_mount_path())
    requested_mount_path = requested_mount_path(path, opts[:mount_path])
    route_path = "#{requested_mount_path}/:token"

    if is_nil(opts[:mount_path]) and requested_mount_path != configured_mount_path do
      raise ArgumentError,
            "mailglass_router_routes/2 path #{inspect(path)} expands to " <>
              "#{inspect(requested_mount_path)}, but Mailglass.Config.compliance_mount_path/0 " <>
              "is #{inspect(configured_mount_path)}"
    end

    quote bind_quoted: [route_path: route_path, as: opts[:as]] do
      Mailglass.Router.__ensure_route_available__(__MODULE__, route_path, :get)
      Mailglass.Router.__ensure_route_available__(__MODULE__, route_path, :post)
      get route_path, Mailglass.Compliance.UnsubscribeController, :show, as: as
      post route_path, Mailglass.Compliance.UnsubscribeController, :unsubscribe, as: as
    end
  end

  @doc false
  def __ensure_route_available__(router_module, route_path, verb) do
    existing_routes = Module.get_attribute(router_module, :phoenix_routes) || []

    if Enum.any?(existing_routes, &(&1.verb == verb and &1.path == route_path)) do
      raise ArgumentError,
            "cannot mount mailglass_router_routes/2 because an existing " <>
              "#{verb |> Atom.to_string() |> String.upcase()} route already claims #{route_path} " <>
              "in :phoenix_routes"
    end
  end

  defp validate_opts!(opts) do
    case NimbleOptions.validate(opts, @opts_schema) do
      {:ok, validated} ->
        validated

      {:error, %NimbleOptions.ValidationError{message: message}} ->
        raise ArgumentError, "invalid opts for mailglass_router_routes/2: " <> message
    end
  end

  defp requested_mount_path(path, nil) do
    normalize_mount_path("#{normalize_base_path(path)}/unsubscribe")
  end

  defp requested_mount_path(_path, mount_path), do: normalize_mount_path(mount_path)

  defp normalize_base_path(path) when is_binary(path) do
    path
    |> String.trim()
    |> String.trim_trailing("/")
    |> String.trim_leading("/")
    |> then(fn
      "" -> "/"
      normalized -> "/" <> normalized
    end)
  end

  defp normalize_mount_path(path) when is_binary(path) do
    path
    |> String.trim()
    |> String.trim_trailing("/")
    |> String.trim_leading("/")
    |> then(fn normalized -> "/" <> normalized end)
  end

end
