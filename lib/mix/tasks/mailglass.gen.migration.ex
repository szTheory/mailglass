defmodule Mix.Tasks.Mailglass.Gen.Migration do
  use Boundary, classify_to: Mailglass
  use Mix.Task

  @shortdoc "Generate Mailglass migration wrappers for a configured Ecto repo"

  @impl Mix.Task
  def run(argv) do
    Mailglass.MigrationGenerator.run(
      %{
        task_name: "mailglass.gen.migration",
        install_suffix: "mailglass_install",
        upgrade_suffix: "mailglass_upgrade",
        install_module_suffix: "MailglassInstall",
        upgrade_module_suffix: "MailglassUpgrade",
        migration_module: Mailglass.Migration,
        initial_version: &Mailglass.Migrations.Postgres.initial_version/0,
        current_version: &Mailglass.Migrations.Postgres.current_version/0
      },
      argv
    )
  end
end
