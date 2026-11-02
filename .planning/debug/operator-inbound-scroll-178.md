---
status: resolved
trigger: "Phase 178 hosted CI Operator Browser Gate timed out on the Phase174 inbound quick-view scroll access test."
created: 2026-11-02
updated: 2026-11-02
---

# Debug Session: operator-inbound-scroll-178

## Symptoms

- **Expected behavior:** Inbound quick view can scroll through overflowing content with PageDown and End while keyboard focus remains on the dialog; navigation controls at both boundaries stay disabled.
- **Actual behavior:** Hosted CI run `41376300645`, attempt 1, failed the Operator Browser Gate at `mailglass_admin/e2e/flows.spec.js:2466:3` because the final-scroll predicate timed out after 5 seconds (`expected true, received false`).
- **Error messages:** `Phase174 scroll access: Inbound overflow is keyboard reachable and both navigation boundaries are disabled`; assertion expects `scrollTop + clientHeight >= scrollHeight - 1`, but it remains false after `End`.
- **Timeline:** First observed in the Cycle 02 PR validation on candidate `a0a7450cc68afe84e25e69276c654d9e63422499` (2026-11-02). The matching inbound scroll test passed or had not been reported before this run; the hosted failure is the first evidence.
- **Reproduction:** `cd mailglass_admin && npx playwright test --config=playwright.config.cjs --workers=1 e2e/flows.spec.js:2466`, strictly local. Do not push, dispatch workflows, rerun hosted checks, update the PR, or launch the preview.

## Constraints

- At the beginning of this debug session the candidate was `a0a7450cc68afe84e25e69276c654d9e63422499`. Plan 28 later authorized Cycle 04 for candidate `8e501960bc975ed44b632ba5c74522e0c5d66f8c`; its hosted operations and one conditional preview attempt are now consumed. Do not start another run or launch.
- No merge/release/deploy/publish or further PR, push, workflow, or preview operation is authorized by Cycle 04.
- Preserve the dirty workspace. Restrict any fix to the failing inbound quick-view scroll behavior or its demonstrably incorrect test contract; do not stage or revert unrelated files.
- User approved all local diagnostic recommendations. Provision only the existing lockfile-pinned artifacts inside a disposable local container for a controlled Linux reproduction; do not modify repository dependency declarations or locks.
- User's `approve-all` also authorizes one bounded local AMD64 browser comparison using already pinned Chromium/Playwright versions. Use disposable resources only; do not incur paid-service costs or pull an oversized full CI image. Remove test-specific containers, volumes and networks afterward.

## Current Focus

assessment: local fix accepted by applicable guardrail signals and exact-SHA hosted Operator Browser Gate passed; Cycle 04 preview remains blocked by a separate login-route 302
hypothesis: the helper sends End after PageDown has moved but before native PageDown completion; Chromium can ignore End at that late animation transition, leaving the prior page-scroll offset
bug_class: heisenbug-mandelbug (timing dependent; native completion-boundary and actual-helper local reproductions now available)
test: completed exact-helper boundary reproduction before/after/revert/reapply and both real production scroll-access regressions with bounded repeats
expecting: the native PageDown completion barrier prevents End from arriving in the observed animation-transition interval while preserving the original accessibility contract
next_action: return the narrow locally verified helper diff for review; preserve the hosted stop and frozen candidate. A future authorized hosted validation must confirm the original workflow before this session can be resolved. Do not run, push, publish, or ask merely to keep the stop in place.
runtime_note: ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27; local Chromium required approved sandbox escalation for macOS Mach port registration
candidate_causes:
  - code/test: confirmed — scrollTop > 0 only establishes movement and permits a second native key before PageDown completion
  - environment/browser: confirmed locally — Chromium can ignore End at the late native PageDown animation boundary; hosted timing is consistent
  - code: application cancellation and focus loss ruled out as necessary by the application-free reproduction
  - data/layout: dynamic or fractional geometry ruled out as necessary by the static fixed-size reproduction
