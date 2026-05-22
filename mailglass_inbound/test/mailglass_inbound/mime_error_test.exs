defmodule MailglassInbound.MIMEErrorTest do
  use ExUnit.Case, async: true

  alias MailglassInbound.MIMEError

  # Mirrors core's test/mailglass/error_test.exs __types__/0 + cause-exclusion
  # assertions. MIMEError is PACKAGE-LOCAL: it does not implement the core
  # Mailglass.Error behaviour and does not join the core @type union.

  test "__types__/0 returns the closed atom set" do
    assert MIMEError.__types__() == [:inbound_mime_invalid, :gen_smtp_unavailable]
  end

  test "the struct exposes the canonical error fields" do
    assert %MIMEError{}.__struct__ == MIMEError

    fields =
      %MIMEError{}
      |> Map.from_struct()
      |> Map.drop([:__exception__])
      |> Map.keys()
      |> Enum.sort()

    assert fields == [:cause, :context, :message, :type]
  end

  test "Exception.message/1 returns the :message field verbatim" do
    err = %MIMEError{type: :inbound_mime_invalid, message: "MIME parse failed", context: %{}}
    assert Exception.message(err) == "MIME parse failed"
  end

  test "Jason.Encoder excludes :cause to prevent raw payload fragments leaking" do
    err = %MIMEError{
      type: :inbound_mime_invalid,
      message: "MIME parse failed",
      cause: "secret-payload-fragment",
      context: %{byte_size: 42}
    }

    json = Jason.encode!(err)
    decoded = Jason.decode!(json)

    assert Map.has_key?(decoded, "type")
    assert Map.has_key?(decoded, "message")
    assert Map.has_key?(decoded, "context")
    refute Map.has_key?(decoded, "cause"), "cause must not appear in JSON output (V8 / payload PII)"
    refute json =~ "secret-payload-fragment", "raw cause payload must not leak into encoded output"
  end

  test "is package-local — does NOT implement the core Mailglass.Error behaviour" do
    # No type/1 or retryable?/1 callbacks: MIMEError lives in mailglass_inbound and
    # must not add itself to the core @type union.
    refute function_exported?(MIMEError, :type, 1)
    refute function_exported?(MIMEError, :retryable?, 1)
  end
end
