defmodule Mix.Tasks.Mailglass.Inbound.Gen.Migration do
  @moduledoc """
  Generates install or upgrade migration wrappers for mailglass_inbound.

  Run `mix help mailglass.inbound.gen.migration` for the supported repository
  and upgrade options.
  """

  use Mix.Task

  @shortdoc "Generate mailglass_inbound migration wrappers for a configured Ecto repo"

  @impl Mix.Task
  def run(argv) do
    if "--repair-legacy" in argv do
      Mix.raise(
        "Installation blocked: no recognized inbound legacy signature; no migration was written"
      )
    end

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
