# Maintaining Mailglass

This document covers the release flow and maintenance protocols for Mailglass.

## Release Flow

Mailglass uses [Release Please](https://github.com/googleapis/release-please) to automate versioning and changelogs.

1. Merge feature branches into `main` using Conventional Commits.
2. Release Please will open a "Release PR" with the version bump and updated `CHANGELOG.md`.
3. Merging the Release PR should trigger the `publish-hex` workflow from the
   published GitHub Release. If downstream workflow fan-out does not happen,
   `workflow_dispatch` with the core release tag (`mailglass-v<version>`) is the canonical maintainer
   fallback.
4. The `publish-hex` workflow is environment-gated and requires manual approval in the GitHub Actions UI.

## Snapshot Update Protocol

When the installer output or golden files change:

1. Run `mix verify.installer.golden`.
2. If the failure is expected, update the golden files in `test/fixtures/`.
3. Commit the updated fixtures with a `chore: update installer golden files` message.

## Publish Summary Snapshot Protocol

The files under `.planning/publish/*-publish-summary.json` are tracked release
proof snapshots, not scratch output.

- Refresh them with `mix mailglass.publish.check` for the affected package(s).
- Review the diff together with the paired `*-files.expected` allowlist diff.
- Commit the snapshot update when the underlying package contents or version
  truth changed intentionally.

Do not gitignore these files: `test/mailglass/stability_contract_test.exs`
reads the inbound summary directly as part of the sibling-package release
contract.

## JTBD Docs Refresh Protocol

The JTBD docs are a two-file system:

- `guides/jobs.md` is the **public adopter ramp-up guide**
- `.planning/research/JTBD-COVERAGE.md` is the **internal source of truth**

Always refresh the internal map first, then project the stable Built rows into
the public guide.

### Refresh order

1. Read the current:
   - `guides/jobs.md`
   - `.planning/research/JTBD-COVERAGE.md`
   - `README.md`
   - `CHANGELOG.md`
   - `.planning/PROJECT.md`
   - `.planning/ROADMAP.md`
   - `.planning/REQUIREMENTS.md`
   - `.planning/STATE.md`
2. Reconcile shipped behavior against live code. When planning artifacts
   disagree, prefer live code, then `PROJECT.md`, then `ROADMAP.md`, then phase
   summaries/verification, and treat `STATE.md` as last-resort bookkeeping.
3. Run a primary-source ecosystem sanity check before changing priority claims.
   Current comparison set:
   - Rails Action Mailer
   - Rails Action Mailbox
   - Anymail
   - Laravel Mail
   - Resend inbound docs
4. Update `.planning/research/JTBD-COVERAGE.md`:
   - refresh built/planned/deferred statuses
   - refresh the active gap list
   - refresh the priority ordering
   - refresh the diminishing-returns line
   - append a row to the refresh log
5. Update `guides/jobs.md` from that map:
   - stable shipped jobs only
   - keep the narrative, adopter-facing framing
   - keep inbound summarized separately while it remains outside the `v1.x`
     promise
6. Refresh dates in both files with exact calendar dates.
7. Update README or docs navigation only if the JTBD docs became harder to
   discover.
8. Run the docs contract tests before merging.

### Guardrails

- Do not let `guides/jobs.md` become a roadmap doc.
- Do not let `JTBD-COVERAGE.md` become feature-inventory churn; it is about
  adopter jobs, gaps, and priority.
- If external research reveals only convenience asks, do not promote them above
  trust-proof or inbound-maturity work.

## Required Checks

Before merging any PR, ensure:
- `mix verify.stability_contract`
- `scripts/verify_support_contract.sh`
- `Support Contract Core`
- `Support Contract Admin`
- `Compile No Optional Deps`
- `mix credo --strict`
- `mix dialyzer`
- `mix docs --warnings-as-errors`

The honest repo-root entrypoint is `mix verify.stability_contract` or
`scripts/verify_support_contract.sh`. They run the three required
branch-protection buckets plus the inbound sibling-package docs lane in sequence:
- `Support Contract Core`
- `Support Contract Admin`
- `mailglass_inbound` docs contract (`mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`)
- `Compile No Optional Deps`

Branch protection truth is narrower than "everything we like to run in CI".
The exact required contexts are:
- `Support Contract Core (Elixir 1.18 / OTP 27)`
- `Support Contract Admin (Elixir 1.18 / OTP 27)`
- `Compile No Optional Deps (Elixir 1.18 / OTP 27)`

Owner-applied branch protection:
- `GH_TOKEN=<admin-pat> ./scripts/setup_branch_protection.sh main`

Read-only branch-protection verification:
- `./scripts/verify-branch-protection.sh --print-expected`
- `./scripts/verify-branch-protection.sh --print-expected-json`
- `GH_TOKEN=<admin-pat> ./scripts/verify-branch-protection.sh main`

When those checks pass, they prove the current compatibility contract described
in [`guides/compatibility-and-deprecations.md`](guides/compatibility-and-deprecations.md):
runtime floors, matched sibling-package docs wiring for `mailglass_inbound`,
matched `mailglass_admin` release truth, and the required-vs-advisory split
below. Do not claim broader support than those repo artifacts prove.

The following checks are advisory signal, not branch-protection truth:
- `Format Check`
- `Compile Warnings as Errors`
- `Mix Task Tests`
- `Inbound Test`
- `Inbound Compile No Optional Deps`
- `Operator Browser Gate`
- `Preview Capture Advisory`
- `Core Full Suite Advisory`
- `Provider Compatibility Advisory`
- `Branch Protection Advisory`
- `Provider Live Advisory`

`Provider Live Advisory` remains a cron and `workflow_dispatch` canary. It is not a merge blocker.

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
   If the fix changes a documented compatibility bridge or support claim, update
   `guides/compatibility-and-deprecations.md` in the same patch.
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

Use the Phase 38 release-day proof forms while running these steps:
- `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-CHECKLIST.md`
- `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md`

The checklist separates repo-proved gates from manual/external proof and forces
explicit capture of the tag, workflow run URLs, approver identity, fallback
usage, Hex/HexDocs checks, branch-protection result, and 60-minute outcome.

1. **Verify CI green on `main` for the SHA to be released.**
   Check `actions/workflows/ci.yml` — required because publish-hex.yml gates
   on this SHA via the `gate-ci-green` job (per Plan 08, D-16).
   The required release-truth buckets are:
   - `Support Contract Core (Elixir 1.18 / OTP 27)`
   - `Support Contract Admin (Elixir 1.18 / OTP 27)`
   - `Compile No Optional Deps (Elixir 1.18 / OTP 27)`
   - Phase 38 prepublish proof/export bundle (`38-01-PREPUBLISH-PROOF.md`)
   - Phase 38 install/upgrade rehearsal artifact (`38-02-REHEARSAL-EVIDENCE.md`)
2. **Merge the release-please PR.**
   Squash-merge keeps the changelog history linear.
   Review the release PR diff before merge. This repo uses a custom
   mailglass_admin dep-pin sync step, so the generated PR is load-bearing.
   The current release path emits package tags such as `mailglass-v<version>`
   and `mailglass_admin-v<version>`.
   If a broad milestone PR was squash-merged under a non-releasable subject
   and release-please skips the cut, recover with a tiny follow-up commit that
   carries a `Release-As: <intended-version>` footer. Do not hand-edit
   `.release-please-manifest.json` to force the version.
3. **Approve the `hex-publish` deployment in the GitHub Environment UI.**
   Review the pre-publish summary in the workflow run page (rendered by the
   `prepublish-summary` job per D-15) BEFORE clicking Approve. Verify the
   file count, total size, CHANGELOG excerpt, and top files all match
   expectations.
   Record the tag, publish workflow run URL, approver identity, and approval
   timestamp in `38-03-RELEASE-RECORD.md`.
   - **Package order:** The workflow guarantees `mailglass` (core) publishes first; once core is indexed, `mailglass_admin` and `mailglass_inbound` publish in parallel against the newly live core.
   - **Idempotency:** All three publish steps check `mix hex.info` first and skip the publish command if the version is already live, making the workflow safe to retry.
   - **Fallback path:** If the Release Please tag/release exists but `publish-hex` did not fan out, dispatch `.github/workflows/publish-hex.yml` manually (with `package=all` and `dry_run=false`). **Do not dispatch from `main`**. Always use the reviewed release tag (for `1.0.0`: `mailglass-v1.0.0`) so the publish run is pinned to the exact commit Release Please tagged.
4. **Within 60 minutes of publish: smoke-install in a fresh Phoenix app.**
   Set a literal timer when approving the deployment.
   Run:

       mix archive.install hex phx_new --force
       mix phx.new sandbox --no-ecto --no-mailer --install
       cd sandbox
       # add {:mailglass, "~> 1.2"}, {:mailglass_admin, "~> 1.2"}, {:mailglass_inbound, "~> 0.2"} to deps
       mix deps.get && mix mailglass.install && mix compile --warnings-as-errors
       mix phx.server  # visit http://localhost:4000/dev/mail/

   If anything fails AND the publish was less than 60 minutes ago AND zero
   downloads have happened, the Retract Decision Tree rule 4
   (`mix hex.publish --revert`) is reachable. After 60 minutes the only
   options are retire-then-patch (rule 1) or patch-only (rule 2).
Keep the published support story honest: if the smoke or support-contract
   checks reveal a mismatch with the documented matrix or upgrade posture, fix
   the guide and package metadata together rather than carrying split truth.
   For inbound-slice changes, rerun `mix verify.stability_contract` so the
   repo-root lane proves the canonical `mailglass_inbound` docs and support
   posture before you publish.
   If you need to reproduce the v0.2 codemod or rollback story during this
   window, do it in a disposable fixture or git-clean worktree only. The
   public rollback contract is git-based review/revert of the upgrade diff,
   not cleanup of arbitrary dirty repositories.

   The post-publish-smoke workflow (`.github/workflows/post-publish-smoke.yml`,
   Plan 09) runs the same smoke automatically — but it does not respect the
   60-minute window. Run the manual smoke during the window regardless.
   If publish succeeds but smoke does not fan out, use `workflow_dispatch` on
   `.github/workflows/post-publish-smoke.yml` with that same core tag.
   Record the post-publish smoke run URL, whether fallback dispatch was used,
   Hex/HexDocs URLs, and the final 60-minute decision in the Phase 38 release
   record.
5. **Post the release link to Elixir Forum #libraries section** (post-publish, optional
   — performed by maintainer on their own cadence; not gated by Phase 07.1's
   milestone-shipped marker per CONTEXT line 14 / line 351).
   Body equals the GitHub Release narrative (CHANGELOG entry verbatim plus
   one framing paragraph for 0.x.0 minor bumps; verbatim CHANGELOG only for
   patches).
