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

  - `inbound_record_inserted/1` — `"mailglass:inbound:\#{tenant_id}"` — the
    per-tenant inbound stream the operator dashboard subscribes to (on
    `Mailglass.PubSub`) so new inbound mail renders in real time. The admin is
    a CONSUMER of this topic; `mailglass_inbound` is the producer. The builder
    here MUST return the IDENTICAL string as
    `MailglassInbound.PubSub.Topics.inbound_record_inserted/1` (CONTEXT D-48-11,
    V8) — the parity test asserts it — so a subscribe here matches a broadcast
    there without an inbound→admin compile dependency.

  `admin_reload/0` and `inbound_record_inserted/1` are the topics the admin
  package consumes. Every call site that subscribes to or broadcasts on these
  topics MUST go through this module — literal topic strings in call sites are
  banned by the Phase 6 lint discipline (LINT-06 PrefixedPubSubTopics).

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

  @doc """
  Returns the per-tenant inbound record-inserted stream topic.

  The operator dashboard subscribes to this topic on `Mailglass.PubSub`. The
  `tenant_id` is embedded so subscribers are scoped to a single tenant. Returns
  the IDENTICAL string as `MailglassInbound.PubSub.Topics.inbound_record_inserted/1`
  (CONTEXT D-48-11) — the admin consumes the inbound producer's stream without an
  inbound→admin compile dependency.
  """
  @doc since: "0.2.0"
  @spec inbound_record_inserted(String.t()) :: String.t()
  def inbound_record_inserted(tenant_id) when is_binary(tenant_id),
    do: "mailglass:inbound:" <> tenant_id
end
