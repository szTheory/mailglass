import Config

# Attach the default telemetry logger in dev so render/send events surface in iex.
config :mailglass, telemetry: [default_logger: true]
