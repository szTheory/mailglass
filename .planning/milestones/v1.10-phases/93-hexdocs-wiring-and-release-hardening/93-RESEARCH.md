# Phase 93: HexDocs Wiring and Release Hardening — Research

**Researched:** 2026-06-13
**Domain:** release-please monorepo path-scoping + CI commit-type linting; live-Hex version reconciliation
**Confidence:** HIGH (both open items resolved with authoritative sources)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (the ones this research is scoped by)
- **D-09:** RELH-01 hardened via an enforced CI commit-type lint that FAILS any PR whose commits touch ONLY `brandbook/`/`.planning/`/`prompts/` while using a bump-triggering type (`feat`/`fix`/`!`/`BREAKING CHANGE`). This is the PRIMARY, committed mechanism.
- **D-10:** Researcher confirms whether release-please offers a clean config-level path exclusion for the root `"."` package; adopt it IN ADDITION if it exists, but never block RELH-01 on it.
- **D-11:** RELH-02 — investigate Hex live FIRST, then reconcile. In-repo is internally consistent at 1.6.1/1.6.1/1.3.0; release-state memory claims 1.6.2/1.6.2/1.3.1; no local `mailglass-v1.6.x` package tags.
- **D-12:** Once truth established: disposition stale/unpublished 1.6.x tags, bump inbound exact-pin to the RELEASED core version via the `fix(inbound):` dance, correct `.planning` memory/docs.
- **D-13:** If the release train has NOT settled, record the blocker and stop short of guessing.

### Claude's Discretion
- Exact CI-lint form (new workflow vs. extend existing; shell vs. action).
- Tag-disposition method (delete vs. annotate-and-document), chosen once Hex truth known.

### Out of scope for this phase
- Cutting any Hex release (logo wiring rides next natural release — HexDocs latency locked).
- Re-deriving ex_doc logo/favicon mechanics (settled in ADOPTION-MECHANICS.md §1).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HEXD-01 | Wire `logo:`/`favicon:` in all three `docs/0`, add width/height to SVGs | Fully settled in ADOPTION-MECHANICS.md §1. **Staleness re-check below: nothing stale — ex_doc still 0.40.1.** |
| HEXD-02 | `mix docs` renders locally, logo/favicon visible, no new warnings, non-bumping commit | Settled §1. The `docs:`/`chore:` non-bumping classification is re-confirmed in RELH-01 §below (release-please defaults unchanged). |
| RELH-01 | release-please can no longer cut a release from brand/planning-only commits | **Open Item 1 below** — VERDICT + CI-lint design + edge-case table. |
| RELH-02 | Reconcile 1.6.x aftermath, bump inbound pin to released core, fix memory | **Open Item 2 below** — 3-way table + encoded action. |
</phase_requirements>

## Summary

Both open items resolved at HIGH confidence.

**RELH-01:** release-please DOES offer a clean config-level mechanism — `exclude-paths`, a per-package array supported on the root `"."` package, whose semantics ("if ALL files from a commit belong to one of the paths, the commit is skipped") are exactly the per-commit form of the lint logic. The documented #2301 footgun does NOT apply here because the guarded paths (`brandbook/`, `.planning/`, `prompts/`) are not owned by any other package. **Recommendation: adopt `exclude-paths` AND the CI lint — belt-and-suspenders.** The CI lint remains primary (it's a required gate that fails loudly; `exclude-paths` fails silently by simply not bumping). Lint placement: a new dedicated workflow (no `paths-ignore`), keying on the PR title type + the PR's changed-file set.

**RELH-02 — the reconciliation flips CONTEXT.md's framing.** Live Hex is authoritative and shows **mailglass 1.6.2 / mailglass_admin 1.6.2 / mailglass_inbound 1.3.1** (all published 2026-06-12). The **release-state memory was CORRECT**; the **in-repo state (1.6.1/1.6.1/1.3.0) is STALE**. Inbound 1.3.1 on Hex already pins `mailglass == 1.6.2`, but the in-repo inbound pin still says `== 1.6.1`. The 1.6.1/1.6.2 package tags exist on the **remote** (`origin`) but were never fetched locally. This is the documented "accidental release train" from the brandbook feat commits (root `.` claimed all paths — the exact bug RELH-01 hardens). The train HAS settled (every package's latest Hex version has a matching remote tag), so D-13's stop-short branch does NOT apply.

