defmodule Mailglass.TestSupport.CitextProbeTest do
  use ExUnit.Case, async: true

  alias Mailglass.TestSupport.CitextProbe

  test "returns :ok when the probe succeeds" do
    assert :ok =
             CitextProbe.run(
               repo: Mailglass.TestRepo,
               max_attempts: 2,
               probe_fun: fn _repo -> :ok end
             )
  end

  test "raises when the probe exhausts its retries" do
    assert_raise RuntimeError,
                 "citext probe exhausted for Mailglass.TestRepo after 3 attempts",
                 fn ->
                   CitextProbe.run(
                     repo: Mailglass.TestRepo,
                     max_attempts: 3,
                     probe_fun: fn _repo ->
                       raise Postgrex.Error, message: "cache lookup failed"
                     end
                   )
                 end
  end
end
