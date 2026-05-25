if Code.ensure_loaded?(Oban.Worker) do
  defmodule MailglassInbound.Prune.Worker do
    @moduledoc """
    Optional Oban cron worker that runs the inbound retention sweep (IOPS-03,
    D-49-28). The batched workhorse lives in `MailglassInbound.Internal.Prune`;
    this worker's `perform/1` just delegates to `prune/0`.

    ## Optional-dep gating

    The entire module is conditionally compiled behind
    `if Code.ensure_loaded?(Oban.Worker)`. When Oban is absent a stub is defined
    exposing `available?/0 -> false`; `MailglassInbound.Application` emits a
    consolidated boot warning directing operators to run
    `mix mailglass.inbound.prune` from their own cron infrastructure.

    ## Never auto-registered

    This worker is NOT auto-registered in `MailglassInbound.Application` (D-49-28).
    Operators wire the cron in their own Oban config — the recommended cadence is
    `0 3 * * *` (3 AM UTC; documented in the Phase 50 operator guide). The
    `mix mailglass.inbound.prune` task runs the sweep synchronously whether or not
    Oban is present, so Oban-less adopters still get a working prune.
    """

    use Oban.Worker, queue: :mailglass_inbound_maintenance

    @doc """
    Returns `true` when the worker is compiled (Oban available). Used by the
    Application boot warning and ops tooling.
    """
    @doc since: "1.2.0"
    @spec available?() :: true
    def available?, do: true

    @impl Oban.Worker
    def perform(_job) do
      case MailglassInbound.Internal.Prune.prune() do
        {:ok, _result} -> :ok
        other -> other
      end
    end
  end
else
  defmodule MailglassInbound.Prune.Worker do
    @moduledoc """
    Stub module — Oban is not loaded, so the prune worker is not compiled.

    `available?/0` returns `false`. The `mix mailglass.inbound.prune` task does
    NOT gate on this — it runs `MailglassInbound.Internal.Prune.prune/0`
    synchronously regardless (only scheduling needs Oban, D-49-28).
    """

    @doc since: "1.2.0"
    @spec available?() :: false
    def available?, do: false
  end
end
