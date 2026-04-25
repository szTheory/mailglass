---
phase: 07-installer-ci-cd-docs
plan: 05
status: completed
updated: 2026-04-25
---

# Plan 07-05 Summary

Wired Release Please with linked versions, protected the Hex publish lane
behind a GitHub Environment, and shipped the pre-publish tarball check as
a Mix task that adopters and CI can both invoke.

## Completed Work

- `release-please-config.json` — manifest mode with `linked-versions`
  joining `mailglass` (root) and `mailglass_admin/`. Both packages roll
  to the same version on every release (CI-04, D-04).
- `.release-please-manifest.json` — coordinated version state. Initial
  pin: `0.1.0` for both packages.
- `.github/workflows/release-please.yml` — opens/maintains the release PR
  on every push to `main`. SHA-pinned `googleapis/release-please-action`.
- `.github/workflows/publish-hex.yml` — protected publish lane:
  - `on: release` trigger only — never runs from `pull_request`.
  - GitHub Environment with required reviewers; `HEX_API_KEY` lives in
    the environment secret, never visible to PR jobs (CI-07).
  - Runs `mix mailglass.publish.check` as a blocking pre-publish gate
    (CI-05) before `mix hex.publish --yes`.
- `lib/mix/tasks/mailglass.publish.check.ex` — pre-publish forbidden-file
  scan via `mix hex.build --unpack`. Catches accidental leakage of
  `_build/`, `deps/`, `.git/`, `.gsd/`, `.planning/`, `.claude/` into the
  tarball (CI-05). The plan originally specified a bash script under
  `.github/scripts/`; landed as a Mix task instead so adopters and CI can
  share one execution path.
- `mailglass_admin/CHANGELOG.md` — bumped to mirror the root v0.1.0
  release (Keep-a-Changelog format).
- `mix.exs` — `def cli` declaring `:test` env for every `verify.*` alias
  (Elixir 1.18+ no longer auto-promotes nested `mix test`); collapsed
  `verify.phase_07` to a single `mix test` call (chained per-file aliases
  trip Mix's task de-duplication and only the first runs);
  `skip_code_autolink_to:` for hidden cross-refs so `mix docs
  --warnings-as-errors` stays green; `Mix.Tasks.Mailglass.Publish.Check`
  added to the Boundary classification.

## Verification

- `mix mailglass.publish.check` ✅ — no forbidden files in the tarball.
- `mix hex.audit` ✅ — no retired packages.
- `mix verify.phase_07` ✅ (13 tests, 0 failures).
- `mix docs --warnings-as-errors` ✅ (0 warnings).
- Manual: confirmed `release-please-config.json` `linked-versions: true`
  resolves both root and admin to the same version target.

## Notes

- Tarball size checks (<500KB core, <2MB admin) are deferred to the
  `publish-hex.yml` workflow itself as a `du -sb` post-build assertion;
  encoding in Elixir would require parsing `mix hex.build` output and
  the workflow-level check is closer to the actual upload path.
- Upgrade path: when `mailglass_inbound` ships at v0.5+ it joins the
  `linked-versions` array — manifest mode makes this a one-line diff.
