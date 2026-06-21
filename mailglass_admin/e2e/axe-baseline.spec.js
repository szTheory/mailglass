// e2e/axe-baseline.spec.js — WCAG 2.2 AA axe-violation baseline PRODUCER (RATCHET-03, D-05).
//
// CommonJS to match the playwright.config.cjs convention. This spec is a
// *producer*: it scans the three operator surfaces (deliveries, inbound,
// preview) across the three themes (light, dark, system) using
// @axe-core/playwright, folds each surface's [role=dialog] overlay violations
// into the surface that opened them (no 4th surface — D-03), and regenerates
// the `current` block of mailglass_admin/docs/axe-baseline.json.
//
// Counting decision (D-03): `total` counts FAILING NODES (sum of
// v.nodes.length), not violations.length. The `rules` map keys each rule-id to
// its node count, with deterministically sorted keys so the committed JSON diff
// is stable. The ExUnit comparator (axe_baseline_test.exs, D-04) derives the
// "inbound.dark: color-contrast 0 -> 2 (REGRESSION)" message shape from this.
//
// Screenshot-free, no pixel-diff. The axe devDep is test-only and never reaches
// priv/static/app.css (Zero-Node asset pipeline constraint).
//
// Regenerate the baseline:
//   cd mailglass_admin && PERSIST_AXE_BASELINE=1 npm run test:operator-browser -- axe-baseline.spec.js
// Without PERSIST_AXE_BASELINE the spec runs the scan and asserts the 9-cell
// shape WITHOUT rewriting the committed JSON (safe to run in CI).

const fs = require("fs");
const path = require("path");
const { test, expect } = require("@playwright/test");
const { AxeBuilder } = require("@axe-core/playwright");

const tenantId = "browser-tenant";
const baseURL =
  process.env.OPERATOR_BASE_URL ||
  `http://127.0.0.1:${process.env.BROWSER_SERVER_PORT || "4101"}`;

const SURFACES = ["deliveries", "inbound", "preview"];
const THEMES = ["light", "dark", "system"];

// The two scrim-backed surfaces whose [role=dialog] overlay violations fold
// into the surface (D-03). For these the overlay MUST open — a silent
// overlay-free scan under-counts violations and would corrupt the ratchet floor
// (WR-04). Preview has no overlay and is intentionally absent from this set.
const OVERLAY_REQUIRED_SURFACES = new Set(["deliveries", "inbound"]);

// docs/axe-baseline.json is a sibling of ui-baseline-scores.json — one level up
// from e2e/ into mailglass_admin/, then into docs/.
const BASELINE_PATH = path.join(__dirname, "..", "docs", "axe-baseline.json");

// The full WCAG 2.2 AA tag set (D-05). withTags restricts axe to rules carrying
// any listed tag; wcag22aa is present in the bundled axe-core 4.11.x rule pack.
const WCAG_22_AA_TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];

// ---------------------------------------------------------------------------
// Theme application (Pitfall 1):
//   light  -> ?theme=light  + emulateMedia colorScheme:light
//   dark   -> ?theme=dark   + emulateMedia colorScheme:dark
//   system -> NO theme query (app in system mode) + emulateMedia colorScheme:dark
// The system cell sets BOTH app-theme=system AND the OS preference to dark so the
// prefers-color-scheme media-query branch is genuinely exercised — otherwise the
// system cell degenerates into a duplicate of light.
// ---------------------------------------------------------------------------
function themeQuery(theme) {
  // Operator/Inbound read ?theme=; absence means :system. Preview honours the
  // same ?theme= convention; absence/`system` => follow prefers-color-scheme.
  if (theme === "light") return "theme=light";
  if (theme === "dark") return "theme=dark";
  return ""; // system: no explicit theme query
}

function emulatedColorScheme(theme) {
  // system exercises the dark media-query branch (Pitfall 1).
  if (theme === "light") return "light";
  return "dark";
}

async function applyTheme(page, theme) {
  await page.emulateMedia({ colorScheme: emulatedColorScheme(theme) });
}

// ---------------------------------------------------------------------------
// Auth + surface navigation (mirrors structural.spec.js / operator.spec.js).
// ---------------------------------------------------------------------------
async function loginOperator(page, returnTo) {
  await page.context().clearCookies();
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();
  const returnEncoded = encodeURIComponent(returnTo);
  await page.goto(
    `/ops/browser-login?tenant_id=${tenantId}&return_to=${returnEncoded}`
  );
  await expect(
    page.getByRole("heading", { name: "Operator overview", exact: true })
  ).toBeVisible();
}

