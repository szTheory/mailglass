# Phase 27: release-install-closure - Research

**Researched:** 2026-05-02
**Domain:** installer template hygiene + GitHub Actions release-trigger correctness
**Confidence:** HIGH (single small repo, all seams already identified, third-party behavior verified against vendored Swoosh source)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-27-01:** The installer-generated Swoosh runtime default should align with Mailglass's package-level default posture by using `config :swoosh, :api_client, false`, not `Swoosh.ApiClient.Finch`.
- **D-27-02:** Phase 27 should close the fresh-host crash by making the installed config honest and dependency-light, not by introducing a stronger HTTP-client opinion than the core package already claims.
- **D-27-03:** REL-17 is judged against the full fresh-host smoke contract already exercised in-repo: add deps, run `mix mailglass.install`, compile with warnings as errors, boot the endpoint, and verify `GET /dev/mail/` succeeds.
- **D-27-04:** A narrower compile-only or config-file-only proof is insufficient for Phase 27 because the known failure mode is an adopter-path boot/install regression.
- **D-27-05:** REL-18 should keep the current release-event-driven publish/smoke topology and treat `github.event.release.tag_name` as the canonical release-day version source.
- **D-27-06:** `workflow_dispatch tag=...` remains a fallback-only path for manual recovery and rehearsal, not part of the normal milestone ship contract.
- **D-27-07:** Scheduled smoke runs remain a separate health-check path and may resolve the latest public release independently, but that path must not define release-day correctness.
- **D-27-08:** Closing Phase 27 includes updating current planning/state artifacts so the manual `workflow_dispatch tag=...` workaround is recorded as historical evidence, not as an active requirement for shipping.
- **D-27-09:** Historical evidence of prior workarounds should be preserved in milestone archives, but current-state docs must reflect the post-fix contract.

### Claude's Discretion

- Exact workflow step names, helper extraction boundaries, and validation-step placement, as long as release-day version resolution remains anchored on the release tag and manual dispatch stays fallback-only.
- Exact installer template wording around Swoosh config, as long as the generated config is honest about Mailglass not pinning a specific API client by default.

### Deferred Ideas (OUT OF SCOPE)

- Broader release-engineering redesign beyond these two closure items.
- Reconsidering the overall release topology (e.g., moving to a different trigger family entirely) is deferred unless needed to satisfy REL-18.
- Any broader installer UX expansion beyond fixing the known Swoosh API client default mismatch.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-17 | Fresh-host install no longer crashes on missing `:hackney` / Swoosh API client defaults (`Issue #25`). | Area A: single-line edit at `lib/mailglass/installer/templates.ex:147` from `Swoosh.ApiClient.Finch` → `false`, plus regenerating two golden snapshots in `test/example/README.md`. The `install_first_preview_smoke_test.exs` already encodes the canonical fresh-host smoke contract and only needs to confirm the workflow YAML markers are unchanged. |
| REL-18 | Post-publish smoke no longer depends on the manual version-resolution workaround (`Issue #9`). | Area B: `cron-guard` already prefers `release.tag_name` correctly. Workaround was triggering BOTH `publish-hex.yml` AND `post-publish-smoke.yml` via `workflow_dispatch`. Closure is (1) verifying release-event path works end-to-end without manual intervention, (2) documenting that fallback-only posture explicitly in the workflow comments, and (3) updating planning docs so Issue #9 is recorded as resolved. |
</phase_requirements>

## Summary

- **REL-17 is a one-line template edit plus golden refresh.** The installer template at `lib/mailglass/installer/templates.ex:147` writes `config :swoosh, :api_client, Swoosh.ApiClient.Finch` into the host's `runtime.exs`, but mailglass's own `mix.exs` does NOT depend on `:finch` — adopters who don't already pull Finch transitively get an `UndefinedFunctionError` at boot. Both the core repo (`config/config.exs:15`) and the admin repo (`mailglass_admin/config/config.exs:20`) already use `config :swoosh, :api_client, false` for exactly this reason. The installer template is the lone outlier. **`[VERIFIED: codebase grep + vendored Swoosh source]`**
- **The Swoosh source confirms `false` is the documented escape valve.** `Swoosh.ApiClient.init/0` calls `Code.ensure_loaded?(client)` before invoking `client.init/0`. With `client = false`, `ensure_loaded?` returns `false` and init silently no-ops. With nothing set, `Application.fetch_env!/2` raises `KeyError` at app boot. So `false` is strictly safer than "unset," and writing `Finch` is hostile to adopters who haven't added the Finch dep. `[VERIFIED: deps/swoosh/lib/swoosh/api_client.ex:39-47]`
- **REL-17 has a single golden seam to update.** Two snapshots in `test/example/README.md` (`GOLDEN_FRESH` line 54, `GOLDEN_NO_ADMIN` line 213) embed the literal `Swoosh.ApiClient.Finch` line. Both refresh in one command: `MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors`. The smoke test (`install_first_preview_smoke_test.exs`) does NOT assert the api_client value — it only checks router mount, layout existence, and workflow YAML markers — so it stays unchanged. `[VERIFIED: test/example/README.md, test/mailglass/install/install_first_preview_smoke_test.exs]`
- **REL-18's automated path already works correctly.** `cron-guard` in `post-publish-smoke.yml:48-61` already uses `context.payload?.release?.tag_name` as the highest-priority version source for `release` events, ahead of `workflow_dispatch` and ahead of the schedule path. The Phase 18 workaround was about the publish workflow, not the smoke workflow: maintainers triggered `publish-hex.yml` manually with `tag=mailglass-v0.3.2` after CI failures left earlier orphan tags. `publish-hex.yml:65, 156, 233` already correctly prefers `github.event.inputs.tag || github.event.release.tag_name` for both checkout `ref` and version resolution. `[VERIFIED: .github/workflows/post-publish-smoke.yml + publish-hex.yml]`
- **REL-18 closure is largely documentation work.** The workflows are correct as written. What's missing is: (1) a clear comment block in both YAMLs labeling release-event as canonical and `workflow_dispatch` as fallback-only (already partially present at `publish-hex.yml:11-12` and `post-publish-smoke.yml:11-13`); (2) updates to `.planning/STATE.md`, `.planning/REQUIREMENTS.md`, and `.planning/PROJECT.md` so they no longer describe Issues #25/#9 as active carry-forward gaps; (3) an end-to-end rehearsal (rehearsal proof acceptable per D-27-06) using `workflow_dispatch tag=...` against a known live tag to confirm the manual recovery path still works. `[VERIFIED: grep across .planning/]`

