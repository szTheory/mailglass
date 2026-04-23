defmodule Mailglass.RateLimiter.Supervisor do
  @moduledoc "Supervises `Mailglass.RateLimiter.TableOwner` (D-22)."
  use Supervisor

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl Supervisor
  def init(_opts) do
    Supervisor.init([Mailglass.RateLimiter.TableOwner], strategy: :one_for_one)
  end
end
