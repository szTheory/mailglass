defmodule MailglassDemo.DataCase do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias MailglassDemo.Repo
      import Ecto.Query
      import MailglassDemo.DataCase
    end
  end

  setup tags do
    pid = Sandbox.start_owner!(MailglassDemo.Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
    :ok
  end
end
