# Phase 27-03 Summary

## Diff Hunks

**`REQUIREMENTS.md`**
```diff
- [x] **REL-17**: Fresh-host install no longer crashes on missing `:hackney` / Swoosh API client defaults (closed in Phase 27; previously tracked as `Issue #25`).
- [x] **REL-18**: Post-publish smoke no longer depends on the prior manual version-resolution workaround (closed in Phase 27; previously tracked as `Issue #9`).

| REL-17 | Phase 27 | Complete |
| REL-18 | Phase 27 | Complete |
```

**`PROJECT.md`**
```diff
- [x] `REL-17` / `REL-18` — fresh-host install and post-publish smoke closure (Phase 27)
```

**`STATE.md`**
```diff
### Carry-forward closure (resolved in Phase 27)

- **Issue #25** — RESOLVED in Phase 27 (REL-17). The installer now writes `config :swoosh, :api_client, false` so a fresh `mix phx.new --no-mailer` host boots without `:finch` in deps. See `.planning/phases/27-release-install-closure/27-01-PLAN.md` and the historical narrative archived under `.planning/milestones/v0.3-phases/18-ship-v0-3-0/`.
- **Issue #9** — RESOLVED in Phase 27 (REL-18). Workflow comments hardened so the canonical release-event path and fallback `workflow_dispatch tag=...` recovery path are explicitly documented in `.github/workflows/post-publish-smoke.yml` and `.github/workflows/publish-hex.yml`. Rehearsal evidence: `.planning/phases/27-release-install-closure/27-02-EVIDENCE.md`.

- Phase 18 (Ship v0.3.x) complete 2026-04-29 — shipped as v0.3.2 after 3-cycle CI recovery (PRs #20, #22 → #21 / 0.3.1 orphan; #23 → #24 / 0.3.2 shipped). DELIV-04 marked Complete; smoke contract gap (Issue #25) was carried forward to v0.4 and closed in Phase 27 (REL-17).
```

**`MILESTONE-ARC.md`**
```diff
- Carry-forward ship/install fixes from `Issue #25` and `Issue #9` (closed in Phase 27 — see REL-17/REL-18)
```

## Line-by-Line Audit (Task 5)

Every remaining mention of `Issue #25` / `Issue #9` in the active planning files has been audited:
- **`REQUIREMENTS.md`**: "previously tracked as \`Issue #25\`" / "previously tracked as \`Issue #9\`" → Framing: **previously-tracked**.
- **`PROJECT.md`**: "Release/install closure for \`Issue #25\` and \`Issue #9\`" → Framing: **historical-goal** (line 73).
- **`STATE.md`**: "**Issue #25** — RESOLVED in Phase 27 (REL-17)" / "**Issue #9** — RESOLVED in Phase 27 (REL-18)" → Framing: **RESOLVED**.
- **`STATE.md`**: "smoke contract gap (Issue #25) was carried forward to v0.4 and closed in Phase 27" → Framing: **closed**.
- **`MILESTONE-ARC.md`**: "Carry-forward ship/install fixes from \`Issue #25\` and \`Issue #9\` (closed in Phase 27...)" → Framing: **closed**.

## Verification
- Confirmed that `git diff --stat .planning/milestones/v0.3-phases/` returns 0 lines (D-27-09 honored).
- Conventional Commit prefix used: `docs(state):`.