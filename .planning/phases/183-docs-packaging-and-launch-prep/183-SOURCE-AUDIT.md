# Phase 183 source coverage and planning assumptions

## Owner-authorized single gap-closure addendum — 183-03

The owner approved exactly one additional plan after final verification found a clean-checkout CI prerequisite gap. This explicitly supersedes the original D-15 two-plan count for this gap only; the historical audit below remains the original two-plan record. No new research or implementation is performed during gap planning.

| Source | ID | Gap-closure coverage | Plan/task | Status |
|--------|----|----------------------|-----------|--------|
| GOAL | Phase 183 / SC-1 / SC-2 | Preserve existing brand identity; make the three-package generated contract a required same-job check and verify local theme/layout against fresh outputs | 03-1/2 | COVERED |
| REQ | BRDOC-01 | Native theme selection and narrow README layout remain asserted in all three packages | 03-1 | COVERED |
| REQ | BRDOC-02 | Three real docs builds, pin/CSS/Lato/claim checks, required docs-job invocation and clean generic tests | 03-1/2 | COVERED |
| REQ | BRDOC-03 / BRDOC-04 / BRDOC-05 / BRDOC-06 | Existing completed work remains covered by plans 01/02; pending owner sign-off, no-capture stop and legal handoff are retained | 01/02; 03 boundaries | COVERED |
| RESEARCH | ExDoc / Validation | Reuse existing verify_output/2 and pinned local Playwright; source/fixture tests stay hermetic, outputs built once per package in the existing required job | 03-1/2 | COVERED |
| RESEARCH | Other original findings | No new research in gaps mode; historical coverage remains in the original audit below | 01/02 | COVERED |
| CONTEXT | D-01 / D-02 / D-03 / D-04 / D-05 | Preserve renderer fragments, full-SHA bytes, lowercase H1/alt, separate tagline, native typography/themes and real package docs checks | 03-1 | COVERED |
| CONTEXT | D-06 / D-07 / D-08 / D-10 | Existing guide/lint/asset work remains covered by original completed plans; no changes are planned | 01/02 | COVERED |
| CONTEXT | D-09 / D-11 / D-12 / D-13 / D-14 / D-16 | Preserve pending canonical patches, consumed capture authorization, platform/Safari limits, no social actions, current caution and no publication/claim authority | 03-1/2 | COVERED |
| CONTEXT | D-15 | Owner expressly authorized one additional gap plan; no broader scope/cap change inferred | 03 objective | COVERED |
| VERIFICATION | sole gaps item | Remove ignored-output dependency from default tests and require same-job real core/Admin/Inbound output validation | 03-1/2 | COVERED |
| VERIFICATION | associated browser items | Explicit output-root support and six existing native-theme/narrow-layout scenarios using installed Chromium; no browser download or favicon capture | 03-1 | COVERED |

Plan 03 depends on completed 183-01 and is wave 3, after its wave 2. Task 1 creates the standalone output consumer and one build/check/browser path; task 2 binds that proven path to the existing required docs job and proves default root discovery. Paths are repository-relative except the pre-existing owner-authorized installed browser resource. The new script and contract paths are created by task 1; the workflow regression test is created by task 2. No count/grep acceptance gate is authored. The absent-README shell checks are explicit cleanliness prerequisites for the full suite, not claims of newly delivered behavior. Calibration is factor 1, zero samples, low confidence; raw/calibrated estimate 26k tokens.

The existing 91s core-only docs observation and 356s/528s unrelated-run critical-path observations support retaining the existing docs job and avoiding repeated generation in generic tests; they do not establish candidate runner-minute savings. Local per-package/build/browser timings will be recorded during execution. No remote CI profiling or dispatch is authorized. Deferred ideas and all owner handoffs remain excluded from implementation scope.

Exactly two plans, three executable tasks each. Execution is **02 in wave 1, then 01 in wave 2**. The launch gate is hardened before source artwork/catalog/checklist work; docs consume the resulting marks and guide. The phase-specific D-15 cap supersedes generic five-file task sizing for the explicitly inventoried package locksteps and mechanical prose sweep. No requirement is reduced or deferred to fit the cap.

## Multi-source coverage audit

