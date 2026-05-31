defmodule MailglassInbound do
  @moduledoc since: "0.1.0"
  @moduledoc """
  Public contract root for the `mailglass_inbound` sibling package.

  this milestone phase keeps the stable surface narrow and explicit:

  - `MailglassInbound.InboundMessage` is the canonical normalized inbound value object.
  - `MailglassInbound.Router` is the adopter-owned routing DSL.
  - `MailglassInbound.Mailbox` is the mailbox callback contract.
  - `MailglassInbound.Ingress.Plug` is the first-party Postmark ingress entrypoint.
  - `MailglassInbound.Ingress.CachingBodyReader` is the package-local raw-body capture helper.
  - `version/0` returns the package version string at compile time.

  The canonical this milestone phase contract inventory lives in
  `mailglass_inbound/docs/api_stability.md`.

  Provider internals, persistence internals, mailbox execution runners, and any
  operator or UI surfaces remain internal or deferred even when package-local
  modules exist to support them.
  """

  @version Mix.Project.config()[:version]

  @doc since: "0.1.0"
  @spec version() :: String.t()
  def version, do: @version
end
