# Phase 173 pinned before captures

These six synthetic PNGs are the existing before captures from revision
`7e3720237f51f2907b77c7dcb03042f2dd379d53`. Their filenames, SHA-256 byte hashes,
dimensions, and capture identities are pinned in
`assets/scripts/check-demo-browser-evidence.cjs` (`EXPECTED_BASELINES`).

`node scripts/prepare_phase173_baselines.cjs`, run from the repository root,
validates the committed PNGs and provisions the ignored evidence directory.
It reuses identical destination bytes and rejects changes or symlinks. Capture
output and sanitized current/baseline pairs remain ignored runtime artifacts.
