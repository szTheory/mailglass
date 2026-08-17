defmodule Mailglass.Runtime do
  @moduledoc false

  alias Mailglass.Runtime.Schema

  @schema_key {Mailglass.Config, :schema}
  @theme_key {Mailglass.Config, :theme}
  @runtime_key {__MODULE__, :current}

  @opaque t :: %__MODULE__{config: keyword()}
  defstruct [:config]

  @doc false
  @spec validate!(keyword()) :: keyword()
  def validate!(opts), do: Schema.validate!(opts)

  @doc false
  @spec bootstrap!() :: t()
  def bootstrap! do
    opts =
      :mailglass
      |> Application.get_all_env()
      |> Keyword.take(Schema.known_keys())

    validated =
      opts
      |> validate!()
      |> normalize_runtime_config()

    _schema = validated |> Keyword.fetch!(:schema) |> Mailglass.Identifier.validate!(:schema)
    validate_repo_adapter!(Keyword.fetch!(validated, :repo))
    runtime = %__MODULE__{config: validated}

    # Publish only after the entire value is valid. The legacy keys remain for
    # compatibility with existing hot paths and test-support reset helpers.
    :persistent_term.put(@schema_key, Keyword.fetch!(validated, :schema))
    :persistent_term.put(@theme_key, Keyword.fetch!(validated, :theme))
    :persistent_term.put(@runtime_key, runtime)

    if Keyword.get(Keyword.fetch!(validated, :telemetry), :default_logger, false) do
      _ = Mailglass.Telemetry.attach_default_logger()
    end

    runtime
  end

  @doc false
  @spec current() :: t()
  def current do
    case :persistent_term.get(@runtime_key, :__miss__) do
      %__MODULE__{} = runtime -> runtime
      :__miss__ -> bootstrap!()
    end
  end

  @doc false
  @spec fetch!(t(), atom()) :: term()
  def fetch!(%__MODULE__{config: config}, key), do: Keyword.fetch!(config, key)

  @doc false
  @spec fetch!(atom()) :: term()
  def fetch!(key), do: current() |> fetch!(key)

  @doc false
  @spec get(atom(), term()) :: term()
  def get(key, default \\ nil), do: current().config |> Keyword.get(key, default)

  @doc false
  @spec schema() :: String.t()
  def schema do
    case :persistent_term.get(@schema_key, :__miss__) do
      schema when is_binary(schema) -> schema
      :__miss__ -> fetch!(:schema)
    end
  end

  @doc false
  @spec reset_for_test!() :: :ok
  def reset_for_test! do
    :persistent_term.erase(@schema_key)
    :persistent_term.erase(@theme_key)
    :persistent_term.erase(@runtime_key)
    :ok
  end

  defp validate_repo_adapter!(nil), do: :ok

  defp validate_repo_adapter!(repo) when is_atom(repo) do
    if Code.ensure_loaded?(repo) and function_exported?(repo, :__adapter__, 0) do
      case repo.__adapter__() do
        Ecto.Adapters.Postgres ->
          :ok

        other ->
          raise Mailglass.ConfigError.new(:invalid,
                  context: %{
                    key: :repo,
                    adapter: other,
                    reason: "Postgres only at v0.1"
                  }
                )
      end
    else
      :ok
    end
  end

  defp normalize_runtime_config(validated) do
    Keyword.update!(validated, :adapter, fn
      module when is_atom(module) -> {module, []}
      {module, opts} -> {module, opts}
    end)
  end
end
