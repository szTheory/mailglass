#!/usr/bin/env bash
# Disposable, package-shaped Mailglass adopter-host migration proof.
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DEP_MODE="${DEP_MODE:-local}"
KEEP_HOST_ON_FAILURE="${KEEP_HOST_ON_FAILURE:-false}"
WORK_DIR="${WORK_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/mailglass-generated-host.XXXXXX")}"
STAGE="boot"
FAMILY="all"
HOST_DIR="${WORK_DIR}/generated_host"
ARTIFACT_DIR="${WORK_DIR}/artifacts"
CHECKPOINT_OUT="${CHECKPOINT_OUT:-$ROOT_DIR/tmp/generated-host-proof/checkpoint.json}"
export HEX_HOME="${WORK_DIR}/hex"
export MIX_HOME="${WORK_DIR}/mix"

usage() {
  echo "Usage: DEP_MODE=local|hex scripts/generated_host_proof.sh [--stage all|migrate|boot|docs|async-parity|negative-controls|feedback|feedback-unsubscribe|readiness] [--family queue-schema|input]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stage) STAGE="${2:-}"; shift 2 ;;
    --family) FAMILY="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "generated-host proof blocked: unknown option '$1'" >&2; usage; exit 1 ;;
  esac
done

case "$DEP_MODE" in local|hex) ;; *) echo "generated-host proof blocked: DEP_MODE must be local|hex" >&2; exit 1 ;; esac
case "$STAGE" in all|migrate|boot|docs|async-parity|negative-controls|feedback|feedback-unsubscribe|readiness) ;; *) echo "generated-host proof blocked: invalid --stage" >&2; exit 1 ;; esac
case "$FAMILY" in all|queue-schema|input) ;; *) echo "generated-host proof blocked: invalid --family" >&2; exit 1 ;; esac
case "$WORK_DIR" in ''|/|"$ROOT_DIR") echo "generated-host proof blocked: unsafe WORK_DIR" >&2; exit 1 ;; esac

cleanup() {
  status=$?

  if [[ "$status" -ne 0 && "$KEEP_HOST_ON_FAILURE" == "true" ]]; then
    echo "generated-host proof retained at $WORK_DIR" >&2
  else
    if [[ -f "$HOST_DIR/config/mailglass_generated_host.exs" ]]; then
      if ! (cd "$HOST_DIR" && MIX_ENV=dev mix ecto.drop --quiet >/dev/null 2>&1); then
        echo "generated-host proof cleanup failed to drop its disposable database" >&2
        if [[ "$status" -eq 0 ]]; then
          status=1
        fi
      fi
    fi

    rm -rf "$WORK_DIR"
  fi

  exit "$status"
}
trap cleanup EXIT

if [[ "$STAGE" == "all" ]]; then
  for stage in migrate boot docs async-parity negative-controls feedback feedback-unsubscribe readiness; do
    echo "generated-host proof: running stage=$stage"
    WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mailglass-generated-host.XXXXXX")" \
      DEP_MODE="$DEP_MODE" KEEP_HOST_ON_FAILURE="$KEEP_HOST_ON_FAILURE" \
      CHECKPOINT_OUT="$CHECKPOINT_OUT" bash "$0" --stage "$stage" --family "$FAMILY"
  done
  exit 0
fi

mkdir -p "$WORK_DIR" "$ARTIFACT_DIR"
rm -rf "$HOST_DIR"
mix archive.install hex phx_new --force >/dev/null
(cd "$WORK_DIR" && mix phx.new generated_host --module GeneratedHost --app generated_host --no-mailer --no-assets --no-install)

if [[ "$DEP_MODE" == "local" ]]; then
  for package_spec in "mailglass:$ROOT_DIR" "mailglass_admin:$ROOT_DIR/mailglass_admin" "mailglass_inbound:$ROOT_DIR/mailglass_inbound"; do
    app="${package_spec%%:*}"
    package="${package_spec#*:}"
    destination="$ARTIFACT_DIR/$app"
    (cd "$package" && MIX_PUBLISH=true mix hex.build --unpack --output "$destination" >/dev/null)
    [[ -f "$destination/mix.exs" ]] || { echo "generated-host proof blocked: package artifact missing mix.exs" >&2; exit 1; }
  done
fi