**Primary recommendation:** Three plans — installer template + golden refresh (REL-17), workflow comment hardening + rehearsal evidence (REL-18), and planning-state cleanup (D-27-08/09). Each maps to one logical reviewer concern and avoids cross-coupling unrelated changes.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Generated `runtime.exs` Swoosh block | Installer template (`Mailglass.Installer.Templates`) | — | Single-write seam: `runtime_config_body/0` is consumed only by `Mailglass.Installer.Plan.build/2` at `lib/mailglass/installer/plan.ex:59`. |
| Golden snapshot maintenance | Test fixture (`test/example/README.md`) | `Mailglass.Test.InstallerFixtureHelpers` | Snapshots regenerate via `MIX_INSTALLER_ACCEPT_GOLDEN=1`; helpers normalize tmp paths and timestamps. |
| Release-day version resolution | GitHub Actions runtime (`cron-guard` job) | `actions/github-script` | Branching logic lives in `post-publish-smoke.yml:34-128` JS body; `release.tag_name` is the canonical signal. |
| Publish-time tag/ref resolution | GitHub Actions runtime (`publish-hex.yml`) | `actions/checkout` | `ref: ${{ github.event.inputs.tag || github.event.release.tag_name }}` already prefers manual tag, falls through to release event. |
| Fresh-host smoke contract | In-repo test (`install_first_preview_smoke_test.exs`) | `post-publish-smoke.yml` `consumer-install` job | The Elixir test asserts the YAML's contract markers; the workflow runs the contract live against published Hex artifacts. |

## Area A: Installer Swoosh Default (REL-17)

### A1. Verbatim quote of the current `runtime_config_body/0`

`lib/mailglass/installer/templates.ex:140-149`:

```elixir
@spec runtime_config_body() :: String.t()
def runtime_config_body do
  """
  config :mailglass,
    telemetry_prefix: [:mailglass],
    enable_preview: true

  config :swoosh, :api_client, Swoosh.ApiClient.Finch
  """
end
```

Module docstring at `lib/mailglass/installer/templates.ex:131-139` justifies this as "Finch ships with mix phx.new" — but as confirmed in the Phase 18 evidence, this assumption was wrong for `mix phx.new --no-mailer` hosts (which is what the smoke workflow uses) and any host that lets Finch fall out of deps later. **`[VERIFIED: file content]`**

### A2. Pinned Swoosh version and its actual default behavior

`mix.lock` pins `swoosh 1.25.0`. Inspecting `deps/swoosh/lib/swoosh/api_client.ex`:

```elixir
defp api_client do
  Application.fetch_env!(:swoosh, :api_client)
end

def init do
  client = api_client()

  if Code.ensure_loaded?(client) and function_exported?(client, :init, 0) do
    :ok = client.init()
  end

  :ok
end
```

And `deps/swoosh/lib/swoosh/application.ex:7`:

```elixir
def start(_type, _args) do
  Swoosh.ApiClient.init()
  ...
end
```

**There is NO Swoosh-side default.** `Application.fetch_env!/2` raises `KeyError` if `:api_client` is absent. Phoenix 1.8 with `--no-mailer` (used in `post-publish-smoke.yml:260`) does not configure swoosh at all, so the host crashes at `Swoosh.Application.start/2` unless the installer fills in the gap. The current installer fills it with `Swoosh.ApiClient.Finch`, which itself requires `:finch` in deps. The host generated by `mix phx.new sandbox --no-mailer --no-ecto` does NOT depend on `:finch` (Phoenix only pulls Finch transitively for the Telemetry HTTP poller, not in the `--no-mailer` shape). Result: boot crashes with `UndefinedFunctionError` for `Swoosh.ApiClient.Finch.init/0`. `[VERIFIED: deps/swoosh source + post-publish-smoke.yml:260]`

When set to `false`, `Code.ensure_loaded?(false)` returns `false` (atom is not a module), so `Swoosh.ApiClient.init/0` no-ops cleanly and Swoosh boots without error. **This is the documented escape valve in the Swoosh README:**

```
# config :swoosh, :api_client, false
# This is the case when you are using `Swoosh.Adapters.Local`,
```

`[VERIFIED: deps/swoosh/README.md:104-107]`

### A3. What the install smoke tests assert

**`test/mailglass/install/install_first_preview_smoke_test.exs`** (lines 7-29) asserts:
1. Router contains `mailglass_admin_routes "/mail"` (line 17).
2. Mailglass layout file exists (line 18).
3. The minimal mailable scaffold file exists (line 19).
4. The `post-publish-smoke.yml` YAML contains the marker strings: `"Run mix mailglass.install"`, `"Compile, fail on warnings"`, `"Boot endpoint and curl /dev/mail/"`, `"GET /dev/mail/ → HTTP ${STATUS}"` (lines 22-25).
5. Whole test completes in < 300_000 ms.

It does NOT inspect the generated `runtime.exs` content. So this test is **unaffected** by the template change. **`[VERIFIED: file content]`**

