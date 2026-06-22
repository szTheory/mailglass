# Milestones

## ✅ v1.13 Admin Design-System Stress Test & UX Uplift (v3) (Shipped: 2026-06-21)

**Phases completed:** 9 phases (109–117), 41 reqs — **mailglass 1.8.0 / mailglass_admin 1.8.0 / mailglass_inbound 1.5.0 live on Hex** (see `milestones/v1.13-MILESTONE-AUDIT.md`)

> Bottom-up fractal admin design-system uplift (foundation → primitives → forms → app shell →
> data display → composed groups → motion → WCAG 2.2 AA ratchet), then a linked-version MINOR
> release. Milestone audit `status: passed` — 41/41 requirements, 9/9 phases. Inbound re-pinned
> `{:mailglass, "== 1.8.0"}` (D-05/D-13). Two real admin fixes shipped in 1.8.0 (mobile back-button
> focus ring; preview frame-theme independence). Publish unblocked via a `mix deps.unlock --all`
> fix in publish-hex.yml (mailglass 1.8.0 → premailex ~> 1.0 vs the stale sibling lock).
> (Scope counted directly from phases 109–117 to avoid `milestone.complete` 999.x inflation.)

## v1.12 Adopter Onboarding & Day-2 Confidence (Shipped: 2026-06-17)

**Phases completed:** 5 phases (104–108), 11 plans — **mailglass 1.7.0 / mailglass_admin 1.7.0 / mailglass_inbound 1.4.0 live on Hex**

> Friction-removal + the first real linked-version Hex release since 1.6.2 (2026-06-12),
> NOT feature growth (D-23 convergence holds; D-28 actually cut the release vs. prepare-only).
> Moves the accumulated v1.7–v1.12 polish (admin IA/design-system, brand adoption, installer
> DX hardening, onboarding docs, inbound replay-modal a11y) from `main` to Hex adopters.
> Milestone audit `status: passed` — 13/13 requirements, 5/5 phases. Inbound exact-pin re-pinned
> to `{:mailglass, "== 1.7.0"}` (D-13 / REL-02).
>
> (Stats note: true v1.12 scope is 5 phases / 13 requirements, counted directly from phases
> 104–108 to avoid the known `milestone.complete` CLI inflation that also counts the 999.x backlog.)

**Key accomplishments:**

- **Phase 104 — Installer fail-closed + webhook doctor (INSTALL-01..04):** `mix mailglass.install` now fails closed (`Mix.raise`, non-zero exit) on an unmanaged `Plug.Parsers` conflict — closing the silent-production-401 footgun — with a `--force` escape hatch that inserts Mailglass's managed parser block above the existing one, plus a new `Mailglass.Installer.Doctor` / `mix mailglass.doctor` static three-state webhook-wiring scan. Tests-first (RED → GREEN).
- **Phase 105 — Onboarding docs (DOCS-01..04):** config-first README quickstart that copy-pastes and runs; `getting-started.md` ends on a `## Next steps` arc; new `guides/learning-path.md` first-week index; `migration-from-swoosh.md` opens with the value-prop pitch (and the stale `~> 0.3` pins bumped to `~> 1.6`). All docs-contract gated.
- **Phase 106 — Day-2 guides (OPS-01/02):** `guides/production-go-live-checklist.md` (deliverability/`mail.doctor`, webhook wiring, secrets, Oban sizing, per-tenant routing, suppression, telemetry) and `guides/errors-and-troubleshooting.md` (unified map of all ten error structs). Registered in `mix.exs` extras + Guides and docs-contract gated.
- **Phase 107 — Inbound replay-modal a11y parity (A11Y-01, ex-v1.11 WR-03):** operator-style focus-trap + Escape-to-close on the admin inbound replay modal, with a Playwright structural assertion and a bundle-clean gate.
- **Phase 108 — Release cut + milestone closeout (REL-01/02):** cut the real linked-version Hex release (1.7.0/1.7.0/1.4.0), re-pinned inbound + admin to `{:mailglass, "== 1.7.0"}`, confirmed Hex resolution + post-publish-smoke green, and archived the milestone. Pushing the never-CI'd v1.12 body before merging surfaced and fixed six genuine pre-flight CI regressions (format, installer-smoke-vs-fail-closed, dialyzer no_return, two ex_doc/docs.check doc issues, a responsive-split Playwright strict-mode locator).

**Release posture:** SHIPPED (D-28). Release commit `0411d485`; PR #84. Publish fan-out raced (one run per release event); all three packages verified live on Hex; post-publish-smoke green on re-dispatch.

**Follow-up (non-blocking):** harden `publish-hex.yml` `gate-ci-green` `isAdvisory()` so "Demo Browser Evidence" (a non-required lane) is classified advisory by name like the other advisory lanes — see `milestones/v1.12-MILESTONE-AUDIT.md`.

---

## v1.11 mailglass_admin Design-System Uplift (Shipped: 2026-06-16)

**Phases completed:** 10 phases (94-103), 42 plans

