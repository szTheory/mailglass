---
created: 2026-06-30T05:10:00.000Z
title: Remove the cowlib advisory allowlist when upstream ships a fix
area: tooling
trigger: cowlib publishes a release that fixes EEF-CVE-2026-43966 and/or EEF-CVE-2026-43969
resolves_phase: 142
files:
  - lib/mix/tasks/mailglass.publish.check.ex
  - test/mailglass/publish/audit_allowlist_test.exs
  - mailglass_admin/mix.lock
---

## Resolution

Closed 2026-07-29 by Phase 142/VULN-05, VULN-06 — but NOT via this todo's
literal trigger. `mix hex.audit` still reports both `EEF-CVE-2026-43966` and
`EEF-CVE-2026-43969` live in `mailglass_admin` as of 2026-07-28/29 (verified:
`mix mailglass.audit --kind hex` names both as accepted-allowlist findings,
not silence) — cowlib 2.19.0 has NOT shipped an upstream fix. Neither entry
is removed.

The todo is closed anyway because its underlying need — "a human must
remember to revisit this allowlist" — is now automated instead of manual.
`Mailglass.SupplyChain.AcceptedAdvisories.expired_entries/1` (recheck_by
staleness, `~D[2026-10-26]` for both entries) and `.unused_entries/1`
(matched-finding staleness) run on every `mix mailglass.audit --kind hex`
invocation, superseding the "watch for an upstream release" manual trigger
this todo originally proposed. The allowlist itself moved from
`@accepted_advisories` in `mailglass.publish.check.ex` to the single shared
`lib/mailglass/supply_chain/accepted_advisories.ex` module both
`mailglass.publish.check` and `mailglass.audit` now read.

When cowlib does ship a fix, this todo's original `## Action` steps 1-4 still
apply in spirit — bump the dep, then remove the matching entry/entries from
`Mailglass.SupplyChain.AcceptedAdvisories`'s `@entries` list (not
`@accepted_advisories`, which no longer exists) — but `expired_entries/1`
will independently start blocking on `2026-10-27` regardless, so the fix is
no longer solely dependent on a maintainer remembering to check.

## Problem

During the v1.14 release (2026-06-30), the `publish.check` Step-13 `hex.audit`
gate was blocked by two **unfixable** cowlib advisories — no patched cowlib
release exists in any version (introduced 2.9.0, unfixed through 2.17.1), and
cowlib is an unavoidable transitive web-stack dep (cowboy → plug_cowboy →
phoenix):

- `EEF-CVE-2026-43966` (MEDIUM) — HTTP Response Splitting via non-VCHAR bytes
- `EEF-CVE-2026-43969` (LOW) — Cookie Request Header Injection

To ship, a **narrow, documented allowlist** (`@accepted_advisories` in
`mailglass.publish.check.ex`) was added that accepts ONLY these two specific
advisory IDs while still hard-blocking on retired packages and every other /
fixable advisory. Regression test: `test/mailglass/publish/audit_allowlist_test.exs`.

This allowlist is **temporary** — it deliberately accepts a known (unpatched)
MEDIUM+LOW risk only because there is no fix to take.

## Action (when the trigger fires)

1. Bump cowlib to the fixed version across the package locks (admin lock carries
   cowlib; root/inbound do not — confirm via `grep '"cowlib"' */mix.lock`).
   Prefer the minimal patched version (`mix deps.update cowlib`, verify with OSV).
2. Remove the matching entry/entries from `@accepted_advisories` in
   `lib/mix/tasks/mailglass.publish.check.ex` (and the comment block above it).
3. Update `test/mailglass/publish/audit_allowlist_test.exs` so the removed IDs no
   longer appear in the "accepted" case (keep the "fixable advisory still blocks"
   + "retired never accepted" guards).
4. Confirm `mix hex.audit` (on a CI/publish runner — local hex can't see fresh
   advisories) reports cowlib clean.

## Context

Full narrative: `.planning/threads/v1.14-release-paused-dep-security-wave.md`,
`.planning/milestones/v1.14-MILESTONE-AUDIT.md`. Maintenance-tier — `/gsd-quick`
when the trigger fires, not a milestone.
