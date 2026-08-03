defmodule Mailglass.GeneratedHost.Journey do
  @moduledoc false

  alias Mailglass.GeneratedHost.HostTemplate

  @mailglass_tables ~w(
    mailglass_events
    mailglass_deliveries
    mailglass_outbound_payloads
    mailglass_suppressions
    mailglass_webhook_events
  )

  @spec run!(keyword()) :: map()
  def run!(opts \\ []) do
    schema = Keyword.fetch!(opts, :schema)
    stage = Keyword.get(opts, :stage, :migrate)

    HostTemplate.install!(File.cwd!(), schema)
    Application.put_env(:mailglass, :repo, GeneratedHost.Repo)
    Application.put_env(:mailglass, :schema, schema)

    run_mix!(["mailglass.gen.migration"])
    run_mix!(["ecto.create"])
    run_mix!(["ecto.migrate"])

    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = Application.fetch_env!(:mailglass, :repo).start_link()
    proof = migration_proof!(schema)

    if stage == :boot do
      {:ok, _} = Application.ensure_all_started(:generated_host)
    end

    proof
  end

  defp run_mix!(args) do
    {output, status} = System.cmd("mix", args, stderr_to_stdout: true)

    if status != 0 do
      raise "generated-host command failed (#{Enum.join(args, " ")}): #{output}"
    end
  end

  defp migration_proof!(schema) do
    repo = Application.fetch_env!(:mailglass, :repo)

    {:ok, %{rows: rows}} =
      repo.query(
        """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = $1 AND table_name = ANY($2)
        ORDER BY table_name
        """,
        [schema, @mailglass_tables]
      )

    actual_tables = Enum.map(rows, &hd/1) |> Enum.sort()
    expected_tables = Enum.sort(@mailglass_tables)

    if actual_tables != expected_tables do
      raise "generated-host migration table inventory drifted: #{inspect(actual_tables)}"
    end

    {:ok, %{rows: [[public_count]]}} =
      repo.query(
        "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = ANY($1)",
        [@mailglass_tables]
      )

    if public_count != 0 do
      raise "generated-host migration leaked Mailglass tables into public"
    end

    version = Mailglass.Migration.migrated_version()
    if version != 7, do: raise("generated-host migration version drifted: #{version}")

    %{schema: schema, tables: actual_tables, migrated_version: version}
  end
end
