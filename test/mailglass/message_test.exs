defmodule Mailglass.MessageTest do
  use ExUnit.Case, async: true

  alias Mailglass.Message

  describe "mailable_function field" do
    test "Message struct has :mailable_function field defaulting to nil" do
      email = Swoosh.Email.new(subject: "Test")
      msg = Message.new(email)
      assert msg.mailable_function == nil
    end

    test "Message.new/2 populates :mailable_function from opts" do
      email = Swoosh.Email.new(subject: "Welcome")

      msg = Message.new(email, mailable: MyApp.UserMailer, mailable_function: :welcome)

      assert msg.mailable == MyApp.UserMailer
      assert msg.mailable_function == :welcome
    end

    test "Message.new/2 with :password_reset function populates the field" do
      email = Swoosh.Email.new(subject: "Reset")
      msg = Message.new(email, mailable: MyApp.UserMailer, mailable_function: :password_reset)
      assert msg.mailable_function == :password_reset
    end
  end

  describe "put_metadata/3" do
    test "returns a new %Message{} with metadata[key] = value" do
      email = Swoosh.Email.new(subject: "Test")
      msg = Message.new(email)

      updated = Message.put_metadata(msg, :delivery_id, "01HXYZ")

      assert updated.metadata == %{delivery_id: "01HXYZ"}
      # Original message is unchanged
      assert msg.metadata == %{}
    end

    test "other fields are untouched" do
      email = Swoosh.Email.new(subject: "Welcome")
      msg = Message.new(email, mailable: MyApp.UserMailer, stream: :transactional)

      updated = Message.put_metadata(msg, :delivery_id, "abc123")

      assert updated.mailable == MyApp.UserMailer
      assert updated.stream == :transactional
      assert updated.swoosh_email == email
    end

    test "on a message with existing metadata, merges without overwriting other keys" do
      email = Swoosh.Email.new(subject: "Test")
      msg = Message.new(email, metadata: %{existing_key: "existing_val"})

      updated = Message.put_metadata(msg, :delivery_id, "01HXYZ")

      assert updated.metadata == %{existing_key: "existing_val", delivery_id: "01HXYZ"}
    end

    test "initialises metadata to %{key => value} when metadata is nil/empty (no crash)" do
      email = Swoosh.Email.new(subject: "Test")
      msg = Message.new(email)
      # Default metadata is %{}, put_metadata should work
      updated = Message.put_metadata(msg, :step, "init")
      assert updated.metadata == %{step: "init"}
    end
  end
end