**`test/mailglass/install/install_golden_test.exs`** runs `Mailglass.Installer.Apply.run` against the example fixture and compares the resulting tree (file paths + sha256 digests + verbatim file bodies, with normalizations for tmp paths, migration timestamps, and installer version) against two snapshot blocks embedded in `test/example/README.md`:
- `<!-- GOLDEN_FRESH_START -->` ... `<!-- GOLDEN_FRESH_END -->` (lines 12-169)
- `<!-- GOLDEN_NO_ADMIN_START -->` ... `<!-- GOLDEN_NO_ADMIN_END -->` (lines 171-319)

**Both snapshots embed the literal `config :swoosh, :api_client, Swoosh.ApiClient.Finch` line** (line 54 and line 213) AND its sha256 digest (`config/runtime.exs sha256:2cc43bcd5ede9de69f9b6dcfb5b57e2474b81fdd01b084637342598fa2845c93` at lines 18 and 175 of the README, plus the same digest in the `.mailglass.toml` `[paths]` block at lines 38 and 197). Refresh command is documented in the test failure message and at `test/example/README.md:10`:

```
MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors
```

After the template change, **all four sha256 digests** for `config/runtime.exs` (one in tree-listing + one in `.mailglass.toml` per snapshot, × 2 snapshots) will change, and the verbatim file body will change in two places. The refresh command handles all of this automatically. **`[VERIFIED: test/example/README.md + test/mailglass/install/install_golden_test.exs]`**

### A4. Single-write seam analysis

The seam is **single-point**:

- Definition: `lib/mailglass/installer/templates.ex:140-149` (`runtime_config_body/0`).
- Sole consumer: `lib/mailglass/installer/plan.ex:59` (`body: Templates.runtime_config_body()`).
- No tests in `test/` reference `runtime_config_body` or grep-match `api_client.*Finch` or `api_client.*false` — verified by `grep -rE 'runtime_config_body|api_client.*Finch|api_client.*false' test/`.

**Editing the template body and refreshing the goldens is the entire code-side change for REL-17.** No other code path or test asserts the literal value. Module docstring at `lib/mailglass/installer/templates.ex:131-139` should also be updated to match the new behavior (it currently describes the Finch rationale verbatim). **`[VERIFIED: grep + structural review]`**

### A5. User-visible breakage analysis

**Dev-path impact:** None. The dev preview LiveView (`MailglassAdmin.Router.mailglass_admin_routes`) does not invoke any Swoosh adapter. The fixture's mailable scaffold uses `Mailglass.Mailable` which produces a deliverable map but does not invoke Swoosh's `:api_client` (HTTP client is only used by API-based adapters like Postmark/SendGrid/Mailgun/SES/Resend, not by `Swoosh.Adapters.Local` or `Mailglass.Adapters.Fake`). The mailglass core's own `config/config.exs:7` defaults to `adapter: {Mailglass.Adapters.Fake, []}`, which is a pure in-memory adapter and never hits Swoosh's HTTP client. **`[VERIFIED: lib/mailglass/adapters/swoosh.ex doc + config/config.exs]`**

**Production-path impact:** Adopters who configure an external Swoosh adapter (Postmark, SendGrid, etc.) will now see Swoosh raise `Swoosh.ApiClient.NotInitialized` (or equivalent) at first delivery attempt because `Application.fetch_env!(:swoosh, :api_client)` will return `false` and the API-based adapters call back through `Swoosh.ApiClient.post/4`. **This forces adopters to make an explicit choice** instead of inheriting an unstated Finch dependency. This is the deliberate posture of D-27-01/02. The error path is well-defined in Swoosh's source (api_client.ex:34-36) and produces a clear stacktrace pointing to `:swoosh, :api_client`. The runtime block already includes commented examples for adopters at `config/runtime.exs:10-23` showing how to configure Postmark/SendGrid/SES, but **does not currently show how to pick an api_client**. The plan should include a one-line commented-out example of `config :swoosh, :api_client, Swoosh.ApiClient.Finch` (or `Hackney` or `Req`) **immediately above** the `config :swoosh, :api_client, false` line so the adopter sees both: the bootable default and the upgrade path. `[ASSUMED — see Assumptions Log A1]`

### A6. Docs/README references to the Swoosh block

Searched `README.md`, `mailglass_admin/README.md`, `CHANGELOG.md`, `docs/api_stability.md`, and all of `guides/*.md`:

- **No user-facing guide** describes the post-install Swoosh block. The only mention in user-visible docs is `CHANGELOG.md:171`: `"installer: match real Phoenix router anchor + Swoosh Finch default"`. This is historical changelog text and does NOT need editing per CHANGELOG conventions (changelog entries describe past releases, not future ones).
- The next changelog entry (auto-generated by Release Please from the Phase 27 `fix:` commits) will describe the new default. **No manual CHANGELOG edit needed.**

`[VERIFIED: grep across README + guides + docs + CHANGELOG]`

## Area B: Post-Publish Smoke Release Tag (REL-18)

### B1. Trigger and version-resolution map for `post-publish-smoke.yml`

| Trigger | Lines | Version resolution path | Status |
|---------|-------|-------------------------|--------|
| `release: types: [published]` | 4-5 | `cron-guard` reads `context.payload?.release?.tag_name`, normalizes to `major.minor.patch` (lines 48-61). | ✅ Canonical (D-27-05). |
| `workflow_dispatch` with `inputs.tag` | 8-15 | `cron-guard` reads `context.payload?.inputs?.tag` (lines 63-71). | ✅ Fallback (D-27-06). |
| `schedule: cron "0 12 * * *"` | 6-7 | `cron-guard` calls `github.rest.repos.listReleases({per_page: 5})`, picks `releases[0]`, applies 7-day age window + Hex.pm presence check (lines 78-128). | ✅ Independent health-check path (D-27-07). |

