defmodule MailglassInbound.Ingress.Provider do
  @moduledoc false

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.Ingress.{Request, VerifiedRequest}

  @type normalized_t :: %{
          required(:message) => InboundMessage.t(),
          required(:evidence) => map()
        }

  @type request_t :: Request.t()

  @typedoc """
  PII-free verification facts threaded into the evidence map's
  `:verification_facts` on a successful (persisting) verify.
  """
  @type verification_facts :: map()

  # Widened `verify!` contract (the design contract, the design contract). The struct-arity
  # `verify!(%Request{}, config)` is the unified shape all four providers trend
  # toward (SendGrid already uses it); the return widens to a three-variant union
  # so the plug's `do_call/2` can express non-persisting verified outcomes the
  # legacy `:: map()` return could not:
  #
  #   * `{:ok, verification_facts}` — verified, PERSIST (existing path).
  #   * `{:replay}`                 — Mailgun replay hit → 200 no-op, NO record.
  #   * `{:control_plane, status}`  — SES SNS Subscription/Unsubscribe confirmation
  #                                   → 200 no-op, NO record.
  #
  # Forged input RAISES a `SignatureError` (core `Mailglass.SignatureError` or the
  # net-new `MailglassInbound.SignatureError`) and is NOT a tuple variant — the
  # plug rescues both and maps to 401.
  #
  # NOTE: Postmark continues to expose the legacy `verify!/3` arity returning a
  # bare `map()` (treated as persist by the plug). The plug dispatches
  # per-provider, so a mixed-arity transition is acceptable within this phase;
  # Plans 02/03 wire the new providers to the struct arity.
  @callback verify!(request :: Request.t(), config :: map()) ::
              {:ok, VerifiedRequest.t() | verification_facts()}
              | {:replay}
              | {:control_plane, http_status :: pos_integer()}
              | verification_facts()

  # Legacy `verify!/3` arity, retained so Postmark (and SendGrid's compatibility
  # shim) keep a valid `@impl MailglassInbound.Ingress.Provider` annotation
  # without edits to their bodies. Postmark returns a bare `map()` (treated as
  # persist by the plug). New providers (Mailgun/SES, Plans 02/03) implement the
  # struct-arity `verify!/2` above. This dual-arity declaration is the
  # mixed-arity transition surface for this phase.
  @callback verify!(
              raw_body :: binary(),
              headers :: [{String.t(), String.t()}],
              config :: map()
            ) :: verification_facts()

  @callback normalize(
              raw_body :: binary(),
              headers :: [{String.t(), String.t()}]
            ) :: normalized_t()

  @callback resolve_content!(VerifiedRequest.t(), config :: map()) :: VerifiedRequest.t()

  # Mixed-arity transition (the design contract): a provider implements EXACTLY ONE `verify!`
  # arity — Postmark the legacy `verify!/3`, SendGrid/Mailgun/SES the struct
  # `verify!/2`. Marking both optional lets each provider compile warning-free
  # while the plug dispatches the right arity per provider. `normalize/2` stays
  # required for the legacy providers; struct-arity `normalize/1` callers (Mailgun
  # /SES) dispatch through the plug's per-provider `normalize_request!/2` clauses.
  @optional_callbacks verify!: 2, verify!: 3, resolve_content!: 2
end
