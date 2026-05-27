defmodule MailglassInbound.Application do
  @moduledoc false

  use Application
  require Logger

  @fallback_warning_key {:mailglass_inbound, :fallback_warning_emitted}

  @impl Application
  def start(_type, _args) do
    :ok = maybe_warn_fallback_mode()

    children = [
      {Task.Supervisor, name: MailglassInbound.TaskSupervisor},
      # Owns the :mailglass_inbound_rate_limit ETS table for the post-verify
      # ingress rate limiter (IOPS-04, the design contract). The prune Oban worker is NOT
      # auto-registered here (the design contract) — it stays unregistered; operators run
      # `mix mailglass.inbound.prune` or wire the documented cron themselves.
      MailglassInbound.RateLimiter.TableOwner
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: MailglassInbound.Supervisor)
  end

  @spec maybe_warn_fallback_mode(keyword()) :: :ok
  def maybe_warn_fallback_mode(opts \\ []) when is_list(opts) do
    optional_deps = Keyword.get(opts, :optional_deps, MailglassInbound.OptionalDeps.Oban)
    warning_key = Keyword.get(opts, :warning_key, @fallback_warning_key)
    already_warned? = :persistent_term.get(warning_key, false)

    cond do
      already_warned? ->
        :ok

      optional_deps.runner() != :task_supervisor ->
        :ok

      true ->
        Logger.warning("""
        [mailglass_inbound] Oban durable execution is unavailable; inbound mailbox execution will use Task.Supervisor only.
        This fallback is best-effort: there is no durable enqueue, no automatic retry, and replay is the recovery path after node loss or shutdown.
        """)

        :persistent_term.put(warning_key, true)
        :ok
    end
  end
end
