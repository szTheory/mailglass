#!/usr/bin/env bash
#
# Generated Ecto-host proof — verifies both public migration generators against
# fresh stock Phoenix hosts and their own Postgres Repos.
set -euo pipefail

MAILGLASS_PATH="${MAILGLASS_PATH:?MAILGLASS_PATH must point at the working tree}"
DATABASE_URL="${DATABASE_URL:?DATABASE_URL must name the generated-host scratch database}"

if [ -n "${WORK_DIR:-}" ]; then
  echo "WORK_DIR is not accepted: generated-host proof always creates its own scratch directory." >&2
  exit 1
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mailglass-generated-ecto-host.XXXXXX")"
JOURNEY_HOST_DIRS=()
JOURNEY_DATABASE_URLS=()

database_name_from_url() {
  local url_without_query="${DATABASE_URL%%\?*}"
  printf '%s' "${url_without_query##*/}"
}

database_url_with_name() {
  local database_name="$1"
  local url_without_query="${DATABASE_URL%%\?*}"
  local query="${DATABASE_URL#"${url_without_query}"}"
  printf '%s/%s%s' "${url_without_query%/*}" "${database_name}" "${query}"
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
  local index

  for index in "${!JOURNEY_HOST_DIRS[@]}"; do
    if [ -d "${JOURNEY_HOST_DIRS[${index}]}" ]; then
      (
        cd "${JOURNEY_HOST_DIRS[${index}]}"
        MIX_ENV=dev DATABASE_URL="${JOURNEY_DATABASE_URLS[${index}]}" mix ecto.drop -r Host.Repo --quiet
      ) || true
    fi
  done

  rm -rf "${WORK_DIR}"
}

trap cleanup EXIT

if ! mix phx.new --version >/dev/null 2>&1; then
  mix local.hex --force
  mix local.rebar --force
  mix archive.install hex phx_new --force
fi

