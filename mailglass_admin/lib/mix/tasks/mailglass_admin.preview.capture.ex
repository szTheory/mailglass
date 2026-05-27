defmodule Mix.Tasks.MailglassAdmin.Preview.Capture do
  use Boundary, classify_to: MailglassAdmin
  use Mix.Task

  alias MailglassAdmin.Preview.{CaptureMatrix, CaptureState, Chromium, Discovery}

  @shortdoc "Capture deterministic preview screenshots across scenario/width/theme matrix"

  @moduledoc """
  Capture deterministic preview screenshots from `MailglassAdmin.PreviewLive`.

  The workflow is maintainer-focused and intentionally bounded:
  Chromium captures provide preview-pipeline confidence only; they do not claim
  cross-client parity.

  ## Usage

      mix mailglass_admin.preview.capture
      mix mailglass_admin.preview.capture --dry-run
      mix mailglass_admin.preview.capture --theme dark --widths 375,768
      mix mailglass_admin.preview.capture --mailables MyApp.UserMailer,MyApp.ReceiptMailer

  ## Options

    * `--base-url` - preview base URL (default: `http://localhost:4000/dev/mail`)
    * `--output-dir` - directory where screenshots are written (default: `tmp/mailglass_admin_preview_capture`)
    * `--theme` - `light`, `dark`, or `both` (default: `both`)
    * `--widths` - comma-separated allowed widths from `375,768,1024`
    * `--mailables` - comma-separated explicit mailable module list
    * `--dry-run` - print deterministic plan without running Chromium
    * `--manifest-out` - reserved path for deterministic manifest output (written in follow-up contract step)
    * `--checkpoint-out` - reserved path for deterministic checkpoint output (written in follow-up contract step)
  """

  @default_base_url "http://localhost:4000/dev/mail"
  @default_output_dir "tmp/mailglass_admin_preview_capture"
  @supported_widths CaptureState.widths()

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} =
      OptionParser.parse(argv,
        strict: [
          base_url: :string,
          output_dir: :string,
          theme: :string,
          widths: :string,
          mailables: :string,
          dry_run: :boolean,
          manifest_out: :string,
          checkpoint_out: :string
        ]
      )

    validate_cli!(opts, rest, invalid)

    config = build_config!(opts)

    Mix.Task.run("app.start")

    matrix =
      config.mailables
      |> Discovery.discover()
      |> CaptureMatrix.build_matrix(
        base_path: config.base_url,
        widths: config.widths,
        themes: config.themes
      )

    if config.dry_run do
      print_dry_run(matrix, config)
    else
      run_capture(matrix, config)
    end
  end

  defp validate_cli!(opts, rest, invalid) do
    if rest != [] do
      Mix.raise(
        "Preview capture blocked: unexpected positional arguments #{Enum.join(rest, " ")}"
      )
    end

    if invalid != [] do
      invalid_flags =
        invalid
        |> Enum.map(fn {key, _value} -> "--#{key}" end)
        |> Enum.join(", ")

      Mix.raise("Preview capture blocked: unknown option(s) #{invalid_flags}")
    end

    validate_base_url!(Keyword.get(opts, :base_url, @default_base_url))
    validate_theme!(Keyword.get(opts, :theme, "both"))
    validate_widths!(Keyword.get(opts, :widths, nil))
  end

  defp build_config!(opts) do
    base_url = normalize_base_url(Keyword.get(opts, :base_url, @default_base_url))
    output_dir = Keyword.get(opts, :output_dir, @default_output_dir)
    themes = parse_themes!(Keyword.get(opts, :theme, "both"))
    widths = parse_widths!(Keyword.get(opts, :widths, nil))
    mailables = parse_mailable_modules!(Keyword.get(opts, :mailables, nil))

    %{
      base_url: base_url,
      output_dir: output_dir,
      themes: themes,
      widths: widths,
      mailables: mailables,
      dry_run: Keyword.get(opts, :dry_run, false),
      manifest_out: Keyword.get(opts, :manifest_out, Path.join(output_dir, "manifest.json")),
      checkpoint_out: Keyword.get(opts, :checkpoint_out, Path.join(output_dir, "checkpoint.json"))
    }
  end

  defp run_capture(%{entries: entries} = matrix, config) do
    File.mkdir_p!(config.output_dir)

    if entries == [] do
      Mix.raise("Preview capture blocked: matrix is empty. Define preview_props/0 or widen filters.")
    end

    Enum.each(entries, fn state ->
      output_path = Path.join(config.output_dir, screenshot_name(state))

      case Chromium.capture(state.url, output_path, state.width) do
        :ok ->
          :ok

        {:error, {:binary_not_found, candidates}} ->
          env_var = Chromium.binary_env()
          candidates_text = Enum.join(candidates, ", ")

          Mix.raise(
            "Preview capture blocked: Chromium binary not found. Set #{env_var} or install one of: #{candidates_text}"
          )

        {:error, {:command_failed, exit_code, output}} ->
          Mix.raise(
            "Preview capture failed (exit #{exit_code}) for #{state.url}: #{output}"
          )
      end
    end)

    Mix.shell().info(
      "Captured #{Enum.count(entries)} screenshots to #{config.output_dir} (manifest target: #{config.manifest_out}, checkpoint target: #{config.checkpoint_out})"
    )

    print_skipped(matrix.skipped)
  end

  defp print_dry_run(matrix, config) do
    entries = matrix.entries

    Mix.shell().info("Preview capture dry-run")
    Mix.shell().info("  base-url: #{config.base_url}")
    Mix.shell().info("  output-dir: #{config.output_dir}")
    Mix.shell().info("  theme(s): #{Enum.map_join(config.themes, ", ", &Atom.to_string/1)}")
    Mix.shell().info("  width(s): #{Enum.join(Enum.map(config.widths, &Integer.to_string/1), ", ")}")
    Mix.shell().info("  matrix entries: #{Enum.count(entries)}")
    Mix.shell().info("  manifest-out: #{config.manifest_out}")
    Mix.shell().info("  checkpoint-out: #{config.checkpoint_out}")

    Enum.each(entries, fn state ->
      Mix.shell().info(
        "  - #{inspect(state.mailable)}:#{state.scenario} width=#{state.width} theme=#{state.theme} url=#{state.url}"
      )
    end)

    print_skipped(matrix.skipped)
  end

  defp print_skipped([]), do: :ok

  defp print_skipped(skipped) do
    Mix.shell().info("  skipped: #{Enum.count(skipped)}")

    Enum.each(skipped, fn entry ->
      detail_suffix = if is_binary(entry.details), do: " (#{entry.details})", else: ""
      Mix.shell().info("    * #{inspect(entry.mailable)} -> #{entry.reason}#{detail_suffix}")
    end)
  end

  defp screenshot_name(%CaptureState{} = state) do
    module_slug =
      state.mailable
      |> inspect()
      |> String.replace_prefix("Elixir.", "")
      |> String.replace(".", "__")

    scenario = Atom.to_string(state.scenario)
    theme = Atom.to_string(state.theme)

    "#{module_slug}--#{scenario}--w#{state.width}--#{theme}.png"
  end

  defp parse_mailable_modules!(nil), do: :auto_scan

  defp parse_mailable_modules!(value) when is_binary(value) do
    value
    |> split_csv()
    |> Enum.map(&module_from_string!/1)
  end

  defp parse_themes!(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "both" -> [:dark, :light]
      "light" -> [:light]
      "dark" -> [:dark]
      _ -> invalid_theme!(value)
    end
  end

  defp parse_widths!(nil), do: @supported_widths

  defp parse_widths!(value) when is_binary(value) do
    parsed =
      value
      |> split_csv()
      |> Enum.map(&parse_width!/1)

    unsupported = Enum.reject(parsed, &(&1 in @supported_widths))

    if unsupported == [] do
      parsed
      |> Enum.uniq()
      |> Enum.sort()
    else
      invalid_widths!(unsupported)
    end
  end

  defp split_csv(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_width!(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _ -> Mix.raise("Preview capture blocked: invalid width #{inspect(value)}")
    end
  end

  defp module_from_string!(module_name) do
    module =
      module_name
      |> String.trim()
      |> normalize_module_name()

    try do
      String.to_existing_atom(module)
    rescue
      ArgumentError ->
        Mix.raise(
          "Preview capture blocked: unknown module #{inspect(module_name)} in --mailables"
        )
    end
  end

  defp normalize_module_name("Elixir." <> _ = name), do: name
  defp normalize_module_name(name), do: "Elixir." <> name

  defp normalize_base_url(base_url) do
    base_url
    |> String.trim()
    |> String.trim_trailing("/")
  end

  defp validate_base_url!(base_url) do
    case URI.parse(base_url) do
      %URI{scheme: scheme, host: host, path: path}
      when scheme in ["http", "https"] and is_binary(host) and host != "" and is_binary(path) and
             path != "" ->
        :ok

      _ ->
        Mix.raise(
          "Preview capture blocked: --base-url must be an absolute http(s) URL like http://localhost:4000/dev/mail"
        )
    end
  end

  defp validate_theme!(theme) do
    case String.downcase(String.trim(theme)) do
      "both" -> :ok
      "light" -> :ok
      "dark" -> :ok
      _ -> invalid_theme!(theme)
    end
  end

  defp validate_widths!(nil), do: :ok

  defp validate_widths!(value) do
    value
    |> parse_widths!()
    |> case do
      [] ->
        Mix.raise("Preview capture blocked: --widths must include at least one width")

      _ ->
        :ok
    end
  end

  defp invalid_theme!(theme) do
    Mix.raise(
      "Preview capture blocked: unsupported theme #{inspect(theme)}. Use --theme light, --theme dark, or --theme both."
    )
  end

  defp invalid_widths!(unsupported) do
    unsupported_widths = Enum.join(Enum.map(unsupported, &Integer.to_string/1), ", ")
    allowed = Enum.join(Enum.map(@supported_widths, &Integer.to_string/1), ",")

    Mix.raise(
      "Preview capture blocked: unsupported widths #{unsupported_widths}. Allowed widths: #{allowed}."
    )
  end
end