**The job correctly prioritizes `release` event first, then `workflow_dispatch`, then falls through to schedule-style "find latest release" logic.** This matches the locked decision matrix exactly. **`[VERIFIED: post-publish-smoke.yml:34-128]`**

### B2. The "manual version-resolution workaround" — what it actually was

**Confused phrasing in STATE.md**. The line 69 STATE.md text reads: *"Issue #9 — chronic post-publish-smoke version-resolution bug. Sidestepped here via `workflow_dispatch tag=mailglass-v0.3.2`; structural fix still pending."*

But cross-referencing `.planning/milestones/v0.3-phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md:63` and the Phase 18 SUMMARY narrative shows the actual situation:

- The `post-publish-smoke.yml` cron-guard logic was rewritten **during Phase 18 itself** (the comment at lines 73-76 references "the 2026-04-28 rehearsal" where an older `workflow_run`-triggered path resolved `VERSION=main` and waited on `mix hex.info mailglass main` — that bug is FIXED in the current YAML).
- The Phase 18 maintainer used `workflow_dispatch tag=mailglass-v0.3.2` to **trigger the publish workflow** manually (because earlier release tags 0.3.0/0.3.1 had failed CI and become orphan tags — Release Please cut a new 0.3.2 tag with green CI, but at that point a manual publish dispatch was simpler than another release-please cycle).
- So the "workaround" was a **publish-side recovery action**, not a smoke-side bug. The smoke workflow then ran automatically via the `release.published` event for `mailglass-v0.3.2`.

**What's actually still pending:** Validating that the release-event path works **end-to-end** with no maintainer intervention from Release Please cutting a tag through smoke completing. The 0.3.2 cycle didn't prove that because the maintainer triggered publish manually. **The plan should include one rehearsal that exercises the full automatic path** (e.g., during the v0.4 ship phase, or by creating a no-op patch release like `0.3.3-rc.0` and watching it auto-flow). This rehearsal is the closure proof for D-27-05. `[VERIFIED: STATE.md, 18-02-PUBLISH-EVIDENCE.md, post-publish-smoke.yml inline comments]`

### B3. publish-hex.yml release-event consumption

`publish-hex.yml` is triggered by `release: types: [published]` (line 4-5) AND `workflow_dispatch` (line 6-28). The version resolution paths are:

- **Checkout ref** (lines 65, 156, 233): `ref: ${{ github.event.inputs.tag || github.event.release.tag_name }}` — workflow_dispatch input wins; release event tag is the fallback.
- **Tagged-SHA gate** (lines 109-120): `actions/github-script` resolves `context.payload.release?.tag_name || context.payload.inputs?.tag || context.sha` → `getCommit({ref})` → `commit.data.sha`. This **inverts** the precedence (release tag preferred). Inconsistent with checkout step but harmless: both eventually point at the same SHA on a real release.
- **Version-from-mix.exs** (lines 169-173): Reads `@version` from `mix.exs` after checkout. This decouples the publish version from the Git tag/ref entirely once the right SHA is checked out.

**No artifact emission to smoke**. `publish-hex.yml` and `post-publish-smoke.yml` are not chained via `workflow_run` (verified by grep). Both react independently to the same GitHub `release.published` event. So the release tag is the shared canonical signal. `[VERIFIED: publish-hex.yml + grep workflow_run]`

### B4. The cron-guard scheduled path

For `eventName === 'schedule'` (lines 78-128 in post-publish-smoke.yml), the logic:

1. Lists last 5 releases via `github.rest.repos.listReleases`.
2. Picks `releases[0]` (most recent).
3. Skips if older than 7 days (line 98-103).
4. Otherwise calls `https://hex.pm/api/packages/mailglass`, checks the version is actually on Hex, skips if not (lines 105-124).
5. Sets `should_run=true, version=<latest>`.

This is the "independent latest-release resolution" cited in D-27-07. **It must remain isolated from the release-day path** — and it already is, because the release-event branch returns at line 60 before any of this code executes. `[VERIFIED: post-publish-smoke.yml]`

### B5. After-the-refactor matrix (no change needed)

| Trigger | Version source | Already correct? |
|---------|---------------|------------------|
| `release: types: [published]` | `github.event.release.tag_name` | ✅ Yes |
| `workflow_dispatch tag=...` | `github.event.inputs.tag` | ✅ Yes |
| `schedule` | `cron-guard` listReleases + 7-day window + Hex.pm presence | ✅ Yes |

**No code changes are needed in either workflow.** What IS needed:

1. **Comment hardening** — explicit, current-tense statements in the YAML headers labeling release-event as canonical and `workflow_dispatch` as fallback-only. The current comments at `publish-hex.yml:11-12` and `post-publish-smoke.yml:11-13` reference "Canonical fallback for v0.3.0" — that wording is stale. Replace with version-agnostic phrasing per D-27-06.
2. **Concurrency group review** — `post-publish-smoke.yml:23` uses `${{ github.event.inputs.tag || github.event.release.tag_name || github.ref }}`. Order is correct but `github.ref` for a `release` event is `refs/tags/<tag>` and for `schedule` is `refs/heads/main` — fine, but document the intent inline.
3. **Rehearsal evidence** — see B2.

### B6. Other workflow file interactions

Workflows in `.github/workflows/`:

| File | Trigger | Interaction with publish/smoke |
|------|---------|-------------------------------|
| `release-please.yml` | `push: main` | Cuts release PRs + creates tags. The tag creation triggers `release.published` → fires both publish-hex and post-publish-smoke independently. Recursion-safe via `GITHUB_TOKEN` anti-recursion guarantee. |
| `ci.yml` | PR / push | Read by `publish-hex.yml`'s `gate-ci-green` job (lines 121-143) via `actions/github-script` → `listWorkflowRuns({workflow_id: 'ci.yml', head_sha})`. **Read-only consumer.** |
| `publish-hex.yml` | `release.published` + `workflow_dispatch` | Publishes to Hex. Has `environment: hex-publish` gate. |
| `post-publish-smoke.yml` | `release.published` + `workflow_dispatch` + `schedule` | Validates published artifact. |
| `gate-self-test.yml` | `workflow_dispatch` only | Independent — no interaction. |
| `provider-live.yml` | (likely `schedule`/dispatch) | Independent — no interaction. |
| `branch-protection-drift.yml` | (probably scheduled) | Independent — no interaction. |
| `actionlint.yml`, `advisory-matrix.yml`, `pr-title.yml` | PR/push | No release interaction. |

**Critical confirmation**: `publish-hex.yml` and `post-publish-smoke.yml` are NOT linked via `workflow_run`. The historical "workflow_run" reference in `post-publish-smoke.yml:73-76` is a dead-code comment about a path that was removed. Both workflows fire from the same `release.published` event in parallel. `[VERIFIED: grep workflow_run + workflow file inspection]`

## Area C: Documentation/State Cleanup

### C1. Active-state references to the workaround / Issues #25 #9

| File | Line | Text |
|------|------|------|
| `.planning/STATE.md` | 68 | `**Issue #25** — post-publish-smoke fresh-host install crashes on missing `:hackney` (Swoosh ApiClient default in Phoenix 1.8). Recommended fix: `mix mailglass.install` writes `config :swoosh, :api_client, false` (or Finch). v0.4 candidate.` |
| `.planning/STATE.md` | 69 | `**Issue #9** — chronic post-publish-smoke version-resolution bug. Sidestepped here via `workflow_dispatch tag=mailglass-v0.3.2`; structural fix still pending.` |
| `.planning/STATE.md` | 78 | `Phase 18 (Ship v0.3.x) complete 2026-04-29 — shipped as v0.3.2 after 3-cycle CI recovery (...). DELIV-04 marked Complete; smoke contract gap (Issue #25) tracked for v0.4.` |
| `.planning/REQUIREMENTS.md` | 36 | `- [ ] **REL-17**: Fresh-host install no longer crashes on missing `:hackney` / Swoosh API client defaults (`Issue #25`).` |
| `.planning/REQUIREMENTS.md` | 37 | `- [ ] **REL-18**: Post-publish smoke no longer depends on the current manual version-resolution workaround (`Issue #9`).` |
| `.planning/REQUIREMENTS.md` | 84-85 | Traceability table rows — REL-17 / REL-18 marked `Pending` for Phase 27. |
| `.planning/PROJECT.md` | 73 | `- Release/install closure for `Issue #25` and `Issue #9`` (in milestone goals list) |
| `.planning/PROJECT.md` | 124 | `- [ ] `REL-17` / `REL-18` — fresh-host install and post-publish smoke closure` (in checklist) |
| `.planning/MILESTONE-ARC.md` | 90 | `- Carry-forward ship/install fixes from `Issue #25` and `Issue #9`` (already past-tense framing acceptable; review during Phase 27 closure) |
| `.planning/ROADMAP.md` | 29, 101 | Phase 27 entry references `REL-17`, `REL-18` — should flip to ✅ on closure, no text rewrite needed. |

**Closure edits per D-27-08:**
- Flip REQUIREMENTS.md REL-17/REL-18 checkboxes to `[x]` and traceability rows to `Complete`.
- Flip PROJECT.md line 124 checkbox to `[x]`.
- Replace the "Carry-forward to next milestone" block in STATE.md (lines 66-69) with a statement that Issue #25 was resolved in Phase 27 (or remove entirely; whichever the planner prefers — these were carry-forward-from-v0.3 items, not v0.4 carry-forwards).
- Update STATE.md line 78 to remove "(Issue #25) tracked for v0.4" parenthetical OR add a forward-pointer to the Phase 27 closure.
- ROADMAP.md Phase 27 row — update Status column from `Pending` to `Complete` once execution finishes (this is mechanical, not a manual edit).

### C2. Archived references that must NOT be edited (D-27-09)

| File | Why preserve as-is |
|------|---------------------|
| `.planning/milestones/v0.3-phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md` | Historical evidence of the v0.3.2 publish recovery cycle, including the workaround narrative. Sealed milestone artifact. |
| `.planning/milestones/v0.3-phases/18-ship-v0-3-0/18-02-SUMMARY.md` | Same — sealed milestone summary. |
| `.planning/milestones/v0.3-ROADMAP.md` | Sealed milestone roadmap. |

These should remain unchanged. The text "Sidestepped via `workflow_dispatch tag=mailglass-v0.3.2`" in archived docs is correct historical record.

### C3. User-facing docs to review

- **CHANGELOG.md** — auto-generated by Release Please from `fix:` commit messages. The Phase 27 commits should be `fix(installer):` and `chore(release):` shaped so the next changelog entry reads sensibly. **No manual edit needed.**
- **README.md** + `guides/*.md` — searched, no current text describes the api_client choice, so no edits required.
- **Inline workflow comments** in `publish-hex.yml:11-12` and `post-publish-smoke.yml:11-13` reference "Canonical fallback for v0.3.0" — version-stale. Replace with version-agnostic wording.

## Area D: Risk Surface and Validation Strategy

### D1. Cheapest in-repo proof for REL-17

**`test/mailglass/install/install_first_preview_smoke_test.exs`** is the canonical in-repo proof. After the template change:

- Re-run the test. It already passes today (template generates a runnable but crash-prone block); after the change it will continue to pass (test does not inspect api_client value).
- **Add one new assertion** (cheap and tightly-scoped) to that test OR to a dedicated `Mailglass.Installer.TemplatesTest`: assert that `Mailglass.Installer.Templates.runtime_config_body/0` contains the literal string `"config :swoosh, :api_client, false"`. This is a regression sentinel that catches a future revert.
- Re-run `mix test test/mailglass/install/install_golden_test.exs` after `MIX_INSTALLER_ACCEPT_GOLDEN=1` refresh to confirm both goldens stabilize.

**The fresh-host smoke contract from CONTEXT.md D-27-03 (add deps → install → compile → boot → curl /dev/mail/) is exercised live by `post-publish-smoke.yml`'s `consumer-install` job (lines 223-317).** That job runs against the published Hex artifact, so it cannot validate Phase 27 changes pre-publish. The strongest pre-publish proof of correctness is:

1. The Elixir test sentinel above.
2. A local rehearsal: clone `~/projects/mailglass` (or fresh tmp dir), `mix archive.install hex phx_new`, `mix phx.new sandbox --no-mailer --no-ecto`, add `{:mailglass, path: "/Users/jon/projects/mailglass"}` and `{:mailglass_admin, path: "/Users/jon/projects/mailglass/mailglass_admin"}` to the sandbox's `mix.exs`, run `mix deps.get && mix mailglass.install && mix compile --warnings-as-errors && mix phx.server &` and `curl http://localhost:4000/dev/mail/`. **This is the same 5-step contract the workflow runs, executed locally against the working tree before publishing.** The plan should include this as a manual verification step in the verification artifact (or as an automated `mix mailglass.smoke.local` task — discretionary).

### D2. Cheapest proof for REL-18

The release-event automatic path can ONLY be validated end-to-end against a real release. Two cheap proofs:

**Proof A (fallback path, per D-27-06):** Trigger `workflow_dispatch tag=mailglass-v0.3.2` against the EXISTING live tag. Watch the workflow run end-to-end and confirm `cron-guard.outputs.version == "0.3.2"`, `consumer-install` succeeds (currently fails because of the api_client crash — so this proof depends on REL-17 being merged first OR being re-tested in v0.4.0 once the fix ships). Either way, this validates the fallback dispatch path.

**Proof B (canonical path):** Wait for the next real release (v0.4.0 milestone close). Confirm the release-event triggers both publish-hex.yml and post-publish-smoke.yml automatically without manual dispatch. This is the gold-standard proof.

**Recommendation:** Plan B is the canonical proof but only available at v0.4.0 ship time. Plan A is acceptable as Phase 27 closure evidence (with a note that Plan B will be re-validated at v0.4.0 ship per the milestone exit criteria). The plan should land Phase 27 with a verification artifact that documents which proof was used.

### D3. REL-17 failure modes if the fix ships wrong

| Failure mode | Symptom | Detection |
|--------------|---------|-----------|
| Template still writes `Finch` | Fresh-host install: `UndefinedFunctionError: Swoosh.ApiClient.Finch.init/0` at app boot | `consumer-install` job in `post-publish-smoke.yml` still red. The grep guard in compile step (line 287-289) catches `UndefinedFunctionError` literally. |
| Template writes `false` but adopter configures Postmark adapter | First send raises `Swoosh.ApiClient` error (api_client is false; no HTTP client to call). Not a boot crash but a delivery-time failure. | Adopter sees clear stacktrace pointing at `:swoosh, :api_client`. The mitigation is the commented `config :swoosh, :api_client, Swoosh.ApiClient.Finch` line above the false setting (per A5 recommendation). `[ASSUMED A1]` |
| Goldens not refreshed | `install_golden_test.exs` red on PR | CI catches before merge. Nothing escapes to Hex. |
| Template moduledoc not updated | Stale comment in source code (no functional impact) | Code review catches. |

**Severity:** Low. The fix is a one-line edit; the failure modes are all well-detected by existing CI and the post-publish smoke workflow.

### D4. REL-18 failure modes if "fix" ships wrong

Since REL-18 is largely doc + comment hardening + rehearsal evidence (the workflow logic is already correct):

| Failure mode | Symptom | Detection |
|--------------|---------|-----------|
| Inadvertently breaking `cron-guard` JS while editing comments | `cron-guard` job fails on next release; smoke does not run | Rehearsal proof catches. CI's actionlint.yml workflow validates YAML structure. |
| Wrong concurrency-group key change | Concurrent runs collide or fail to gate | Rehearsal catches. |
| Planning-state edits introduce contradictions (e.g., mark REL-18 complete but leave PROJECT.md checkbox unchecked) | Documentation incoherence | Code review + GSD tooling validation. |

**Severity:** Low-medium. The risk is in editing the workflow YAML at all — every edit risks regression. The plan should minimize YAML changes to comment-only diffs (no logic changes) unless rehearsal exposes an actual bug.

## Validation Architecture (Dimension 8)

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.18, OTP 27) — see `mix.exs:135` swoosh dep, `.tool-versions` |
| Config file | `test/test_helper.exs`, `mix.exs` (`test_paths: ["test"]`) |
| Quick run command | `mix test test/mailglass/install/install_first_preview_smoke_test.exs --warnings-as-errors` |
| Golden refresh | `MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors` |
| Full suite command | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| REL-17 | Generated `runtime.exs` does not crash a fresh Phoenix host on boot | unit (sentinel) | `mix test test/mailglass/install/install_first_preview_smoke_test.exs:7` | ✅ Existing test, may add one literal-string assertion as regression sentinel |
| REL-17 | Generated installer file tree matches expected snapshot | golden | `mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors` | ✅ Existing test, snapshot bodies regenerated |
| REL-17 | End-to-end: add deps → install → compile → boot → curl /dev/mail/ | live workflow (manual rehearsal locally OR automatic post-publish) | local rehearsal command sequence per D1; OR `post-publish-smoke.yml` `consumer-install` job after publish | ✅ Workflow exists; local rehearsal is manual |
| REL-18 | Release-event triggers smoke automatically | live workflow (rehearsal via fallback dispatch OR wait for next real release) | `gh workflow run post-publish-smoke.yml -f tag=mailglass-v0.3.2` (Proof A) OR observe v0.4.0 ship (Proof B) | ✅ Workflow exists |
| REL-18 | Workflow comments accurately describe canonical/fallback distinction | doc lint / code review | manual review of YAML diff | n/a — review-time check |
| REL-18 | Planning state reflects post-fix contract | doc lint | grep `Issue #25\|Issue #9` in `.planning/STATE.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md` after edits | n/a — review-time check |