| Source | ID | Required outcome or constraint | Plan/task | Status |
|--------|----|--------------------------------|-----------|--------|
| GOAL | Phase 183 | Adopter README/HexDocs/package/favicon identity is v2; irreversible claims wait for clearance | Both plans | COVERED |
| GOAL | SC-1 | Correct renderer themes, immutable raw URLs, offline byte contract | 01-01/02 | COVERED |
| GOAL | SC-2 | Three real docs builds, m mark, syntax-only colors, native Lato/theme | 01-01/02/03 | COVERED |
| GOAL | SC-3 | Design guide/tool config and pending paired owner drafts | 02-02 | COVERED |
| GOAL | SC-4 | Lowercase lint, intended payload and full package checks | 01-03 | COVERED |
| GOAL | SC-5 | Three-engine favicon sizes, upload checklist and blocked announcement/TM with rollout independent | 02-01/03, 01-03 | COVERED |
| REQ | BRDOC-01 | Theme-aware README headers at immutable asset SHA | 01-01/02 | COVERED |
| REQ | BRDOC-02 | Branded ExDoc in all package configs and real builds | 01-01/02/03 | COVERED |
| REQ | BRDOC-03 | Design guide, impeccable config, pending owner drafts | 02-02 | COVERED |
| REQ | BRDOC-04 | Effective lowercase lint, payload allowlists and package checks | 01-03 | COVERED |
| REQ | BRDOC-05 | 16/24/32 three-engine favicon evidence, social/avatar handoff | 02-03 | COVERED |
| REQ | BRDOC-06 | Current-record claim/announcement gate; rollout independent | 02-01, 01-01/03 | COVERED |
| RESEARCH | README | Hex.pm sanitization, light-first fragments, absolute full-SHA URLs; no network-dependent CI | 01-01/02 | COVERED |
| RESEARCH | ExDoc | Existing 0.40.4 hooks/assets, code colors only, Lato/class selection | 01-01/02 | COVERED |
| RESEARCH | Design | Root DESIGN.md/tool sidecar plus retained Admin guide, handwritten parity, narrow retired-font exception and tracked exit | 02-02 | COVERED |
| RESEARCH | Owner drafts | Unified patch pair, apply-check, pending status, stable research path | 02-02 | COVERED |
| RESEARCH | Lint | Full adopter corpus, API/code/wire/history exceptions, test teeth/rot/floor, positive and negative lockstep pins | 01-03 | COVERED |
| RESEARCH | Package | Actual tarball/golden/pin relation, six fonts/OFL/logo/favicon, forbidden source roots, known two-file Admin drift, release-digest coverage | 01-03 | COVERED |
| RESEARCH | Favicon | Manifest-driven source update, same zip, source/served SHA, three engines/themes/sizes, DPR/background coverage, independent PNG metrics, unique catalogs and advisory input filter | 02-03 | COVERED |
| RESEARCH | Browser limits | No cross-engine byte golden, explicit 16px overlap exception, measured grey threshold, Safari tab chrome unobserved | 02-03 | COVERED |
| RESEARCH | Social | Pinned social/avatar dimensions, complete repo URLs, post-upload read-back; personal identities skipped | 02-03 | COVERED |
| RESEARCH | Trademark | Close WR-01/02 first, named registers clear, future/overlong dates reject, no production flags, public/generated decoded claims, exact hash-bound rule exception, no publish dependency | 02-01, 01-01/03 | COVERED |
| RESEARCH | Validation | Existing ExUnit/Mix/Playwright; real three-package docs/full package checks; background execution; no new runtime dependency | Both verification blocks | COVERED |
| CONTEXT | D-01 | Two images and renderer fragments, requirement already amended | 01-01/02 | COVERED |
| CONTEXT | D-02 | Exact immutable commit, offline refs/bytes, reachability disclosed, no remote tag | 01-01/02 | COVERED |
| CONTEXT | D-03 | Lowercase H1/alt, separate tagline, no full book package | 01-01/03 | COVERED |
| CONTEXT | D-04 | All-package v2 mark/favicon, code colors only, native Lato/class toggle | 01-01/02 | COVERED |
| CONTEXT | D-05 | Three separate docs builds, generated output and every package check | 01-01/02/03 | COVERED |
| CONTEXT | D-06 | Retained Admin guide, root/tool files, correct sources/parity | 02-02 | COVERED |
| CONTEXT | D-07 | Narrow Inter exception, source reason and follow-up | 02-02 | COVERED |
| CONTEXT | D-08 | Structural lowercase lint with module/API/history/tests/source exceptions | 01-03, 02-02 | COVERED |
| CONTEXT | D-09 | Pending owner research drafts; canonical files untouched | 02-02, 01-03 exception | COVERED |
| CONTEXT | D-10 | Assets added through update and declared extension manifest; no v1 social assets | 02-03 | COVERED |
| CONTEXT | D-11 | Three engines, themes and sizes, unique source-bound PNG metrics; Safari limit | 02-03 | COVERED |
| CONTEXT | D-12 | Repository-only checklist, full URLs/read-back, personal identities skipped | 02-03 | COVERED |
| CONTEXT | D-13 | Close warning bypasses; scan decoded public/generated claims with narrow pinned exception | 02-01, 01-01/03 | COVERED |
| CONTEXT | D-14 | Blocked research draft; current caution denies while packages/code remain allowed | 02-01, 01-03 | COVERED |
| CONTEXT | D-15 | Exactly two plans, all scope retained, sizing exception documented | Both | COVERED |
| CONTEXT | D-16 | No upload/tag/publish/release/deploy/announce/claim/canonical edits; human legal handoff remains | Both tasks and verification | COVERED |
| UI-SPEC | Empty | Required static assets fail if absent; lowercase alt remains | Both must_haves; 01-01/02, 02-03 | COVERED |
| UI-SPEC | Loading | No custom loader; capture waits for decode | Both must_haves; 01-01/02, 02-03 | COVERED |
| UI-SPEC | Error | Missing/undecodable/pin mismatch fails; alt fallback | Both must_haves; 01-01/02, 02-03 | COVERED |
| UI-SPEC | Populated | Matching theme/native class, full favicon matrix | Both must_haves; 01-01/02, 02-03 | COVERED |
| UI-SPEC | Long text | Single lowercase H1, wrapping separate tagline, undistorted artwork | Both must_haves; 01-01/02 | COVERED |
| UI-SPEC | Overflow | Available width/ratio/96px floor, wrapping without horizontal scroll | Both must_haves; 01-01/02 | COVERED |

