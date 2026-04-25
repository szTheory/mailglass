defmodule Mix.Tasks.Mailglass.Install do
  use Boundary, classify_to: Mailglass

  @shortdoc "Install mailglass into a Phoenix host app"

  @moduledoc """
  Install mailglass into a Phoenix host app.

  ## Usage

      mix mailglass.install
      mix mailglass.install --dry-run
      mix mailglass.install --no-admin
      mix mailglass.install --force

  ## Options

    * `--dry-run` - plan and classify operations without mutating files.
    * `--no-admin` - skip adding Mailglass admin router mounts.
    * `--force` - allow explicit overwrite/append on unmanaged drift.
  """

  use Mix.Task

  alias Mailglass.Installer.Apply
  alias Mailglass.Installer.Operation
  alias Mailglass.Installer.Plan

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} =
      OptionParser.parse(argv, strict: [dry_run: :boolean, no_admin: :boolean, force: :boolean])

    validate_cli!(rest, invalid)
    Mix.Task.run("app.start")

    plan =
      Plan.build(opts, %{
        oban_available?: Mailglass.OptionalDeps.Oban.available?()
      })

    case Apply.run(plan, opts) do
      {:ok, %{operations: operations, counts: counts, dry_run?: dry_run?}} ->
        Enum.each(operations, &print_operation/1)
        print_totals(counts, dry_run?)
        maybe_raise_conflict_error(counts)

      {:error, reason} ->
        Mix.raise(format_error(reason))
    end
  end

  @spec validate_cli!([String.t()], keyword()) :: :ok
  defp validate_cli!(rest, invalid) do
    if rest != [] do
      Mix.raise("Installation blocked: unexpected positional arguments #{Enum.join(rest, " ")}")
    end

    if invalid != [] do
      invalid_flags =
        invalid
        |> Enum.map(fn {key, _value} -> "--#{key}" end)
        |> Enum.join(", ")

      Mix.raise("Installation blocked: unknown option(s) #{invalid_flags}")
    end

    :ok
  end

  @spec print_operation(Operation.t()) :: :ok
  defp print_operation(%Operation{status: :conflict, path: path, reason: %{sidecar: sidecar}}) do
    Mix.shell().info("[conflict] #{render_path(path)} -> #{sidecar}")
  end

  defp print_operation(%Operation{status: status, path: path}) do
    Mix.shell().info("#{status_label(status)} #{render_path(path)}")
  end

  @spec print_totals(map(), boolean()) :: :ok
  defp print_totals(counts, dry_run?) do
    suffix =
      if dry_run? do
        " (dry run)"
      else
        ""
      end

    Mix.shell().info(
      "Install result#{suffix}: create=#{counts.create} update=#{counts.update} " <>
        "unchanged=#{counts.unchanged} conflict=#{counts.conflict}"
    )
  end

  @spec maybe_raise_conflict_error(map()) :: :ok
  defp maybe_raise_conflict_error(%{conflict: 0}), do: :ok

  defp maybe_raise_conflict_error(%{conflict: conflict_count}) do
    Mix.raise("Installation blocked: #{conflict_count} conflict(s) require manual merge")
  end

  @spec status_label(Operation.status() | nil) :: String.t()
  defp status_label(:create), do: "[create]"
  defp status_label(:update), do: "[update]"
  defp status_label(:unchanged), do: "[unchanged]"
  defp status_label(:conflict), do: "[conflict]"
  defp status_label(_unknown), do: "[unchanged]"

  @spec render_path(String.t() | nil) :: String.t()
  defp render_path(nil), do: "(runtime)"
  defp render_path(path), do: path

  @spec format_error(term()) :: String.t()
  defp format_error({:manifest_read_failed, path, reason}),
    do: "Installation blocked: cannot read manifest #{path} (#{inspect(reason)})"

  defp format_error({:manifest_write_failed, path, reason}),
    do: "Installation blocked: cannot write manifest #{path} (#{inspect(reason)})"

  defp format_error({:file_read_failed, path, reason}),
    do: "Installation blocked: cannot read #{path} (#{inspect(reason)})"

  defp format_error({:file_write_failed, path, reason}),
    do: "Installation blocked: cannot write #{path} (#{inspect(reason)})"

  defp format_error({:unknown_operation_kind, kind}),
    do: "Installation blocked: unsupported operation kind #{inspect(kind)}"

  defp format_error({:task_run_failed, task, reason}),
    do: "Installation blocked: #{task} failed (#{reason})"

  defp format_error({:conflict_sidecar_write_failed, sidecar_path, reason}),
    do: "Installation blocked: cannot write sidecar #{sidecar_path} (#{inspect(reason)})"

  defp format_error(other), do: "Installation blocked: #{inspect(other)}"
end