and_gate: yes — an early movement-only test barrier plus End arriving in Chromium's late animation-completion interval are both required; Linux architecture and LiveView are not required by the minimal reproduction
reasoning_checkpoint:
  hypothesis: the test races two native keyboard scrolls because scrollTop > 0 proves movement, not completion; End can be ignored at Chromium's PageDown completion boundary
  confirming_evidence:
    - standalone pinned Chromium with no LiveView or application handlers ignored End in 2/24 timing cases and 5/24 reconfirmation cases; focus stayed on the scroll container and defaultPrevented was false
    - failing local End arrived 1–5 ms before PageDown scrollend; hosted attempt-2 End arrived 166.5 ms after PageDown with offset 629→630 and no further movement
    - arming scrollend before PageDown and awaiting it produced 24/24 bottom-scroll successes across adjacent 140/150/160/170 ms timings
  falsification_test: if the actual helper still fails after native PageDown scrollend is observed, or if the unchanged helper cannot reproduce at the same completion interval, revisit the proposed synchronization fix
  fix_rationale: wait for the first keyboard gesture to complete before exercising the second; preserve native PageDown, native End, focus assertions, axe coverage and the exact bottom predicate without programmatic scroll, retry or timeout changes
  blind_spots: no hosted execution is authorized; an event-based local fix cannot establish exact frozen-candidate hosted approval or repair Chromium's behavior for real rapid overlapping keys
  candidate_causes:
    - code/test — scrollTop > 0 is an incomplete PageDown completion barrier
    - environment/browser — Chromium drops End at the native scroll animator completion boundary
    - data/layout — removed as necessary cause by a static fixed-size scroll container
  and_gate: yes — incomplete sequencing plus the late browser animation interval; native scrolling alone normally succeeds

## Evidence

- timestamp: 2026-11-02
  checked: single-hunk revert/reapply, final bounded real regression and source-integrity review
  found: removing the hunk restored flows.spec.js exactly to HEAD and the same actual-helper timing harness failed 3/12 cases (/private/tmp/mailglass-scroll178-helper-reverted.log). Reapplying it yielded 12/12 passes (/private/tmp/mailglass-scroll178-helper-reapplied.log), with every End occurring after PageDown scrollend. Final real inbound and delivery tests repeated three times each passed (6 passed, 15.8s, workers=1, retries=0; /private/tmp/mailglass-scroll178-target-final.log). node --check, git diff --check and unchanged product/config/dependency diffs pass. The only nonplanning diff is 13 added lines in flows.spec.js; nothing was staged or committed.
  implication: local target, held-out sibling and revert/reconfirm guardrail signals accept the test synchronization fix. Mutation testing is explicitly skipped because Stryker is absent/unconfigured. Existing axe/focus/native key/bottom/navigation assertions remain intact; no timeout or retry increase, programmatic scroll, product behavior change, hosted action or remote mutation occurred. Session awaits a future authorized original-environment verification, not a routine acknowledgment.

- timestamp: 2026-11-02
  checked: interpretation of prior eliminated overlapping-input hypothesis and pinned Chromium implementation
  found: prior probes only proved that overlapping PageDown and End does not always fail; they did not sample the final animation interval. New static native and exact-helper reproducers fail specifically in that interval. Attempt-2 original and retry send End 166.543 ms and 179.723 ms after PageDown respectively, near the final 629/630 pixel update. Chromium 147.0.7727.15 source maps PageDown to page-granularity relative scrolling and End to document-granularity absolute scrolling, and explicitly separates keyboard scroll completion from keyup.
  implication: supersedes the earlier local nonreproduction inference, without erasing its history. The precise Chromium internal fault is not patched or claimed located; the confirmed local root cause is missing test synchronization across two native scrolls. Primary implementation references: https://chromium.googlesource.com/chromium/src/+/147.0.7727.15/third_party/blink/renderer/core/input/keyboard_event_manager.cc and https://chromium.googlesource.com/chromium/src/+/147.0.7727.15/third_party/blink/renderer/core/input/scroll_manager.cc (saved read-only under /private/tmp/mailglass-scroll178-*.cc).

- timestamp: 2026-11-02
  checked: changed exact-helper timing reproducer and real production quick-view browser tests
  found: /private/tmp/mailglass-scroll178-helper-after.log records 12/12 passes at the same boundary timings; every End keydown occurs after the native PageDown scrollend. The authorized targeted command for both Phase174 scroll access tests passed in 7.4s with workers=1 and retries=0. Both original accessibility contracts and navigation boundary checks executed. node --check and git diff --check also pass.
  implication: the completion event repairs the observed sequencing defect locally. Revert/reapply the single hunk and repeat the minimal harness before accepting; hosted outcome remains unverified and the hosted stop remains in force.

- timestamp: 2026-11-02
  checked: original assertPhase174QuickViewScrollAccess extracted unchanged from flows.spec.js and executed with real axe and Playwright on a minimal static dialog
  found: /private/tmp/mailglass-scroll178-helper-before.log records 6/12 failures across 145/150/155/160 ms PageDown-to-End timings. Failing probes retain dialog focus and leave scrollTop at the native PageDown endpoint while End occurs before scrollend. The initial diagnostic setup used browser.newPage(), which cannot support axe's extra page, and was corrected to an explicit browser context before collecting this result; that setup failure is excluded.
  implication: the exact shared helper, including axe, focus and original bottom predicate, catches the same browser-level race locally. Applied only a prearmed scrollend listener and a bounded completion poll before End. No product markup, CSS, keyboard bindings, timeouts, retries or assertion predicates changed.

