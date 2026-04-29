defmodule Mailglass.Webhook.Providers.MailgunReplayCache.Supervisor do
  @moduledoc "Supervises `Mailglass.Webhook.Providers.MailgunReplayCache.TableOwner`."
  use Supervisor

  def start_link(opts) do
    {name, init_opts} = Keyword.pop(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, init_opts, name: name)
  end

  @impl Supervisor
  def init(_opts) do
    children = [
      {Mailglass.Webhook.Providers.MailgunReplayCache.TableOwner,
       [name: Mailglass.Webhook.Providers.MailgunReplayCache.TableOwner]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
