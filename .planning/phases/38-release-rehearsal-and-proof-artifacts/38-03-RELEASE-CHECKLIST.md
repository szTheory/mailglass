# Phase 38 — Release Checklist

## Repo-proved before publish

1. Confirm the tagged SHA is green in `actions/workflows/ci.yml`.
   Proof fields:
   - CI run URL:
   - Tag:
   - SHA:
2. Confirm the required release-truth buckets are green for that SHA.
   Required buckets:
   - `Support Contract Core (Elixir 1.18 / OTP 27)`
   - `Support Contract Admin (Elixir 1.18 / OTP 27)`
   - `Compile No Optional Deps (Elixir 1.18 / OTP 27)`
   - `38-01-PREPUBLISH-PROOF.md`
   - `38-02-REHEARSAL-EVIDENCE.md`
3. Confirm the Phase 38 proof exports are current.
   Proof fields:
   - `mailglass-publish-summary.json` reviewed:
   - `mailglass_admin-publish-summary.json` reviewed:
   - Release manifest versions reviewed:

## Manual/external proof

1. GitHub Environment approval for `hex-publish`.
   Proof fields:
   - Publish workflow run URL:
   - GitHub Environment approver:
   - Approval timestamp:
2. Fallback dispatch if publish fan-out fails.
   Proof fields:
   - Fallback dispatch used:
   - Fallback tag:
   - Fallback workflow run URL:
3. Branch-protection verification.
   Proof fields:
   - Branch-protection verification result:
   - Branch-protection note path:
4. Live package and docs verification.
   Proof fields:
   - Hex URLs:
   - HexDocs URLs:
5. 60-minute smoke and release decision window.
   Proof fields:
   - Post-publish smoke run URL:
   - Smoke start time:
   - Smoke decision time:
   - 60-minute outcome:

Use `38-03-RELEASE-RECORD.md` to store the filled values above.