- timestamp: 2026-11-02
  checked: bounded standalone native-scroll timing sweep and one-variable completion-wait comparison
  found: /private/tmp/mailglass-scroll178-native.log reproduces 2 ignored End presses in 24 cases; /private/tmp/mailglass-scroll178-native-reconfirm.log reproduces 5/24. Failing probes retain dialog focus and record defaultPrevented=false for both keys; End follows the final movement and precedes PageDown scrollend by a few milliseconds. The 24-case /private/tmp/mailglass-scroll178-native-settled.log comparison waits for native scrollend, and all cases reach scrollTop 1461 + clientHeight 720 = scrollHeight 2181. No LiveView, custom keyboard handler, server, external network or dynamic layout is present.
  implication: minimal reproduction isolates a browser animation-completion timing interaction, rather than Linux, LiveView, focus loss or data. The test's early movement poll permits overlapping inputs. Waiting for the native completion event is a narrow test synchronization remedy; it does not change product accessibility semantics. Shrinking framework and Stryker are not configured; manual minimization and bounded boundary timing samples are used without adding dependencies.

- timestamp: 2026-11-02
  checked: attempt-2 original trace input sequence and complete production input handlers, CSS, quick-view markup and shared test helper
  found: PageDown starts at trace time 94915.650 ms; End starts at 95082.193 ms (166.543 ms later). Dialog scrollTop is 553 at 95050.139, 608 at 95063.484, 629 at 95080.658 and 630 after End, then remains 630. End generates and clears the same LiveView loading attributes as PageDown. The global application listener prevents only Arrow defaults; ModalFocusTrap listens only to focusin; detail_key ignores PageDown/End; the dialog uses overflow-y:auto and overscroll-behavior:contain. The existing test deliberately requires real native PageDown movement and exact End-to-bottom access, so replacing it with programmatic scrolling would weaken its contract.
  implication: focus loss and direct application cancellation remain contradicted. Prior early-scroll probes did not specifically sweep the late animation transition seen here; run one bounded standalone timing sweep without product edits. Chromium sandbox-only startup failure is unrelated; the authorized local browser diagnostic is running with the required macOS sandbox exception.

- timestamp: 2026-11-02
  checked: one freshly authorized rerun of the failed Operator Browser Gate job
  found: run `41376300645` attempt 2 on the same SHA failed after 309 passed, 1 failed, 1 skipped. Both Playwright's original execution and internal retry #1 timed out at the bottom-scroll predicate after `End`; the focus check immediately before End passed. The trace and error context are saved under `/private/tmp/mailglass-scroll178-hosted-attempt2`.
  implication: this is reproducible on hosted Ubuntu Chromium, although macOS and local Linux ARM64/AMD64 browser comparisons pass. Restarting local Docker did not alter the hosted behavior. Investigate the actual input/scroll contract before changing code; no further hosted retry is allowed.

- timestamp: 2026-11-02
  checked: one unchanged inbound original-target execution with the pinned AMD64 browser and post-run cleanup
  found: original flows.spec.js:2466 target passed (5811 ms test; 52.4 seconds including server compilation) with retries=0 and workers=1. Browser was Linux x86_64 Chrome Headless Shell 147.0.7727.15/revision 1217 on existing Ubuntu 24.04; both ends used Playwright 1.59.1. Browser server used existing Node 24.19.0, while the unchanged test/server side used Node 22.14.0 and Elixir 1.18.4/OTP 27 on ARM64. PW_TEST_CONNECT_WS_ENDPOINT and PW_TEST_CONNECT_EXPOSE_NETWORK=<loopback> supplied browser transport without modifying the original config or test. External network was disconnected before test execution; all test containers were internal-only with no published ports. Disposable containers/network/anonymous database volume and downloaded/extracted browser assets were removed. Before/after SHA256 fingerprints found zero changed tracked nonplanning files; relevant test/config/package/lock diffs are empty.
  implication: AMD64 browser architecture by itself is insufficient to reproduce the hosted failure in this bounded emulated comparison. Leave source, dependencies and assertions unchanged; no evidence-supported fix exists. Log is /private/tmp/mailglass-scroll178-amd64-run.log; reporter, installed library inventory, container isolation metadata and source-integrity result are under /private/tmp/mailglass-scroll178-amd64-1793589067. No additional test invocation, image pull, hosted action or remote mutation occurred.

- timestamp: 2026-11-02
  checked: exact AMD64 browser artifact and minimal library provisioning size
  found: Chrome Headless Shell 147.0.7727.15 archive is 117394312 bytes; MD5 matches the upstream Google Storage x-goog-hash, zip integrity passes and executable ELF machine is 62 (AMD64). SHA256 is cf779cd5486f3fc5a18bea4ac606026a1667ae16efaee15af51bd3ad3ae01092. A simulated no-recommends install needs 46.3 MB downloads/201 MB container storage. The simulation's expected abort was misclassified by the preparation helper and its disposable container was removed; no browser test ran.
  implication: the standalone browser plus minimal shared libraries is practical without a new image or paid service. Recreate only that disposable container and proceed with one unchanged original target.