cd "$HOST_DIR"
DEP_MODE="$DEP_MODE" ARTIFACT_DIR="$ARTIFACT_DIR" VERSION="${VERSION:-}" VERSION_INBOUND="${VERSION_INBOUND:-}" elixir -e '
  dep = fn app, path, version ->
    case System.get_env("DEP_MODE") do
      "local" -> "      {:#{app}, path: \"#{path}\", override: true},\n"
      "hex" when version != "" -> "      {:#{app}, \"== #{version}\"},\n"
      "hex" -> raise "hex mode requires exact package versions"
    end
  end
  artifact_dir = System.fetch_env!("ARTIFACT_DIR")
  entries = case System.get_env("DEP_MODE") do
    "local" -> dep.(:mailglass, Path.join(artifact_dir, "mailglass"), "") <> dep.(:mailglass_admin, Path.join(artifact_dir, "mailglass_admin"), "") <> dep.(:mailglass_inbound, Path.join(artifact_dir, "mailglass_inbound"), "") <> "      {:oban, \"~> 2.21\"},\n"
    "hex" -> dep.(:mailglass, "", System.fetch_env!("VERSION")) <> dep.(:mailglass_admin, "", System.fetch_env!("VERSION")) <> dep.(:mailglass_inbound, "", System.fetch_env!("VERSION_INBOUND")) <> "      {:oban, \"~> 2.21\"},\n"
  end
  content = File.read!("mix.exs")
  File.write!("mix.exs", String.replace(content, ~r/(defp deps do\n\s*\[\n)/, "\\1" <> entries, global: false))
'
MIX_PUBLISH=true mix deps.get
if [[ "$DEP_MODE" == "hex" ]] && (grep -Eq '"(path|git)":' mix.lock || grep -Eq 'path:|git:' mix.exs); then
  echo "generated-host proof blocked: Hex mode resolved a path or git dependency" >&2
  exit 1
fi

cp "$ROOT_DIR/dev/mailglass/generated_host/journey.ex" lib/generated_host_journey.ex
cp "$ROOT_DIR/dev/mailglass/generated_host/host_template.ex" lib/generated_host_host_template.ex
cp "$ROOT_DIR/dev/mailglass/generated_host/checkpoint.ex" lib/generated_host_checkpoint.ex
schema="mailglass_proof_$(date +%s)_$RANDOM"
ELIXIR_STAGE="${STAGE//-/_}"
ELIXIR_FAMILY="${FAMILY//-/_}"
# The generated Mailglass config must exist before the VM that runs the
# journey loads Mix configuration. The journey remains idempotent and writes
# the same host-owned sources again, but doing this in a preliminary VM keeps
# the Repo used for catalog assertions on the same per-run database that the
# child migration commands use.
MIX_ENV=dev mix run --no-start -e "Mailglass.GeneratedHost.HostTemplate.install!(File.cwd!(), \"$schema\")"
MIX_ENV=dev mix run --no-start -e "proof = Mailglass.GeneratedHost.Journey.run!(schema: \"$schema\", stage: :$ELIXIR_STAGE, family: :$ELIXIR_FAMILY); File.write!(\"proof.json\", Jason.encode!(proof))"
mkdir -p "$WORK_DIR/checkpoint"
DEP_MODE="$DEP_MODE" STAGE="$STAGE" SOURCE_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD)" MIX_ENV=dev mix run --no-start -e 'proof = Jason.decode!(File.read!("proof.json")); stage = System.get_env("STAGE"); stages = [%{"name" => "install", "status" => "passed", "command_sha256" => String.duplicate("0", 64)}, %{"name" => "migrate", "status" => "passed", "command_sha256" => String.duplicate("1", 64)}] ++ if(stage == "async-parity", do: [Mailglass.GeneratedHost.Checkpoint.async_parity!(proof["async_parity"])], else: []) ++ if(stage == "negative-controls", do: [Mailglass.GeneratedHost.Checkpoint.negative_controls!(proof["negative_controls"])], else: []) ++ if(stage in ["feedback", "feedback-unsubscribe"], do: [Mailglass.GeneratedHost.Checkpoint.feedback!(proof["feedback"])], else: []) ++ if(stage == "feedback-unsubscribe", do: [Mailglass.GeneratedHost.Checkpoint.one_click!(proof["one_click"])], else: []) ++ if(stage == "readiness", do: [Mailglass.GeneratedHost.Checkpoint.operator_readiness!(proof["operator_readiness"])], else: []); payload = Mailglass.GeneratedHost.Checkpoint.encode(%{dependency_mode: System.fetch_env!("DEP_MODE"), source_sha: System.fetch_env!("SOURCE_SHA"), packages: [], stages: stages}); File.write!(Path.expand("../checkpoint.json", File.cwd!()), Jason.encode!(payload))'
bash "$ROOT_DIR/scripts/check_generated_host_proof.sh" --checkpoint "$WORK_DIR/checkpoint.json"
mkdir -p "$(dirname "$CHECKPOINT_OUT")"
cp "$WORK_DIR/checkpoint.json" "$CHECKPOINT_OUT"
echo "generated-host proof passed: mode=$DEP_MODE stage=$STAGE schema=$schema"
