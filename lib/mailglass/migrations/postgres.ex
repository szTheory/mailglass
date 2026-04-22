defmodule Mailglass.Migrations.Postgres do
  @moduledoc false

  use Ecto.Migration

  @initial_version 1
  @current_version 1
  @default_prefix "public"

  @doc false
  def initial_version, do: @initial_version

  @doc false
  def current_version, do: @current_version

  @spec up(keyword()) :: :ok
  def up(opts) do
    opts = with_defaults(opts, @current_version)
    initial = migrated_version(opts)

    cond do
      initial == 0 ->
        change(@initial_version..opts.version, :up, opts)

      initial < opts.version ->
        change((initial + 1)..opts.version, :up, opts)

      true ->
        :ok
    end
  end

  @spec down(keyword()) :: :ok
  def down(opts) do
    opts = with_defaults(opts, @initial_version - 1)
    initial = max(migrated_version(opts), @initial_version)

    if initial > opts.version do
      change(initial..(opts.version + 1)//-1, :down, opts)
    else
      :ok
    end
  end

  @spec migrated_version(map() | keyword()) :: non_neg_integer()
  def migrated_version(opts) do
    opts = with_defaults(opts, @initial_version)

    repo = Map.get_lazy(opts, :repo, fn -> repo() end)
    escaped_prefix = Map.fetch!(opts, :escaped_prefix)

    query = """
    SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
    FROM pg_class
    LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE pg_class.relname = 'mailglass_events'
    AND pg_namespace.nspname = '#{escaped_prefix}'
    """

    case repo.query(query, [], log: false) do
      {:ok, %{rows: [[version]]}} when is_binary(version) -> String.to_integer(version)
      _ -> 0
    end
  end

  defp change(range, direction, opts) do
    for index <- range do
      pad_idx = String.pad_leading(to_string(index), 2, "0")

      [__MODULE__, "V#{pad_idx}"]
      |> Module.concat()
      |> apply(direction, [opts])
    end

    case direction do
      :up -> record_version(opts, Enum.max(range))
      :down -> record_version(opts, Enum.min(range) - 1)
    end

    :ok
  end

  defp record_version(_opts, 0), do: :ok

  defp record_version(%{prefix: prefix}, version) do
    execute("COMMENT ON TABLE #{inspect(prefix)}.mailglass_events IS '#{version}'")
  end

  defp with_defaults(opts, version) do
    opts
    |> Enum.into(%{prefix: @default_prefix, version: version})
    |> then(fn o ->
      o
      |> Map.put(:quoted_prefix, inspect(o.prefix))
      |> Map.put(:escaped_prefix, String.replace(o.prefix, "'", "\\'"))
      |> Map.put_new(:create_schema, o.prefix != @default_prefix)
    end)
  end
end