- timestamp: 2026-11-02
  checked: continuation initialization and narrow AMD64 reproduction design
  found: no project skill directories, configured debugger skills or knowledge-base.md exist; MemPalace CLI is absent. The existing AMD64 Ubuntu 24.04 image executes under Docker emulation. Locked Playwright 1.59.1 maps Chromium revision 1217 to Chrome Headless Shell 147.0.7727.15 and supports PW_TEST_CONNECT_WS_ENDPOINT. Source and dependency locks remain read-only.
  implication: reuse the known-working disposable ARM64 server and connect the unchanged original Playwright target to a disposable AMD64 browser, avoiding another Elixir/native dependency toolchain and a full CI image. Browser emulation and ARM64 server remain limits. SBFL remains unavailable; no fix proposed.

- timestamp: 2026-11-02
  checked: cached AMD64 reproduction assets without downloads
  found: all project mailglass app/demo images and the installed Microsoft Playwright v1.60.0-noble image are ARM64. All sixteen project Playwright volumes were mounted read-only in one disposable inventory container; the only Chromium 1217 chrome and headless_shell files were ELF machine 183 (AArch64), with no machine 62 (AMD64) copy. Node 22-bookworm and catthehacker/ubuntu act-24.04 are cached AMD64; the latter runs and reports x86_64 under Docker emulation, but has no browser cache or Elixir/Erlang toolchain in its standard toolcache paths. The closest explicitly versioned cached AMD64 Elixir image is 1.18.5/OTP 27.3.4.17, whereas CI requires 1.18.4/OTP 27. The pinned CI Postgres digest also differs from the cached project image recorded earlier.
  implication: the exact hosted AMD64 environment is not cached. At minimum, an AMD64 Chromium 1217 artifact is needed for the next browser-architecture comparison; a full matching AMD64 server comparison additionally needs the exact BEAM runtime and native dependency artifacts. No image/artifact was fetched and no additional browser test was invoked; both inventory containers used --pull=never, --network=none and --rm.

- timestamp: 2026-11-02
  checked: original and retry traces from the exact Cycle 02 hosted run, using GitHub GET API only
  found: API confirms run 41376300645 attempt 1 head a0a7450cc68afe84e25e69276c654d9e63422499. Artifact operator-browser-timeout-evidence-41376300645-node-22 downloaded to /private/tmp/mailglass-scroll178-hosted-failure.zip; SHA256 66dc84549c0b1c11059137ec5b060e22a2cb9bf970c98c0ca94f51668384a731 matches GitHub's recorded digest. Both original and retry traces show inbound-quick-view focused immediately before End. PageDown advances to 630px; End dispatch then leaves the dialog at 630px for the entire failing predicate. The modal phx-keydown-loading class appears and clears after both keys, consistent with ignored server key events. This confirms End did not advance the hosted scroll position; no recorded geometry/focus evidence explains why. Earlier matching traces under opgate-pr-40904235961 are older and cannot stand in for this candidate.
  implication: simple lack of focus before End is contradicted by the exact failure trace, while native browser/environment behavior remains unconfirmed. The source and assertion remain unchanged; no remote mutation or hosted execution occurred.

- timestamp: 2026-11-02
  checked: single unchanged inbound target on Linux ARM64 with matching Chromium 1217, Playwright 1.59.1, Node 22.14.0 and Elixir 1.18.4/OTP 27
  found: the complete original target passed in 2.5 seconds (60.0 seconds including cold compilation). The verified lazy_html artifact loaded normally without Lexbor fallback. Log /private/tmp/mailglass-scroll178-linux-provisioned-db.log and reporter /private/tmp/mailglass-scroll178-linux-provisioned-1793588042/test-results/operator-browser-evidence.json contain the result. All disposable containers/network/anonymous DB volume were removed; docker queries found no experiment resources. Source and dependency locks have no diff.
  implication: Linux alone is not sufficient to reproduce; no code or test change is justified. The comparison remains ARM64 with a different Postgres image digest, so it is not exact hosted-runner equivalence. Inspect already-downloaded failure traces next, without another test invocation.

- timestamp: 2026-11-02
  checked: first provisioned Linux setup with verified cached native artifact
  found: lazy_html compiled successfully and all application compilation completed. Server boot then failed before Chromium because disposable Postgres had not been configured to create mailglass_test. The setup cleaned up all its own containers/network/anonymous database volume. Log /private/tmp/mailglass-scroll178-linux-provisioned.log records the FATAL invalid_catalog_name error; no browser-level test executed.
  implication: correct only the disposable database fixture (POSTGRES_DB=mailglass_test); no product or test inference follows from this setup error