> Adopter-visible-quality milestone under the D-23 convergence rule (recorded as
> D-27) — NOT feature growth. Admin UI only (3 surfaces). **Release posture:
> prepare-only — no Hex release cut**; versions remain 1.6.2 / 1.6.2 / 1.3.1.
> Milestone audit `status: passed` — 34/34 requirements, 10/10 phases, 16/16
> integration paths, 7/7 E2E flows. Nyquist coverage `partial` (informational; all
> 10 VERIFICATION.md files passed).
>
> (Stats note: true v1.11 scope is 10 phases / 42 plans, counted directly from
> phases 94-103 to avoid the known `milestone.complete` CLI inflation that also
> counts the leftover v1.10 91-93 dirs and the 999.x backlog.)

**Key accomplishments:**

- **Phase 94 — Token re-baseline (TOKEN-01..05, RATCHET-03):** `mailglass_admin/assets/css/app.css` now consumes the canonical `brandbook/tokens.css` `--mg-*` two-tier tokens as the single source of truth — daisyUI theme vars reference `var(--mg-*)` with no duplicate hex literals; borders draw in the border role (not the accent), cards sit on `surface-raised`, and dark muted/error/primary-content were fixed to WCAG AA on their actual surface. A fail-closed ExUnit token-parity test breaks the build on any brand-token drift, and the tightened conformance + motion grep gates (`text-lg/xl/2xl`, arbitrary `tracking-[…]`, `ease-in`, layout-property transitions) landed FIRST so the swap couldn't regress silently.
- **Phase 95 — Idempotent quality ratchet v2 (RATCHET-01/02/04/05):** stood up a committed per-`component × pillar × theme` score baseline (meet-or-beat), one carried-forward `GAP-NN` register with stable IDs + run-ids and a sev≥3 anti-churn citation gate, a Playwright structural-assertion layer (focus rings, ARIA, ≥44px touch targets, font-weight ∈ {400,700}, accent-on-allowlist, reduced-motion), and an LLM-scored 18-cell PNG matrix writing `docs/ui-baseline-scores.json` (PNGs gitignored — no pixel-diff).
- **Phase 96 — Research dossier (RESEARCH-01..05):** five parallel-subagent dossiers under `.planning/research/v1.11/`, each ending in an adversarially-synthesized LOCKED DECISION block the build phases consumed without re-reading the body — 14 MOTION-LD, 9 IA-LD, 22 STATE-LD, 8 DARK-LD, and 16 COPY-LD locked decisions (Emil Kowalski motion, gov.uk IA, component-state matrices, dark-mode pitfalls, thoughtful-maintainer microcopy).
- **Phase 97 — Cross-surface component layer + gallery (COMP-01..03, GALLERY-01/02):** Level-1 uplift of every shared component (icon/logo/flash/badge/status_badge/shell/orientation_strip/nav_link/theme_toggle/tenant_chip) on-brand in both themes across the full locked interaction-state matrix, plus a dev-only component gallery LiveView (`/dev/mail/gallery`, dev live_session only) with stable `data-testid` cells feeding the ratchet's structural layer.
- **Phases 98-100 — Three-surface fractal uplift (GROUP/PAGE/RESP/FLOW/A11Y + GROUP-02/03 + PAGE-03):** Operator `/ops/mail` got master-detail IA, full happy/error/boundary seed coverage, and 390/768/1440 responsiveness (CR-01/02/03 nil-guards folded in); Inbound `/ops/mail/inbound` — the heaviest lift — gained a summary-backed overview tier and scannable token-clean RoutingTrace/EvidenceCard layouts that preserve PII/raw-payload boundaries by default; Preview `/dev/mail` gained full dark-mode chrome at parity (the previewed email keeps its own independent dark toggle). Every surface validated end-to-end against its real JTBD flow.
- **Phases 101-103 — Global passes + idempotent closeout (COPY-01, MOTION-01/02, CLOSE):** a global "thoughtful maintainer" microcopy pass (data-driven voice_test, "Oops" banned across all 3 surfaces); a motion uplift within the hard constraints (`--ease-symmetric` token, real enter/exit asymmetry via `phx-remove`, connection-state `.mg-skeleton`, CSS-only `@view-transition` PE, `prefers-reduced-motion` collapsing all motion); and a closeout that flipped all open GAP rows to fixed, armed the meet-or-beat ratchet (36/36 cells, 15 improved, zero regressions), confirmed all 6 CI gates green (56 + 236 + conformance + conformance-advisory + motion + 54/54 Playwright), and staged the linked-version release ceremony prepare-only.

**Release posture:** prepare-only — no Hex release cut by this milestone. One PENDING ceremony action documented: inbound exact-pin re-pin (`{:mailglass, "== <NEW_CORE_VERSION>"}`) after the Release Please PR merges, the only manual action before a real publish (D-13, deliberate divergence from the Phase 79 precedent because the target version is unknowable pre-PR).

