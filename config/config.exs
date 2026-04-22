import Config

# Mailglass config is read at runtime via Application.get_env/2.
# Only Mailglass.Config may use Application.compile_env* (LINT-08).
# See Mailglass.Config for the full option schema (lands in Plan 03).
config :mailglass,
  adapter: {Mailglass.Adapters.Fake, []}

# Swoosh 1.25+ requires :api_client to be set at boot. Mailglass does not
# pin a specific HTTP client — adopters choose (Finch, Hackney, Req) or use
# Mailglass.Adapters.Fake in dev/test. Set to false so Swoosh skips init.
# Adopters override this in their own config when they select an HTTP adapter.
config :swoosh, :api_client, false

import_config "#{config_env()}.exs"
