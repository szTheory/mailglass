---
phase: 183-docs-packaging-and-launch-prep
plan: "03"
subsystem: testing
tags: [exdoc, playwright, mix, ci, brand-docs]

requires:
  - phase: 183
    provides: Three-package ExDoc brand checks and native theme assertions from plan 01
provides:
  - A serial docs validation script that builds core, Admin, and Inbound into one owned temporary root
  - A standalone real-output contract and explicit output-root browser selection
  - Required Docs Warnings as Errors CI wiring for all three locked dev dependency sets
affects: [BRDOC-01, BRDOC-02, docs-ci, clean-checkout-tests]

actuals:
  tokens: 10026
  tasks: 2
  commits: 4
  plan_head_before: 7d8a15bbf12b1519787869f97f24e3aa521c6263
  plan_head_after: 250d7feede1295fe3e88770a34080f5d3b9056e6

tech-stack:
  added: []
  patterns:
    - Explicit generated-output roots shared by the ExUnit output contract and browser check
    - Serial docs builds with cleanup limited to a unique owned temporary directory

key-files:
  created:
    - ci/contracts/brand_docs_output_test.exs
    - scripts/verify_brand_docs.sh
    - test/scripts/brand_docs_ci_wiring_test.exs
    - .planning/phases/183-docs-packaging-and-launch-prep/183-03-task1-red-evidence.json
  modified:
    - test/scripts/brand_docs_contract_test.exs
    - mailglass_admin/e2e/docs-theme-contract.cjs
    - mailglass_admin/e2e/docs-theme-contract.test.cjs
    - .github/workflows/ci.yml

key-decisions:
  - "Keep fixture and source assertions in default root tests; run actual generated-output checks from ci/contracts with an explicit root."
  - "Build each package once in the existing required docs job and reuse that output for the ExUnit contract and optional local browser mode."
  - "Preserve the Chromium launch failure and leave native-theme/layout behavior unverified; no download or second browser attempt was made."

patterns-established:
  - "The output-root CLI validates every selected README before launching Chromium and keeps legacy package selection."
  - "The required docs job retains its existing identity and CI Green edge while installing locked dev dependencies for all packages."

requirements-completed: [BRDOC-01, BRDOC-02]
coverage:
  - id: D1
    description: Default root brand docs tests run source and fixture checks without generated checkout docs.
    requirement: BRDOC-02
    verification:
      - kind: unit
        ref: "mix test test/scripts/brand_docs_contract_test.exs --warnings-as-errors --seed 0"
        status: pass
    human_judgment: false
  - id: D2
    description: Fresh core, Admin, and Inbound docs pass the explicit-root real-output contract.
    requirement: BRDOC-02
    verification:
      - kind: integration
        ref: "Generated outputs from verify_brand_docs.sh passed MIX_ENV=dev mix run --no-start ci/contracts/brand_docs_output_test.exs before the browser launch step."
        status: pass
    human_judgment: false
  - id: D3
    description: Native theme switching and 375px layout are verified for all three generated packages.
    requirement: BRDOC-01
    verification:
      - kind: automated_ui
        ref: "scripts/verify_brand_docs.sh --browser; Chromium failed at launch before scenarios"
        status: unknown
    human_judgment: true
    rationale: The installed Chromium process failed at macOS bootstrap registration before any package page opened, so the theme and layout assertions did not run.
  - id: D4
    description: The required docs job invokes the all-package checker and remains required by CI Green.
    requirement: BRDOC-02
    verification:
      - kind: unit
        ref: "mix test test/scripts/brand_docs_ci_wiring_test.exs test/scripts/brand_docs_contract_test.exs test/scripts/required_checks_test.exs test/scripts/ci_parity_drift_test.exs test/scripts/lane_classification_drift_test.exs --warnings-as-errors --seed 0"
        status: pass
    human_judgment: false
  - id: D5
    description: The unchanged default root test suite passes with generated README outputs absent.
    verification:
      - kind: unit
        ref: "mix test --warnings-as-errors"
        status: fail
    human_judgment: false

duration: 28min
completed: 2026-11-17
status: halted
---

# Phase 183 Plan 03: Clean Docs Output and CI Gate Summary

**Three-package ExDoc verification now builds into an owned temporary root and runs behind the existing required Docs Warnings as Errors check.**

## Performance

- **Duration:** 28 min
- **Started:** 2026-11-17T03:02:20Z
- **Completed:** 2026-11-17T03:30:13Z
- **Tasks:** 2 executed
- **Implementation files:** 7 declared files

## Accomplishments

