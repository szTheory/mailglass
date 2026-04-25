defmodule Mailglass.RateLimiter.Supervisor do
  @moduledoc "Supervises `Mailglass.RateLimiter.TableOwner` (D-22)."
  use Supervisor

  def start_link(opts) do
    {name, init_opts} = Keyword.pop(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, init_opts, name: name)
  end

  @impl Supervisor
  def init(_opts) do
    children = [
      {Mailglass.RateLimiter.TableOwner, [name: Mailglass.RateLimiter.TableOwner]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
