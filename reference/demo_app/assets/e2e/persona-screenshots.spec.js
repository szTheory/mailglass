// persona-screenshots.spec.js — METHOD-01 persona-critic SCREENSHOT SEAM.
//
// This is an EVIDENCE PRODUCER, not a new harness and NOT a pixel-diff baseline
// (D-01 / D-02). It REUSES the existing @playwright/test runner + the demo's
// playwright.config.cjs (baseURL/DEMO_BASE_URL/PORT resolution) — the same infra
// demo.spec.js / cohort.spec.js drive. Every shot lands ONLY in the git-ignored
// cache `.planning/research/v1.14/.cache/screenshots/` (verified ignored before
// the first run via Plan-01 Task 1's `.gitignore:45 /.planning/research/**/.cache/`).
//
// ── Login path (Pitfall 5 resolution) ────────────────────────────────────────
// The operator surfaces (/ops/mail*) require an authenticated session. Against the
// running `make demo` (MIX_ENV=dev) we use the HUMAN entry `/demo/login?return_to=…`
// — the exact path cohort.spec.js uses against the demo — NOT the `/ops/browser-*`
// helper routes (those are an operator-test affordance; the demo cohort specs
// authenticate via /demo/login, so this seam matches that proven path). The
// dev-only review surfaces (/dev/storybook, /dev/mail, /dev/mail/gallery) are NOT
// session-gated, so they are shot directly without a login round-trip.
//
// ── Base URL (Pitfall 4 resolution) ──────────────────────────────────────────
// playwright.config.cjs already honors DEMO_BASE_URL (in-network `make demo-e2e`,
// e.g. http://demo:4015) and PORT (host run, http://127.0.0.1:${PORT:-4015}).
// This seam adds NO base-URL logic of its own — `page.goto` uses the config baseURL.
//
// ── Personas (D-03) ──────────────────────────────────────────────────────────
// Seeded by `make demo` (DemoData.reset! -> MailglassDemo.Personas.seed!). NO new
// seed path is added (would risk the persona drift-guard). Each test re-seeds via
// the SAME `POST /demo/evidence/reset` seam demo.spec.js uses, then routes via
// `/ops/mail?tenant_id=<persona>`:
//   * northstar     — many / high-count / error
//   * fjordline-aps — one / long-ID / non-ASCII / null
//   * helios-void   — zero-data (realized by absence; direct-URL only — it is not
//                     in the >=2-tenant switcher, reached by explicit tenant_id)
//
// ── Theme (reuses structural.spec.js applyThemeEmulation pattern) ────────────
//   light  -> ?theme=light
//   dark   -> ?theme=dark
//   system -> NO ?theme= param + emulateMedia({colorScheme:'dark'}) so the
//             prefers-color-scheme branch is genuinely exercised.
//
// ── Sampling (D-04 matrix, prioritized — NOT the ~1,620-cell Cartesian sweep) ─
// Anchor cells (always shot): each surface × the three personas × {375, 1440} ×
// {light, dark} — the 4-corner viewport/theme square that catches most layout/
// contrast defects. Targeted state cells where a persona NATURALLY produces them
// (helios-void => empty/zero; northstar => error/high-count; fjordline-aps =>
// long-ID/non-ASCII/null) are inherent in the persona routing. Spot-checks: the
// system theme + 320 + 768 are added on the #1/#2 surfaces only (App-shell+Health,
// Deliveries). The register cites the exact cell per finding, so coverage is auditable.

const { test } = require("@playwright/test");
const path = require("path");
const fs = require("fs");

// Git-ignored evidence cache (D-02). Resolved relative to this spec file:
// assets/e2e -> ../../../../ is the repo root.
const OUT = path.resolve(
  __dirname,
  "../../../../.planning/research/v1.14/.cache/screenshots"
);

const PERSONAS = ["northstar", "fjordline-aps", "helios-void"];

// The biggest-impact-first surfaces. `kind` drives routing + whether a session is
// required. Operator surfaces are session-gated (login via /demo/login); the
// dev-only review surfaces are open. `priority` tags the #1/#2 surfaces that get
// the system-theme + 320 + 768 spot-check.
const SURFACES = [
  { id: "overview", kind: "operator", suffix: "", priority: 1 },
  { id: "deliveries", kind: "operator", suffix: "&view=deliveries", priority: 2 },
  { id: "inbound", kind: "operator-inbound", suffix: "", priority: 3 },
  { id: "preview", kind: "dev-open", route: "/dev/mail", priority: 3 },
  { id: "gallery", kind: "dev-open", route: "/dev/mail/gallery", priority: 4 },
  { id: "storybook", kind: "dev-open", route: "/dev/storybook", priority: 4 }
];

