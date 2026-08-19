defmodule MailglassInbound.Migrations.Postgres do
  @moduledoc "Internal migration runner for mailglass_inbound (Postgres)."

  use Ecto.Migration

  @initial_version 1
  @current_version 2
  @default_prefix "public"

  @doc false
  def initial_version, do: @initial_version

  @doc false
  def current_version, do: @current_version

  @spec up(keyword()) :: :ok
  def up(opts) do
    opts = with_defaults(opts, @current_version)
    # First action: physically create the schema (INB-02) so the v01
    # `create table(prefix:)` DDL has a namespace to land in. No-op for the
    # default "public" prefix and for an explicit `create_schema: false`.
    initial = migrated_version(opts)
    maybe_create_schema(opts)

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

    prefix = Map.fetch!(opts, :prefix)

    validate_identifier!(prefix, :prefix)

    # Use parameter binding for the schema comparison instead of string
    # interpolation. The prefix is also validated against an identifier
    # regex above as a belt-and-suspenders guard. Inbound anchors on
    # `mailglass_inbound_records` — independent of core's `mailglass_events`
    # anchor.
    query = """
    SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
    FROM pg_class
    LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE pg_class.relname = 'mailglass_inbound_records'
    AND pg_namespace.nspname = $1
    """

    case catalog_result(opts, query, prefix) do
      {:ok, %{rows: []}} ->
        0

      {:ok, %{rows: [[nil]]}} ->
        raise_version_error(:missing_comment, prefix)

      {:ok, %{rows: [[version]]}} when is_binary(version) ->
        parse_version!(version, prefix)

      {:error, reason} ->
        raise_version_error(:query_failed, prefix, reason)

      result ->
        raise_version_error(:unexpected_result, prefix, result)
    end
  end

  defp catalog_result(opts, query, prefix) do
    case Map.fetch(opts, :query_result) do
      {:ok, result} -> result
      :error -> Map.get_lazy(opts, :repo, fn -> repo() end).query(query, [prefix], log: false)
    end
  end

  defp parse_version!(version, prefix) do
    case Integer.parse(version) do
      {parsed, ""} when parsed >= @initial_version and parsed <= @current_version -> parsed
      {_parsed, ""} -> raise_version_error(:out_of_range, prefix)
      _ -> raise_version_error(:invalid_comment, prefix)
    end
  end

  @spec raise_version_error(atom(), String.t()) :: no_return()
  defp raise_version_error(reason, prefix), do: raise_version_error(reason, prefix, nil)

  @spec raise_version_error(atom(), String.t(), term()) :: no_return()
  defp raise_version_error(reason, prefix, cause) do
    raise Mailglass.MigrationVersionError.new(reason,
            package: :mailglass_inbound,
            prefix: prefix,
            cause: cause
          )
  end

  defp change(range, direction, opts) do
    for index <- range do
      pad_idx = String.pad_leading(to_string(index), 2, "0")

      [__MODULE__, "V#{pad_idx}"]
      |> Module.concat()
      |> apply(direction, [migration_opts(opts, index)])
    end

    case direction do
      :up ->
        record_version(opts, Enum.max(range))

      :down ->
        target = Enum.min(range) - 1
        record_version(opts, target)
        # Drop the schema only on a full teardown to version 0 — after every
        # v01 table is gone (INB-02). Partial down-migrations that don't reach
        # 0 leave the schema in place. RESTRICT (never CASCADE) so a non-empty
        # schema fails loudly instead of silently nuking adopter objects (T-135-04).
        if target == 0, do: maybe_drop_schema(opts)
    end

    :ok
  end

  defp maybe_create_schema(%{prefix: prefix, create_schema: true}) do
    # Re-validate before interpolation as the single unquoted-identifier
    # chokepoint (T-135-03), even though the value is operator config, not
    # request input. `inspect/1` double-quotes it.
    validate_identifier!(prefix, :prefix)
    execute(~s(CREATE SCHEMA IF NOT EXISTS #{inspect(prefix)}))
  end

  defp maybe_create_schema(_), do: :ok

  defp maybe_drop_schema(%{prefix: prefix, create_schema: true}) do
    validate_identifier!(prefix, :prefix)

    # A configured schema may be shared with core or contain adopter-owned
    # relations. Keep the RESTRICT attempt inside PostgreSQL's exception block:
    # it catches only 2BP01 without aborting Ecto's migration transaction, while
    # every other database error still propagates.
    execute("""
    DO $$
    BEGIN
      DROP SCHEMA IF EXISTS #{inspect(prefix)} RESTRICT;
    EXCEPTION WHEN dependent_objects_still_exist THEN
      NULL;
    END
    $$;
    """)
  end

  defp maybe_drop_schema(_), do: :ok

  defp record_version(_opts, 0), do: :ok

  defp record_version(%{prefix: prefix}, version) do
    # `prefix` is validated by `with_defaults/2` before reaching here.
    # Inbound version anchor: pg_class comment on `mailglass_inbound_records`
    # (independent from core's `mailglass_events` anchor).
    validate_identifier!(prefix, :prefix)
    execute("COMMENT ON TABLE #{inspect(prefix)}.mailglass_inbound_records IS '#{version}'")
  end

  defp with_defaults(opts, version) do
    opts
    |> Enum.into(%{prefix: @default_prefix, version: version})
    |> then(fn o ->
      validate_identifier!(o.prefix, :prefix)

      o
      |> Map.put(:quoted_prefix, inspect(o.prefix))
      |> Map.put(:escaped_prefix, String.replace(o.prefix, "'", "\\'"))
      |> Map.put_new(:create_schema, o.prefix != @default_prefix)
    end)
  end

  # V02 can safely expose concurrent DDL only when a generated host wrapper
  # disables Ecto's migration transaction. The migration runner consumes this explicit
  # contract; direct legacy wrappers remain transaction-safe meanwhile.
  defp migration_opts(opts, 2),
    do: Map.put(opts, :concurrent_indexes, Map.get(opts, :non_transactional_wrapper, false))

  defp migration_opts(opts, _index), do: opts

  defp validate_identifier!(value, key), do: Mailglass.Identifier.validate!(value, key)
end