- timestamp: 2026-11-02
  checked: provisioning the pinned lazy_html Linux ARM64 NIF from its package-declared GitHub release URL
  found: downloaded lazy_html 0.1.13 NIF 2.16 archive; SHA256 adde710db6109143a9c2884e4ac012693a2324eb3adf3fc1a778c7d125bfe1e2 exactly matches deps/lazy_html/checksum.exs. The immutable package version and checked checksum are unchanged. The artifact is stored only at /private/tmp/mailglass-scroll178-artifacts and will be copied into the disposable container cache; Lexbor source fallback is unnecessary if that verified artifact loads.
  implication: the original dependency blocker is resolved without repository or lockfile changes, and the actual browser test can now be attempted on the existing internal-only Docker network

- timestamp: 2026-11-02
  checked: user authorization for continued local diagnosis
  found: user approved all recommendations, including provisioning locked artifacts in the disposable Linux container to obtain a browser-level reproduction
  implication: proceed within the local-only diagnostic boundary; no repository dependency changes or hosted actions are authorized or needed

- timestamp: 2026-11-02
  checked: one original-target Linux invocation with CI=true, --workers=1 and --retries=0
  found: Node 22.14.0, Elixir 1.18.4/OTP 27, Playwright 1.59.1 and cached Chromium 1217 were available. The app compiled copied dependencies until lazy_html 0.1.13 attempted to fetch lazy_html-nif-2.16-aarch64-linux-gnu-0.1.13.tar.gz; its source fallback then attempted to clone Lexbor revision 244b84956a6dc7eec293781d051354f351274c46. Neither artifact was cached, and both requests failed DNS on the deliberately internal-only network. Playwright exited because webServer could not start, before launching Chromium or running the test. The generic gcc/make suggestion is not the cause; make ran and failed on the uncached Lexbor clone.
  implication: existing installed images and caches cannot complete this bounded offline reproduction as configured. No product/test fix is supported, and no additional invocation was made. Full log is /private/tmp/mailglass-scroll178-linux-repro-arm64.log; generated reporter JSON is /private/tmp/mailglass-scroll178-linux-1793587619/test-results/operator-browser-evidence.json.

- timestamp: 2026-11-02
  checked: Linux experiment isolation and cleanup
  found: repository was mounted read-only and copied into disposable container storage; existing browser cache was read-only; no ports were published; network was internal-only; no packages or images were fetched. All experiment app/database/helper containers, anonymous database volumes and internal networks were removed. Post-run Docker queries found no mailglass-scroll178-linux containers or networks. No workflow, PR, push, preview, dependency-lock or source mutation occurred.
  implication: dirty workspace and frozen hosted candidate are preserved. Only this debug record was changed in the repository by this continuation.

- timestamp: 2026-11-02
  checked: disposable Linux setup before test launch
  found: node:22-bookworm is AMD64 locally despite the ARM64 app image, so copying that binary failed with a missing x86-64 ELF interpreter. The browser test never launched. The script removed its own containers, anonymous DB volume and internal network. Installed node:22.14.0-bookworm is ARM64 and can supply the compatible binary.
  implication: correct the local setup architecture and proceed with the one authorized browser test; this setup failure supplies no scroll evidence.

- timestamp: 2026-11-02
  checked: existing project browser volumes and dependency sources
  found: mailglass-phase173-review-cea2f46a-20261010165422-30235-22143_mailglass_demo_playwright contains Linux chromium-1217 and chromium_headless_shell-1217. Host dependency source directories and Playwright 1.59.1 node_modules are present; cached admin dependency volumes are empty. A local Node 22 image can supply its binary without fetching packages.
  implication: a local Linux comparison is feasible using disposable source/dependency copies, offline compilation and an internal-only Docker network. Checkout, dependency locks, existing caches and all remote state will remain unchanged.

- timestamp: 2026-11-02
  checked: local CI workflow and installed image metadata
  found: Operator Browser Gate uses Postgres 16-alpine, Node 22, Elixir 1.18.4/OTP 27 and locked Playwright 1.59.1 (Chromium revision 1217). Existing Playwright 1.60.0 image supplies revision 1223 only; existing demo test image supplies Elixir 1.18.4/OTP 27 but has no source/deps embedded at /workspace. Local images are ARM64, whereas hosted ubuntu-latest is normally AMD64. Postgres 16-alpine is installed with a different digest from the workflow pin.
  implication: do not claim exact hosted-environment equivalence. Check existing browser/dependency caches before a bounded local Linux comparison; do not download or modify dependencies.