// Anchor viewport/theme square (always) + the #1/#2 spot-check extension.
const ANCHOR_VIEWPORTS = [375, 1440];
const ANCHOR_THEMES = ["light", "dark"];
const SPOTCHECK_VIEWPORTS = [320, 768]; // priority<=2 surfaces only
const SPOTCHECK_THEME = "system"; // priority<=2 surfaces only

function themeQuery(theme) {
  // system == absence of an explicit theme query value (shell.ex theme contract).
  return theme === "system" ? "" : `theme=${theme}`;
}

// emulateMedia MUST precede navigation so the system branch resolves to dark.
async function applyThemeEmulation(page, theme) {
  if (theme === "system") {
    await page.emulateMedia({ colorScheme: "dark" });
  } else {
    await page.emulateMedia({ colorScheme: null });
  }
}

// Build the per-cell list of {viewport, theme} pairs for a surface, honoring the
// prioritized sample: the anchor square for every surface, plus the spot-check
// cells for the #1/#2 surfaces.
function cellsFor(surface) {
  const cells = [];
  for (const vw of ANCHOR_VIEWPORTS)
    for (const theme of ANCHOR_THEMES) cells.push({ vw, theme });
  if (surface.priority <= 2) {
    for (const vw of SPOTCHECK_VIEWPORTS)
      cells.push({ vw, theme: SPOTCHECK_THEME });
    // one system shot at a representative wide width on the top surfaces
    cells.push({ vw: 1440, theme: SPOTCHECK_THEME });
  }
  return cells;
}

// Resolve the URL for a (surface, persona) under the operator vs dev-open split.
function urlFor(surface, persona, theme) {
  const tq = themeQuery(theme);
  if (surface.kind === "operator") {
    const q = [`tenant_id=${persona}`, surface.suffix.replace(/^&/, ""), tq]
      .filter(Boolean)
      .join("&");
    return `/ops/mail?${q}`;
  }
  if (surface.kind === "operator-inbound") {
    const q = [`tenant_id=${persona}`, tq].filter(Boolean).join("&");
    return `/ops/mail/inbound?${q}`;
  }
  // dev-open surfaces are persona-independent; theme still threaded where honored.
  return tq ? `${surface.route}?${tq}` : surface.route;
}

// Authenticate the operator session via the human /demo/login entry (Pitfall 5),
// then land on the target operator URL. return_to is encoded so the nested query
// survives the login redirect (the cohort.spec.js / demo.spec.js convention).
async function openOperator(page, targetUrl) {
  const returnTo = encodeURIComponent(targetUrl);
  await page.goto(`/demo/login?return_to=${returnTo}`);
  // A second explicit nav guarantees we are on the exact target (login may land
  // on a normalized path); robust to LiveView connection timing.
  await page.goto(targetUrl);
}

test.beforeAll(async () => {
  fs.mkdirSync(OUT, { recursive: true });
});

test.describe("persona-critic screenshot seam (METHOD-01 evidence producer)", () => {
  // Re-seed the persona cohort before each shot via the SAME destructive reset
  // seam demo.spec.js uses (DemoData.reset! -> Personas.seed!). Kept serial by the
  // shared playwright.config.cjs (no fullyParallel) — the reset races a shared DB.
  test.beforeEach(async ({ request }) => {
    const response = await request.post("/demo/evidence/reset", {
      headers: {
        "x-mailglass-demo-reset-token":
          process.env.DEMO_EVIDENCE_RESET_TOKEN || ""
      }
    });
    if (!response.ok()) {
      throw new Error(
        `demo reset failed (${response.status()}); is \`make demo\` up and DEMO_EVIDENCE_RESET_TOKEN set?`
      );
    }
  });

  for (const surface of SURFACES) {
    // dev-open review surfaces are persona-independent — shoot them once per cell
    // (persona "any") rather than ×3, to keep the sample tractable.
    const personasForSurface =
      surface.kind === "dev-open" ? ["any"] : PERSONAS;

    for (const persona of personasForSurface) {
      for (const { vw, theme } of cellsFor(surface)) {
        const cell = `${surface.id}-${persona}-${vw}-${theme}`;
        test(`shot ${cell}`, async ({ page }) => {
          await page.setViewportSize({ width: vw, height: 900 });
          await applyThemeEmulation(page, theme);

          const url = urlFor(surface, persona, theme);
          if (surface.kind === "operator" || surface.kind === "operator-inbound") {
            await openOperator(page, url);
          } else {
            await page.goto(url);
          }

          // Give LiveView a beat to connect + paint before the capture.
          await page.waitForLoadState("networkidle").catch(() => {});

          await page.screenshot({
            path: path.join(OUT, `${cell}.png`),
            fullPage: true
          });
        });
      }
    }
  }
});
