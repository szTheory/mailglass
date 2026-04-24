defmodule Mailglass.Webhook do
  @moduledoc """
  Webhook boundary root.

  External adopters use `Mailglass.Webhook.Router` and
  `Mailglass.Webhook.CachingBodyReader`; internal modules under
  `Mailglass.Webhook.*` share the same boundary.
  """

  use Boundary,
    deps: [Mailglass, Mailglass.Events],
    exports: [CachingBodyReader, Plug, Router, Reconciler, Pruner]
end
