---
phase: 72-contract-docs-and-stale
reviewed: 2026-06-02T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - guides/compatibility-and-deprecations.md
  - guides/jobs.md
  - lib/mix/tasks/mailglass.docs.check.ex
  - mailglass_inbound/mix.exs
  - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/stability_contract_test.exs
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# Phase 72: Code Review Report

**Reviewed:** 2026-06-02T00:00:00Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

This phase ships contract/documentation surfaces: two adopter guides
(`compatibility-and-deprecations.md`, `jobs.md`), the `mix mailglass.docs.check`
Tier 1 docs-drift guard, the `mailglass_inbound` mix project, and three
contract test suites. No production runtime logic is in scope, so there are no
security or correctness BLOCKERs — but the value of this phase is the
*enforcement* these files provide, and several of the guard mechanisms are
weaker than they appear.

I verified the substantive claims rather than assuming them: every relative
doc link in both guides resolves; all 28 `@tier1_surface_rules` keys map
exactly 1:1 onto `@tier1_paths` (no rule is silently un-runnable under a
default invocation); the `verify.phase_*` deprecation-bridge claim in the
compatibility guide is backed by real aliases in `mix.exs`; the
`resolve_outbound_adapter_ref/1` example in jobs.md Job 10 returns shapes
(`{:ok, ref}` / `:default`) that match the actual `@callback` contract and the
consumer in `outbound.ex`; and the error modules referenced by the closed-type
introspection tests all define `__types__/0`. Those checks came back clean.

The findings below are about guard robustness and doc/code-comment quality —
places where a test or check will pass while providing less protection than its
name implies, or where stale-comment / brittle-assertion patterns invite future
drift.

## Warnings

### WR-01: `changelog_unreleased` over-claims provide false confidence while the section is empty

**File:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:542,552-554`
**Issue:** The test extracts the `## [Unreleased]` changelog section and then
runs `refute changelog_unreleased =~ blocked` and `refute_over_claims!` against
it. In its normal between-releases state the Unreleased section contains only
`"No unreleased changes yet."` (confirmed in `mailglass_inbound/CHANGELOG.md:8-10`).
A `refute ... =~` against a stub paragraph is vacuously true, so these guards
provide zero protection precisely when the changelog is in its default state —
the test is green whether or not the protection is meaningful. A real
over-claim added during a future release-prep edit is only caught if it lands
in the brief window the section is populated.
**Fix:** Either assert the section is non-empty before treating the refutes as
meaningful, or move the over-claim guard to a stable always-populated surface
(e.g. the latest released changelog section, or the README active region which
the test already extracts). For example, add a positive guard that fails loudly
if the section is the empty stub when a release is being prepared, so the
absence of protection is visible rather than silent.

### WR-02: `--path` glob runs only `leak_issues` on matched files, silently skipping all surface/preview/trust rules

**File:** `lib/mix/tasks/mailglass.docs.check.ex:465-478,496-501`
**Issue:** When invoked as `mix mailglass.docs.check --path "guides/**/*.md"`
(the exact form shown in the moduledoc usage block, line 15), `docs_paths/1`
returns the glob result, and `tier1_surface_issues/1` /
`preview_boundary_issues/1` / `trust_boundary_issues/1` all filter rules by
`MapSet.member?(selected_paths, path)` against *exact* rule-key strings. A glob
like `guides/**/*.md` returns `guides/preview.md`, `guides/testing.md`, etc.,
which do match the rule keys — but a glob that produces a path in any
non-canonical form (`./guides/preview.md`, an absolute path, or a deeper-nested
file) silently matches no rule and runs only the leak check. The task still
prints `OK — Tier 1 docs match the stability contract`, giving the operator a
false "fully checked" signal. There is no warning that surface rules were not
applied to a requested path.
**Fix:** When `--path` yields files that have surface rules but the path form
differs from the rule key, normalize with `Path.relative_to_cwd/1` before the
`MapSet.member?` comparison, or emit an informational notice listing which
selected paths had no matching surface rule so the operator knows the run was
leak-only for those files.

### WR-03: Brittle exact-version assertions in stability test will break on every release ceremony

**File:** `test/mailglass/stability_contract_test.exs:116-147`
**Issue:** The `"inbound 1.0 release preflight truth..."` test hardcodes
`expected_version = "1.0.0"` and `expected_core_version = "1.3.0"` and asserts
them against the manifest, mix.exs `@version`, the publish summary, and the
core pin. The same file's *other* tests (lines 94, 105-106, 113) deliberately
use SemVer-pattern regexes and document in comments that exact pins "[do] not
need updating per release." Mixing a hardcoded-exact assertion into a suite
that otherwise went out of its way to be ceremony-agnostic means the next
linked-version bump (e.g. core to `1.4.0` / inbound to `1.1.0`) will red this
single test even though nothing is actually wrong — exactly the per-release
maintenance toil the surrounding tests were written to avoid. This is a known
recurring pain point for this repo (see the `@version` / pin drift commits in
recent history).
**Fix:** Decide intentionally: if this test must pin `1.0.0`/`1.3.0` as a
*frozen* preflight snapshot, add a comment saying so and that it is expected to
be updated by the release ceremony (so future maintainers do not treat the red
as a bug). Otherwise convert the assertions to read the expected values from
the manifest/mix.exs (e.g. `manifest["mailglass_inbound"]`) and assert
*internal consistency* across the artifacts rather than a literal string,
matching the ceremony-agnostic style of the neighboring tests.

