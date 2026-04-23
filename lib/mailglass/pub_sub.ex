defmodule Mailglass.PubSub do
  @moduledoc """
  Name atom for the mailglass-owned Phoenix.PubSub child.

  The `Mailglass.Application` supervision tree starts
  `{Phoenix.PubSub, name: Mailglass.PubSub, adapter: Phoenix.PubSub.PG2}`.
  Projector broadcasts, admin LiveView subscriptions, and TestAssertions'
  PubSub-backed matchers all target this name.

  ## Topics

  See `Mailglass.PubSub.Topics` — a typed builder producing
  `mailglass:`-prefixed binaries. Phase 6 `LINT-06 PrefixedPubSubTopics`
  enforces the prefix at lint time.
  """
end
