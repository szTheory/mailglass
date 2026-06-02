# Phase 73: Inbound 1.0 Publish Evidence - Context

**Gathered:** 2026-06-02 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Run or prepare the inbound-only publish path for `mailglass_inbound` `1.0.0`
and record Hex, HexDocs, smoke, fallback, and 60-minute decision evidence.

This phase covers REL-02 and REL-03. **Posture is locked to PREPARE-AND-STAGE,
not run** (see D-01): stage `mailglass_inbound-v1.0.0` tag readiness, dry-run
rehearse the inbound-only dispatch, and produce an evidence-ready release record
with post-publish-only fields marked pending. The actual irreversible
`mix hex.publish` of `1.0.0` is the maintainer's deferred trigger, outside this
phase body.

It must NOT: actually publish `1.0.0` to Hex; cut the real
`mailglass_inbound-v1.0.0` tag as a publish trigger; force a `mailglass` or
`mailglass_admin` release; flip reference-app dependency pins to `~> 1.0` before
publish; add a new executable gate that asserts live Hex/HexDocs evidence;
broaden inbound feature scope; or rebuild publish-workflow mechanics that
already exist.
</domain>

<decisions>
## Implementation Decisions

### Publish Posture (escalated — maintainer-confirmed)
- **D-01:** Phase 73 **prepares and stages** the inbound-only publish path; it
  does NOT run the real `mix hex.publish` of `mailglass_inbound 1.0.0`. The
  maintainer confirmed "Prepare & stage" over "Run now" and "Prepare then run".
  Publishing to Hex is irreversible after the 60-minute / zero-download window
  (`MAINTAINING.md:232-234`), so the actual publish trigger stays a deliberate
  maintainer action after this phase, not a phase-body side effect.
- **D-02:** "Prepare" concretely means: (a) confirm `mailglass_inbound-v1.0.0`
  tag/ref readiness from the reviewed source ref without creating the live
  publish-triggering tag; (b) dry-run rehearse the inbound-only dispatch
  (`package=mailglass_inbound`, `dry_run=true`) to prove the path; (c) author
  an evidence-ready release record. No step in this phase causes an irreversible
  external publish.

### Release-Evidence Artifact
- **D-03:** Create a new inbound-scoped release record in the Phase 73 directory
  (e.g. `73-xx-RELEASE-RECORD.md`, optionally a matching
  `73-xx-RELEASE-CHECKLIST.md`), structurally modeled on the Phase 38 forms but
  scoped to the single inbound package and the `mailglass_inbound-v1.0.0` tag.
  Do NOT edit the archived Phase 38 forms in place — they are the linked
  core/admin v1.0 record.
- **D-04:** The record must carry the full REL-03 field set: tag/ref, release-vs-
  dispatch path, publish workflow run URL, fallback usage, Hex index URL,
  HexDocs URL, install/smoke proof, and the 60-minute revert/retire decision.
  Drop the obsolete GitHub-Environment approver fields from the Phase 38 shape
  (publish is hands-free; the `hex-publish` environment has no required
  reviewers).
- **D-05:** Post-publish-only fields (Hex index URL, HexDocs URL, install/smoke
  proof, 60-minute outcome) are recorded as explicit `pending` / `not run`
  markers under the prepare posture — mirroring the Phase 38 "not run"
  convention. Pending evidence must read as pending, never as captured (Honest
  Surface Area).

### Inbound-Only Dispatch Path (reuse, don't rebuild)
- **D-06:** REL-02 requires NO workflow changes. The inbound-only dispatch
  (`package=mailglass_inbound`, dispatched from the `mailglass_inbound-v1.0.0`
  tag, never from `main`) is already wired in `.github/workflows/publish-hex.yml`
  (package choice input, tag-pinned checkout, inbound-slice gating, `dry_run`
  input, ordered fan-out). The phase documents, dry-run-rehearses, and records
  this path — it does not reinvent it.
- **D-07:** The dry-run rehearsal is load-bearing: it must confirm a single-
  package inbound dispatch behaves correctly within the ordered fan-out
  (admin waits on inbound) without forcing a core/admin release.

### Evidence Completeness Verification
- **D-08:** Completeness is asserted by a documented artifact plus, at most, a
  light extension of an existing docs/release-contract check — NOT a brand-new
  executable gate that asserts live Hex/HexDocs URLs. Such a gate would fail
  deterministically because `1.0.0` is not on Hex under the prepare posture and
  would block milestone closeout.
