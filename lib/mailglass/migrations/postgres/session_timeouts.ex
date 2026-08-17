defmodule Mailglass.Migrations.Postgres.SessionTimeouts do
  @moduledoc false

  @lock_timeout "500ms"
  @statement_timeout "30s"

  @doc false
  @spec run(module(), (-> result)) :: result when result: var
  def run(repo, fun) when is_atom(repo) and is_function(fun, 0) do
    repo.checkout(fn ->
      prior_lock_timeout = current_setting(repo, "lock_timeout")
      prior_statement_timeout = current_setting(repo, "statement_timeout")

      try do
        set_setting(repo, "lock_timeout", @lock_timeout)
        set_setting(repo, "statement_timeout", @statement_timeout)
        fun.()
      after
        # Preserve the adopter's exact prior session values. Nesting the
        # restores ensures statement_timeout is attempted even if restoring
        # lock_timeout itself raises while the connection is failing.
        try do
          set_setting(repo, "lock_timeout", prior_lock_timeout)
        after
          set_setting(repo, "statement_timeout", prior_statement_timeout)
        end
      end
    end)
  end

  defp current_setting(repo, name) do
    %{rows: [[value]]} = repo.query!("SELECT current_setting($1)", [name])
    value
  end

  defp set_setting(repo, name, value) do
    repo.query!("SELECT set_config($1, $2, false)", [name, value])
  end
end