**Primary recommendation:** RELH-01 — add `exclude-paths: ["brandbook", ".planning", "prompts"]` to the root `.` package config AND a required `guard-brand-only-bumps` CI workflow. RELH-02 — treat Hex (1.6.2/1.6.2/1.3.1) as truth: bump in-repo @versions + manifest + pins to match released reality via a `fix(inbound):`-anchored reconciliation, fetch the remote 1.6.x tags (don't delete — they're real published releases), and correct `.planning` docs that claim 1.6.1.

---

## Open Item 1 — RELH-01: release-please config path exclusion + CI-lint design

### VERDICT on config mechanism: a clean mechanism EXISTS — `exclude-paths`

**`exclude-paths` is a real, schema-defined, per-package option** [CITED: raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json].

Schema fragment (verbatim from the repo's own `$schema` target):
```json
"exclude-paths": {
  "description": "Path of commits to be excluded from parsing. If all files from commit belong to one of the paths it will be skipped",
  "type": "array",
  "items": { "type": "string" }
}
```

Key facts:
- **Available on the root `"."` package.** The property lives in `ReleaserConfigOptions`, referenced by both the top-level config (via `allOf`) and each per-package entry (via `additionalProperties`). The root package is just another package entry. [CITED: release-please config schema]
- **Semantics match the lint exactly:** a commit is skipped for that package only if *every* file in the commit is under one of the excluded paths. A mixed commit (brand file + real code) is NOT skipped — it still bumps. This is identical to the "subset" logic the lint must implement. [CITED: schema description]
- **Documented pattern for "root package that should NOT claim subdir X" confirmed.** Community guidance shows exactly the `"."` + `exclude-paths` shape to stop a root package claiming subpackage changes [CITED: googleapis/release-please issue #2459, #2477; WebSearch].

**The #2301 footgun does NOT apply here.** Issue #2301 ("`exclude-paths` ignoring every commit") is the case where someone excludes a path that the *same* package legitimately owns/releases, so its own commits get skipped and no release PR ever appears. Our guarded paths (`brandbook/`, `.planning/`, `prompts/`) are **not owned by any package** — no package should ever release because of a change confined to them. Excluding them from the root `.` (and, defensively, from `mailglass_admin`/`mailglass_inbound` too — though those package-dir prefixes already don't match these top-level dirs) cannot suppress any legitimate release. [VERIFIED: issue #2301 analysis + repo path layout]

**Honest absence-of-certainty note:** `exclude-paths` is documented and schema-backed, but it fails *silently* — if it ever misbehaves (e.g., a release-please-action version regression), nothing alerts you; you simply get no bump. That is precisely why it must be the SECONDARY mechanism behind a loud, required CI lint.

### VERDICT: adopt BOTH

| Mechanism | Role | Failure mode | Why keep it |
|---|---|---|---|
| Root `.` `exclude-paths: ["brandbook", ".planning", "prompts"]` | Defense-in-depth (prevents the bump at the source) | Silent (no bump, no alert) | Clean, native, zero-flake; stops the train before it starts |
| `guard-brand-only-bumps` CI lint (required check) | **Primary** (fails the PR loudly) | Loud (red required check, blocks merge) | Enforced gate; catches the case before merge; auditable |

Adopting `exclude-paths` is low-cost and strictly additive. But per D-09/D-10, **plan the CI lint as the deliverable that must exist and pass**; treat `exclude-paths` as a one-line config add in the same phase.

> Caveat for the planner: `exclude-paths` matching is path-prefix based on the **monorepo-relative** path. Use bare directory names without leading `./` or trailing `/` — `"brandbook"`, `".planning"`, `"prompts"` — matching how the existing `component`/package paths are written in `release-please-config.json`.

### CI-lint design (the committed primary mechanism)

#### Placement: a NEW dedicated workflow — do NOT extend `ci.yml`, do NOT rely solely on `pr-title.yml`

The constraint that decides placement:
- `ci.yml` has `paths-ignore: [".planning/**", "prompts/**"]` (verified `ci.yml:6-13`). A `feat:` PR touching only `.planning/` (or, by the same class, only brand paths) **skips `ci.yml` entirely** — so the lint cannot live in any `ci.yml` job or it would be silently absent on exactly the PRs it must catch. (Note: `ci.yml`'s `paths-ignore` does NOT list `brandbook/**`, so a brand-only PR currently *does* run `ci.yml` today — but `.planning/`-only PRs do not, and the guard must cover all three paths uniformly. Don't depend on the asymmetry.)
- `pr-title.yml` uses `pull_request_target` with no `paths-ignore` (verified `pr-title.yml:3-6`), so it ALWAYS fires — good trigger model — but it only inspects the PR *title*, not the changed-file set, and it uses a third-party action. Bolting file-set logic onto it would mix concerns and require `contents: read` it doesn't currently have.

**Recommendation:** a new workflow `.github/workflows/guard-release-trigger.yml` (name at planner's discretion) on `pull_request` with **no `paths-ignore`**, so it runs on every PR including brand/planning-only ones. Add it to the branch-protection required-checks set so it actually blocks merge.

> Trigger choice — `pull_request` vs `pull_request_target`: use plain **`pull_request`** with `permissions: pull-requests: read` (or just `contents: read` + `gh` with the default token). The lint reads the PR's own changed files and title; it does not need secrets or write access, so the `pull_request_target` elevated-context model (used by `pr-title.yml` only because its action needs to post status on forks) is unnecessary and higher-risk here. This repo is single-maintainer with no external fork PRs, so `pull_request` is sufficient and safer.

#### What to lint: PR title type + PR changed-file set (NOT per-commit)

Reasoning (this is the load-bearing decision):
- **Squash-merge** is the repo's workflow (CLAUDE.md: "Squash-merge workflow"). On squash merge, the **PR title becomes the single merge commit message** that release-please parses on `main`. So the *type that triggers release-please is the PR title's type*, full stop — individual commit message types on the branch are discarded by the squash. Linting per-commit types would check strings release-please never sees.
- The "touches only guarded paths" question is about the **aggregate changed-file set of the PR** (what the squash commit will contain), not any single intermediate commit. A PR with one brand-only commit and one code-only commit squashes into a commit touching both — and must PASS.
- Therefore the correct, least-flaky inputs are: **(a) the PR title's conventional-commit type**, and **(b) the PR's full changed-file list** (`gh pr view --json files` / the GitHub API `pulls/{n}/files`). Both are stable PR-level facts; neither depends on commit-history shape, rebases, or fixup noise.

This makes the check **exactly mirror** what release-please + `exclude-paths` will do at merge time, which is the property you want.

#### Check logic (pseudocode / shell)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Inputs available in pull_request context:
#   PR_TITLE  = ${{ github.event.pull_request.title }}
#   PR_NUMBER = ${{ github.event.pull_request.number }}
# GH_TOKEN = ${{ secrets.GITHUB_TOKEN }} (read scope is enough)

GUARDED=( "brandbook/" ".planning/" "prompts/" )

# 1. Extract the conventional-commit type from the PR title.
#    Matches: "feat:", "fix:", "feat(scope):", "feat!:", "fix(scope)!:", etc.
#    Capture: $type (feat|fix|docs|...) and whether a "!" bang is present.
if [[ "$PR_TITLE" =~ ^([a-z]+)(\([^\)]*\))?(!)?: ]]; then
  type="${BASH_REMATCH[1]}"
  bang="${BASH_REMATCH[3]}"   # "!" if breaking-change marker present
else
  echo "PR title is not a conventional commit — pr-title.yml owns that failure; pass here."
  exit 0
fi

# 2. Is this a BUMP-TRIGGERING title?
#    release-please defaults: feat -> minor, fix -> patch, any "!" -> major.
#    Also honor a BREAKING CHANGE footer if the project ever adds one to titles
#    (titles normally won't carry it, but cheap to check).
is_bump="false"
case "$type" in
  feat|fix) is_bump="true" ;;
esac
[[ -n "$bang" ]] && is_bump="true"
[[ "$PR_TITLE" == *"BREAKING CHANGE"* ]] && is_bump="true"

if [[ "$is_bump" != "true" ]]; then
  echo "Non-bumping type '$type' — release-please will not cut a release. PASS."
  exit 0
fi

# 3. Get the PR's changed files (PR-level aggregate = the squash commit content).
mapfile -t files < <(gh pr view "$PR_NUMBER" --json files --jq '.files[].path')

if [[ "${#files[@]}" -eq 0 ]]; then
  echo "No changed files reported — nothing to guard. PASS."
  exit 0
fi

# 4. Are ALL changed files inside the guarded path set? (subset test)
all_guarded="true"
for f in "${files[@]}"; do
  in_guard="false"
  for g in "${GUARDED[@]}"; do
    if [[ "$f" == "$g"* ]]; then in_guard="true"; break; fi
  done
  if [[ "$in_guard" != "true" ]]; then all_guarded="false"; break; fi
done

# 5. Decision: bump-triggering type AND every file is brand/planning-only -> FAIL.
if [[ "$all_guarded" == "true" ]]; then
  echo "::error::PR title type '${type}${bang}' triggers a release-please bump, but every"
  echo "::error::changed file is under brand/planning paths (${GUARDED[*]})."
  echo "::error::This is the 1.6.x accidental-release pattern. Use a non-bumping type"
  echo "::error::(docs:/chore:/test:) for brand/planning-only changes, or include real"
  echo "::error::package code if a release is genuinely intended."
  exit 1
fi

echo "Bump-triggering type touches real package code (not exclusively brand/planning). PASS."
exit 0
```

#### Edge-case table (all three required cases handled)

| PR | Title type | Changed files | `is_bump` | `all_guarded` | Result | Correct? |
|----|-----------|---------------|-----------|---------------|--------|----------|
| Mixed: brand book + real `lib/` code | `feat:` | `brandbook/x.svg`, `lib/mailglass/foo.ex` | true | **false** | **PASS** | ✓ real release intended |
| Brand/planning-only, non-bumping | `docs:` | `brandbook/x.svg`, `.planning/y.md` | **false** | true | **PASS** (exits at step 2) | ✓ docs never bumps |
| Brand/planning-only, bumping — **the 1.6.x bug** | `feat:` / `fix:` | `brandbook/x.svg` only (or `.planning/`-only) | true | true | **FAIL** | ✓ exactly the bug |
| Bang/breaking, brand-only | `chore!:` | `.planning/y.md` only | true (bang) | true | **FAIL** | ✓ `!` bumps major even on chore |
| Non-conventional title | (none) | anything | — | — | PASS (defer to pr-title.yml) | ✓ no double-failure |

The pseudocode short-circuits at step 2 for non-bumping types BEFORE fetching files, so a `docs:`/`chore:`/`test:` brand-only PR is cheap and always passes — the common v1.10 case.

#### Belt-and-suspenders interaction with `exclude-paths`

If `exclude-paths` is also added: a brand-only `feat:` PR that somehow merges (e.g., lint disabled in a one-off) still produces NO bump because release-please skips the all-excluded commit. The lint catches it at PR time; `exclude-paths` catches it at parse time. Neither alone is trusted; together they close the gap that fired twice in the 1.6.x incident (`brandbook feat` → core 1.6.0; `fix(inbound)` → core 1.6.2).

> One subtlety the planner should note in the task: `fix(inbound):` commits legitimately touch `mailglass_inbound/` (NOT a guarded path), so they correctly PASS the lint and correctly bump inbound. The 1.6.2 over-bump was core picking up a `fix(inbound):` commit because the root `.` claimed `mailglass_inbound/`'s files too — that is fixed by giving the root `.` an `exclude-paths` (or, more precisely, the root over-claim is the same class of bug; `exclude-paths` on `brandbook/.planning/prompts` does not fix the inbound-attribution-to-core case). **If the planner also wants to stop `fix(inbound):` from bumping core, that requires excluding `mailglass_inbound` (and `mailglass_admin`) from the root `.` `exclude-paths` too** — a strictly larger hardening. Recommend including all five paths in the root exclude list: `["brandbook", ".planning", "prompts", "mailglass_admin", "mailglass_inbound"]`, so the root `.` only ever releases for genuine core (`lib/`, root-level) changes. This directly addresses the second proven 1.6.x trigger.

---

## Open Item 2 — RELH-02: authoritative live-Hex version truth

### Live Hex (authoritative source of truth) — `mix hex.info`

| Package | Latest on Hex | Released | Notable |
|---|---|---|---|
| `mailglass` | **1.6.2** | 2026-06-12 | downloads on 1.6.2: 11 |
| `mailglass_admin` | **1.6.2** | 2026-06-12 | (1.6.1 was NOT published for admin — `mix hex.info mailglass_admin 1.6.1` → "No release"; admin jumped 1.5.1 → 1.6.2) |
| `mailglass_inbound` | **1.3.1** | 2026-06-12 | inbound 1.3.1 deps: **`mailglass == 1.6.2`** |

Recent Hex release lists (verified live):
- mailglass: 1.6.2, 1.6.1, 1.5.1, 1.5.0, 1.4.5 …
- mailglass_admin: 1.6.2, 1.5.1, 1.5.0, 1.4.5 … (**no 1.6.1** — linked-version split artifact; admin's 1.6.1 release PR evidently never published, only core's did, then both jumped to 1.6.2)
- mailglass_inbound: 1.3.1, 1.3.0, 1.2.0, 1.1.5 …

### Git tags — local vs. remote (the missing piece)

| Tag | Local? | Remote (`origin`)? |
|---|---|---|
| `mailglass-v1.6.1` | ✗ | **✓** (`0193d94c`) |
| `mailglass-v1.6.2` | ✗ | **✓** (`c77ee82e`) |
| `mailglass_admin-v1.6.1` | ✗ | **✓** (`0193d94c`) |
| `mailglass_admin-v1.6.2` | ✗ | **✓** (`c77ee82e`) |
| `mailglass_inbound-v1.6.*` | ✗ | ✗ (inbound uses its own line — would be `mailglass_inbound-v1.3.1`) |
| `v1.6` (milestone tag) | ✓ | — |

**Key correction to CONTEXT.md's premise:** the 1.6.x package tags are NOT "stale/unpublished." They **exist on the remote and correspond to real published Hex releases.** They are merely **un-fetched locally** (the local checkout never ran `git fetch --tags` since those tags were pushed by the release bot). `mailglass-v1.6.1`/`admin-v1.6.1` share one SHA; `…-v1.6.2` share another — consistent with linked core+admin releases. (Note: a `mailglass_admin-v1.6.1` tag exists on the remote even though admin 1.6.1 was never published to Hex — that's the linked-version release-PR tagging both, with admin's Hex publish having failed/skipped; harmless tag, real on git, no Hex artifact.)

### 3-way reconciliation table

| Source | mailglass | mailglass_admin | mailglass_inbound | inbound→core pin | Authoritative? |
|---|---|---|---|---|---|
| **(a) Hex live** | **1.6.2** | **1.6.2** | **1.3.1** | `== 1.6.2` | **YES — ground truth** |
| (b) In-repo (manifest + 3×@version + 2 pins) | 1.6.1 | 1.6.1 | 1.3.0 | `== 1.6.1` | No — **STALE** |
| (c) Release-state memory | 1.6.2 | 1.6.2 | 1.3.1 | (= released) | **Matches Hex — was CORRECT** |

In-repo specifics (verified):
- `.release-please-manifest.json` → `{".":"1.6.1","mailglass_admin":"1.6.1","mailglass_inbound":"1.3.0"}`
- `mix.exs:4` `@version "1.6.1"`; `mailglass_admin/mix.exs:4` `@version "1.6.1"`; `mailglass_inbound/mix.exs:4` `@version "1.3.0"`
- `mailglass_admin/mix.exs:142` pin `{:mailglass, "== 1.6.1"}`; `mailglass_inbound/mix.exs:127` pin `{:mailglass, "== 1.6.1"}`

**Verdict on D-13:** the train HAS settled. Every package's latest Hex version has a matching remote git tag, and inbound 1.3.1's published `mailglass == 1.6.2` pin is internally consistent with core 1.6.2. There is no mid-flight contradiction. **Do NOT invoke D-13's stop-short branch.** Proceed with reconciliation.

### Encoded reconciliation ACTION for the planner

This is the **Hex > in-repo** branch of D-12: in-repo manifest/pins are stale and must be advanced to released reality. Released reality is 1.6.2/1.6.2/1.3.1 with inbound pinning core `== 1.6.2`.

The subtlety: **this phase cuts no Hex release** (locked scope). So the goal is to make the *in-repo source of truth match what is already on Hex* — not to publish anything new. The released 1.6.2/1.3.1 artifacts already exist; the repo just needs to stop lying about being on 1.6.1.

Two equally-valid encodings — recommend the planner pick **Encoding A** (it keeps release-please's manifest as the single source of truth and lets the next natural release flow cleanly):

**Encoding A — align in-repo to released reality, no version bump intended:**
1. `git fetch --tags origin` so local has `mailglass-v1.6.2`, `mailglass_admin-v1.6.2`, etc. (disposition = **fetch + keep**, see below). No deletion.
2. Update `.release-please-manifest.json` → `{".":"1.6.2","mailglass_admin":"1.6.2","mailglass_inbound":"1.3.1"}` to match Hex.
3. Update the three `@version` lines: core `mix.exs:4` → `1.6.2`, admin `mix.exs:4` → `1.6.2`, inbound `mix.exs:4` → `1.3.1`.
4. Update both core-dep pins to the released core: admin `mix.exs:142` and inbound `mix.exs:127` → `{:mailglass, "== 1.6.2"}`.
5. Correct `.planning` release-state memory/docs that assert 1.6.1 (STATE.md, CLAUDE.md current-state, the release-state memory files) to the final truth **1.6.2/1.6.2/1.3.1**.

**Commit typing for the version-alignment edits — this is where the `fix(inbound):` dance matters:**

The catch: editing `@version`/manifest by hand is normally something release-please OWNS — it rewrites those on a release PR. Hand-editing them to *match what's already released* (catch-up, not a bump) is safe ONLY if release-please then sees no further work to do. Because the manifest will say 1.6.2/1.6.2/1.3.1 (= what's tagged/published), release-please's next run finds no un-released bump-triggering commits for those versions and proposes nothing — correct.

For the **inbound exact-pin** specifically (`mailglass_inbound/mix.exs:127`), the in-repo comment (lines 114-124) is explicit and binding:
- The published inbound 1.3.1 **already** carries `== 1.6.2` (verified via `mix hex.info mailglass_inbound 1.3.1`). So the *Hex artifact is correct*; only the *working-tree pin* is stale at `== 1.6.1`.
- Bumping the working-tree pin to `== 1.6.2` to match the released inbound is a **catch-up**, not a new release. But the comment's rule stands for the future: **any change that needs to SHIP a new pin to Hex must land as `fix(inbound):`** (chore/docs do NOT trigger an inbound release, leaving adopters on a stale pin). Since this phase ships no release, the pin edit can ride a non-bumping `chore(release):`/`docs(state):` reconciliation commit — but the planner must NOT pre-bump the pin to a core version that isn't published. Core 1.6.2 IS published, so `== 1.6.2` is safe.
- **Ordering constraint (the reds-main pitfall):** never set the inbound/admin pin to an UNPUBLISHED core version. `== 1.6.2` is published → safe. If a future task wanted `== 1.6.3` before core 1.6.3 ships, that reds main (the docs-contract/installer-smoke jobs try to resolve a non-existent Hex version). Not a risk here.

**Commit-type recommendation for the reconciliation PR:** use **non-bumping types** so this phase cuts nothing:
- `chore(release): align in-repo manifest + @version + dep pins to released 1.6.2/1.6.2/1.3.1` (manifest + mix.exs edits)
- `docs(state): correct release-state memory to 1.6.2/1.6.2/1.3.1` (`.planning` docs)

> Cross-check this against RELH-01's lint: a `chore(release):` PR that touches `mix.exs`/manifest (real package files, NOT brand/planning) is non-bumping anyway and is not all-guarded → PASSES the new lint trivially. A `docs(state):` PR touching only `.planning/` is non-bumping → PASSES at step 2. No conflict between the two requirements landing in the same phase.

> Note on whether release-please will fight the hand-edit: the release-please-action only rewrites `@version`/manifest **when it cuts a release PR**. With the manifest already at the released versions and no pending bump-triggering commits, it has nothing to cut. The `sed` sync step in `release-please.yml:139-263` only runs `if prs_created == 'true'`, so it won't touch the pins outside a release PR. The hand-edit is stable.

### Tag disposition (D-12 / discretion)

**Recommendation: FETCH and KEEP — do NOT delete.** The 1.6.1/1.6.2 package tags on `origin` are real, point at real published Hex releases, and are referenced by `source_ref` in the published tarballs (`source_ref: "v" <> @version` patterns). Deleting them would orphan HexDocs "view source" links and break the audit trail. The only anomaly — `mailglass_admin-v1.6.1` exists on git but admin 1.6.1 was never published to Hex — is a harmless linked-version tagging artifact; **annotate-and-document** it in the release-state memory rather than delete (deleting a tag the bot will plausibly re-derive invites churn). So: `git fetch --tags`, keep all, document the admin-1.6.1-tag-without-Hex-publish quirk.

### What CONTEXT.md got backwards (flag for the planner)

CONTEXT.md D-11 says "in-repo state is internally consistent at 1.6.1/1.6.1/1.3.0 … release-state memory claims Hex shipped 1.6.2/1.6.2/1.3.1." Investigation proves **the memory was right and the in-repo is the stale one.** The planner should encode the *Hex > in-repo* reconciliation, not the *memory was wrong* branch. (D-12 already enumerates this branch — "IF Hex > in-repo → in-repo manifest/pins are stale and must be bumped" — so this is a covered case, just the opposite of CONTEXT.md's leading assumption.)

---

## HEXD-01/02 staleness re-check (per task instructions)

Confirmed nothing in ADOPTION-MECHANICS.md §1 is stale:
- ex_doc still resolves to **0.40.1** in all three lockfiles (the §1 evidence table holds; the 0.40.3 dependabot PR #77 is still pending/orthogonal per D-08).
- `logo:`/`favicon:` semantics unchanged; SVG width/height gap still real (canonical SVGs are viewBox-only).
- Relative-path strategy (`brandbook/assets/...` root; `../brandbook/assets/...` siblings) still valid — `brandbook/` is now the canonical post-rename folder (Phase 91 complete).
No re-research needed; §1 is authoritative for HEXD-01/02.

## Project Constraints (from CLAUDE.md)

- **Squash-merge workflow** → lint the PR title, not per-commit (drives RELH-01 design).
- **Conventional Commits enforced** (`pr-title.yml` allowlist) — the new lint complements, does not replace, the type-validity check.
- **All third-party GitHub Actions pinned to commit SHA** — the new guard workflow should use only `actions/checkout` (SHA-pinned) + `gh` (preinstalled); avoid adding a new third-party action (favors the shell-script form over a marketplace action).
- **`docs(state):` commit type for STATE.md updates** — CI path filters skip them; the RELH-02 memory correction uses this type.
- **Hex publish only from protected ref / hands-free pipeline** — RELH-02 must not trigger a publish (use non-bumping commit types).
- **Inbound exact-pin drags a paired release** — relevant to RELH-02 future bumps, not to this phase's catch-up edit (1.6.2 already published).
- **Don't run mix in `reference/demo_app`** (swoosh lock drift) — honored; no such command run during research.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `exclude-paths` is honored by the pinned `release-please-action` v5.0.0 (`45996ed1`) used here — schema-defined but action-version behavior not runtime-tested in this repo | Open Item 1 | LOW — it's secondary to the lint; if it silently no-ops, the required CI lint still blocks the bug. Planner can verify by adding it and observing no behavior change on a benign brand-only `docs:` PR. |
| A2 | The remote `mailglass_admin-v1.6.1` tag corresponds to a release PR that tagged both linked packages but only published core to Hex (admin 1.6.1 absent from Hex) | Open Item 2 | LOW — affects only the documentation note; reconciliation target (1.6.2/1.6.2/1.3.1) is unaffected. |

## Sources

### Primary (HIGH confidence)
- `mix hex.info mailglass` / `mailglass_admin` / `mailglass_inbound` (live, 2026-06-13) — authoritative version truth 1.6.2/1.6.2/1.3.1; inbound 1.3.1 pins `mailglass == 1.6.2`.
- `git ls-remote --tags origin` — remote 1.6.1/1.6.2 package tags exist; local does not have them.
- release-please config schema: https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json — `exclude-paths` definition (array, per-package incl. root `.`).
- Repo files read: `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`, `pr-title.yml`, `ci.yml`, `mix.exs`, `mailglass_admin/mix.exs`, `mailglass_inbound/mix.exs`.
- `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md` §1, §2 (pre-settled mechanics, re-confirmed current).

### Secondary (MEDIUM confidence)
- https://github.com/googleapis/release-please/issues/2301 — `exclude-paths` footgun (does NOT apply to unowned guard paths).
- https://github.com/googleapis/release-please/issues/2459, https://github.com/googleapis/release-please/issues/2477 — root `.` + `exclude-paths` pattern for monorepos.

## Metadata

**Confidence breakdown:**
- RELH-01 config mechanism (`exclude-paths`): HIGH — schema-verified, semantics documented, footgun analyzed and excluded.
- RELH-01 CI-lint design: HIGH — placement forced by verified `ci.yml`/`pr-title.yml` triggers; logic mirrors release-please's own parse.
- RELH-02 version truth: HIGH — live `mix hex.info` + remote tags + inbound published-pin all corroborate 1.6.2/1.6.2/1.3.1.

**Research date:** 2026-06-13
**Valid until:** ~2026-07-13 (Hex versions are immutable facts; release-please schema is stable. Re-check only if a new 1.6.x/1.7.x release lands before planning.)

## RESEARCH COMPLETE

**Phase:** 93 — HexDocs Wiring and Release Hardening
**Confidence:** HIGH

### Key Findings
- **RELH-01 config mechanism EXISTS:** root `.` `exclude-paths` is schema-supported; recommend `["brandbook", ".planning", "prompts", "mailglass_admin", "mailglass_inbound"]` to also stop `fix(inbound):` from bumping core (the second proven 1.6.x trigger). Adopt IN ADDITION to the lint.
- **RELH-01 lint:** new dedicated workflow (no `paths-ignore`), `pull_request` trigger, lint PR-title type + PR changed-file subset. Three required edge cases verified (mixed PASS, non-bumping PASS, brand-only-bumping FAIL).
- **RELH-02 truth flips CONTEXT.md:** Hex is authoritative at **1.6.2/1.6.2/1.3.1**; the **release-state memory was correct**, the **in-repo (1.6.1/1.6.1/1.3.0) is stale.** Inbound 1.3.1 on Hex already pins `== 1.6.2`.
- **Tags are real, just un-fetched:** 1.6.1/1.6.2 package tags exist on `origin` → `git fetch --tags` + KEEP, do not delete.
- **Train has settled → D-13 stop-short does NOT apply.** Proceed with the Hex>in-repo reconciliation using non-bumping commit types (this phase cuts no release).

### File Created
`.planning/phases/93-hexdocs-wiring-and-release-hardening/93-RESEARCH.md`

### Ready for Planning
Both open items resolved at HIGH confidence with concrete, executable guidance.
