defmodule Mailglass.Installer.Manifest do
  @moduledoc """
  `.mailglass.toml` manifest helpers for deterministic installer reruns.
  """

  @manifest_path ".mailglass.toml"

  @type t :: %{
          installer_version: String.t(),
          last_run_at: String.t() | nil,
          paths: %{optional(String.t()) => String.t()}
        }

  @doc """
  Returns the default manifest path.
  """
  @spec default_path() :: String.t()
  def default_path, do: @manifest_path

  @doc """
  Returns a new in-memory manifest shape.
  """
  @spec new() :: t()
  def new do
    %{installer_version: installer_version(), last_run_at: nil, paths: %{}}
  end

  @doc """
  Loads a manifest from disk. Missing files return an empty manifest.
  """
  @spec load(String.t()) :: {:ok, t()} | {:error, term()}
  def load(path \\ @manifest_path) do
    case File.read(path) do
      {:ok, contents} -> {:ok, parse(contents)}
      {:error, :enoent} -> {:ok, new()}
      {:error, reason} -> {:error, {:manifest_read_failed, path, reason}}
    end
  end

  @doc """
  Writes a manifest to disk in deterministic order.
  """
  @spec write(t(), String.t()) :: :ok | {:error, term()}
  def write(manifest, path \\ @manifest_path) do
    case File.write(path, dump(manifest)) do
      :ok -> :ok
      {:error, reason} -> {:error, {:manifest_write_failed, path, reason}}
    end
  end

  @doc """
  Computes a deterministic SHA-256 hash for any binary content.
  """
  @spec hash(binary()) :: String.t()
  def hash(contents) when is_binary(contents) do
    :sha256
    |> :crypto.hash(contents)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Returns a previously tracked hash for `path`.
  """
  @spec path_hash(t(), String.t()) :: String.t() | nil
  def path_hash(%{paths: paths}, path), do: Map.get(paths, path)

  @doc """
  Inserts or updates a tracked path hash in memory.
  """
  @spec put_hash(t(), String.t(), String.t()) :: t()
  def put_hash(manifest, path, path_hash) do
    put_in(manifest, [:paths, path], path_hash)
  end

  @doc """
  Updates installer version and operation timestamp in memory.
  """
  @spec with_run_metadata(t(), keyword()) :: t()
  def with_run_metadata(manifest, opts \\ []) do
    timestamp = Keyword.get(opts, :timestamp, current_timestamp())
    version = Keyword.get(opts, :installer_version, installer_version())

    manifest
    |> Map.put(:installer_version, version)
    |> Map.put(:last_run_at, timestamp)
  end

  @spec parse(String.t()) :: t()
  defp parse(contents) do
    {manifest, _in_paths?} =
      contents
      |> String.split("\n")
      |> Enum.reduce({new(), false}, fn line, {acc, in_paths?} ->
        trimmed = String.trim(line)

        version_match = Regex.run(~r/^installer_version\s*=\s*"([^"]*)"$/, trimmed)
        timestamp_match = Regex.run(~r/^last_run_at\s*=\s*"([^"]*)"$/, trimmed)

        path_match =
          if in_paths? do
            Regex.run(~r/^"([^"]+)"\s*=\s*"([^"]*)"$/, trimmed)
          else
            nil
          end

        cond do
          trimmed == "" or String.starts_with?(trimmed, "#") ->
            {acc, in_paths?}

          trimmed == "[paths]" ->
            {acc, true}

          is_list(version_match) ->
            [_, version] = version_match
            {%{acc | installer_version: version}, in_paths?}

          is_list(timestamp_match) ->
            [_, timestamp] = timestamp_match
            {%{acc | last_run_at: blank_to_nil(timestamp)}, in_paths?}

          is_list(path_match) ->
            [_, path, path_hash] = path_match
            {put_hash(acc, path, path_hash), in_paths?}

          true ->
            {acc, in_paths?}
        end
      end)

    manifest
  end

  @spec dump(t()) :: String.t()
  defp dump(manifest) do
    header = [
      ~s(installer_version = "#{escape_toml(manifest.installer_version)}"),
      ~s(last_run_at = "#{escape_toml(manifest.last_run_at || "")}"),
      "",
      "[paths]"
    ]

    path_lines =
      manifest.paths
      |> Enum.sort_by(fn {path, _hash} -> path end)
      |> Enum.map(fn {path, path_hash} ->
        ~s("#{escape_toml(path)}" = "#{escape_toml(path_hash)}")
      end)

    Enum.join(header ++ path_lines ++ [""], "\n")
  end

  @spec blank_to_nil(String.t()) :: String.t() | nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  @spec escape_toml(String.t()) :: String.t()
  defp escape_toml(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
  end

  @spec installer_version() :: String.t()
  defp installer_version do
    case Application.spec(:mailglass, :vsn) do
      nil -> "0.1.0"
      version -> to_string(version)
    end
  end

  @spec current_timestamp() :: String.t()
  defp current_timestamp do
    System.system_time(:second)
    |> DateTime.from_unix!()
    |> DateTime.to_iso8601()
  end
end
