defmodule MailglassInbound.InboundMessageTest do
  use ExUnit.Case, async: true

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundMessage.Signals

  test "package shell exposes a version helper" do
    assert is_binary(MailglassInbound.version())
  end

  test "public struct exposes only the stable normalized contract fields" do
    expected_keys =
      [
        :tenant_id,
        :provider,
        :provider_message_id,
        :message_id,
        :envelope_recipient,
        :from,
        :to,
        :cc,
        :bcc,
        :reply_to,
        :subject,
        :headers,
        :sent_at,
        :received_at,
        :text_body,
        :html_body,
        :attachments,
        :signals
      ]
      |> Enum.sort()

    actual_keys =
      InboundMessage.__struct__()
      |> Map.keys()
      |> Enum.reject(&(&1 == :__struct__))
      |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "public struct excludes raw payload and execution evidence concerns" do
    fields =
      InboundMessage.__struct__()
      |> Map.keys()
      |> Enum.reject(&(&1 == :__struct__))

    refute :raw_payload in fields
    refute :raw_mime in fields
    refute :signature_evidence in fields
    refute :replay_id in fields
    refute :mailbox_outcome in fields
    refute :storage_path in fields
    refute :provider_payload in fields
  end

  test "tenant_id and envelope_recipient are first-class routing fields" do
    message = %InboundMessage{
      tenant_id: "tenant_123",
      envelope_recipient: "support@example.com",
      to: [%{address: "visible@example.com", name: "Visible Recipient"}]
    }

    assert message.tenant_id == "tenant_123"
    assert message.envelope_recipient == "support@example.com"
    assert hd(message.to).address == "visible@example.com"
  end

  describe "framework-owned :signals nested struct (IOPS-05, D-49-21)" do
    test ":signals defaults to %Signals{} with every field defaulted and non-nil" do
      message = %InboundMessage{}

      assert %Signals{} = message.signals
      # Safe dot-access on a default-built struct never raises (Pitfall 7).
      assert message.signals.suppression_flagged == false
    end

    test "Signals is its own framework-owned struct, not a free :metadata map" do
      assert %Signals{suppression_flagged: false} = %Signals{}
      refute Map.has_key?(%InboundMessage{}, :metadata)
    end

    test "suppression_flagged?/1 returns the boolean value of the signal" do
      flagged = %InboundMessage{signals: %Signals{suppression_flagged: true}}
      clean = %InboundMessage{signals: %Signals{suppression_flagged: false}}
      defaulted = %InboundMessage{}

      assert InboundMessage.suppression_flagged?(flagged) == true
      assert InboundMessage.suppression_flagged?(clean) == false
      assert InboundMessage.suppression_flagged?(defaulted) == false
    end

    test "the flag is pattern-matchable in a function head" do
      matcher = fn
        %InboundMessage{signals: %Signals{suppression_flagged: true}} -> :suppressed
        %InboundMessage{} -> :clean
      end

      assert matcher.(%InboundMessage{signals: %Signals{suppression_flagged: true}}) ==
               :suppressed

      assert matcher.(%InboundMessage{}) == :clean
    end
  end
end