- Removed the generated-output test from default root discovery while keeping all fixture and README source assertions active.
- Added a standalone ExUnit contract that requires `MAILGLASS_DOCS_OUTPUT_ROOT` and checks exactly the core, Admin, and Inbound outputs.
- Added `scripts/verify_brand_docs.sh` to build the three packages serially into one unique temporary directory, run the output contract once, optionally run the browser checker against those same pages, and remove only that directory on exit.
- Added pure browser CLI/path helpers for `--output-root`, fail-closed README validation before Chromium launch, and guarded module execution so node tests do not launch a browser.
- Wired the existing required docs job to locked dev dependencies for all three packages and the new validation script. The job name, timeout, gate, core guide check, and CI Green edge remain intact.

## Verification Results

| Check | Result | Evidence |
|---|---|---|
| Browser CLI/path tests | **Pass** | 5 tests passed; missing package output fails before Chromium launch. |
| Root source/fixture contract | **Pass** | 4 tests passed with generated docs absent. |
| Missing standalone output root | **Pass, fail-closed control** | Command exited 1 with `MAILGLASS_DOCS_OUTPUT_ROOT must name an existing generated docs output root`. |
| Three docs builds and real-output contract | **Pass** | Core build 2s, Admin 1s, Inbound 1s, output contract 1s; one ExUnit output test passed. |
| Native theme and narrow layout browser behavior | **Blocked** | The installed Chromium launched its process then SIGTRAPed at `bootstrap_check_in org.chromium.Chromium.MachPortRendezvousServer` with macOS permission denied (1100), before any package page or scenario ran. Behavior is **not verified**. |
| CI wiring, required-check, and lane parity contracts | **Pass** | 85 tests passed, 0 failures; the final focused wiring test also passed 2 tests. Mutations removing the script call, Inbound dependency step, or CI Green edge were rejected. |
| Full default root suite | **Fail** | 2,448 tests, 7 failures, 27 excluded, 7 skipped; the suite floor reported 2,437 executed and 7 failures. See the exact failures below. This is not a green result. |
| Script syntax and whitespace | **Pass** | `bash -n scripts/verify_brand_docs.sh` and `git diff --check`. |

The three checkout paths `doc/README.html`, `mailglass_admin/doc/README.html`, and `mailglass_inbound/doc/README.html` were absent before the full root command. The one docs script run removed its unique temporary output directory after the browser launch failure; the Chromium PID exited. No browser was downloaded, no screenshot or favicon capture was made, and no remote CI was dispatched.

Admin docs preserved the existing hidden-link and cross-package warnings, including hidden references to `Mailglass.Operator.Deliveries.get_delivery/2`, `Mailglass.Operator.Timeline.get_delivery_event/3`, and internal Admin modules. Inbound docs preserved its existing hidden-reference warnings and missing compatibility-guide links from its README and routing guide. Core docs passed with `--warnings-as-errors`. These warnings were recorded without expanding the plan into documentation repairs.

### Full Root Suite Failures

Each failure below is from an unmodified test or artifact outside this plan's seven implementation files. The attribution of these failures as pre-existing is **unverified**; no baseline rerun or out-of-scope repair was performed.

1. `Mailglass.Scripts.TestExceptionsContractTest` — “registry is bidirectional and unexpired” at `test/scripts/test_exceptions_contract_test.exs:13`; it reports `test/mailglass/docs_contract_test.exs:807` versus `:826`.
2. `Mailglass.Scripts.BrandStatusMarksTest` — “the committed brandbook/status-marks.json names the same zip the brand pin pins” at `test/scripts/brand_status_marks_test.exs:301`; the recorded ZIP SHA differs from the pin.
3. `Mailglass.ReferenceHost.PublicSeamsContractTest` — “reference host wiring stays on stable public seams only (HOST-02)” at `test/reference_host/public_seams_contract_test.exs:10`; a required public-seam sentence is missing.
4. `Mailglass.Scripts.Phase164RepositoryTruthTest` — “git runtime rules do not conceal the retired finalize-phase extension paths” at `test/scripts/phase_164_repository_truth_test.exs:261`; the retired extension path is considered ignored.
5. `Mailglass.Scripts.Phase164CloseoutTest` — “owned sibling cleanup refuses pre-existing and token-replaced paths” at `test/scripts/phase_164_closeout_test.exs:2042`; fixture creation under `/Users/jon/projects/` failed with `not owner`.
6. `Mailglass.Scripts.Phase164CloseoutTest` — “phase 164 gap closure rejects alternate repository identities before evidence collection” at `test/scripts/phase_164_closeout_test.exs:856`; sibling fixture allocation under `/Users/jon/projects/` failed with `:eperm`.
7. `Mailglass.Scripts.Phase164CloseoutTest` — “rejects a sibling checkout and a foreign symlink before component collection” at `test/scripts/phase_164_closeout_test.exs:177`; sibling fixture allocation under `/Users/jon/projects/` failed with `:eperm`.

