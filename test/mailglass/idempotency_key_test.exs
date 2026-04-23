defmodule Mailglass.IdempotencyKeyTest do
  use ExUnit.Case, async: true

  # CORE-05: `Mailglass.IdempotencyKey` produces deterministic dedup keys
  # for the webhook ingest path (Phase 4) and the provider-message-id
  # dedup surface (Phase 3). Keys are sanitized (`[^\x20-\x7E]` stripped)
  # and length-capped at 512 chars before they land in the UNIQUE partial
  # index on the events ledger.

  describe "for_webhook_event/2" do
    test "produces deterministic keys in 'provider:event_id' format" do
      assert Mailglass.IdempotencyKey.for_webhook_event(:postmark, "evt_abc123") ==
               "postmark:evt_abc123"
    end

    test "is deterministic — same inputs produce same key" do
      key1 = Mailglass.IdempotencyKey.for_webhook_event(:sendgrid, "sg_evt_1")
      key2 = Mailglass.IdempotencyKey.for_webhook_event(:sendgrid, "sg_evt_1")
      assert key1 == key2
    end

    test "sanitizes control characters from keys (T-IDEMP-001)" do
      key = Mailglass.IdempotencyKey.for_webhook_event(:postmark, "evil\x00\x01key")
      refute String.contains?(key, <<0x00>>)
      refute String.contains?(key, <<0x01>>)
      assert key == "postmark:evilkey"
    end

    test "strips DEL (0x7F) and other non-printable ASCII" do
      key = Mailglass.IdempotencyKey.for_webhook_event(:postmark, "hello\x7Fworld")
      assert key == "postmark:helloworld"
    end

    test "sanitizes non-ASCII characters from keys" do
      key = Mailglass.IdempotencyKey.for_webhook_event(:postmark, "keyé中文")
      # All remaining bytes are ASCII printable (0x20-0x7E)
      for <<byte <- key>> do
        assert byte in 0x20..0x7E
      end
      assert key == "postmark:key"
    end

    test "truncates keys longer than 512 characters" do
      long_id = String.duplicate("x", 600)
      key = Mailglass.IdempotencyKey.for_webhook_event(:postmark, long_id)
      assert byte_size(key) <= 512
    end

    test "different providers produce different keys for the same event_id" do
      assert Mailglass.IdempotencyKey.for_webhook_event(:postmark, "shared") !=
               Mailglass.IdempotencyKey.for_webhook_event(:sendgrid, "shared")
    end
  end

  describe "for_webhook_event/3 (batch index form — CONTEXT line 343)" do
    test "sanitizes the per-batch index form" do
      # SendGrid batches: each event in the array gets a :index-qualified key
      # so the UNIQUE partial index on `mailglass_events.idempotency_key`
      # dedupes per-event, not per-batch.
      assert Mailglass.IdempotencyKey.for_webhook_event(:postmark, "abc-123", 0) ==
               "postmark:abc-123:0"

      assert Mailglass.IdempotencyKey.for_webhook_event(:sendgrid, "evt_X", 5) ==
               "sendgrid:evt_X:5"
    end

    test "is deterministic — same inputs produce same key" do
      key1 = Mailglass.IdempotencyKey.for_webhook_event(:sendgrid, "sg_evt_9", 3)
      key2 = Mailglass.IdempotencyKey.for_webhook_event(:sendgrid, "sg_evt_9", 3)
      assert key1 == key2
    end

    test "index 0 and arity-2 form are distinguishable" do
      # arity-2: "postmark:abc" ; arity-3 at idx=0: "postmark:abc:0"
      refute Mailglass.IdempotencyKey.for_webhook_event(:postmark, "abc") ==
               Mailglass.IdempotencyKey.for_webhook_event(:postmark, "abc", 0)
    end

    test "sanitizes control chars inside event_id while preserving index suffix" do
      key = Mailglass.IdempotencyKey.for_webhook_event(:sendgrid, "evt\x00id", 2)
      assert key == "sendgrid:evtid:2"
    end
  end

  describe "for_provider_message_id/2" do
    test "produces 'provider:msg:message_id' format" do
      assert Mailglass.IdempotencyKey.for_provider_message_id(:sendgrid, "SG.abc") ==
               "sendgrid:msg:SG.abc"
    end

    test "namespace collision — for_webhook_event and for_provider_message_id never collide" do
      # The `msg:` infix on provider_message_id keeps the two namespaces
      # disjoint even when a provider's webhook event_id happens to equal
      # a provider_message_id string.
      refute Mailglass.IdempotencyKey.for_webhook_event(:postmark, "abc") ==
               Mailglass.IdempotencyKey.for_provider_message_id(:postmark, "abc")
    end

    test "sanitizes control chars from provider_message_id" do
      key = Mailglass.IdempotencyKey.for_provider_message_id(:postmark, "id\x00x")
      assert key == "postmark:msg:idx"
    end
  end
end
