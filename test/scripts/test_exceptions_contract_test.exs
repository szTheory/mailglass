defmodule Mailglass.Scripts.TestExceptionsContractTest do
  use ExUnit.Case, async: true

  @script Path.expand("../../scripts/check_test_exceptions.sh", __DIR__)
  test "registry is bidirectional and unexpired" do
    assert {"OK: test exception registry is complete and unexpired.\n", 0} =
             System.cmd("bash", [@script], stderr_to_stdout: true)
  end

  test "missing or expired registry metadata fails closed" do
    broken =
      Path.join(System.tmp_dir!(), "test-exceptions-#{System.unique_integer([:positive])}.exs")

    on_exit(fn -> File.rm(broken) end)

    File.write!(
      broken,
      "%{exceptions: [%{source: \"test/mailglass/application_test.exs:60\", kind: :skip, owner: \"core\", reason: \"fixture\", expires_on: ~D[2000-01-01], category: :fixture}]}\n"
    )

    assert {_output, 1} =
             System.cmd("bash", [@script],
               env: [{"TEST_EXCEPTIONS_REGISTRY", broken}],
               stderr_to_stdout: true
             )
  end
end
