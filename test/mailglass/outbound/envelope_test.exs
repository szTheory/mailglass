defmodule Mailglass.Outbound.EnvelopeTest do
  use ExUnit.Case, async: true

  alias Mailglass.Message
  alias Mailglass.Outbound.Envelope

  @tag phase_150_task: "t150_06_01"
  test "round-trips the complete V1 envelope with ordered duplicate collections" do
    attachment =
      Swoosh.Attachment.new({:data, "attachment bytes"},
        filename: "report.txt",
        content_type: "text/plain",
        type: :inline,
        cid: "report-cid",
        headers: [{"X-Part", "one"}, {"X-Part", "one"}]
      )

    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Mailglass", "sender@example.com"})
      |> Swoosh.Email.cc({"Recipient", "recipient@example.com"})
      |> Swoosh.Email.reply_to([{"Reply", "reply@example.com"}, {"Reply", "reply@example.com"}])
      |> Swoosh.Email.subject("Private subject")
      |> Swoosh.Email.text_body("")
      |> Swoosh.Email.html_body("<p>html body</p>")
      |> Map.put(:headers, [{"X-Trace", "one"}, {"X-Trace", "one"}])
      |> Map.put(:provider_options, nil)
      |> Map.put(:attachments, [attachment])

    message =
      Message.build(email,
        tenant_id: "tenant-150",
        mailable: __MODULE__,
        stream: :operational,
        tags: ["welcome", "welcome"],
        metadata: nil
      )

    assert {:ok, envelope} = Envelope.dump(message, adapter_ref: "primary")
    assert envelope["headers"] == [["X-Trace", "one"], ["X-Trace", "one"]]
    assert Envelope.digest(envelope) == Envelope.digest(envelope)

    assert {:ok, %Envelope.Decoded{message: restored, adapter_ref: "primary"}} =
             Envelope.load(envelope)

    assert restored.swoosh_email.from == {"Mailglass", "sender@example.com"}
    assert restored.swoosh_email.cc == [{"Recipient", "recipient@example.com"}]

    assert restored.swoosh_email.reply_to == [
             {"Reply", "reply@example.com"},
             {"Reply", "reply@example.com"}
           ]

    assert restored.swoosh_email.headers == [{"X-Trace", "one"}, {"X-Trace", "one"}]
    assert restored.swoosh_email.text_body == ""
    assert restored.swoosh_email.provider_options == nil
    assert restored.metadata == nil
    assert restored.tags == ["welcome", "welcome"]

    assert [%Swoosh.Attachment{data: "attachment bytes", path: nil, headers: headers}] =
             restored.swoosh_email.attachments

    assert headers == [{"X-Part", "one"}, {"X-Part", "one"}]
  end

  @tag phase_150_task: "t150_06_01"
  test "materializes a path attachment before its source changes or disappears" do
    path = Path.join(System.tmp_dir!(), "mailglass-envelope-#{System.unique_integer([:positive])}")
    File.write!(path, "original bytes")
    on_exit(fn -> File.rm(path) end)

    message =
      message_with_attachment(
        Swoosh.Attachment.new(path, filename: "original.txt", content_type: "text/plain")
      )

    assert {:ok, envelope} = Envelope.dump(message, adapter_ref: "primary")
    File.write!(path, "changed bytes")
    File.rm!(path)

    assert {:ok, %Envelope.Decoded{message: restored}} = Envelope.load(envelope)

    assert [%Swoosh.Attachment{data: "original bytes", path: nil}] =
             restored.swoosh_email.attachments

    refute inspect(envelope) =~ path
  end

  @tag phase_150_task: "t150_06_01"
  test "rejects malformed required fields and preserves present nil values" do
    assert {:ok, envelope} = Envelope.dump(message_with_attachment(), adapter_ref: "primary")

    assert {:error, %{type: :serialization_failed}} =
             Envelope.load(Map.delete(envelope, "adapter_ref"))

    assert {:error, %{type: :serialization_failed}} =
             Envelope.dump(message_with_attachment(), adapter_ref: "")
  end

  @tag phase_150_task: "t150_06_02"
  test "rejects unsafe and over-bounded JSON before encoding" do
    too_deep = Enum.reduce(1..17, nil, fn _, value -> [value] end)
    too_wide = List.duplicate(nil, 10_001)

    for metadata <- [too_deep, too_wide, %{"a" => 2, a: 1}, %{bad: self()}] do
      message = %{message_with_attachment() | metadata: metadata}

      assert {:error, %{type: :serialization_failed, context: %{reason_class: _}}} =
               Envelope.dump(message, adapter_ref: "primary")
    end
  end

  @tag phase_150_task: "t150_06_02"
  test "accepts values at the documented JSON depth boundary" do
    at_depth = Enum.reduce(1..16, nil, fn _, value -> [value] end)

    assert {:ok, _} =
             Envelope.dump(%{message_with_attachment() | metadata: at_depth},
               adapter_ref: "primary"
             )
  end

  defp message_with_attachment(attachment \\ nil) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Mailglass", "sender@example.com"})
      |> Swoosh.Email.to({"Recipient", "recipient@example.com"})
      |> Swoosh.Email.subject("Private subject")
      |> then(fn email -> if attachment, do: %{email | attachments: [attachment]}, else: email end)

    Message.build(email,
      tenant_id: "tenant-150",
      mailable: __MODULE__,
      tags: [],
      metadata: %{}
    )
  end
end
