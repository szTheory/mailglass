defmodule MailglassDemo.ConnCase do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      @endpoint MailglassDemoWeb.Endpoint

      import Phoenix.ConnTest
      import Plug.Conn
      import MailglassDemo.ConnCase
    end
  end

  setup tags do
    pid = Sandbox.start_owner!(MailglassDemo.Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
