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