- timestamp: 2026-11-02
  checked: final unchanged delivery and inbound scroll tests after diagnostic cleanup
  found: both passed in 6.9s; git diff --exit-code -- mailglass_admin/e2e/flows.spec.js returned 0; no DEBUG-scroll-178, SCROLL_DIAGNOSTICS or SCROLL_CPU_RATE instrumentation remains.
  implication: source restored exactly; only this debug record remains changed by this investigation. Original hosted issue is unverified, not fixed. No unrelated files were staged or reverted.

- timestamp: 2026-11-02
  checked: temporary local timing probes (early first-movement polling, then rate-8 CPU throttling)
  found: four early-poll and four CPU-throttled tests passed. Keydown End arrived while PageDown was moving; focus remained inbound-quick-view, geometry remained 2181/720, and browser scrolling reached the bottom within roughly 200ms. Relevant package-lock.json, mix.lock and Playwright config also have no candidate-to-HEAD diff.
  implication: the suspected overlapping-input timing issue is not sufficient to reproduce locally. No evidence supports changing product behavior or relaxing the bottom assertion. Remove all temporary source instrumentation.

- timestamp: 2026-11-02
  checked: relevant source differential between local HEAD and hosted frozen candidate
  found: no differences in flows.spec.js, app.css, hooks.js, Assets controller, InboundLive or inbound quick-view component.
  implication: local checks execute the same relevant implementation despite different overall HEAD; candidate remains frozen.
- timestamp: 2026-11-02
  checked: early-poll diagnostic local experiment, first three completed runs
  found: native End keydown arrived at scrollTop 1, 6 and 9 during PageDown animation; focus remained inbound-quick-view throughout and final geometry was scrollTop 1461 + clientHeight 720 = scrollHeight 2181, with scrollend around 170ms after End. No key default was prevented by the measured listeners.
  implication: overlapping native scrolling alone does not reproduce on macOS; vary scheduling before concluding this explanation. No product fix warranted yet.

- timestamp: 2026-11-02
  checked: original inbound reproduction repeated sequentially twelve times
  found: all twelve passed unchanged in 34.5s (in addition to the initial pass).
  implication: macOS is not exposing the hosted intermittent failure under default timing. Diagnostic experiment records focus, key and scroll events while polling first PageDown movement earlier; no product change proposed.
- timestamp: 2026-11-02
  checked: source identity and input handlers
  found: local HEAD is de799da72b9ebbce45bd1f358f8527b0c894cbe1, not frozen hosted candidate a0a7450cc68afe84e25e69276c654d9e63422499; relevant helper and inbound component must be compared before treating local results as candidate proof. detail_key ignores PageDown and End; native browser owns both defaults.
  implication: isolate browser/test timing and verify candidate source equivalence; do not claim remote-candidate validation from local HEAD alone.

- timestamp: 2026-11-02
  checked: original target with supported runtime and local Chromium sandbox escalation
  found: one pass in 4.0s; full inbound PageDown/End, navigation boundaries, and focus-return test passed unchanged.
  implication: original issue is not deterministic on first local attempt; test bounded repeat before drawing conclusions.

- timestamp: 2026-11-02
  checked: runtime-selected targeted local Playwright command
  found: local isolated server booted successfully; Chromium aborted before creating a page because macOS bootstrap_check_in was denied inside sandbox.
  implication: rerun the same local test with narrowly scoped sandbox escalation; this is not evidence about scroll behavior.

- timestamp: 2026-11-02
  checked: initial local targeted Playwright command
  found: server never started; asdf could not select an Elixir version in mailglass_admin (exit 126).
  implication: not a reproduction of the scroll failure; retry using the repository's explicit supported runtime selection.
- timestamp: 2026-11-02
  checked: project skill discovery and debug recall
  found: no .agents/skills or .codex/skills directories; gsd-debugger configured skill query returned no skills; no knowledge-base.md exists.
  implication: no prior matching KB diagnosis; begin observation. SBFL skipped because no per-test coverage exists for browser flows.

## Eliminated

- hypothesis: InboundLive detail_key directly intercepts/prevents End scrolling
  evidence: End and PageDown reach the default no-op server branch; browser diagnostics show native scrolling and retained dialog focus. Assets controller only prevents Arrow defaults, while PreviewPanelScroll is not attached to this dialog.
  timestamp: 2026-11-02
- hypothesis: overlapping PageDown and End alone necessarily causes the bottom timeout
  evidence: eight diagnostic runs sent End during PageDown movement, including rate-8 CPU throttling, and every run reached the existing bottom predicate. This only eliminates the sufficient-cause claim locally, not a platform-dependent interaction.
  timestamp: 2026-11-02

## Resolution

