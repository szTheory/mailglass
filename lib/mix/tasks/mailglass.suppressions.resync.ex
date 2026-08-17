defmodule Mix.Tasks.Mailglass.Suppressions.Resync do
  use Boundary, classify_to: Mailglass

  use Mix.Task

  alias Mailglass.Suppression.Resync

  @shortdoc "Rebuild suppression rows from tenant-scoped event history"

  @moduledoc """
  Rebuilds `mailglass_suppressions` from the append-only event ledger for one tenant.

  Default mode applies missing suppression rows. Pass `--dry-run` to preview
  counts without writing. Pass `--verbose` to print candidate-level detail for
  the explicit tenant you selected.
  """

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} =
      OptionParser.parse(argv,
        strict: [
          tenant_id: :string,
          dry_run: :boolean,
          verbose: :boolean,
          from: :string,
          to: :string
        ]
      )

    validate_cli!(opts, rest, invalid)
    Mix.Task.run("app.start")

    case Resync.run(service_opts(opts)) do
      {:ok, result} ->
        Mix.shell().info(summary_line(result))

        if opts[:verbose] do
          Enum.each(result.candidates, fn candidate ->
            Mix.shell().info(verbose_line(candidate))
          end)

          if result.candidates_truncated? do
            Mix.shell().info(
              "candidate detail truncated at 100 entries; aggregate counts are complete"
            )
          end
        end

      {:error, :tenant_id_required} ->
        Mix.raise("Suppression resync blocked: --tenant-id is required")

      {:error, {:invalid_datetime, field, value}} ->
        Mix.raise("Suppression resync blocked: --#{field} must be ISO-8601, got #{inspect(value)}")

      {:error, {:invalid_window, from, to}} ->
        Mix.raise(
          "Suppression resync blocked: --from must be before or equal to --to (#{from} > #{to})"
        )

      {:error, reason} ->
        Mix.raise("Suppression resync failed: #{inspect(reason)}")
    end
  end

  defp validate_cli!(opts, rest, invalid) do
    if rest != [] do
      Mix.raise(
        "Suppression resync blocked: unexpected positional arguments #{Enum.join(rest, " ")}"
      )
    end

    if invalid != [] do
      invalid_flags =
        invalid
        |> Enum.map(fn {key, _value} -> "--#{key}" end)
        |> Enum.join(", ")

      Mix.raise("Suppression resync blocked: unknown option(s) #{invalid_flags}")
    end

    unless is_binary(opts[:tenant_id]) and opts[:tenant_id] != "" do
      Mix.raise("Suppression resync blocked: --tenant-id is required")
    end

    :ok
  end

  defp service_opts(opts) do
    []
    |> Keyword.put(:tenant_id, opts[:tenant_id])
    |> maybe_put(:dry_run, opts[:dry_run] == true)
    |> maybe_put(:from, opts[:from])
    |> maybe_put(:to, opts[:to])
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, _key, false), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp summary_line(result) do
    mode = if result.dry_run, do: "dry-run", else: "apply"

    "#{mode} tenant=#{result.tenant_id} scanned=#{result.scanned} " <>
      "would_insert=#{result.would_insert} inserted=#{result.inserted} existing=#{result.existing}"
  end

  defp verbose_line(candidate) do
    "candidate address=#{candidate.address} scope=#{candidate.scope} " <>
      "stream=#{inspect(candidate.stream)} reason=#{candidate.reason} " <>
      "event_type=#{candidate.event_type} status=#{candidate.status}"
  end
end
