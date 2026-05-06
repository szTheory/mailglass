# Phase 38 Plan 03 Summary

## Outcome

Release-day closeout now has one explicit checklist, one populated rehearsal
record, and one honest branch-protection note tied back into the canonical
proof bundle.

## Completed Work

- Updated `MAINTAINING.md` so the release runbook points to the Phase 38
  checklist/record artifacts and names the exact repo-proved buckets.
- Added `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-CHECKLIST.md`
  with separate `Repo-proved before publish` and `Manual/external proof`
  sections.
- Added `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md`
  populated with rehearsal values plus explicit `not run` markers for live-only
  fields.
- Added `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-BRANCH-PROTECTION-NOTE.md`
  documenting branch-protection verification as accepted external closeout debt.
- Appended release-record highlights into `38-01-PREPUBLISH-PROOF.md`.

## Verification

- `actionlint .github/workflows/publish-hex.yml .github/workflows/post-publish-smoke.yml .github/workflows/release-please.yml .github/workflows/branch-protection-drift.yml`
- `rg -n "Repo-proved before publish|actions/workflows/ci.yml|Support Contract Core \\(Elixir 1.18 / OTP 27\\)|Support Contract Admin \\(Elixir 1.18 / OTP 27\\)|Compile No Optional Deps \\(Elixir 1.18 / OTP 27\\)|38-01-PREPUBLISH-PROOF.md|38-02-REHEARSAL-EVIDENCE.md|Manual/external proof|Publish workflow run URL|GitHub Environment approver|Approval timestamp|Fallback dispatch used|Branch-protection verification result|Smoke decision time|accepted external closeout debt" MAINTAINING.md .planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-CHECKLIST.md .planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-BRANCH-PROTECTION-NOTE.md`
- `rg -n "^Release type: (rehearsal|live)$|^Tag: .+$|^Publish workflow run URL: (https://.+|not run|not applicable)$|^Post-publish smoke run URL: (https://.+|not run|not applicable)$|^Proof bundle path: 38-01-PREPUBLISH-PROOF\\.md$|^Install/upgrade rehearsal path: 38-02-REHEARSAL-EVIDENCE\\.md$|^Hex index confirmation: .+$|^HexDocs URLs: .+$|^Fallback path used: (yes|no|not run|not applicable)$|^60-minute outcome: .+$|^GitHub Environment approver: .+$|^Branch-protection verification result: .+$" .planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md`

## Deviations

- The release record is intentionally marked `rehearsal`; live publish, Hex
  indexing, HexDocs checks, and the 60-minute decision remain explicit external
  steps for a real cut.