Deferred ideas remain excluded: human register/reverse-image/counsel searches, remote brand tag, social upload, personal avatars, package publication/announcement and recipient inline-CSS cleanup. The explicit follow-up records that last item; it does not implement it. The recipient page's capitalized brand label is a casing-only correction, not a font/color/behavior change.

## Dependency and reachability analysis

| Task | Needs | Creates or advances | Checkpoint |
|------|-------|--------------------|------------|
| 183-02-01 | Existing current search record and gate/tests | Production denial tracer, closed bypasses, public/generated claim scan, blocked draft | None |
| 183-02-02 | Pinned tokens/brand/status words, existing guide/config and canonical owner files | Usable guide/tool contract, pending patch pair and scoped exception | None |
| 183-02-03 | Hardened gate, existing pin/extraction/browser infrastructure | Declared source assets, independent catalog and repo-only handoff | None |
| 183-01-01 | 02's pinned marks and scanner | Real core README→ExDoc→theme path and verifiers | None |
| 183-01-02 | Core path and shared verifiers | Same capability in both sibling packages | None |
| 183-01-03 | All docs configs/README contracts and 02's guidance | Enforced lowercase actual prose, reviewed real payloads and final generated outputs | None |

Every artifact has a trigger/consumer: README/package docs build, root DESIGN/tool discovery, ExUnit's existing scripts/admin lanes, browser producer CLI and required catalog consumer, default production gate, and a manually actionable owner patch/checklist. Browser producer has no app/server/DB dependency. Same-wave file overlap: none because only 02 is wave 1; test/mailglass/docs_contract_test.exs is deliberately reused by 01 after 02. No API matrix or schema change applies. Graphify is disabled; no project-local skills or structural map were present. No PATTERNS.md was available; local pinned source and existing contract tests supply the patterns.

## Flagged edge assumptions — unresolved, not lifted into truths

The deterministic spec-less probe returned 10 items, 0 resolved, 10 unresolved, with 3 unclassified. No explicit/backstop predicate was invented. Keep all ten visible during implementation/review; acceptance comes from existing CONTEXT/RESEARCH/UI-SPEC requirements, not an assumed probe resolution.

