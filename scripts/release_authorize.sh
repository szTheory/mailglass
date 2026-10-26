#!/usr/bin/env bash
# Turn a proposal-only release-please run's captured candidate into the
# authorized release ledger, the way PR #311 was built by hand.
#
#   scripts/release_authorize.sh <run-id> [--target PATH] [--pr]
#
# 1. Reads run <run-id> (must be a successful release-please.yml run) and
#    downloads its `release-proposal-candidate-<run-id>` artifact.
# 2. Writes the ledger from it: status=authorized, candidate_versions,
#    proposal_identity, publishable_content.digest, states.capture=captured,
#    states.authorization=authorized. Nothing else changes. The ledger must be
#    `inactive` first.
# 3. Validates the written ledger with release_policy_validate_target.sh
#    (against a worktree at the proposal head), `validate-candidate` and
#    `validate-authorization`, and only then moves it into place.
# 4. Prints the CANDIDATE digest from validate-candidate. That digest is what
#    the protected release-please/publish-hex dispatches take; the publishable
#    content digest in the ledger does NOT authorize anything.
#
# Without --pr it only writes the ledger file (default
# .planning/release-target.json) and never commits or pushes. With --pr it
# writes the ledger in a temporary worktree of origin/main, commits only that
# file on a new branch, pushes it, and opens the reviewed authorization PR.
# Either way the ledger change is its own reviewed PR; this script cannot merge,
# tag, or publish.
set -euo pipefail

repository=szTheory/mailglass
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  echo "usage: scripts/release_authorize.sh <run-id> [--target PATH] [--pr]" >&2
  exit 2
}

run_id=""
target=""
open_pr=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr) open_pr=true ;;
    --target)
      [[ $# -ge 2 ]] || usage
      target=$2
      shift
      ;;
    -h | --help) usage ;;
    -*) usage ;;
    *)
      [[ -z "$run_id" ]] || usage
      run_id=$1
      ;;
  esac
  shift
done

[[ -n "$run_id" ]] || usage
[[ "$run_id" =~ ^[1-9][0-9]*$ ]] || fail "run id must be a positive integer, got '$run_id'"
[[ "$open_pr" != true || -z "$target" ]] || fail "--pr writes the ledger on a fresh branch of origin/main; do not combine it with --target"

for tool in gh git jq mix; do
  command -v "$tool" >/dev/null 2>&1 || fail "$tool is required"
done

work=$(mktemp -d)
head_worktree=""
pr_worktree=""
cleanup() {
  if [[ -n "$head_worktree" ]]; then
    git -C "$repo_root" worktree remove --force "$head_worktree" >/dev/null 2>&1 || true
  fi
  if [[ -n "$pr_worktree" ]]; then
    git -C "$repo_root" worktree remove --force "$pr_worktree" >/dev/null 2>&1 || true
  fi
  rm -rf "$work"
}
trap cleanup EXIT

policy() {
  (
    cd "$repo_root"
    mix run --no-start --no-compile --no-deps-check \
      --require scripts/release_policy.exs \
      -e 'Mailglass.ReleasePolicy.cli(System.argv())' -- "$@"
  )
}

# --- 1. The run and its candidate artifact ---------------------------------
run_json=$(gh api "repos/${repository}/actions/runs/${run_id}") ||
  fail "could not read run ${run_id}"
jq -e '.path == ".github/workflows/release-please.yml" and .status == "completed" and .conclusion == "success"' \
  <<<"$run_json" >/dev/null ||
  fail "run ${run_id} is not a successful completed release-please.yml run"

artifact="release-proposal-candidate-${run_id}"
gh run download "$run_id" -R "$repository" -n "$artifact" -D "$work/artifact" >/dev/null ||
  fail "could not download artifact ${artifact} from run ${run_id}"
candidate="$work/artifact/proposal-candidate.json"
[[ -f "$candidate" ]] || fail "artifact ${artifact} has no proposal-candidate.json"

# Shape check before any value reaches the ledger. The policy re-checks all of
# this; failing here keeps a malformed artifact out of the ledger file at all.
jq -e '
  (keys == ["candidate_versions", "proposal_identity", "publishable_content"]) and
  (.candidate_versions | keys == ["mailglass", "mailglass_admin", "mailglass_inbound"]) and
  all(.candidate_versions[]; type == "string" and test("^[0-9]+\\.[0-9]+\\.[0-9]+$")) and
  (.proposal_identity | keys == ["head_sha", "source_sha"]) and
  all(.proposal_identity[]; type == "string" and test("^[0-9a-f]{40}$")) and
  (.publishable_content | keys == ["algorithm", "digest", "excludes"]) and
  (.publishable_content.digest | type == "string" and test("^[0-9a-f]{64}$"))' \
  "$candidate" >/dev/null ||
  fail "artifact ${artifact} is not a well-formed proposal candidate"

