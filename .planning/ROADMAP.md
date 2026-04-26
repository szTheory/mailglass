# Roadmap: mailglass

**Current Milestone:** TBD (run `/gsd-new-milestone` to start the next cycle)
**Granularity:** standard (config.json)
**Sibling package out of milestone:** `mailglass_inbound` (v0.5+, not roadmapped here)

## Milestones

- ✅ **v0.1 Validation Release** — Phases 1–7 + 07.1 (shipped 2026-04-26 to Hex.pm) — see [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- 📋 **Next milestone** — TBD (candidates: v0.1.2 polish, v0.2 Mailable API redesign, v0.5 deliverability wave)

## Phases

<details>
<summary>✅ v0.1 Validation Release (Phases 1–7 + 07.1) — SHIPPED 2026-04-26</summary>

- [x] Phase 1: Foundation (6/6 plans) — completed 2026-04-22
- [x] Phase 2: Persistence + Tenancy (6/6 plans) — completed 2026-04-22
- [x] Phase 3: Transport + Send Pipeline (12/12 plans) — completed 2026-04-23
- [x] Phase 4: Webhook Ingest (9/9 plans) — completed 2026-04-24
- [x] Phase 5: Dev Preview LiveView (6/6 plans) — completed 2026-04-25
- [x] Phase 6: Custom Credo + Boundary (6/6 plans) — completed 2026-04-24
- [x] Phase 7: Installer + CI/CD + Docs (5/5 plans) — completed 2026-04-25
- [x] Phase 07.1: Publish to Hex.pm (INSERTED) (11/11 plans) — completed 2026-04-26

Total: 8 phases, 61 plans. Hex.pm: `mailglass` 0.1.0 + 0.1.1, `mailglass_admin` 0.1.0 + 0.1.1.

Full details: [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md).

</details>

### 📋 Next Milestone (Planned)

To be defined. Run `/gsd-new-milestone` to start the next cycle.

**Candidate scope** (from v0.1.2 TODO queue + v0.5 deliverability wave):

- **v0.1.2 polish** (release-engineering fixes captured during v0.1.1 ship):
  1. Exclude `CLAUDE.md` from HexDocs
  2. Add installer goldens to `mix mailglass.publish.check`
  3. Switch publish-hex.yml + post-publish-smoke.yml to tag-push trigger
  4. Rename `verify.phase_NN` aliases to semantic names
- **v0.2** (potential design discussion):
  - Mailable API Swoosh leakage — abstract above Swoosh
- **v0.5** (deliverability wave) — DELIV-01..10 + admin v0.5 (prod-mountable browser, suppressions UI, replay) + DELIV-04 (Mailgun/SES/Resend webhook normalization) + DELIV-06 `mix mail.doctor`

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v0.1 | 6/6 | Complete | 2026-04-22 |
| 2. Persistence + Tenancy | v0.1 | 6/6 | Complete | 2026-04-22 |
| 3. Transport + Send Pipeline | v0.1 | 12/12 | Complete | 2026-04-23 |
| 4. Webhook Ingest | v0.1 | 9/9 | Complete | 2026-04-24 |
| 5. Dev Preview LiveView | v0.1 | 6/6 | Complete | 2026-04-25 |
| 6. Custom Credo + Boundary | v0.1 | 6/6 | Complete | 2026-04-24 |
| 7. Installer + CI/CD + Docs | v0.1 | 5/5 | Complete | 2026-04-25 |
| 07.1. Publish to Hex.pm (INSERTED) | v0.1 | 11/11 | Complete | 2026-04-26 |

---
*Roadmap defined: 2026-04-21. v0.1 archived: 2026-04-26.*
*Coverage: 84/84 v1 REQ-IDs mapped to exactly one phase. No orphans, no duplicates.*
