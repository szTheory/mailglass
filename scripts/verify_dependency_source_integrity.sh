#!/usr/bin/env bash
set -euo pipefail

required_yamerl_headers=(
  deps/yamerl/include/yamerl_tokens.hrl
  deps/yamerl/include/yamerl_nodes.hrl
  deps/yamerl/include/internal/yamerl_constr.hrl
)

repair_required=false
for header in "${required_yamerl_headers[@]}"; do
  if [[ ! -f "$header" ]]; then
    repair_required=true
  fi
done

if [[ "$repair_required" == true ]]; then
  yamerl_version=$(mix deps | awk '$1 == "*" && $2 == "yamerl" { print $3; exit }')
  if [[ -z "$yamerl_version" ]]; then
    echo "Unable to resolve locked yamerl version for source repair" >&2
    exit 1
  fi

  echo "Root yamerl source is incomplete; restoring Hex package ${yamerl_version}"
  mix deps.clean yamerl
  mix hex.package fetch yamerl "$yamerl_version" --unpack --output deps/yamerl
fi

for header in "${required_yamerl_headers[@]}"; do
  test -f "$header"
done
