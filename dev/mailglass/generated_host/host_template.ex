defmodule Mailglass.GeneratedHost.HostTemplate do
  @moduledoc false

  @spec install!(Path.t(), String.t()) :: :ok
  def install!(host_root, schema) when is_binary(host_root) and is_binary(schema) do
    write!(host_root, "config/mailglass_generated_host.exs", config_source(schema))
    write!(host_root, "lib/generated_host/repo.ex", repo_source())
    write!(host_root, "lib/generated_host/proof.ex", proof_source())
    append_import!(host_root)
    :ok
  end

  defp write!(host_root, relative_path, content) do
    path = Path.join(host_root, relative_path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
  end

  defp config_source(schema) do
    """
    import Config

    config :mailglass,
      repo: GeneratedHost.Repo,
      schema: #{inspect(schema)}

    config :swoosh, :api_client, false
    """
  end

  defp append_import!(host_root) do
    path = Path.join(host_root, "config/config.exs")
    import_line = "\nimport_config \"mailglass_generated_host.exs\"\n"

    unless File.read!(path) =~ import_line do
      File.write!(path, import_line, [:append])
    end
  end

  defp proof_source do
    """
    defmodule GeneratedHost.Proof do
      @moduledoc false
      def marker, do: :generated_host
    end
    """
  end

  defp repo_source do
    """
    defmodule GeneratedHost.Repo do
      use Ecto.Repo,
        otp_app: :generated_host,
        adapter: Ecto.Adapters.Postgres
    end
    """
  end
end
