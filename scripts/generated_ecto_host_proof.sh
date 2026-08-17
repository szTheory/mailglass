#!/usr/bin/env bash
#
# Generated Ecto-host proof — verifies the public migration generators against
# a stock Phoenix host and its own Postgres Repo. This is deliberately separate
# from consumer_install_smoke.sh's no-Ecto preview/boot journey.
set -euo pipefail

MAILGLASS_PATH="${MAILGLASS_PATH:?MAILGLASS_PATH must point at the working tree}"
DATABASE_URL="${DATABASE_URL:?DATABASE_URL must name the generated-host scratch database}"
WORK_DIR="${WORK_DIR:-$(mktemp -d)}"
HOST_DIR="${WORK_DIR}/host"

database_name_from_url() {
  local url_without_query="${DATABASE_URL%%\?*}"
  printf '%s' "${url_without_query##*/}"
}

SCRATCH_DATABASE="$(database_name_from_url)"

case "${SCRATCH_DATABASE}" in
  mailglass_generated_ecto_host_[a-z0-9_]*) ;;
  *)
    echo "Refusing to create or drop DATABASE_URL outside the generated-host scratch namespace." >&2
    echo "Expected a database named mailglass_generated_ecto_host_<suffix>; got ${SCRATCH_DATABASE}." >&2
    exit 1
    ;;
esac

cleanup() {
  if [ -d "${HOST_DIR}" ]; then
    (
      cd "${HOST_DIR}"
      MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix ecto.drop -r Host.Repo --quiet
    ) || true
  fi

  rm -rf "${WORK_DIR}"
}

trap cleanup EXIT

echo "==> generated Ecto host proof (${SCRATCH_DATABASE})"

if ! mix phx.new --version >/dev/null 2>&1; then
  mix local.hex --force
  mix local.rebar --force
  mix archive.install hex phx_new --force
fi

rm -rf "${HOST_DIR}"
(
  cd "${WORK_DIR}"
  mix phx.new host --module Host --app host --no-install --no-assets --no-html --no-mailer
)

cd "${HOST_DIR}"

MAILGLASS_PATH="${MAILGLASS_PATH}" elixir -e '
  path = System.fetch_env!("MAILGLASS_PATH")
  content = File.read!("mix.exs")

  deps =
    ~s(      {:mailglass, path: "#{path}", override: true},\n) <>
      ~s(      {:mailglass_inbound, path: "#{path}/mailglass_inbound"},\n)

  updated = String.replace(content, ~r/(defp deps do\n\s*\[\n)/, "\\1" <> deps, global: false)
  File.write!("mix.exs", updated)
'

cat > config/runtime.exs <<'EOF'
import Config

if config_env() == :dev do
  database_url = System.fetch_env!("DATABASE_URL")

  config :host, Host.Repo,
    url: database_url,
    pool_size: 10

  config :mailglass, repo: Host.Repo,
    schema: "mailglass",
    adapter: {Mailglass.Adapters.Fake, []},
    async_adapter: :task_supervisor

  config :mailglass_inbound, repo: Host.Repo, schema: "mailglass"

  config :swoosh, :api_client, false
end
EOF

MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix deps.get
MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix compile --warnings-as-errors
MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix ecto.drop -r Host.Repo --quiet
MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix ecto.create -r Host.Repo --quiet

MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix do compile + mailglass.gen.migration --repo Host.Repo
sleep 1
MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix do compile + mailglass.inbound.gen.migration --repo Host.Repo

MIGRATIONS_PATH="$(MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix run --no-start -e 'IO.write(Ecto.Migrator.migrations_path(Host.Repo))')"

if ! rg -q 'Mailglass\.Migration\.up\(\)' "${MIGRATIONS_PATH}"/*_mailglass_install.exs ||
    ! rg -q 'MailglassInbound\.Migration\.up\(\)' "${MIGRATIONS_PATH}"/*_mailglass_inbound_install.exs; then
  echo "Generated wrappers did not delegate to both public package façades." >&2
  exit 1
fi

if rg -q 'create table\(:mailglass_|CREATE TABLE[[:space:]]+mailglass_' "${MIGRATIONS_PATH}"; then
  echo "Generated wrappers must not contain copied package DDL." >&2
  exit 1
fi

MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix ecto.migrate -r Host.Repo

MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix run -e '
  alias Mailglass.Outbound.Delivery

  if Mailglass.Migration.migrated_version(repo: Host.Repo) !=
       Mailglass.Migrations.Postgres.current_version() do
    raise "core migration anchor did not reach the package current version"
  end

  if MailglassInbound.Migration.migrated_version(repo: Host.Repo) !=
       MailglassInbound.Migrations.Postgres.current_version() do
    raise "inbound migration anchor did not reach the package current version"
  end

  attrs = %{
    tenant_id: "generated-host",
    mailable: "GeneratedHostMailable",
    stream: :transactional,
    recipient: "generated-host@example.com",
    last_event_type: :queued,
    last_event_at: DateTime.utc_now(),
    metadata: %{}
  }

  {:ok, delivery} = Host.Repo.insert(Delivery.changeset(attrs), prefix: "mailglass")
  reloaded = Host.Repo.get!(Delivery, delivery.id, prefix: "mailglass")
  1 = Host.Repo.aggregate(Delivery, :count, :id, prefix: "mailglass")

  if reloaded.id != delivery.id do
    raise "Host.Repo did not reload the persisted delivery"
  end
'

MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix ecto.rollback -r Host.Repo --step 1
MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix run -e '
  %{rows: [[nil]]} = Host.Repo.query!("SELECT to_regclass($1)", ["mailglass.mailglass_inbound_records"])
'

MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix ecto.rollback -r Host.Repo --step 1
MIX_ENV=dev DATABASE_URL="${DATABASE_URL}" mix run -e '
  assert_relations_absent! = fn ->
    for relation <- ["mailglass_events", "mailglass_deliveries", "mailglass_inbound_records"] do
      %{rows: [[nil]]} = Host.Repo.query!("SELECT to_regclass($1)", ["mailglass.#{relation}"])
    end
  end

  assert_relations_absent!.()
'

echo "Generated Ecto host proof passed."
