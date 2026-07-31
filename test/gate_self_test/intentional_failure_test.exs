defmodule Mailglass.GateSelfTest.IntentionalFailureTest do
  @moduledoc """
  Intentional failure injected by .github/workflows/gate-self-test.yml.
  If you see this file outside that workflow, delete it — the test
  is meant to live for the duration of one self-test run only.
  """
  use ExUnit.Case, async: true

  test "this test always fails — verifies the Tests gate blocks PRs" do
    assert false, "intentional failure for gate-self-test"
  end
end
