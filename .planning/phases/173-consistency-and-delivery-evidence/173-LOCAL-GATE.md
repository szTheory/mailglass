---
phase: 173
status: incomplete
local_status: passed
candidate_sha: 8b4ce3e9643dd1b6a64cc5c96213245bb284512a
completed_at: 2026-10-10T15:31:00Z
exit_code: 1
started_at: 2026-10-10T15:25:12Z
---

# Phase 173 current-candidate local gate

The reviewed outer launcher completed against exact committed SHA `8b4ce3e9643dd1b6a64cc5c96213245bb284512a`. Every local delivery predicate passed. Exit 1 is the expected incomplete delivery outcome for the two unresolved external predicates below.

- Command: `bash scripts/check_phase173_candidate.sh`
- Detached sparse candidate: `/private/tmp/mailglass-phase173.rNJ8Lp8c/candidate`
- Local log: `/private/tmp/mailglass-phase173-full-gate-1791645829779.log`
- Git index confirms both protected paths have the `S` skip-worktree flag.
- Original owner edits stay outside the candidate. At local-gate completion, remote authorization was pending; the later approved push and CI result are recorded below and in `173-REMOTE-CI.md`.

## Local results

| Check | Result |
|---|---|
| Core | 79 tests, zero failures |
| Admin | 605 tests, zero failures, one existing exclusion |
| Inbound | Three properties and 480 tests, zero failures, three existing exclusions |
| Connected operator/preview browser | 30 passed |
| Preview routes | All five required routes passed |
| Served Admin CSS | Byte hash matches the committed candidate bundle |
| Additional preview asset rebuild gate | Not run because phase Admin assets were unchanged |
| Fresh synthetic browser evidence | Passed; six captures and six baseline/current PNG pairs validated |
| Candidate provenance | Exact SHA; checkpoint and all captures clean |
| Final checkout and locks | Candidate status clean outside sparse exclusions; all four Mix locks unchanged |

Built and served Admin CSS SHA-256: `91c0b80fd5d2d9dd42d6501b615f3167b5f25a13beed92894e11fdfa1b6abff1`.

The full gate independently validated the retained checkpoint and all twelve PNG byte hashes. A post-run check confirmed its exact candidate SHA, passed status, six capture records, clean flags, expected CSS identity, and final Git cleanliness. No original protected file or owner edit was used.

## Retained owner review

- Preview: [http://127.0.0.1:63769/dev/mail](http://127.0.0.1:63769/dev/mail)
- Compose project: `mailglass-phase173-review-8b4ce3e9-20261010152740-92746-4520`
- Delivery record: `/private/tmp/mailglass-phase173.rNJ8Lp8c/candidate/reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json`
- Sanitized evidence: `/private/tmp/mailglass-phase173.rNJ8Lp8c/candidate/reference/demo_app/tmp/demo_browser_evidence/retained/`

The disposable screenshot project was cleaned by its own wrapper. The new review preview, its candidate worktree, and older retained review resources remain available.

Scoped cleanup for this new review, only after its review is complete:

```bash
docker compose -p "mailglass-phase173-review-8b4ce3e9-20261010152740-92746-4520" -f "/private/tmp/mailglass-phase173.rNJ8Lp8c/candidate/compose.demo.yml" down
git worktree remove "/private/tmp/mailglass-phase173.rNJ8Lp8c/candidate"
rmdir "/private/tmp/mailglass-phase173.rNJ8Lp8c"
```

No cleanup command above was run.

## Outstanding delivery predicates

The gate recorded exactly two failures:

1. No successful required `CI Green` workflow run for the exact candidate SHA.
2. Protected owner acceptance remains unverified.

UIQ-03 and Phase 173 remain incomplete. The preceding 24/27 goal-verification report is historical until refreshed with this runtime evidence; this local run does not establish either external predicate.

## Concrete remote CI action, subsequently approved and completed

The origin repository was checked to be `szTheory/mailglass`. A read-only matching-ref query found no existing branch named `gsd/phase-173-delivery-8b4ce3e9`. The user subsequently answered `yes` to the bounded branch push and manual dispatch described here.

The approved action published this exact candidate to that new branch and manually dispatched the existing CI workflow there:

```bash
git push origin 8b4ce3e9643dd1b6a64cc5c96213245bb284512a:refs/heads/gsd/phase-173-delivery-8b4ce3e9
gh workflow run ci.yml --repo szTheory/mailglass --ref gsd/phase-173-delivery-8b4ce3e9
```

The workflow accepts manual dispatch and forces the full code matrix for that event. A successful exact-SHA `CI Green` result is required. A branch-only push does not trigger CI because push triggers are limited to main. No merge, release, main push, or change to branch protection is part of this proposed action.

Both actions completed successfully. Exact-SHA CI run [38064299090](https://github.com/szTheory/mailglass/actions/runs/38064299090) has a failed required `CI Green` aggregate; see `173-REMOTE-CI.md` for diagnosis. This later evidence does not alter the historical local-gate JSON. Authenticated owner acceptance remains a separate prerequisite.

Preserve the retained review resources and pending owner edits. If the delivery candidate changes, require new evidence for its exact SHA.
