import Config

# Synthetic adopter endpoint for router + LiveView test coverage.
# See test/support/endpoint_case.ex. The `secret_key_base` literal is
# 72 chars (>= Phoenix's 64-byte minimum).
#
# `pubsub_server: Mailglass.PubSub` — Plan 06's LiveReload test
# (preview_live_test.exs line 138) broadcasts on `Mailglass.PubSub`,
# so the synthetic endpoint points there. `Mailglass.PubSub` is started
# by the mailglass core application's supervisor, which boots when
# `:mailglass` loads. The earlier choice of `MailglassAdmin.TestPubSub`
# (Plan 02) was never started by any supervisor and never carried
# adopter broadcasts — Plan 06 corrects the mismatch.
config :mailglass_admin, MailglassAdmin.TestAdopter.Endpoint,
  http: [port: 4002],
  server: false,
  secret_key_base: String.duplicate("mailglass_admin_test_secret_key_base_0", 2),
  live_view: [signing_salt: "mailglass_admin_test_signing_salt_0123"],
  pubsub_server: Mailglass.PubSub,
  render_errors: [formats: [html: MailglassAdmin.TestAdopter.ErrorHTML], layout: false]
