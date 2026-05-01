---
phase: 25-deliverability-doctor
verified: 2026-05-01T20:59:48Z
status: passed
score: 10/10 must-haves verified
overrides_applied: 0
human_verification: []
---

# Phase 25: deliverability-doctor Verification Report

**Phase Goal:** Ship `mix mail.doctor` with actionable DNS deliverability diagnostics.
**Verified:** 2026-05-01T20:59:48Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The deliverability doctor has one shared result contract that can render the same DNS findings as human output or JSON without scraping text. | ✓ VERIFIED | `lib/mailglass/deliverability/result.ex` defines the schema-versioned result contract; `lib/mailglass/deliverability/formatter.ex` renders both `render_human/2` and `render_json/1` from that result; formatter tests pin both render paths. |
| 2 | DNS lookups are isolated behind a Mailglass-owned resolver seam, so transient resolver failures and malformed answers become explicit data instead of crashes. | ✓ VERIFIED | `lib/mailglass/deliverability/resolver.ex` wraps OTP `:inet_res` and normalizes `:timeout`, `:nxdomain`, `:servfail`, and `:malformed_answer`; `lib/mailglass/deliverability.ex` stores those in `resolver_errors`; `test/mailglass/deliverability_test.exs` asserts they are captured rather than raised. |
| 3 | The runtime can run one explicit domain plus zero or more explicit DKIM selectors without requiring Repo, Oban, or admin UI state. | ✓ VERIFIED | `Mailglass.Deliverability.run/1` accepts only `domain`, `dkim_selectors`, and `resolver`; no persistence or UI modules are involved; CLI delegates directly to this runtime. |
| 4 | SPF, DKIM, and DMARC findings distinguish structural failure from uncertainty instead of flattening everything into pass/fail. | ✓ VERIFIED | SPF emits `:fail`, `:warn`, `:cannot_verify`, and `:pass`; DKIM emits `:cannot_verify` for missing or malformed selector context; DMARC distinguishes missing, malformed, monitoring, partial enforcement, and enforcement states. Unit tests cover each path. |
| 5 | Explicit DKIM selector input is required for selector-specific checks, and missing selectors become `cannot_verify` with remediation instead of guessed provider folklore. | ✓ VERIFIED | `lib/mailglass/deliverability.ex` only checks selectors supplied by the caller; `lib/mailglass/deliverability/dkim.ex` emits `:selector_required` as `:cannot_verify`; task and formatter tests assert the operator-facing remediation copy. |
| 6 | SPF and DMARC advisories stay standards-aware rather than hiding weak policy behind a pass/fail grade. | ✓ VERIFIED | SPF warns on weak terminal policy and fails at the RFC lookup ceiling; DMARC warns on `p=none`, passes `p=reject`, and surfaces malformed records explicitly. Unit and property tests cover the lookup-limit and policy cases. |
| 7 | MX and BIMI findings stay honest about ambiguity: no MX is not silently treated as broken, and missing BIMI is not treated as failed deliverability. | ✓ VERIFIED | `lib/mailglass/deliverability/mx.ex` warns when MX is absent, passes Null MX as explicit send-only posture, and fails mixed Null MX; `lib/mailglass/deliverability/bimi.ex` warns when BIMI is absent and keeps provider caveats explicit. |
| 8 | Default human output is grouped by SPF, DKIM, DMARC, MX, and BIMI, while verbose evidence is optional and JSON stays machine-readable. | ✓ VERIFIED | `lib/mailglass/deliverability/formatter.ex` renders grouped sections in that order, exposes evidence only when `verbose?: true`, and encodes the shared result with `Jason.encode!/1`; formatter and task tests pin all three behaviors. |
| 9 | A user can run `mix mail.doctor --domain example.com` and get grouped SPF, DKIM, DMARC, MX, and BIMI findings, with strict rejection of hidden inference, unknown flags, positional args, and bad formats. | ✓ VERIFIED | `lib/mix/tasks/mail.doctor.ex` uses strict `OptionParser`, requires `--domain`, repeats `--dkim-selector`, validates `--format`, and rejects positional or unknown args; `test/mix/tasks/mail_doctor_task_test.exs` covers grouped output and each CLI rejection path. |
| 10 | The shipped docs and code preserve the DNS-only truth posture: honest `cannot_verify`, explicit selector contract, and no hidden inference or grading. | ✓ VERIFIED | `README.md` documents one-domain runs, explicit selectors, verbose mode, JSON mode, `schema_version: 1`, and says the doctor does not promise inbox placement certainty or a deliverability grade; no grading or scoring surface exists in the task, runtime, or formatter beyond summary counts. |

