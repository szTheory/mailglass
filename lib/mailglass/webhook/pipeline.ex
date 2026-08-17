defmodule Mailglass.Webhook.Pipeline do
  @moduledoc false

  @type outcome :: {Plug.Conn.t(), map()}

  @doc false
  @spec run(Plug.Conn.t(), atom(), keyword(), (Plug.Conn.t(), atom(), keyword() -> outcome())) ::
          outcome()
  def run(conn, provider, opts, runner)
      when is_atom(provider) and is_list(opts) and is_function(runner, 3) do
    runner.(conn, provider, opts)
  end
end
