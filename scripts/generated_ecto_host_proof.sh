#!/usr/bin/env bash
#
# Generated Ecto-host proof — upgrades populated prior-version schemas through
# both public package generators, proves concurrent-index recovery, and rolls
# back only the additive versions.
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

run_generator() {
  local package="$1"
  local journey_url="$2"
  shift 2

  case "${package}" in
    core) MIX_ENV=dev DATABASE_URL="${journey_url}" mix do compile + mailglass.gen.migration --repo Host.Repo "$@" ;;
    inbound) MIX_ENV=dev DATABASE_URL="${journey_url}" mix do compile + mailglass.inbound.gen.migration --repo Host.Repo "$@" ;;
    *)
      echo "Unknown package generator: ${package}" >&2
      exit 1
      ;;
  esac
}

run_journey() {
  local journey_name="$1"
  local first_upgrade="$2"
  local second_upgrade="$3"
  local journey_database="${SCRATCH_DATABASE}_${journey_name}"
  local journey_url
  local journey_dir="${WORK_DIR}/${journey_name}"
  local host_dir="${journey_dir}/host"
  local migrations_path
  local core_install_path
  local inbound_install_path
  local core_upgrade_path
  local inbound_upgrade_path
  local core_upgrade_version

  case "${journey_name}" in
    core_first|inbound_first) ;;
    *)
      echo "Unknown journey: ${journey_name}" >&2
      exit 1
      ;;
  esac

  journey_url="$(database_url_with_name "${journey_database}")"
  JOURNEY_HOST_DIRS+=("${host_dir}")
  JOURNEY_DATABASE_URLS+=("${journey_url}")

  echo "==> generated populated-upgrade proof (${journey_name}: ${journey_database})"
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

  # Public initial generators provide the real wrappers. Pin only their facade
  # target versions to construct the prior release baseline; no package DDL is
  # copied into the host.
  run_generator core "${journey_url}"
  sleep 1
  run_generator inbound "${journey_url}"

  migrations_path="$(MIX_ENV=dev DATABASE_URL="${journey_url}" mix run --no-start --no-compile -e 'IO.write(Ecto.Migrator.migrations_path(Host.Repo))')"
  core_install_path="$(find "${migrations_path}" -name '*_mailglass_install.exs' -print -quit)"
  inbound_install_path="$(find "${migrations_path}" -name '*_mailglass_inbound_install.exs' -print -quit)"

  CORE_INSTALL_PATH="${core_install_path}" INBOUND_INSTALL_PATH="${inbound_install_path}" elixir -e '
    rewrite! = fn path, old, new ->
      source = File.read!(path)
      updated = String.replace(source, old, new, global: false)

      if updated == source, do: raise("baseline wrapper anchor missing from #{path}")
      File.write!(path, updated)
    end

    rewrite!.(
      System.fetch_env!("CORE_INSTALL_PATH"),
      "Mailglass.Migration.up(repo: Host.Repo)",
      "Mailglass.Migration.up(repo: Host.Repo, version: 5)"
    )

    rewrite!.(
      System.fetch_env!("INBOUND_INSTALL_PATH"),
      "MailglassInbound.Migration.up(repo: Host.Repo)",
      "MailglassInbound.Migration.up(repo: Host.Repo, version: 1)"
    )
  '

  if rg -q 'create table\(:mailglass_|CREATE TABLE[[:space:]]+mailglass_' "${migrations_path}"; then
    echo "Generated wrappers must not contain copied package DDL." >&2
    exit 1
  fi

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.migrate -r Host.Repo

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    if Mailglass.Migration.migrated_version(repo: Host.Repo) != 5,
      do: raise("core baseline did not stop at V05")

    if MailglassInbound.Migration.migrated_version(repo: Host.Repo) != 1,
      do: raise("inbound baseline did not stop at V01")

    webhook_id = Ecto.UUID.generate()

    Host.Repo.query!(
      """
      INSERT INTO mailglass.mailglass_webhook_events
        (id, tenant_id, provider, provider_event_id, event_type_raw, status,
         raw_payload, received_at, inserted_at, updated_at)
      VALUES ($1::uuid, $mg$generated-host$mg$, $mg$postmark$mg$, $mg$legacy-webhook$mg$, $mg$Delivery$mg$,
              $mg$succeeded$mg$, $json${}$json$::jsonb, now(), now(), now())
      """,
      [Ecto.UUID.dump!(webhook_id)]
    )

    Enum.each(["legacy-mime-one", "legacy-mime-two"], fn raw_mime ->
      record_id = Ecto.UUID.generate()
      evidence_id = Ecto.UUID.generate()

      Host.Repo.query!(
        """
        INSERT INTO mailglass.mailglass_inbound_records
          (id, tenant_id, provider, received_at, inserted_at, updated_at)
        VALUES ($1::uuid, $mg$generated-host$mg$, $mg$sendgrid$mg$, now(), now(), now())
        """,
        [Ecto.UUID.dump!(record_id)]
      )

      Host.Repo.query!(
        """
        INSERT INTO mailglass.mailglass_inbound_evidence
          (id, tenant_id, provider, inbound_record_id, raw_payload, raw_headers,
           raw_mime, verification_facts, parse_warnings, attachment_blobs,
           inserted_at, updated_at)
        VALUES ($1::uuid, $mg$generated-host$mg$, $mg$sendgrid$mg$, $2::uuid, $json${}$json$::jsonb,
                $json${}$json$::jsonb, $3, $json${}$json$::jsonb, $json${}$json$::jsonb, $json${}$json$::jsonb, now(), now())
        """,
        [Ecto.UUID.dump!(evidence_id), Ecto.UUID.dump!(record_id), raw_mime]
      )
    end)
  '

  sleep 1
  run_generator "${first_upgrade}" "${journey_url}" --upgrade --from "$(if [ "${first_upgrade}" = core ]; then printf 5; else printf 1; fi)"
  sleep 1
  run_generator "${second_upgrade}" "${journey_url}" --upgrade --from "$(if [ "${second_upgrade}" = core ]; then printf 5; else printf 1; fi)"

  core_upgrade_path="$(find "${migrations_path}" -name '*_mailglass_upgrade.exs' -print -quit)"
  inbound_upgrade_path="$(find "${migrations_path}" -name '*_mailglass_inbound_upgrade.exs' -print -quit)"

  for upgrade_path in "${core_upgrade_path}" "${inbound_upgrade_path}"; do
    rg -q '@disable_ddl_transaction true' "${upgrade_path}"
    rg -q '@disable_migration_lock true' "${upgrade_path}"
    rg -q 'non_transactional_wrapper: true' "${upgrade_path}"
  done

  rg -q 'Mailglass\.Migration\.down\(repo: Host\.Repo, version: 5, non_transactional_wrapper: true\)' "${core_upgrade_path}"
  rg -q 'MailglassInbound\.Migration\.down\(repo: Host\.Repo, version: 1, non_transactional_wrapper: true\)' "${inbound_upgrade_path}"

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.migrate -r Host.Repo

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    alias MailglassInbound.InboundMessage
    alias MailglassInbound.Ingress.Persist

    if Mailglass.Migration.migrated_version(repo: Host.Repo) != 6,
      do: raise("core upgrade did not reach V06")

    if MailglassInbound.Migration.migrated_version(repo: Host.Repo) != 2,
      do: raise("inbound upgrade did not reach V02")

    handoff = %{
      tenant_id: "generated-host",
      provider: :sendgrid,
      message: %InboundMessage{
        tenant_id: "generated-host",
        provider: :sendgrid,
        received_at: DateTime.utc_now()
      },
      evidence: %{
        raw_payload: %{}, raw_headers: %{}, raw_mime: "legacy-mime-one",
        verification_facts: %{}, parse_warnings: %{}, attachment_blobs: %{}
      }
    }

    {:ok, %{status: :duplicate}} = Persist.persist(handoff, repo: Host.Repo, routes: [])

    {:ok, %{count: 1, done?: false, next_cursor: cursor}} =
      Persist.backfill_sha256(repo: Host.Repo, prefix: "mailglass", limit: 1)

    %{rows: [[1]]} = Host.Repo.query!("SELECT count(*) FROM mailglass.mailglass_inbound_evidence WHERE raw_mime_sha256 IS NULL")

    {:ok, %{count: 1, done?: true}} =
      Persist.backfill_sha256(repo: Host.Repo, prefix: "mailglass", limit: 1, after_id: cursor)

    {:ok, %{count: 0, done?: true}} =
      Persist.backfill_sha256(repo: Host.Repo, prefix: "mailglass", limit: 1)

    raw_signed_body = <<0, 255, 13, 10, 123, 34, 98, 121, 116, 101, 115, 34, 125>>
    webhook_id = Ecto.UUID.generate()

    Host.Repo.query!(
      """
      INSERT INTO mailglass.mailglass_webhook_events
        (id, tenant_id, provider, provider_event_id, event_type_raw, status,
         raw_payload, raw_signed_body, received_at, inserted_at, updated_at)
      VALUES ($1::uuid, $mg$generated-host$mg$, $mg$postmark$mg$, $mg$byte-proof$mg$, $mg$Delivery$mg$,
              $mg$pending$mg$, $json${}$json$::jsonb, $2, now(), now(), now())
      """,
      [Ecto.UUID.dump!(webhook_id), raw_signed_body]
    )

    %{rows: [[^raw_signed_body]]} =
      Host.Repo.query!("SELECT raw_signed_body FROM mailglass.mailglass_webhook_events WHERE id = $1::uuid", [Ecto.UUID.dump!(webhook_id)])

    expected_indexes =
      Mailglass.Migrations.Postgres.V06.concurrent_indexes() ++
        MailglassInbound.Migrations.Postgres.V02.concurrent_indexes()

    %{rows: index_rows} = Host.Repo.query!(
      """
      SELECT c.relname, i.indisvalid, i.indisready
      FROM pg_index AS i
      JOIN pg_class AS c ON c.oid = i.indexrelid
      JOIN pg_namespace AS n ON n.oid = c.relnamespace
      WHERE n.nspname = $mg$mailglass$mg$ AND c.relname = ANY($1)
      ORDER BY c.relname
      """,
      [expected_indexes]
    )

    if length(index_rows) != length(expected_indexes) or
         Enum.any?(index_rows, fn [_name, valid, ready] -> not valid or not ready end),
      do: raise("generated upgrade indexes are missing or invalid: #{inspect(index_rows)}")

    Host.Repo.checkout(fn ->
      Host.Repo.query!("SET enable_seqscan = off")
      webhook_plan = Host.Repo.query!("EXPLAIN (FORMAT JSON) SELECT id FROM mailglass.mailglass_webhook_events WHERE status = $mg$pending$mg$ ORDER BY inserted_at, id LIMIT 10")
      inbound_plan = Host.Repo.query!("EXPLAIN (FORMAT JSON) SELECT id FROM mailglass.mailglass_inbound_evidence WHERE tenant_id = $mg$generated-host$mg$ AND provider = $mg$sendgrid$mg$ AND raw_mime_sha256 = decode(repeat($mg$00$mg$, 32), $mg$hex$mg$)")
      plans = inspect(webhook_plan.rows) <> inspect(inbound_plan.rows)

      unless String.contains?(plans, "mailglass_webhook_events_status_age_id_idx") and
               String.contains?(plans, "mailglass_inbound_evidence_sha256_idx"),
        do: raise("expected generated indexes were absent from EXPLAIN plans: #{plans}")

      Host.Repo.query!("RESET enable_seqscan")
    end)
  '

  # Create the exact PostgreSQL failure residue that CREATE INDEX CONCURRENTLY
  # leaves behind, then rerun the generated core wrapper from anchor V05.
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    name = "mailglass_webhook_events_status_age_id_idx"
    Host.Repo.query!("DROP INDEX CONCURRENTLY IF EXISTS mailglass.#{name}")

    try do
      Host.Repo.query!(
        "CREATE INDEX CONCURRENTLY #{name} ON mailglass.mailglass_webhook_events ((1 / (CASE WHEN status = $mg$succeeded$mg$ THEN 0 ELSE 1 END)))"
      )

      raise "invalid-index fixture unexpectedly succeeded"
    rescue
      error in Postgrex.Error ->
        if error.postgres.code != :division_by_zero, do: reraise(error, __STACKTRACE__)
    end

    %{rows: [[false]]} = Host.Repo.query!(
      """
      SELECT i.indisvalid
      FROM pg_index AS i
      JOIN pg_class AS c ON c.oid = i.indexrelid
      JOIN pg_namespace AS n ON n.oid = c.relnamespace
      WHERE n.nspname = $mg$mailglass$mg$ AND c.relname = $1
      """,
      [name]
    )
  '

  core_upgrade_version="$(basename "${core_upgrade_path}" | cut -d_ -f1)"

  CORE_UPGRADE_VERSION="${core_upgrade_version}" MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    {version, ""} = System.fetch_env!("CORE_UPGRADE_VERSION") |> Integer.parse()
    Host.Repo.query!("DELETE FROM schema_migrations WHERE version = $1", [version])
    Host.Repo.query!("COMMENT ON TABLE mailglass.mailglass_events IS $mg$5$mg$")
  '

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.migrate -r Host.Repo
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.migrate -r Host.Repo

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    if Mailglass.Migration.migrated_version(repo: Host.Repo) != 6,
      do: raise("core invalid-index retry did not restore V06")

    names = Mailglass.Migrations.Postgres.V06.concurrent_indexes()

    %{rows: rows} = Host.Repo.query!(
      """
      SELECT c.relname, i.indisvalid, i.indisready
      FROM pg_index AS i
      JOIN pg_class AS c ON c.oid = i.indexrelid
      JOIN pg_namespace AS n ON n.oid = c.relnamespace
      WHERE n.nspname = $mg$mailglass$mg$ AND c.relname = ANY($1)
      """,
      [names]
    )

    if length(rows) != length(names) or Enum.any?(rows, fn [_name, valid, ready] -> not valid or not ready end),
      do: raise("core invalid-index retry did not converge: #{inspect(rows)}")
  '

  FIRST_ROLLBACK_PACKAGE="${second_upgrade}" MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.rollback -r Host.Repo --step 1
  FIRST_ROLLBACK_PACKAGE="${second_upgrade}" MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    case System.fetch_env!("FIRST_ROLLBACK_PACKAGE") do
      "core" ->
        5 = Mailglass.Migration.migrated_version(repo: Host.Repo)
        2 = MailglassInbound.Migration.migrated_version(repo: Host.Repo)

      "inbound" ->
        6 = Mailglass.Migration.migrated_version(repo: Host.Repo)
        1 = MailglassInbound.Migration.migrated_version(repo: Host.Repo)
    end
  '

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.rollback -r Host.Repo --step 1
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    5 = Mailglass.Migration.migrated_version(repo: Host.Repo)
    1 = MailglassInbound.Migration.migrated_version(repo: Host.Repo)

    %{rows: [[nil]]} = Host.Repo.query!("SELECT to_regclass($mg$mailglass.mailglass_webhook_events_status_age_id_idx$mg$)")
    %{rows: [[nil]]} = Host.Repo.query!("SELECT to_regclass($mg$mailglass.mailglass_inbound_evidence_sha256_idx$mg$)")

    %{rows: [[0]]} = Host.Repo.query!(
      """
      SELECT count(*) FROM information_schema.columns
      WHERE table_schema = $mg$mailglass$mg$ AND
        ((table_name = $mg$mailglass_webhook_events$mg$ AND column_name = $mg$raw_signed_body$mg$) OR
         (table_name = $mg$mailglass_inbound_evidence$mg$ AND column_name = $mg$raw_mime_sha256$mg$))
      """
    )

    for relation <- ["mailglass_events", "mailglass_webhook_events", "mailglass_inbound_records", "mailglass_inbound_evidence"] do
      %{rows: [[name]]} = Host.Repo.query!("SELECT to_regclass($1)", ["mailglass.#{relation}"])
      if is_nil(name), do: raise("additive rollback removed prior relation #{relation}")
    end

    %{rows: [[2]]} = Host.Repo.query!("SELECT count(*) FROM mailglass.mailglass_inbound_evidence")
  '
}

# Opposing generator order proves package-independent upgrade and rollback.
run_journey core_first core inbound
run_journey inbound_first inbound core

echo "Generated Ecto host proof passed."
