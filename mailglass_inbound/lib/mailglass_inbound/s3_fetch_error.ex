defmodule MailglassInbound.S3FetchError do
  @moduledoc since: "0.2.0"
  @moduledoc """
  Structured error for AWS SES inbound S3-object fetch failures.

  Raised when the SES receipt-rule S3 action object cannot be retrieved and fed
  into `MailglassInbound.MIME.parse/1`. Mirrors the shape of
  `MailglassInbound.MIMEError` / `Mailglass.ConfigError` — a closed `:type` atom
  set, a `[:type, :message, :cause, :context]` `defexception`, and a
  `Jason.Encoder` derivation that **excludes `:cause`** so raw S3/error fragments
  never leak into serialized output (logs, telemetry, admin). Match on the struct
  and `:type`, never on the message string.

  This struct is **package-local**: it does NOT implement the core
  `Mailglass.Error` behaviour and does NOT join `Mailglass.Error`'s `@type`
  union. It is a plain `defexception` with a `__types__/0` contract helper.

  ## Types

  - `:s3_object_not_ready` — the bounded `GetObject` retry was exhausted before
    the object became readable. This is the **transient** path: the handler does
    NOT ack, so SNS redelivers and the dedupe layer is the real safety net.
  - `:s3_fetch_failed` — a non-retryable S3 error (access denied, bucket missing,
    malformed key, gateway/exit failure). Retrying will not help.

  See `docs/api_stability.md` (mailglass_inbound) for the locked `:type` atom
  set. Adding a value requires a CHANGELOG entry + `@since` annotation (minor
  version bump); removing a value requires a major version bump.
  """

  @types [:s3_object_not_ready, :s3_fetch_failed]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context]

  @type t :: %__MODULE__{
          type: :s3_object_not_ready | :s3_fetch_failed,
          message: String.t(),
          cause: term() | nil,
          context: map()
        }

  @doc "Returns the closed set of valid `:type` atoms. Tested against `docs/api_stability.md`."
  @doc since: "0.2.0"
  def __types__, do: @types

  @impl true
  def message(%__MODULE__{message: m}), do: m
end
