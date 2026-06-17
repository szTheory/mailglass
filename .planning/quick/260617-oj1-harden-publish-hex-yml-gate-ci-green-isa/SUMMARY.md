---
quick_id: 260617-oj1
slug: harden-publish-hex-yml-gate-ci-green-isa
date: 2026-06-17
status: complete
---

# Summary: Classify "Demo Browser Evidence" as advisory in gate-ci-green

## What changed

`.github/workflows/publish-hex.yml` — added `'Demo Browser Evidence'` to the
`ADVISORY_LANES` array in the `gate-ci-green` job's "Verify CI is green on tagged
SHA" step, and expanded the adjacent comment to name both predates-convention
lanes ("Operator Browser Gate" and "Demo Browser Evidence").

## Why

`Demo Browser Evidence (Docker Compose / Chromium)` is a non-required,
browser-based CI lane whose name predates the `<name> Advisory (...)` convention,
so `isAdvisory()` did not recognise it. A red Demo Browser Evidence lane would
have wrongly blocked a Hex release. Listing it explicitly matches the existing
treatment of "Operator Browser Gate".

## Verification

- `python3 yaml.safe_load` → YAML OK.
- Node check of the `isAdvisory()` logic against real job names:
  - `Demo Browser Evidence (Docker Compose / Chromium)` → advisory ✓
  - `Operator Browser Gate (...)` → advisory ✓
  - `Preview Capture Advisory (...)` → advisory ✓ (convention match)
  - `Compile No Optional Deps` → blocking ✓
  - `Trust Lane Repo Head` → blocking ✓

## Files

- `.github/workflows/publish-hex.yml`
