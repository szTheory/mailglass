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

if [ "${#blocked_results[@]}" -gt 0 ]; then
  echo "CI Green blocked: unacceptable required lane result(s): ${blocked_results[*]}" >&2
  exit 1
fi