**Accepted tech debt (non-blocking, advisory):** conformance grep forward-fragility + token_parity dark-theme regex fragility (Phase 94 WR-01/02); ease-in gate same-line pathological case, stale `structural.spec.js:943-944` comment, inbound replay modal missing operator-style focus-trap + Escape handler (highest-priority follow-up), `phx-remove` exit literal `duration-150` vs token (Phase 102 WR-01..04).

---

## v1.10 Brand Adoption (Shipped: 2026-06-13)

**Phases completed:** 3 phases (91-93), 9 plans

> Repo-artifact milestone — no Hex release cut by these commits (brand/docs use
> non-release-triggering types; HexDocs wiring ships with the next natural release).
> Milestone audit `status: passed` — 10/10 requirements, 3/3 phases, 5/5 integration
> seams, 4/4 E2E flows, Nyquist compliant on all phases.
>
> (Stats note: `milestone.complete` over-counted by including the dormant 999.x backlog
> dirs; true v1.10 scope is 3 phases / 9 plans, corrected here per the known CLI inflation.)

**Key accomplishments:**

- **Phase 91 — Folder adoption:** the v1.9 fable brand book became canonical `brandbook/` via `git mv`; the codex book was removed from the active tree (history preserves it at frozen baseline `09a84dd4`); CLAUDE.md + `mailglass_admin/docs/design-system.md` brand pointers reconciled to `brandbook/brand-book.md`; the v1.9 quality gate re-passed 9/9 on the new path with scoped-diff and release-safety evidence.
- **Phase 92 — README + social surfaces:** the root README now opens with `brandbook/examples/readme-header.svg` (sealed-flap header, GitHub light/dark safe); `brandbook/examples/og-card.png` (2400×1260, under GitHub's 1 MB limit) committed as the milestone's only binary, with Settings-UI-only social-preview upload steps documented.
- **Phase 92 — Admin wordmark:** the admin placeholder wordmark was replaced with a font-free, theme-safe sealed-flap `currentColor` lockup rendered inline by `Components.logo/1`; the rebuilt bundle passed the `verify.preview` bundle-clean gate with logo-asset regression tests banning live text/font dependencies.
- **Phase 93 — HexDocs wiring (HEXD-01/02):** ex_doc `logo:`/`favicon:` wired into all three packages' `docs/0`, pointing at canonical `brandbook/` assets via relative paths, with explicit `width`/`height` added to the SVGs for ex_doc 0.40.x; `mix docs` renders verified locally for all three (inert on hexdocs.pm until each package's next natural release).
- **Phase 93 — Release hardening (RELH-01):** belt-and-suspenders guard against the 1.6.x accidental-release pattern — `exclude-paths` on the root `.` package plus a new required `guard-release-trigger` PR lint (with an offline 6-case fixture) that fails any bump-triggering PR whose changes are entirely under brand/planning paths.
- **Phase 93 — Version reconciliation (RELH-02):** the 1.6.x aftermath reconciled to released truth **1.6.2 / 1.6.2 / 1.3.1** — in-repo manifest/`@version`/dep pins advanced from stale 1.6.1/1.6.1/1.3.0, remote 1.6.x tags fetched and kept, inbound exact-pin bumped via the `fix(inbound)` dance, CLAUDE.md + STATE.md corrected.

