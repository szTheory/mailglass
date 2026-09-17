#!/usr/bin/env bash
# Release-trigger guard: the decision logic, factored out so the workflow and
# the offline fixture test exercise the SAME code rather than two hand-synced
# copies of it.
#
# Two independent checks, both aimed at commits that reach release-please:
#
#   guard_decision       A bump-triggering type (feat/fix/any "!") whose diff is
#                        entirely non-shippable. release-please derives the bump
#                        from the commit TYPE alone and never inspects paths, so
#                        `feat:` on a docs-only change proposes a minor version.
#
#   guard_subject_hygiene
#                        A literal backslash-n in a commit subject, from
#                        `git commit -m "subject\n\n- bullet"` without $'...'
#                        or a heredoc. Renders as one unbroken line in the
#                        generated CHANGELOG that ships to Hex.
#
# Sourced as a library (`source scripts/guard_release_trigger.sh`) or run as a
# CLI (see the dispatch block at the bottom).
set -euo pipefail

# Path prefixes that are never part of a shippable change. brandbook/,
# .planning/ and prompts/ are repo-internal trees; the rest of the predicate
# below catches documentation that DOES ship inside a package.
GUARDED_PREFIXES=( "brandbook/" ".planning/" "prompts/" )

# ---------------------------------------------------------------------------
# Is this path non-shippable — i.e. changing it alone never justifies a version
# bump?
#
# Note the deliberate divergence from each package's `defp package` `files`
# allowlist in mix.exs. That allowlist is NOT usable as the "shippable" set
# here: it lists README*, CHANGELOG*, docs and guides, because those are
# published to Hex alongside the code. They ship, but changing one is still a
# docs change. #222 is exactly that case — a two-line edit to
# mailglass_inbound/README.md, inside the package and inside its allowlist,
# typed `feat:`, which proposed mailglass_inbound 2.3.0.
#
# So the classifier is by KIND, not by whether the file is published.
# ---------------------------------------------------------------------------
guard_path_is_non_shippable() {
  local f="$1"

  local g
  for g in "${GUARDED_PREFIXES[@]}"; do
    [[ "$f" == "$g"* ]] && return 0
  done

  # Any markdown, at any depth: READMEs, CHANGELOGs, guides, package docs.
  [[ "$f" == *.md ]] && return 0

  # Non-markdown assets living in a documentation tree (images in docs/,
  # sample output in guides/), at the repo root or inside any package.
  [[ "$f" == docs/* || "$f" == */docs/* ]] && return 0
  [[ "$f" == guides/* || "$f" == */guides/* ]] && return 0

  # Test trees. Every package's test tree now sits in its own exclude-paths
  # (root test/ for core since #263; mailglass_admin/test and
  # mailglass_inbound/test since #265), so config alone would stop a bump
  # today. This rule is kept deliberately, for two reasons. The exclusion is
  # per-package config that a future package can be added without, and a
  # `fix:` whose only content is tests is mistyped regardless of whether it
  # happens to bump anything — that commit is a `test:`. The guard classifies
  # by kind so it stays correct independently of how exclude-paths drift.
  [[ "$f" == test/* || "$f" == */test/* ]] && return 0

  return 1
}

# Note on what is deliberately absent: scripts/, .github/, ci/, dev/,
# reference/ and test_js/ are not classified here. They are non-shippable, but
# they sit in the core package's exclude-paths and outside both sibling
# packages' roots, so no commit type applied to them can produce a bump.
# Flagging them would fail commits that cannot cause the defect this guard
# exists to prevent.

# ---------------------------------------------------------------------------
# Extract the conventional-commit type and breaking-change bang from a subject.
# Echoes "type<TAB>bang"; returns 1 if the subject is not a conventional commit.
# ---------------------------------------------------------------------------
guard_parse_subject() {
  local subject="$1"

  if [[ "$subject" =~ ^([a-z]+)(\([^\)]*\))?(!)?: ]]; then
    printf '%s\t%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[3]}"
    return 0
  fi

  return 1
}

# ---------------------------------------------------------------------------
# Does this message body carry release-please's explicit release footer?
#
# `Release-As: x.y.z` is release-please's own native mechanism for declaring an
# intended release, so this is an escape hatch the tool already understands
# rather than one invented here.
#
# It exists because a deliberate docs-only release IS a legitimate act. 3edc95f0
# ("fix(publish): document tarball allowlist protocol and release 2.2.1") changed
# only MAINTAINING.md and was meant to cut 2.2.1. Without an override this guard
# would make that impossible, and a fail-closed release control with no declared
# way through is how releases get stranded — the failure mode that froze this
# repo's release-target ledger for four weeks.
#
# The footer makes intent explicit and auditable: the version is stated, in the
# commit, by whoever wanted it.
# ---------------------------------------------------------------------------
guard_body_declares_release() {
  local body="$1"
  [[ "$body" =~ (^|$'\n')[[:space:]]*Release-As:[[:space:]]*[0-9] ]]
}

# ---------------------------------------------------------------------------
# guard_decision <subject> <newline-delimited file list> [message body]
# Returns 0 (PASS) or 1 (FAIL — the guard fires).
# ---------------------------------------------------------------------------
guard_decision() {
  local subject="$1"
  local file_list="$2"
  local body="${3:-}"

  # 1. Parse the type. A non-conventional subject is pr-title.yml's failure to
  #    report on a PR, and is not something this guard can reason about on a
  #    direct push either — PASS rather than double-failing.
  local parsed type bang
  parsed="$(guard_parse_subject "$subject")" || return 0
  type="${parsed%%$'\t'*}"
  bang="${parsed##*$'\t'}"

  # 2. Is this a bump-triggering type?
  #    release-please defaults: feat -> minor, fix -> patch, any "!" -> major.
  #    The title-level breaking-change signal is the "!" marker. "BREAKING
  #    CHANGE:" is a commit-BODY footer, not a subject substring — matching it
  #    here would false-positive any subject merely mentioning the phrase
  #    (e.g. "docs: document our BREAKING CHANGE policy").
  local is_bump="false"
  case "$type" in
    feat|fix) is_bump="true" ;;
  esac
  [[ -n "$bang" ]] && is_bump="true"

  [[ "$is_bump" != "true" ]] && return 0

  # 2b. An explicit Release-As: footer means the release is intended on purpose.
  #     Honour it whatever the diff looks like.
  guard_body_declares_release "$body" && return 0

  # 3. Parse the file list. printf '%s' (not echo) so an empty string yields
  #    ZERO bytes -> a 0-element array, faithfully matching `gh pr view --json
  #    files --jq`, which emits nothing for an empty file set. `echo ""` would
  #    emit a lone newline -> a 1-element array of "", making the 0-element
  #    branch below unreachable and silently untested (WR-01).
  local -a files
  mapfile -t files < <(printf '%s' "$file_list")

  [[ "${#files[@]}" -eq 0 ]] && return 0

  # 4. Subset test: is EVERY changed file non-shippable?
  local f
  for f in "${files[@]}"; do
    guard_path_is_non_shippable "$f" || return 0
  done

  return 1
}

# ---------------------------------------------------------------------------
# guard_subject_hygiene <subject>
# Returns 0 (clean) or 1 (contains a literal backslash-n).
# ---------------------------------------------------------------------------
guard_subject_hygiene() {
  local subject="$1"
  [[ "$subject" == *'\n'* ]] && return 1
  return 0
}

# ---------------------------------------------------------------------------
# CLI dispatch. Only runs when executed directly, never when sourced.
#   guard_release_trigger.sh decision <subject> <file-list>
#   guard_release_trigger.sh hygiene  <subject>
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  case "${1:-}" in
    decision)
      if guard_decision "${2:-}" "${3:-}"; then
        echo "PASS"
      else
        echo "FAIL"
        exit 1
      fi
      ;;
    hygiene)
      if guard_subject_hygiene "${2:-}"; then
        echo "PASS"
      else
        echo "FAIL"
        exit 1
      fi
      ;;
    *)
      echo "usage: $0 {decision <subject> <file-list>|hygiene <subject>}" >&2
      exit 2
      ;;
  esac
fi
