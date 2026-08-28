#!/usr/bin/env bash
# Bind, validate, and collect truthful scheduled-control evidence.

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
config_path="${SCHEDULED_CONTROL_CONFIG:-$repo_root/.github/scheduled-controls.json}"

usage() {
  cat >&2 <<'USAGE'
usage:
  scheduled_control_evidence.sh bind --control ID --artifact PATH
  scheduled_control_evidence.sh verify-file --control ID --artifact PATH --run-json PATH --output PATH
  scheduled_control_evidence.sh verify-run --run-id ID --output PATH
  scheduled_control_evidence.sh sweep --output PATH
USAGE
  exit 2
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

control_json() {
  local control="$1"
  jq -cer --arg control "$control" '.controls[] | select(.id == $control)' "$config_path"
}

control_for_workflow() {
  local workflow_name="$1"
  jq -cer --arg workflow_name "$workflow_name" \
    '.controls[] | select(.workflow_name == $workflow_name)' "$config_path"
}

render_summary() {
  local artifact="$1" digest="$2"

  jq -r --arg digest "$digest" '
    "## Scheduled control evidence\n\n" +
    "- control: `\(.control)`\n" +
    "- status: `\(.status)`\n" +
    "- reason: `\(.reason)`\n" +
    "- event: `\(.event_name)`\n" +
    "- run: `\(.run_id)`\n" +
    "- workflow-sha: `\(.workflow_sha)`\n" +
    "- head-sha: `\(.head_sha)`\n" +
    "- payload-sha256: `\($digest)`\n" +
    (if ((.probes // .checks // []) | length) > 0 then
      "\n### Evidence details\n" +
      ((.probes // .checks) |
        map((.source // .message // "") as $detail | "- \(.status) `\(.name)`: \($detail)") |
        join("\n")) + "\n"
    else "" end)
  ' "$artifact"
}

bind_artifact() {
  local control="$1" artifact="$2"
  local event_name="${GITHUB_EVENT_NAME:-}" run_id="${GITHUB_RUN_ID:-}"
  local workflow_sha="${GITHUB_WORKFLOW_SHA:-}" head_sha="${GITHUB_SHA:-}"
  local evidence_schema temporary bind_failed=false

  control_json "$control" >/dev/null
  evidence_schema=$(jq -er '.evidence_schema' "$config_path")

  [[ "$run_id" =~ ^[0-9]+$ ]] || { echo "Invalid GITHUB_RUN_ID: $run_id" >&2; exit 1; }
  [[ "$workflow_sha" =~ ^[0-9a-f]{40}$ ]] || { echo "Invalid GITHUB_WORKFLOW_SHA: $workflow_sha" >&2; exit 1; }
  [[ "$head_sha" =~ ^[0-9a-f]{40}$ ]] || { echo "Invalid GITHUB_SHA: $head_sha" >&2; exit 1; }
  [ -n "$event_name" ] || { echo "GITHUB_EVENT_NAME is required" >&2; exit 1; }

  temporary=$(mktemp "${artifact}.XXXXXX")
  trap 'rm -f "$temporary"' RETURN

  if [ ! -s "$artifact" ]; then
    jq -n \
      --arg status "cannot-check" \
      --arg reason "source_result_missing" \
      '{status: $status, reason: $reason}' >"$temporary"
    bind_failed=true
  elif ! jq -e 'type == "object" and (.status | type == "string") and (.reason | type == "string")' "$artifact" >/dev/null 2>&1; then
    jq -n \
      --arg status "cannot-check" \
      --arg reason "source_result_invalid" \
      '{status: $status, reason: $reason}' >"$temporary"
    bind_failed=true
  else
    cp "$artifact" "$temporary"
  fi

  if ! jq -e '.status == "pass" or .status == "blocked" or .status == "cannot-check" or .status == "pending"' "$temporary" >/dev/null; then
    jq -n \
      --arg status "cannot-check" \
      --arg reason "source_status_invalid" \
      '{status: $status, reason: $reason}' >"$temporary"
    bind_failed=true
  fi

  if ! jq -e --arg event_name "$event_name" --arg run_id "$run_id" '
      (.event_name == null or .event_name == $event_name) and
      (.run_id == null or (.run_id | tostring) == $run_id)
    ' "$temporary" >/dev/null; then
    jq -n \
      --arg status "cannot-check" \
      --arg reason "source_provenance_mismatch" \
      '{status: $status, reason: $reason}' >"$temporary"
    bind_failed=true
  fi

  jq \
    --arg schema "$evidence_schema" \
    --arg control "$control" \
    --arg event_name "$event_name" \
    --arg run_id "$run_id" \
    --arg workflow_sha "$workflow_sha" \
    --arg head_sha "$head_sha" \
    '. + {
      evidence_schema: $schema,
      control: $control,
      event_name: $event_name,
      run_id: $run_id,
      workflow_sha: $workflow_sha,
      head_sha: $head_sha
    }' "$temporary" >"${temporary}.bound"

  mv "${temporary}.bound" "$artifact"
  rm -f "$temporary"
  trap - RETURN

  payload_sha=$(sha256_file "$artifact")
  render_summary "$artifact" "$payload_sha"

  if [ "$bind_failed" = true ]; then
    return 1
  fi
}

verify_file() {
  local control="$1" artifact="$2" run_json="$3" output="$4"
  local expected_schema run_id run_attempt run_event run_status run_name run_sha run_branch
  local artifact_sha verified_at

  control_json "$control" >/dev/null
  expected_schema=$(jq -er '.evidence_schema' "$config_path")
  run_id=$(jq -er '.id | tostring' "$run_json")
  run_attempt=$(jq -er '.run_attempt' "$run_json")
  run_event=$(jq -er '.event' "$run_json")
  run_status=$(jq -er '.status' "$run_json")
  run_name=$(jq -er '.name' "$run_json")
  run_sha=$(jq -er '.head_sha' "$run_json")
  run_branch=$(jq -er '.head_branch' "$run_json")

  [ "$run_event" = "schedule" ] || { echo "Run $run_id is not schedule evidence." >&2; return 1; }
  [ "$run_attempt" -eq 1 ] 2>/dev/null || { echo "Run $run_id is not attempt 1." >&2; return 1; }
  [ "$run_status" = "completed" ] || { echo "Run $run_id is not completed." >&2; return 1; }
  [ "$run_branch" = "main" ] || { echo "Run $run_id is not from main." >&2; return 1; }
  [[ "$run_sha" =~ ^[0-9a-f]{40}$ ]] || { echo "Run $run_id has an invalid head SHA." >&2; return 1; }
  [ "$(control_for_workflow "$run_name" | jq -r '.id')" = "$control" ] || {
    echo "Run $run_id workflow does not match control $control." >&2
    return 1
  }

  jq -e \
    --arg schema "$expected_schema" \
    --arg control "$control" \
    --arg run_id "$run_id" \
    --arg run_sha "$run_sha" '
      type == "object" and
      .evidence_schema == $schema and
      .control == $control and
      .event_name == "schedule" and
      (.run_id | tostring) == $run_id and
      .workflow_sha == $run_sha and
      .head_sha == $run_sha and
      (.status == "pass" or .status == "blocked" or .status == "cannot-check" or .status == "pending") and
      (.reason | type == "string") and
      (.reason | length > 0)
    ' "$artifact" >/dev/null || {
      echo "Run $run_id artifact failed the scheduled-control envelope." >&2
      return 1
    }

  artifact_sha=$(sha256_file "$artifact")
  verified_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  jq -n \
    --arg schema "$(jq -er '.verification_schema' "$config_path")" \
    --arg verified_at "$verified_at" \
    --arg control "$control" \
    --arg payload_sha256 "$artifact_sha" \
    --slurpfile run "$run_json" \
    --slurpfile artifact "$artifact" '
      {
        schema: $schema,
        kind: "run",
        verified_at: $verified_at,
        evidence_valid: true,
        control: $control,
        source_run: {
          id: ($run[0].id | tostring),
          attempt: $run[0].run_attempt,
          name: $run[0].name,
          event: $run[0].event,
          status: $run[0].status,
          conclusion: $run[0].conclusion,
          head_branch: $run[0].head_branch,
          head_sha: $run[0].head_sha,
          html_url: $run[0].html_url,
          updated_at: $run[0].updated_at
        },
        result: {
          status: $artifact[0].status,
          reason: $artifact[0].reason,
          workflow_sha: $artifact[0].workflow_sha,
          payload_sha256: $payload_sha256
        }
      }
    ' >"$output"
}

download_run_evidence() {
  local run_id="$1" output="$2"
  local temporary run_json workflow_name control artifact_name artifact_file
  local artifacts_json artifact_id artifact_digest artifact_count archive_sha logs_zip payload_sha

  [[ "$run_id" =~ ^[0-9]+$ ]] || { echo "Invalid run ID: $run_id" >&2; return 1; }
  [ -n "${GITHUB_REPOSITORY:-}" ] || { echo "GITHUB_REPOSITORY is required" >&2; return 1; }

  temporary=$(mktemp -d)
  trap 'rm -rf "$temporary"' RETURN
  run_json="$temporary/run.json"

  gh api "repos/$GITHUB_REPOSITORY/actions/runs/$run_id" >"$run_json"
  workflow_name=$(jq -er '.name' "$run_json")
  control=$(control_for_workflow "$workflow_name")
  artifact_name=$(jq -r --arg run_id "$run_id" '.artifact_name | gsub("\\{run_id\\}"; $run_id)' <<<"$control")
  artifact_file=$(jq -r '.artifact_file' <<<"$control")
  artifacts_json="$temporary/artifacts.json"

  gh api "repos/$GITHUB_REPOSITORY/actions/runs/$run_id/artifacts?per_page=100" >"$artifacts_json"
  artifact_count=$(jq --arg name "$artifact_name" '[.artifacts[] | select(.name == $name and .expired == false)] | length' "$artifacts_json")
  [ "$artifact_count" -eq 1 ] || {
    echo "Run $run_id must retain exactly one unexpired artifact named $artifact_name." >&2
    return 1
  }

  artifact_id=$(jq -er --arg name "$artifact_name" '.artifacts[] | select(.name == $name and .expired == false) | .id' "$artifacts_json")
  artifact_digest=$(jq -er --arg name "$artifact_name" '.artifacts[] | select(.name == $name and .expired == false) | .digest' "$artifacts_json")
  gh api "repos/$GITHUB_REPOSITORY/actions/artifacts/$artifact_id/zip" >"$temporary/artifact.zip"
  [ "$(wc -c <"$temporary/artifact.zip")" -le 1048576 ] || { echo "Run $run_id artifact archive is too large." >&2; return 1; }
  archive_sha=$(sha256_file "$temporary/artifact.zip")
  [ "$artifact_digest" = "sha256:$archive_sha" ] || {
    echo "Run $run_id artifact archive digest does not match the GitHub API." >&2
    return 1
  }

  [ "$(unzip -Z1 "$temporary/artifact.zip" | wc -l | tr -d ' ')" -eq 1 ] || {
    echo "Run $run_id artifact archive has an unexpected shape." >&2
    return 1
  }
  [ "$(unzip -Z1 "$temporary/artifact.zip")" = "$artifact_file" ] || {
    echo "Run $run_id artifact archive does not contain $artifact_file." >&2
    return 1
  }

  unzip -p "$temporary/artifact.zip" "$artifact_file" >"$temporary/$artifact_file"
  verify_file "$(jq -r '.id' <<<"$control")" "$temporary/$artifact_file" "$run_json" "$output"

  payload_sha=$(jq -er '.result.payload_sha256' "$output")
  logs_zip="$temporary/logs.zip"
  gh api "repos/$GITHUB_REPOSITORY/actions/runs/$run_id/logs" >"$logs_zip"
  unzip -p "$logs_zip" | grep -F "payload-sha256: \`$payload_sha\`" >/dev/null || {
    echo "Run $run_id logs do not contain the retained payload digest." >&2
    return 1
  }

  jq --arg artifact_archive_digest "$artifact_digest" \
    '.result.artifact_archive_digest = $artifact_archive_digest' "$output" >"$temporary/report.json"
  mv "$temporary/report.json" "$output"
  rm -rf "$temporary"
  trap - RETURN
}

sweep_controls() {
  local output="$1" temporary control control_id workflow_file run_id max_age report run_json updated_at
  local expected_main_sha observed_head_sha
  temporary=$(mktemp -d)
  trap 'rm -rf "$temporary"' RETURN

  expected_main_sha=$(gh api "repos/$GITHUB_REPOSITORY/git/ref/heads/main" --jq '.object.sha')
  [[ "$expected_main_sha" =~ ^[0-9a-f]{40}$ ]] || {
    echo "Protected main has an invalid SHA: $expected_main_sha" >&2
    return 1
  }

  while IFS= read -r control; do
    workflow_file=$(jq -r '.workflow_file' <<<"$control")
    control_id=$(jq -r '.id' <<<"$control")
    max_age=$(jq -r '.max_age_seconds' <<<"$control")
    run_id=$(gh api "repos/$GITHUB_REPOSITORY/actions/workflows/$workflow_file/runs?event=schedule&per_page=1" --jq '.workflow_runs[0].id')
    [[ "$run_id" =~ ^[0-9]+$ ]] || { echo "No scheduled run found for $workflow_file." >&2; return 1; }
    report="$temporary/$control_id.json"
    run_json="$temporary/$control_id-run.json"
    gh api "repos/$GITHUB_REPOSITORY/actions/runs/$run_id" >"$run_json"
    observed_head_sha=$(jq -er '.head_sha' "$run_json")

    if [ "$observed_head_sha" != "$expected_main_sha" ]; then
      jq -n \
        --arg schema "$(jq -er '.verification_schema' "$config_path")" \
        --arg control "$control_id" \
        --arg expected_main_sha "$expected_main_sha" \
        --slurpfile run "$run_json" '
          {
            schema: $schema,
            kind: "run",
            verified_at: (now | todateiso8601),
            evidence_valid: false,
            control: $control,
            expected_main_sha: $expected_main_sha,
            source_run: {
              id: ($run[0].id | tostring),
              attempt: $run[0].run_attempt,
              name: $run[0].name,
              event: $run[0].event,
              status: $run[0].status,
              conclusion: $run[0].conclusion,
              head_branch: $run[0].head_branch,
              head_sha: $run[0].head_sha,
              html_url: $run[0].html_url,
              updated_at: $run[0].updated_at
            },
            result: {
              status: "pending",
              reason: "awaiting_current_main_schedule",
              workflow_sha: $run[0].head_sha
            }
          }
        ' >"$report"
      rm -f "$run_json"
      continue
    fi

    download_run_evidence "$run_id" "$report"
    rm -f "$run_json"
    updated_at=$(jq -er '.source_run.updated_at' "$report")
    jq -ne --arg updated_at "$updated_at" --argjson max_age "$max_age" \
      '(now - ($updated_at | fromdateiso8601)) <= $max_age' >/dev/null || {
      echo "Latest scheduled run for $workflow_file is stale." >&2
      return 1
    }
  done < <(jq -c '.controls[]' "$config_path")

  jq -s \
    --arg schema "$(jq -er '.verification_schema' "$config_path")" \
    --arg expected_main_sha "$expected_main_sha" \
    '(. | all(.evidence_valid == true)) as $valid |
      {
        schema: $schema,
        kind: "sweep",
        status: (if $valid then "pass" else "pending" end),
        reason: (if $valid then "all_controls_current" else "awaiting_current_main_schedule" end),
        evidence_valid: $valid,
        expected_main_sha: $expected_main_sha,
        controls: .
      }' \
    "$temporary"/*.json >"$output"
  rm -rf "$temporary"
  trap - RETURN

  if ! jq -e '.status == "pass"' "$output" >/dev/null; then
    jq -r '.reason' "$output" >&2
    return 1
  fi
}

command="${1:-}"
shift || true

control=""
artifact=""
run_json=""
run_id=""
output=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --control) control="${2:-}"; shift 2 ;;
    --artifact) artifact="${2:-}"; shift 2 ;;
    --run-json) run_json="${2:-}"; shift 2 ;;
    --run-id) run_id="${2:-}"; shift 2 ;;
    --output) output="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

case "$command" in
  bind)
    [ -n "$control" ] && [ -n "$artifact" ] || usage
    bind_artifact "$control" "$artifact"
    ;;
  verify-file)
    [ -n "$control" ] && [ -n "$artifact" ] && [ -n "$run_json" ] && [ -n "$output" ] || usage
    verify_file "$control" "$artifact" "$run_json" "$output"
    ;;
  verify-run)
    [ -n "$run_id" ] && [ -n "$output" ] || usage
    download_run_evidence "$run_id" "$output"
    ;;
  sweep)
    [ -n "$output" ] || usage
    sweep_controls "$output"
    ;;
  *) usage ;;
esac
