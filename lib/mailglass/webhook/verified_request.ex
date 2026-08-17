defmodule Mailglass.Webhook.VerifiedRequest do
  @moduledoc false

  @enforce_keys [:raw_body, :decoded]
  defstruct [:raw_body, :decoded]

  @type decoded :: {:ok, term()} | {:error, term()}
  @type t :: %__MODULE__{raw_body: binary(), decoded: decoded()}

  @spec decode(binary(), (binary() -> decoded())) :: t()
  def decode(raw_body, decoder \\ &Jason.decode/1)
      when is_binary(raw_body) and is_function(decoder, 1) do
    decoded =
      try do
        case decoder.(raw_body) do
          {:ok, _payload} = result -> result
          {:error, _reason} = result -> result
          _ -> {:error, :invalid_json}
        end
      rescue
        _ -> {:error, :invalid_json}
      end

    %__MODULE__{raw_body: raw_body, decoded: decoded}
  end

  @spec payload_or_nil(t()) :: map() | list() | nil
  def payload_or_nil(%__MODULE__{decoded: {:ok, payload}}) when is_map(payload) or is_list(payload),
    do: payload

  def payload_or_nil(%__MODULE__{}), do: nil
end
