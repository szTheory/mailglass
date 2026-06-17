---
phase: 105-onboarding-docs-quickstart-fix-learning-arc
reviewed: 2026-06-17T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - README.md
  - guides/learning-path.md
  - guides/getting-started.md
  - guides/migration-from-swoosh.md
  - mix.exs
  - test/mailglass/docs_contract_test.exs
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Phase 105: Code Review Report

**Reviewed:** 2026-06-17
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Phase 105 is a docs-only onboarding improvement covering four DOCS items: a config-first README
Quickstart fix (DOCS-01), getting-started reorder with troubleshooting update (DOCS-02), a new
`guides/learning-path.md` learning arc (DOCS-03), and a value-prop opener + pin bump in the
migration guide (DOCS-04). The implementation is largely correct and the contract tests are well
constructed. Three warnings and two info items are present.

The most significant finding is a factual inaccuracy: `guides/getting-started.md` references "before
version 1.7" as the version boundary for the new fail-closed installer behavior, but `@version` in
`mix.exs` is `"1.6.2"` and no 1.7.x release exists yet on Hex. Current published HexDocs (1.6.2)
do not include the Phase 104 fail-closed code, so the troubleshooting text describes behavior that
1.6.2 adopters cannot observe.

The contract test for the migration guide's dep-pin fix is logically incomplete: it refutes the old
`~> 0.3` pin but does not positively assert the correct `~> 1.6` pin is present, leaving a coverage
gap. A third warning covers a test that bundles unrelated concerns under a misleading name.

---

## Warnings

### WR-01: Troubleshooting entry references a non-existent version ("before version 1.7")

**File:** `guides/getting-started.md:113`
**Issue:** The updated 401-troubleshooting entry reads:

> "**If you installed mailglass before version 1.7:**"

The current Hex-published version is `1.6.2` (confirmed by `mix.exs` `@version`). Phase 104's
fail-closed installer behavior is on the `main` branch but has not shipped to Hex and will not ship
until a future release. No version 1.7 exists. Any adopter reading the 1.6.2 HexDocs — or the
current README on hex.pm — will encounter:

1. A troubleshooting step that says "mailglass.install now fails closed," which 1.6.2 does **not** do.
2. A reference to `mix mailglass.doctor`, which does not exist in the 1.6.2 Hex package.

The note `"If you installed mailglass before version 1.7"` embeds a speculative future version number
not decided by any planning artifact. The 105-CONTEXT.md D-07 requirement says "do not over-claim."
Claiming "version 1.7" as a fact is an over-claim.

**Fix:** Use a forward-looking description that does not hard-code an unreleased version number:

```markdown
**If you installed mailglass before the fail-closed installer was introduced
(check `mix mailglass.doctor` — if the task is unavailable, your version predates it):**
```

Or, if the intent is to gate on the Phase 104 release, note the caveat:

```markdown
**If you installed mailglass before version 1.7 (not yet released at time of writing —
check `mix mailglass.doctor --help` to confirm it is available):**
```

This keeps the content accurate on main while being honest with 1.6.2 adopters who will read the
published docs before the next Hex release ships.

---

### WR-02: Contract test for migration guide dep-pin fix is negation-only — no positive assertion

**File:** `test/mailglass/docs_contract_test.exs:196`
**Issue:** The DOCS-04 contract assertion for the stale-pin fix is:

```elixir
refute migration =~ "~> 0.3", "migration-from-swoosh.md still contains stale ~> 0.3 pin"
```

This only verifies the old pin is absent. If the dep block were deleted entirely, or the pins were
changed to `~> 0.9` (or any version other than `0.3`), the assertion would still pass even though
the guide would be wrong or empty. There is no corresponding positive assertion that `~> 1.6` (the
correct current pin, consistent with the dynamic version check in the installation test) is present.

The existing "installation snippet targets the current stable surface" test dynamically checks README
pins against `Mix.Project.config()[:version]`, which prevents silent drift. The migration guide gets
no equivalent protection.

**Fix:** Add a positive assertion alongside the refute. The simplest safe form (no version drift if
the major stays 1.x) is:

```elixir
# Positive: correct major-series pin is present
assert migration =~ ~r/\{:mailglass,\s*"~>\s*1\.\d+"\}/,
       "migration-from-swoosh.md dep pin for :mailglass is missing or wrong major series"
assert migration =~ ~r/\{:mailglass_admin,\s*"~>\s*1\.\d+"\}/,
       "migration-from-swoosh.md dep pin for :mailglass_admin is missing or wrong major series"

# Negative: stale 0.3 pin is gone
refute migration =~ "~> 0.3", "migration-from-swoosh.md still contains stale ~> 0.3 pin"
```

