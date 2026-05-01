defmodule Mix.Tasks.Mail.Doctor do
  use Boundary, classify_to: Mailglass

  use Mix.Task

  alias Mailglass.Deliverability.Formatter

  @shortdoc "Run DNS-only deliverability checks for one domain"

  @moduledoc """
  Run DNS-only deliverability checks for one explicit domain.

  ## Usage

      mix mail.doctor --domain example.com
      mix mail.doctor --domain example.com --dkim-selector default
      mix mail.doctor --domain example.com --verbose
      mix mail.doctor --domain example.com --format json
  """

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} =
      OptionParser.parse(argv,
        strict: [
          domain: :string,
          dkim_selector: :keep,
          verbose: :boolean,
          format: :string
        ]
      )

    validate_cli!(opts, rest, invalid)
    Mix.Task.run("app.start")

    case Mailglass.Deliverability.run(service_opts(opts)) do
      {:ok, result} ->
        result
        |> render_output(opts)
        |> Mix.shell().info()

      {:error, :blank_domain} ->
        Mix.raise("Deliverability doctor blocked: --domain is required")

      {:error, {:invalid_dkim_selector, _selector}} ->
        Mix.raise("Deliverability doctor blocked: --dkim-selector cannot be blank")

      {:error, reason} ->
        Mix.raise("Deliverability doctor failed: #{inspect(reason)}")
    end
  end

  defp validate_cli!(opts, rest, invalid) do
    if rest != [] do
      Mix.raise(
        "Deliverability doctor blocked: unexpected positional arguments #{Enum.join(rest, " ")}"
      )
    end

    if invalid != [] do
      invalid_flags =
        invalid
        |> Enum.map(fn {key, _value} -> "--#{key}" end)
        |> Enum.join(", ")

      Mix.raise("Deliverability doctor blocked: unknown option(s) #{invalid_flags}")
    end

    unless is_binary(opts[:domain]) and String.trim(opts[:domain]) != "" do
      Mix.raise("Deliverability doctor blocked: --domain is required")
    end

    format = Keyword.get(opts, :format, "human")

    unless format in ["human", "json"] do
      Mix.raise("Deliverability doctor blocked: invalid format #{inspect(format)}")
    end

    :ok
  end

  defp service_opts(opts) do
    []
    |> Keyword.put(:domain, opts[:domain])
    |> Keyword.put(:dkim_selectors, Keyword.get_values(opts, :dkim_selector))
    |> maybe_put(:resolver, Application.get_env(:mailglass, :deliverability_resolver))
  end

  defp render_output(result, opts) do
    case Keyword.get(opts, :format, "human") do
      "json" -> Formatter.render_json(result)
      "human" -> Formatter.render_human(result, verbose?: opts[:verbose] == true)
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
