defmodule Mailglass.Installer.Conflict do
  @moduledoc """
  Conflict sidecar writer used when installer changes cannot be applied safely.
  """

  @sidecar_prefix ".mailglass_conflict_"

  @doc """
  Writes a merge sidecar for a conflicting target path.
  """
  @spec write_sidecar(String.t(), atom() | String.t(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def write_sidecar(target_path, reason, proposed_contents, opts \\ []) do
    reason_value = to_string(reason)
    token = conflict_token(target_path, reason_value, proposed_contents)
    base = Path.basename(target_path) |> sanitize_token()
    reason_token = sanitize_token(reason_value)
    sidecar_name = "#{@sidecar_prefix}#{base}_#{reason_token}_#{token}.patch"
    sidecar_dir = Keyword.get(opts, :sidecar_dir, Path.dirname(target_path))
    sidecar_path = Path.join(sidecar_dir, sidecar_name)

    if Keyword.get(opts, :dry_run, false) do
      {:ok, sidecar_path}
    else
      sidecar_contents = sidecar_contents(target_path, reason_value, proposed_contents)

      with :ok <- File.mkdir_p(sidecar_dir),
           :ok <- File.write(sidecar_path, sidecar_contents) do
        {:ok, sidecar_path}
      else
        {:error, failure_reason} ->
          {:error, {:conflict_sidecar_write_failed, sidecar_path, failure_reason}}
      end
    end
  end

  @spec conflict_token(String.t(), String.t(), String.t()) :: String.t()
  defp conflict_token(target_path, reason, proposed_contents) do
    "#{target_path}|#{reason}|#{proposed_contents}"
    |> Mailglass.Installer.Manifest.hash()
    |> binary_part(0, 12)
  end

  @spec sanitize_token(String.t()) :: String.t()
  defp sanitize_token(value) do
    value
    |> String.replace(~r/[^a-zA-Z0-9]+/, "_")
    |> String.trim("_")
    |> case do
      "" -> "unknown"
      token -> token
    end
  end

  @spec sidecar_contents(String.t(), String.t(), String.t()) :: String.t()
  defp sidecar_contents(target_path, reason, proposed_contents) do
    """
    # mailglass conflict sidecar
    # target: #{target_path}
    # reason: #{reason}
    # merge: apply the proposal manually, then rerun mix mailglass.install

    #{String.trim_trailing(proposed_contents)}
    """
  end
end
