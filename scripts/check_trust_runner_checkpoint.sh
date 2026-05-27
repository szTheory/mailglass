#!/usr/bin/env bash
# Validate deterministic trust-runner checkpoint contract artifacts.

set -euo pipefail

CHECKPOINT_PATH="tmp/mailglass_trust_runner/checkpoint.json"

usage() {
  cat <<'EOF'
Usage: check_trust_runner_checkpoint.sh [options]

Validate trust-runner checkpoint artifact schema, boundary claim, stage order,
and deterministic checkpoint hash.

Options:
  --checkpoint PATH  Path to checkpoint.json
  --help             Show this message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --checkpoint)
      CHECKPOINT_PATH="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Trust runner checkpoint validation blocked: unknown option '$1'" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$CHECKPOINT_PATH" ]]; then
  echo "Trust runner checkpoint validation blocked: missing checkpoint at '$CHECKPOINT_PATH'" >&2
  exit 1
fi

python3 - "$CHECKPOINT_PATH" <<'PY'
import hashlib
import json
import pathlib
import sys

checkpoint_path = pathlib.Path(sys.argv[1])
expected_schema = "trust_runner.v1"
expected_boundary = (
    "reference-host trust-journey confidence only; signed-negative webhook and "
    "non-happy-path diagnosis are deferred to Phase 58"
)
required_stages = [
    "install",
    "preview",
    "send",
    "webhook_ingest",
    "operator_troubleshooting",
]

errors = []

try:
    checkpoint = json.loads(checkpoint_path.read_text())
except Exception as exc:  # noqa: BLE001
    print(f"[trust-runner-checkpoint] FAIL: checkpoint is not valid JSON: {exc}", file=sys.stderr)
    sys.exit(1)

required_keys = [
    "schema_version",
    "claim_boundary",
    "checkpoint_count",
    "checkpoint_sha256",
    "checkpoints",
]

for key in required_keys:
    if key not in checkpoint:
        errors.append(f"missing required key '{key}'")

if checkpoint.get("schema_version") != expected_schema:
    errors.append(
        f"schema_version must be '{expected_schema}' (got {checkpoint.get('schema_version')!r})"
    )

if checkpoint.get("claim_boundary") != expected_boundary:
    errors.append("claim_boundary is missing required bounded language for Phase 58 defer")

checkpoints = checkpoint.get("checkpoints")
if not isinstance(checkpoints, list):
    errors.append("checkpoints must be an array")
    checkpoints = []

checkpoint_count = checkpoint.get("checkpoint_count")
if not isinstance(checkpoint_count, int):
    errors.append("checkpoint_count must be an integer")
    checkpoint_count = 0

if checkpoint_count != len(checkpoints):
    errors.append(
        f"checkpoint_count ({checkpoint_count}) must equal len(checkpoints) ({len(checkpoints)})"
    )

stages = []
for index, row in enumerate(checkpoints):
    if not isinstance(row, dict):
        errors.append(f"checkpoints[{index}] must be an object")
        continue

    stage = row.get("stage")
    status = row.get("status")
    fixture_id = row.get("fixture_id")

    if not isinstance(stage, str) or stage.strip() == "":
        errors.append(f"checkpoints[{index}].stage must be a non-empty string")
    else:
        stages.append(stage)

    if not isinstance(status, str) or status.strip() == "":
        errors.append(f"checkpoints[{index}].status must be a non-empty string")

    if not isinstance(fixture_id, str) or fixture_id.strip() == "":
        errors.append(f"checkpoints[{index}].fixture_id must be a non-empty string")

if stages != required_stages:
    errors.append(f"stage order mismatch: expected {required_stages}, got {stages}")

if sorted(stages) != sorted(required_stages):
    errors.append(f"stage set mismatch: expected {required_stages}, got {stages}")

hash_rows = []
for row in checkpoints:
    if not isinstance(row, dict):
        continue

    stage = row.get("stage")
    status = row.get("status")
    fixture_id = row.get("fixture_id")

    if isinstance(stage, str) and isinstance(status, str) and isinstance(fixture_id, str):
        hash_rows.append(f"{stage}|{status}|{fixture_id}")

computed_sha = hashlib.sha256("\n".join(hash_rows).encode()).hexdigest()
if checkpoint.get("checkpoint_sha256") != computed_sha:
    errors.append(
        "checkpoint_sha256 mismatch: expected deterministic SHA from ordered checkpoint rows"
    )

if errors:
    for error in errors:
        print(f"[trust-runner-checkpoint] FAIL: {error}", file=sys.stderr)
    sys.exit(1)

print("[trust-runner-checkpoint] OK: deterministic trust checkpoint contract verified")
print(f"[trust-runner-checkpoint] schema_version={expected_schema}")
print(f"[trust-runner-checkpoint] checkpoint_count={checkpoint_count}")
print(f"[trust-runner-checkpoint] stages={stages}")
PY
