# Phase 044.5 — Deferred Items

Out-of-scope discoveries logged during plan execution. These are NOT regressions caused by phase work; they are pre-existing or peripheral issues observed while validating in-scope changes.

## From Plan 044.5-01 (Commit A) — discovered 2026-05-07

### 1. Missing `mailglass_inbound/.gitignore`

- **Observed during:** Plan 044.5-01 Task 3 validation runs
- **What:** Running `mix deps.get` and `mix mailglass.publish.check --package mailglass_inbound` in a fresh clone (or the worktree) creates `mailglass_inbound/_build/`, `mailglass_inbound/deps/`, and `mailglass_inbound/_publish_check/`. None of these are ignored.
- **Why it's a gap:** `mailglass_admin/` has its own `.gitignore` covering `/_build/`, `/deps/`, `/cover/`, `/doc/`, `.elixir_ls/`. The root `.gitignore` covers `/_build/` and `/deps/` only at the repo root, not under sibling package dirs. `mailglass_inbound` should mirror `mailglass_admin/.gitignore`.
- **Severity:** Low. Untracked dirs do not pollute commits (specific-file `git add` was used). Only a cosmetic `git status` issue and a hygiene gap.
- **Why deferred:** Plan 044.5-01's `<files>` list is exact. Creating a new `mailglass_inbound/.gitignore` file is out of scope.
- **Suggested follow-up:** Add to Plan 02 (Wave 1) as a small prep edit, OR a 1-commit follow-up after Plan 044.5-01 lands. Minimal content: copy `mailglass_admin/.gitignore` verbatim.

### 2. Pre-existing `mix mailglass.docs.check` red on `main`

- **Observed during:** Plan 044.5-01 Task 3 validation runs
- **What:** `mix mailglass.docs.check` exits 1 with 5 Tier 1 docs issues:
  - stale token in `mailglass_inbound/README.md`: "public replay API"
  - stale token in `mailglass_inbound/README.md`: "operator UI"
  - stale token in `mailglass_inbound/docs/api_stability.md`: "public replay API is stable"
  - missing required token in `mailglass_inbound/docs/sendgrid_ingress.md`: "Task.Supervisor fallback is bounded best-effort only"
  - stale token in `mailglass_inbound/docs/sendgrid_ingress.md`: "re-ingest of provider payloads"
- **Pre-existing:** Reproduced at parent commit `b5b39d7c` before any edits.
- **Cascade:** Causes `mix verify.stability_contract` (the repo-truth lane) to exit 2 — chain-fails before reaching the final `compile --no-optional-deps --warnings-as-errors` step.
- **Why deferred:** Plan 044.5-01 modifies 5 specific files; none of these failing docs files are in scope. Plan 03 (Wave 2 / Commit C) is the natural place to curate inbound docs as part of the first-publish CHANGELOG framing.
- **Suggested follow-up:** Plan 03 should explicitly include the inbound docs token reconciliation (either by updating the docs to match the Tier 1 token list, or by updating the Tier 1 token list to reflect the current accurate inbound surface). Plan 03 already touches `mailglass_inbound/CHANGELOG.md` for first-publish framing prose, so adjacency is natural.

### 3. Architectural-style question — `mix mailglass.publish.check` bootstrap-state behavior

- **Observed during:** Plan 044.5-01 Task 3 validation
- **What:** `mix mailglass.publish.check --package mailglass_inbound` exits 1 between Commit A landing and the release-please PR opening because the bootstrap state (manifest at `0.0.0`, `mix.exs @version` at `0.1.0`) violates `verify_metadata`'s strict `manifest_version == mix.exs version` assertion AND `verify_linked_constraint`'s strict `mailglass dep "== root_version"` assertion.
- **Plan said:** Acceptance criterion expects exit 0.
- **Why the conflict is structural:** The manifest's `0.0.0` is a sentinel that release-please consumes to compute the next version (per release-please manifest-releaser docs). There is no Commit-A state where both checks pass simultaneously without first running release-please end-to-end.
- **Why deferred:** This is a Rule 4 architectural change to `lib/mix/tasks/mailglass.publish.check.ex`. Adding a `--bootstrap` mode (allowing `manifest == "0.0.0"` to bypass equality assertions for first-publish packages) is non-trivial and outside Plan 044.5-01's surface. The check IS expected to pass on the release-please PR head ref during workflow-dispatch dry-run (D-44.5-04 step 3), where the manifest reads `{".": "1.0.0", "mailglass_admin": "1.0.0", "mailglass_inbound": "0.1.0"}` and root `@version` reads `"1.0.0"`.
- **Suggested follow-up:** User decision. Options:
  - **(a)** Accept the local-only `[conflict]` as a documented bootstrap-period quirk (no code change). Remove the Task 3 acceptance-criterion line that says publish.check must exit 0 in Commit-A state.
  - **(b)** Add a `--bootstrap` flag to `mix mailglass.publish.check` in a small follow-up plan (after Plan 04 lands, or in Phase 51 closeout). The flag would skip `verify_metadata`'s manifest-equality assertion and `verify_linked_constraint`'s root-version assertion when the manifest holds `0.0.0` for the package.
  - **(c)** Modify the task to special-case `manifest_version == "0.0.0"` automatically (no flag needed), treating it as "this is a first-publish bootstrap package; defer manifest equality until release-please PR opens". This is the most ergonomic but also the largest behavior change.

