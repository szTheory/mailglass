# Phase 177: Readable Health and Coherent Account Navigation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-10-28
**Phase:** 177-readable-health-and-coherent-account-navigation
**Mode:** assumptions (plus per-area research fan-out at the owner's request)
**Areas analyzed:** Preview return seam, Account control scope, Health composition, Verification

## Assumptions Presented

### Preview return seam
| Assumption | Confidence | Evidence |
|---|---|---|
| Closed-set `return_surface` + opaque `return_tenant_id`; Preview rebuilds destination from existing `navigation` config | Likely | router.ex:270-401, preview_live.ex:743-762, RETURN-DESTINATION.md |
| No public API; session whitelists byte-identical | Confident | router.ex:376-377, api_stability.md |
| Thread context through every Preview URL builder | Confident | preview_live.ex:163-191,682-693,798,807-846; sidebar.ex |
| Authorization stays with host Auth/Tenancy seam; test clause proves denial | Likely | operator/mount.ex, endpoint_case.ex:349-383 |
| Demo navigation repointed at /ops/* with AdminAuth login deny | Likely | demo router.ex:104-148, page_controller.ex:155-210 |

### Account control
| Assumption | Confidence | Evidence |
|---|---|---|
| Control heads a scoped group (Health/Deliveries/Inbound); Preview outside; mobile band copy | Likely | shell.ex:184-318, surface_nav.ex:8-13, admin_shell.ex:54-70, ACCOUNT-CONTROL.md |
| Preview: no picker/name/id; static scope label; no "sample data" claim | Likely | router.ex:393-394, UPSTREAM-SCOPE.md:33,62,80 |

### Health
| Assumption | Confidence | Evidence |
|---|---|---|
| Single ~42rem column expected; measured against grouped B at container widths | Likely | health_overview.ex:38-166, operator_live.ex:743-768, HEALTH-COMPOSITION.md |
| Populations/order/links unchanged; counts de-emphasized | Confident | operator_live.ex:2849-2931 |

### Verification
| Assumption | Confidence | Evidence |
|---|---|---|
| ExUnit connected + mutation-proven prohibition contract + Playwright geometry + production stories | Confident | METHODOLOGY.md, phase175 template, 176-CONTEXT D-28..D-30 |

## Corrections Made

No corrections — all assumptions confirmed.

## Synthesis Conflicts Resolved
- Analyzer proposed a `return_to` path validated by exact match; research proposed a closed surface set. Chose the closed set (no URL accepted).
- Analyzer kept the Account control in the topbar; research moved it to head the scoped nav group. Chose the group header — the mobile band is always visible below md, so 168 D-01 holds.
- Return research copy "Previews use sample data" conflicts with UXF-09 "no misleading sample-data claim"; adopted the Account research's provenance-neutral subtitle.
- Return research recommended a mailglass-side allow-list for URL `tenant_id`; rejected in favour of the host Auth seam (avoids breaking activity-free Account deep links); deferred.

## External Research
- Return destination: OWASP Unvalidated Redirects cheat sheet, CWE-601, WHATWG URL, phx.gen.auth `user_return_to`, Rails `url_from`, Django `url_has_allowed_host_and_scheme` — see `.planning/research/phase-177/RETURN-DESTINATION.md`.
- Account scope: Stripe, Vercel, Linear, Sentry, AWS IAM region selector — see `ACCOUNT-CONTROL.md`.
- Health: operator dashboard prior art, WCAG 2.2 target size, container queries — see `HEALTH-COMPOSITION.md`.
