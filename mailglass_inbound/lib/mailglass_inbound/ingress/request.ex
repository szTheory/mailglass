defmodule MailglassInbound.Ingress.Request do
  @moduledoc false

  @enforce_keys [:provider, :headers]
  defstruct [
    :provider,
    :raw_body,
    :params,
    :raw_mime,
    :content_type,
    headers: []
  ]

  @type t :: %__MODULE__{
          provider: atom(),
          raw_body: binary() | nil,
          headers: [{String.t(), String.t()}],
          params: map() | nil,
          raw_mime: binary() | nil,
          content_type: String.t() | nil
        }
end
