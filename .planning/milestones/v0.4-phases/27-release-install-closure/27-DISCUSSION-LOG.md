# Phase 27: release-install-closure - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-01
**Phase:** 27-release-install-closure
**Mode:** assumptions
**Areas analyzed:** Installer Runtime Default, Smoke Contract Boundary, Release-Day Version Source, Release Evidence And Current-State Cleanup

## Assumptions Presented

### Installer Runtime Default
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 27 should align the installer-generated Swoosh runtime block with Mailglass's package-level default posture by using `config :swoosh, :api_client, false` rather than `Swoosh.ApiClient.Finch`. | Likely | `lib/mailglass/installer/templates.ex`, `config/config.exs`, `.planning/milestones/v0.3-phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md`, `.planning/STATE.md` |

### Smoke Contract Boundary
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| REL-17 should be judged against the full fresh-host smoke contract of add deps -> install -> compile -> boot -> `GET /dev/mail/`, not a narrower proof. | Confident | `test/mailglass/install/install_first_preview_smoke_test.exs`, `.github/workflows/post-publish-smoke.yml`, `.planning/milestones/v0.3-phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md` |

### Release-Day Version Source
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| REL-18 should keep the current release-event-driven topology and make `github.event.release.tag_name` the canonical release-day version source, with manual `workflow_dispatch tag` fallback-only. | Likely | `.github/workflows/publish-hex.yml`, `.github/workflows/post-publish-smoke.yml`, `.planning/todos/pending/2026-04-26-post-publish-smoke-version-resolution-bug.md`, `.planning/todos/pending/2026-04-26-publish-hex-workflow-run-gate-cant-detect-tag-creation.md` |

### Release Evidence And Current-State Cleanup
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Closing Phase 27 includes updating current planning/state artifacts so the manual `workflow_dispatch tag=...` workaround is historical evidence, not active ship contract. | Likely | `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/milestones/v0.3-phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md` |

## Corrections Made

None. User confirmed all assumptions as-is.

## External Research Applied

- Swoosh docs confirm `config :swoosh, :api_client, false` is a supported path when no API client is needed: `https://hexdocs.pm/swoosh/Swoosh.html`
- Swoosh Finch docs confirm `Swoosh.ApiClient.Finch` requires a started Finch process and optional `:finch_name` config: `https://hexdocs.pm/swoosh/Swoosh.ApiClient.Finch.html`

## Outcome

Assumptions were accepted without correction and promoted into `27-CONTEXT.md` as locked implementation decisions for downstream planning.
