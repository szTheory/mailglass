defmodule MailglassInbound.Ingress.VerifiedRequest do
  @moduledoc false

  alias MailglassInbound.Ingress.Request

  @enforce_keys [:request, :raw_body, :envelope, :verification_facts, :warnings]
  defstruct [:request, :raw_body, :envelope, :verification_facts, :warnings, :raw_mime]

  @opaque t :: %__MODULE__{
            request: Request.t(),
            raw_body: binary(),
            envelope: map(),
            verification_facts: map(),
            warnings: map(),
            raw_mime: binary() | nil
          }
end
