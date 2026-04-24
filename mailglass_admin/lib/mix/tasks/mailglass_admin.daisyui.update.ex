defmodule Mix.Tasks.MailglassAdmin.Daisyui.Update do
  use Boundary, classify_to: MailglassAdmin

  @shortdoc "Refresh vendored daisyUI .js files from GitHub releases"

  @moduledoc """
  Curls the latest `daisyui.js` + `daisyui-theme.js` from the daisyUI
  GitHub releases page and writes them to `assets/vendor/`. Prepends a
  pin-comment with today's date + the source URL for CHANGELOG
  traceability per CONTEXT D-22.

  ## Usage

      mix mailglass_admin.daisyui.update

  Run from `mailglass_admin/`. After the fetch:

    1. Review the diff (`git diff assets/vendor/`).
    2. Update `CHANGELOG.md` with the new daisyUI version pin.
    3. Commit.

  Supply-chain discipline: this is the single authorized path for
  refreshing vendored daisyUI. Dependabot does NOT cover vendored
  files; maintainer review on each diff is the explicit control.

  ## Failures

  Exits via `Mix.raise/1` on:

    * HTTP status != 200 on either fetch.
    * `:httpc.request/4` error (DNS, connection refused, etc.).

  The `assets/vendor/*.js` files on disk are left untouched if the
  fetch fails — a half-written vendor tree would break the next
  `mix mailglass_admin.assets.build` invocation.
  """

  use Mix.Task

  @daisyui_release "https://github.com/saadeghi/daisyui/releases/latest/download"

  @impl Mix.Task
  def run(_argv) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    [
      {"daisyui.js", @daisyui_release <> "/daisyui.js"},
      {"daisyui-theme.js", @daisyui_release <> "/daisyui-theme.js"}
    ]
    |> Enum.each(fn {name, url} ->
      path = Path.join(["assets", "vendor", name])
      Mix.shell().info("Downloading " <> name <> " ...")

      request = {String.to_charlist(url), []}
      http_opts = [autoredirect: true]
      opts = [body_format: :binary]

      case :httpc.request(:get, request, http_opts, opts) do
        {:ok, {{_, 200, _}, _headers, body}} ->
          today = Date.utc_today() |> Date.to_iso8601()
          header = "// Fetched " <> today <> " from " <> url <> "\n"
          File.write!(path, header <> body)
          Mix.shell().info("  -> wrote " <> path)

        {:ok, {{_, status, _}, _headers, _body}} ->
          Mix.raise("Unexpected HTTP status " <> Integer.to_string(status) <> " from " <> url)

        {:error, reason} ->
          Mix.raise("Failed to fetch " <> url <> ": " <> inspect(reason))
      end
    end)

    Mix.shell().info("Done. Review diff, update CHANGELOG, commit.")
  end
end
