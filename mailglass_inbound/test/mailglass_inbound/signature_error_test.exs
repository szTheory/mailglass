defmodule MailglassInbound.SignatureErrorTest do
  use ExUnit.Case, async: true

  alias MailglassInbound.SignatureError

  # Mirrors test/mailglass_inbound/mime_error_test.exs (__types__/0 closed set,
  # field set, :cause JSON exclusion, package-local assertion) plus the
  # no-recovery semantics + new/2 builder lifted from core
  # Mailglass.SignatureError. SignatureError is PACKAGE-LOCAL: it does NOT
  # implement the core Mailglass.Error behaviour and does NOT join the core
  # @type union.

  test "__types__/0 returns the closed atom set" do
    assert SignatureError.__types__() == [
             :bad_signature,
             :missing_header,
             :malformed_header,
             :timestamp_skew,
             :subscribe_url_untrusted
           ]
  end

  test "the struct exposes the canonical error fields (incl. :provider)" do
    assert %SignatureError{}.__struct__ == SignatureError

    fields =
      %SignatureError{}
      |> Map.from_struct()
      |> Map.drop([:__exception__])
      |> Map.keys()
      |> Enum.sort()

    assert fields == [:cause, :context, :message, :provider, :type]
  end

  test "Exception.message/1 returns the :message field verbatim" do
    err = %SignatureError{type: :bad_signature, message: "Inbound signature failed", context: %{}}
    assert Exception.message(err) == "Inbound signature failed"
  end

  test "Jason.Encoder excludes :cause and :provider to prevent secret leakage" do
    err = %SignatureError{
      type: :bad_signature,
      message: "Inbound signature failed",
      cause: "secret-signing-key-fragment",
      provider: :mailgun,
      context: %{detail: "hmac mismatch"}
    }

    json = Jason.encode!(err)
    decoded = Jason.decode!(json)

    assert Map.has_key?(decoded, "type")
    assert Map.has_key?(decoded, "message")
    assert Map.has_key?(decoded, "context")
    refute Map.has_key?(decoded, "cause"), "cause must not appear in JSON output (PII / secret)"
    refute Map.has_key?(decoded, "provider"), "provider must not appear in JSON output"

    refute json =~ "secret-signing-key-fragment",
           "raw cause payload must not leak into encoded output"
  end

  test "new/2 validates the type against the closed set" do
    assert_raise ArgumentError, fn -> SignatureError.new(:not_a_type, []) end
  end

  test "new/2 builds a no-recovery struct with provider, formatted message, and context" do
    err = SignatureError.new(:bad_signature, provider: :mailgun, context: %{detail: "x"})

    assert %SignatureError{} = err
    assert err.type == :bad_signature
    assert err.provider == :mailgun
    assert err.context == %{detail: "x"}
    assert is_binary(err.message)
    assert err.message != ""
  end

  test "is package-local — does NOT implement the core Mailglass.Error behaviour" do
    # No type/1 or retryable?/1 callbacks: SignatureError lives in
    # mailglass_inbound and must not add itself to the core @type union.
    refute function_exported?(SignatureError, :type, 1)
    refute function_exported?(SignatureError, :retryable?, 1)
  end

  test "is no-recovery — carries no retryable affordance returning true" do
    # CLAUDE.md #5 / D-22: webhook signature failures never recover.
    refute function_exported?(SignatureError, :retryable?, 1)
    refute function_exported?(SignatureError, :retryable?, 0)
  end

  test "__types__/0 matches the closed set documented in docs/api_stability.md" do
    # D-46-19: the locked :type atom set lives in mailglass_inbound/docs/api_stability.md.
    doc = File.read!(Path.join([__DIR__, "..", "..", "docs", "api_stability.md"]))

    for type <- SignatureError.__types__() do
      assert doc =~ "`:#{type}`",
             "SignatureError type :#{type} must be documented in docs/api_stability.md"
    end
  end
end
