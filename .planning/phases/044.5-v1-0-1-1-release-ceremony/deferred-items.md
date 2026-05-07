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

## From Plan 044.5-04 (post-publish carry-over for Phase 51 closeout) — discovered 2026-05-07

The five items below are the "post-publish cleanup carry-over" batch from Plan 04. They are NOT regressions — they are recovery patterns that were intentionally landed on `main` to ship the v1.0/1.1 ceremony, and which become incorrect once the publish has settled. Phase 51 closeout owns the cleanup as a single batch.

### 6. Remove `release-as: "1.0.0"` config fields in `release-please-config.json`

- **Observed during:** Plan 044.5-04 ceremony retries (commit `749e01d`)
- **What:** `release-please-config.json` carries `"release-as": "1.0.0"` fields on the `.` (root / `mailglass`) and `mailglass_admin` package configs. These were added during the dispatch-3 → dispatch-4 recovery to force the linked-versions plugin to honor the v1.0.0 cut after per-commit `Release-As: 1.0.0` trailers (commits `dfc457e`, `dd61b5c`) were silently overridden by the linked-versions plugin's group-resolution logic (Pitfall 5 / T-44.5-04-06).
- **Why it must be removed:** Config-driven `release-as` is a *sticky* override — release-please will continue to cut every subsequent release at `1.0.0` until the field is deleted. After the v1.0/1.1 ceremony has settled (which it has — see `044.5-RELEASE-RECORD.md`), the field becomes a foot-gun for the next release.
- **Suggested fix:** Delete the `"release-as": "1.0.0"` line from both the `.` and `mailglass_admin` blocks in `release-please-config.json`. Verify with `release-please --dry-run` locally that the next computed cut is the natural Conventional-Commits-driven version (1.1.0 or 2.0.0 depending on what lands), not 1.0.0.
- **Target phase:** Phase 51 closeout.

### 7. Remove editorial comment lines added to `mix.exs` files by the Release-As trailer recovery commits

- **Observed during:** Plan 044.5-04 ceremony retries (commits `dfc457e` and `dd61b5c`)
- **What:** Both root `mix.exs` and `mailglass_inbound/mix.exs` carry editorial comment lines that were added as "anchors" for the per-commit `Release-As: <ver>` trailers in `dfc457e` (root) and `dd61b5c` (inbound). The commits were committed because release-please's `Release-As` trailer detection requires a non-empty diff — the comment lines exist solely as that diff carrier.
- **Why they must be removed:** The trailer recovery is no longer needed (the v1.0.0 / 0.1.0 cuts have shipped). The comment lines are now editorial noise in `mix.exs` files that are otherwise tightly maintained. Future readers will not understand why they exist.
- **Suggested fix:** Delete the editorial comment line from root `mix.exs` and the matching comment line from `mailglass_inbound/mix.exs`. Verify `mix compile --warnings-as-errors` and `mix mailglass.publish.check --package <each>` still pass after the deletes.
- **Target phase:** Phase 51 closeout. Bundle with item #6 for a single Conventional Commit (`chore(release-engineering): clean up post-1.0 publish recovery anchors`).

### 8. Fix the post-publish-smoke `consumer-install` sandbox builder bug for `mailglass_inbound`

