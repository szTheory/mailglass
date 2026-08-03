defmodule Mailglass.ProductionPreflight do
  @moduledoc """
  Runs bounded, read-only production readiness checks for a Mailglass host.

  `run/1` intentionally returns every check result instead of raising on the
  first problem, so an operator can fix a complete configuration set before
  accepting traffic. It is never invoked during ordinary application boot.
  """

  @current_migration_version 7

  @type check_id ::
          :repo_access
          | :schema_access
          | :migration_version
          | :delivery_adapter
          | :webhook_signing
          | :outbound_queue
          | :payload_maintenance
          | :operator_mount

  @type check :: %{id: check_id(), status: :passed | :failed, remediation: String.t()}
  @type result :: %{status: :ready | :failed, checks: [check()]}

  @doc """
  Returns secret-safe readiness results for the configured production host.

  The check only performs read-only database and runtime observations. It does
  not migrate a schema, start a queue, schedule maintenance, or alter routing.
  """
  @doc since: "2.4.0"
  @spec run(keyword()) :: result()
  def run(_opts \\ []) do
    checks = [
      repo_access(),
      schema_access(),
      migration_version(),
      delivery_adapter(),
      webhook_signing(),
      outbound_queue(),
      payload_maintenance(),
      operator_mount()
    ]

    %{
      status: if(Enum.all?(checks, &(&1.status == :passed)), do: :ready, else: :failed),
      checks: checks
    }
  end

  defp repo_access do
    case Mailglass.Repo.query!("SELECT 1") do
      %{rows: [[1]]} ->
        passed(:repo_access)

      _ ->
        failed(
          :repo_access,
          "Start the configured Ecto Repo and verify its PostgreSQL connection."
        )
    end
  rescue
    _ ->
      failed(:repo_access, "Start the configured Ecto Repo and verify its PostgreSQL connection.")
  end

  defp schema_access do
    with {:ok, schema} <- configured_schema(),
         %{rows: [[true]]} <-
           Mailglass.Repo.query!(
             "SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = $1)",
             [schema]
           ) do
      passed(:schema_access)
    else
      _ -> failed(:schema_access, "Create the configured Mailglass schema with mix ecto.migrate.")
    end
  rescue
    _ -> failed(:schema_access, "Create the configured Mailglass schema with mix ecto.migrate.")
  end

  defp migration_version do
    case safely_migrated_version() do
      @current_migration_version ->
        passed(:migration_version)

      _ ->
        failed(
          :migration_version,
          "Run the generated Mailglass migration wrapper until the configured schema is current."
        )
    end
  end

  defp delivery_adapter do
    case safely_default_adapter() do
      {:ok, adapter} when is_atom(adapter) ->
        if Code.ensure_loaded?(adapter) and function_exported?(adapter, :deliver, 2) do
          passed(:delivery_adapter)
        else
          failed(
            :delivery_adapter,
            "Configure :mailglass, :adapter with a loaded Mailglass.Adapter deliver/2 module."
          )
        end

      _ ->
        failed(
          :delivery_adapter,
          "Configure :mailglass, :adapter with a loaded Mailglass.Adapter deliver/2 module."
        )
    end
  end

  defp webhook_signing do
    if signing_configured?() do
      passed(:webhook_signing)
    else
      failed(
        :webhook_signing,
        "Configure a signature verification credential for every mounted webhook provider."
      )
    end
  end

  defp outbound_queue do
    case Mailglass.Config.production_readiness() do
      :ok ->
        passed(:outbound_queue)

      {:error, _} ->
        failed(
          :outbound_queue,
          "Run Oban with a positive-concurrency :mailglass_outbound queue; Task.Supervisor is not durable."
        )
    end
  rescue
    _ ->
      failed(
        :outbound_queue,
        "Run Oban with a positive-concurrency :mailglass_outbound queue; Task.Supervisor is not durable."
      )
  end

  defp payload_maintenance do
    case Mailglass.Config.outbound_payload_maintenance() do
      mode when mode in [:scheduled, :manual] ->
        passed(:payload_maintenance)

      :none ->
        failed(
          :payload_maintenance,
          "Set :outbound_payload_maintenance to :scheduled or use the documented manual payload-prune runbook."
        )
    end
  rescue
    _ ->
      failed(
        :payload_maintenance,
        "Set :outbound_payload_maintenance to :scheduled or use the documented manual payload-prune runbook."
      )
  end

  defp operator_mount do
    case Mailglass.Config.operator_auth() do
      auth when is_atom(auth) ->
        if Code.ensure_loaded?(auth) and function_exported?(auth, :authorize, 2) do
          passed(:operator_mount)
        else
          failed(
            :operator_mount,
            "Mount MailglassAdmin.Router behind a host auth pipeline and configure its authorize/2 callback."
          )
        end

      _ ->
        failed(
          :operator_mount,
          "Mount MailglassAdmin.Router behind a host auth pipeline and configure its authorize/2 callback."
        )
    end
  rescue
    _ ->
      failed(
        :operator_mount,
        "Mount MailglassAdmin.Router behind a host auth pipeline and configure its authorize/2 callback."
      )
  end

  defp configured_schema do
    case Application.get_env(:mailglass, :schema) do
      schema when is_binary(schema) and schema != "" -> {:ok, schema}
      _ -> :error
    end
  end

  defp safely_migrated_version do
    Mailglass.Migration.migrated_version()
  rescue
    _ -> 0
  end

  defp safely_default_adapter do
    {adapter, _opts} = Mailglass.Config.default_adapter()
    {:ok, adapter}
  rescue
    _ -> :error
  end

  defp signing_configured? do
    providers = [
      {:postmark, :basic_auth},
      {:sendgrid, :public_key},
      {:mailgun, :signing_key},
      {:resend, :secret}
    ]

    Enum.any?(providers, fn {provider, credential} ->
      Application.get_env(:mailglass, provider, [])
      |> Keyword.get(credential)
      |> present_secret?()
    end)
  end

  defp present_secret?({username, password}) when is_binary(username) and is_binary(password),
    do: username != "" and password != ""

  defp present_secret?(value) when is_binary(value), do: value != ""
  defp present_secret?(_value), do: false

  defp passed(id), do: %{id: id, status: :passed, remediation: ""}
  defp failed(id, remediation), do: %{id: id, status: :failed, remediation: remediation}
end
