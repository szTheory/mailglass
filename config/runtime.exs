import Config

# Adopter-provided runtime configuration example (uncomment and adapt):
#
#   config :mailglass,
#     repo: MyApp.Repo,
#     adapter:
#       {Mailglass.Adapters.Swoosh,
#        swoosh_adapter:
#          {Swoosh.Adapters.Postmark, api_key: System.fetch_env!("POSTMARK_DEFAULT_API_KEY")}},
#     adapters: [
#       postmark_acme:
#         {Mailglass.Adapters.Swoosh,
#          swoosh_adapter:
#            {Swoosh.Adapters.Postmark, api_key: System.fetch_env!("POSTMARK_ACME_API_KEY")}},
#       sendgrid_globex:
#         {Mailglass.Adapters.Swoosh,
#          swoosh_adapter:
#            {Swoosh.Adapters.Sendgrid, api_key: System.fetch_env!("SENDGRID_GLOBEX_API_KEY")}},
#       ses_ops:
#         {Mailglass.Adapters.Swoosh,
#          swoosh_adapter:
#            {Swoosh.Adapters.AmazonSES,
#             region: "us-east-1",
#             access_key: System.fetch_env!("SES_ACCESS_KEY"),
#             secret: System.fetch_env!("SES_SECRET")}}
#     ]
#
# Single-tenant installs only need `config :mailglass, adapter`.
# Add `config :mailglass, adapters:` when your tenancy callback needs
# reusable named route refs at runtime.

# CI matrix-axis hook (D-06 / Success Criterion 7). runtime.exs is evaluated
# AFTER config/test.exs, so this runtime override wins over the test.exs
# `:schema` "public" pin. When the Advisory Matrix job sets
# `MAILGLASS_SCHEMA=mailglass`, the whole core suite runs under the isolated
# `mailglass` schema via the existing `Config.schema/0` path (facade prefix
# injection + migration entrypoint). Guarded to the :test env and a non-empty
# value so dev/prod are never affected and the default suite (no env var) keeps
# the config/test.exs "public" pin.
if config_env() == :test do
  case System.get_env("MAILGLASS_SCHEMA") do
    schema when is_binary(schema) and schema != "" ->
      config :mailglass, :schema, schema

    _ ->
      :ok
  end
end
