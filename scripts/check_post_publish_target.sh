#!/usr/bin/env bash
# Bind a post-publish proof to the authorized package content and all three
# policy-derived release tags. This script is executed from the trusted
# workflow control checkout, never from the caller-supplied target checkout.

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: check_post_publish_target.sh --repo PATH --target PATH --target-ref SHA --core VERSION --admin VERSION --inbound VERSION
EOF
}

repo=""
target=""
target_ref=""
core=""
admin=""
inbound=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) repo=${2:-}; shift 2 ;;
    --target) target=${2:-}; shift 2 ;;
    --target-ref) target_ref=${2:-}; shift 2 ;;
    --core) core=${2:-}; shift 2 ;;
    --admin) admin=${2:-}; shift 2 ;;
    --inbound) inbound=${2:-}; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 64 ;;
  esac
done

for value in "$repo" "$target" "$target_ref" "$core" "$admin" "$inbound"; do
  [ -n "$value" ] || { usage; exit 64; }
done

[[ "$target_ref" =~ ^[0-9a-f]{40}$ ]] || {
  echo "ERROR: target_ref must be an exact 40-character lowercase commit SHA" >&2
  exit 1
}

for version in "$core" "$admin" "$inbound"; do
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
    echo "ERROR: candidate version is not exact stable SemVer: $version" >&2
    exit 1
  }
done

[ "$core" = "$admin" ] || {
  echo "ERROR: linked core/admin versions diverge" >&2
  exit 1
}

repo=$(cd -- "$repo" && pwd)
[ -f "$target" ] || {
  echo "ERROR: validated release target is unavailable: $target" >&2
  exit 1
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
expected_tags=(
  "mailglass-v${core}"
  "mailglass_admin-v${admin}"
  "mailglass_inbound-v${inbound}"
)

for tag in "${expected_tags[@]}"; do
  git -C "$repo" update-ref -d "refs/tags/$tag" >/dev/null 2>&1 || true

  if ! git -C "$repo" fetch --force --no-tags origin "+refs/tags/$tag:refs/tags/$tag" >/dev/null 2>&1; then
    echo "ERROR: required tag is unavailable: $tag" >&2
    exit 1
  fi

  resolved=$(git -C "$repo" rev-parse "refs/tags/${tag}^{commit}" 2>/dev/null) || {
    echo "ERROR: required tag cannot be resolved to a commit: $tag" >&2
    exit 1
  }

  if [ "$resolved" != "$target_ref" ]; then
    echo "ERROR: required tag $tag does not resolve to target_ref $target_ref" >&2
    exit 1
  fi
done

if ! expected_digest=$(jq -er \
  '.publishable_content.digest | select(type == "string" and test("^[0-9a-f]{64}$"))' \
  "$target"); then
  echo "ERROR: authorized content digest is missing or malformed" >&2
  exit 1
fi

actual_digest=$("$script_dir/release_policy_content_digest.sh" --repo "$repo" --ref "$target_ref")

if [ "$actual_digest" != "$expected_digest" ]; then
  echo "ERROR: canonical package content digest mismatch for target_ref $target_ref" >&2
  exit 1
fi

echo "post-publish target verified: ref=$target_ref tags=3 content_digest=$actual_digest"
