# Maintaining Mailglass

This document covers the release flow and maintenance protocols for Mailglass.

## Release Flow

Mailglass uses [Release Please](https://github.com/googleapis/release-please) to automate versioning and changelogs.

1. Merge feature branches into `main` using Conventional Commits.
2. Release Please will open a "Release PR" with the version bump and updated `CHANGELOG.md`.
3. Merging the Release PR triggers the `publish-hex` workflow.
4. The `publish-hex` workflow is environment-gated and requires manual approval in the GitHub Actions UI.

## Snapshot Update Protocol

When the installer output or golden files change:

1. Run `mix verify.installer.golden`.
2. If the failure is expected, update the golden files in `test/fixtures/`.
3. Commit the updated fixtures with a `chore: update installer golden files` message.

## Required Checks

Before merging any PR, ensure:
- `mix compile --warnings-as-errors`
- `mix test --warnings-as-errors`
- `mix credo --strict`
- `mix dialyzer`
- `mix docs --warnings-as-errors`

## Bus Factor & Continuity

Mailglass is single-maintainer at v0.1. The release pipeline is gated on a GitHub
Environment (`hex-publish`) with a single required reviewer (`szTheory`). When a
GitHub Environment has only one reviewer, GitHub silently disables the
`prevent_self_review` setting — the gate is effectively a one-eye pause, not a
two-eyes review. This is documented honestly here rather than presented as a
stronger control than it is. Multi-owner Hex transition is deferred to v0.5,
when production adopters exist (D-26 rationale: at v0.1 the asymmetry of a
co-owner being able to `mix hex.publish` from their own machine bypassing
GitHub governance is a worse footgun than the bus-factor risk it solves).

If `szTheory` is unreachable for more than 30 days, the community can request a
Hex.pm package transfer by opening a public issue titled
`Maintainer-unreachable: requesting Hex transfer` on
https://github.com/szTheory/mailglass/issues — Hex.pm's public maintainer-transfer
process can be initiated from there.

## Retract Decision Tree

Five rules. Bias toward patch over retract — three retractions in your first six
months tells evaluators "don't bet on this lib."

1. **Data-loss / security / signature bypass / fails to compile.**
   Run `mix hex.retire <pkg> <ver> security|invalid --message "<140 chars>"`
   AND ship `<ver+1>` immediately.
2. **User-visible breakage with workaround.**
   Do NOT retire. Patch within 7 days. Add a CHANGELOG entry.
3. **Cosmetic / docs / non-runtime.**
   Do NOT retire. Roll into next planned patch.
4. **Published less than 60 minutes ago AND zero downloads.**
   Run `mix hex.publish --revert <ver>` (only window where unpublish works —
   also bounded by Hex.pm's 24-hour initial-release window).
5. **Already retired and false alarm.**
   Run `mix hex.retire <pkg> <ver> --unretire`.

## Security Response SLA

Single-maintainer numbers, written to be kept rather than aspired to.

- **Acknowledgement of report:** within 72 hours.
- **Mitigation or workaround for critical issues:** within 14 days.
- **Public security advisory:** published alongside the fix.

Critical issue classes are listed in `SECURITY.md` (`## Critical Classes`).
Reports go through the disclosure address documented there or via GitHub
Private Vulnerability Reporting if no email is reachable.

## Release Runbook

Five steps. Step 4 has a literal 60-minute timer — that is the last revert
window before the published artifact becomes permanent.

1. **Verify CI green on `main` for the SHA to be released.**
   Check `actions/workflows/ci.yml` — required because publish-hex.yml gates
   on this SHA via the `gate-ci-green` job (per Plan 08, D-16).
2. **Merge the release-please PR.**
   Squash-merge keeps the changelog history linear. The merge commit is what
   release-please tags as `mailglass-sibling-group-v<version>`.
3. **Approve the `hex-publish` deployment in the GitHub Environment UI.**
   Review the pre-publish summary in the workflow run page (rendered by the
   `prepublish-summary` job per D-15) BEFORE clicking Approve. Verify the
   file count, total size, CHANGELOG excerpt, and top files all match
   expectations.
4. **Within 60 minutes of publish: smoke-install in a fresh Phoenix app.**
   Set a literal timer when approving the deployment.
   Run:

       mix archive.install hex phx_new --force
       mix phx.new sandbox --no-ecto --no-mailer --install
       cd sandbox
       # add {:mailglass, "~> 0.1"}, {:mailglass_admin, "~> 0.1"} to deps
       mix deps.get && mix mailglass.install --yes && mix compile --warnings-as-errors
       mix phx.server  # visit http://localhost:4000/dev/mail/

   If anything fails AND the publish was less than 60 minutes ago AND zero
   downloads have happened, the Retract Decision Tree rule 4
   (`mix hex.publish --revert`) is reachable. After 60 minutes the only
   options are retire-then-patch (rule 1) or patch-only (rule 2).

   The post-publish-smoke workflow (`.github/workflows/post-publish-smoke.yml`,
   Plan 09) runs the same smoke automatically — but it does not respect the
   60-minute window. Run the manual smoke during the window regardless.
5. **Post the release link to Elixir Forum #libraries section** (post-publish, optional
   — performed by maintainer on their own cadence; not gated by Phase 07.1's
   milestone-shipped marker per CONTEXT line 14 / line 351).
   Body equals the GitHub Release narrative (CHANGELOG entry verbatim plus
   one framing paragraph for 0.x.0 minor bumps; verbatim CHANGELOG only for
   patches).