function withTheme(pathWithQuery, theme) {
  const tq = themeQuery(theme);
  if (!tq) return pathWithQuery;
  return pathWithQuery.includes("?")
    ? `${pathWithQuery}&${tq}`
    : `${pathWithQuery}?${tq}`;
}

// Opens the Deliveries (operator) surface for the given theme, then opens its
// [role=dialog] replay modal so the overlay violations fold into this surface.
async function openDeliveries(page, theme) {
  await loginOperator(page, `/ops/mail?tenant_id=${tenantId}`);
  await page.goto(withTheme(`/ops/mail?tenant_id=${tenantId}&view=deliveries`, theme));
  await expect(
    page.getByRole("heading", { name: "Deliveries", exact: true, level: 1 })
  ).toBeVisible();
  // Open the replay [role=dialog] overlay (D-03 fold). REQUIRED for deliveries:
  // any failure throws and fails the producer rather than silently scanning the
  // surface overlay-free and under-counting violations (WR-04).
  return openOverlay(page, "deliveries", async () => {
    await page.getByTestId("operator-delivery-row").first().click();
    await expect(page.getByTestId("operator-detail-column")).toBeVisible();
    await page.getByTestId("operator-replay-open").click();
    const modal = page.getByTestId("operator-replay-modal");
    await expect(modal).toBeVisible();
    expect(await modal.getAttribute("role")).toBe("dialog");
  });
}

async function openInbound(page, theme) {
  await loginOperator(page, `/ops/mail?tenant_id=${tenantId}`);
  await page.goto(withTheme(`/ops/mail/inbound?tenant_id=${tenantId}`, theme));
  await expect(
    page.getByRole("heading", { name: "Inbound records", level: 1 })
  ).toBeVisible();
  // REQUIRED for inbound (see openDeliveries / WR-04): failure throws.
  return openOverlay(page, "inbound", async () => {
    const replayableRow = page
      .getByTestId("inbound-record-row")
      .filter({
        hasNot: page.locator(".badge-warning", { hasText: "No match" })
      })
      .first();
    await replayableRow.click();
    await page.waitForURL(/inbound_id=/);
    await page.getByTestId("inbound-replay-open").click();
    const modal = page.getByTestId("inbound-replay-modal");
    await expect(modal).toBeVisible();
    expect(await modal.getAttribute("role")).toBe("dialog");
  });
}

// Preview surface has no [role=dialog] overlay — it is scanned as-is. The
// overlay-fold rule is a no-op here (no 4th surface is ever created).
async function openPreview(page, theme) {
  await page.context().clearCookies();
  await page.goto(
    withTheme(
      `/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default`,
      theme
    )
  );
  await expect(page.getByTestId("preview-shell")).toBeVisible();
  // Preview legitimately has no overlay to fold (D-03) — there is nothing to
  // open, so report overlay_opened=false WITHOUT it being a failure.
  return false;
}

// Runs the opener for a scrim-backed surface. The overlay fold (D-03) is the
// whole point of the producer, so an opener failure on a REQUIRED surface
// throws and fails the producer rather than silently scanning the surface
// overlay-free and promoting an under-counted baseline (WR-04). Returns true
// when the overlay opened. `surface` MUST be in OVERLAY_REQUIRED_SURFACES — the
// previous unconditional `catch` that could mask a renamed testid or timing
// regression is gone.
async function openOverlay(page, surface, opener) {
  if (!OVERLAY_REQUIRED_SURFACES.has(surface)) {
    throw new Error(
      `openOverlay called for non-overlay surface "${surface}" — only ` +
        `${[...OVERLAY_REQUIRED_SURFACES].join(", ")} fold an overlay (D-03).`
    );
  }
  // No try/catch: a failure here (renamed testid, no replayable row, timing
  // regression) is a real producer failure, not a silently-skipped scan.
  await opener();
  return true;
}

// Returns whether the surface's overlay was opened so the producer can assert
// the two scrim-backed surfaces were never scanned overlay-free (WR-04).
async function openSurface(page, surface, theme) {
  if (surface === "deliveries") return openDeliveries(page, theme);
  if (surface === "inbound") return openInbound(page, theme);
  return openPreview(page, theme);
}

// ---------------------------------------------------------------------------
// Violation summarization (D-03): total = sum of node counts; rules = rule-id
// -> node count with deterministically sorted keys.
// ---------------------------------------------------------------------------
function summarizeViolations(violations) {
  const rules = {};
  let total = 0;
  for (const v of violations) {
    const n = v.nodes.length; // each failing node counts once
    rules[v.id] = (rules[v.id] || 0) + n;
    total += n;
  }
  const sortedRules = Object.fromEntries(
    Object.keys(rules)
      .sort()
      .map(k => [k, rules[k]])
  );
  return { total, rules: sortedRules };
}

