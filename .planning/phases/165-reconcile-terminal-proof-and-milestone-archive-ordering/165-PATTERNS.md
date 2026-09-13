# Phase 165: Reconcile terminal proof and milestone archive ordering - Pattern Map

**Mapped:** 2026-09-13
**Files analyzed:** 15 new/modified file groups
**Analogs found:** 15 / 15

All analogs below were verified with `git ls-files`. No ignored runtime mirror is used as an implementation source. The external installed executable is deliberately not a file assignment here: its destination and exact installation tuple require the D-16 approval checkpoint.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/mailglass_finalize_milestone_loader.mjs` | utility / trust-boundary loader | file-I/O, request-response | `scripts/mailglass_finalize_phase_loader.mjs` | exact role; archive semantics differ |
| `scripts/finalize_milestone_v2_7.sh` | service / terminal verifier | batch, file-I/O | `scripts/finalize_phase_164.sh` | exact role; archive semantics differ |
| `test/scripts/phase_165_milestone_finalizer_test.exs` | test | batch, event-driven fixtures | `test/scripts/phase_164_closeout_test.exs` | exact |
| `mix.exs` | config | request-response task dispatch | `mix.exs` Phase 164 aliases | exact in-file pattern |
| `test/test_helper.exs` | config | request-response test filtering | `test/test_helper.exs` Phase 164 exclusion | exact in-file pattern |
| `.planning/phases/161-*/161-04-SUMMARY.md` | lifecycle metadata | transform | adjacent `161-05-SUMMARY.md` | exact frontmatter pattern |
| `.planning/phases/161-*/161-VALIDATION.md` | validation record | batch | `.planning/phases/164-*/164-VALIDATION.md` | role-match |
| `.planning/phases/163-*/163-VALIDATION.md` | validation record | batch | `.planning/phases/164-*/164-VALIDATION.md` | role-match |
| `.planning/ROADMAP.md` | lifecycle config | transform | current `.planning/ROADMAP.md` Phase 165 block | exact in-file pattern |
| `.planning/PROJECT.md` | lifecycle config | transform | current `.planning/PROJECT.md` milestone sections | exact in-file pattern |
| `.planning/STATE.md` | lifecycle state | transform | current `.planning/STATE.md` | exact in-file pattern |
| `.planning/state.json` | generated state store | transform | canonical `publishStateContract` output currently tracked at `.planning/state.json` | exact owner |
| `.planning/phases/165-*/165-VALIDATION.md` | validation record | batch | `.planning/phases/164-*/164-VALIDATION.md` | exact |
| `.planning/phases/165-*/165-VERIFICATION.md` | verification record | batch | `.planning/phases/164-*/164-VERIFICATION.md` | exact |
| `.planning/phases/165-*/165-*-SUMMARY.md` | lifecycle metadata | transform | `.planning/phases/164-*/164-44-SUMMARY.md` | exact |

The canonical audit, archived roadmap/requirements/audit, `milestones/v2.7-phases/`, and milestone-history changes are workflow-owned outputs rather than hand-authored implementation files. Plans should invoke the canonical audit/archive owners and validate their output instead of introducing repository-local copies.

## Pattern Assignments

### `scripts/mailglass_finalize_milestone_loader.mjs` (utility, file-I/O/request-response)

**Analog:** `scripts/mailglass_finalize_phase_loader.mjs`

**Imports and closed runtime pattern** (lines 1-35):

```javascript
#!/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node
import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import { chmodSync, lstatSync, mkdirSync, mkdtempSync, readFileSync,
  realpathSync, rmSync, statSync, writeFileSync } from "node:fs";

