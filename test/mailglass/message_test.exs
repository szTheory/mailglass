defmodule Mailglass.MessageTest do
  use ExUnit.Case, async: true

  alias Mailglass.Message

  describe "mailable_function field" do
    test "Message struct has :mailable_function field defaulting to nil" do
      email = Swoosh.Email.new(subject: "Test")
      msg = Message.build(email)
      assert msg.mailable_function == nil
    end

    test "Message.new/2 populates :mailable_function from opts" do
      email = Swoosh.Email.new(subject: "Welcome")

      msg = Message.build(email, mailable: MyApp.UserMailer, mailable_function: :welcome)

      assert msg.mailable == MyApp.UserMailer
      assert msg.mailable_function == :welcome
    end

    test "Message.new/2 with :password_reset function populates the field" do
      email = Swoosh.Email.new(subject: "Reset")
      msg = Message.build(email, mailable: MyApp.UserMailer, mailable_function: :password_reset)
      assert msg.mailable_function == :password_reset
    end
  end

  describe "native setters" do
    test "to/2 sets recipient" do
      msg = Message.build(Swoosh.Email.new())
      updated = Message.to(msg, "user@example.com")
      assert updated.swoosh_email.to == [{"", "user@example.com"}]
    end

    test "from/2 sets sender" do
      msg = Message.build(Swoosh.Email.new())
      updated = Message.from(msg, "sender@example.com")
      assert updated.swoosh_email.from == {"", "sender@example.com"}
    end

    test "subject/2 sets subject" do
      msg = Message.build(Swoosh.Email.new())
      updated = Message.subject(msg, "Hello")
      assert updated.swoosh_email.subject == "Hello"
    end

    test "text_body/2 sets text body" do
      msg = Message.build(Swoosh.Email.new())
      updated = Message.text_body(msg, "Text content")
      assert updated.swoosh_email.text_body == "Text content"
    end

    test "html_body/2 sets html body" do
      msg = Message.build(Swoosh.Email.new())
      updated = Message.html_body(msg, "<p>HTML</p>")
      assert updated.swoosh_email.html_body == "<p>HTML</p>"
    end

    test "header/3 sets custom header" do
      msg = Message.build(Swoosh.Email.new())
      updated = Message.header(msg, "X-Custom", "value")
      assert updated.swoosh_email.headers["X-Custom"] == "value"
    end

    test "attach/2 adds attachment" do
      msg = Message.build(Swoosh.Email.new())
      attachment = Swoosh.Attachment.new({:data, "content"}, filename: "test.txt")
      updated = Message.attach(msg, attachment)
      assert updated.swoosh_email.attachments == [attachment]
    end

    test "put_tag/2 adds to message tags list" do
      msg = Message.build(Swoosh.Email.new())
      updated = Message.put_tag(msg, "welcome-series")
      assert updated.tags == ["welcome-series"]

      updated2 = Message.put_tag(updated, "onboarding")
      assert updated2.tags == ["welcome-series", "onboarding"]
    end

    test "put_stream/2 sets stream" do
      msg = Message.build(Swoosh.Email.new())
      updated = Message.put_stream(msg, :bulk)
      assert updated.stream == :bulk
    end

    test "put_stream/2 raises FunctionClauseError for invalid stream" do
      msg = Message.build(Swoosh.Email.new())

      assert_raise FunctionClauseError, fn ->
        Message.put_stream(msg, :invalid)
      end
    end
  end

  describe "new_from_use/2" do
    test "defaults to :transactional stream" do
      msg = Message.new_from_use(MyApp.UserMailer, [])
      assert msg.stream == :transactional
    end

    test "accepts valid stream opt" do
      msg = Message.new_from_use(MyApp.UserMailer, stream: :bulk)
      assert msg.stream == :bulk
    end

    test "raises FunctionClauseError or ArgumentError for invalid stream opt" do
      assert_raise ArgumentError, ~r/invalid stream/, fn ->
        Message.new_from_use(MyApp.UserMailer, stream: :invalid)
      end
    end
  end

  describe "put_metadata/3" do
    test "returns a new %Message{} with metadata[key] = value" do
      email = Swoosh.Email.new(subject: "Test")
      msg = Message.build(email)

      updated = Message.put_metadata(msg, :delivery_id, "01HXYZ")

      assert updated.metadata == %{delivery_id: "01HXYZ"}
      # Original message is unchanged
      assert msg.metadata == %{}
    end

    test "other fields are untouched" do
      email = Swoosh.Email.new(subject: "Welcome")
      msg = Message.build(email, mailable: MyApp.UserMailer, stream: :transactional)

      updated = Message.put_metadata(msg, :delivery_id, "abc123")

      assert updated.mailable == MyApp.UserMailer
      assert updated.stream == :transactional
      assert updated.swoosh_email == email
    end

    test "on a message with existing metadata, merges without overwriting other keys" do
      email = Swoosh.Email.new(subject: "Test")
      msg = Message.build(email, metadata: %{existing_key: "existing_val"})

      updated = Message.put_metadata(msg, :delivery_id, "01HXYZ")

      assert updated.metadata == %{existing_key: "existing_val", delivery_id: "01HXYZ"}
    end

    test "initialises metadata to %{key => value} when metadata is nil/empty (no crash)" do
      email = Swoosh.Email.new(subject: "Test")
      msg = Message.build(email)
      # Default metadata is %{}, put_metadata should work
      updated = Message.put_metadata(msg, :step, "init")
      assert updated.metadata == %{step: "init"}
    end
  end
end
