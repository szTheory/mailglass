# Deferred Items — Phase 122

## Plan 122-01

- **[Out of scope] Pre-existing warnings-as-errors failure in `operator_live.ex:505`**
  - `mix compile --warnings-as-errors` fails on `attribute "selected_delivery" ... must be a :map, got: nil` in `MailglassAdmin.Operator.DeliveriesList.deliveries_list/1`.
  - Pre-existing in committed code (HEAD, introduced phase 120 commit e59a6e5f), NOT caused by this plan. `preview_live.ex` itself compiles clean.
  - Not fixed here per scope boundary (only auto-fix issues directly caused by this task's changes).

## Plan 122-03

- **[D-17 fallback → Phase 123] `preview` persona re-shoot deferred — demo boot needs a baseline-drifting `mix deps.get`**
  - The single `preview` dev-open cell (`reference/demo_app/assets/e2e/persona-screenshots.spec.js:70`) expands to exactly 4 cells (`preview-any-{375,1440}-{light,dark}`, persona-independent) and is **unedited** (re-run target only; adding/removing any cell fires the persona drift-guard, D-12).
  - The persona producer drives the demo via Docker (`compose.demo.yml` `demo`/`demo_e2e`); the `demo` container CMD runs a plain `mix deps.get && mix ecto.setup && mix phx.server` against the host-mounted workspace lock. A fresh resolve drifts the FROZEN deterministic demo baseline: `plug 1.19.2 => 1.20.1`, `plug_cowboy 2.8.1 => 2.9.0`, `premailex 0.3.20 => 1.0.0 (major)`, `swoosh 1.26.1 => 1.26.2`. (Verified via `mix deps.get --check-locked` — EXIT 0 but the resolve reports those `=>` bumps; `--check-locked` refuses to write, but the container CMD's plain `mix deps.get` would write them.)
  - Per the locked D-12 + D-17 fallback (mirroring 121-04's operator-inbound deferral): the actual shoot is **deferred to Phase 123**, when the demo env is brought up under a coordinated baseline bump. No fabricated run; no drifted baseline/lock this phase. `reference/demo_app/mix.lock` verified byte-clean.
  - Phase-123 follow-up: re-run `npx playwright test e2e/persona-screenshots.spec.js --grep "shot preview-"` against an up `make demo` (with `DEMO_EVIDENCE_RESET_TOKEN`) to capture the only-forward `preview` visual delta across the 4 anchor cells.
