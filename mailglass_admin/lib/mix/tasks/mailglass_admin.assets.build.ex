defmodule Mix.Tasks.MailglassAdmin.Assets.Build do
  use Boundary, classify_to: MailglassAdmin

  @shortdoc "Build mailglass_admin CSS bundle (production, minified)"

  @moduledoc """
  Compiles `mailglass_admin/assets/css/app.css` to
  `mailglass_admin/priv/static/app.css` via the `tailwind` Hex package —
  zero Node toolchain required.

  ## Usage

      mix mailglass_admin.assets.build

  Run after editing `assets/css/app.css` or after touching any HEEx
  source under `lib/mailglass_admin/` (Tailwind's content scanner walks
  those files to determine which utility classes to emit).

  CI runs this followed by `git diff --exit-code priv/static/` per
  CONTEXT D-04 / PREV-06 — any drift between the committed bundle and
  the bundle produced from the current source fails merge.
  """

  use Mix.Task

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("tailwind", ["default", "--minify"])
  end
end
