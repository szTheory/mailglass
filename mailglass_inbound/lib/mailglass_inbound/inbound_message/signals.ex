defmodule MailglassInbound.InboundMessage.Signals do
  @moduledoc """
  Framework-derived, read-only signals about an inbound message.

  `Signals` is the typed nested struct carried on
  `MailglassInbound.InboundMessage`'s `:signals` field. It follows the
  `Ecto.Schema.Metadata` (`__meta__`) archetype: **the framework writes these
  facts; the adopter reads them.** Adopters never construct or mutate a `Signals`
  struct — they pattern-match it or read its fields inside a mailbox `process/1`
  callback.

  ## Closed contract

  Every field is enumerated, defaulted, and non-nil. Today the only signal is:

    * `:suppression_flagged` — `true` when the message's first `from` address is
      on the tenant's suppression list at receipt time. It is a
      diagnostic signal only: there is no auto-bounce and no auto-suppression
      (the design contract). The adopter decides whether to reject, ignore, or process.

  Because every field has a non-nil default, safe dot-access
  (`message.signals.suppression_flagged`) never raises a `KeyError` — including
  for records persisted before a given signal column existed, which project
  through the schema's column default.

  This struct holds framework-derived facts only and is distinct from the
  adopter-owned application data that lives elsewhere in the framework — see
  `MailglassInbound.InboundMessage`'s the design contract note for the naming rationale.

  ## Evolution

  Future derived signals (for example `spf_pass`, `dkim_pass`, `dmarc_pass`,
  `spam_score`, `auto_response`) each become a new typed field on this struct,
  each carrying its own `@since` and CHANGELOG entry under a linked minor bump.
  Additive only — existing pattern-matches keep working.
  """

  @typedoc "Framework-owned read-only inbound signals. Every field is defaulted and non-nil."
  @type t :: %__MODULE__{
          suppression_flagged: boolean()
        }

  @doc since: "1.2.0"
  defstruct suppression_flagged: false
end
