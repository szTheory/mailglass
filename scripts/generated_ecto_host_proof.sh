#!/usr/bin/env bash
#
# Generated Ecto-host proof — upgrades populated prior-version schemas through
# both public package generators, proves concurrent-index recovery, and rolls
# back only the additive versions.
set -euo pipefail

FRESH_DELIVERY_STAGES=(fresh_install sync_send atomic_enqueue worker_run persisted_outcome)
BOUNDARY_STAGES=(custom_modules multi_repo_prefixes upgrade rollback idempotent_rerun)

validate_stage_attestation() {
  local journey="$1"
  local stage="$2"
  local result="$3"
  local expected

  case "${journey}|${stage}" in
    core_first\|fresh_install) expected="install_order=core,inbound" ;;
    inbound_first\|fresh_install) expected="install_order=inbound,core" ;;
    core_first\|sync_send|inbound_first\|sync_send) expected="delivery=sent;events=2" ;;
    core_first\|atomic_enqueue|inbound_first\|atomic_enqueue)
      expected="rollback=0,0,0;commit=1,1"
      ;;
    core_first\|worker_run|inbound_first\|worker_run) expected="job=completed" ;;
    core_first\|persisted_outcome|inbound_first\|persisted_outcome)
      expected="delivery=sent;event=dispatched;events=2"
      ;;
    core_first\|custom_modules|inbound_first\|custom_modules)
      expected="repos=postgres;adapter=generated"
      ;;
    core_first\|multi_repo_prefixes|inbound_first\|multi_repo_prefixes)
      expected="prefixes=isolated;migration_sources=2"
      ;;
    core_first\|upgrade|inbound_first\|upgrade) expected="versions=6,2;indexes=valid" ;;
    core_first\|rollback|inbound_first\|rollback)
      expected="versions=5,1;host_marker=present"
      ;;
    core_first\|idempotent_rerun|inbound_first\|idempotent_rerun)
      expected="versions=5,1;host_marker=present"
      ;;
    *)
      echo "Generated-host attestation has an unknown journey/stage." >&2
      return 1
      ;;
  esac

  if [ "${result}" != "${expected}" ]; then
    echo "Generated-host attestation mismatch for ${journey}/${stage}." >&2
    return 1
  fi
}

validate_checkpoint_file() {
  local checkpoint_path="$1"
  local expected_rows=()
  local journey
  local stage
  local sequence=0
  local row_index=0

  for journey in core_first inbound_first; do
    for stage in "${FRESH_DELIVERY_STAGES[@]}"; do
      sequence=$((sequence + 1))
      expected_rows+=("${sequence}|${journey}|${stage}|passed")
    done

    for stage in "${BOUNDARY_STAGES[@]}"; do
      sequence=$((sequence + 1))
      expected_rows+=("${sequence}|${journey}|${stage}|passed")
    done
  done

  if [ ! -f "${checkpoint_path}" ]; then
    echo "Generated-host checkpoint file is missing." >&2
    return 1
  fi

  while IFS= read -r checkpoint_row || [ -n "${checkpoint_row}" ]; do
    if [ "${row_index}" -ge "${#expected_rows[@]}" ] ||
       [ "${checkpoint_row}" != "${expected_rows[${row_index}]}" ]; then
      echo "Generated-host checkpoint contract mismatch at row $((row_index + 1))." >&2
      return 1
    fi

    row_index=$((row_index + 1))
  done < "${checkpoint_path}"

  if [ "${row_index}" -ne "${#expected_rows[@]}" ]; then
    echo "Generated-host checkpoint contract is incomplete." >&2
    return 1
  fi
}

if [ "${1:-}" = "--validate-checkpoints" ]; then
  if [ "$#" -ne 2 ]; then
    echo "Usage: $0 --validate-checkpoints CHECKPOINT_FILE" >&2
    exit 2
  fi

  validate_checkpoint_file "$2"
  exit
fi

if [ "${1:-}" = "--validate-attestation" ]; then
  if [ "$#" -ne 4 ]; then
    echo "Usage: $0 --validate-attestation JOURNEY STAGE RESULT" >&2
    exit 2
  fi

  validate_stage_attestation "$2" "$3" "$4"
  exit
fi

MAILGLASS_PATH="${MAILGLASS_PATH:?MAILGLASS_PATH must point at the working tree}"
DATABASE_URL="${DATABASE_URL:?DATABASE_URL must name the generated-host scratch database}"

if [ -n "${WORK_DIR:-}" ]; then
  echo "WORK_DIR is not accepted: generated-host proof always creates its own scratch directory." >&2
  exit 1
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mailglass-generated-ecto-host.XXXXXX")"
CHECKPOINT_FILE="${WORK_DIR}/generated-host-checkpoints.txt"
ATTESTATION_FILE="${WORK_DIR}/generated-host-attestations.txt"
CHECKPOINT_SEQUENCE=0
JOURNEY_HOST_DIRS=()
JOURNEY_DATABASE_URLS=()

