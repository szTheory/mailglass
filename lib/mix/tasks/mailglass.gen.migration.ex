defmodule Mix.Tasks.Mailglass.Gen.Migration do
  use Boundary, classify_to: Mailglass

  use Mix.Task

  @shortdoc "Generate the Mailglass installer migration"

  @moduledoc false

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} = OptionParser.parse(argv, strict: [upgrade: :boolean])

    if rest != [] or invalid != [] do
      Mix.raise("Installation blocked: unexpected args for mailglass.gen.migration")
    end

    _upgrade? = opts[:upgrade] == true

    path = Path.join(["priv", "repo", "migrations", "#{timestamp()}_mailglass_install.exs"])

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, migration_body())

    Mix.shell().info("created #{path}")

    :ok
  end

  defp timestamp do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
    |> Calendar.strftime("%Y%m%d%H%M%S")
  end

  defp migration_body do
    app_module = current_app_module()

    """
    defmodule #{app_module}.Repo.Migrations.MailglassInstall do
      use Ecto.Migration

      def change do
        create table(:mailglass_events) do
          add :tenant_id, :string
          timestamps(type: :utc_datetime_usec)
        end
      end
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