result: root_cause_found_local_fix_verified_hosted
root_cause: the shared browser test treats positive PageDown movement as completion, so End can arrive in Chromium's late native PageDown animation-completion interval and be ignored; an application-free reproduction and the unchanged actual helper reproduce the same retained-focus/stuck-page-offset symptom locally
fix: arm a one-shot native scrollend listener before PageDown and poll its completion before sending End; retain all original accessibility, native keyboard, focus, exact bottom and navigation boundary assertions
oracle_type: specified — original keyboard-access contract requires real PageDown movement followed by End reaching scrollTop + clientHeight >= scrollHeight - 1; timing boundary samples cover both sides of the native completion interval
files_changed: [mailglass_admin/e2e/flows.spec.js, .planning/debug/operator-inbound-scroll-178.md]
verification:
  target_test: { result: pass, evidence: actual-helper timing reproducer 12/12 after fix and 12/12 after reapply; real inbound target passes initially and in three final repeats }
  mutation_check: { result: skipped, reason_if_skipped: Stryker is absent and unconfigured; no dependency added }
  no_op_deletion: { result: pass, deletion_justified_by_rca: false, evidence: 13 additive lines; original keys and predicates retained; no product/config/lockfile changes }
  adjacent_tests: { result: pass, suites_run: [Phase174 delivery scroll access, Phase174 inbound navigation boundaries and focus return], evidence: final two-case target repeated three times — 6 passed in 15.8s }
  revert_and_reconfirm: { result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, evidence: exact HEAD helper fails 3/12 reverted; fixed helper passes 12/12 reapplied }
  original_target: pass (initial run + twelve repeats + final adjacent run; fourteen unchanged inbound executions)
  timing_diagnostics: pass (four earlier-poll runs + four CPU-throttled runs; temporary instrumentation removed)
  adjacent_delivery_scroll: pass (final unchanged run)
  source_cleanup: pass (flows.spec.js exactly matches HEAD, no debug markers remain)
  linux_original_target: pass (single unchanged target on Linux ARM64, matching Chromium 1217 and Playwright 1.59.1, after checksum-verified NIF provisioning and disposable DB correction)
  linux_cleanup: pass (own containers, anonymous DB volumes and internal networks removed)
  amd64_original_target: pass (one unchanged original target, Playwright 1.59.1, AMD64 Chrome Headless Shell 147.0.7727.15/revision 1217, retries=0; 5811 ms test)
  amd64_integrity: pass (upstream download MD5/size, zip integrity, x86_64 ELF and browser version; unchanged source fingerprints and relevant diffs)
  amd64_cleanup: pass (own containers, internal network, anonymous DB volume and browser download/extraction removed)
  guardrail_verdict: accepted
  hosted_verification: pass — exact candidate 8e501960bc975ed44b632ba5c74522e0c5d66f8c, CI run 41388571351 attempt 1, Operator Browser Gate 310 passed/1 skipped/0 failed/0 flaky; the unchanged inbound scroll-access case passed in the hashed log below
  hosted_log: reference/demo_app/tmp/phase178_candidate/recovery-cycle-04/41388571351-attempt-1/operator-browser-gate.log
  hosted_log_sha256: 3284a1e1060317e0b23a5bbcb58f3fe8a9dcd16abc6605bb7a5a6fbc447372e3
limitations:
  - Earlier macOS ARM64, Linux ARM64 and AMD64 browser comparisons passed unchanged. The new timing-controlled macOS native and exact-helper reproducers now expose the same stuck-offset symptom, so those earlier passes do not rule out the completion-boundary race. No changed-helper hosted run has occurred.
  - The AMD64 browser ran under Docker emulation on existing Ubuntu 24.04 with current minimal OS libraries and Node 24.19.0 for the browser endpoint; its disposable server/test client remained ARM64 with pinned Node 22.14.0 and Elixir 1.18.4/OTP 27. The local Postgres 16-alpine image digest differs from the hosted pin. This isolates browser architecture but is not exact hosted-runner equivalence.
  - This fixes the test's sequencing between two independent keyboard gestures. It does not modify Chromium or promise that a real user's overlapping End during the native animation boundary is repaired; no production accessibility semantics changed.
  - Local HEAD differs overall from the frozen candidate, but relevant source, browser config and dependency locks match. The candidate's hosted test evidence is limited to the exact run receipts in Cycle 04 and does not establish that the owner preview is available.
  - Cycle 04's single preview attempt failed at `/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar` with HTTP 302; no retry or relaunch is authorized. The exact route record and candidate-only cleanup are in `178-RECOVERY-CYCLE-04.json` and `178-DELIVERY.md`.

### Hosted closure (Cycle 04)

The exact-SHA attempt-1 Operator Browser Gate completed successfully on run `41388571351`. Its raw log contains the inbound scroll-access case passing at line 1307, with the related delivery scroll-access case passing at line 1306. The complete summary is 310 passed, 1 skipped, 0 failed, 0 flaky. This closes the hosted verification pending for this test fix; it does not close UIQ-08 or imply a passing preview. The single preview attempt failed on the login route and was cleaned up without touching the owner demo.

