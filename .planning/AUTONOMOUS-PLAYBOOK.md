# Autonomous Playbook — discuss, verify, CI

Standing owner instructions for every GSD run in this repo, including `/gsd-autonomous`. Subagents and orchestrators read this through the pointer in `CLAUDE.md`. It extends, and never overrides, `CLAUDE.md` § Decision Policy and § Verification Policy (D-52) and `.planning/METHODOLOGY.md`.

Recorded 2026-11-15; verification rules reaffirmed 2026-11-17. Do not re-ask the owner about anything below.

## 1. Discuss phases: fan out, synthesize, decide

Applies to discuss, smart-discuss, spec and any gray-area decision. Do not ask the owner except for the genuine strategic forks listed in CLAUDE.md § Decision Policy (ship/no-ship, license, lock-in that is expensive to reverse, brand/visual identity, public-API shape the project's own goals decide).

1. **Fan out with subagents, for context efficiency.** One subagent per decision area, in parallel. Keep fanning out until returns diminish: enumerate every relevant point, then synthesize one coherent set of recommendations. Do not stop at the first pass.
2. **Per decision point, cover breadth and depth through every relevant stakeholder lens.** Pick the ones that apply: security, product, design/UX, software architecture, DevOps/release, distributed systems, rendering and 2D/3D graphics where relevant, and language/framework specialists (Elixir/OTP, Phoenix/LiveView, Ecto/Postgres, TypeScript/Node, CSS, and so on). For each: pros, cons, tradeoffs, examples, patterns, antipatterns, best practices, footguns, lessons learned.
3. **Look outside the repo.** Other products and ecosystems (cross-language is fine) when helpful. Prefer reputable primary sources (specs, official docs, vendor docs, source code) over blog summaries. Think for yourself; quality of information beats quantity.
4. **Run an adversarial pass** before synthesizing: try to break each candidate recommendation.
5. **Synthesize one-shot recommendations** that reinforce each other and the locked vision (`PROJECT.md`, `prompts/`). Then proceed with them. Record each decision and its rationale in CONTEXT.md (or the plan, or the commit). Never drop a decision silently.
6. **Dependencies: a little copying beats a new dependency.** A truly needed dep is fine. Smaller, flatter dependency trees are more secure and avoid pulling in abstractions we do not need.
7. **UI/UX phases:** apply existing patterns, principle of least surprise, conventions, elegant design, and the brand book. Do not get lost in tangents. The goal is a coherent recommendation set, followed automatically.
8. **Persist multi-pass research** under `.planning/research/` so it is not regenerated.

## 2. Verify phases: shift left, zero human UAT

Canonical rules: `.planning/METHODOLOGY.md` § "Shift-Left Verification by Default" and `CLAUDE.md` § Verification Policy. In short:

1. **Automate the world.** Integration, e2e, smoke and seam tests, with a DevOps mindset. Shift onto CI only when the recurring value justifies it. Throwaway local verification is fine and does not need to live in CI.
2. **Target zero owner verification.** Close UAT rows as `source: automated` with the covering test. Never present a "reply yes if this matches" checkpoint for anything a machine can observe.
3. **Owner hand-off is limited to** ship/no-ship, brand/visual identity, secrets/credentials/interactive login, the `hex-publish` approval and physical devices, each with a full-URL runbook.
4. **Take automation as far as you can without the owner, but only where it gives useful feedback.** Do not paint yourself into a corner, and do not build verification that cannot tell you anything.
5. **Do not loop back here.** If a verification question is already settled by this file, METHODOLOGY or a recorded decision, apply it and move on.
6. **Reconcile verifier hand-offs before stopping.** `human_needed` is a missing-evidence signal, not permission to return a deterministic test to the owner. Check the current candidate and existing tests first; add the cheapest useful automation for machine-observable behavior, record it as `source: automated`, and clear UAT with the shared GSD predicate. If a live service does not yet contain the candidate, verify source/package/generated-output contracts and keep the live limitation explicit; never publish or ask the owner to publish just to satisfy UAT. Add a read-only post-publish check only when it has recurring value.
7. **Keep human checks irreducible and exact.** Reserve owner UAT for genuine subjective identity/product judgment, legal/policy or ship authority, physical devices, secrets/interactive authentication, or unavailable external state that materially changes the decision. Give the owner one precise action and its consequence; never ask them to inspect deterministic receipts or repeat automated checks.

## 3. Cheap checks first, then the long suite

Before any long test, build or process, run the cheap consistency checks first (format check, bundle `--check`, scoped contract tests, grep/lint guards). When something is slow or stuck, step back and look for the bottleneck or low-hanging fruit instead of retrying the same thing.

## 4. CI and release: look for cheap speed wins every time

Whenever a CI run is in progress or has just finished, and whenever a release step runs, check for low-hanging fruit that cuts iteration time, GitHub Actions minutes or cost: redundant jobs, missing caches, serial steps that could run in parallel, over-broad path triggers, avoidable full rebuilds. Do this without lowering the quality of the gate. File findings as a todo or fix them in a separate `ci:` commit, never bundled into feature work. Required lanes stay merge-blocking; advisory lanes stay advisory.

Before waiting on hosted CI, run cheap local consistency checks and the existing project gate first. Use `act` when it is already available and a selected job adds useful coverage that can be reproduced faithfully and within the plan's authorized effects and limits; select only that job instead of replaying unrelated lanes. Check all job side effects too: dependency or browser downloads, external services, image pulls, and Docker use must be authorized, attributable, and covered by the resource lifecycle in §5. Treat `act` as a fast local diagnostic, not as a replacement for required GitHub-hosted checks, branch protection, run-bound artifacts, or release evidence. Do not install `act`, pull or build runner images, expose production secrets, or invoke publish/release/deploy jobs just to reproduce CI. Retain shared images and caches. Record unsupported GitHub-specific behavior or other fidelity gaps, then use the hosted required checks for final acceptance.

