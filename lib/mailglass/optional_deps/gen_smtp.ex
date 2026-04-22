defmodule Mailglass.OptionalDeps.GenSmtp do
  @moduledoc """
  Gateway for the optional gen_smtp dependency (`{:gen_smtp, "~> 1.3"}`).

  Used for SMTP relay ingress in `mailglass_inbound` (v0.5+). Not needed by
  `mailglass` core for outbound — Swoosh handles SMTP transport via its own
  `Swoosh.Adapters.SMTP` which declares `:gen_smtp` as its own optional dep.

  The `:gen_smtp` Hex package is an Erlang library; the entry module is the
  erlang atom `:gen_smtp_client`. There is no `GenSmtp` Elixir module.
  `Code.ensure_loaded?/1` accepts Erlang module atoms transparently.
  """

  @compile {:no_warn_undefined, [:gen_smtp_client]}

  @doc """
  Returns `true` when `:gen_smtp` (`:gen_smtp_client`) is loaded.
  """
  @doc since: "0.1.0"
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(:gen_smtp_client)
end
