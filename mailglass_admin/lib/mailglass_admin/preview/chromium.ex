defmodule MailglassAdmin.Preview.Chromium do
  @moduledoc """
  Deterministic Chromium CLI wrapper for preview screenshot capture.
  """

  @binary_env "MAILGLASS_ADMIN_CHROMIUM_BIN"
  @binary_candidates [
    "chromium",
    "chromium-browser",
    "google-chrome",
    "google-chrome-stable",
    "chrome",
    "chromium-headless-shell"
  ]

  @default_height 2400
  @default_virtual_time_budget 4_000
  @default_timeout 30_000

  @type error ::
          {:binary_not_found, [String.t()]}
          | {:command_failed, non_neg_integer(), String.t()}

  @spec capture(String.t(), String.t(), 375 | 768 | 1024, keyword()) :: :ok | {:error, error()}
  def capture(url, output_path, width, opts \\ [])
      when is_binary(url) and is_binary(output_path) and width in [375, 768, 1024] do
    case discover_binary() do
      nil ->
        {:error, {:binary_not_found, @binary_candidates}}

      binary ->
        args =
          build_args(
            url,
            output_path,
            width,
            Keyword.get(opts, :height, @default_height),
            Keyword.get(opts, :virtual_time_budget, @default_virtual_time_budget)
          )

        {output, exit_code} =
          System.cmd(binary, args,
            stderr_to_stdout: true,
            timeout: Keyword.get(opts, :timeout, @default_timeout)
          )

        if exit_code == 0 do
          :ok
        else
          {:error, {:command_failed, exit_code, String.trim(output)}}
        end
    end
  end

  @spec binary_env() :: String.t()
  def binary_env, do: @binary_env

  @spec binary_candidates() :: [String.t()]
  def binary_candidates, do: @binary_candidates

  @spec discover_binary() :: String.t() | nil
  def discover_binary do
    System.get_env(@binary_env)
    |> case do
      value when is_binary(value) and value != "" ->
        value

      _ ->
        Enum.find_value(@binary_candidates, &System.find_executable/1)
    end
  end

  @spec build_args(String.t(), String.t(), 375 | 768 | 1024, pos_integer(), pos_integer()) :: [String.t()]
  def build_args(url, output_path, width, height, virtual_time_budget)
      when is_binary(url) and is_binary(output_path) and width in [375, 768, 1024] and
             is_integer(height) and height > 0 and is_integer(virtual_time_budget) and
             virtual_time_budget > 0 do
    [
      "--headless",
      "--disable-gpu",
      "--hide-scrollbars",
      "--run-all-compositor-stages-before-draw",
      "--virtual-time-budget=#{virtual_time_budget}",
      "--window-size=#{width},#{height}",
      "--screenshot=#{output_path}",
      url
    ]
  end
end
