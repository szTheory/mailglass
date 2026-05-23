defmodule MailglassInbound.SignatureError do
  @moduledoc """
  Structured, **no-recovery** error for inbound provider signature failures
  (Mailgun HMAC, AWS SES SNS X.509, and SNS `SubscribeURL` trust-policy checks).

  Webhook signature errors are never retryable — the caller is either
  misconfigured (wrong signing key) or the request is a forgery. The plug maps
  this to a 4xx and lets the request fail closed; there is **no** recovery path
  (CLAUDE.md "Things Not To Do" #5 / D-22). This struct mirrors the no-recovery
  contract of core `Mailglass.SignatureError` while staying package-local.

  It follows the same closed-`:type` discipline as
  `MailglassInbound.MIMEError` — a closed `:type` atom set, a
  `[:type, :message, :cause, :context, :provider]` `defexception`, and a
  `Jason.Encoder` derivation that **excludes `:cause` and `:provider`** so signing
  secrets and raw payload fragments never leak into serialized output (logs,
  telemetry, admin). Match on the struct and `:type`, never on the message string.

  This struct is **package-local**: it does NOT implement the core
  `Mailglass.Error` behaviour and does NOT join `Mailglass.Error`'s `@type`
  union (that behaviour and union live in `mailglass` core). It is a plain
  `defexception` with a `__types__/0` contract helper and a `new/2` builder.

  ## Types

  - `:bad_signature` — HMAC/X.509 signature math did not verify against the
    configured key (forged or tampered request).
  - `:missing_header` — a required signing field/header is absent from the request.
  - `:malformed_header` — a signing field/header is present but cannot be parsed
    (bad Base64, missing prefix, unknown signature version).
  - `:timestamp_skew` — the signed timestamp is outside the acceptable tolerance
    window (Mailgun replay-window protection).
  - `:subscribe_url_untrusted` — an SNS `SubscribeURL`/`SigningCertURL` failed
    `TrustPolicy` validation (SSRF / hijack guard).

  ## Per-kind Fields

  - `:provider` — the provider atom (`:mailgun`, `:ses`, …) that rejected the
    request. Excluded from JSON output.

  See `docs/api_stability.md` (mailglass_inbound) for the locked `:type` atom
  set. Adding a value requires a CHANGELOG entry + `@since` annotation (minor
  version bump); removing a value requires a major version bump.
  """

  @types [:bad_signature, :missing_header, :malformed_header, :timestamp_skew, :subscribe_url_untrusted]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context, :provider]

  @type t :: %__MODULE__{
          type:
            :bad_signature
            | :missing_header
            | :malformed_header
            | :timestamp_skew
            | :subscribe_url_untrusted,
          message: String.t(),
          cause: term() | nil,
          context: map(),
          provider: atom() | nil
        }

  @doc "Returns the closed set of valid `:type` atoms. Tested against `docs/api_stability.md`."
  @doc since: "0.2.0"
  def __types__, do: @types

  @impl true
  def message(%__MODULE__{message: m}), do: m

  @doc """
  Build a `MailglassInbound.SignatureError` struct.

  Validates `type` against the closed `__types__/0` set (raises `ArgumentError`
  otherwise) and formats a per-type, brand-voiced message. Mirrors core
  `Mailglass.SignatureError.new/2` semantics while staying package-local.

  ## Options

  - `:cause` — an underlying exception/term to wrap (kept out of JSON output).
  - `:context` — a map of non-PII metadata about the request.
  - `:provider` — the provider atom that rejected the request (kept out of JSON).
  """
  @doc since: "0.2.0"
  @spec new(atom(), keyword()) :: t()
  def new(type, opts \\ [])

  def new(type, opts) when type in @types do
    ctx = opts[:context] || %{}

    %__MODULE__{
      type: type,
      message: format_message(type, ctx),
      cause: opts[:cause],
      context: ctx,
      provider: opts[:provider]
    }
  end

  def new(type, _opts) do
    raise ArgumentError,
          "MailglassInbound.SignatureError: #{inspect(type)} is not a valid :type. " <>
            "Valid types: #{inspect(@types)}"
  end

  # Brand voice per CLAUDE.md (thoughtful maintainer): specific, composed, never
  # "Oops!" — each message names the failure mode in atom-aligned terms so
  # operators can correlate Logger output with the typed :type field.
  defp format_message(:bad_signature, _ctx),
    do: "Inbound signature failed: signature does not verify against the configured key"

  defp format_message(:missing_header, _ctx),
    do: "Inbound signature failed: a required signing field is missing"

  defp format_message(:malformed_header, ctx) do
    detail = ctx[:detail]
    base = "Inbound signature failed: a signing field is malformed"
    if detail, do: base <> " (#{detail})", else: base
  end

  defp format_message(:timestamp_skew, _ctx),
    do: "Inbound signature failed: timestamp is outside the acceptable tolerance window"

  defp format_message(:subscribe_url_untrusted, _ctx),
    do: "Inbound signature failed: the SNS URL failed trust-policy validation"
end
