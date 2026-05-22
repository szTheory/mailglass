import Config

# Per-env config. Mirrors the core mailglass config/ convention so Mix loads
# the test-env repo credentials from config/test.exs.
import_config "#{config_env()}.exs"