const MAX_OUTPUT_BYTES = 16_000;
const TRUSTED_TOOLS = Object.freeze({
  NODE: "/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node",
  GIT: "/opt/homebrew/Cellar/git/2.41.0/bin/git",
  BASH: "/opt/homebrew/Cellar/bash/5.2.37/bin/bash",
  GH: "/opt/homebrew/Cellar/gh/2.95.0/bin/gh",
  JQ: "/usr/bin/jq"
});
```

Copy the physical, absolute tool closure and bounded diagnostics. Give the milestone loader a new identity/source path and accept only exact `v2.7`; do not modify or import the Phase 164 constants.

**Tool/auth guard** (lines 123-145):

```javascript
const allowedOwners = new Set([0, process.getuid?.()].filter(Number.isInteger));
for (const name of REQUIRED_TOOL_NAMES) {
  const path = tools[name];
  if (!isAbsolute(path)) fail(`trusted ${name} path is not absolute`);
  entry = lstatSync(path);
  physical = realpathSync(path);
  if (!entry.isFile() || entry.isSymbolicLink() || physical !== path) {
    fail(`trusted ${name} executable is not one physical regular file`);
  }
  if (!allowedOwners.has(entry.uid) || (entry.mode & 0o022) !== 0) {
    fail(`trusted ${name} executable has unsafe ownership or mode`);
  }
}
```

**Commit-file authentication** (lines 281-326): authenticate one stage-0 tracked path, require a blob at the captured OID, reject staged/working differences, and read bytes with `git show`. Apply this to the loader, verifier, and every archived evidence dependency.

```javascript
const type = git(repo, ["cat-file", "-t", `${authorityOid}:${repositoryPath}`], {
  encoding: "utf8"
}).stdout.trim();
if (type !== "blob") fail(`${repositoryPath} is not a blob at the authority commit`);
exactIndexRecord(repo, repositoryPath);
if (staged.status !== 0 || working.status !== 0) {
  fail(`${repositoryPath} differs from authority`);
}
```

**Private materialization** (lines 395-401):

```javascript
mkdirSync(dirname(destination), { recursive: true, mode: 0o700 });
const mode = dependency.executable ? 0o500 : 0o400;
writeFileSync(destination, contents, { flag: "wx", mode });
chmodSync(destination, mode);
```

The manifest must enumerate archived `v2.7-ROADMAP.md`, `v2.7-REQUIREMENTS.md`, `v2.7-MILESTONE-AUDIT.md`, exact phase directories 161-165, and final `MILESTONES.md`/`PROJECT.md`/`STATE.md`/`state.json`; it must reject mixed live/archive fallback.

**Clean/moving authority guard** (lines 416-450): use porcelain v1 with all untracked files, capture a full OID once, and re-authenticate installed/current source bytes. Recheck the captured OID immediately before child dispatch.

### `scripts/finalize_milestone_v2_7.sh` (service, batch/file-I/O)

**Analog:** `scripts/finalize_phase_164.sh`

**Fail-closed cleanliness pattern** (lines 26-28 and 266-270):

```bash
"$MAILGLASS_GIT" -C "$repo" status --porcelain=v1 --untracked-files=all
```

Any output or command failure is non-clean. Repeat at entry, after evidence collection, before report publication, and before successful return.

**Exact push-CI selector** (lines 91-108):

```jq
select(
  .workflowName == "CI" and
  .event == "push" and
  .attempt == 1 and
  .headBranch == "main" and
  .headSha == $sha and
  .status == "completed" and
  .conclusion == "success"
)
```

Derive the acceptable run from read-only listings. Accept no run ID from the caller and expose no dispatch/rerun command. Apply the analogous exact tuple to every registered schedule: event `schedule`, attempt `1`, branch `main`, exact final SHA, completed/success.

**Output pattern** (lines 245-280): collect into a private temporary directory, write only beneath an ignored `tmp/` report root, then perform late HEAD/cleanliness/repository checks. A late failure must not leave a pass report.

Add semantic guards before remote lookup: audit `status: passed`, exact `16/16`, `5/5`, `16/16`, `5/5`, all five validations compliant, exact archive set, final lifecycle-state agreement, and preserved 14-PR policy disclosure.

### `test/scripts/phase_165_milestone_finalizer_test.exs` (test, batch/event-driven fixtures)

**Analog:** `test/scripts/phase_164_closeout_test.exs`

**Lane non-vacuity pattern** (lines 139-175): inspect `Mix.Project.config()[:aliases]`, assert exact required/controlled-host aliases, isolate the installed describe block by tag, require at least one test, and reject conditional skips or disposable-fixture helpers inside the real installed boundary.

```elixir
aliases = Mix.Project.config()[:aliases]
assert Keyword.fetch!(aliases, :"verify.ci_lane_contract") == [expected_required_lane]
assert Regex.scan(~r/^    test "/m, installed_block) != []
refute installed_block =~ "@tag :skip"
refute installed_block =~ "if File.regular?(@installed_loader)"
```

**Hostile CI fixture** (lines 474-501): create several plausible runs (rerun, dispatch, wrong SHA, and one exact run), assert only the exact attempt-one push is selected, and assert no workflow dispatch/rerun vocabulary exists.

**Archive manifest fixture** (adapt lines 991-1055): enumerate the complete expected set, delete each required member one at a time, add malformed/extra members, assert nonzero status, bounded diagnostics, and no dispatch marker. For Phase 165 the matrix is archived phases 161-165 plus audit and final state artifacts, not numbered Phase 164 plan pairs.

**Moving-HEAD fixture** (lines 1220-1235): prove the accepted fixture dispatches, mutate HEAD at the boundary, then require nonzero status, no marker, and the stable `authority commit changed` diagnostic.

Also cover stale-but-parseable audit, incomplete archive, dirty index/worktree/untracked output, caller-selected/rerun CI, non-natural schedules, and tracked report paths. Each negative must reach its intended boundary and prove non-dispatch/non-pass output.

### `mix.exs` and `test/test_helper.exs` (config, request-response)

**Analogs:** the Phase 164 aliases in `mix.exs`; base exclusion in `test/test_helper.exs`.

**Alias separation pattern** (`mix.exs`, lines 294-313):

```elixir
"verify.ci_lane_contract": [
  "test test/scripts/ --exclude phase_164_proposal_boundary --exclude phase_164_installed_production_boundary --warnings-as-errors"
],
"verify.phase_164.installed_boundary": [
  "test test/scripts/phase_164_closeout_test.exs --only phase_164_installed_production_boundary --warnings-as-errors"
]
```

Add the Phase 165 installed tag to the required lane's exclusions and a dedicated `verify.phase_165.installed_boundary` alias. Keep repository fixtures in the required lane and real host-installed assertions only in the dedicated lane. Mirror the global default exclusion pattern from `test/test_helper.exs:45-53` by adding `:phase_165_installed_production_boundary` to `base_exclusions`.

### Phase 161 SUMMARY and Phase 161/163 VALIDATION reconciliation (lifecycle metadata, transform/batch)

**SUMMARY analog:** `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-05-SUMMARY.md:21-35` uses list-shaped YAML:

```yaml
requirements-completed: [WSPC-02]
```

Use the same key in `161-04-SUMMARY.md` with exactly `[WSPC-01, WSPC-03, WSPC-04]`, because 161-04 owns the final workspace verification. Do not move ownership of the already-claimed `WSPC-02`.

**VALIDATION analog:** `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-VALIDATION.md`. Preserve the existing Phase 161/163 evidence bodies and re-run the canonical validation workflow so frontmatter becomes workflow-recognized `status: validated`; do not manually relabel without refreshed evidence. Existing Phase 161/163 files demonstrate the fields to retain:

```yaml
phase: 163
slug: deterministic-release-path-timeout-repairs
nyquist_compliant: true
wave_0_complete: true
human_uat_required: false
```

### ROADMAP / PROJECT / STATE / `state.json` (lifecycle config/store, transform)

**Analogs:** their own current milestone sections, with canonical generation for JSON.

- In `.planning/ROADMAP.md`, retain the existing Phase 165 block at lines 375-383 and reconcile v2.7 headings/counts from Phases 161-164 to 161-165. Remove current-facing Phase 164-pending terminal authority claims; historical plan descriptions remain historical.
- In `.planning/PROJECT.md`, update the current v2.7 section around lines 78-104 only as lifecycle truth requires; preserve scope/non-goals and the 16-requirement count.
- In `.planning/STATE.md`, follow the current focus/status/progress structure at lines 29-38 and the Phase 165 history entry near line 130. Before archive it should describe Phase 165 ordinary work honestly; after archive it must agree v2.7 is complete and archived.
- Do not hand-author `.planning/state.json`. Invoke the installed canonical `publishStateContract(cwd)` after the last Markdown lifecycle edit and require `{published: true, reason: "published"}`. Include the republished JSON in the final tracked archive commit.

### `165-VALIDATION.md`, `165-VERIFICATION.md`, and `165-*-SUMMARY.md` (lifecycle records, batch/transform)

**Analogs:** Phase 164 records and summaries.

- Copy the validation frontmatter/task-map/command-evidence shape from `164-VALIDATION.md`, but make the two authorities explicit: ordinary repository and controlled-host readiness are validation inputs; the real post-archive terminal invocation is not.
- Copy `164-VERIFICATION.md`'s authority language: ordinary verification proves implementation and fixtures, not terminal evidence. Record every D-12 hostile case and exact command/result.
- Copy list-shaped `requirements-completed` and structured verification entries from `164-44-SUMMARY.md`, but Phase 165 must use `requirements-completed: []` because D-09 assigns no REQ-ID. Summaries may claim decision completion, never a new requirement mapping.

## Shared Patterns

### Authentication and authority capture

**Source:** `scripts/mailglass_finalize_phase_loader.mjs:123-145,240-268,295-370,416-450`

Apply to both new finalizer files: physical canonical checkout, normalized `szTheory/mailglass` origin, exact full lowercase HEAD OID, regular non-symlink safe-owned tool/source paths, one stage-0 index record, clean tree including untracked files, and recheck immediately before dispatch/report success.

### Error handling

**Source:** `scripts/mailglass_finalize_phase_loader.mjs:96-121,177-190`

```javascript
function fail(message) {
  throw new Error(`finalize-phase: ${message}`);
}
function bounded(message) {
  return String(message).slice(-MAX_OUTPUT_BYTES);
}
```

Use a new milestone-specific prefix. Subprocesses require explicit timeout/maxBuffer, nonzero/error checks, and bounded stderr/stdout. Shell checks use explicit nonzero exits and closed JSON shape validation.

### Secrets and child environment

**Source:** `scripts/mailglass_finalize_phase_loader.mjs:148-174`

Reconstruct `PATH` from authenticated physical tools. Allowlist only necessary identity/temp/locale/socket/token fields, reject `ASDF_*`, pass GitHub credentials ephemerally, and never serialize tokens or environment dumps.

### Evidence separation

**Source:** `test/scripts/phase_164_closeout_test.exs:139-175,546-560`

Keep three distinct claims: disposable fixture correctness, approved installed-command readiness, and actual one-time terminal observation. Ordinary verification must state it is not terminal proof. Terminal output is ignored evidence and may occur only after the final archived SHA is protected and all exact remote evidence exists.

### Canonical audit/archive ownership

Use the installed GSD audit and milestone completion workflows. Assert the dry run has a non-null audit, exactly phases 161-165, and `quick: []`; request explicit `--confirm` only at the mutation boundary. Do not recreate archive moves, audit parsing, or state publication in ad hoc scripts.

## No Analog Found

None. The Phase 164 closeout implementation is a direct structural analog for every new executable/test concern, while adjacent planning artifacts cover every metadata role. The planner must change the authority subject from live Phase 164 state to final archived v2.7 state rather than copying Phase 164 constants or paths verbatim.

## Metadata

**Analog search scope:** `scripts/`, `test/scripts/`, `mix.exs`, `test/test_helper.exs`, tracked `.planning/` lifecycle artifacts
**Files scanned:** 17 primary files plus targeted Phase 164 summary search
**Pattern extraction date:** 2026-09-13
**Tracked-source gate:** passed for every named repository analog
