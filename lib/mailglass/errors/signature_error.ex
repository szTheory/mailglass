defmodule Mailglass.SignatureError do
  @moduledoc """
  Raised when webhook signature verification fails.

  Webhook signature errors are never retryable — the caller is either
  misconfigured (wrong secret) or the request is a forgery. Let the
  process crash under supervision and surface a 4xx to the provider.

  ## Types

  The closed atom set is extended per   from the original
  four-atom  set to the seven-atom webhook-ingest set. The legacy
  atoms (`:missing`, `:malformed`, `:mismatch`) remain in the set for
  backward compatibility with any code that already raises them; 
  formally hardens the migration with `api_stability.md` documentation
  and final message wording.

  - `:missing_header` — the provider's signature header is not present on the request
  - `:malformed_header` — the header is present but cannot be parsed (bad Base64, missing prefix)
  - `:bad_credentials` — Postmark Basic Auth user/pass mismatch (`Plug.Crypto.secure_compare/2` returned false)
  - `:ip_disallowed` — Postmark IP allowlist mismatch (opt-in; )
  - `:bad_signature` — HMAC/ECDSA math returned false; collapses `:tampered_body` per 
  - `:timestamp_skew` — the signed timestamp is outside the acceptable window
  - `:malformed_key` — PEM/DER decode failure at config validate-at-boot time
  - `:missing` — (legacy) alias of `:missing_header`; retained until  consolidates
  - `:malformed` — (legacy) alias of `:malformed_header`; retained until  consolidates
  - `:mismatch` — (legacy) alias of `:bad_signature`; retained until  consolidates

  ## Per-kind Fields

  - `:provider` — the provider atom (`:postmark`, `:sendgrid`, `:mailgun`, …)
    that rejected the request.

  See `Mailglass.Error` for the shared contract and `docs/api_stability.md`
  for the locked `:type` atom set.
  """

  @behaviour Mailglass.Error

  #   extends the atom set from 4 to 7. The legacy atoms
  # (`:missing`, `:malformed`, `:mismatch`) are retained so 's
  # error_test.exs assertions and any raise sites outside this module
  # continue to work.  consolidates naming + `api_stability.md`.
  @types [
    :missing_header,
    :malformed_header,
    :bad_credentials,
    :ip_disallowed,
    :bad_signature,
    :timestamp_skew,
    :malformed_key,
    # Legacy:
    :missing,
    :malformed,
    :mismatch
  ]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context, :provider]

  @type t :: %__MODULE__{
          type:
            :missing_header
            | :malformed_header
            | :bad_credentials
            | :ip_disallowed
            | :bad_signature
            | :timestamp_skew
            | :malformed_key
            | :missing
            | :malformed
            | :mismatch,
          message: String.t(),
          cause: Exception.t() | nil,
          context: %{atom() => term()},
          provider: atom() | nil
        }

  @doc "Returns the closed set of valid `:type` atoms. Tested against `docs/api_stability.md`."
  @doc since: "0.1.0"
  def __types__, do: @types

  @impl Mailglass.Error
  def type(%__MODULE__{type: t}), do: t

  @impl Mailglass.Error
  def retryable?(%__MODULE__{}), do: false

  @impl true
  def message(%__MODULE__{type: type, context: ctx}) do
    format_message(type, ctx || %{})
  end

  @doc """
  Build a `Mailglass.SignatureError` struct.

  ## Options

  - `:cause` — an underlying exception to wrap (kept out of JSON output).
  - `:context` — a map of non-PII metadata about the request.
  - `:provider` — the provider atom that rejected the request.
  """
  @doc since: "0.1.0"
  @spec new(atom(), keyword()) :: t()
  def new(type, opts \\ []) when type in @types do
    ctx = opts[:context] || %{}

    %__MODULE__{
      type: type,
      message: format_message(type, ctx),
      cause: opts[:cause],
      context: ctx,
      provider: opts[:provider]
    }
  end

  #   messages. Brand voice per CLAUDE.md (thoughtful
  # maintainer): specific, composed, never "Oops!" — each message names
  # the failure mode in atom-aligned terms so operators can correlate
  # Logger output with the typed :type field.
  defp format_message(:missing_header, _ctx),
    do: "Webhook signature failed: signature header is missing"

  defp format_message(:malformed_header, ctx) do
    detail = ctx[:detail]
    base = "Webhook signature failed: signature header is malformed"
    if detail, do: base <> " (#{detail})", else: base
  end

  defp format_message(:bad_credentials, _ctx),
    do: "Webhook signature failed: credentials do not match the configured pair"

  defp format_message(:ip_disallowed, _ctx),
    do: "Webhook signature failed: source IP is not in the configured allowlist"

  defp format_message(:bad_signature, _ctx),
    do: "Webhook signature failed: signature does not verify against the configured key"

  defp format_message(:timestamp_skew, _ctx),
    do: "Webhook signature failed: timestamp is outside the acceptable tolerance window"

  defp format_message(:malformed_key, _ctx),
    do: "Webhook verification key failed to decode (DER/Base64 invalid; check your provider config)"

  #  legacy messages — preserved verbatim.
  defp format_message(:missing, _ctx),
    do: "Webhook signature verification failed: signature header is missing"

  defp format_message(:malformed, _ctx),
    do: "Webhook signature verification failed: signature is malformed"

  defp format_message(:mismatch, _ctx),
    do: "Webhook signature verification failed: signature does not match"
end