### Sampling Rate

- **Per task commit:** `mix test test/mailglass/install/ --warnings-as-errors` (~30 sec; covers both relevant tests)
- **Per wave merge:** `mix test --warnings-as-errors` (full suite)
- **Phase gate:** Full suite green + at least one of REL-18 Proof A or Proof B captured in verification artifact

### Wave 0 Gaps

- [ ] None — both `install_first_preview_smoke_test.exs` and `install_golden_test.exs` already exist. Optional sentinel assertion in `install_first_preview_smoke_test.exs` OR a tiny new `templates_test.exs` is a discretionary add.
- [ ] No new framework, no new fixtures, no new conftest equivalent needed.

## Pitfalls

### Pitfall 1: Forgetting to refresh both golden snapshots

**What goes wrong:** Edit the template, re-run `install_golden_test.exs` without `MIX_INSTALLER_ACCEPT_GOLDEN=1`. Test fails. Engineer refreshes only `GOLDEN_FRESH` (the first failure), thinks they're done. `GOLDEN_NO_ADMIN` still fails on next CI run.

**Why it happens:** Both snapshots embed the runtime body verbatim and both digests change.

**How to avoid:** The refresh command in the test failure message refreshes BOTH snapshots in one pass (the test runs both fixtures). The README documents this at line 10. Plan should include explicit verification step: after refresh, `git diff test/example/README.md` should show changes in both snapshot blocks.

### Pitfall 2: Updating template moduledoc rationale to contradict the new behavior

**What goes wrong:** The `runtime_config_body/0` moduledoc at lines 131-139 explicitly describes the Finch rationale ("Finch ships with mix phx.new ... With Finch, no extra deps or boot wiring is needed"). If the engineer changes the body but leaves the docstring, future readers see contradictory documentation.

**How to avoid:** Plan should explicitly call out "rewrite the @doc above runtime_config_body/0 to match the new behavior." Quote the new rationale: Mailglass does not pin a specific HTTP client; `false` lets Swoosh boot; commented examples show how to opt in to Finch/Hackney/Req.

### Pitfall 3: Concurrency-group key drift in workflow YAML

**What goes wrong:** Editing `post-publish-smoke.yml` to clarify comments accidentally changes the concurrency group key (line 23). Two concurrent smoke runs (e.g., release + scheduled) deadlock or one cancels the other unexpectedly.

**How to avoid:** Plan should cap REL-18 YAML edits at "comments only" unless an explicit logic change is justified by a rehearsal failure. Diff review must inspect `concurrency:` block.

### Pitfall 4: CHANGELOG.md edit conflicts with Release Please

**What goes wrong:** Manual CHANGELOG.md edits to describe REL-17/REL-18 collide with Release Please's auto-generated section on the next release.

**How to avoid:** Do NOT manually edit CHANGELOG.md. Use `fix(installer):` and `chore(release):` Conventional Commit prefixes; Release Please handles the changelog. (CLAUDE.md and project methodology already enforce this.)

### Pitfall 5: Optional-deps lane interaction (cross-check from CLAUDE.md)

**What goes wrong:** `Mailglass.OptionalDeps.*` is the gateway pattern for optional deps. Engineer wonders if Swoosh's api_client should be wrapped similarly.