- **D-09:** Reference-app dependency pins (`reference/host_app/mix.exs`,
  `reference/demo_app/mix.exs`) stay at `~> 0.3.0` in this phase. The
  `~> 1.0` flip is the post-publish pin-truth Phase 71 explicitly deferred —
  it happens only when the actual publish runs, because bumping before publish
  makes the reference apps resolve an unavailable version.

### Runbook Truth Fix (in-scope defect)
- **D-10:** Fix the stale runbook path at `MAINTAINING.md:256-257`, which cites
  `.planning/phases/38-release-rehearsal-and-proof-artifacts/...` — a directory
  that was archived to `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/`.
  A release runbook pointing at a missing file is a broken release contract and
  directly undermines SC-3. Fix it while the phase touches the runbook for
  inbound-only publish/fallback wording.

### Claude's Discretion
- Planner may decide whether the inbound release record is one file or a
  record + checklist pair, and the exact filename, as long as the full REL-03
  field set is present and pending fields read as pending.
- Planner may choose whether to extend an existing docs/release-contract test
  for evidence-completeness assertion or rely on the documented artifact alone,
  provided no new gate asserts live external state under the prepare posture.
- Planner should prefer existing repo-native lanes (`mix mailglass.publish.check
  --package mailglass_inbound`, `publish-hex.yml` `dry_run`,
  `mix verify.stability_contract`) over inventing new release mechanics.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 73 goal, v1.6 success criteria (esp. SC-3 and
  SC-4), and requirement mapping.
- `.planning/REQUIREMENTS.md` - REL-02, REL-03, PROOF-01/PROOF-02, and v1.6
  out-of-scope/traceability.
- `.planning/PROJECT.md` - v1.6 milestone intent, convergence posture, release
  governance scope guardrails, hands-free publish policy.
- `.planning/STATE.md` - current position, v1.6 scope locks, prior release/trust
  decisions.
