defmodule Mix.Tasks.Mailglass.Inbound.Gen.Migration do
  use Mix.Task

  @shortdoc "Generate mailglass_inbound migration wrappers for a configured Ecto repo"

  @impl Mix.Task
  def run(argv) do
    Mailglass.MigrationGenerator.run(
      %{
        task_name: "mailglass.inbound.gen.migration",
        install_suffix: "mailglass_inbound_install",
        upgrade_suffix: "mailglass_inbound_upgrade",
        install_module_suffix: "MailglassInboundInstall",
        upgrade_module_suffix: "MailglassInboundUpgrade",
        migration_module: MailglassInbound.Migration,
        initial_version: &MailglassInbound.Migrations.Postgres.initial_version/0,
        current_version: &MailglassInbound.Migrations.Postgres.current_version/0
      },
      argv
    )
  end
end