checkpoint() {
  local journey="$1"
  local stage="$2"
  local result_path="$3"
  local result

  if [ ! -f "${result_path}" ]; then
    echo "Generated-host runtime attestation is missing for ${journey}/${stage}." >&2
    return 1
  fi

  result="$(<"${result_path}")"
  validate_stage_attestation "${journey}" "${stage}" "${result}"

  CHECKPOINT_SEQUENCE=$((CHECKPOINT_SEQUENCE + 1))
  printf '%s|%s|%s|%s\n' "${CHECKPOINT_SEQUENCE}" "${journey}" "${stage}" "${result}" >> "${ATTESTATION_FILE}"
  printf '%s|%s|%s|passed\n' "${CHECKPOINT_SEQUENCE}" "${journey}" "${stage}" >> "${CHECKPOINT_FILE}"
}

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
    inbound) MIX_ENV=dev DATABASE_URL="${journey_url}" mix do compile + mailglass.inbound.gen.migration --repo Host.InboundRepo "$@" ;;
    *)
      echo "Unknown package generator: ${package}" >&2
      exit 1
      ;;
  esac
}

rollback_package() {
  local package="$1"
  local journey_url="$2"

  case "${package}" in
    core) MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.rollback -r Host.Repo --step 1 ;;
    inbound) MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.rollback -r Host.InboundRepo --step 1 ;;
    *)
      echo "Unknown rollback package: ${package}" >&2
      exit 1
      ;;
  esac
}

migrate_package() {
  local package="$1"
  local journey_url="$2"
  local install_sequence="$3"
  local repo

  case "${package}" in
    core) repo="Host.Repo" ;;
    inbound) repo="Host.InboundRepo" ;;
    *)
      echo "Unknown migration package: ${package}" >&2
      exit 1
      ;;
  esac

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.migrate -r "${repo}"

  INSTALL_PACKAGE="${package}" INSTALL_SEQUENCE="${install_sequence}" \
    MIX_ENV=dev DATABASE_URL="${journey_url}" mix run --no-start -e '
      package = System.fetch_env!("INSTALL_PACKAGE")
      {sequence, ""} = System.fetch_env!("INSTALL_SEQUENCE") |> Integer.parse()
      relation =
        case package do
          "core" -> "mailglass_core.mailglass_events"
          "inbound" -> "mailglass_inbound.mailglass_inbound_records"
        end

      {:ok, _started} = Application.ensure_all_started(:ecto_sql)
      {:ok, _repo} = Host.Repo.start_link()
      %{rows: [[^relation]]} = Host.Repo.query!("SELECT to_regclass($1)::text", [relation])

      Host.Repo.query!("""
      CREATE TABLE IF NOT EXISTS public.generated_host_install_order (
        sequence integer PRIMARY KEY,
        package text NOT NULL CHECK (package IN ($mg$core$mg$, $mg$inbound$mg$))
      )
      """)

      %{num_rows: 1} =
        Host.Repo.query!(
          "INSERT INTO public.generated_host_install_order (sequence, package) VALUES ($1, $2)",
          [sequence, package]
        )
    '
}