- `.planning/METHODOLOGY.md` - decisive-by-default, honest-surface,
  recommendation-first, compatibility-contract lenses (note: release/irreversible-
  publish phases escalate ship-or-don't to the maintainer).

### Prior Locked Decisions (this milestone)
- `.planning/phases/71-inbound-release-truth-preflight/71-CONTEXT.md` - REL-01 /
  PROOF-01 source/package truth reconciliation and the deferral of reference-pin
  flip + Hex/HexDocs evidence to Phase 73.
- `.planning/phases/72-contract-docs-and-stale/72-CONTEXT.md` - DOC-01 / DOC-02 /
  PROOF-02 contract docs and stale-claim guard decisions.
- `.planning/milestones/v1.4-phases/66-release-position-decision/66-CONTEXT.md` -
  the `mailglass_inbound` `1.0.0` release-position decision and evidence gate.

### Release-Day Forms (shape source — do NOT edit in place)
- `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md`
  - field set + "not run" pending-marker convention to clone for inbound.
- `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-CHECKLIST.md`
  - repo-proved-vs-manual gate separation to adapt for the inbound-only slice.

### Release Truth & Publish Infra
- `.github/workflows/publish-hex.yml` - inbound-only dispatch path
  (`package=mailglass_inbound`), tag-pinned checkout, inbound-slice gating,
  `dry_run` rehearsal input, ordered fan-out core→inbound→admin, idempotent
  `hex.info` skip.
- `.github/workflows/release-please.yml` - release PR sync, sibling pins,
  package-tag emission.
- `.github/workflows/post-publish-smoke.yml` - automatic post-publish smoke
  (does not respect the 60-minute window; manual smoke still required in window).
- `.release-please-manifest.json` / `release-please-config.json` - version truth
  and package topology (inbound is its own line; core/admin linked at 1.3.0).
- `mailglass_inbound/mix.exs` - `@version "1.0.0"`, `MIX_PUBLISH=true` pin
  `{:mailglass, "== 1.3.0"}`, package allowlist, docs extras.
- `mailglass_inbound/CHANGELOG.md` - inbound `1.0.0` release-note truth.
- `.planning/publish/mailglass_inbound-publish-summary.json` - committed inbound
  publish-summary (`source_ref: v1.0.0`, `source_ref_pattern`, pin).
- `.planning/publish/mailglass_inbound-files.expected` - committed package
  allowlist.

### Proof & Runbook Files
- `MAINTAINING.md` - "Release Runbook" (5 steps, literal 60-minute revert timer),
  "Retract Decision Tree", inbound-only fallback dispatch wording, and the stale
  Phase 38 path at lines 256-257 to fix (D-10).
- `lib/mix/tasks/mailglass.publish.check.ex` - package preflight + publish-summary
  writer (`--package mailglass_inbound`).
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` - inbound
  stale-wording / over-claim guards (candidate for light evidence-completeness
  extension per D-08).
- `test/mailglass/stability_contract_test.exs` - root release-automation /
  package-truth assertions.
- `mailglass_inbound/docs/api_stability.md` - canonical inbound stable contract
  inventory.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/publish-hex.yml` already exposes `mailglass_inbound` as a
  `package` dispatch choice, pins checkout to `inputs.tag || release.tag_name`
  (never `main`), gates the inbound slice independently, provides a `dry_run`
  input for non-destructive rehearsal, and orders the fan-out core→inbound→admin
  with idempotent `hex.info` skips. No workflow change is needed for REL-02.
- The Phase 38 release forms already encode the exact REL-03 field set and a
  literal "not run" pending-marker convention — clone the shape, drop the
  obsolete approver fields.
- `MAINTAINING.md:298` already documents the inbound-only recovery dispatch
  (`package=mailglass_inbound` from `mailglass_inbound-v1.0.0`), so REL-02
  documentation is refinement, not invention.
- `.planning/publish/mailglass_inbound-publish-summary.json` already records
  `source_ref: v1.0.0`, `source_ref_pattern: mailglass_inbound-v%{version}`,
  and the `== 1.3.0` pin from Phase 71.
- `mix mailglass.publish.check --package mailglass_inbound` and
  `mix verify.stability_contract` are the repo-native deterministic lanes to
  lean on for required proof.

### Established Patterns
- Required proof is deterministic repo/package evidence; live Hex/HexDocs and
  smoke/install proof are required only once the actual publish runs — recorded
  as pending until then under the prepare posture.
- Package-local checks own package-local truth; root tests own aggregate wiring
  and release-automation topology.
- Inbound is an independent release line; nothing here forces a core/admin cut.
- Stale docs/runbook claims are fixed honestly when a phase touches the surface.

### Integration Points
- Planning should inspect `publish-hex.yml` inbound-slice/`dry_run` paths, the
  Phase 38 forms, `MAINTAINING.md` runbook + retract tree (incl. the stale
  path at 256-257), the inbound publish-summary/allowlist, reference-app pins
  (`reference/host_app/mix.exs`, `reference/demo_app/mix.exs` — left at
  `~> 0.3.0`), and inbound docs-contract / root stability-contract tests.
- Verification should include the inbound publish-check lane, a `dry_run=true`
  rehearsal of the inbound-only dispatch, and `mix verify.stability_contract`;
  no new gate may assert live external (Hex/HexDocs) state.
</code_context>

<specifics>
## Specific Ideas

The maintainer confirmed both presented question sets as recommended:
- **Publish posture:** "Prepare & stage" (not "Run now", not "Prepare then run").
  This phase performs no irreversible Hex publish.
- **Evidence shape:** "As proposed" — new inbound-scoped RELEASE-RECORD in the
  phase dir (Phase 38 shape, archived forms untouched), explicit pending markers
  for post-publish fields, fix the stale `MAINTAINING.md:256-257` path, and no
  new executable gate asserting live external state.
</specifics>

<deferred>
## Deferred Ideas

- **Actual `mailglass_inbound 1.0.0` Hex publish + live evidence capture** —
  deferred to a deliberate maintainer trigger after this phase. When it runs,
  flip reference-app pins to `~> 1.0`, capture live Hex/HexDocs/smoke evidence,
  and fill the 60-minute decision in the release record.
- The following remain explicitly out of scope for v1.6 unless a future
  milestone separately promotes them: matcher expansion, lifecycle callbacks,
  public replay API, provider extension API, synthetic inbound UI, `gen_smtp`
  listener, Cloudflare recipe docs, ecosystem integrations, demo app
  enhancements, screenshot workflow expansion, planning-directory cleanup, broad
  source hygiene, and any forced core/admin release line.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 73 scope.
</deferred>

---

*Phase: 73-inbound-1-0-publish-evidence*
*Context gathered: 2026-06-02*
