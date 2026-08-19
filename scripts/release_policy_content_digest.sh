#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: release_policy_content_digest.sh [--repo PATH] [--ref TREEISH]

Print the SHA-256 digest of the tracked files shipped by the mailglass,
mailglass_admin, and mailglass_inbound Hex packages.
EOF
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)
treeish=HEAD

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      [ "$#" -ge 2 ] || { usage; exit 64; }
      repo_root=$2
      shift 2
      ;;
    --ref)
      [ "$#" -ge 2 ] || { usage; exit 64; }
      treeish=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 64
      ;;
  esac
done

git -C "$repo_root" rev-parse --verify --quiet "${treeish}^{tree}" >/dev/null || {
  echo "ERROR: release content tree is unavailable: $treeish" >&2
  exit 1
}

# These required roots keep an accidental invocation in an unrelated/incomplete
# repository from producing a plausible digest.
for required in mix.exs mailglass_admin/mix.exs mailglass_inbound/mix.exs; do
  git -C "$repo_root" cat-file -e "${treeish}:${required}" 2>/dev/null || {
    echo "ERROR: required package file is missing from $treeish: $required" >&2
    exit 1
  }
done

entries=$(mktemp)
trap 'rm -f "$entries"' EXIT

# Keep this allowlist aligned with package.files in the three Mix projects.
# Hash Git tree entries (mode, object id, and path), not the mutable worktree:
# callers can therefore compare proposal, source, main, merged, and tag trees
# through the same interface without staging or checking them out.
while IFS= read -r -d '' entry; do
  path=${entry#*$'\t'}

  case "$path" in
    # mailglass: mix.exs package files
    lib/*|priv/gettext/*|guides/*|mix.exs|LICENSE|README.md|CHANGELOG.md|MAINTAINING.md|CONTRIBUTING.md|SECURITY.md|CODE_OF_CONDUCT.md)
      printf '%s\0' "$entry" >>"$entries"
      ;;

    # mailglass_admin: paths are rooted below mailglass_admin/ in this monorepo
    mailglass_admin/lib/*|mailglass_admin/priv/static/*|mailglass_admin/docs/*|mailglass_admin/.formatter.exs|mailglass_admin/mix.exs|mailglass_admin/README*|mailglass_admin/CHANGELOG*|mailglass_admin/LICENSE*)
      printf '%s\0' "$entry" >>"$entries"
      ;;

    # mailglass_inbound: paths are rooted below mailglass_inbound/ in this monorepo
    mailglass_inbound/lib/*|mailglass_inbound/docs/*|mailglass_inbound/.formatter.exs|mailglass_inbound/mix.exs|mailglass_inbound/README*|mailglass_inbound/CHANGELOG*|mailglass_inbound/LICENSE*)
      printf '%s\0' "$entry" >>"$entries"
      ;;
  esac
done < <(git -C "$repo_root" ls-tree -r -z "$treeish")

[ -s "$entries" ] || {
  echo "ERROR: release content allowlist selected no tracked files" >&2
  exit 1
}

if command -v shasum >/dev/null 2>&1; then
  LC_ALL=C sort -z "$entries" | shasum -a 256 | awk '{print $1}'
elif command -v sha256sum >/dev/null 2>&1; then
  LC_ALL=C sort -z "$entries" | sha256sum | awk '{print $1}'
else
  echo "ERROR: no SHA-256 implementation found (shasum or sha256sum)" >&2
  exit 1
fi
