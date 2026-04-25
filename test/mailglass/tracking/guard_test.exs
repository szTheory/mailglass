defmodule Mailglass.Tracking.GuardTest do
  use ExUnit.Case, async: true

  alias Mailglass.Tracking.Guard
  alias Mailglass.Message
  alias Mailglass.FakeFixtures.TestMailer
  alias Mailglass.FakeFixtures.TrackingMailer

  # Test 4: assert_safe! returns :ok when tracking is off
  test "Test 4: assert_safe! returns :ok when tracking is off (TestMailer.welcome)" do
    msg = %Message{mailable: TestMailer, mailable_function: :welcome, stream: :transactional}
    assert Guard.assert_safe!(msg) == :ok
  end

  # Test 5: assert_safe! returns :ok when tracking on but function doesn't match auth regex
  test "Test 5: assert_safe! returns :ok when tracking on but function name is not auth-stream" do
    msg = %Message{mailable: TrackingMailer, mailable_function: :campaign, stream: :operational}
    assert Guard.assert_safe!(msg) == :ok
  end

  # Test 6: assert_safe! raises on magic_link + tracking enabled
  test "Test 6: assert_safe! raises ConfigError for :magic_link + tracking enabled" do
    msg = %Message{mailable: TrackingMailer, mailable_function: :magic_link, stream: :operational}

    # First verify assert_raise works
    assert_raise Mailglass.ConfigError, fn ->
      Guard.assert_safe!(msg)
    end

    # Then inspect the struct fields (use is_struct/2 not .field notation on :undef)
    err = catch_error(Guard.assert_safe!(msg))
    assert is_struct(err, Mailglass.ConfigError)
    assert err.type == :tracking_on_auth_stream
    assert err.context.mailable == TrackingMailer
    assert err.context.function == :magic_link
  end

  # Test 7: raises for all four canonical auth function names
  test "Test 7: assert_safe! raises for :password_reset, :verify_email, :confirm_account" do
    for fun_name <- [:password_reset, :verify_email, :confirm_account] do
      msg = %Message{mailable: TrackingMailer, mailable_function: fun_name, stream: :operational}
      err = catch_error(Guard.assert_safe!(msg))

      assert is_struct(err, Mailglass.ConfigError),
             "Expected ConfigError for #{fun_name}"

      assert err.type == :tracking_on_auth_stream,
             "Expected :tracking_on_auth_stream for #{fun_name}"
    end
  end

  # Test 8: prefix match — magic_link_verify_otp also raises
  test "Test 8: assert_safe! raises for prefix-matched :magic_link_verify_otp" do
    msg = %Message{
      mailable: TrackingMailer,
      mailable_function: :magic_link_verify_otp,
      stream: :operational
    }

    err = catch_error(Guard.assert_safe!(msg))
    assert is_struct(err, Mailglass.ConfigError)
    assert err.type == :tracking_on_auth_stream
  end

  # Test 9: :password_changed_notification does NOT match (different prefix)
  test "Test 9: assert_safe! returns :ok for :password_changed_notification (non-auth prefix)" do
    msg = %Message{
      mailable: TrackingMailer,
      mailable_function: :password_changed_notification,
      stream: :operational
    }

    assert Guard.assert_safe!(msg) == :ok
  end

  # Test 10: nil mailable_function returns :ok (can't guard without function name)
  test "Test 10: assert_safe! returns :ok when mailable_function is nil" do
    msg = %Message{mailable: TrackingMailer, mailable_function: nil, stream: :operational}
    assert Guard.assert_safe!(msg) == :ok
  end
end
