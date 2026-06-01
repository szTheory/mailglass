defmodule MailglassDemo.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MailglassDemo.Repo,
      MailglassDemoWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: MailglassDemo.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    MailglassDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
