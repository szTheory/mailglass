defmodule MailglassReferenceHost.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MailglassReferenceHost.Repo
    ]

    opts = [strategy: :one_for_one, name: MailglassReferenceHost.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
