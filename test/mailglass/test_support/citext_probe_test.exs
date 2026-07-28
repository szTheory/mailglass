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

  test "raises when the poisoned-OID probe exhausts its retries" do
    assert_raise RuntimeError,
                 ~r/^citext probe exhausted for Mailglass\.TestRepo after 3 attempts/,
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

  test "exhaustion message carries the last observed error" do
    error =
      assert_raise RuntimeError, fn ->
        CitextProbe.run(
          repo: Mailglass.TestRepo,
          max_attempts: 2,
          probe_fun: fn _repo ->
            raise Postgrex.Error, message: "cache lookup failed for type 424242"
          end
        )
      end

    message = Exception.message(error)

    assert message =~ "last error:"
    assert message =~ "cache lookup failed for type 424242"
  end

  test "retries the poisoned-OID surface until it clears" do
    {:ok, counter} = Agent.start_link(fn -> 0 end)

    probe_fun = fn _repo ->
      attempt = Agent.get_and_update(counter, &{&1 + 1, &1 + 1})

      if attempt < 3 do
        raise Postgrex.Error, message: "cache lookup failed for type 424242"
      else
        :ok
      end
    end

    assert :ok =
             CitextProbe.run(
               repo: Mailglass.TestRepo,
               max_attempts: 5,
               probe_fun: probe_fun
             )

    assert Agent.get(counter, & &1) == 3
  end

  # Regression: a permanent fault used to be swallowed by the retry loop and
  # reported as "citext probe exhausted", pointing diagnosis at the citext type
  # when the real cause was something else entirely (e.g. an unmigrated
  # database). Permanent faults must surface immediately, unchanged.
  test "re-raises a non-poisoned-OID Postgrex.Error immediately without retrying" do
    {:ok, counter} = Agent.start_link(fn -> 0 end)

    probe_fun = fn _repo ->
      Agent.update(counter, &(&1 + 1))
      raise Postgrex.Error, message: ~s(relation "mailglass_suppressions" does not exist)
    end

    error =
      assert_raise Postgrex.Error, fn ->
        CitextProbe.run(
          repo: Mailglass.TestRepo,
          max_attempts: 5,
          probe_fun: probe_fun
        )
      end

    assert Exception.message(error) =~ "does not exist"
    refute Exception.message(error) =~ "citext probe exhausted"
    assert Agent.get(counter, & &1) == 1, "permanent fault must not be retried"
  end

  test "treats a postgres :internal_error code as the poisoned-OID surface" do
    assert_raise RuntimeError, ~r/citext probe exhausted/, fn ->
      CitextProbe.run(
        repo: Mailglass.TestRepo,
        max_attempts: 2,
        probe_fun: fn _repo ->
          raise Postgrex.Error,
            postgres: %{
              code: :internal_error,
              message: "cache lookup failed for type 424242",
              pg_code: "XX000",
              severity: "ERROR"
            }
        end
      )
    end
  end
end
