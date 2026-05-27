defmodule MailglassInbound.Router.Route do
  @moduledoc false

  @type matcher :: String.t() | Regex.t()
  @type header_match :: {String.t(), matcher()}

  @type t :: %__MODULE__{
          mailbox: module(),
          recipient: matcher() | nil,
          subject: matcher() | nil,
          headers: [header_match()],
          source: {String.t(), pos_integer()} | nil
        }

  # `:source` is additive, internal reflection metadata captured at compile time
  # (`{file, line}` via `__CALLER__` in `Router.route/2`). It lets
  # `MailglassInbound.Internal.Doctor` name `router.ex:LINE` in route-conflict
  # findings (the design contract) without changing runtime match semantics.
  defstruct [:mailbox, :recipient, :subject, :source, headers: []]
end
