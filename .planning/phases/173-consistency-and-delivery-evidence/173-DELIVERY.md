# Phase 173 delivery review

This runbook opens the committed Phase 173 candidate in an isolated demo and shows
which checkout, Admin CSS bytes, browser routes, and CI result the evidence describes.
It uses synthetic fixtures. The earlier feedback preview is a separate service and
must remain available while this review candidate runs.

## Start and open the candidate

From the original repository workspace, after all Phase 173 source, test, and
documentation changes have their normal GSD commits, run:

```bash
bash scripts/check_phase173_candidate.sh
```

The launcher records only original dirty path/status metadata in
`reference/demo_app/tmp/demo_browser_evidence/origin-dirty-paths.json`, then creates
a detached worktree from the captured `HEAD`. The candidate checkout must have that
exact candidate SHA and a clean checkout (tracked and untracked status) before runtime evidence
is written. Original owner edits are excluded; their file contents are never copied
into the candidate. The excluded owner paths are listed in the metadata record. If an
excluded owner path is also required by a committed
acceptance path, the gate names it and leaves that proof incomplete.

Before candidate execution, the launcher validates Plan 04's six pinned baseline
PNG paths, byte hashes, and dimensions in the original ignored evidence directory.
Only those six validated byte buffers are copied into the detached candidate under
their existing relative names. Missing, altered, escaped, symlinked, or conflicting
baseline files leave an incomplete delivery record and stop before browser capture.
No evidence directory or other owner workspace content is copied. A dirty
`reference/demo_app/README.md` is recorded only as a path/status acceptance gap.

On successful preview startup, open the exact URL printed by the gate and recorded
in `reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json`:

```text
http://127.0.0.1:<recorded-port>/dev/mail
```

Use these review routes:

1. **Preview authoring:** `/dev/mail` — inspect a rendered message and its HTML,
   text, raw, and header views.
2. **Component inventory:** `/dev/mail/gallery` — browse the broad Admin Gallery
   and its representative states.
3. **Curated component stories:** `/dev/storybook/primitives/nav_link?variation_id=long_label`
   — inspect the focused Storybook example using the same Admin CSS.
4. **Outbound operations:** `/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar`
   — review delivery detail and replay investigation.
5. **Inbound operations:** `/demo/login?return_to=%2Fops%2Fmail%2Finbound%3Ftenant_id%3Dnorthstar`
   — review inbound records and their routing evidence.
6. **Recipient output:** `/dev/unsubscribe/<synthetic-state>` — review the bounded
   built-in recipient states. This is not an interactive browser submission test.

The candidate record names the detached candidate worktree path, exact SHA, isolated
Compose project, non-default loopback ports, preview URL, and the source CSS identity,
built CSS identity, and served CSS identity. The browser check requests the preview, Gallery, and curated
Storybook pages and hashes the bytes fetched from their versioned CSS route against
`mailglass_admin/priv/static/app.css`; `mailglass_admin/assets/css/app.css` is
recorded separately as the source CSS identity. A startup log or URL string alone
never establishes readiness.

The candidate then runs the focused evidence wrapper in a separate disposable
Compose project. That generated project ID is passed to the app as
`DEMO_EVIDENCE_PROJECT_ID` and to Playwright as `DEMO_EVIDENCE_RUN_ID`. Each reset
first reads `/health` without following redirects and requires the returned project
identity to match the run ID before it sends the reset token. The candidate gate
accepts delivery only when the retained checkpoint reports `passed`, names the exact
candidate SHA, records `candidate_dirty=false`, and every current/baseline PNG is an
allowlisted regular file with its recorded SHA-256 bytes.

## Checks and evidence limits

The detached candidate runs the bounded repository regression gate:

```bash
bash scripts/gsd-regression-gate.sh
```

When Admin CSS or generated assets changed, it also runs the pinned-toolchain asset
check from the candidate checkout:

```bash
cd mailglass_admin
ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix verify.preview
```

Required delivery CI is **`CI Green` for the exact candidate SHA**. The gate checks
GitHub run/job metadata read-only and records the matching run URL and status. A run
for another SHA, an absent run, or a non-success conclusion leaves required proof
missing. Existing browser and screenshot-capture jobs are listed separately as
advisory; they do not replace or weaken the required aggregate. No branch-protection
setting is changed. No merge or publication occurs; this workflow also does not push
or dispatch CI.

The demo and its screenshots contain synthetic data only. This is browser preview
evidence; it does not certify Gmail, Outlook, Apple Mail, delivered-email dark mode,
remote image loading, or any other email-client behavior. The browser checks cover
their recorded 375px viewport and route/asset identity. The 320px Gallery overflow
recorded by Plan 02 remains deferred and is not a pass.

Runtime JSON and screenshots live only under the ignored
`reference/demo_app/tmp/demo_browser_evidence/` directory. Capture artifacts have a
14-day advisory retention period. `artifactDirectory` is the local evidence root;
only `uploadableArtifactDirectory` at
`reference/demo_app/tmp/demo_browser_evidence/retained/` contains the sanitized
checkpoint and six current/baseline PNG pairs allowed into advisory retention. Raw
reports, full capture manifests, and `delivery-candidate.json` stay local. Keep the
candidate review Compose project and detached worktree available for owner review;
the gate does not dispose of either one on success or when CI proof is missing.

## Scoped cleanup after review

Read `REVIEW_PROJECT` and `WORKTREE` from
`reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json`, then stop
only that review project and remove only its detached worktree:

```bash
docker compose -p "$REVIEW_PROJECT" -f "$WORKTREE/compose.demo.yml" down
git worktree remove "$WORKTREE"
rmdir "$(dirname "$WORKTREE")"
```

Do not run `make demo-down` for this cleanup: it targets the retained feedback
preview. The ignored JSON and capture artifacts may be removed after their 14-day
review window by deleting only `reference/demo_app/tmp/demo_browser_evidence/`.
