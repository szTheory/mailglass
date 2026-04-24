import Config

# Synthetic adopter endpoint for router + LiveView test coverage.
# See test/support/endpoint_case.ex. The `secret_key_base` literal is
# 72 chars (>= Phoenix's 64-byte minimum). The `pubsub_server` name
# matches the PubSub name that Plan 06's LiveReload test broadcasts on.
config :mailglass_admin, MailglassAdmin.TestAdopter.Endpoint,
  http: [port: 4002],
  server: false,
  secret_key_base: String.duplicate("mailglass_admin_test_secret_key_base_0", 2),
  live_view: [signing_salt: "mailglass_admin_test_signing_salt_0123"],
  pubsub_server: MailglassAdmin.TestPubSub,
  render_errors: [formats: [html: MailglassAdmin.TestAdopter.ErrorHTML], layout: false]
