# Conditionally compiled — the entire `defmodule` is elided when
# `:phoenix_live_reload` is absent, so `MailglassAdmin.OptionalDeps.PhoenixLiveReload`
# does not exist at all without the dep. Callers must guard via
# `Code.ensure_loaded?(MailglassAdmin.OptionalDeps.PhoenixLiveReload)` before
# referencing it. This mirrors the core mailglass pattern for Sigra
# integration (see `lib/mailglass/optional_deps/sigra.ex`).
if Code.ensure_loaded?(Phoenix.LiveReloader) do
  defmodule MailglassAdmin.OptionalDeps.PhoenixLiveReload do
    @moduledoc """
    Gateway for the optional `{:phoenix_live_reload, "~> 1.6"}` dep
    (CONTEXT D-24, dev-only).

    When `phoenix_live_reload` is loaded (the normal dev configuration),
    `MailglassAdmin.PreviewLive` subscribes to
    `MailglassAdmin.PubSub.Topics.admin_reload/0`
    (`"mailglass:admin:reload"`) on connected-socket mount — the adopter's
    `:phoenix_live_reload` config broadcasts on that topic after a file
    save, which drives the LiveView to re-discover mailables and re-render
    the current scenario.

    When `phoenix_live_reload` is absent (prod builds, dev without the
    dep installed), the gateway module is elided entirely. PreviewLive's
    subscribe step is skipped; the dashboard still renders — the adopter
    just has to hit the browser refresh button after editing a mailable.

    Boundary classification: submodule auto-classifies into the
    `MailglassAdmin` root boundary declared in `lib/mailglass_admin.ex`;
    `classify_to:` is reserved for mix tasks and protocol implementations
    and is not used here.
    """

    @compile {:no_warn_undefined, [Phoenix.LiveReloader]}

    @doc """
    Returns `true`. Because this module is conditionally compiled, its
    mere existence implies `phoenix_live_reload` is loaded. Callers
    should still `Code.ensure_loaded?(__MODULE__)` before calling.
    """
    @doc since: "0.1.0"
    @spec available?() :: boolean()
    def available?, do: true
  end
end