core=$(jq -er '.candidate_versions.mailglass' "$candidate")
admin=$(jq -er '.candidate_versions.mailglass_admin' "$candidate")
inbound=$(jq -er '.candidate_versions.mailglass_inbound' "$candidate")
head_sha=$(jq -er '.proposal_identity.head_sha' "$candidate")
source_sha=$(jq -er '.proposal_identity.source_sha' "$candidate")
content_digest=$(jq -er '.publishable_content.digest' "$candidate")

# --- 2. Where the ledger is written -------------------------------------------
if [[ "$open_pr" == true ]]; then
  git -C "$repo_root" fetch --no-tags origin main >/dev/null 2>&1 ||
    fail "could not fetch origin main"
  pr_worktree="$work/main"
  git -C "$repo_root" worktree add --detach "$pr_worktree" origin/main >/dev/null 2>&1 ||
    fail "could not create a worktree of origin/main"
  target="$pr_worktree/.planning/release-target.json"
elif [[ -z "$target" ]]; then
  target="$repo_root/.planning/release-target.json"
  if [[ -n "$(git -C "$repo_root" status --porcelain -- .planning/release-target.json)" ]]; then
    fail ".planning/release-target.json has uncommitted changes; refusing to overwrite them"
  fi
fi
[[ -f "$target" ]] || fail "release target not found: $target"

jq -e '.status == "inactive" and .states.capture == "inactive" and .states.authorization == "unauthorized"' \
  "$target" >/dev/null ||
  fail "the release ledger is not inactive (status=$(jq -r '.status' "$target")); close out the previous release first"

authorized="$work/release-target.json"
jq --slurpfile c "$candidate" '
  .status = "authorized"
  | .candidate_versions = $c[0].candidate_versions
  | .proposal_identity = $c[0].proposal_identity
  | .publishable_content.digest = $c[0].publishable_content.digest
  | .states.capture = "captured"
  | .states.authorization = "authorized"' \
  "$target" >"$authorized"

# --- 3. Validate before the ledger moves into place ---------------------------
git -C "$repo_root" fetch --no-tags origin "$head_sha" >/dev/null 2>&1 ||
  fail "could not fetch proposal head $head_sha"
head_worktree="$work/head"
git -C "$repo_root" worktree add --detach "$head_worktree" "$head_sha" >/dev/null 2>&1 ||
  fail "could not create a worktree at proposal head $head_sha"

target_output=$("$script_dir/release_policy_validate_target.sh" "$authorized" "mailglass-v${core}" "$head_worktree") ||
  fail "validate-target rejected the authorized ledger at proposal head $head_sha"

candidate_output=$(policy validate-candidate "$authorized" "$candidate") ||
  fail "validate-candidate rejected the authorized ledger"
[[ "$candidate_output" == *"candidate_valid=true"* ]] ||
  fail "validate-candidate did not confirm the candidate"
candidate_digest=$(sed -n 's/^candidate_digest=\([0-9a-f]\{64\}\)$/\1/p' <<<"$candidate_output")
[[ "$candidate_digest" =~ ^[0-9a-f]{64}$ ]] ||
  fail "validate-candidate did not report a candidate digest"

authorization_output=$(policy validate-authorization "$authorized" "$candidate_digest") ||
  fail "validate-authorization rejected candidate digest $candidate_digest"
[[ "$authorization_output" == *"authorized=true"* ]] ||
  fail "validate-authorization did not confirm the authorization"

cp "$authorized" "$target"

summary="versions        mailglass ${core}, mailglass_admin ${admin}, mailglass_inbound ${inbound}
proposal head   ${head_sha}
source sha      ${source_sha}
content digest  ${content_digest}
validate-target ${target_output//$'\n'/ }"

echo "Wrote the authorized ledger: $target"
echo "$summary"
echo
echo "CANDIDATE DIGEST (pass this to the protected dispatches): ${candidate_digest}"

# --- 4. Optional reviewed PR --------------------------------------------------
if [[ "$open_pr" == true ]]; then
  branch="chore/authorize-release-${core}"
  title="chore(release): authorize the ${core}/${admin}/${inbound} release candidate"
  git -C "$pr_worktree" switch -c "$branch" >/dev/null
  git -C "$pr_worktree" add .planning/release-target.json
  git -C "$pr_worktree" commit -q -F - <<EOF
${title}

Records the candidate captured by the proposal-only release-please run
${run_id} into the fail-closed release authorization ledger, written by
scripts/release_authorize.sh from that run's proposal-candidate artifact.

${summary}
validate-candidate => candidate_valid=true
validate-authorization (candidate digest ${candidate_digest}) => authorized=true

Baselines, Hex evidence identifiers and final_identity are untouched. This
commit only authorizes; it cannot publish.
EOF
  git -C "$pr_worktree" push -u origin "$branch" >/dev/null
  gh pr create -R "$repository" --base main --head "$branch" --title "$title" \
    --body "Authorizes the candidate from release-please run https://github.com/${repository}/actions/runs/${run_id}.

\`\`\`
${summary}
\`\`\`

Candidate digest for the protected dispatches: \`${candidate_digest}\`"
fi
