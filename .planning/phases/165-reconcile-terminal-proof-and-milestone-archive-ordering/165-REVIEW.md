---
phase: 165-reconcile-terminal-proof-and-milestone-archive-ordering
reviewed: 2026-09-13T20:05:16Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - mix.exs
  - scripts/finalize_milestone_v2_7.sh
  - scripts/mailglass_finalize_milestone_loader.mjs
  - test/scripts/ci_parity_drift_test.exs
  - test/scripts/phase_164_closeout_test.exs
  - test/scripts/phase_165_milestone_finalizer_test.exs
  - test/scripts/scheduled_control_evidence_test.exs
  - test/scripts/suite_floor_contract_test.exs
  - test/support/suite_floor.ex
  - test/test_helper.exs
findings:
  critical: 5
  warning: 4
  info: 0
  total: 9
status: issues_found
---

# Phase 165: Code Review Report

**Reviewed:** 2026-09-13T20:05:16Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

The milestone finalizer has five release-blocking authority defects. Most importantly, the shipped loader exports a fixture path that accepts caller-fabricated CI/schedule records and emits the same pass-report schema as production while disabling canonical origin and `origin/main` checks. The installed executable and its runtime tools are also not authenticated at the terminal boundary, and several path and archive-semantic checks are weaker than the Phase 165 threat model claims. Four additional test and maintainability defects leave these gaps under-tested or permit the one-shot contract to drift.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01 — BLOCKER: Shipped fixture API can forge a production-shaped terminal pass report

**File:** `/Users/jon/projects/mailglass/scripts/mailglass_finalize_milestone_loader.mjs:432-464`

**Also affected:** `/Users/jon/projects/mailglass/scripts/finalize_milestone_v2_7.sh:132-145`, `/Users/jon/projects/mailglass/test/scripts/phase_165_milestone_finalizer_test.exs:650-669`

**Issue:** `runFixtureFinalization/1` is exported by the same module that is installed as the production command. It accepts caller-supplied `ciRuns`, `scheduleRuns`, `expectedScheduleNames`, `tools`, and output path, then sets `MAILGLASS_MILESTONE_FIXTURE=1`. The shell uses that unauthenticated flag to skip branch, canonical-origin, fetch, and `HEAD == origin/main` enforcement. The resulting report still has schema `mailglass-finalize-milestone-report-v1` and `status: "pass"`, with no fixture marker. Any local caller can therefore import the repository or installed loader, supply fabricated attempt-1 records for the current OID, and create terminal evidence indistinguishable from the protected GitHub path. The happy-path test demonstrates this exact caller-selected evidence route.

**Fix:** Remove the fixture bypass from the shipped loader/finalizer. Put fixture orchestration in a test-only module that cannot emit the production schema. Production shell checks should be unconditional:

```bash
branch=$($MAILGLASS_GIT -C "$repo" branch --show-current)
[ "$branch" = main ] || fail "canonical checkout is not on main"
$MAILGLASS_GIT -C "$repo" fetch origin main
[ "$($MAILGLASS_GIT -C "$repo" rev-parse refs/remotes/origin/main)" = "$expected_oid" ] ||
  fail "HEAD does not equal origin/main"
```

If fixture execution must share code, return a distinct `mailglass-finalize-milestone-fixture-v1` document that can never carry `status: "pass"`, and make the production report writer reject fixture mode.

### CR-02 — BLOCKER: Terminal mode never authenticates the executable that is actually running

**File:** `/Users/jon/projects/mailglass/scripts/mailglass_finalize_milestone_loader.mjs:479-505`

**Also affected:** `/Users/jon/projects/mailglass/scripts/mailglass_finalize_milestone_loader.mjs:536-559`, `/Users/jon/projects/mailglass/test/scripts/phase_165_milestone_finalizer_test.exs:379-387`

**Issue:** A byte-comparison self-check exists, but `finalizeMilestone()` never calls it or otherwise binds `import.meta.url` to the approved loader blob/destination. The controlled-host test only uses `File.regular?/1` (which follows symlinks) and checks attacker-controlled `--version` text. A symlink or replacement executable that prints that string passes the installed boundary, and terminal mode then runs without any independent approved-digest check. This contradicts T-165-04-T01 and the Plan 04 claim that installed bytes are proved at the boundary.

