#!/usr/bin/env bash
set -euo pipefail

# CI Green is a protected aggregate. Its inputs are deliberately passed as
# explicit values rather than inferred from skipped leaves, because a skip can
# otherwise hide a failed or absent change-classification job.
if [ "$#" -lt 2 ]; then
  echo "CI Green blocked: policy requires detector result and code output" >&2
  exit 1
fi

detector_result="$1"
code_output="$2"
shift 2

if [ "$detector_result" != "success" ]; then
  echo "CI Green blocked: change detector result must be success (got ${detector_result:-'(missing)'})" >&2
  exit 1
fi

if [ "$code_output" != "true" ] && [ "$code_output" != "false" ]; then
  echo "CI Green blocked: change detector code output must be exactly true or false (got ${code_output:-'(missing)'})" >&2
  exit 1
fi

if [ "$#" -eq 0 ]; then
  echo "CI Green blocked: no required lane results were supplied" >&2
  exit 1
fi

seen_lanes=()
blocked_results=()

policy_lane_ids() {
  local key="$1"

  elixir -e '
    {policy, _binding} = Code.eval_file("config/quality/ci_policy.exs")
    lanes =
      case System.argv() do
        ["active_required"] -> policy.active_required
        ["advisory"] -> policy.advisory
      end

    IO.puts(Enum.join(lanes, "\n"))
  ' "$key"
}

while IFS= read -r lane; do
  active_required_lanes+=("$lane")
done < <(policy_lane_ids active_required)

while IFS= read -r lane; do
  advisory_lanes+=("$lane")
done < <(policy_lane_ids advisory)

if [ "${#active_required_lanes[@]}" -eq 0 ] || [ "${#advisory_lanes[@]}" -eq 0 ]; then
  echo "CI Green blocked: policy manifest produced an empty required or advisory lane set" >&2
  exit 1
fi

contains_lane() {
  local candidate="$1"
  local entry
  shift

  for entry in "$@"; do
    [ "$entry" = "$candidate" ] && return 0
  done

  return 1
}

for lane_input in "$@"; do
  if [[ "$lane_input" != *=* ]]; then
    echo "CI Green blocked: malformed required lane input: $lane_input" >&2
    exit 1
  fi

  lane="${lane_input%%=*}"
  result="${lane_input#*=}"

  if [[ ! "$lane" =~ ^[a-z_][a-z0-9_]*$ ]] || [[ "$result" == *"="* ]]; then
    echo "CI Green blocked: malformed required lane input: $lane_input" >&2
    exit 1
  fi

  if contains_lane "$lane" "${advisory_lanes[@]}"; then
    echo "CI Green blocked: advisory lane cannot be supplied as required evidence: $lane" >&2
    exit 1
  fi

  if ! contains_lane "$lane" "${active_required_lanes[@]}"; then
    echo "CI Green blocked: unknown required lane input: $lane" >&2
    exit 1
  fi

  for seen_lane in "${seen_lanes[@]-}"; do
    if [ "$seen_lane" = "$lane" ]; then
      echo "CI Green blocked: duplicate required lane input: $lane" >&2
      exit 1
    fi
  done
  seen_lanes+=("$lane")

  if [ -z "$result" ]; then
    blocked_results+=("$lane=(missing)")
  elif [ "$code_output" = "true" ] && [ "$result" != "success" ]; then
    blocked_results+=("$lane=$result")
  elif [ "$code_output" = "false" ] && [ "$result" != "success" ] && [ "$result" != "skipped" ]; then
    blocked_results+=("$lane=$result")
  fi
done

for required_lane in "${active_required_lanes[@]}"; do
  if ! contains_lane "$required_lane" "${seen_lanes[@]}"; then
    blocked_results+=("$required_lane=(missing)")
  fi
done

if [ "${#blocked_results[@]}" -gt 0 ]; then
  echo "CI Green blocked: unacceptable required lane result(s): ${blocked_results[*]}" >&2
  exit 1
fi