## From Plan 044.5-04 (Wave 3 / live ceremony) — discovered 2026-05-07

### 4. Stale `stability_contract_test.exs` assertions for `mailglass_inbound`

- **Observed during:** Plan 044.5-04 Task 2 investigation (after fixing the publish.check glob-entry bug)
- **What:** `test/mailglass/stability_contract_test.exs:74` asserts `manifest =~ "\"mailglass_inbound\": \"0.3.2\""` and `inbound_mix =~ "{:mailglass, \"== 0.3.2\"}"` and `summary =~ "\"mailglass_inbound\": \"0.3.2\""`. After Plan 01's Commit A (which is correctly merged to `main`), the manifest now reads `0.0.0`, the inbound mix.exs pin reads `== 1.0.0`, and the inbound mix.exs `@version` reads `0.1.0`. All three assertions fail.
- **Pre-existing on `main`:** Yes — confirmed by running `mix test test/mailglass/stability_contract_test.exs:74` against HEAD `749e01d`. The test ALREADY fails on `main`. Plan 01 should have updated these assertions as part of Commit A.
- **Severity:** Low. The CI lane that gates `publish-hex.yml` (`gate-ci-green`) ran successfully against the PR head (otherwise the dry-run would not have reached prepublish-summary). So this test is either excluded from the gate, or was already excluded as part of Plan 01's known-broken-state.
- **Why it didn't surface earlier:** The `verify.stability_contract` Mix alias chain (which would run this test) exits early on `mix mailglass.docs.check` failures (Item 2 above), short-circuiting before the stability tests run.
- **Why deferred:** Updating these test assertions is a Plan 01 / Commit A scope item that was missed. Adding it to Plan 04 would conflict with the Plan 04 task list (no test changes are in scope for Plan 04). The correct fix is a small follow-up commit on `main` updating the three assertions:
  - `manifest =~ "\"mailglass_inbound\": \"0.0.0\""` (or update again post-merge to `0.1.0`)
  - `inbound_mix =~ "{:mailglass, \"== 1.0.0\"}"`
  - `inbound_mix =~ "@version \"0.1.0\""` (additional assertion to cover the new value)
  - `summary =~ "\"mailglass_inbound\":` ... (drop the `0.3.2` qualifier or update post-merge)
- **Suggested follow-up:** Plan 05 (Wave 4 closeout). Bundle with `release-as` cleanup of `release-please-config.json` and the `unowned-package` evidence capture as a single closeout task.

### 5. `mailglass.publish.check` glob-entry false-positive for `priv/static/fonts/*.woff2`

- **Observed during:** Plan 044.5-04 Task 2 dry-run dispatch (initial attempt, run id 25498258711)
- **What:** `mix mailglass.publish.check --package mailglass_admin` was failing with `"Delivery blocked: missing required file priv/static/fonts/*.woff2"` even though six `.woff2` files were present in the unpacked tarball.
- **Root cause:** `required_file_entries(:mailglass_admin)` includes the literal glob string `"priv/static/fonts/*.woff2"` (introduced in 79524c0 / Phase 42-03 refactor). The `verify_required_files` `MapSet.member?` check rejects the glob string (no literal path matches it), so it ends up in the `missing` list. The package-specific `woff2_count >= 1` check passes correctly, but the generic `if missing != [] do fail_step` at line 540 still trips.
- **Status:** Fixed in commit 12002ea (Plan 04 Rule 1 deviation) — `verify_required_files` now excludes glob entries (any string containing `*`) from the literal path-membership scan. Tracked here for Plan 05 SUMMARY visibility.
- **Pre-existing on `main`:** Yes — present since 79524c0 (May 6 2026). Never surfaced before Phase 44.5 because admin publish.check was last successfully run at v0.3.2 (Phase 38) on pre-79524c0 tooling.
- **Severity:** High at the moment of discovery — blocked the dry-run dispatch entirely. Now resolved.
- **Suggested follow-up:** None required; fix landed in 12002ea. This entry is a paper-trail for Plan 05 SUMMARY auditing.
