defmodule Mailglass.ErrorTest do
  use ExUnit.Case, async: true

  # --- Raisable + pattern-matchable (CORE-01) ---

  test "all six error structs are raisable" do
    assert_raise Mailglass.SendError, fn ->
      raise Mailglass.SendError.new(:adapter_failure)
    end

    assert_raise Mailglass.TemplateError, fn ->
      raise Mailglass.TemplateError.new(:heex_compile)
    end

    assert_raise Mailglass.SignatureError, fn ->
      raise Mailglass.SignatureError.new(:missing)
    end

    assert_raise Mailglass.SuppressedError, fn ->
      raise Mailglass.SuppressedError.new(:address)
    end

    assert_raise Mailglass.RateLimitError, fn ->
      raise Mailglass.RateLimitError.new(:per_domain, context: %{retry_after_ms: 1000})
    end

    assert_raise Mailglass.ConfigError, fn ->
      raise Mailglass.ConfigError.new(:missing, context: %{key: :repo})
    end
  end

  test "pattern-match by struct discriminates correctly" do
    err = Mailglass.SendError.new(:adapter_failure)
    assert %Mailglass.SendError{} = err
    assert err.type == :adapter_failure
    # Discriminator check: struct module comparison, phrased so Elixir 1.19's
    # type checker doesn't narrow the term at compile time the way a literal
    # `refute match?(%Mailglass.TemplateError{}, err)` would.
    refute err.__struct__ == Mailglass.TemplateError
  end

  test "pattern-match by :type sub-kind works without inspecting :message" do
    err = Mailglass.RateLimitError.new(:per_domain, context: %{retry_after_ms: 5000})
    assert %Mailglass.RateLimitError{type: :per_domain, retry_after_ms: 0} = err
    # retry_after_ms defaults to 0 when only context is provided; explicit option sets the field.
    err2 = Mailglass.RateLimitError.new(:per_domain, retry_after_ms: 5000)
    assert %Mailglass.RateLimitError{retry_after_ms: 5000} = err2
  end

  # --- __types__/0 matches api_stability.md (CORE-01, D-07) ---

  test "__types__/0 returns the closed atom set for SendError" do
    assert Mailglass.SendError.__types__() ==
             [:adapter_failure, :rendering_failed, :preflight_rejected, :serialization_failed]
  end

  test "__types__/0 returns the closed atom set for TemplateError" do
    assert Mailglass.TemplateError.__types__() ==
             [:heex_compile, :missing_assign, :helper_undefined, :inliner_failed]
  end

  test "__types__/0 returns the closed atom set for SignatureError" do
    assert Mailglass.SignatureError.__types__() ==
             [:missing, :malformed, :mismatch, :timestamp_skew]
  end

  test "__types__/0 returns the closed atom set for SuppressedError" do
    assert Mailglass.SuppressedError.__types__() == [:address, :domain, :tenant_address]
  end

  test "__types__/0 returns the closed atom set for RateLimitError" do
    assert Mailglass.RateLimitError.__types__() == [:per_domain, :per_tenant, :per_stream]
  end

  test "__types__/0 returns the closed atom set for ConfigError" do
    assert Mailglass.ConfigError.__types__() ==
             [:missing, :invalid, :conflicting, :optional_dep_missing]
  end

  # --- Jason.Encoder excludes :cause (T-PII-002, D-06) ---

  test "Jason.Encoder on errors excludes :cause to prevent PII in serialized payloads" do
    inner = %RuntimeError{message: "inner error with recipient@example.com in it"}
    err = Mailglass.SendError.new(:adapter_failure, cause: inner, context: %{})

    json = Jason.encode!(err)
    decoded = Jason.decode!(json)

    assert Map.has_key?(decoded, "type")
    assert Map.has_key?(decoded, "message")
    assert Map.has_key?(decoded, "context")
    refute Map.has_key?(decoded, "cause"), "cause must not appear in JSON output (D-06 / T-PII-002)"
    refute Map.has_key?(decoded, "delivery_id"), "per-kind fields must not appear (not in :only)"
  end

  # --- Mailglass.Error behaviour helpers ---

  test "is_error?/1 returns true for all six error structs" do
    errors = [
      Mailglass.SendError.new(:adapter_failure),
      Mailglass.TemplateError.new(:heex_compile),
      Mailglass.SignatureError.new(:missing),
      Mailglass.SuppressedError.new(:address),
      Mailglass.RateLimitError.new(:per_domain),
      Mailglass.ConfigError.new(:missing)
    ]

    Enum.each(errors, fn err ->
      assert Mailglass.Error.is_error?(err), "Expected is_error? true for #{inspect(err.__struct__)}"
    end)
  end

  test "is_error?/1 returns false for non-error terms" do
    refute Mailglass.Error.is_error?(%{})
    refute Mailglass.Error.is_error?(nil)
    refute Mailglass.Error.is_error?("error string")
    refute Mailglass.Error.is_error?(%RuntimeError{message: "not a mailglass error"})
  end

  test "retryable?/1 returns false for SignatureError and ConfigError (D-09)" do
    refute Mailglass.Error.retryable?(Mailglass.SignatureError.new(:mismatch))
    refute Mailglass.Error.retryable?(Mailglass.ConfigError.new(:missing))
  end

  test "retryable?/1 returns true for RateLimitError (D-09)" do
    assert Mailglass.Error.retryable?(Mailglass.RateLimitError.new(:per_domain))
  end

  test "retryable?/1 returns false for SuppressedError (D-09)" do
    refute Mailglass.Error.retryable?(Mailglass.SuppressedError.new(:address))
  end

  test "root_cause/1 walks :cause chain to the deepest error" do
    inner = Mailglass.ConfigError.new(:missing)
    outer = Mailglass.SendError.new(:adapter_failure, cause: inner)
    assert Mailglass.Error.root_cause(outer) == inner
  end

  test "root_cause/1 returns the error itself when :cause is nil" do
    err = Mailglass.SendError.new(:adapter_failure)
    assert Mailglass.Error.root_cause(err) == err
  end

  # --- Error message brand voice (CLAUDE.md, CONTEXT.md D-08) ---

  test "error messages use brand-voice strings and never 'Oops'" do
    err = Mailglass.SuppressedError.new(:address)
    assert err.message == "Delivery blocked: recipient is on the suppression list"
    refute String.contains?(err.message, "Oops")
    refute String.contains?(err.message, "went wrong")
  end
end
