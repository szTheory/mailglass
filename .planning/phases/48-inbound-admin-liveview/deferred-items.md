# Deferred Items — Phase 48

Out-of-scope discoveries logged during execution (not fixed; surfaced for later).

## From Plan 48-01 (Wave 0)

- **Pre-existing Credo warning in `mailglass_admin/test/support/citext_probe.ex:36`**
  — `mix credo --strict` reports `[W] Use reraise inside a rescue block to
  preserve the original stacktrace`. This file was NOT modified by Plan 48-01
  (last changed in commit 6b4732f). It causes `mix credo --strict` to exit 16
  (warning-level). It is unrelated to the inbound admin seams and is out of scope
  per the executor SCOPE BOUNDARY rule. No PrefixedPubSubTopics (LINT-06)
  violation is present — all topics route through `MailglassAdmin.PubSub.Topics`.

- **Custom `Mailglass.Credo.*` checks report as "undefined" in the admin
  worktree** — the twelve custom checks (incl. `PrefixedPubSubTopics`) live in the
  core `mailglass` package and are not compiled into the admin's credo run in this
  worktree environment. Plan 48-01's PubSub code is compliant with the LINT-06
  rule (no literal topic strings at call sites; the builder is the single source).
