defmodule Mailglass.MigrationConcurrencySourceTest do
  use Mailglass.DataCase, async: false

  @v06_path Path.expand("../../lib/mailglass/migrations/postgres/v06.ex", __DIR__)
  @inbound_v02_path Path.expand(
                      "../../mailglass_inbound/lib/mailglass_inbound/migrations/postgres/v02.ex",
                      __DIR__
                    )

  test "nontransactional migration timeouts are connection-affine and restore prior values after failure" do
    repo = Mailglass.TestRepo

    repo.checkout(fn ->
      original_lock_timeout = current_setting(repo, "lock_timeout")
      original_statement_timeout = current_setting(repo, "statement_timeout")

      try do
        set_setting(repo, "lock_timeout", "7s")
        set_setting(repo, "statement_timeout", "9s")

        assert_raise Postgrex.Error, fn ->
          Mailglass.Migrations.Postgres.SessionTimeouts.run(repo, fn ->
            assert current_setting(repo, "lock_timeout") == "500ms"
            assert current_setting(repo, "statement_timeout") == "30s"
            repo.query!("SELECT 1 / 0")
          end)
        end

        assert current_setting(repo, "lock_timeout") == "7s"
        assert current_setting(repo, "statement_timeout") == "9s"
      after
        set_setting(repo, "lock_timeout", original_lock_timeout)
        set_setting(repo, "statement_timeout", original_statement_timeout)
      end
    end)
  end

  test "both concurrent migration versions execute their DDL inside the runtime timeout scope" do
    for path <- [@v06_path, @inbound_v02_path] do
      source = File.read!(path)

      assert source =~ "execute(fn ->"
      assert source =~ "SessionTimeouts.run(repo(), fn ->"
      refute source =~ "execute(\"SET lock_timeout"
      refute source =~ "execute(\"RESET lock_timeout"
    end
  end

  defp current_setting(repo, name) do
    %{rows: [[value]]} = repo.query!("SELECT current_setting($1)", [name])
    value
  end

  defp set_setting(repo, name, value) do
    repo.query!("SELECT set_config($1, $2, false)", [name, value])
  end
end
