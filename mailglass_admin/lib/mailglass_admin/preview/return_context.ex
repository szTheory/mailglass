defmodule MailglassAdmin.Preview.ReturnContext do
  @moduledoc false

  # Closed-set return context for Preview -> operator-surface navigation
  # (Phase 177, UXF-10).
  #
  # An operator surface (Health, Deliveries, Inbound) mints two internal query
  # params on its Preview link: `return_surface` and `return_tenant_id`. Preview
  # never reads a URL from the request. The Back destination is rebuilt from the
  # host's configured navigation entry for the named surface, with the opaque
  # tenant id substituted into that entry's own query. Anything outside the
  # closed set resolves to `nil` (direct entry: no Back link, no error UI).
  #
  # Every function here is total. The surface is compared as a string, so no
  # atom is ever created from request input, and nothing in this module emits
  # diagnostics: the tenant id appears only as a percent-encoded query value
  # inside an href.

  @surfaces ~w(overview deliveries inbound)
  @max_id_bytes 255

  @nav_keys %{
    "overview" => :overview_path,
    "deliveries" => :deliveries_path,
    "inbound" => :inbound_path
  }

  @labels %{
    "overview" => "Back to Health",
    "deliveries" => "Back to Deliveries",
    "inbound" => "Back to Inbound"
  }

  @type t :: %{
          surface: String.t(),
          tenant_id: String.t(),
          href: String.t(),
          query_pairs: [{String.t(), String.t()}]
        }

  @doc """
  Validates the request params against the host navigation and returns the
  return context, or `nil` when the request carries no usable context.
  """
  @spec resolve(map(), map() | nil) :: t() | nil
  def resolve(%{"return_surface" => surface, "return_tenant_id" => tenant_id}, navigation)
      when is_binary(surface) and is_binary(tenant_id) and surface in @surfaces do
    with true <- valid_tenant_id?(tenant_id),
         href when is_binary(href) <- surface_href(navigation, surface, tenant_id) do
      %{
        surface: surface,
        tenant_id: tenant_id,
        href: href,
        query_pairs: [{"return_surface", surface}, {"return_tenant_id", tenant_id}]
      }
    else
      _ -> nil
    end
  end

  def resolve(_params, _navigation), do: nil

  @doc "Query pairs that carry the context across Preview-internal URLs."
  @spec query_pairs(t() | nil) :: [{String.t(), String.t()}]
  def query_pairs(%{query_pairs: pairs}) when is_list(pairs), do: pairs
  def query_pairs(_context), do: []

  @doc """
  Appends `pairs` to the query of `path`. An empty list returns `path`
  unchanged, so direct-entry URLs stay byte-identical.
  """
  @spec append_query(String.t(), list()) :: String.t()
  def append_query(path, []), do: path

  def append_query(path, pairs) when is_binary(path) and is_list(pairs) do
    uri = URI.parse(path)
    existing = uri.query |> Kernel.||("") |> URI.query_decoder() |> Enum.to_list()
    URI.to_string(%{uri | query: URI.encode_query(existing ++ pairs)})
  rescue
    ArgumentError -> path
  end

  @doc """
  Builds the host-configured entry for `surface` with `tenant_id` replaced in
  place (never added as a second `tenant_id` key). Returns `nil` when the entry
  is missing or is not a local absolute path.
  """
  @spec surface_href(map() | nil, String.t(), String.t()) :: String.t() | nil
  def surface_href(navigation, surface, tenant_id)
      when is_binary(surface) and is_binary(tenant_id) do
    with key when not is_nil(key) <- Map.get(@nav_keys, surface),
         path when is_binary(path) <- navigation_path(navigation, key),
         true <- local_path?(path) do
      put_tenant(path, tenant_id)
    else
      _ -> nil
    end
  rescue
    ArgumentError -> nil
  end

  def surface_href(_navigation, _surface, _tenant_id), do: nil

  @doc """
  The Preview link an operator surface renders. The context is minted only when
  an Account is selected and the configured Preview path is a local absolute
  path, so an Account id never leaves for another origin.
  """
  @spec operator_preview_href(String.t() | nil, atom(), String.t() | nil) :: String.t() | nil
  def operator_preview_href(preview_path, active, selected_tenant_id)
      when active in [:overview, :deliveries, :inbound] do
    if valid_tenant_id?(selected_tenant_id) and local_path?(preview_path) do
      append_query(preview_path, [
        {"return_surface", Atom.to_string(active)},
        {"return_tenant_id", selected_tenant_id}
      ])
    else
      preview_path
    end
  end

  def operator_preview_href(preview_path, _active, _selected_tenant_id), do: preview_path

  @doc "True only for a local absolute path: no scheme, host, `//` prefix or backslash."
  @spec local_path?(term()) :: boolean()
  def local_path?("/" <> _ = path) when is_binary(path) do
    String.valid?(path) and
      not String.starts_with?(path, "//") and
      not String.contains?(path, "\\") and
      not Regex.match?(~r/\p{Cc}/u, path) and
      match?(%URI{scheme: nil, host: nil}, URI.parse(path))
  end

  def local_path?(_path), do: false

  @doc "True for a non-blank, valid UTF-8, control-free id of 1..255 bytes."
  @spec valid_tenant_id?(term()) :: boolean()
  def valid_tenant_id?(id) when is_binary(id) do
    byte_size(id) in 1..@max_id_bytes//1 and
      String.valid?(id) and
      String.trim(id) != "" and
      not Regex.match?(~r/\p{Cc}/u, id)
  end

  def valid_tenant_id?(_id), do: false

  @doc "Back link label for a closed-set surface. Never interpolates request text."
  @spec back_label(String.t()) :: String.t()
  def back_label(surface) when is_binary(surface), do: Map.get(@labels, surface, "Back")
  def back_label(_surface), do: "Back"

  defp navigation_path(navigation, key) when is_map(navigation) do
    case Map.get(navigation, key) || Map.get(navigation, Atom.to_string(key)) do
      path when is_binary(path) and path != "" -> path
      _ -> nil
    end
  end

  defp navigation_path(_navigation, _key), do: nil

  defp put_tenant(path, tenant_id) do
    uri = URI.parse(path)

    pairs =
      uri.query
      |> Kernel.||("")
      |> URI.query_decoder()
      |> Enum.to_list()
      |> List.keystore("tenant_id", 0, {"tenant_id", tenant_id})

    URI.to_string(%{uri | query: URI.encode_query(pairs)})
  end
end