**Fix:** Make the controlled-host gate lstat the exact canonical destination, reject symlinks, verify mode/owner, hash the installed bytes, compare them with the approved commit blob, and only then invoke terminal mode. Also bind the running path and digest into the report. For example:

```javascript
const executableLexical = fileURLToPath(import.meta.url);
const executable = realpathSync(executableLexical);
if (executableLexical !== INSTALLATION_DESTINATION || executable !== INSTALLATION_DESTINATION) {
  fail("terminal executable is not the approved installation destination");
}
const approved = authenticated.find((entry) => entry.path === SOURCE_PATH)?.contents;
if (!approved || !readFileSync(executable).equals(approved)) fail("installed-byte mismatch");
```

The external test must exercise this exact path, not merely `--version`, and include real-path symlink and byte-tamper negative controls.

### CR-03 — BLOCKER: “Trusted runtime closure” binds paths, not executable identity, and leaves PATH shadowing open

**File:** `/Users/jon/projects/mailglass/scripts/mailglass_finalize_milestone_loader.mjs:93-126`

**Also affected:** `/Users/jon/projects/mailglass/scripts/mailglass_finalize_milestone_loader.mjs:334-350`, `/Users/jon/projects/mailglass/scripts/finalize_milestone_v2_7.sh:27-86`

**Issue:** `validateTrustedToolchain()` checks only absolute path, regular-file type, owner, and group/world write bits. It permits user-owned, owner-writable executables and never records or verifies tool SHA-256/version. The installation proposal's `runtime_closure` contains only `{name, path}`, despite the Plan 04 and security records claiming versions and digests. Worse, `buildChildEnvironment()` places user-owned tool directories before `/usr/bin` and `/bin`, while the shell invokes bare `awk`, `grep`, `sed`, `basename`, `mktemp`, `chmod`, `mv`, and `rm`. A shadow executable in an earlier directory can bypass audit validation, alter the report, or execute arbitrary code even though Git/JQ paths are pinned.

**Fix:** Pin and revalidate content digest plus expected version for every executable at proposal, self-check, and terminal invocation. Do not put user-writable directories on the shell lookup path; invoke every shell utility by a validated absolute path or use a minimal system-only path:

```javascript
env.PATH = "/usr/bin:/bin";
runtime_closure: Object.entries(tools).map(([name, path]) => ({
  name,
  path,
  sha256: sha256(readFileSync(path)),
  version: probeVersion(name, path),
}))
```

Reject digest/version drift before any GitHub query or report write, and add a negative test that shadows `grep`/`mktemp` in an earlier directory.

### CR-04 — BLOCKER: Audit and lifecycle semantics are accepted by substring presence

**File:** `/Users/jon/projects/mailglass/scripts/finalize_milestone_v2_7.sh:41-79`

**Issue:** Only `status` and `audited_head` are parsed from frontmatter. The four audit scores and policy-debt disposition use unrestricted `grep -F`, and STATE/PROJECT/MILESTONES are similarly accepted if words occur anywhere. An audit with authoritative `requirements: 15/16` can still pass by containing prose such as “expected requirements: 16/16”; `STATE.md` saying “v2.7 is not archived” also satisfies the current `archived` check. The report then hardcodes all audit components to pass. This is not the exact semantic validation promised by T-165-05-T01.

**Fix:** Parse the canonical structured fields, reject duplicate keys, and compare exact values. At minimum, use the existing frontmatter parser for all scores:

```bash
[ "$(frontmatter_value "$audit" requirements)" = "16/16" ] || fail "..."
[ "$(frontmatter_value "$audit" phases)" = "5/5" ] || fail "..."
[ "$(frontmatter_value "$audit" integration)" = "16/16" ] || fail "..."
[ "$(frontmatter_value "$audit" flows)" = "5/5" ] || fail "..."
```

Prefer one strict YAML/JSON parser for the complete audit/lifecycle contract, and add hostile fixtures that retain the expected token in explanatory prose while changing the authoritative field.

### CR-05 — BLOCKER: Lexical path checks allow symlinked parent traversal before rejection

**File:** `/Users/jon/projects/mailglass/scripts/mailglass_finalize_milestone_loader.mjs:311-359`

**Also affected:** `/Users/jon/projects/mailglass/scripts/mailglass_finalize_milestone_loader.mjs:548-549`