**How to avoid:** Swoosh itself is not optional (it's a hard dep at `mix.exs:135`). The `:api_client` is a Swoosh-internal config, not a mailglass optional-dep. **No `Mailglass.OptionalDeps.*` change is needed.** The CI lane `mix compile --no-optional-deps --warnings-as-errors` (`ci.yml:105`) is unaffected.

### Pitfall 6: Misinterpreting "Issue #9" scope

**What goes wrong:** Reading STATE.md line 69 literally and trying to "fix" `cron-guard` version resolution when it's already correct. Wasted effort.

**How to avoid:** The plan must explicitly state the diagnosis from B2 above: the cron-guard logic was already fixed during Phase 18; what remained pending is rehearsal evidence + comment hardening. Don't rewrite working JS.

### Pitfall 7: Cross-check against `.planning/research/PITFALLS.md`

`grep -nE 'Issue #25|Issue #9|hackney|api_client|workflow_dispatch tag' .planning/research/PITFALLS.md` returns 0 matches. The 42 pre-existing pitfalls do not include this domain. **No conflicts to reconcile.** `[VERIFIED: grep]`

### Pitfall 8: HEX_API_KEY visibility (defensive check per CLAUDE.md)

REL-17 and REL-18 changes do NOT touch any workflow's secret-handling logic. `publish-hex.yml`'s `environment: hex-publish` gate (lines 152, 228) is unchanged. The `post-publish-smoke.yml` workflow does not consume HEX_API_KEY at all. **No secret-scoping risk.** `[VERIFIED: grep HEX_API_KEY in publish-hex.yml + post-publish-smoke.yml]`

## Recommended Plan Decomposition

**Suggested: three plans**, sliced by reviewer concern boundary, each independently mergeable but executed in order:

### `27-01-PLAN.md` — Installer Swoosh default + golden refresh (REL-17)

**Files touched:** `lib/mailglass/installer/templates.ex` (template body + moduledoc), `test/example/README.md` (both golden snapshots regenerated via the documented refresh command). Optional: add a literal-string sentinel assertion to `test/mailglass/install/install_first_preview_smoke_test.exs` OR new `test/mailglass/installer/templates_test.exs`.

**Verification:**
- `mix test test/mailglass/install/ --warnings-as-errors` green.
- `git diff test/example/README.md` shows updates to both `GOLDEN_FRESH` and `GOLDEN_NO_ADMIN` blocks (digests + verbatim runtime.exs body).
- Local rehearsal per D1 (manual, captured in verification artifact OR a `mix mailglass.smoke.local` task — discretionary).

**Rationale for slicing:** This is the only code change in the phase. Self-contained, small diff, single reviewer focus.

### `27-02-PLAN.md` — Workflow comment hardening + rehearsal evidence (REL-18)

**Files touched:** `.github/workflows/publish-hex.yml` (comment block at lines 11-12), `.github/workflows/post-publish-smoke.yml` (comment block at lines 11-13 + the historical-note comment at lines 73-76 if it can be made clearer). **No logic changes** unless rehearsal exposes a bug.

**Verification:**
- `actionlint` (already gated by CI) green on the YAML diff.
- One rehearsal proof captured in verification artifact: either Proof A (`gh workflow run post-publish-smoke.yml -f tag=mailglass-v0.3.2` against the existing live tag, after REL-17 ships so the consumer-install step passes) OR Proof B (deferred to v0.4.0 ship, with a clear note in the verification artifact).

**Rationale for slicing:** YAML-only changes; reviewer concern is "are the comments accurate and is the manual recovery path still functional?". Independent from code changes.

### `27-03-PLAN.md` — Planning-state cleanup (D-27-08/09)

**Files touched:** `.planning/REQUIREMENTS.md` (flip checkboxes + traceability rows for REL-17/REL-18), `.planning/PROJECT.md` (line 124 checkbox), `.planning/STATE.md` (rework "Carry-forward to next milestone" block + the parenthetical at line 78). **Do NOT edit** any file under `.planning/milestones/v0.3-phases/` (D-27-09).

**Verification:**
- `grep -rE 'Issue #25|Issue #9|workflow_dispatch tag=mailglass' .planning/` returns ONLY archived `milestones/v0.3-*` references.
- REL-17 + REL-18 traceability rows show `Complete`.
- ROADMAP.md Phase 27 row flips to ✅ via GSD tooling at phase close (not manually edited in this plan).

**Rationale for slicing:** Doc-only change; isolates state-doc maintenance from code/workflow changes. Easy code-review scope.

**Total scope:** 3 plans, each ~1-3 file edits, each independently mergeable. No cross-plan dependency except sequencing (REL-17 ships before REL-18 rehearsal so the smoke proof works on the existing tag).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Adding a commented-out `config :swoosh, :api_client, Swoosh.ApiClient.Finch` example above the `false` line in the installer template improves adopter ergonomics | Area A (A5) and pitfalls | Low: it's a discretionary addition. If maintainer disagrees, drop it; the `false` setting alone satisfies D-27-01. The CONTEXT.md "Claude's Discretion" entry explicitly permits this kind of wording choice. |

## Sources

### Primary (HIGH confidence)
- `lib/mailglass/installer/templates.ex` — current template seam quoted verbatim
- `lib/mailglass/installer/plan.ex` — confirms single consumer of `runtime_config_body/0`
- `deps/swoosh/lib/swoosh/api_client.ex` — `init/0` and `api_client/0` source confirms `false` is safe and "unset" raises
- `deps/swoosh/lib/swoosh/application.ex` — confirms `init/0` is called on app boot
- `deps/swoosh/README.md:97-107` — documents `config :swoosh, :api_client, false` escape valve
- `config/config.exs:15` and `mailglass_admin/config/config.exs:20` — repo's own usage matches the recommended adopter setting
- `test/example/README.md` — both golden snapshots inspected line-by-line
- `test/mailglass/install/install_first_preview_smoke_test.exs` — test contract quoted verbatim
- `test/mailglass/install/install_golden_test.exs` — golden refresh mechanism quoted verbatim
- `.github/workflows/post-publish-smoke.yml` — full YAML inspected, version-resolution paths mapped
- `.github/workflows/publish-hex.yml` — full YAML inspected, ref/tag handling confirmed
- `.planning/milestones/v0.3-phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md` — historical recovery narrative

### Secondary (MEDIUM confidence)
- WebFetch of https://hexdocs.pm/swoosh/Swoosh.html — confirms api_client `false` semantics and Finch/Hackney/Req as the three shipped clients
- WebFetch of https://github.com/phoenixframework/phoenix/issues/5786 — confirms the long-standing Phoenix/Swoosh dependency-omission failure mode

### Tertiary (LOW confidence)
- WebFetch of https://github.com/phoenixframework/phoenix/commit/3c63d9e — confirms Phoenix mailer generator default switched to `Local` adapter, but does not pin which Phoenix version

## Metadata

**Confidence breakdown:**
- Installer seam + template: HIGH — single file, verified, single consumer
- Swoosh runtime behavior: HIGH — vendored source inspected; `Application.fetch_env!` semantics unambiguous
- Smoke workflow correctness: HIGH — full YAML inspected, branching logic mapped
- Publish workflow correctness: HIGH — full YAML inspected
- Planning-doc closure scope: HIGH — exhaustive grep
- A5 commented-example recommendation: MEDIUM — one assumed claim flagged in Assumptions Log

**Research date:** 2026-05-02
**Valid until:** 2026-06-01 (30 days; stable terrain — no expected upstream churn in Swoosh 1.25 or in GitHub Actions release-event semantics)

## RESEARCH COMPLETE
