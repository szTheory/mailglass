defmodule MailglassAdmin.PubSub.Topics do
  @moduledoc """
  Typed topic builder for `mailglass_admin` PubSub broadcasts. Every topic is
  prefixed `mailglass:` — Phase 6 `LINT-06 PrefixedPubSubTopics` (see the
  forthcoming check in the core `mailglass` package) enforces the prefix at
  lint time. The prefixed shape matches `Mailglass.PubSub.Topics` in the core
  library; the two modules intentionally share the convention so adopter
  telemetry handlers can pattern-match on a single namespace.

  ## Topics emitted

  - `admin_reload/0` — `"mailglass:admin:reload"` — the LiveReload notify
    target. `MailglassAdmin.PreviewLive` subscribes on mount; broadcasts
    originate from the adopter's `:phoenix_live_reload` config (CONTEXT
    D-24). The admin package itself never broadcasts on this topic at
    v0.1 — it is purely a consumer surface.

  At v0.1 `admin_reload/0` is the ONE topic the admin package consumes.
  Every call site that subscribes to or broadcasts on this topic MUST go
  through this module — literal topic strings in call sites are banned by
  the Phase 6 lint discipline.

  Submodules of `MailglassAdmin` are auto-classified into the root
  boundary (`use Boundary, deps: [Mailglass], exports: [Router]` in
  `lib/mailglass_admin.ex`); `classify_to:` is a Boundary directive
  reserved for mix tasks and protocol implementations and is not used
  here.
  """

  @doc "Returns the LiveReload broadcast topic for admin auto-refresh."
  @doc since: "0.1.0"
  @spec admin_reload() :: String.t()
  def admin_reload, do: "mailglass:admin:reload"
end