**Accepted follow-ups (documented, not blockers):** register `guard-release-trigger` as a required branch-protection check once a PR has exercised it (GitHub API can't register a check name until it has run once); HexDocs logo/favicon latency is by design (no forced release).

**Known deferred items at close:** 1 — `refresh-outbound-admin-ui-look-and-feel` todo (follow-up design-system milestone candidate, out of v1.10 scope). See STATE.md Deferred Items.

---

## v1.9 Brand Book Fable — A/B Brand System (Shipped: 2026-06-12)

**Phases completed:** 6 phases (85-90), 7 plans

**Milestone verification:** 22/22 requirements verified through per-phase
goal-backward verification (every phase has a `passed` VERIFICATION.md), the
Phase 90 consolidated gate re-proved every constraint on the final folder
state (9/9 checks, first run), and the maintainer approved the A/B
walkthrough with no punch list — the audit function was fulfilled by this
chain rather than a separate retroactive audit document.

**Key accomplishments:**

- Research-grounded differentiation brief: forensic codex audit (20 verified defect rows, 9 strengths, 6 killed false differentiators) locking 12 differentiators, the book outline, kill-list, and 21-file manifest before any artifact was authored.
- Contrast-proven two-tier token foundation (tokens.json + tokens.css) with complete 39-role light/dark parity, six computed fix hexes, four newly decided dark feedback backgrounds, and a 192-row script-computed WCAG matrix.
- The maintainer selected 4D "the sealed flap" through a four-round evidence-rendered tournament (8 options → 6 variants → color program → envelope-in-light exploration); the winner ships as a complete 8-asset, two-expression, mono-safe logo system with an OS-dark-adaptive favicon, now adopted under canonical `brandbook/assets/`.
- Self-contained fable brand book: a 77.7 KB file:// page whose theme toggle re-skins every specimen, whose 45-pair WCAG matrix is computed from the live tokens at runtime, with a fully keyboard-operable component gallery and a usage-rule-honoring logo system — plus the brand-book.md text master and README.
- All eight remaining manifest files shipped — landing + email HTML specimens, four portable SVGs, two copy libraries keyed to the seven domain nouns — slotted into the book's Specimens grid and proven with a three-iteration visual audit ending zero-defect.
- The complete fable brandbook folder (256 KB) passed all 9 scripted gate checks on the first run; maintainer sign-off: "I LOVE THE NEW BRANDBOOK."

**Deferred to a future milestone:** A/B winner adoption (folder rename,
README/HexDocs/social propagation, PNG export pipeline).

---

## v1.8 Brand System and Repo-Ready Brandbook (Closed superseded: 2026-06-11)

**Phases completed:** 3 of 5 phases (80-82), 5 plans; phases 83-84 superseded
(intent substantially satisfied out-of-band, residual gaps accepted)

**Closure mode:** Closed as **superseded**, not cleanly shipped. The milestone
audit verdict is `gaps_found` (`.planning/milestones/v1.8-MILESTONE-AUDIT.md`);
the gaps were accepted because an out-of-band session (frozen at commit
`09a84dd4`) completed the brandbook around the selected concept-07r identity,
and the v1.9 milestone ("Brand Book Fable — A/B Brand System") supersedes the
remaining work with a competing fable brand book, now adopted as canonical
`brandbook/`.

**Key accomplishments:**

- Row-addressable brand audit with required-surface stress matrix, stable BRAND-GAP register, and Phase 81-84 handoff gates
- Source brandbook and token guidance now preserve the Mailglass brand center, label draft assets honestly, and keep product admin UI mechanics separate from brandbook tokens.
- Three source-native logo directions and a criteria-based review artifact now give the maintainer visual evidence before final SVG approval.
- The maintainer checkpoint resolved out-of-band: concept-07r-no-idot-02-tighter-gap is the selected canonical identity.
- The selected 07r identity was promoted into the canonical asset set and the active brand docs were rewritten around it, out-of-band.

**Known gaps (accepted at close):**

- EXAMPLE-01/02, VOICE-01, REPO-01..03 never verified through GSD phases 83-84;
  partial out-of-band coverage only.

- `brandbook/assets/logo-primary.svg` wordmark is live `<text>` in macOS-only
  Avenir Next; degrades off-macOS.

- `brandbook/tokens.json` retains planning-language references to a contrast
  validation that never ran; dark tokens exist but are never demonstrated.

Known deferred items at close: 2 (pre-existing v1.7 bookkeeping artifacts for
Phase 76, already documented as resolved-downstream in STATE.md Deferred Items).

---

## v1.8 Brand System and Repo-Ready Brandbook (Active: 2026-06-05)

**Phases:** 5 phases (80-84)

**Goal:** Pressure-test the prompt-era Mailglass brand book and commit a
self-contained, source-control-friendly `brandbook/` system for docs, README
presentation, landing pages, tokens, SVG logos, visual specimens, voice, and
maintainer-safe marketing collateral.

**Scope:** This is a repo-artifact milestone, not product expansion. It does not
change public APIs, Hex package code, release workflows, or the implemented
admin design system.

**Status correction:** Commit `572f3eb2` created draft brandbook artifacts, but
v1.8 is not complete. The normal GSD discussion/phase/execute/verify lifecycle
still needs to run, starting at Phase 80. The draft logo SVGs are one direction,
not reviewed logo options.

**Target artifacts:**

- Static HTML brandbook
- Critical Markdown brand audit
- Concise source brand book
- JSON/CSS design tokens
- Editable SVG logo system
- SVG visual specimens
- Artifact hygiene and export policy

---

## v1.7 Admin UI — IA & Design-System Polish v2 (Shipped: 2026-06-05)

**Phases completed:** 6 phases (74-79), 22 plans

**Milestone audit:** `status: passed` — 19/19 requirements satisfied, 7/7 cross-phase seams wired, 3/3 E2E operator flows complete (`.planning/milestones/v1.7-MILESTONE-AUDIT.md`).

**Key accomplishments:**

- **Phase 74 evidence gate (zero code):** produced a scored gap register (surface × light/dark × 390/768/1440 × state), a frozen UI-SPEC with the canonical status-badge taxonomy table resolving the five-way `badge_class/1` conflict, a committed before-baseline screenshot set, and a full demo/e2e assertion-ripple inventory keyed to Phases 75-78.
- **Phase 75 IA & orientation:** generalized `Shell.orientation_strip/1` onto all three surfaces (Deliveries, Inbound, Preview) and added an in-library task-oriented Operator Overview landing at `/ops/mail/` via a `:overview` action in `OperatorLive.handle_params/3` — surfacing orphan-backlog / recent-failure / suppression-count health with **zero router-macro change**.
- **Phase 76 design-system hardening:** replaced all five divergent `badge_class/1` private copies with one unified `Components.status_badge/1` atom (icon+label, GAP-01..06 collapsed); migrated every admin HEEx file off the raw type/spacing scale onto v1 tokens; restructured the flat 2×2 support-card grid into a Tier 1/Tier 2 triage hierarchy; rebuilt+committed the bundle behind a self-contained `heroicons-inline.js` plugin.
- **Phase 77 motion polish:** fixed the `motion-reveal` re-fire bug with record-keyed detail-pane ids (GAP-19) so entrances fire once per selection not per patch; enforced `prefers-reduced-motion`, transform/opacity-only, ≤300ms discipline via a `check_motion_conformance.sh` grep gate.
- **Phase 78 seed expressiveness:** made every screen state reachable by a seeded URL — all 14 outbound statuses, every inbound outcome, each replay/reconcile state, orphan/failed-ingest rows, empty-tenant, and truncation-stress rows — with demo/e2e count assertions updated in the same commit and frozen baseline pins untouched.
- **Phase 79 closeout & release prep:** re-ran the full audit matrix vs the Phase 74 baseline, extended the Playwright suite to 10 green structural tests, passed conformance + bundle-clean gates, CLOSED all sev-4/5 gap-register rows (`79-GAP-CLOSEOUT.md`), and staged the linked-version release ceremony (inbound exact-pin `== 1.4.5` → `== 1.5.0`, prepare-only — pipeline owns publish).

**Known deferred items at close:** 2 (Phase 76 human-UAT/verification artifacts left in `partial`/`human_needed` state — both resolved downstream by Phases 77 + 79 and the milestone audit; see STATE.md Deferred Items).

---

## v1.6 Inbound 1.0 Release and Truth Lock (Shipped: 2026-06-02)

**Phases completed:** 3 phases, 6 plans, 5 tasks

**Key accomplishments:**

- Exact inbound 1.0.0 release-truth proof with blocker-only root docs/runbook corrections
- Inbound RELEASE-RECORD and RELEASE-CHECKLIST authored under prepare-and-stage posture: mix mailglass.publish.check (exit 0) and stability_contract test (6/0) captured; all post-publish fields (Hex, HexDocs, smoke, 60-minute) marked pending/not run

---

## v1.5 Demo Evidence and Click-Around Confidence (Shipped: 2026-06-02)

**Phases completed:** 4 phases, 8 plans, 14 tasks

**Key accomplishments:**

- Demo app now has executable local-vs-Hex dependency modes with current published constraints, and reference-host scope lock blocks rich-demo drift.
- Compose demo now enforces Phoenix health readiness and deterministic Playwright dependency setup for reliable click-around and browser evidence runs.
- Phase 67 now has executable deterministic reset proof plus a one-command `verify.phase67` lane and bounded `demo_browser_evidence.v1` wording for demo-only adoption evidence.
- Deterministic Northstar fixture corpus now seeds six outbound and four inbound named stories with replay lineage plus a repo-root quick gate.
- Preview mailers now expose deterministic, realistic scenario props and copy, and six scenario contracts are pinned at the public `Mailglass.Message` seam.
- Guided Northstar dashboard hub copy now points maintainers into real preview/outbound/inbound surfaces with explicit destructive reset wording and focused controller proof.
- Canonical demo docs now pin quickstart, click-path, seeded stories, reset semantics, and boundary claims with executable ExUnit contract checks.

---

## v1.4 Inbound Stability Lock (Shipped: 2026-06-01)

**Phases completed:** 4 phases, 12 plans, 22 tasks

**Key accomplishments:**

- Semantics-first inbound stability inventory with package-local docs-contract guards for stable, testing, internal, and deferred seams
- Inbound runtime seam metadata now reflects package-line truth (`0.1.0` and `0.2.0`) for compiled-doc contract proofing.
- Stable inbound structured-error and operator task modules now expose truthful `0.2.0` `since` metadata without widening direct invocation guarantees.
- Aligned inbound testing helper compiled-doc metadata to the truthful `0.2.0` package line across fixtures, ingress drivers, assertions, and mailbox case template.
- Inbound docs contract now fails closed on structured-error type-set drift, stale dep pins, and stable-surface over-claims while preserving explicit deferred-language mentions.
- Inbound now owns one authoritative compiled-doc stability proof lane, and root `verify.stability_contract` delegates to that package-owned support-contract alias.
- Canonical inbound adoption and compatibility flow now routes all stability guarantees through the inbound API stability inventory.
- Inbound operator, testing, and admin trust docs now explicitly lock command semantics, process-local assertion behavior, and replay trust boundaries without promoting internal APIs.
- Inbound adoption and compatibility wording is now executable: docs-contract and Tier 1 checks fail closed on canonical-path or compatibility-topology drift.
- Operator/testing/admin trust semantics are now fail-closed in both package-local docs-contract tests and root Tier 1 docs checks.
- Promoted `mailglass_inbound` to `1.0.0` with aligned source/manifest/README truth, operational release notes, and refreshed candidate-version publish evidence.

---

## v1.3 Adopter Trust Proof (Shipped: 2026-05-31)

**Phases completed:** 7 phases, 18 plans, 29 tasks

**Key accomplishments:**

- A committed maintained Phoenix host baseline now boots with Ecto wiring and a deterministic README-backed boot contract for HOST-01.
- HOST-02 is now mechanically enforced by locking the reference host to stable public seams and adding a fail-closed contract test for forbidden internal coupling.
- HOST-03 is now enforced by a committed scope contract plus deterministic required/forbidden token tests that prevent trust-proof drift into second-product expansion.
- Shipped one canonical `mix verify.reference_host.journey` entrypoint backed by a deterministic stage runner and fail-closed contract tests that preserve the Phase 57/58 trust boundary.
- Delivered deterministic fixture/checkpoint evidence for the trust runner, including `trust_runner.v1` schema output, stable ordering/hash semantics, and fail-closed checkpoint validation for downstream trust lanes.
- Postmark webhook evidence now proves the maintained reference-host route verifies before tenant, persistence, or execution work.
- No-match routing diagnosis evidence now completes the verify-first webhook plus operator troubleshooting trust checkpoint.
- Added `trust_lane_repo_head` and clean-baseline trust lanes, registered repo-head in branch-protection `REQUIRED_CHECKS`, and uploaded 90-day `trust_runner.v1` checkpoint artifacts for release evidence.
- Post-publish smoke now runs the published-version trust journey, guards fresh published installs against hackney regressions, and closes the smoke tracker automatically after green CI evidence.
- Maintainer release docs now require green trust evidence, describe hands-free publish accurately, and have deterministic tests preventing stale gate drift.
- Reference-host docs now explicitly state a usage-proof-only boundary and route stable guarantees to canonical api_stability inventories, with deterministic Phase 61 token checks enforced in the existing trust-runner contract test.
- Maintainer, webhook, troubleshooting, and operator trust-entry docs now route guarantee semantics to canonical stability inventories and executable contract lanes without widening public contract scope.
- Phase 61 trust-entry docs are now fail-closed under deterministic checker and ExUnit contract assertions for canonical stability routing, non-contract framing, and internals-as-guarantee overreach.
- Reference host release-line proof now resolves the v1.3 sibling packages from Hex and fails closed on stale Hex versions.

---

## v0.4 Roadmap: mailglass (Backfilled: 2026-05-29)

**Note:** Synthesized from archive snapshot by `/gsd-health --backfill`. Original completion date unknown.

---

## v0.3 : Webhook Coverage Complete (Backfilled: 2026-05-29)

**Note:** Synthesized from archive snapshot by `/gsd-health --backfill`. Original completion date unknown.

---

## v0.1 : Validation Release (Backfilled: 2026-05-29)

**Note:** Synthesized from archive snapshot by `/gsd-health --backfill`. Original completion date unknown.

---

## v0.2 Production-Credible Core (Shipped: 2026-04-28)

**Phases completed:** 5 phases, 29 plans, 41 tasks

**Key accomplishments:**

- Replace dead workflow_run-with-head_branch gate with on: release: types: [published] across both publish workflows, and add mix hex.info idempotency guard so workflow reruns cannot double-publish.
- Scan before execution:
- Bash-loop generalization:
- One-liner:
- AsyncAdapter behaviour (5th first-class behaviour) + CitextProbe extraction: eliminates Task.Supervisor sandbox ownership leaks and citext OID flakes; PR-A foundation landed; PR-B advisory lane added; PR-C gate flip awaiting szTheory soak sign-off
- Credo step
- 1. [Rule 3 - Refactoring] Internal usage of `Message.new` migrated to `Message.build`
- Phase:
- Enforced v0.2 API stability via a CI script scanning for Swoosh type leaks and documented the official freeze policy.
- Phase:
- 1. [Rule 3 - Blocker] Fixed struct compile deadlock between Message and Stream
- RFC 8058 unsubscribe config, lifecycle seam, and Phoenix.Token URL service with raw-secret rotation fallback
- Message-aware outbound compliance now injects RFC 8058 unsubscribe headers atomically and strict lint blocks any ad hoc header mutation path.
- Core RFC 8058 unsubscribe controller with standalone GET confirmation, replay-safe POST event append, and lifecycle-aware transaction composition
- Added the core router macro for RFC 8058 unsubscribe routes, backed by compile-time collision detection and route reflection tests.
- Read-only `mix mailglass.gen.unsubscribe` checklist with strict CLI parsing, canonical router instructions, and live route-preflight guidance
- StreamData coverage now proves unsubscribe secret rotation, expiry, URL hardening, stream header gating, and one-click POST replay convergence.
- Adopter-facing RFC 8058 setup, replay, rotation, and DKIM verification guidance with load-bearing docs smoke coverage
- Webhook ingest now projects complaint, unsubscribe, and hard-bounce events into idempotent suppression rows through a centralized helper and replay-convergence property coverage
- A targeted Credo check now fails when webhook ingest moves suppression writes ahead of the durable event append and projector path
- Soft-bounce escalation now has an Oban-backed worker, a direct evaluation helper, and the V03 storage slot needed for its event-window query
- Tenant-scoped suppression rebuild via a shared resync service and strict `mix mailglass.suppressions.resync` contract
- Structured suppression preflight errors with reason/source/expiry context plus explicit non-PII telemetry for blocked sends and webhook auto-adds
- Tenant-scoped suppression removal now rejects complaint and unsubscribe rows, complaint expiries are blocked before insert and in Postgres, and the webhook guide documents why complaint suppression outlives deletable source evidence.

---

## v0.5 Adoption Hardening (Shipped: 2026-05-03)

**Phases completed:** 4 phases, 7 plans

**Key accomplishments:**

- `mix mailglass.gen.mailable` generator implemented using Igniter for boilerplate-free scaffolding of mailable modules and HEEx templates.
- Comprehensive `Mailglass.TestAssertions` suite added, providing high-signal helpers for verifying outbound delivery, async webhook outcomes (delivered/bounced), and HTML content matching.
- Multi-bucket per-domain rate limiting implemented with `Mailglass.RateLimiter`, ensuring reputation protection with transactional bypass safety for critical emails.
- First-party Webhook Troubleshooting Guide and Upgrading Guide published to address common adopter friction points.
- Hardened `mix mailglass.install` with dry-run support, conflict detection, and improved dependency management.

---

## v0.6 Production Maturity (Shipped: 2026-05-05)

**Phases completed:** 3 phases, 9 plans

**Key accomplishments:**

- Replay and reconcile operator flows now resolve exact tenant-safe targets before adopter-owned destructive-action authorization and preserve audit cleanliness on stale-auth denials.
- Replay and repair wording is unified across the operator header, modal, timeline, and audit surfaces with explicit availability, outcome, and effect states.
- Reconcile now has one honest contract across Oban and Oban-less installs, including a truthful `mix mailglass.reconcile` fallback and aligned maintenance docs.
- Incident support now includes a canonical operator guide, a tenant-scoped support-summary read model, masked overview cues, and exemplar drilldowns into webhook and timeline evidence.
- Verification now relies on explicit root/admin support-contract authorities and three named required CI buckets, with only manual branch-protection verification and non-blocking boundary warnings accepted as closeout debt.

---

## v1.0 Stability Lock (Shipped: 2026-05-06)

**Phases completed:** 4 phases (35-38), 12 plans

**Key accomplishments:**

- Canonical core/admin stability inventories with explicit stable / internal / sibling-package-only classification, backed by compiled-doc and docs-surface verification.
- Explicit `1.x` compatibility/deprecation guide and a canonical latest-`0.x` to `1.0` upgrade path, both folded into existing repo-native verification lanes.
- Semantic Tier 1 drift checks, canonical testing and admin trust docs, and a repo-root `verify.stability_contract` proof entrypoint.
- Committed release-rehearsal artifacts (install + upgrade evidence), explicit release checklist/record, and Hex publish posture ready for live cutover.
- Accepted closeout debt: partial Nyquist bookkeeping for Phase 35, non-blocking boundary warnings in support-contract lanes, manual GitHub branch-protection verification.
- **Live publish: 2026-05-07** — `mailglass` 1.0.0, `mailglass_admin` 1.0.0, `mailglass_inbound` 0.1.0 published to Hex.pm via Phase 44.5 ceremony. See `.planning/phases/044.5-v1-0-1-1-release-ceremony/044.5-RELEASE-RECORD.md`.

---

## v1.1 Inbound Core Slice (Shipped: 2026-05-06)

**Phases completed:** 6 phases (39-44), 17 plans (12 product + 5 audit-gap closure)

**Key accomplishments:**

- Opened `mailglass_inbound` as the first sibling-package expansion past `v1.0` — canonical `%InboundMessage{}` struct, narrow router DSL, and mailbox behaviour with locked `:accept` / `:reject` / `:ignore` / `{:bounce, reason}` outcomes.
- First-party Postmark inbound ingress: verify-first plug, sealed normalization seam, and duplicate-safe persistence of both normalized canonical data and raw provider source for replay/debug truth.
- First-party SendGrid inbound ingress: post-commit mailbox execution, SendGrid-specific dedup, and honest replay over stored truth that never re-pretends a stored message is a fresh provider event.
- Operationally credible async execution: Oban-backed inbound worker plus bounded `Task.Supervisor` fallback when Oban is absent, canonical adoption / install / testing / operator docs, and repo-root release-proof coverage for the new sibling package.
- Execution verification chain restored end-to-end: Phase 43 recovered `39-VERIFICATION.md`, `40-VERIFICATION.md`, replaced the plan-check `41-VERIFICATION.md`, and added `41-VALIDATION.md`; Phase 44 recovered `42-VERIFICATION.md` and reconciled `REQUIREMENTS.md` / `STATE.md` / `ROADMAP.md` so the v1.1 audit re-ran with `status: passed`.
- Accepted carry-forward debt only — no new closeout debt introduced. Conductor-style dev UI, Mailgun / SES / `gen_smtp` relay ingress remain deliberately deferred so the first inbound milestone stays narrow and supportable.

---

## v1.2 Inbound Production Confidence (Shipped: 2026-05-26)

**Phases completed:** 10 phases (44.5, 45-50, 50.5, 50.7, 51), 42 plans

**Live publish: 2026-05-26** — `mailglass` 1.2.0, `mailglass_admin` 1.2.0, `mailglass_inbound` 0.2.0 published to Hex.pm via Phase 50.5 ceremony. See `.planning/phases/50.5-v1-2-release-ceremony/50.5-RELEASE-RECORD.md`. Sandbox install proof (`mix phx.new` + `~> 1.2` / `~> 0.2` deps + `mix compile --warnings-as-errors`) passed within the 60-minute window.

**Key accomplishments (9 REQ-ID categories):**

- **TELE** (Phase 45) — `MailglassInbound.Telemetry` span surface at `[:mailglass_inbound, :ingress|route|execution|persist, *]` with PII-free whitelisted metadata; per-tenant PubSub topics via `PubSub.Topics`; never-raise `MailglassInbound.MIME` parse seam over the optional `Mailglass.OptionalDeps.GenSmtp.decode/2` (returns `{:ok, _}` or `{:error, %MIMEError{}}`); StreamData 1000-replay convergence property guarantees idempotent execution.
- **MIME** (Phase 45) — Package-local `MailglassInbound.MIMEError` defexception; depth-guarded never-raise contract verified against malformed MIME.
- **MGUN** (Phase 46) — `MailglassInbound.Ingress.Providers.Mailgun` HMAC-SHA256 ingress with `SignatureError` no-recovery contract, dual body-mime/parsed mode, fingerprint dedupe via `unique_constraint`.
- **SESI** (Phase 46) — `MailglassInbound.Ingress.Providers.SES` SNS X.509 verification + S3 fetch (SSRF-guarded); `MailglassInbound.S3Fetcher` behaviour with `ExAwsS3` + `Fake` adapters; `MailglassInbound.OptionalDeps.ExAwsS3` gateway (first optional deps since the v1.0 STACK lock; `--no-optional-deps` lane intact); `S3FetchError` transient/permanent mapping.
- **ITEST** (Phase 47) — Hex-public Testing helpers under one ExDoc group: `MailboxCase` (ExUnit case template, `async: false`, ETS sandbox), `TestAssertions` (4 matcher styles + outcome + routing + negative), `Test.Ingress` (real persist+sync-execute driver), `Fixtures` (code-built Postmark/SendGrid/Mailgun/SES-SNS payloads incl. a signed SNS minted from an ephemeral RSA-2048 keypair through the real `CertCache` — no `.eml`/`.pem` files on disk).
- **IGEN** (Phase 47) — Three Igniter generators: `mix mailglass.gen.{mailbox,inbound_router,inbound_route}` (idempotent Sourceror-zipper edits, `--dry-run` free).
- **IADM** (Phase 48) — `MailglassAdmin.InboundLive` mountable admin UI at `/inbound` (list, detail, timeline, routing-trace views; tenant-gated replay confirm modal); `MailglassAdmin.OptionalDeps.MailglassInbound` runtime gateway so admin works with or without inbound.
- **IOPS** (Phase 49) — `mix mailglass.inbound.{doctor,replay,prune}` operator tasks (three-state exit codes; `--tenant` required for replay; typed "yes" confirmation for prune; `--dry-run` / `--yes` for cron); `MailglassInbound.RateLimiter` three-bucket limiter (tenant / sender_domain / recipient); `InboundMessage.Signals` suppression-flag-only contract at `.signals.suppression_flagged` (no auto-bounce, Deviation D-49-21).
- **IDOC** (Phase 50) — Six adopter guides under `mailglass_inbound/docs/`: install, testing, operator, mailgun, ses, routing-debug; extended `mix mailglass.docs.check` to enforce all six.
- **CLOSE** (Phases 44.5 and 51) — Live `v1.0`/`v1.1` publish closeout, Phase 35 Nyquist reconciliation, branch-protection repo truth, citext race fix, boundary cleanup, and explicit WR-01..WR-06 dispositions.

**Known deferred items at close:** 1 (see `STATE.md` Deferred Items)

**Residual follow-up (non-blocking):**

- release-please-action v5 + `GITHUB_TOKEN` anti-recursion still forces `workflow_dispatch` for downstream publish fanout.
- Admin publish still needs an explicit Hex-index wait on inbound when sibling packages release in parallel.
- `SEED-003-ecosystem-integrations` remains dormant for a future milestone rather than being treated as partial `v1.2` scope.