**Issue:** `safePredecessor()` lstat-checks only the final destination component. If `/Users/jon/.local/bin` is a symlink, an absent destination is approved as `create` without authenticating where it resolves. Similarly, `finalizeMilestone()` lexically resolves `repo/tmp/...` and calls `mkdirSync` before the shell canonicalizes the report parent. An ignored `tmp` symlink can therefore make the command create its report directory outside the repository before the later boundary check fails. This violates the exact installation destination and ignored-only output boundaries.

**Fix:** Authenticate every existing parent component with `lstat`, reject symlinks, and compare the physical parent against the approved physical root before any mkdir/write. Create the report directory through a verified parent and re-check it after creation:

```javascript
const tmpRoot = resolve(repo, "tmp");
const tmpEntry = lstatSync(tmpRoot);
if (!tmpEntry.isDirectory() || tmpEntry.isSymbolicLink() || !inside(repo, realpathSync(tmpRoot))) {
  fail("report root is not a physical repository directory");
}
```

Apply the same rule to `dirname(INSTALLATION_DESTINATION)` and add intermediate-parent symlink fixtures for both boundaries.

## Warnings

### WR-01 — WARNING: Restoration-failure test permits the config to remain modified and the recovery copy to disappear

**File:** `/Users/jon/projects/mailglass/test/scripts/phase_165_milestone_finalizer_test.exs:364-376`

**Issue:** The restoration-failure case checks only a diagnostic and absence of `--confirm`; unlike the other cases, it never asserts that `restoration.config` equals `restoration.original`. The extracted runbook cleanup deletes its temporary directory even when restoration fails, so this test currently accepts the dangerous state where `.planning/config.json` remains overridden and the only original-byte backup is removed. That makes the claimed exact-restoration negative control unreliable.

**Fix:** Assert exact bytes after every failure, including restoration failure, and make cleanup retain/report the recovery file until restoration succeeds:

```elixir
assert File.read!(restoration.config) == restoration.original
refute File.read!(restoration.log) =~ "--confirm"
```

Add a failure-after-confirm fixture as well, because that is the point where leaving `git.create_tag=false` behind is most consequential.

### WR-02 — WARNING: The named Node report boundary is dead code while production uses a second implementation

**File:** `/Users/jon/projects/mailglass/scripts/mailglass_finalize_milestone_loader.mjs:362-378`

**Issue:** `writeTerminalReport()` is exported and asserted by name, but no production or test call uses it. The actual report is written independently in Bash. The two boundaries already differ in path handling, temporary-file naming, and parent assumptions, so future hardening of the named function will not protect production. The current test only checks that its source name exists.

**Fix:** Route production through one report writer and behavior-test tracked, ignored, symlink-parent, existing-target, and late-mutation cases. If Bash must own the atomic write, remove the unused Node export and test the Bash boundary directly.

### WR-03 — WARNING: CI parity “bijection” assertion is tautological

**File:** `/Users/jon/projects/mailglass/test/scripts/ci_parity_drift_test.exs:239-244`

**Issue:** Both `known` and `matcher_lanes` are constructed from the same `lanes` list, so `MapSet.difference(matcher_lanes, known)` is always empty. The asserted stale-matcher direction can never fail and does not prove the advertised bijection.

**Fix:** Maintain an independently enumerable matcher-key set (or return `{lane, matcher}` entries from one explicit table) and compare that set with the policy lane set. Add a negative control containing a stale matcher key and assert it is reported.

### WR-04 — WARNING: The one-terminal-invocation hard stop is procedural only

**File:** `/Users/jon/projects/mailglass/scripts/mailglass_finalize_milestone_loader.mjs:536-562`

**Issue:** Every invocation creates a new random report directory, and neither the loader nor finalizer checks for an existing terminal receipt for the same milestone/SHA. The command can therefore be rerun indefinitely, producing multiple pass reports despite the Plan 01/05 one-shot and “no report rewrite” contract. There is no test for a second invocation.

**Fix:** Use an authenticated deterministic receipt/lock keyed by milestone and authority OID with exclusive creation, or maintain a separately approved host-side one-shot record. Reject a second invocation before GitHub queries and add a two-call negative test.

---

_Reviewed: 2026-09-13T20:05:16Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
