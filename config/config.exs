import Config

# Mailglass config is read at runtime via Application.get_env/2.
# Only Mailglass.Config may use Application.compile_env* (LINT-08).
# See Mailglass.Config for the full option schema (lands in Plan 03).
config :mailglass,
  adapter: {Mailglass.Adapters.Fake, []}

import_config "#{config_env()}.exs"