- **Observed during:** Plan 044.5-04 manual `post-publish-smoke.yml workflow_dispatch` (run id 25512418095)
- **What:** The `consumer-install` job constructs a sandbox `mix.exs` deps section by writing `{:mailglass, "~> $VERSION"}` where `$VERSION` is the version of the package under smoke-test. When smoke-testing `mailglass_inbound`, this writes `{:mailglass, "~> 0.1.0"}` (using inbound's version) — but `mailglass` is not at 0.1.0; it's at 1.0.0. Hex resolution fails because no `mailglass 0.1.0` package exists.
- **Root cause:** The smoke job was added in Plan 02 / Commit B (commit `2a36e93`) as a clone of the admin smoke step. Admin's version is the same as core's (linked-versions group), so the bug was invisible during Plan 02 testing. Inbound is on a separate version line, so the assumption breaks.
- **Why it must be fixed:** The post-publish-smoke workflow is meant to validate adopter installability of each newly published package. With this bug, every inbound publish (current and future) will fail the consumer-install step even when the actual Hex artifact is valid. The orchestrator's manual `mix phx.new` adopter validation already proved the production packages are adopter-installable; the smoke is a CI-side check that needs repair.
- **Suggested fix:** In `.github/workflows/post-publish-smoke.yml`, the heredoc that builds the sandbox `mix.exs` deps list should not add a `{:mailglass, "~> $VERSION"}` line when smoke-testing `mailglass_inbound`. Either (a) skip the explicit core dep when smoke-testing inbound (let it resolve transitively from `mailglass_inbound`'s pin to `mailglass == 1.0.0`), or (b) compute the correct core version separately (read from `cron-guard.outputs.version` for the linked-group versions, which is the canonical source).
- **Target phase:** Phase 51 closeout. Verify by running `gh workflow run post-publish-smoke.yml -f package=mailglass_inbound` after the fix; expect all three smoke steps green.

### 9. Re-strict Operator Browser Gate from advisory back to required

- **Observed during:** Plan 044.5-04 dispatch-2 / `gate-ci-green` triage (commit `5734c1b`)
- **What:** `gate-ci-green` in `.github/workflows/publish-hex.yml` carries an `ADVISORY_LANES` allowlist that includes `"Operator Browser Gate"`. This means a red Operator Browser Gate does NOT block the publish. The Rule 4 architectural deviation rationale is in `044.5-CI-TRIAGE-SUMMARY.md`: the Phoenix endpoint is healthy, the failure is at the Playwright/auth-flow layer, and a proper fix requires either hardening the synthetic test endpoint to be a complete Phoenix endpoint OR redesigning the lane around a real LiveView mount path.
- **Why it must be re-strict:** Advisory-only is a temporary release-unblocker, not a long-term posture. Leaving the lane advisory means future regressions in the operator browser flow will not block publishes — a quality regression risk that is acceptable for a single ceremony but not as a steady-state.
- **Suggested fix (depends on Phase 51 architectural decision):**
  - Option A: Properly fix the Playwright/redirect harness (requires reproducing the failure end-to-end against an Elixir 1.18/OTP 27 + Node 22 + Postgres-16 stack; investigating whether session cookies survive the 302 redirect; deciding whether the synthetic `MailglassAdmin.TestAdopter.Endpoint` needs to grow Plug.Parsers / Plug.MethodOverride / Plug.RequestId).
  - Option B: Move the gate to a different test architecture (real LiveView mount via ConnCase rather than Playwright browser-flow).
  - In either case, the final cleanup edit in `publish-hex.yml` is: remove `"Operator Browser Gate"` from the `ADVISORY_LANES` array.
- **Target phase:** Phase 51 closeout. Pairs with item #10 (gate-ci-green ADVISORY_LANES re-empty).

### 10. Re-strict `gate-ci-green` `ADVISORY_LANES` to empty after item #9

- **Observed during:** Plan 044.5-04 dispatch-2 / `gate-ci-green` triage (commit `5734c1b`)
- **What:** `gate-ci-green` was extended with an `ADVISORY_LANES` array (currently containing `"Operator Browser Gate"`) so the lane could fail without blocking publish. The intent is that this list is the temporary advisory window during the v1.0/1.1 ceremony; in steady state, the array should be empty (no advisory lanes — every CI lane gates publish).
- **Why it must be re-empty:** Same rationale as item #9 — advisory lanes are a release-unblocker, not a steady-state posture.
- **Suggested fix:** After item #9 is resolved (the Operator Browser Gate is properly green again), edit `.github/workflows/publish-hex.yml` so `ADVISORY_LANES=()` (empty array). Add an actionlint pass to verify the YAML still parses.
- **Target phase:** Phase 51 closeout. Bundle with item #9 in a single Conventional Commit (`fix(ci): restore Operator Browser Gate as required + clear advisory list`).

---

**Phase 51 batching guidance:** Items #6 and #7 are a single docs/release-engineering cleanup commit. Items #9 and #10 are a single CI cleanup commit (sequenced after the Operator Browser Gate is genuinely green). Item #8 stands alone as a dedicated workflow-fix commit. The full closeout batch is therefore ~3 commits, all `chore`/`fix` scope, scheduled for the Phase 51 PR window.
