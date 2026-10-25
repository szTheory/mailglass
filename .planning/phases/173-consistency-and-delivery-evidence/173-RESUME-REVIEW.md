# Phase 173 candidate and protected-path review

Reviewed: 2026-10-10T15:04:55Z

## Result

The committed candidate at the time of this review is `8b4ce3e9643dd1b6a64cc5c96213245bb284512a`. It includes the latest source fix at `4994442105315afdaa71beba73f6ab85e40f8533`; every committed change between those SHAs is under `.planning/`. The candidate launcher and its directly checked gate inputs have no working-tree differences from HEAD.

The existing outer candidate launcher provides a path-safe local validation route under the saved fence. A fresh disposable contract run passed. This establishes the isolation route; it does not establish a current full regression, preview, screenshot, CI, or delivery pass.

Phase 173 stays verifying at the recorded 24/27 must-haves. No requirement or verification score was changed by this review.

## Candidate identity

| Identity | Meaning |
|---|---|
| `a7fd4843d17c2bf201fb1366c588d65af0f22c3d` | Historical full local gate result, before the capture-path alias fix |
| `4994442105315afdaa71beba73f6ab85e40f8533` | Latest code fix; included in current HEAD |
| `8b4ce3e9643dd1b6a64cc5c96213245bb284512a` | Current committed HEAD, including subsequent reports and the pause record |

The launcher captures origin HEAD once and binds its detached checkout, evidence, and CI query to that full SHA. If new commits are made before the next run, the new HEAD becomes the candidate and needs its own evidence.

Two scoped pending summaries were reviewed and preserved: untracked `173-05-SUMMARY.md` and modified `173-07-SUMMARY.md`. They are absent or different in the committed candidate and must not be represented as committed acceptance inputs. The first summary's `requirements-completed` list includes UIQ-03, but its own readiness text and the canonical verification report leave that requirement unproven. Final closeout must reconcile these records without treating historical results as current proof.

## Protected-path boundary

The protected paths remain `reference/demo_app/README.md` and `reference/demo_app/assets/e2e/demo.spec.js`. This review used allowed source files and synthetic temporary fixtures; it did not open, hash, or copy either original protected file.

| Stage | Evidence for the boundary |
|---|---|
| Original checkout | Outer launcher records HEAD and explicitly leaves dirty inventory uncollected; no origin status/diff/ls-files/cat-file inventory |
| Candidate creation | `worktree add --detach --no-checkout`, then both non-cone sparse exclusions, then materialization |
| Deliverable checks | Both protected path strings are skipped before Git object probes |
| Dependency setup | Existing pinned Mix/npm locks; candidate-generated demo lock changes restored only in the candidate |
| Docker builds | Root contexts use final active exclusions for both paths; the contract rejects Dockerfile-specific ignore overrides |
| Runtime mounts | Compose binds the sparse candidate, so original owner files are not mounted |
| Regression | Core, Admin, Inbound, and connected operator/preview suites run from the candidate |
| Demo browser evidence | Explicitly selects `phase173-evidence.spec.js`; its imports and evidence source paths do not select the fenced spec or README |
| Evidence transfer | Only the six validated pinned PNG baseline buffers are transferred |
| External systems | Read-only exact-SHA CI query; owner acceptance remains unverified; no push/dispatch/merge/release |

The wrapper's unscoped Git status runs inside the sparse candidate in this route. Do not invoke the wrapper or the broad regression gate directly in the original dirty checkout under the saved fence.

## Fresh verification

Commands run:

```bash
bash -n scripts/check_phase173_candidate.sh scripts/test_check_phase173_candidate.sh scripts/run_demo_browser_evidence.sh scripts/gsd-regression-gate.sh
bash scripts/test_check_phase173_candidate.sh
```

Both returned exit 0. The contract uses real Git only with harmless temporary sentinel files, and fake Git/Docker/GitHub CLIs for the candidate matrix. Captured output:

```text
real Git sparse checkout left both synthetic protected sentinels unmaterialized
protected-path source contract passed all positive and negative mutations
Phase 173 candidate fake-CLI contract passed (SHA, cleanliness, ancestry, owner dirt, HTTP/CSS, CI, retention, no remote writes).
```

Local raw log: `/private/tmp/mailglass-phase173-resume-contract-1791644529360.log`.

Read-only `gh run list --repo szTheory/mailglass --workflow CI --commit 8b4ce3e9643dd1b6a64cc5c96213245bb284512a --limit 20 --json databaseId,headSha,status,conclusion,url,event` returned `[]`. No matching CI run was found in this query. No remote write was made.

## Next action

Run the existing outer launcher from the original project root:

```bash
bash scripts/check_phase173_candidate.sh
```

Use its captured full SHA as the authority for that run. The established sparse route satisfies the checkpoint's alternative of a proven path-safe execution context; lifting the original-file access fence is unnecessary for local validation.

This review did not execute that full gate, start services, alter retained previews, or remove retained resources. Runtime permissions for a new worktree, Docker, and Chromium may still need the sandbox's normal review. Required CI and authenticated owner acceptance remain unresolved; the remote-write fence remains active. The gate intentionally returns an incomplete result while those prerequisites are missing, even if local predicates pass.
