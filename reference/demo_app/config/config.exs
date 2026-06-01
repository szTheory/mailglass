import Config

config :mailglass_demo,
  ecto_repos: [MailglassDemo.Repo]

config :mailglass_demo, MailglassDemo.Repo, migration_timestamps: [type: :utc_datetime_usec]

config :mailglass,
  repo: MailglassDemo.Repo,
  tenancy: Mailglass.Tenancy.SingleTenant,
  adapter: {Mailglass.Adapters.Fake, []},
  async_adapter: :task_supervisor,
  suppression_store: Mailglass.SuppressionStore.Ecto,
  adapter_endpoint: "mailglass-demo-endpoint"

config :mailglass, :tracking,
  host: "localhost:4015",
  scheme: "http",
  salts: ["mailglass-demo-tracking-salt"]

config :mailglass_inbound,
  repo: MailglassDemo.Repo,
  router: MailglassDemoWeb.InboundRouter,
  async_adapter: :task_supervisor,
  postmark: [basic_auth: {"demo-postmark-user", "demo-postmark-pass"}]

config :swoosh, :api_client, false

config :mailglass_demo, MailglassDemoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [html: MailglassDemoWeb.ErrorHTML], layout: false],
  pubsub_server: Mailglass.PubSub,
  live_view: [signing_salt: "mailglass_demo_live_view_salt"]

import_config "#{config_env()}.exs"
