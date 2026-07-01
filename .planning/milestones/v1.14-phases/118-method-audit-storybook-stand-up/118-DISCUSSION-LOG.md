# Phase 118: Method, Audit & Storybook stand-up - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-26
**Phase:** 118-method-audit-storybook-stand-up
**Mode:** assumptions
**Areas analyzed:** Persona-Critic Harness, Defect Register, phoenix_storybook Integration, New Judgment Gates, Ratchet Floor Inheritance

## Assumptions Presented

### Persona-Critic Harness (METHOD-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Agent-orchestrated Playwright walkthroughs vs running `make demo`; reuse existing e2e infra | Confident | `reference/demo_app/assets/playwright.config.cjs`, `make demo-e2e`, `mailglass_admin/e2e/*.spec.js` |
| Screenshots → gitignored `.planning/research/v1.14/.cache/screenshots/`; evidence not pixel-baseline | Confident | `.planning/research/.cache/` already gitignored; pixel-diff out of scope (REQUIREMENTS.md) |
| Personas already seeded by `make demo`; no new seed path | Confident | `reference/demo_app/lib/mailglass_demo/demo_data.ex` `reset!/0` → `Personas.seed!`; `reference/persona_spec/personas.ex` (helios-void absent) |

### Defect Register (METHOD-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Hit-list at `.planning/research/v1.14/DEFECT-REGISTER.md` (milestone scope) | Likely | Consumed by phases 119-123; sibling to MILESTONE-SEED.md / STRESS-TEST-PROMPT.md |

### phoenix_storybook Integration (STORY-01, STORY-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Added to demo app `only: :dev`, NOT shipped `mailglass_admin/lib/` | Confident | `mailglass_admin/mix.exs` `:files` ships `lib` glob; demo already mounts admin via `import MailglassAdmin.Router` |
| Sandbox CSS via `css_path` → existing served `/mail/css-<md5>` bundle; no Node build of our CSS; omit `js_path` | Likely→Confident (post-research) | phoenix_storybook sandboxing docs: `css_path` is a remote URL `<link>`, optional, served by your own endpoint |
| Theme bridge: storybook applies CSS class, components use `data-theme` — bridge via story root, never edit app.css | Likely | phoenix_storybook color_modes docs (class-not-attribute); `operator/shell.ex:219` `data-theme` |
| v1.2 supports Phoenix 1.8 / LV 1.1 | Confident (research) | hex v1.2.0 (2026-06-11) CHANGELOG aligns to Phoenix 1.8 / Tailwind v4 |

### New Judgment Gates (METHOD-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Playwright rendered-DOM assertions (aria-current; no-nav-duplication testid), not greps | Likely | `operator_live.ex:349` hardcoded literal; `structural.spec.js` keys off `[aria-current='page']`; `data-testid="operator-overview-nav"` (`operator_live.ex:416`) |
| Drafted pending/xfail in 118; green in 119; armed at 123 | Likely | Bug live until 119; roadmap 123 SC3 owns gate-arming |

### Ratchet Floor Inheritance (METHOD-02 SC4)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 118 = verification-run only; no re-score, no arming | Confident | Locked "NO pillar re-score in 118"; roadmap 123 owns re-score + arm |
| Floor = 26 conformance gates + 54-cell aesthetic + 9-cell axe + 24-item Bucket-A + persona drift-guard | Confident | `check-conformance.sh`, `ratchet_baseline_test`, `axe_baseline_test`, `bucket_a_coverage_test.exs`, `persona_drift_guard_test.exs` |

## Corrections Made

No corrections — both fork questions confirmed the recommended (first) option.

### Gate timing
- **Question:** METHOD-02 says gates "armed, green" in 118, but the target bug isn't fixed until 119.
- **User choice:** Draft pending in 118, arm green at 119/123. (Do NOT pull the 119 nav fix into 118.)
- **Reason:** Avoids baking the bug into a weakened gate; respects phase boundaries.

### Defect register location
- **Question:** Where does the durable hit-list live?
- **User choice:** `.planning/research/v1.14/DEFECT-REGISTER.md` (milestone scope).
- **Reason:** Phases 119-123 consume it without reaching into an archived phase dir.

## External Research

- **phoenix_storybook sandbox-CSS API:** `css_path` is an optional top-level option in the
  `use PhoenixStorybook` config module — a remote URL string injected as a `<link>` into the
  sandbox iframe, served by your own endpoint. It can point at an arbitrary already-served static
  route (e.g. `/mail/css-<md5>`). Loaded into the `app` CSS layer so it wins over explorer styles.
  Source: https://phoenix-storybook.hexdocs.pm/sandboxing.html
- **Node/esbuild:** NOT required for our component CSS. The explorer UI ships prebuilt in the hex
  package, served by `storybook_assets()`. `js_path` is optional (only for story-specific hooks) —
  omit it ⇒ no esbuild watcher. `mix phx.gen.storybook` scaffolds a watcher path to avoid.
  Source: https://phoenix-storybook.hexdocs.pm/setup.html
- **Theming:** storybook applies CSS **classes** to the sandbox (`color_mode` dark/light classes
  or `themes:` keys), NOT `data-theme` attributes — bridge required (D-08).
  Source: https://phoenix-storybook.hexdocs.pm/color_modes.html
- **Version:** latest v1.2.0 (2026-06-11); Phoenix 1.8 / LV 1.1 supported; v1.0 rename
  Story→Variation, files `*.story.exs`.
  Source: https://hex.pm/packages/phoenix_storybook