| Requirement | Probe category | Status | Planning treatment |
|-------------|----------------|--------|--------------------|
| BRDOC-01 | unclassified | FLAGGED unresolved | Existing README requirements implemented; probe has no separately resolved edge |
| BRDOC-02 | adjacency | FLAGGED unresolved | Native CSS/script coexistence is tested; no probe resolution claimed |
| BRDOC-02 | empty | FLAGGED unresolved | Missing media/output fixtures are tested per explicit sources |
| BRDOC-02 | ordering | FLAGGED unresolved | Build/theme hook ordering tested; no invented explicit edge |
| BRDOC-03 | unclassified | FLAGGED unresolved | Parity and pending-pair requirements implemented |
| BRDOC-04 | empty | FLAGGED unresolved | Corpus floors and actual archive checks prevent vacuity |
| BRDOC-04 | encoding | FLAGGED unresolved | Structural code/entity exceptions are covered by source-backed tests |
| BRDOC-04 | concurrency | FLAGGED unresolved | Serial package/golden operations preserve current checks; no new concurrency promise |
| BRDOC-05 | concurrency | FLAGGED unresolved | Serial, unique, no-overwrite capture follows source conventions |
| BRDOC-06 | unclassified | FLAGGED unresolved | Explicit gate hardening and separation requirements implemented |

## Spec-less prohibition recall and precision

No Phase SPEC supplied a Prohibitions section. Applied the required two-stage probe to each requirement. Raw candidates were overproduced first, then engineering concerns were dropped, with only bespoke intent retained as flagged-unverified assumptions.

| Requirement | Raw recall candidates (ten each) | Precision result |
|-------------|----------------------------------|------------------|
| BRDOC-01 | Wrong theme; wrong ref; wrong host; missing alt; duplicate H1; cropped logo; shifted tagline; invented endorsement; public broken refs; layout overflow | Retain endorsement transparency intent; ordinary renderer/ref/geometry correctness belongs to contracts |
| BRDOC-02 | OS-only theme; wrong font; global CSS; wrong mark; missing favicon; missing output; external script; false Safari claim; source pollution; broken relative paths | Retain honest evidence/Safari intent; ordinary output/security correctness belongs to tests/STRIDE |
| BRDOC-03 | Wrong tokens; divergent narrative; ignored guide; global Inter allowance; stale patch; half-applied patch; canonical policy silently adopted; sender-identity confusion; retired source; missing follow-up | Existing locked owner boundary already covers adoption; source authority/token/pending cases remain explicit requirements, no additional prohibition minted |
| BRDOC-04 | Empty scan; wrong casing; renamed API; deleted history; stale exception; missing OFL; extra book; golden-only proof; leaked secret; unreviewed payload | Routine correctness/compatibility in contracts; secret disclosure is canon security, referred to STRIDE/security review, no bespoke duplicate |
| BRDOC-05 | Missing browser; forged metrics; stale SHA; overwritten evidence; cross-engine goldens; tab-chrome inference; personal avatar conflation; social upload; wrong dimensions; unlimited decode | Safari evidence intent retained once; personal/social boundaries already locked; remaining evidence correctness belongs to contracts/STRIDE |
| BRDOC-06 | False clearance; partial registers; future record; endless window; CLI bypass; encoded claims; registered mark; release coupling; counsel substitution; draft presented as publishable | Explicit source gate/owner boundaries implemented; unsupported endorsement/evidence claims remain the two retained assumptions, no extra legal-policy promise |

The two retained statements were projected through the installed probe-core projectProhibitions serializer. They appear only in 02's must_haves.prohibitions, with status unresolved, judgment tier and flagged-unverified reasons, and with no wired-check fields. Count: 2 kept = 2 authored; 10 edge items = 10 surfaced assumptions. Neither is silently dismissed or counted as a resolved explicit truth. The downstream verifier must flag them for judgment unless sufficient evidence resolves them.

## Grounding and discovery evidence

- Existing ExDoc formatter/config/templates confirm one logo path/one img and supported hooks; tiny local class-observing JS handles the two pinned mark files while CSS remains code-color-only.
- The reviewed zip was fetched read-only and its SHA checked during planning; exact favicon-32-light/dark, PNG/ICO/avatar/social member paths used by 02 exist in that archive.
- Existing OTP/Elixir environment and package aliases were inspected. New test/producer paths are explicitly created by their own tasks. No grep/count verification gate is authored, so there is no unrecorded passing-at-HEAD match gate.
- Estimate calibration: factor 1, samples 0, confidence low. Raw projections are 54k for launch safeguards/evidence and 48k for docs/prose/package contracts. Both remain below half of a 200k execution context.
- Existing admin/installer/doc pins and the two missing Admin golden module paths are included. Source candidates are exact paths; unchanged candidates need no edits.
- Only browser engine binaries may need downloading with the existing locked CLI; no npm/pip/cargo dependency installation or library upgrade is planned.
- Prior full-suite environmental failures remain disclosed; a failing required lane must be diagnosed rather than silently weakened or called passed.
