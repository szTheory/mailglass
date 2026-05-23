defmodule MailglassInbound.S3FetchErrorTest do
  use ExUnit.Case, async: true

  alias MailglassInbound.S3FetchError

  # Mirrors test/mailglass_inbound/mime_error_test.exs verbatim. S3FetchError is
  # PACKAGE-LOCAL: it does not implement the core Mailglass.Error behaviour and
  # does not join the core @type union.

  test "__types__/0 returns the closed atom set" do
    assert S3FetchError.__types__() == [:s3_object_not_ready, :s3_fetch_failed]
  end

  test "the struct exposes the canonical error fields" do
    assert %S3FetchError{}.__struct__ == S3FetchError

    fields =
      %S3FetchError{}
      |> Map.from_struct()
      |> Map.drop([:__exception__])
      |> Map.keys()
      |> Enum.sort()

    assert fields == [:cause, :context, :message, :type]
  end

  test "Exception.message/1 returns the :message field verbatim" do
    err = %S3FetchError{type: :s3_fetch_failed, message: "S3 fetch failed", context: %{}}
    assert Exception.message(err) == "S3 fetch failed"
  end

  test "Jason.Encoder excludes :cause to prevent raw S3/error fragments leaking" do
    err = %S3FetchError{
      type: :s3_fetch_failed,
      message: "S3 fetch failed",
      cause: "secret-bucket-internal-error",
      context: %{attempts: 3}
    }

    json = Jason.encode!(err)
    decoded = Jason.decode!(json)

    assert Map.has_key?(decoded, "type")
    assert Map.has_key?(decoded, "message")
    assert Map.has_key?(decoded, "context")
    refute Map.has_key?(decoded, "cause"), "cause must not appear in JSON output"
    refute json =~ "secret-bucket-internal-error", "raw cause payload must not leak into encoded output"
  end

  test "is package-local — does NOT implement the core Mailglass.Error behaviour" do
    refute function_exported?(S3FetchError, :type, 1)
    refute function_exported?(S3FetchError, :retryable?, 1)
  end

  test "__types__/0 matches the closed set documented in docs/api_stability.md" do
    # D-46-17: the locked :type atom set lives in mailglass_inbound/docs/api_stability.md.
    doc = File.read!(Path.join([__DIR__, "..", "..", "docs", "api_stability.md"]))

    for type <- S3FetchError.__types__() do
      assert doc =~ "`:#{type}`",
             "S3FetchError type :#{type} must be documented in docs/api_stability.md"
    end
  end
end