**Score:** 10/10 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mailglass/deliverability/result.ex` | Shared schema-versioned finding and summary contract | ✓ VERIFIED | `schema_version`, closed statuses, summary computation, facts buckets, and resolver error normalization are all implemented. |
| `lib/mailglass/deliverability/resolver.ex` | Resolver behaviour and OTP-backed DNS adapter | ✓ VERIFIED | TXT, MX, and CNAME callbacks are implemented over `:inet_res` with normalized error reasons and no raw tuples exposed upstream. |
| `lib/mailglass/deliverability.ex` | Single runtime entrypoint for one-domain doctor runs | ✓ VERIFIED | Validates explicit domain and selectors, collects protocol facts, runs all analyzers, and returns `Mailglass.Deliverability.Result`. |
| `lib/mailglass/deliverability/spf.ex` | SPF analyzer with lookup-pressure and uncertainty accounting | ✓ VERIFIED | Handles missing, multiple, malformed, weak terminal policy, lookup pressure, void lookups, nested uncertainty, and healthy posture. |
| `lib/mailglass/deliverability/dkim.ex` | Explicit-selector DKIM analyzer | ✓ VERIFIED | Handles missing selectors, malformed selector data, CNAME delegation, revoked keys, short keys, and selector-specific pass/warn/fail semantics. |
| `lib/mailglass/deliverability/dmarc.ex` | DMARC policy and tag analyzer | ✓ VERIFIED | Handles missing, multiple, malformed, monitoring, quarantine, reject, and advisory tags such as `rua`, `adkim`, `aspf`, and `sp`. |
| `lib/mailglass/deliverability/mx.ex` | MX and Null MX analyzer | ✓ VERIFIED | Distinguishes malformed MX, missing MX, Null MX send-only posture, conflicting Null MX, and normal MX presence. |
| `lib/mailglass/deliverability/bimi.ex` | BIMI readiness analyzer | ✓ VERIFIED | Handles missing or malformed BIMI, DMARC prerequisite warnings, `l=` and `a=` guidance, and provider caveats without overclaiming display certainty. |
| `lib/mailglass/deliverability/formatter.ex` | Shared human and JSON formatter | ✓ VERIFIED | Human output is grouped and verbose-aware; JSON output serializes the shared result contract directly. |
| `lib/mix/tasks/mail.doctor.ex` | Thin strict CLI wrapper | ✓ VERIFIED | Delegates to runtime and formatter, not to embedded protocol logic, and enforces the shipped flag contract. |
| `test/support/deliverability_resolver_stub.ex` | Deterministic resolver fake | ✓ VERIFIED | Supplies TXT, MX, and CNAME fixtures plus normalized resolver failures for deterministic tests. |
| `test/mix/tasks/mail_doctor_task_test.exs` | CLI contract coverage | ✓ VERIFIED | Covers grouped output, JSON output, verbose evidence, explicit selector posture, and CLI validation failures. |
| `test/mailglass/deliverability/*.exs` | Analyzer and formatter unit coverage | ✓ VERIFIED | Covers shared contract, runtime, SPF, DKIM, DMARC, MX, BIMI, and formatter behavior. |
| `test/mailglass/properties/deliverability_*.exs` | Property coverage for status and SPF pressure semantics | ✓ VERIFIED | Covers closed status domain, `cannot_verify` preservation, and SPF lookup-limit behavior. |
| `README.md` | User-facing deliverability doctor docs | ✓ VERIFIED | Matches the shipped flags and documents the DNS-only, non-grading trust posture. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/mailglass/deliverability.ex` | `lib/mailglass/deliverability/resolver.ex` | Runtime orchestration uses injected resolver module | ✓ WIRED | `run/1` validates `resolver` and passes it through fact collection and SPF analysis. |
| `lib/mailglass/deliverability.ex` | `lib/mailglass/deliverability/result.ex` | Top-level run builds the schema-versioned result map | ✓ WIRED | `Result.new/1` is the final return boundary for domain, selectors, findings, facts, summary, and resolver errors. |
| `test/support/deliverability_resolver_stub.ex` | `test/mailglass/deliverability_test.exs` | Runtime tests prove contract behavior without live DNS | ✓ WIRED | Runtime tests inject the stub and assert normalized facts plus resolver-error capture. |
| `lib/mailglass/deliverability/dkim.ex` | `lib/mailglass/deliverability.ex` | Runtime forwards explicit selector lists only | ✓ WIRED | Runtime gathers only caller-supplied selectors and passes those facts into DKIM analysis. |
| `lib/mailglass/deliverability/spf.ex` | `test/mailglass/properties/deliverability_spf_property_test.exs` | Property tests pin recursion and lookup-limit semantics | ✓ WIRED | Property suite generates SPF trees and proves no `:pass` outcome at or above ten lookups. |
| `lib/mailglass/deliverability/dmarc.ex` | `lib/mailglass/deliverability/result.ex` | Status and remediation copy fit the shared contract | ✓ WIRED | DMARC findings use the required `area`, `check`, `status`, `title`, `why_it_matters`, `observed`, and `remediation` fields. |
| `lib/mailglass/deliverability/bimi.ex` | `lib/mailglass/deliverability/dmarc.ex` | BIMI readiness depends on shared DMARC posture | ✓ WIRED | Runtime passes DMARC posture into BIMI analysis and tests assert the threaded posture. |
| `lib/mailglass/deliverability.ex` | `lib/mailglass/deliverability/{spf,dkim,dmarc,mx,bimi}.ex` | Runtime invokes every analyzer before building the shared result | ✓ WIRED | `analyze_all/2` runs every protocol analyzer and preserves area ordering in findings. |
| `lib/mailglass/deliverability/formatter.ex` | `lib/mailglass/deliverability/result.ex` | Both renderers consume one result contract | ✓ WIRED | Human and JSON rendering both operate directly on the result map. |
| `test/mailglass/deliverability/formatter_test.exs` | `lib/mailglass/deliverability/formatter.ex` | Tests pin grouped headers and machine output stability | ✓ WIRED | Formatter tests assert section order, verbose evidence, and JSON shape. |
| `lib/mix/tasks/mail.doctor.ex` | `lib/mailglass/deliverability.ex` | CLI delegates to the shared runtime | ✓ WIRED | Task uses `Mailglass.Deliverability.run(service_opts(opts))`. |
| `lib/mix/tasks/mail.doctor.ex` | `lib/mailglass/deliverability/formatter.ex` | CLI chooses human or JSON output from the shared formatter | ✓ WIRED | Task routes `"json"` to `render_json/1` and default output to `render_human/2`. |
| `README.md` | `lib/mix/tasks/mail.doctor.ex` | Docs match the exact shipped flags and one-domain contract | ✓ WIRED | README usage matches `--domain`, repeatable `--dkim-selector`, `--verbose`, and `--format json`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/mailglass/deliverability.ex` | `collected.facts`, `collected.resolver_errors` | `Mailglass.Deliverability.Resolver.lookup_txt/1`, `lookup_mx/1`, `lookup_cname/1` | Yes - live OTP resolver in production, deterministic stub in tests | ✓ FLOWING |
| `lib/mailglass/deliverability.ex` | `findings` | `SPF.analyze/2`, `DKIM.analyze/1`, `DMARC.analyze/1`, `MX.analyze/1`, `BIMI.analyze/2` | Yes - analyzers build protocol findings from collected facts | ✓ FLOWING |
| `lib/mailglass/deliverability/result.ex` | `summary` | Derived from `findings` via `summary/1` | Yes - computed from the shared finding list, not formatter-local counting | ✓ FLOWING |
| `lib/mailglass/deliverability/formatter.ex` | `result.summary`, `result.findings` | Shared result returned by `Mailglass.Deliverability.run/1` | Yes - both human and JSON output use the same result payload | ✓ FLOWING |
| `lib/mix/tasks/mail.doctor.ex` | `render_output(result, opts)` | Shared runtime result and formatter mode selection | Yes - CLI prints the formatter output directly | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Deliverability analyzers, shared contract, formatter, and CLI task all pass their focused suites | `mix test test/mailglass/deliverability/*.exs test/mailglass/properties/deliverability_*.exs test/mix/tasks/mail_doctor_task_test.exs --warnings-as-errors` | `3 properties, 41 tests, 0 failures` | ✓ PASS |
| The shipped CLI contract stays in parity with the shared runtime and JSON/human renderers for the same resolver-backed scenario | `mix test test/mix/tasks/mail_doctor_task_test.exs --warnings-as-errors` | `9 tests, 0 failures`; parity test proves CLI human output, CLI JSON output, and direct runtime formatting stay identical for the same end-to-end fixture | ✓ PASS |
| Phase plans all map to the same requirement IDs | `sed -n '/^requirements:/,/^tags:/p' .planning/phases/25-deliverability-doctor/*-PLAN.md` | All four plans declare `DOCTOR-01`, `DOCTOR-02`, `DOCTOR-03` | ✓ PASS |
| No placeholder or incomplete markers appear in the phase 25 deliverability files | `rg -n -i 'TODO|FIXME|XXX|HACK|PLACEHOLDER|coming soon|will be here|not yet implemented|not available|console\\.log' ...phase-25-files...` | No matches in scanned implementation, tests, or README sections | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `DOCTOR-01` | `25-01` to `25-04` | User can run `mix mail.doctor` against a domain and receive SPF, DKIM, DMARC, MX, and BIMI findings. | ✓ SATISFIED | Runtime runs all five analyzers; formatter groups all five sections; task tests assert grouped operator output for all protocol areas. |
| `DOCTOR-02` | `25-01` to `25-04` | `mix mail.doctor` classifies findings as pass, warn, fail, or cannot-verify. | ✓ SATISFIED | `Result.statuses/0` closes the status set; analyzers emit all four statuses; result and property tests pin summary counting and `cannot_verify` preservation. |
| `DOCTOR-03` | `25-01` to `25-04` | `mix mail.doctor` explains remediation in operator-facing language without overstating certainty. | ✓ SATISFIED | Every analyzer emits `title`, `why_it_matters`, `observed`, and `remediation`; README and BIMI/MX/DMARC wording explicitly avoid inbox-placement certainty or grading. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No placeholder, TODO, FIXME, console-only, or obvious stub markers were found in the scoped phase-25 implementation and tests. | ℹ️ Info | No anti-pattern blockers detected in the verified scope. |

### Human Verification Required

None. The live DNS boundary is intentionally treated as an external adapter contract rather than a manual UAT gate for Phase 25. The shipped acceptance surface is now covered by deterministic end-to-end tests that drive `mix mail.doctor` through the injected resolver seam and prove human-output parity, JSON-output parity, and runtime-contract parity for the same scenario.

### Gaps Summary

No code or wiring gaps were found in the phase 25 implementation. The deliverability runtime, analyzers, formatter, CLI wrapper, tests, and README all satisfy the planned must-haves and the phase's DOCTOR requirements. Human UAT is no longer required because the shipped CLI contract now has deterministic end-to-end parity coverage in CI.

---

_Verified: 2026-05-01T20:59:48Z_
_Verifier: Claude (gsd-verifier)_
