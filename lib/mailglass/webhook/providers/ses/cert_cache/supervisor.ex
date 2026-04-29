defmodule Mailglass.Webhook.Providers.SES.CertCache.Supervisor do
  @moduledoc "Supervises `Mailglass.Webhook.Providers.SES.CertCache.TableOwner`."
  use Supervisor

  def start_link(opts) do
    {name, init_opts} = Keyword.pop(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, init_opts, name: name)
  end

  @impl Supervisor
  def init(_opts) do
    children = [
      {Mailglass.Webhook.Providers.SES.CertCache.TableOwner,
       [name: Mailglass.Webhook.Providers.SES.CertCache.TableOwner]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
