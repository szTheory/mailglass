defmodule Mailglass.Adapter do
  @moduledoc """
  Behaviour every mailglass adapter implements (TRANS-01).

  Return shape is locked in `docs/api_stability.md` §Adapter. Changes to
  the callback signature are semver-breaking.

  ## Contract

  On success: `{:ok, %{message_id: String.t(), provider_response: term()}}`.
  The `:message_id` is the adapter's canonical identifier for this
  delivery — Phase 4 webhook ingest uses it to join incoming events to
  the `%Delivery{}` row via `provider_message_id`.

  On failure: `{:error, %Mailglass.Error{}}`. Return struct must be a
  subtype of `%Mailglass.Error{}` — callers pattern-match by struct,
  never by message string. `%Mailglass.SendError{type: :adapter_failure}`
  is the canonical wrap for downstream provider errors.

  ## Adapters in this repo

  - `Mailglass.Adapters.Fake` (TRANS-02) — in-memory, Swoosh.Sandbox-style
    ownership. The merge-blocking release gate (D-13).
  - `Mailglass.Adapters.Swoosh` (TRANS-03) — wraps any `Swoosh.Adapter`
    (Postmark, SendGrid, Mailgun, SES, Resend, SMTP). Normalizes errors
    into `%Mailglass.SendError{}`.

  Adopters implement custom adapters by conforming to this behaviour.
  """

  @type deliver_ok :: %{required(:message_id) => String.t(), required(:provider_response) => term()}

  @callback deliver(Mailglass.Message.t(), keyword()) ::
              {:ok, deliver_ok()} | {:error, Mailglass.Error.t()}
end
