# Phase 38 — Branch Protection Note

Branch-protection verification remains accepted external closeout debt for this
phase.

- `.github/workflows/branch-protection-drift.yml` and `scripts/setup_branch_protection.sh`
  are useful helper assets, but they are not the authoritative source of the
  live GitHub branch-protection state.
- The workflow can no-op when the required GitHub secret is absent, and the
  helper script still depends on external GitHub settings plus an admin token.
- Treat branch-protection confirmation as a manual/external proof item on the
  release checklist until those helpers are repaired into repo-truth-grade
  evidence.

Current closeout posture: accepted external closeout debt.
