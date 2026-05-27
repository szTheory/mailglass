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
expected_boundary = "reference-host trust-journey confidence only; signed Postmark webhook verification and no-match operator diagnosis proven by deterministic runner evidence"
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
    errors.append("claim_boundary is missing required bounded Phase 58 evidence language")

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

rows_by_stage = {
    row.get("stage"): row
    for row in checkpoints
    if isinstance(row, dict) and isinstance(row.get("stage"), str)
}

forbidden_evidence_keys = {"raw_payload", "payload", "headers", "recipient", "sender", "subject", "html"}


def evidence_for(stage):
    row = rows_by_stage.get(stage, {})
    evidence = row.get("evidence")
    if not isinstance(evidence, dict):
        errors.append(f"{stage}.evidence must be an object")
        return {}
    return evidence


def validate_no_forbidden_evidence_keys(value, path):
    if isinstance(value, dict):
        for key, child in value.items():
            key_path = f"{path}.{key}"
            if key in forbidden_evidence_keys:
                errors.append(f"forbidden evidence key at {key_path}")
            validate_no_forbidden_evidence_keys(child, key_path)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            validate_no_forbidden_evidence_keys(child, f"{path}[{index}]")


webhook_evidence = evidence_for("webhook_ingest")
operator_evidence = evidence_for("operator_troubleshooting")

for stage_name, evidence in [
    ("webhook_ingest", webhook_evidence),
    ("operator_troubleshooting", operator_evidence),
]:
    validate_no_forbidden_evidence_keys(evidence, f"{stage_name}.evidence")

if webhook_evidence:
    if webhook_evidence.get("negative_status") != 401:
        errors.append("webhook_ingest.evidence.negative_status must be 401")
    if webhook_evidence.get("negative_reason") != "bad_credentials":
        errors.append("webhook_ingest.evidence.negative_reason must be 'bad_credentials'")
    if webhook_evidence.get("verified_before_tenant") is not True:
        errors.append("webhook_ingest.evidence.verified_before_tenant must be true")

if operator_evidence:
    expected_dimensions = ["recipient", "subject", "header:x-priority"]
    if operator_evidence.get("scenario") != "no_match":
        errors.append("operator_troubleshooting.evidence.scenario must be 'no_match'")
    if operator_evidence.get("outcome") != "no_match":
        errors.append("operator_troubleshooting.evidence.outcome must be 'no_match'")
    if operator_evidence.get("status_language") != "no matching mailbox route":
        errors.append(
            "operator_troubleshooting.evidence.status_language must be 'no matching mailbox route'"
        )
    if operator_evidence.get("raw_payload_included") is not False:
        errors.append("operator_troubleshooting.evidence.raw_payload_included must be false")
    if operator_evidence.get("private_recipient_included") is not False:
        errors.append("operator_troubleshooting.evidence.private_recipient_included must be false")
    if operator_evidence.get("recipient_masked") is not True:
        errors.append("operator_troubleshooting.evidence.recipient_masked must be true")
    if operator_evidence.get("route_clause_dimensions") != expected_dimensions:
        errors.append(
            "operator_troubleshooting.evidence.route_clause_dimensions must be "
            f"{expected_dimensions}"
        )
    if operator_evidence.get("trace_card_count") != 3:
        errors.append("operator_troubleshooting.evidence.trace_card_count must be 3")

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
# Hash identity is intentionally limited to stage|status|fixture_id.
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
