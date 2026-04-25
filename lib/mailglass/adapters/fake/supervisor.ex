defmodule Mailglass.Adapters.Fake.Supervisor do
  @moduledoc """
  Supervises `Mailglass.Adapters.Fake.Storage`. Started unconditionally in
  `Mailglass.Application` (D-02) via the `Code.ensure_loaded?/1`-gated
  `maybe_add/3` call placed in Plan 01 (I-08).

  Idle cost ≈ 2KB + one process; adopters routing production traffic through
  `Mailglass.Adapters.Swoosh` pay nothing the Fake isn't doing anyway.

  ## Why unconditional?

  The Fake adapter is the merge-blocking release gate (D-13). Every CI run
  exercises the full pipeline through Fake, which requires the Storage
  GenServer to be running. Starting it unconditionally means the adapter is
  always available, regardless of the configured production adapter. This
  matches how `Swoosh.Adapters.Sandbox.Storage` works.

  ## api_stability.md note

  `Mailglass.Adapters.Fake.Storage` is a library-reserved GenServer name.
  Adopters must not register a process under this name. (LINT-07 exception:
  library-internal singleton per D-02.)
  """
  use Supervisor

  def start_link(opts) do
    {name, init_opts} = Keyword.pop(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, init_opts, name: name)
  end

  @impl Supervisor
  def init(_opts) do
    children = [
      {Mailglass.Adapters.Fake.Storage, [name: Mailglass.Adapters.Fake.Storage]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
