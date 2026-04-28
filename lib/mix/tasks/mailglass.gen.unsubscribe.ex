defmodule Mix.Tasks.Mailglass.Gen.Unsubscribe do
  use Boundary, classify_to: Mailglass

  use Mix.Task

  alias Mailglass.Config
  alias Mailglass.Compliance.UnsubscribeController

  @shortdoc "Print the Mailglass unsubscribe installation checklist"

  @moduledoc """
  Prints the read-only Mailglass unsubscribe installation checklist.

  This task copies zero files and exists to keep adopters aligned with the
  runtime RFC 8058 config and router contract.
  """

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} = OptionParser.parse(argv, strict: [])

    validate_cli!(opts, rest, invalid)
    Mix.Task.run("app.start")

    output =
      [
        heading(),
        config_section(),
        router_section(),
        preflight_section(),
        uat_section(),
        dkim_section()
      ]
      |> Enum.join("\n\n")

    Mix.shell().info(output)
  end

  defp heading do
    """
    Mailglass unsubscribe checklist

    This task intentionally copies zero files. Wire the config and router manually, then run the UAT steps below.
    """
  end

  defp config_section do
    """
    1. Compliance config

        config :mailglass, :compliance,
          endpoint: MyAppWeb.Endpoint,
          host: #{inspect(Config.compliance_host() || "unsubscribe.example.com")},
          scheme: #{inspect(Config.compliance_scheme())},
          mount_path: #{inspect(Config.compliance_mount_path())}
    """
  end

  defp router_section do
    route_path = canonical_route_path()
    base_path = canonical_base_path()

    """
    2. Router mount

        import Mailglass.Router

        scope "/" do
          pipe_through :browser
          mailglass_router_routes "#{base_path}"
        end

    Canonical route shape: #{route_path}
    This is the same contract as `import Mailglass.Router` plus `mailglass_router_routes "#{base_path}"`.
    """
  end

  defp preflight_section do
    route_path = canonical_route_path()

    lines =
      case route_preflight() do
        [] ->
          [
            "3. Route preflight",
            "",
            "No loaded Phoenix router currently claims #{route_path}. After you add the macro, it should expose both GET and POST routes."
          ]

        findings ->
          [
            "3. Route preflight",
            ""
            | Enum.map(findings, &format_preflight_line/1)
          ]
      end

    Enum.join(lines, "\n")
  end

  defp uat_section do
    route_path = canonical_route_path()

    """
    4. UAT recipe

    - Browser GET check: visit GET #{route_path} with a signed token and confirm the confirmation page renders.
    - One-click POST check: POST #{route_path} with the same token and confirm the endpoint returns 200 without redirecting.
    - Replay POST check: repeat the POST and confirm it stays idempotent.
    - No-copy check: rerun `mix mailglass.gen.unsubscribe` and confirm it still copies zero files.
    """
  end

  defp dkim_section do
    """
    5. DKIM follow-up

    Verify your ESP signs both `List-Unsubscribe` and `List-Unsubscribe-Post` in the DKIM `h=` list before calling the rollout complete.
    """
  end

  defp route_preflight do
    expected_path = canonical_route_path()

    loaded_router_modules()
    |> Enum.flat_map(fn router_module ->
      router_module
      |> router_matches(expected_path)
      |> classify_router(router_module)
    end)
  end

  defp loaded_router_modules do
    :code.all_loaded()
    |> Enum.map(&elem(&1, 0))
    |> Enum.filter(&function_exported?(&1, :__routes__, 0))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp router_matches(router_module, expected_path) do
    router_module.__routes__()
    |> Enum.filter(&(&1.path == expected_path and &1.verb in [:get, :post]))
  end

  defp classify_router([], _router_module), do: []

  defp classify_router(routes, router_module) do
    verbs = MapSet.new(Enum.map(routes, & &1.verb))
    managed? = Enum.all?(routes, &(&1.plug == UnsubscribeController))

    cond do
      managed? and MapSet.equal?(verbs, MapSet.new([:get, :post])) ->
        [{:ok, router_module, "already exposes GET and POST #{canonical_route_path()} via Mailglass.Compliance.UnsubscribeController"}]

      true ->
        [{:warning, router_module, collision_message(routes)}]
    end
  end

  defp collision_message(routes) do
    claimed_routes =
      routes
      |> Enum.map(fn route ->
        "#{route.verb |> Atom.to_string() |> String.upcase()} #{route.path} -> #{inspect(route.plug)}"
      end)
      |> Enum.join("; ")

    "claims #{claimed_routes}. Align the router so #{canonical_route_path()} is owned only by Mailglass.Compliance.UnsubscribeController for both GET and POST."
  end

  defp format_preflight_line({status, router_module, message}) do
    "[#{status}] #{inspect(router_module)} #{message}"
  end

  defp canonical_route_path do
    normalize_mount_path(Config.compliance_mount_path()) <> "/:token"
  end

  defp canonical_base_path do
    mount_path = normalize_mount_path(Config.compliance_mount_path())

    case String.trim_trailing(mount_path, "/unsubscribe") do
      "" -> "/"
      path -> path
    end
  end

  defp normalize_mount_path(path) when is_binary(path) do
    normalized =
      path
      |> String.trim()
      |> String.trim_trailing("/")
      |> String.trim_leading("/")

    "/" <> normalized
  end

  defp validate_cli!(opts, rest, invalid) do
    if opts != [] do
      Mix.raise("Unsubscribe checklist blocked: unexpected parsed options #{inspect(opts)}")
    end

    if rest != [] do
      Mix.raise(
        "Unsubscribe checklist blocked: unexpected positional arguments #{Enum.join(rest, " ")}"
      )
    end

    if invalid != [] do
      invalid_flags =
        invalid
        |> Enum.map(fn {key, _value} -> "--#{key}" end)
        |> Enum.join(", ")

      Mix.raise("Unsubscribe checklist blocked: unknown option(s) #{invalid_flags}")
    end

    :ok
  end
end