async function scanSurface(page, surface, theme) {
  await applyTheme(page, theme);
  const overlayOpened = await openSurface(page, surface, theme);
  const results = await new AxeBuilder({ page }).withTags(WCAG_22_AA_TAGS).analyze();
  return { ...summarizeViolations(results.violations), overlay_opened: overlayOpened };
}

// ---------------------------------------------------------------------------
// Producer tests: one test per surface x theme cell (each does its own login +
// surface open + axe scan, so the 30s per-test timeout is comfortable). Cells
// accumulate into `measured`; afterAll assembles the 9-cell current block and
// (optionally) promotes it into the committed JSON. Always asserts cell shape.
// ---------------------------------------------------------------------------
const measured = {};

test.describe("axe WCAG 2.2 AA baseline producer (RATCHET-03)", () => {
  for (const surface of SURFACES) {
    for (const theme of THEMES) {
      test(`scan ${surface} / ${theme}`, async ({ page }) => {
        // A full-page axe-core analysis (plus overlay open on the scrim-backed
        // surfaces) can occasionally brush against the 30s per-test default under
        // CI/Docker load — the preview surface is the heaviest. Mark these scans
        // slow (3x timeout) so a slow-but-correct scan does not flake the gate.
        test.slow();
        const cell = await scanSurface(page, surface, theme);
        // Shape assertion — every cell is { total: number, rules: object }.
        expect(typeof cell.total, `${surface}.${theme} total`).toBe("number");
        expect(typeof cell.rules, `${surface}.${theme} rules`).toBe("object");
        // Fail closed (WR-04): the two scrim-backed surfaces MUST have opened
        // their overlay so the D-03 fold actually measured the overlay's
        // violations. An overlay-free scan under-counts and must never be
        // promoted. (openOverlay also throws on failure; this is the recorded,
        // assertable backstop.)
        if (OVERLAY_REQUIRED_SURFACES.has(surface)) {
          expect(
            cell.overlay_opened,
            `${surface}.${theme} must scan with its [role=dialog] overlay open`
          ).toBe(true);
        }
        measured[surface] = measured[surface] || {};
        measured[surface][theme] = cell;
      });
    }
  }

  test.afterAll(() => {
    if (!process.env.PERSIST_AXE_BASELINE) return;

    // All 9 cells must have been measured before we promote.
    for (const surface of SURFACES) {
      for (const theme of THEMES) {
        const cell = measured[surface] && measured[surface][theme];
        if (!cell) {
          throw new Error(
            `axe producer: missing measured cell ${surface}.${theme} — ` +
              "cannot promote a partial baseline"
          );
        }
      }
    }

    // Per-invocation unique run_id, decoupled from any milestone date so a
    // same-day re-run can never collide with the committed `prior.run_id`
    // (WR-01). The full ISO timestamp (colons/dots flattened to dashes) is
    // distinct down to the millisecond.
    const runId = `axe-${new Date().toISOString().replace(/[:.]/g, "-")}`;
    // Preserve the existing `prior` block — the real current->prior promotion is
    // plan 116-06's job, not this producer's.
    const existing = JSON.parse(fs.readFileSync(BASELINE_PATH, "utf8"));
    // Fail closed before writing: never emit a `current.run_id` equal to the
    // existing `prior.run_id`, which would make the ExUnit anti-vacuity guard
    // (axe_baseline_test.exs) fail on an otherwise-valid re-baseline.
    const priorRunId = existing.prior && existing.prior.run_id;
    if (runId === priorRunId) {
      throw new Error(
        `axe producer: generated run_id ${runId} collides with the committed ` +
          "prior.run_id — refusing to write a vacuous self-comparison baseline."
      );
    }
    // Persist only the committed cell shape ({ total, rules }). The
    // overlay_opened flag is an in-run fail-closed guard (asserted above), not
    // part of the committed baseline schema the ExUnit comparator reads — strip
    // it so the committed JSON stays minimal and byte-stable.
    const persistedViolations = {};
    for (const surface of SURFACES) {
      persistedViolations[surface] = {};
      for (const theme of THEMES) {
        const { total, rules } = measured[surface][theme];
        persistedViolations[surface][theme] = { total, rules };
      }
    }

    const next = {
      schema_version: 1,
      prior: existing.prior,
      current: { run_id: runId, violations: persistedViolations }
    };
    fs.writeFileSync(BASELINE_PATH, JSON.stringify(next, null, 2) + "\n");
  });
});
