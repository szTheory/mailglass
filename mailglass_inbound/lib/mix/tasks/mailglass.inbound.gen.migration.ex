defmodule Mix.Tasks.Mailglass.Inbound.Gen.Migration do
  # NOTE: no `use Boundary, classify_to:` here. `mailglass_inbound` does not run
  # the `:boundary` compiler, so the annotation would not compile. The boundary
  # LAW (inbound depends on core, never the reverse) is still honored — this omits
  # only the compile-time annotation (deliberate deviation from the design contract).
  use Mix.Task

  @shortdoc "Generate the mailglass_inbound installer migration"

  @moduledoc """
  Generates the 8-line wrapper migration file in `priv/repo/migrations/`
  that delegates `up/0` and `down/0` to `MailglassInbound.Migration`.

  Run once in the host application after adding `:mailglass_inbound` as a
  dependency; idempotent (re-running is safe).

      mix mailglass.inbound.gen.migration

  The generated file looks like:

      defmodule MyApp.Repo.Migrations.MailglassInboundInstall do
        use Ecto.Migration
        def up, do: MailglassInbound.Migration.up()
        def down, do: MailglassInbound.Migration.down()
      end

  The wrapper stays stable across mailglass_inbound versions. Per-version DDL
  lives in `MailglassInbound.Migrations.Postgres.VNN` modules dispatched by the
  runner; the wrapper never needs updating as mailglass_inbound evolves.
  """

  @impl Mix.Task
  def run(argv) do
    {_opts, rest, invalid} = OptionParser.parse(argv, strict: [])

    if rest != [] or invalid != [] do
      Mix.raise("Installation blocked: unexpected args for mailglass.inbound.gen.migration")
    end

    case existing_wrapper_migration() do
      nil ->
        path =
          Path.join(["priv", "repo", "migrations", "#{timestamp()}_mailglass_inbound_install.exs"])

        File.mkdir_p!(Path.dirname(path))
        File.write!(path, migration_body())

        Mix.shell().info("created #{path}")

      path ->
        Mix.shell().info("unchanged #{path}")
    end

    :ok
  end

  defp existing_wrapper_migration do
    ["priv", "repo", "migrations", "*_mailglass_inbound_install.exs"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.sort()
    |> List.first()
  end

  defp timestamp do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
    |> Calendar.strftime("%Y%m%d%H%M%S")
  end

  defp migration_body do
    app_module = current_app_module()

    """
    defmodule #{app_module}.Repo.Migrations.MailglassInboundInstall do
      use Ecto.Migration

      def up, do: MailglassInbound.Migration.up()
      def down, do: MailglassInbound.Migration.down()
    end
    """
  end

  defp current_app_module do
    mix_exs = File.read!("mix.exs")

    case Regex.run(~r/app:\s*:(\w+)/, mix_exs) do
      [_, app] -> Macro.camelize(app)
      _ -> "Example"
    end
  end
end
