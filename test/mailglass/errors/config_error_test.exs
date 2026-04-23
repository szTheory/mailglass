defmodule Mailglass.ConfigErrorTest do
  use ExUnit.Case, async: true

  alias Mailglass.ConfigError

  describe "__types__/0 includes Phase 3 atoms" do
    test "includes :tracking_on_auth_stream, :tracking_host_missing, and :tracking_endpoint_missing in addition to the 4 existing atoms" do
      types = ConfigError.__types__()
      assert :missing in types
      assert :invalid in types
      assert :conflicting in types
      assert :optional_dep_missing in types
      assert :tracking_on_auth_stream in types
      assert :tracking_host_missing in types
      assert :tracking_endpoint_missing in types
    end

    test "__types__/0 returns exactly 7 atoms" do
      assert length(ConfigError.__types__()) == 7
    end
  end

  describe "new/2 with :tracking_on_auth_stream" do
    test "produces a clear, specific error message (brand voice)" do
      err =
        ConfigError.new(:tracking_on_auth_stream,
          context: %{mailable: MyMailer, function: :magic_link}
        )

      assert %ConfigError{type: :tracking_on_auth_stream} = err
      assert err.message =~ "Tracking misconfigured"
      assert err.message =~ "auth-stream"
      assert err.message =~ "magic_link"
      refute err.message =~ "Oops"
    end

    test "includes mailable module name in message" do
      err =
        ConfigError.new(:tracking_on_auth_stream,
          context: %{mailable: MyApp.UserMailer, function: :password_reset}
        )

      assert err.message =~ "MyApp.UserMailer"
      assert err.message =~ "password_reset"
    end
  end

  describe "new/2 with :tracking_host_missing" do
    test "produces a clear message instructing how to fix config" do
      err = ConfigError.new(:tracking_host_missing, context: %{})

      assert %ConfigError{type: :tracking_host_missing} = err
      assert err.message =~ "Tracking misconfigured"
      assert err.message =~ "tracking host is required"
      assert err.message =~ ":tracking"
      refute err.message =~ "Oops"
    end
  end
end
