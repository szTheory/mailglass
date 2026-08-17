defmodule Mailglass.Runtime do
  @moduledoc false

  # Keep the established key for the first migrated slice. Test/support code
  # deliberately erases it when changing the process-global app environment.
  @schema_key {Mailglass.Config, :schema}
  @runtime_key {__MODULE__, :current}

  @opaque t :: %__MODULE__{schema: String.t()}
  defstruct [:schema]

  @doc false
  @spec bootstrap!() :: t()
  def bootstrap! do
    Application.get_env(:mailglass, :schema, "mailglass")
    |> bootstrap!()
  end

  @doc false
  @spec bootstrap!(String.t()) :: t()
  def bootstrap!(schema) when is_binary(schema) do
    validated_schema = Mailglass.Identifier.validate!(schema, :schema)
    runtime = %__MODULE__{schema: validated_schema}

    :persistent_term.put(@schema_key, validated_schema)
    :persistent_term.put(@runtime_key, runtime)
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
  @spec schema() :: String.t()
  def schema do
    case :persistent_term.get(@schema_key, :__miss__) do
      schema when is_binary(schema) -> schema
      :__miss__ -> bootstrap!().schema
    end
  end

  @doc false
  @spec reset_for_test!() :: :ok
  def reset_for_test! do
    :persistent_term.erase(@schema_key)
    :persistent_term.erase(@runtime_key)
    :ok
  end
end
