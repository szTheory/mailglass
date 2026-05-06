defmodule MailglassInbound.Router.Route do
  @moduledoc false

  @type matcher :: String.t() | Regex.t()
  @type header_match :: {String.t(), matcher()}

  @type t :: %__MODULE__{
          mailbox: module(),
          recipient: matcher() | nil,
          subject: matcher() | nil,
          headers: [header_match()]
        }

  defstruct [:mailbox, :recipient, :subject, headers: []]
end