A regex anchored to `1.\d+` survives future minor bumps (1.7, 1.8, …) without needing to update
this test on every release, unlike a hardcoded `"~> 1.6"` string check.

---

### WR-03: Contract test "Getting Started ends on a Next steps section" asserts unrelated troubleshooting content under a misleading name

**File:** `test/mailglass/docs_contract_test.exs:132`
**Issue:** The test named `"Getting Started ends on a Next steps section"` contains three distinct
assertions:

1. That the last `## ` heading is `"Next steps"` (DOCS-02 heading-order requirement)
2. That `"learning-path.md"` is linked from the file (DOCS-02 Next steps content)
3. That `"mix mailglass.doctor"` appears in the file (the Phase 104 troubleshooting update)

The third assertion has a failure message `"getting-started.md Troubleshooting must describe mix
mailglass.doctor"` that references "Troubleshooting" — a different section from the one the test
is named for. This is not wrong today, but it creates a maintenance hazard: if the two concerns
need to evolve independently (e.g., the troubleshooting section is extracted to a separate file in
Phase 106), a future author has to parse why a test named "ends on a Next steps section" is also
gatekeeping `mix mailglass.doctor`.

Additionally, this test is currently the only contract gate that verifies the Phase 104 fail-closed
prose is present. If WR-01 is fixed by softening the version claim and the `mix mailglass.doctor`
assertion is removed or loosened, that prose goes uncontracted.

**Fix:** Split the `mix mailglass.doctor` assertion into a separate test with an accurate name:

```elixir
test "Getting Started troubleshooting describes the fail-closed installer and doctor task" do
  getting_started = File.read!("guides/getting-started.md")

  assert getting_started =~ "mix mailglass.doctor",
         "getting-started.md Troubleshooting must describe mix mailglass.doctor"
  assert getting_started =~ "--force",
         "getting-started.md Troubleshooting must describe the --force escape hatch"
end
```

This also adds the `--force` assertion, which is explicitly listed as a must-have in `105-03-PLAN.md`
but is absent from the current contract tests.

---

## Info

### IN-01: `guides/rate-limiting.md` is listed in the README Documentation index but is not registered in `mix.exs` extras

**File:** `README.md:286`
**Issue:** The README Documentation index ends with:

```markdown
- [`guides/rate-limiting.md`](guides/rate-limiting.md) — multi-bucket throughput protection
```

But `guides/rate-limiting.md` is not present in `mix.exs` `extras:` or `groups_for_extras:`. This
means HexDocs will not render that guide as a page, so the link in the README will 404 on
HexDocs.

This is a **pre-existing issue** not introduced by Phase 105 (the entry was in the README before any
Phase 105 commits, confirmed by `git show 45781f4b:README.md`). Phase 105 edited the README
Documentation section (adding the learning-path link) without fixing the pre-existing
rate-limiting gap. Flagging here because the phase touched this section.

**Fix:** Either register `guides/rate-limiting.md` in both `extras:` and `groups_for_extras:
[Guides: ...]` (mirroring the pattern for every other guide), or remove the README link until the
guide is registered. The `mailglass.docs.check` Mix task should catch this in CI if it performs a
cross-reference check.

---

### IN-02: The contract test for learning-path registration does not verify the guides linked FROM the index exist on disk

**File:** `test/mailglass/docs_contract_test.exs:151`
**Issue:** The `"learning-path is registered in both mix.exs docs lists"` test verifies:

1. `File.exists?("guides/learning-path.md")` — the index file itself exists.
2. `Regex.scan(~r/"guides\/learning-path\.md"/, mix_exs)` — both registration points are present.

It does not verify that the seven guides linked from within `learning-path.md` exist on disk
(`jobs.md`, `authoring-mailables.md`, `preview.md`, `webhooks.md`, `testing.md`, `telemetry.md`,
and the four "Going deeper" guides). All seven currently exist, so there is no runtime breakage.
However, if a guide is renamed or removed in a future phase, the learning-path index will silently
have broken links with no test catching it.

**Fix (optional, for Phase 106):** Add existence assertions for the guides that `learning-path.md`
links to. A compact form:

```elixir
for guide <- ~w[
  guides/jobs.md
  guides/authoring-mailables.md
  guides/preview.md
  guides/webhooks.md
  guides/testing.md
  guides/telemetry.md
  guides/multi-tenancy.md
  guides/dkim-setup.md
  guides/unsubscribe.md
  guides/migration-from-swoosh.md
] do
  assert File.exists?(guide), "learning-path.md links to #{guide} but the file does not exist"
end
```

---

_Reviewed: 2026-06-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
