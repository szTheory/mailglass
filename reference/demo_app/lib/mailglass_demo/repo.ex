defmodule MailglassDemo.Repo do
  use Ecto.Repo,
    otp_app: :mailglass_demo,
    adapter: Ecto.Adapters.Postgres

  # v2.0 moves the mailglass + inbound tables into the configured schema
  # (default "mailglass"). This demo shares ONE repo across `:mailglass`,
  # `:mailglass_inbound`, and its own seed/reset code, and its entire dataset
  # lives in that single schema — exactly the posture of a single-schema
  # adopter. Library reads/writes route through the facades
  # (`Mailglass.Repo` / `MailglassInbound.InboundRecords`), which inject
  # `prefix:`; but the demo also inserts core changesets DIRECTLY through this
  # repo (`DemoData.delivery!/1` etc.) and issues raw TRUNCATE/count SQL, none
  # of which carry a prefix. Pinning the connection `search_path` to the
  # configured schema makes every access — facade, direct-ORM, and raw —
  # resolve there. `Mailglass.Config.schema/0` validates the value as a safe
  # SQL identifier, so interpolating it into the SET is injection-safe.
  #
  # This is a consumer-app convenience for a single-schema deployment; it is
  # NOT the library test harness (where locked-decision-3 forbids leaning on
  # search_path to mask a missing `prefix:`). Explicit qualification is still
  # used for the raw SQL in `DemoData`.
  # `public` is listed FIRST so the core `CREATE EXTENSION IF NOT EXISTS citext`
  # (v01.ex, deliberately UNqualified per MIGR-05) installs into `public` and
  # Postgrex can resolve the `citext` type at connection boot. The mailglass +
  # inbound tables live ONLY in the isolated schema, so an unqualified table
  # reference still resolves via the `#{schema}` fallback entry — while citext
  # (which exists only in `public`) resolves via the leading `public` entry.
  def init(_context, config) do
    schema = Mailglass.Config.schema()
    config = Keyword.put(config, :after_connect, {Postgrex, :query!, ["SET search_path = public, #{schema}", []]})
    {:ok, config}
  end
end