run_journey() {
  local rollback_order="$1"
  local first_generator="$2"
  local second_generator="$3"
  local journey_database="${SCRATCH_DATABASE}_${rollback_order}"
  local journey_url
  local journey_dir="${WORK_DIR}/${rollback_order}"
  local host_dir="${journey_dir}/host"
  local migrations_path

  case "${rollback_order}" in
    core_first|inbound_first) ;;
    *)
      echo "Unknown rollback order: ${rollback_order}" >&2
      exit 1
      ;;
  esac

  journey_url="$(database_url_with_name "${journey_database}")"
  JOURNEY_HOST_DIRS+=("${host_dir}")
  JOURNEY_DATABASE_URLS+=("${journey_url}")

  echo "==> generated Ecto host proof (${rollback_order}: ${journey_database})"
  mkdir -p "${journey_dir}"

  (
    cd "${journey_dir}"
    mix phx.new host --module Host --app host --no-install --no-assets --no-html --no-mailer
  )

  cd "${host_dir}"

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

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix deps.get
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix compile --warnings-as-errors
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.drop -r Host.Repo --quiet
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.create -r Host.Repo --quiet

  for generator in "${first_generator}" "${second_generator}"; do
    case "${generator}" in
      core) MIX_ENV=dev DATABASE_URL="${journey_url}" mix do compile + mailglass.gen.migration --repo Host.Repo ;;
      inbound) MIX_ENV=dev DATABASE_URL="${journey_url}" mix do compile + mailglass.inbound.gen.migration --repo Host.Repo ;;
    esac
    sleep 1
  done

  migrations_path="$(MIX_ENV=dev DATABASE_URL="${journey_url}" mix run --no-start -e 'IO.write(Ecto.Migrator.migrations_path(Host.Repo))')"

  if ! rg -q 'Mailglass\.Migration\.up\(repo: Host\.Repo\)' "${migrations_path}"/*_mailglass_install.exs ||
      ! rg -q 'Mailglass\.Migration\.down\(repo: Host\.Repo\)' "${migrations_path}"/*_mailglass_install.exs ||
      ! rg -q 'MailglassInbound\.Migration\.up\(repo: Host\.Repo\)' "${migrations_path}"/*_mailglass_inbound_install.exs ||
      ! rg -q 'MailglassInbound\.Migration\.down\(repo: Host\.Repo\)' "${migrations_path}"/*_mailglass_inbound_install.exs; then
    echo "Generated wrappers did not bind both public package façades to Host.Repo." >&2
    exit 1
  fi

  if rg -q 'create table\(:mailglass_|CREATE TABLE[[:space:]]+mailglass_' "${migrations_path}"; then
    echo "Generated wrappers must not contain copied package DDL." >&2
    exit 1
  fi

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.migrate -r Host.Repo

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    alias Mailglass.Outbound.Delivery
    alias MailglassInbound.InboundRecords.InboundRecord

    core_version = Mailglass.Migrations.Postgres.current_version()
    inbound_version = MailglassInbound.Migrations.Postgres.current_version()

    if Mailglass.Migration.migrated_version(repo: Host.Repo) != core_version,
      do: raise("core migration anchor did not reach the package current version")

    if MailglassInbound.Migration.migrated_version(repo: Host.Repo) != inbound_version,
      do: raise("inbound migration anchor did not reach the package current version")

    {:ok, delivery} =
      Host.Repo.insert(Delivery.changeset(%{
          tenant_id: "generated-host",
          mailable: "GeneratedHostMailable",
          stream: :transactional,
          recipient: "generated-host@example.com",
          last_event_type: :queued,
          last_event_at: DateTime.utc_now(),
          metadata: %{}
        }), prefix: "mailglass")

    reloaded_delivery = Host.Repo.get!(Delivery, delivery.id, prefix: "mailglass")

    {:ok, inbound_record} =
      Host.Repo.insert(
        InboundRecord.changeset(%{
          tenant_id: "generated-host",
          provider: "proof",
          provider_message_id: "generated-host-proof",
          received_at: DateTime.utc_now()
        }),
        prefix: "mailglass"
      )

    reloaded_inbound = Host.Repo.get!(InboundRecord, inbound_record.id, prefix: "mailglass")

    if reloaded_delivery.id != delivery.id or reloaded_inbound.id != inbound_record.id,
      do: raise("Host.Repo did not reload persisted package data")
  '

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.rollback -r Host.Repo --step 1
  ROLLED_BACK_PACKAGE="${rollback_order%_first}" MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    rolled_back = System.fetch_env!("ROLLED_BACK_PACKAGE")
    core_relations = ["mailglass_events", "mailglass_deliveries", "mailglass_suppressions", "mailglass_webhook_events"]
    inbound_relations = ["mailglass_inbound_records", "mailglass_inbound_evidence", "mailglass_inbound_replay_runs"]

    assert_absent! = fn relations ->
      Enum.each(relations, fn relation ->
        %{rows: [[nil]]} = Host.Repo.query!("SELECT to_regclass($1)", ["mailglass.#{relation}"])
      end)
    end

    assert_present! = fn relations ->
      Enum.each(relations, fn relation ->
        %{rows: [[name]]} = Host.Repo.query!("SELECT to_regclass($1)", ["mailglass.#{relation}"])
        false = is_nil(name)
      end)
    end

    assert_first_rollback_state! = fn
      "core" ->
        assert_absent!.(core_relations)
        assert_present!.(inbound_relations)
      "inbound" ->
        assert_absent!.(inbound_relations)
        assert_present!.(core_relations)
    end

    assert_first_rollback_state!.(rolled_back)
    %{rows: [["mailglass"]]} = Host.Repo.query!("SELECT to_regnamespace($1)::text", ["mailglass"])
  '

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.rollback -r Host.Repo --step 1
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    relations = [
      "mailglass_events", "mailglass_deliveries", "mailglass_suppressions", "mailglass_webhook_events",
      "mailglass_inbound_records", "mailglass_inbound_evidence", "mailglass_inbound_replay_runs"
    ]

    assert_final_rollback_state! = fn ->
      Enum.each(relations, fn relation ->
        %{rows: [[nil]]} = Host.Repo.query!("SELECT to_regclass($1)", ["mailglass.#{relation}"])
      end)

      %{rows: [[nil]]} = Host.Repo.query!("SELECT to_regnamespace($1)::text", ["mailglass"])
    end

    assert_final_rollback_state!.()
  '
}

# Inbound is generated last here, so ordinary rollback exercises inbound first.
run_journey inbound_first core inbound
# Core is generated last here, so ordinary rollback exercises core first.
run_journey core_first inbound core

echo "Generated Ecto host proof passed."
