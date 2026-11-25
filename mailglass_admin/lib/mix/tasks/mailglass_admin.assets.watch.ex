defmodule Mix.Tasks.MailglassAdmin.Assets.Watch do
  use Boundary, classify_to: MailglassAdmin

  @shortdoc "Watch mode for maintainer dev loop"

  @moduledoc """
  Runs Tailwind in `--watch` mode. Recompiles `priv/static/app.css`
  on every save to `assets/css/app.css` or any HEEx source under
  `lib/mailglass_admin/`.

  ## Usage

      mix mailglass_admin.assets.watch

  Intended for maintainer dev loops only — production builds go through
  `mix mailglass_admin.assets.build`, which minifies. Its `--check` mode is
  the CI drift gate.
  """

  use Mix.Task

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("tailwind", ["default", "--watch"])
  end
end
