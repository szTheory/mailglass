# Phase 73 — Inbound Release Record

Release type: prepare-and-stage
Tag: mailglass_inbound-v1.0.0 (staged, not cut)
Release-vs-dispatch path: workflow_dispatch fallback rehearsal (package=mailglass_inbound), tag-pinned — canonical path is release: published, deferred to maintainer
Publish workflow run URL: pending; see 73-02 rehearsal evidence
Post-publish smoke run URL: not run
Proof bundle path: .planning/publish/mailglass_inbound-publish-summary.json (mix mailglass.publish.check --package mailglass_inbound)
Install/upgrade rehearsal path: pending; deferred to post-publish maintainer trigger
Hex index confirmation: not run; rehearsal stayed repo-local
HexDocs URLs: pending; not published under prepare posture
Fallback path used: not run
60-minute outcome: not run; no live publish window started

## Proof links

- Inbound release checklist: `73-01-RELEASE-CHECKLIST.md`
- Committed inbound publish summary: `.planning/publish/mailglass_inbound-publish-summary.json`
- Maintainer runbook (inbound-only publish/fallback path): `MAINTAINING.md`

## Notes

This record captures repo-local staging only. The `mix mailglass.publish.check --package mailglass_inbound` preflight lane exited 0 and the root inbound-preflight-consistency test (`mix test test/mailglass/stability_contract_test.exs`) passed — these are the deterministic captured fields. Live publish, Hex index, HexDocs verification, install/smoke proof, and the 60-minute revert window remain explicit `pending` / `not run` until the maintainer's deferred `mailglass_inbound 1.0.0` publish trigger runs (D-01). Branch-protection verification does not apply to this inbound-only slice; the `hex-publish` GitHub Environment has no required reviewers (publish is hands-free, per D-04 and CLAUDE.md "Commit & Branch Conventions").