The final three errors directly report this sandbox's inability to create those paths outside the workspace writable root. The other four also have no overlap with files changed by this plan, but their baseline status remains unverified.

## CI Efficiency Notes

No hosted CI run was authorized or observed for this candidate, so candidate runner time and savings are unmeasured. The `183-01` historical run recorded the core-only docs job at 91s, Installer Host Smoke at 356s, and the advisory browser lane still running after 528s; those are unrelated historical measurements. The supported improvement is structural: generic root test processes no longer build three docs trees, and the required docs job builds each package once and reuses those outputs for validation. No runner-minute savings are claimed.

## Task Commits

1. **Task 1 RED:** `861961b8` — failing output-root and pre-launch validation regressions.
2. **Task 2 RED:** `385c2789` — required docs job and CI wiring regression tests.
3. **Task 1 implementation:** `714b1260` — standalone output contract, temporary build script, and explicit browser output roots.
4. **Task 2 implementation:** `250d7fee` — locked three-package dependencies and required docs-job invocation.

## Files Created/Modified

- `ci/contracts/brand_docs_output_test.exs` — standalone real-output contract.
- `scripts/verify_brand_docs.sh` — serial package builds, output validation, optional local browser check, and owned-temp cleanup.
- `mailglass_admin/e2e/docs-theme-contract.cjs` and `.test.cjs` — explicit output-root selection and fail-closed tests.
- `test/scripts/brand_docs_contract_test.exs` — retains only checkout-independent fixture/source tests.
- `test/scripts/brand_docs_ci_wiring_test.exs` and `.github/workflows/ci.yml` — structural contract and required CI integration.
- `.planning/phases/183-docs-packaging-and-launch-prep/183-03-task1-red-evidence.json` — machine-checked TAP RED evidence.

## Decisions Made

- Kept actual generated-output checks outside default root test discovery; the normal suite continues to run source and fixture checks.
- Kept the required CI gate matrix-free and reused each build output rather than introducing another job, browser setup, dependency, or artifact transfer.
- Preserved the single browser launch failure as a limitation. The browser assertions did not run, so this summary does not claim the theme or 375px behaviors passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Report browser elapsed time when the browser command fails**
- **Found during:** Task 1 verification.
- **Issue:** The first script version printed the browser duration only after success, hiding timing on a failed launch.
- **Fix:** The script now prints elapsed time and exit code on browser failure before returning the same failure status.
- **Files modified:** `scripts/verify_brand_docs.sh`.
- **Verification:** `bash -n scripts/verify_brand_docs.sh`; no second browser run was made.
- **Committed in:** `714b1260`.

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** The failure remains visible and the script now reports its timing; no verification boundary was weakened.

## Issues Encountered

- Chromium was installed at the requested pinned path but could not start in this environment because macOS denied its Mach port bootstrap registration. The one browser attempt ended before any theme/layout scenario. No download or retry was made.
- The unchanged full root suite failed in seven tests. Their names, first failure locations, and observed causes are listed above; baseline attribution is unverified.
- Admin and Inbound docs emitted existing hidden-link and cross-package warnings; builds succeeded and the warnings were not broadened into unrelated fixes.
- The optional `WINDOWS.md` unrun-verify append was refused because its existing rendered table disagrees with fenced JSON row 48. No manual edit was made to that cross-phase ledger.

## User Setup Required

None for the implemented CI wiring. The browser behavior gate remains unresolved in this execution and needs orchestration-level reconciliation before any further browser attempt.

## Next Phase Readiness

The clean-checkout wiring is implemented and its focused contracts pass. This plan is **halted for verification**, not reported complete: the required full-root command failed and native theme/layout behavior could not be exercised. No hosted CI was dispatched. The orchestrator should reconcile those two gates and decide whether a new local browser run is authorized after the launch restriction is addressed.

## Threat Flags

None. The changes add no network endpoint, auth path, schema change, or filesystem access beyond the owned temporary docs directory.

## Self-Check: PASSED

- All created artifacts listed above exist.
- All four task commit hashes are ancestors of HEAD.
- `git diff --check` passes for the final planning edits.
- The halted plan status remains explicit; browser behavior and the full root suite are not reported as passed.

