import Config

# Fake adapter for all test runs. Tests that exercise real-provider adapters
# inject {:ok, ...} return shapes via Mox in their own setup blocks.
config :mailglass,
  adapter: {Mailglass.Adapters.Fake, []}

# Suppress the boot-time "Oban not loaded" warning in test output.
config :logger, level: :warning
