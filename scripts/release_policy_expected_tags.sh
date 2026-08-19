#!/usr/bin/env bash
set -euo pipefail

manifest=${1:?usage: release_policy_expected_tags.sh MANIFEST [TARGET]}
target=${2:-}

if [ ! -r "$manifest" ]; then
  echo "ERROR: release manifest is missing or unreadable: $manifest" >&2
  exit 1
fi

if [ -n "$target" ] && [ -r "$target" ] && [ "$(jq -r '.status // ""' "$target")" = "active" ]; then
  jq -er '
    . as $target
    | if (.release_packages | type) != "array" or (.release_packages | length) == 0 then
        error("active release target must declare release_packages")
      elif any(.release_packages[]; type != "string" or length == 0 or ($target.packages[.] | type) != "string") then
        error("active release target has an invalid release package")
      else
        .release_packages[] as $package
        | .packages[$package] as $version
        | if $package == "mailglass" then "mailglass-v\($version)" else "\($package)-v\($version)" end
      end
  ' "$target"
else
  jq -er '
    if type != "object" or length == 0 or any(.[]; type != "string" or length == 0) then
      error("release manifest must be a non-empty object of version strings")
    else
      to_entries[]
      | .key as $package
      | .value as $version
      | if $package == "." then "mailglass-v\($version)" else "\($package)-v\($version)" end
    end
  ' "$manifest"
fi