### Commands and outcomes

All production browser test commands used `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` in `mailglass_admin`, with local Chromium sandbox escalation after the sandbox-only launch denial. Application-free timing harnesses use the unchanged installed Playwright/axe packages directly and create no server or network resources.

```text
npx playwright test --config=playwright.config.cjs --workers=1 e2e/flows.spec.js:2466
1 passed (4.0s)
npx playwright test --config=playwright.config.cjs --workers=1 e2e/flows.spec.js:2466 --repeat-each=12
12 passed (34.5s)
SCROLL_DIAGNOSTICS=1 npx playwright test --config=playwright.config.cjs --workers=1 e2e/flows.spec.js --grep 'Phase174 scroll access: Inbound' --repeat-each=4
4 passed (14.1s)
SCROLL_DIAGNOSTICS=1 SCROLL_CPU_RATE=8 npx playwright test --config=playwright.config.cjs --workers=1 e2e/flows.spec.js --grep 'Phase174 scroll access: Inbound' --repeat-each=4
4 passed (15.1s)
npx playwright test --config=playwright.config.cjs --workers=1 e2e/flows.spec.js --grep 'Phase174 scroll access:'
2 passed (6.9s)
```

The diagnostic environment flags applied only to temporary helper instrumentation; those flags and instrumentation were removed before the final run. One diagnostic invocation using an obsolete shifted line number selected zero tests, then was corrected to a name selector; it supplied no behavior evidence.

Linux continuation used only installed Docker images and read-only caches, with a disposable checkout/dependency copy and isolated Postgres 16. It ran this exact target once under Node 22.14.0, Elixir 1.18.4/OTP 27 and CI=true:

```text
npx --no-install playwright test --config=playwright.config.cjs --workers=1 --retries=0 e2e/flows.spec.js:2466
Error: Process from config.webServer was not able to start. Exit code: 1
lazy_html Linux NIF download unavailable; fallback Lexbor clone unavailable on internal-only network
```

No second browser invocation followed this dependency failure. The earlier wrong-architecture Node setup failed before invoking Playwright and was corrected using an existing ARM64 Node 22 image. Local setup script and logs remain in /private/tmp/mailglass-scroll178-linux-repro* for inspection; there is no project implementation change to review or commit.

The authorized AMD64 continuation downloaded only the exact pinned standalone browser and minimal libraries into a disposable container based on an already cached image. Browser archive MD5 matched Google's response header; the recorded SHA256 is a local audit fingerprint, not an independently signed checksum. The temporary AMD64 Playwright endpoint used the unchanged installed package with an internal network and loopback forwarding. The original test/config remained unmodified:

```text
PW_TEST_CONNECT_WS_ENDPOINT=ws://amd64-browser:3000/ PW_TEST_CONNECT_EXPOSE_NETWORK=<loopback>
npx --no-install playwright test --config=playwright.config.cjs --workers=1 --retries=0 e2e/flows.spec.js:2466
1 passed (52.4s), test duration 5811 ms
```

All earlier container comparison resources and browser payloads were removed. The continuation subsequently found and locally verified the completion-event helper fix recorded above; no hosted verification or publication followed. The session remains awaiting original-environment verification, not resolved. Hosted stop and frozen candidate remain unchanged.

### Current continuation commands and results

```text
node /private/tmp/mailglass-scroll178-native.cjs
initial sweep: 2/24 ignored End; bounded reconfirmation: 5/24 ignored End
node /private/tmp/mailglass-scroll178-native.cjs --settled
24/24 reach the exact bottom after native PageDown completion
node /private/tmp/mailglass-scroll178-helper.cjs
unchanged actual helper: 6/12 fail; fixed: 12/12 pass; reverted: 3/12 fail; reapplied: 12/12 pass
npx --no-install playwright test --config=playwright.config.cjs --workers=1 --retries=0 e2e/flows.spec.js --grep 'Phase174 scroll access:'
2 passed (7.4s)
npx --no-install playwright test --config=playwright.config.cjs --workers=1 --retries=0 e2e/flows.spec.js --grep 'Phase174 scroll access:' --repeat-each=3
6 passed (15.8s)
node --check mailglass_admin/e2e/flows.spec.js
exit 0
git diff --check -- mailglass_admin/e2e/flows.spec.js
exit 0
```

The actual-helper diagnostic extracts the named helper from the current file, executes it with the installed real Playwright expect and AxeBuilder, and varies only the earliest End dispatch time across 145/150/155/160 ms. It uses a static focusable dialog and no application/LiveView. Original test assertions are executed unchanged; the diagnostic's 1s poll timeout only bounds each failed sample and is not a repository configuration change. Raw event records and scripts remain under /private/tmp/mailglass-scroll178-{native,helper}*.cjs/.log. No Stryker/property framework was added and no remote action is pending under current authorization.