### WR-04: `mailglass_dep/0` MIX_PUBLISH pin (`== 1.3.0`) drifts independently from the `@version` and is unguarded in-source

**File:** `mailglass_inbound/mix.exs:110-116`
**Issue:** `mailglass_dep/0` hardcodes `{:mailglass, "== 1.3.0"}` for published
builds while `@version "1.0.0"` (line 4) is the inbound package version. These
two numbers are independently editable strings in the same file with no
compile-time or test-time link asserting the publish pin tracks the *core*
release line. The release-please sync step is documented (in
`stability_contract_test.exs:102-106`) to bump both on the ceremony branch, but
nothing in this file fails fast if a hand-edit updates `@version` and forgets
the pin (or vice versa). A stale `== 1.3.0` shipped against a core `1.4.0`
would silently publish an inbound package that cannot resolve its sibling.
**Fix:** This is partially covered by `stability_contract_test.exs:116-147`
(WR-03), but that test hardcodes the same literals it is meant to protect, so a
coordinated wrong-edit to both files passes. Consider deriving the publish pin
from the core `mix.exs` `@version` at release-prep time, or add a test that
reads the core package version and asserts the inbound publish pin matches it,
rather than asserting both against a hardcoded constant.

## Info

### IN-01: Stale phase-number comment in skipped test references archived artifacts

**File:** `test/mailglass/docs_contract_test.exs:249-261`
**Issue:** The `@tag :skip` Phase 38 test carries a multi-line comment ending
"Phase 51 closeout should re-pin these assertions to the v1.0/1.1
release-record format." This is a long-lived skipped test whose TODO references
a phase (51) that, per current milestone state, has come and gone without the
re-pin happening. A permanently-skipped test with a stale follow-up note is
dead weight that future readers must re-investigate.
**Fix:** Either action the re-pin against
`044.5-RELEASE-RECORD.md`, or delete the skipped test and capture the intent in
a planning artifact rather than carrying an inert test body.

### IN-02: Mojibake / empty-parenthetical artifacts in the Tenancy moduledoc surfaced via jobs.md review

**File:** `lib/mailglass/tenancy.ex:90,93,96` (reached while verifying the
jobs.md Job 10 contract)
**Issue:** The docstring contains `verified webhook context ().` and
`'s "verify-first..."` and `'s "verify-first, tenant-second"` — the leading
noun before `'s` is missing, and `()` is an empty parenthetical. These read as
a find/replace or encoding casualty. Not in the changed file set for this
phase, but it is the public contract jobs.md Job 10 points adopters at, so it
undermines the "thoughtful maintainer" voice at a high-traffic doc entry point.
**Fix:** Restore the elided subject (likely "Mailglass" or the behaviour name)
and drop the empty `()`. Flagging as Info since it is out of this phase's diff.

### IN-03: jobs.md Job 3 mailable example interpolates a URL directly into HTML

**File:** `guides/jobs.md:165-169`
**Issue:** The password-reset example builds `html_body("<p>Reset it here:
#{url}</p>")` by raw string interpolation. The guide's own framing (Job 3 is
"an auth email you can trust") sits awkwardly next to an HTML-injection-shaped
snippet — if `url` ever carried untrusted content this is an XSS pattern, and
copy-paste-driven adopters tend to generalize the shape. The snippet parses and
is not itself exploitable (the URL is app-generated), so this is doc-quality
guidance, not a live vulnerability.
**Fix:** Prefer the HEEx component path shown in Job 1 (`<.button href={url}>`)
which escapes attributes, or add a one-line note that auth URLs are
app-generated and reach for components when interpolating any user-influenced
value into HTML bodies.

### IN-04: `nearby_non_contract_framing?/2` re-reads the file per candidate line

**File:** `lib/mix/tasks/mailglass.docs.check.ex:561-580`
**Issue:** Inside `trust_boundary_issues/1`'s per-line `Enum.flat_map`, each
line that matches both the internal-detail and contract-claim regexes triggers
`nearby_non_contract_framing?/2`, which calls `File.read!(path)` and re-splits
the whole file again. The outer loop already holds the split lines. This is
redundant I/O, not a correctness bug (and performance is out of v1 scope), but
it is a maintainability smell in an otherwise tidy module.
**Fix:** Pass the already-split `lines` list into the helper instead of
re-reading from disk, so the function works on in-memory data and the file is
read once per path.

---

_Reviewed: 2026-06-02T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