---
*Phase: 183-docs-packaging-and-launch-prep*
*Completed: 2026-11-17*

## Corrected Docker Gate Follow-up — 2026-11-17

This section supersedes the earlier statements that the Docker browser path had not run or that another browser attempt was unauthorized. The owner later authorized continued browser runs.

The first corrected full gate confirmed the container-to-host route but exposed three browser failures. Chromium reached the container's 128-process cap during persistent-context launches, and Fontconfig tried read-only cache locations. Raising the bounded cap to 512, placing its cache under the existing writable `/tmp`, and keeping the same 2 GB / 2 CPU limits fixed those launch failures. A second full gate then passed 36 of 37 browser cases; the remaining Axe baseline case reproduced in isolation.

The Playwright trace showed Axe's partial-frame collector timing out while walking the preview's script-sandboxed `srcdoc` frame. The timeout closed the test context before Axe's cleanup page was created. The preview baseline check now uses Axe legacy mode with the same WCAG 2.2 AA tags. An isolated Docker run passed in all three themes and matched the committed baseline.

The final full gate used the pinned Playwright 1.65.1 image, fixed `BROWSER_SERVER_PORT=51130`, and zero Playwright retries. Results: Storybook 42 passed; Core 81 passed; Admin 1,817 passed with 1 excluded; Inbound 481 passed with 3 excluded; browser 37 passed. The last full run took 67.94 seconds; the browser lane took 25.1 seconds and Admin was the longest non-browser lane at 31.6 seconds. After the reviewer identified and we fixed a DNS-resolution timeout gap in the preflight, this exact gate ran again and passed. The authoritative hash-verified output is `/private/tmp/mailglass-183-regression-gate-verified.log` (`c46260e67e60866f3e68dec5bb24211bbbe8771b6d81f37a77f774269f600c3c`).

During diagnosis, a temporary all-interface bind was tried. A cheap Docker Desktop probe then proved the container can reach a host listener bound only to `127.0.0.1`, so the broader bind was removed before the final full gate. The Admin test now asserts loopback binding, and the gate probes the actual container-to-host readiness route before launching Chromium. The task-created browser containers were removed automatically, the host server stopped, port 51130 was clear afterward, and the existing `mailglass-demo` containers remained running. No hosted CI was dispatched.

The previously recorded default root suite result remains **2,448 tests, 7 failures, 27 excluded, and 7 skipped**. The owner selected preserve-and-continue; that suite was not rerun, and its remaining failures stay outside this phase's scope. The pre-UAT-conversion verifier state is superseded by the Shift-Left Verification Follow-up below.

## Shift-Left Verification Follow-up — 2026-11-17

The owner reaffirmed D-52: target zero human UAT and reconcile verifier hand-offs against current-source evidence before stopping. The two former UAT items now have automated evidence, and the verification report passes 20/20 without claiming that unpublished external pages were observed.

- README source contracts cover all three package headers, pinned light/dark assets, renderer-specific fragments, lowercase fallback alt text, and responsive image rules. The final three-package ExDoc browser check already passed both native themes and the 375 px geometry/no-overflow assertions. UAT records both checks as `source: automated`; the live GitHub and Hex.pm pages are explicitly unobserved because this candidate is unpublished, and are not an owner UAT gate.
- The favicon producer now exports the same `captureAndSaveTile` helper used by its production capture loop. Its browser-free Node test gates image decoding and confirms that screenshotting waits for decode and frame settling, while saving waits for the existing PNG validation callback. The existing catalog validator keeps `safariTabChromeObserved: false`; no additional favicon capture ran.
- The fast test runs immediately after Node setup in the existing operator-browser CI job, before Mix dependencies, npm browser dependencies, or browser installation. It passed locally in under 100 ms, uses only Node built-ins, and adds no browser launch or dependency. `actionlint`, both Node syntax checks, the source pin `--check`, and `git diff --check` passed; hosted CI was not dispatched.
- `.planning/METHODOLOGY.md`, `.planning/AUTONOMOUS-PLAYBOOK.md`, `.planning/PROJECT.md`, and the local root `AGENTS.md` now state the verifier-reconciliation rule, cheap-preflight order, human-only boundary, and CI/release efficiency review. This makes the lesson discoverable without reopening this UAT.

GSD UAT completed with 2/2 automated passes, `verification.status` returned `passed`, and the shared `phase uat-passed 183 --require-verification` predicate reported no blockers. The root suite remains at its previously recorded seven failures and was not rerun. No release or publication occurred.
