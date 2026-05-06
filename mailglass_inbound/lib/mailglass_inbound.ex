defmodule MailglassInbound do
  @moduledoc since: "0.5.0"
  @moduledoc """
  Public contract root for the `mailglass_inbound` sibling package.

  Phase 39 intentionally keeps the stable surface narrow:

  - `MailglassInbound.InboundMessage` is the canonical normalized inbound value object.
  - `MailglassInbound.Router` is the adopter-owned routing DSL.
  - `MailglassInbound.Mailbox` is the mailbox callback contract.
  - `version/0` returns the package version string at compile time.

  The canonical Phase 39 contract inventory lives in
  `mailglass_inbound/docs/api_stability.md`.

  Provider-specific ingress, mailbox execution runners, and any operator or UI
  surfaces remain deferred to later phases even when package-local internals
  exist to support them.
  """

  @version Mix.Project.config()[:version]

  @doc since: "0.5.0"
  @spec version() :: String.t()
  def version, do: @version
end
