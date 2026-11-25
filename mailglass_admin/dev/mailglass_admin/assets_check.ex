defmodule MailglassAdmin.AssetsCheck do
  @moduledoc """
  Byte-for-byte drift check for the committed admin bundle.

  Builds `assets/css/app.css` with the pinned Tailwind binary (the same
  `:default` profile `mix mailglass_admin.assets.build` uses) into a
  temporary file, then compares those bytes to the committed
  `priv/static/app.css`. Nothing is written inside `priv/static/`.

  This module lives in `dev/`, so it is compiled for `:dev` and `:test` only
  and never ships in the Hex tarball. The shipped task
  `Mix.Tasks.MailglassAdmin.Assets.Build` reaches it through
  `Code.ensure_loaded?/1` and `apply/3`, which keeps the shipped code free of
  a compile-time reference to `Tailwind` (an `only: [:dev, :test]` dependency).

  ## Entry points

  One compare function backs two enforcement paths, so deleting either one
  stays visible: `mix mailglass_admin.assets.build --check` (the first step of
  `mix verify.support_contract.admin`) and the ExUnit contract test
  `bundle_reproducibility_contract_test.exs` in the same required lane.

  ## Failure modes

    * `{:error, {:drift, fresh_size, committed_size, first_diff_offset}}` — the
      bytes differ; the offset is the first differing index, or the length of
      the shorter file when one is a prefix of the other.
    * `{:error, {:committed_unreadable, reason}}` — the committed bundle is
      missing or cannot be read.
    * `{:error, {:tailwind_failed, status, output}}` — the Tailwind binary
      exited non-zero.

  A Tailwind binary install or download failure is never rescued: it raises,
  so the check fails closed and cannot turn a network error into a pass.
  """

  @fix_command "mix mailglass_admin.assets.build"
  @committed_relative "priv/static/app.css"

  @type reason ::
          {:drift, non_neg_integer(), non_neg_integer(), non_neg_integer()}
          | {:committed_unreadable, :file.posix() | :badarg | :terminated | :system_limit}
          | {:tailwind_failed, integer(), String.t()}

  @doc """
  Builds the bundle to a temporary file and compares it to the committed one.

  ## Options

    * `:cd` — directory the Tailwind build runs in. Defaults to the `:cd` of
      the `:default` Tailwind profile (the `mailglass_admin` package root).
    * `:committed` — path of the committed bundle. Defaults to
      `priv/static/app.css` under `:cd`.
    * `:bin_path` — Tailwind binary. Defaults to `Tailwind.bin_path/0`.
    * `:installer` — zero-arity function that installs the binary when it is
      missing. Defaults to `&Tailwind.install/0`. It is never wrapped in a
      `rescue`.
  """
  @spec check(keyword()) :: :ok | {:error, reason()}
  def check(opts \\ []) do
    profile = Tailwind.config_for!(:default)
    cd = Keyword.get(opts, :cd, profile[:cd])
    committed = Keyword.get(opts, :committed, Path.join(cd, @committed_relative))
    bin_path = Keyword.get_lazy(opts, :bin_path, &Tailwind.bin_path/0)
    installer = Keyword.get(opts, :installer, &Tailwind.install/0)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "mg_assets_check_#{System.pid()}_#{System.unique_integer([:positive])}.css"
      )

    # Fail closed: a download failure raises out of here and is never turned
    # into a pass (D-06).
    unless File.exists?(bin_path), do: installer.()

    try do
      {output, status} =
        System.cmd(bin_path, build_args(profile[:args], tmp),
          cd: cd,
          env: %{"BROWSERSLIST_IGNORE_OLD_DATA" => "1"},
          stderr_to_stdout: true
        )

      if status == 0 do
        compare(File.read!(tmp), File.read(committed))
      else
        {:error, {:tailwind_failed, status, String.trim(output)}}
      end
    after
      File.rm(tmp)
    end
  end

  @doc """
  Same as `check/1`, but raises `Mix.Error` with `format_error/1` text on any
  failure. Returns `:ok` when the committed bundle matches a fresh build.
  """
  @spec run_check!(keyword()) :: :ok
  def run_check!(opts \\ []) do
    case check(opts) do
      :ok -> :ok
      {:error, reason} -> Mix.raise(format_error(reason))
    end
  end

  @doc """
  Renders a `check/1` failure as maintainer-facing text with the fix command.
  """
  @spec format_error(reason()) :: String.t()
  def format_error({:drift, fresh_size, committed_size, offset}) do
    "Admin bundle drift: a fresh build is #{fresh_size} bytes, " <>
      "the committed #{@committed_relative} is #{committed_size} bytes, " <>
      "first difference at byte #{offset}. " <>
      "Run #{@fix_command} and commit #{@committed_relative}."
  end

  def format_error({:committed_unreadable, reason}) do
    "Admin bundle check blocked: the committed #{@committed_relative} cannot be read " <>
      "(#{reason}: #{:file.format_error(reason)}). " <>
      "Run #{@fix_command} and commit #{@committed_relative}."
  end

  def format_error({:tailwind_failed, status, output}) do
    "Admin bundle check blocked: the pinned Tailwind build exited with status #{status}. " <>
      "Output: #{output}"
  end

  # Replace the profile's own `--output=` entry. The Tailwind CLI comma-joins a
  # second `--output` flag into one path, so appending one is unusable and would
  # write inside priv/static/ (F1).
  defp build_args(profile_args, tmp) do
    {args, replaced?} =
      Enum.map_reduce(profile_args, false, fn
        "--output=" <> _, _replaced? -> {"--output=" <> tmp, true}
        arg, replaced? -> {arg, replaced?}
      end)

    if replaced?, do: args ++ ["--minify"], else: args ++ ["--output=" <> tmp, "--minify"]
  end

  defp compare(fresh, {:ok, committed}) when fresh == committed, do: :ok

  defp compare(fresh, {:ok, committed}) do
    {:error, {:drift, byte_size(fresh), byte_size(committed), first_diff(fresh, committed, 0)}}
  end

  defp compare(_fresh, {:error, reason}), do: {:error, {:committed_unreadable, reason}}

  defp first_diff(<<byte, fresh::binary>>, <<byte, committed::binary>>, offset),
    do: first_diff(fresh, committed, offset + 1)

  defp first_diff(_fresh, _committed, offset), do: offset
end