run_journey() {
  local journey_name="$1"
  local first_package="$2"
  local second_package="$3"
  local journey_database="${SCRATCH_DATABASE}_${journey_name}"
  local journey_url
  local journey_dir="${WORK_DIR}/${journey_name}"
  local host_dir="${journey_dir}/host"
  local core_migrations_path
  local inbound_migrations_path
  local core_install_path
  local inbound_install_path
  local core_upgrade_path
  local inbound_upgrade_path
  local core_upgrade_version
  local inbound_upgrade_version
  local stage_attestation_path

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

    # `inspect/1` emits a valid Elixir literal for paths containing quotes,
    # backslashes, or whitespace.
    deps =
      "      {:mailglass, path: " <> inspect(path) <> ", override: true},\n" <>
        "      {:mailglass_inbound, path: " <> inspect(Path.join(path, "mailglass_inbound")) <> "},\n" <>
        "      {:oban, \"~> 2.21\"},\n"

    updated = String.replace(content, ~r/(defp deps do\n\s*\[\n)/, "\\1" <> deps, global: false)
    File.write!("mix.exs", updated)
  '

  cat > config/runtime.exs <<'EOF'
import Config

if config_env() == :dev do
  database_url = System.fetch_env!("DATABASE_URL")

  config :host, ecto_repos: [Host.Repo, Host.InboundRepo]

  config :host, Host.Repo,
    url: database_url,
    pool_size: 10,
    migration_source: "core_schema_migrations"

  config :host, Host.InboundRepo,
    url: database_url,
    pool_size: 10,
    migration_source: "inbound_schema_migrations"

  config :mailglass, repo: Host.Repo,
    schema: "mailglass_core",
    adapter: {Host.GeneratedHostAdapter, []},
    adapters: [generated: {Host.GeneratedHostAdapter, []}],
    tenancy: Host.GeneratedHostTenancy,
    async_adapter: :oban

  config :mailglass_inbound, repo: Host.InboundRepo, schema: "mailglass_inbound"
  config :host, Oban, repo: Host.Repo, queues: [mailglass_outbound: 1]
  config :swoosh, :api_client, false
end
EOF

  elixir -e '
    path = "config/config.exs"
    source = File.read!(path)
    updated =
      String.replace(
        source,
        "ecto_repos: [Host.Repo]",
        "ecto_repos: [Host.Repo, Host.InboundRepo]",
        global: false
      )
    if updated == source, do: raise("generated host ecto_repos anchor missing")
    File.write!(path, updated)
  '

  mkdir -p lib/host
  cp "${MAILGLASS_PATH}/test/fixtures/generated_host/custom_modules.exs" lib/host/generated_host_modules.ex

  elixir -e '
    path = "lib/host/application.ex"
    source = File.read!(path)
    updated =
      Regex.replace(
        ~r/^(\s+)Host\.Repo,\n/m,
        source,
        "\\1Host.Repo,\n\\1Host.InboundRepo,\n\\1{Oban, Application.fetch_env!(:host, Oban)},\n",
        global: false
      )
    if updated == source, do: raise("generated host application child anchor missing")
    File.write!(path, updated)
  '

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix deps.get
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix compile --warnings-as-errors
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.drop -r Host.Repo --quiet
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.create -r Host.Repo --quiet

  # Public initial generators provide the real wrappers. Pin only their facade
  # target versions to construct the prior release baseline; no package DDL is
  # copied into the host.
  run_generator "${first_package}" "${journey_url}"
  sleep 1
  run_generator "${second_package}" "${journey_url}"

  core_migrations_path="$(MIX_ENV=dev DATABASE_URL="${journey_url}" mix run --no-start --no-compile -e 'IO.write(Ecto.Migrator.migrations_path(Host.Repo))')"
  inbound_migrations_path="$(MIX_ENV=dev DATABASE_URL="${journey_url}" mix run --no-start --no-compile -e 'IO.write(Ecto.Migrator.migrations_path(Host.InboundRepo))')"
  core_install_path="$(find "${core_migrations_path}" -name '*_mailglass_install.exs' -print -quit)"
  inbound_install_path="$(find "${inbound_migrations_path}" -name '*_mailglass_inbound_install.exs' -print -quit)"

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.gen.migration install_oban -r Host.Repo
  oban_migration_path="$(find "${core_migrations_path}" -name '*_install_oban.exs' -print -quit)"
  cat > "${oban_migration_path}" <<'EOF'
defmodule Host.Repo.Migrations.InstallOban do
  use Ecto.Migration

  def up, do: Oban.Migrations.up()
  def down, do: Oban.Migrations.down()
end
EOF

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
      "MailglassInbound.Migration.up(repo: Host.InboundRepo)",
      "MailglassInbound.Migration.up(repo: Host.InboundRepo, version: 1)"
    )
  '

  if rg -q 'create table\(:mailglass_|CREATE TABLE[[:space:]]+mailglass_' "${core_migrations_path}" "${inbound_migrations_path}"; then
    echo "Generated wrappers must not contain copied package DDL." >&2
    exit 1
  fi

  migrate_package "${first_package}" "${journey_url}" 1
  migrate_package "${second_package}" "${journey_url}" 2

  stage_attestation_path="${journey_dir}/fresh-install.attestation"
  STAGE_ATTESTATION_PATH="${stage_attestation_path}" \
    EXPECTED_FIRST_PACKAGE="${first_package}" EXPECTED_SECOND_PACKAGE="${second_package}" \
    MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    expected_first = System.fetch_env!("EXPECTED_FIRST_PACKAGE")
    expected_second = System.fetch_env!("EXPECTED_SECOND_PACKAGE")

    if Mailglass.Migration.migrated_version(repo: Host.Repo) != 5,
      do: raise("core baseline did not stop at V05")

    if MailglassInbound.Migration.migrated_version(repo: Host.InboundRepo) != 1,
      do: raise("inbound baseline did not stop at V01")

    %{rows: [[1, ^expected_first], [2, ^expected_second]]} =
      Host.Repo.query!(
        "SELECT sequence, package FROM public.generated_host_install_order ORDER BY sequence"
      )

    File.write!(
      System.fetch_env!("STAGE_ATTESTATION_PATH"),
      "install_order=#{expected_first},#{expected_second}"
    )

    webhook_id = Ecto.UUID.generate()

    Host.Repo.query!(
      """
      INSERT INTO mailglass_core.mailglass_webhook_events
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

      Host.InboundRepo.query!(
        """
        INSERT INTO mailglass_inbound.mailglass_inbound_records
          (id, tenant_id, provider, received_at, inserted_at, updated_at)
        VALUES ($1::uuid, $mg$generated-host$mg$, $mg$sendgrid$mg$, now(), now(), now())
        """,
        [Ecto.UUID.dump!(record_id)]
      )

      Host.InboundRepo.query!(
        """
        INSERT INTO mailglass_inbound.mailglass_inbound_evidence
          (id, tenant_id, provider, inbound_record_id, raw_payload, raw_headers,
           raw_mime, verification_facts, parse_warnings, attachment_blobs,
           inserted_at, updated_at)
        VALUES ($1::uuid, $mg$generated-host$mg$, $mg$sendgrid$mg$, $2::uuid, $json${}$json$::jsonb,
                $json${}$json$::jsonb, $3, $json${}$json$::jsonb, $json${}$json$::jsonb, $json${}$json$::jsonb, now(), now())
        """,
        [Ecto.UUID.dump!(evidence_id), Ecto.UUID.dump!(record_id), raw_mime]
      )
    end)

    %{rows: [["oban_jobs"]]} = Host.Repo.query!("SELECT to_regclass($mg$public.oban_jobs$mg$)::text")
  '

  checkpoint "${journey_name}" fresh_install "${stage_attestation_path}"

  stage_attestation_path="${journey_dir}/sync-send.attestation"
  STAGE_ATTESTATION_PATH="${stage_attestation_path}" \
    MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    Mailglass.Tenancy.put_current("generated-host")

    message =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Generated", "sender@example.invalid"})
      |> Swoosh.Email.to("sync@example.invalid")
      |> Swoosh.Email.subject("generated sync proof")
      |> Swoosh.Email.html_body("<p>generated sync proof</p>")
      |> Swoosh.Email.text_body("generated sync proof")
      |> Mailglass.Message.build(mailable: Host.GeneratedProof, tenant_id: "generated-host")

    {:ok, delivery} = Mailglass.deliver(message)
    true = delivery.status == :sent
    true = delivery.last_event_type == :dispatched
    true = delivery.provider_message_id == "generated-host-#{delivery.id}"

    %{rows: [["sent", 2]]} = Host.Repo.query!(
      "SELECT d.status, count(e.id) FROM mailglass_core.mailglass_deliveries d JOIN mailglass_core.mailglass_events e ON e.delivery_id = d.id WHERE d.id = $1::uuid GROUP BY d.status",
      [Ecto.UUID.dump!(delivery.id)]
    )

    File.write!(System.fetch_env!("STAGE_ATTESTATION_PATH"), "delivery=sent;events=2")
  '

  checkpoint "${journey_name}" sync_send "${stage_attestation_path}"

  # Force the final Oban step in the enqueue Multi to fail for one known
  # delivery id. The preceding delivery and queued-event writes must roll back
  # with it; success-only co-existence is not sufficient atomicity evidence.
  stage_attestation_path="${journey_dir}/atomic-enqueue.attestation"
  STAGE_ATTESTATION_PATH="${stage_attestation_path}" \
    MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    Mailglass.Tenancy.put_current("generated-host")
    failure_id = Ecto.UUID.generate()
    constraint = "generated_host_atomic_enqueue_failure"

    Host.Repo.query!("""
    ALTER TABLE public.oban_jobs
      ADD CONSTRAINT #{constraint}
      CHECK ((args->>$mg$delivery_id$mg$) IS DISTINCT FROM $mg$#{failure_id}$mg$)
    """)

    try do
      message =
        Swoosh.Email.new()
        |> Swoosh.Email.from({"Generated", "sender@example.invalid"})
        |> Swoosh.Email.to("rollback@example.invalid")
        |> Swoosh.Email.subject("generated atomic rollback proof")
        |> Swoosh.Email.text_body("generated atomic rollback proof")
        |> Mailglass.Message.build(
          mailable: Host.GeneratedProof,
          tenant_id: "generated-host",
          metadata: %{delivery_id: failure_id}
        )

      try do
        result = Mailglass.deliver_later(message)
        raise "atomic rollback fixture unexpectedly returned #{inspect(result)}"
      rescue
        error in Ecto.ConstraintError ->
          if error.constraint != constraint, do: reraise(error, __STACKTRACE__)
      end

      %{rows: [[0, 0, 0]]} = Host.Repo.query!(
        """
        SELECT
          (SELECT count(*) FROM mailglass_core.mailglass_deliveries WHERE id = $1::uuid),
          (SELECT count(*) FROM mailglass_core.mailglass_events WHERE delivery_id = $1::uuid),
          (SELECT count(*) FROM public.oban_jobs WHERE args->>$mg$delivery_id$mg$ = $2)
        """,
        [Ecto.UUID.dump!(failure_id), failure_id]
      )

      File.write!(System.fetch_env!("STAGE_ATTESTATION_PATH"), "rollback=0,0,0")
    after
      Host.Repo.query!("ALTER TABLE public.oban_jobs DROP CONSTRAINT #{constraint}")
    end
  '

  async_delivery_id_path="${journey_dir}/async-delivery-id"

  ASYNC_DELIVERY_ID_PATH="${async_delivery_id_path}" \
    STAGE_ATTESTATION_PATH="${stage_attestation_path}" \
    MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    Mailglass.Tenancy.put_current("generated-host")

    message =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Generated", "sender@example.invalid"})
      |> Swoosh.Email.to("async@example.invalid")
      |> Swoosh.Email.subject("generated async proof")
      |> Swoosh.Email.html_body("<p>generated async proof</p>")
      |> Swoosh.Email.text_body("generated async proof")
      |> Mailglass.Message.build(mailable: Host.GeneratedProof, tenant_id: "generated-host")

    {:ok, delivery} = Mailglass.deliver_later(message)

    %{rows: [[1]]} = Host.Repo.query!(
      "SELECT count(*) FROM public.oban_jobs WHERE args->>$mg$delivery_id$mg$ = $1",
      [delivery.id]
    )

    %{rows: [[1]]} = Host.Repo.query!(
      "SELECT count(*) FROM mailglass_core.mailglass_deliveries WHERE id = $1::uuid AND tenant_id = $mg$generated-host$mg$",
      [Ecto.UUID.dump!(delivery.id)]
    )

    File.write!(System.fetch_env!("ASYNC_DELIVERY_ID_PATH"), delivery.id)
    File.write!(System.fetch_env!("STAGE_ATTESTATION_PATH"), ";commit=1,1", [:append])
  '

  async_delivery_id="$(<"${async_delivery_id_path}")"

  if ! printf '%s' "${async_delivery_id}" | rg -q '^[0-9a-f-]{36}$'; then
    echo "Generated-host async delivery did not return a UUID." >&2
    exit 1
  fi

  checkpoint "${journey_name}" atomic_enqueue "${stage_attestation_path}"

  stage_attestation_path="${journey_dir}/worker-run.attestation"
  ASYNC_DELIVERY_ID="${async_delivery_id}" STAGE_ATTESTATION_PATH="${stage_attestation_path}" \
    MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    delivery_id = System.fetch_env!("ASYNC_DELIVERY_ID")

    wait_until = fn predicate, description ->
      Enum.reduce_while(1..100, nil, fn _, _ ->
        if predicate.() do
          {:halt, :ok}
        else
          Process.sleep(100)
          {:cont, nil}
        end
      end) || raise("timed out waiting for #{description}")
    end

    :ok = wait_until.(fn ->
      %{rows: [[state]]} = Host.Repo.query!(
        "SELECT state FROM public.oban_jobs WHERE args->>$mg$delivery_id$mg$ = $1",
        [delivery_id]
      )

      state == "completed"
    end, "Oban worker completion")

    File.write!(System.fetch_env!("STAGE_ATTESTATION_PATH"), "job=completed")
  '

  checkpoint "${journey_name}" worker_run "${stage_attestation_path}"

  stage_attestation_path="${journey_dir}/persisted-outcome.attestation"
  ASYNC_DELIVERY_ID="${async_delivery_id}" STAGE_ATTESTATION_PATH="${stage_attestation_path}" \
    MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    delivery_id = System.fetch_env!("ASYNC_DELIVERY_ID")

    %{rows: [["sent", "dispatched", provider_message_id, 2]]} = Host.Repo.query!(
      "SELECT d.status, d.last_event_type, d.provider_message_id, count(e.id) FROM mailglass_core.mailglass_deliveries d JOIN mailglass_core.mailglass_events e ON e.delivery_id = d.id WHERE d.id = $1::uuid GROUP BY d.status, d.last_event_type, d.provider_message_id",
      [Ecto.UUID.dump!(delivery_id)]
    )

    true = provider_message_id == "generated-host-#{delivery_id}"

    %{rows: [[true]]} = Host.Repo.query!(
      "SELECT EXISTS (SELECT 1 FROM mailglass_core.mailglass_deliveries WHERE id = $1::uuid AND metadata::text LIKE $mg$%generated async proof%$mg$)",
      [Ecto.UUID.dump!(delivery_id)]
    )

    File.write!(
      System.fetch_env!("STAGE_ATTESTATION_PATH"),
      "delivery=sent;event=dispatched;events=2"
    )
  '

  checkpoint "${journey_name}" persisted_outcome "${stage_attestation_path}"

  stage_attestation_path="${journey_dir}/custom-modules.attestation"
  ASYNC_DELIVERY_ID="${async_delivery_id}" STAGE_ATTESTATION_PATH="${stage_attestation_path}" \
    MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    delivery_id = System.fetch_env!("ASYNC_DELIVERY_ID")
    Ecto.Adapters.Postgres = Host.InboundRepo.__adapter__()
    {:ok, :generated} =
      Host.GeneratedHostTenancy.resolve_outbound_adapter_ref(%{tenant_id: "generated-host"})

    %{rows: [["generated", provider_message_id]]} = Host.Repo.query!(
      "SELECT adapter_ref, provider_message_id FROM mailglass_core.mailglass_deliveries WHERE id = $1::uuid",
      [Ecto.UUID.dump!(delivery_id)]
    )

    true = provider_message_id == "generated-host-#{delivery_id}"
    File.write!(System.fetch_env!("STAGE_ATTESTATION_PATH"), "repos=postgres;adapter=generated")
  '

  checkpoint "${journey_name}" custom_modules "${stage_attestation_path}"

  stage_attestation_path="${journey_dir}/multi-repo-prefixes.attestation"
  STAGE_ATTESTATION_PATH="${stage_attestation_path}" \
    MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    Host.Repo.query!("CREATE TABLE IF NOT EXISTS public.generated_host_marker (id integer PRIMARY KEY)")

    %{rows: [["mailglass_core.mailglass_deliveries"]]} =
      Host.Repo.query!("SELECT to_regclass($mg$mailglass_core.mailglass_deliveries$mg$)::text")

    %{rows: [["mailglass_inbound.mailglass_inbound_records"]]} =
      Host.InboundRepo.query!("SELECT to_regclass($mg$mailglass_inbound.mailglass_inbound_records$mg$)::text")

    %{rows: [[nil, nil]]} = Host.Repo.query!(
      "SELECT to_regclass($mg$public.mailglass_deliveries$mg$), to_regclass($mg$public.mailglass_inbound_records$mg$)"
    )

    %{rows: [[2]]} = Host.Repo.query!(
      "SELECT count(*) FROM information_schema.tables WHERE table_schema = $mg$public$mg$ AND table_name = ANY($1)",
      [["core_schema_migrations", "inbound_schema_migrations"]]
    )

    File.write!(
      System.fetch_env!("STAGE_ATTESTATION_PATH"),
      "prefixes=isolated;migration_sources=2"
    )
  '

  checkpoint "${journey_name}" multi_repo_prefixes "${stage_attestation_path}"

  sleep 1
  run_generator "${first_package}" "${journey_url}" --upgrade --from "$(if [ "${first_package}" = core ]; then printf 5; else printf 1; fi)"
  sleep 1
  run_generator "${second_package}" "${journey_url}" --upgrade --from "$(if [ "${second_package}" = core ]; then printf 5; else printf 1; fi)"

  core_upgrade_path="$(find "${core_migrations_path}" -name '*_mailglass_upgrade.exs' -print -quit)"
  inbound_upgrade_path="$(find "${inbound_migrations_path}" -name '*_mailglass_inbound_upgrade.exs' -print -quit)"

  for upgrade_path in "${core_upgrade_path}" "${inbound_upgrade_path}"; do
    rg -q '@disable_ddl_transaction true' "${upgrade_path}"
    rg -q '@disable_migration_lock true' "${upgrade_path}"
    rg -q 'non_transactional_wrapper: true' "${upgrade_path}"
  done

  rg -q 'Mailglass\.Migration\.down\(repo: Host\.Repo, version: 5, non_transactional_wrapper: true\)' "${core_upgrade_path}"
  rg -q 'MailglassInbound\.Migration\.down\(repo: Host\.InboundRepo, version: 1, non_transactional_wrapper: true\)' "${inbound_upgrade_path}"

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.migrate -r Host.Repo
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.migrate -r Host.InboundRepo

  stage_attestation_path="${journey_dir}/upgrade.attestation"
  STAGE_ATTESTATION_PATH="${stage_attestation_path}" \
    MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    alias MailglassInbound.InboundMessage
    alias MailglassInbound.Ingress.Persist

    if Mailglass.Migration.migrated_version(repo: Host.Repo) != 6,
      do: raise("core upgrade did not reach V06")

    if MailglassInbound.Migration.migrated_version(repo: Host.InboundRepo) != 2,
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

    {:ok, %{status: :duplicate}} = Persist.persist(handoff, repo: Host.InboundRepo, routes: [])

    {:ok, %{count: 1, done?: false, next_cursor: cursor}} =
      Persist.backfill_sha256(repo: Host.InboundRepo, prefix: "mailglass_inbound", limit: 1)

    %{rows: [[1]]} = Host.InboundRepo.query!("SELECT count(*) FROM mailglass_inbound.mailglass_inbound_evidence WHERE raw_mime_sha256 IS NULL")

    {:ok, %{count: 1, done?: true}} =
      Persist.backfill_sha256(repo: Host.InboundRepo, prefix: "mailglass_inbound", limit: 1, after_id: cursor)

    {:ok, %{count: 0, done?: true}} =
      Persist.backfill_sha256(repo: Host.InboundRepo, prefix: "mailglass_inbound", limit: 1)

    raw_signed_body = <<0, 255, 13, 10, 123, 34, 98, 121, 116, 101, 115, 34, 125>>
    webhook_id = Ecto.UUID.generate()

    Host.Repo.query!(
      """
      INSERT INTO mailglass_core.mailglass_webhook_events
        (id, tenant_id, provider, provider_event_id, event_type_raw, status,
         raw_payload, raw_signed_body, received_at, inserted_at, updated_at)
      VALUES ($1::uuid, $mg$generated-host$mg$, $mg$postmark$mg$, $mg$byte-proof$mg$, $mg$Delivery$mg$,
              $mg$pending$mg$, $json${}$json$::jsonb, $2, now(), now(), now())
      """,
      [Ecto.UUID.dump!(webhook_id), raw_signed_body]
    )

    %{rows: [[^raw_signed_body]]} =
      Host.Repo.query!("SELECT raw_signed_body FROM mailglass_core.mailglass_webhook_events WHERE id = $1::uuid", [Ecto.UUID.dump!(webhook_id)])

    core_names = Mailglass.Migrations.Postgres.V06.concurrent_indexes()
    inbound_names = MailglassInbound.Migrations.Postgres.V02.concurrent_indexes()

    %{rows: core_index_rows} = Host.Repo.query!(
      """
      SELECT c.relname, i.indisvalid, i.indisready
      FROM pg_index AS i
      JOIN pg_class AS c ON c.oid = i.indexrelid
      JOIN pg_namespace AS n ON n.oid = c.relnamespace
      WHERE n.nspname = $mg$mailglass_core$mg$ AND c.relname = ANY($1)
      ORDER BY c.relname
      """,
      [core_names]
    )

    %{rows: inbound_index_rows} = Host.InboundRepo.query!(
      """
      SELECT c.relname, i.indisvalid, i.indisready
      FROM pg_index AS i
      JOIN pg_class AS c ON c.oid = i.indexrelid
      JOIN pg_namespace AS n ON n.oid = c.relnamespace
      WHERE n.nspname = $mg$mailglass_inbound$mg$ AND c.relname = ANY($1)
      ORDER BY c.relname
      """,
      [inbound_names]
    )

    if length(core_index_rows) != length(core_names) or
         Enum.any?(core_index_rows, fn [_name, valid, ready] -> not valid or not ready end) or
         length(inbound_index_rows) != length(inbound_names) or
         Enum.any?(inbound_index_rows, fn [_name, valid, ready] -> not valid or not ready end),
      do: raise("generated upgrade indexes are missing or invalid")

    Host.Repo.checkout(fn ->
      Host.Repo.query!("SET enable_seqscan = off")
      webhook_plan = Host.Repo.query!("EXPLAIN (FORMAT JSON) SELECT id FROM mailglass_core.mailglass_webhook_events WHERE status = $mg$pending$mg$ ORDER BY inserted_at, id LIMIT 10")
      plans = inspect(webhook_plan.rows)

      unless String.contains?(plans, "mailglass_webhook_events_status_age_id_idx"),
        do: raise("expected generated indexes were absent from EXPLAIN plans: #{plans}")

      Host.Repo.query!("RESET enable_seqscan")
    end)

    Host.InboundRepo.checkout(fn ->
      Host.InboundRepo.query!("SET enable_seqscan = off")
      inbound_plan = Host.InboundRepo.query!("EXPLAIN (FORMAT JSON) SELECT id FROM mailglass_inbound.mailglass_inbound_evidence WHERE tenant_id = $mg$generated-host$mg$ AND provider = $mg$sendgrid$mg$ AND raw_mime_sha256 = decode(repeat($mg$00$mg$, 32), $mg$hex$mg$)")

      unless String.contains?(inspect(inbound_plan.rows), "mailglass_inbound_evidence_sha256_idx"),
        do: raise("expected inbound generated index was absent from EXPLAIN plan")

      Host.InboundRepo.query!("RESET enable_seqscan")
    end)

    File.write!(System.fetch_env!("STAGE_ATTESTATION_PATH"), "versions=6,2;indexes=valid")
  '

  checkpoint "${journey_name}" upgrade "${stage_attestation_path}"

  # Create the exact PostgreSQL failure residue that CREATE INDEX CONCURRENTLY
  # leaves behind, then rerun the generated core wrapper from anchor V05.
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    name = "mailglass_webhook_events_status_age_id_idx"
    Host.Repo.query!("DROP INDEX CONCURRENTLY IF EXISTS mailglass_core.#{name}")

    try do
      Host.Repo.query!(
        "CREATE INDEX CONCURRENTLY #{name} ON mailglass_core.mailglass_webhook_events ((1 / (CASE WHEN status = $mg$succeeded$mg$ THEN 0 ELSE 1 END)))"
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
      WHERE n.nspname = $mg$mailglass_core$mg$ AND c.relname = $1
      """,
      [name]
    )
  '

  core_upgrade_version="$(basename "${core_upgrade_path}" | cut -d_ -f1)"

  CORE_UPGRADE_VERSION="${core_upgrade_version}" MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    {version, ""} = System.fetch_env!("CORE_UPGRADE_VERSION") |> Integer.parse()
    Host.Repo.query!("DELETE FROM core_schema_migrations WHERE version = $1", [version])
    Host.Repo.query!("COMMENT ON TABLE mailglass_core.mailglass_events IS $mg$5$mg$")
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
      WHERE n.nspname = $mg$mailglass_core$mg$ AND c.relname = ANY($1)
      """,
      [names]
    )

    if length(rows) != length(names) or Enum.any?(rows, fn [_name, valid, ready] -> not valid or not ready end),
      do: raise("core invalid-index retry did not converge: #{inspect(rows)}")
  '

  # Exercise the inbound path independently: a failed concurrent build leaves
  # an invalid index shell, which the generated V02 wrapper must remove before
  # it can rebuild all package-owned indexes.
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    name = "mailglass_inbound_evidence_retention_idx"
    Host.InboundRepo.query!("DROP INDEX CONCURRENTLY IF EXISTS mailglass_inbound.#{name}")

    try do
      Host.InboundRepo.query!(
        "CREATE INDEX CONCURRENTLY #{name} ON mailglass_inbound.mailglass_inbound_evidence ((1 / (CASE WHEN provider = $mg$sendgrid$mg$ THEN 0 ELSE 1 END)))"
      )

      raise "invalid-index fixture unexpectedly succeeded"
    rescue
      error in Postgrex.Error ->
        if error.postgres.code != :division_by_zero, do: reraise(error, __STACKTRACE__)
    end

    %{rows: [[false]]} = Host.InboundRepo.query!(
      """
      SELECT i.indisvalid
      FROM pg_index AS i
      JOIN pg_class AS c ON c.oid = i.indexrelid
      JOIN pg_namespace AS n ON n.oid = c.relnamespace
      WHERE n.nspname = $mg$mailglass_inbound$mg$ AND c.relname = $1
      """,
      [name]
    )
  '

  inbound_upgrade_version="$(basename "${inbound_upgrade_path}" | cut -d_ -f1)"

  INBOUND_UPGRADE_VERSION="${inbound_upgrade_version}" MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    {version, ""} = System.fetch_env!("INBOUND_UPGRADE_VERSION") |> Integer.parse()
    Host.InboundRepo.query!("DELETE FROM inbound_schema_migrations WHERE version = $1", [version])
    Host.InboundRepo.query!("COMMENT ON TABLE mailglass_inbound.mailglass_inbound_records IS $mg$1$mg$")
  '

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.migrate -r Host.InboundRepo
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.migrate -r Host.InboundRepo

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    if MailglassInbound.Migration.migrated_version(repo: Host.InboundRepo) != 2,
      do: raise("inbound invalid-index retry did not restore V02")

    names = MailglassInbound.Migrations.Postgres.V02.concurrent_indexes()

    %{rows: rows} = Host.InboundRepo.query!(
      """
      SELECT c.relname, i.indisvalid, i.indisready
      FROM pg_index AS i
      JOIN pg_class AS c ON c.oid = i.indexrelid
      JOIN pg_namespace AS n ON n.oid = c.relnamespace
      WHERE n.nspname = $mg$mailglass_inbound$mg$ AND c.relname = ANY($1)
      """,
      [names]
    )

    if length(rows) != length(names) or Enum.any?(rows, fn [_name, valid, ready] -> not valid or not ready end),
      do: raise("inbound invalid-index retry did not converge: #{inspect(rows)}")
  '

  rollback_package "${second_package}" "${journey_url}"
  FIRST_ROLLBACK_PACKAGE="${second_package}" MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    case System.fetch_env!("FIRST_ROLLBACK_PACKAGE") do
      "core" ->
        5 = Mailglass.Migration.migrated_version(repo: Host.Repo)
        2 = MailglassInbound.Migration.migrated_version(repo: Host.InboundRepo)

      "inbound" ->
        6 = Mailglass.Migration.migrated_version(repo: Host.Repo)
        1 = MailglassInbound.Migration.migrated_version(repo: Host.InboundRepo)
    end
  '

  rollback_package "${first_package}" "${journey_url}"
  stage_attestation_path="${journey_dir}/rollback.attestation"
  STAGE_ATTESTATION_PATH="${stage_attestation_path}" \
    MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    5 = Mailglass.Migration.migrated_version(repo: Host.Repo)
    1 = MailglassInbound.Migration.migrated_version(repo: Host.InboundRepo)

    %{rows: [[nil]]} = Host.Repo.query!("SELECT to_regclass($mg$mailglass_core.mailglass_webhook_events_status_age_id_idx$mg$)")
    %{rows: [[nil]]} = Host.InboundRepo.query!("SELECT to_regclass($mg$mailglass_inbound.mailglass_inbound_evidence_sha256_idx$mg$)")

    %{rows: [[0]]} = Host.Repo.query!(
      """
      SELECT count(*) FROM information_schema.columns
      WHERE table_schema = $mg$mailglass_core$mg$ AND
        table_name = $mg$mailglass_webhook_events$mg$ AND column_name = $mg$raw_signed_body$mg$
      """
    )

    %{rows: [[0]]} = Host.InboundRepo.query!(
      """
      SELECT count(*) FROM information_schema.columns
      WHERE table_schema = $mg$mailglass_inbound$mg$ AND
        table_name = $mg$mailglass_inbound_evidence$mg$ AND column_name = $mg$raw_mime_sha256$mg$
      """
    )

    for relation <- ["mailglass_events", "mailglass_webhook_events"] do
      %{rows: [[name]]} = Host.Repo.query!("SELECT to_regclass($1)", ["mailglass_core.#{relation}"])
      if is_nil(name), do: raise("additive rollback removed prior relation #{relation}")
    end

    for relation <- ["mailglass_inbound_records", "mailglass_inbound_evidence"] do
      %{rows: [[name]]} = Host.InboundRepo.query!("SELECT to_regclass($1)", ["mailglass_inbound.#{relation}"])
      if is_nil(name), do: raise("additive rollback removed prior relation #{relation}")
    end

    %{rows: [[2]]} = Host.InboundRepo.query!("SELECT count(*) FROM mailglass_inbound.mailglass_inbound_evidence")
    %{rows: [["generated_host_marker"]]} = Host.Repo.query!("SELECT to_regclass($mg$public.generated_host_marker$mg$)::text")
    File.write!(
      System.fetch_env!("STAGE_ATTESTATION_PATH"),
      "versions=5,1;host_marker=present"
    )
  '

  checkpoint "${journey_name}" rollback "${stage_attestation_path}"

  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.rollback -r Host.Repo --to "${core_upgrade_version}"
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.rollback -r Host.Repo --to "${core_upgrade_version}"
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.rollback -r Host.InboundRepo --to "${inbound_upgrade_version}"
  MIX_ENV=dev DATABASE_URL="${journey_url}" mix ecto.rollback -r Host.InboundRepo --to "${inbound_upgrade_version}"

  stage_attestation_path="${journey_dir}/idempotent-rerun.attestation"
  STAGE_ATTESTATION_PATH="${stage_attestation_path}" \
    MIX_ENV=dev DATABASE_URL="${journey_url}" mix run -e '
    5 = Mailglass.Migration.migrated_version(repo: Host.Repo)
    1 = MailglassInbound.Migration.migrated_version(repo: Host.InboundRepo)
    %{rows: [["generated_host_marker"]]} = Host.Repo.query!("SELECT to_regclass($mg$public.generated_host_marker$mg$)::text")
    File.write!(
      System.fetch_env!("STAGE_ATTESTATION_PATH"),
      "versions=5,1;host_marker=present"
    )
  '

  checkpoint "${journey_name}" idempotent_rerun "${stage_attestation_path}"
}

# Opposing generator, initial migration, upgrade, and rollback order proves
# package independence across the complete journey.
run_journey core_first core inbound
run_journey inbound_first inbound core

validate_checkpoint_file "${CHECKPOINT_FILE}"
cat "${CHECKPOINT_FILE}"
echo "Generated Ecto host proof passed."
