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
