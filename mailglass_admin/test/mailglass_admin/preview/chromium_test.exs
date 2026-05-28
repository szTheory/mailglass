defmodule MailglassAdmin.Preview.ChromiumTest do
  # async: false — these tests mutate process env (MAILGLASS_ADMIN_CHROMIUM_BIN, PATH).
  use ExUnit.Case, async: false

  alias MailglassAdmin.Preview.Chromium

  @env "MAILGLASS_ADMIN_CHROMIUM_BIN"

  setup do
    saved_bin = System.get_env(@env)
    saved_path = System.get_env("PATH")

    on_exit(fn ->
      restore(@env, saved_bin)
      restore("PATH", saved_path)
    end)

    :ok
  end

  defp restore(key, nil), do: System.delete_env(key)
  defp restore(key, value), do: System.put_env(key, value)

  test "capture/4 enforces the timeout and kills a hung binary" do
    # A fake "chromium" that ignores its args and sleeps well past the timeout.
    script = Path.join(System.tmp_dir!(), "fake_chromium_#{System.unique_integer([:positive])}.sh")
    File.write!(script, "#!/usr/bin/env bash\nsleep 30\n")
    File.chmod!(script, 0o755)
    on_exit(fn -> File.rm(script) end)

    System.put_env(@env, script)

    {elapsed_us, result} =
      :timer.tc(fn ->
        Chromium.capture("http://localhost/x", Path.join(System.tmp_dir!(), "x.png"), 375,
          timeout: 100
        )
      end)

    assert {:error, {:command_failed, 124, message}} = result
    assert message =~ "timed out"
    # Returns promptly (killed at ~100ms), nowhere near the 30s sleep.
    assert elapsed_us < 5_000_000
  end

  test "capture/4 returns binary_not_found when no Chromium is resolvable" do
    System.delete_env(@env)
    System.put_env("PATH", "")

    assert {:error, {:binary_not_found, candidates}} =
             Chromium.capture("http://localhost/x", Path.join(System.tmp_dir!(), "x.png"), 375)

    assert is_list(candidates) and candidates != []
  end
end
