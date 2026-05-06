defmodule MailglassInbound.Ingress.Provider do
  @moduledoc false

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.Ingress.Request

  @type normalized_t :: %{
          required(:message) => InboundMessage.t(),
          required(:evidence) => map()
        }

  @type request_t :: Request.t()

  @callback verify!(
              raw_body :: binary(),
              headers :: [{String.t(), String.t()}],
              config :: map()
            ) :: map()

  @callback normalize(
              raw_body :: binary(),
              headers :: [{String.t(), String.t()}]
            ) :: normalized_t()
end
