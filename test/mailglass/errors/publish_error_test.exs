defmodule Mailglass.PublishErrorTest do
  use ExUnit.Case, async: true

  alias Mailglass.PublishError

  describe "__types__/0" do
    test "returns the closed atom set" do
      assert PublishError.__types__() == [:publish_blocked_golden_drift]
    end
  end

  describe "retryable?/1" do
    test "returns false" do
      err = PublishError.new(:publish_blocked_golden_drift)
      refute Mailglass.Error.retryable?(err)
    end
  end

  describe "new/2 with :publish_blocked_golden_drift" do
    test "includes the exact remediation command in the message" do
      err = PublishError.new(:publish_blocked_golden_drift)

      assert err.message =~ "Publish blocked: installer goldens drifted"

      assert err.message =~
               "MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors"
    end

    test "appends subprocess output when present in context" do
      err =
        PublishError.new(:publish_blocked_golden_drift,
          context: %{output: "1 test, 1 failure\n\nmismatch snapshot"}
        )

      assert err.message =~ "Subprocess output:\n1 test, 1 failure\n\nmismatch snapshot"
    end
  end
end
