defmodule Mailglass.IdempotencyKey do
  @moduledoc """
  Generates deterministic idempotency keys for webhook deduplication and
  event-ledger entries.

  Keys follow the format locked in CORE-05:

    * `for_webhook_event(provider, event_id)` → `"provider:event_id"`
    * `for_provider_message_id(provider, message_id)` → `"provider:msg:message_id"`

  The `msg:` infix on provider-message-id keys keeps the two namespaces
  disjoint so a webhook event id and a provider message id that happen to
  share a string value never collide in the `UNIQUE` partial index.

  ## Sanitization (T-IDEMP-001)

  Keys are derived from provider-supplied strings that reach us across a
  trust boundary. Two normalization passes run on every key:

    1. Non-ASCII-printable bytes (outside `0x20..0x7E`) are stripped —
       control characters, DEL, and UTF-8 continuation bytes alike. The
       resulting key is pure printable ASCII.
    2. The key is truncated at `#{512}` bytes so malicious or malformed
       input cannot balloon the row size or the unique-index b-tree.

  Both passes happen before the key is written to the events ledger, so
  the ledger itself never sees a non-printable byte.
  """

  @max_length 512

  @doc """
  Builds an idempotency key for a webhook event.

  ## Examples

      iex> Mailglass.IdempotencyKey.for_webhook_event(:postmark, "evt_abc")
      "postmark:evt_abc"

      iex> Mailglass.IdempotencyKey.for_webhook_event(:postmark, "evt\x00abc")
      "postmark:evtabc"
  """
  @doc since: "0.1.0"
  @spec for_webhook_event(atom(), String.t()) :: String.t()
  def for_webhook_event(provider, event_id)
      when is_atom(provider) and is_binary(event_id) do
    sanitize("#{provider}:#{event_id}")
  end

  @doc """
  Builds a per-batch-event idempotency key for SendGrid batch payloads.

  Each event in a batch gets `"\#{provider}:\#{provider_event_id}:\#{index}"`
  so duplicate inserts of the same batch event collapse via the
  `mailglass_events.idempotency_key` partial UNIQUE index (Phase 2 Plan
  05 DDL). Single-event Postmark payloads use `for_webhook_event/2`
  without the index suffix.

  Phase 4 extension per CONTEXT line 343 (Plan 04-06).

  ## Examples

      iex> Mailglass.IdempotencyKey.for_webhook_event(:sendgrid, "evt_X", 0)
      "sendgrid:evt_X:0"

      iex> Mailglass.IdempotencyKey.for_webhook_event(:postmark, "abc-123", 5)
      "postmark:abc-123:5"
  """
  @doc since: "0.1.0"
  @spec for_webhook_event(atom(), String.t(), non_neg_integer()) :: String.t()
  def for_webhook_event(provider, event_id, index)
      when is_atom(provider) and is_binary(event_id) and is_integer(index) and index >= 0 do
    sanitize("#{provider}:#{event_id}:#{index}")
  end

  @doc """
  Builds an idempotency key for a provider-assigned message id.

  ## Examples

      iex> Mailglass.IdempotencyKey.for_provider_message_id(:sendgrid, "SG.abc")
      "sendgrid:msg:SG.abc"
  """
  @doc since: "0.1.0"
  @spec for_provider_message_id(atom(), String.t()) :: String.t()
  def for_provider_message_id(provider, message_id)
      when is_atom(provider) and is_binary(message_id) do
    sanitize("#{provider}:msg:#{message_id}")
  end

  # Strip anything outside ASCII printable range (including UTF-8
  # continuation bytes, control characters 0x00-0x1F, and DEL 0x7F) then
  # cap at @max_length bytes. `String.slice/2` operates on codepoints;
  # because the prior `String.replace/3` leaves only single-byte ASCII,
  # codepoint count == byte count and the 512-byte cap holds exactly.
  @spec sanitize(String.t()) :: String.t()
  defp sanitize(key) do
    key
    |> String.replace(~r/[^\x20-\x7E]/, "")
    |> String.slice(0, @max_length)
  end
end
