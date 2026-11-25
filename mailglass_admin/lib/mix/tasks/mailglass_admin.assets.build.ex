defmodule Mix.Tasks.MailglassAdmin.Assets.Build do
  use Boundary, classify_to: MailglassAdmin

  @shortdoc "Build or verify the mailglass_admin CSS bundle (production, minified)"

  @moduledoc """
  Compiles `mailglass_admin/assets/css/app.css` to
  `mailglass_admin/priv/static/app.css` via the `tailwind` Hex package —
  zero Node toolchain required.

  ## Usage

      mix mailglass_admin.assets.build
      mix mailglass_admin.assets.build --check

  Run the plain build after editing `assets/css/app.css`, after touching any
  HEEx or Elixir source under `lib/`, or after editing `brandbook/tokens.css`,
  then commit the rebuilt `priv/static/app.css` in the same change.

  ## `--check`

  `--check` is the drift gate. It runs the pinned Tailwind build into a
  temporary file, leaves `priv/static/` untouched, and compares the bytes to
  the committed `priv/static/app.css`. It exits non-zero when the bundle
  differs, is missing, or is truncated, and the message gives both sizes, the
  first differing byte, and the fix command. A Tailwind binary download or
  install failure fails the check; it is never treated as a pass.

  The required CI job `support_contract_admin` runs `--check` as the first
  step of `mix verify.support_contract.admin`, and an ExUnit contract test in
  the same lane runs the same compare.

  `--check` is a maintainer-only mode. It needs the `tailwind` dependency,
  which exists only in the `:dev` and `:test` environments of the
  mailglass_admin repository.

  ## What the bundle depends on

  The bundle is a pure function of these inputs. A change to any of them
  changes the bytes:

    * `assets/css/app.css`
    * `assets/vendor/*.js` (vendored daisyUI 5.5.19 and the icon plugin)
    * every file under `lib/`, because Tailwind scans it as plain text and
      any word that looks like a utility class emits that class
    * `../brandbook/tokens.css`, which sits outside the package directory
    * the pinned Tailwind binary version (4.1.12, set in `config/config.exs`)
  """

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} = OptionParser.parse(argv, strict: [check: :boolean])
    validate_cli!(rest, invalid)

    if Keyword.get(opts, :check, false) do
      check!()
    else
      Mix.Task.run("tailwind", ["default", "--minify"])
    end
  end

  defp validate_cli!(rest, invalid) do
    if rest != [] do
      Mix.raise(
        "Admin asset build blocked: unexpected positional arguments #{Enum.join(rest, " ")}"
      )
    end

    if invalid != [] do
      flags = Enum.map_join(invalid, ", ", fn {flag, _value} -> flag end)
      Mix.raise("Admin asset build blocked: unknown option(s) #{flags}")
    end
  end

  # The drift compare lives in a non-shipped dev/ module because it calls
  # `Tailwind`, a dependency that exists only in :dev and :test. `apply/3`
  # keeps this shipped task free of a compile-time reference to it.
  defp check! do
    if Code.ensure_loaded?(MailglassAdmin.AssetsCheck) do
      :ok = apply(MailglassAdmin.AssetsCheck, :run_check!, [[]])
      %{size: bytes} = File.stat!("priv/static/app.css")
      Mix.shell().info("Admin bundle matches a fresh build (#{bytes} bytes).")
    else
      Mix.raise(
        "Admin asset check blocked: --check is a maintainer-only mode, " <>
          "available in the mailglass_admin repository under MIX_ENV=dev or MIX_ENV=test."
      )
    end
  end
end
