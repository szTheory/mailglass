const { test, expect, chromium } = require("@playwright/test");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { execFileSync } = require("child_process");
const { resolveEvidenceOutputPath } = require("../scripts/evidence-output-path.cjs");

const OWNER = '[data-theme-owner="quick-view-story"]';
const REPO_ROOT = path.resolve(__dirname, "../../../../");
const EVIDENCE_DIR = resolveEvidenceOutputPath(process.env.PHASE174_EVIDENCE_DIR ||
  path.resolve(__dirname, "../../tmp/demo_browser_evidence/phase174"));
const FIDELITY_PATH = path.join(EVIDENCE_DIR, "fidelity.json");
const BASE_URL = process.env.DEMO_BASE_URL || `http://127.0.0.1:${process.env.PORT || "4015"}`;
const FONT_FILES = [
  "inter-400.woff2",
  "inter-700.woff2",
  "inter-tight-400.woff2",
  "inter-tight-700.woff2",
  "ibm-plex-mono-400.woff2",
  "ibm-plex-mono-700.woff2"
];
const VIEWPORT_WIDTHS = [320, 375, 768, 1280, 1440];
const STORY_CASES = [
  {
    area: "delivery",
    path: "/dev/storybook/quick_views/delivery?variation_id=northstar_normal",
    variant: "northstar_normal"
  },
  {
    area: "inbound",
    path: "/dev/storybook/quick_views/inbound?variation_id=northstar_normal",
    variant: "northstar_normal"
  }
];
const PHASE175_EVIDENCE_DIR = resolveEvidenceOutputPath(process.env.PHASE175_EVIDENCE_DIR ||
  path.resolve(__dirname, "../../tmp/demo_browser_evidence/phase175"));
const PHASE175_FIDELITY_PATH = path.join(PHASE175_EVIDENCE_DIR, "fidelity.json");
const PHASE175_SOURCE_FILES = [
  "reference/persona_spec/quick_view_scenarios.ex",
  "reference/persona_spec/quick_view_scenarios.json",
  "reference/demo_app/storybook/delivery_investigation.story.exs",
  "reference/demo_app/assets/e2e/delivery-investigation.spec.js",
  "reference/demo_app/assets/e2e/storybook-fidelity.spec.js",
  "mailglass_admin/e2e/storybook-axe.spec.js",
  "mailglass_admin/e2e/support/storybook-axe.cjs",
  "mailglass_admin/e2e/support/storybook-axe-supplement.cjs",
  "mailglass_admin/e2e/flows.spec.js",
  "mailglass_admin/e2e/phase175-inbound.spec.js",
  "mailglass_admin/assets/css/app.css",
  "mailglass_admin/priv/static/app.css",
  "mailglass_admin/priv/static/hooks.js",
  "mailglass_admin/lib/mailglass_admin/operator/detail_header.ex",
  "mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex",
  "mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex",
  "mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex",
  ...FONT_FILES.map(filename => `mailglass_admin/priv/static/fonts/${filename}`)
];

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

function md5(bytes) {
  return crypto.createHash("md5").update(bytes).digest("hex");
}

function sourceIdentity() {
  const revision =
    process.env.DEMO_CANDIDATE_REVISION ||
    execFileSync("git", ["rev-parse", "HEAD"], { cwd: REPO_ROOT, encoding: "utf8" }).trim();
  const status = execFileSync("git", ["status", "--porcelain"], {
    cwd: REPO_ROOT,
    encoding: "utf8"
  });
  return {
    revision,
    dirty: status.length > 0,
    dirtyStatusSha256: sha256(Buffer.from(status))
  };
}

function phase175SourceIdentity() {
  const revision = execFileSync("git", ["rev-parse", "HEAD"], { cwd: REPO_ROOT, encoding: "utf8" }).trim();
  const files = [...PHASE175_SOURCE_FILES].sort().map(relativePath => {
    const bytes = fs.readFileSync(path.join(REPO_ROOT, relativePath));
    return { path: relativePath, bytes: bytes.byteLength, sha256: sha256(bytes) };
  });
  const input = files.map(file => `${file.path}\0${file.bytes}\0${file.sha256}\n`).join("");
  return {
    hash_method: "sha256(sorted(path\\0byte_length\\0file_sha256\\n))",
    revision,
    files,
    digest: sha256(Buffer.from(input))
  };
}

function appendPhase175FidelityEvidence(receipt) {
  fs.mkdirSync(PHASE175_EVIDENCE_DIR, { recursive: true });
  const evidence = fs.existsSync(PHASE175_FIDELITY_PATH)
    ? JSON.parse(fs.readFileSync(PHASE175_FIDELITY_PATH, "utf8"))
    : { source: phase175SourceIdentity(), selectedCaseIds: [], executedCaseIds: [], cases: [], evidenceLimits: [
        "Story composition proves rendering only; command authorization, persistence and replay results are checked on connected routes.",
        "Actual zoom is Chromium tab zoom reported by chrome.tabs.getZoom with observed effective CSS viewport and DPR; the device scale factor only keeps screenshot output readable."
      ] };
  if (JSON.stringify(evidence.source) !== JSON.stringify(receipt.source)) {
    evidence.selectedCaseIds = [];
    evidence.executedCaseIds = [];
    evidence.cases = [];
  }
  evidence.source = receipt.source;
  const caseIds = receipt.executedCaseIds?.length
    ? receipt.executedCaseIds
    : [receipt.caseId, ...(receipt.cases || []).map(item => item.caseId)].filter(Boolean);
  for (const id of caseIds) {
    if (!evidence.selectedCaseIds.includes(id)) evidence.selectedCaseIds.push(id);
    if (!evidence.executedCaseIds.includes(id)) evidence.executedCaseIds.push(id);
  }
  evidence.cases.push(receipt);
  fs.writeFileSync(PHASE175_FIDELITY_PATH, `${JSON.stringify(evidence, null, 2)}\n`);
}

function appendFidelityEvidence(section, receipt) {
  fs.mkdirSync(EVIDENCE_DIR, { recursive: true });
  const evidence = fs.existsSync(FIDELITY_PATH)
    ? JSON.parse(fs.readFileSync(FIDELITY_PATH, "utf8"))
    : {
        source: sourceIdentity(),
        selectedCaseIds: [],
        executedCaseIds: [],
        themes: [],
        stylesheets: [],
        fonts: [],
        computedRoles: [],
        widths: [],
        evidenceLimits: [
          "Browser zoom reconciliation is owned by Phase 178.",
          "Captures use synthetic Northstar demo records only.",
          "The width matrix exercises System-resolved light and dark tokens at every viewport; the dedicated theme cases exercise Light/Dark/System radio selection and live preference changes."
        ]
      };

  evidence[section] ||= [];
  evidence[section].push(receipt);
  const caseIds = [receipt.caseId, ...(receipt.cases || []).map(scenario => scenario.caseId)].filter(Boolean);
  for (const caseId of caseIds) {
    if (!evidence.selectedCaseIds.includes(caseId)) {
      evidence.selectedCaseIds.push(caseId);
    }
    if (!evidence.executedCaseIds.includes(caseId)) {
      evidence.executedCaseIds.push(caseId);
    }
  }
  fs.writeFileSync(FIDELITY_PATH, `${JSON.stringify(evidence, null, 2)}\n`);
}

async function adminCssUrl(page) {
  for (const frame of page.frames()) {
    const href = await frame
      .evaluate(() => {
        const link = [...document.querySelectorAll('link[rel="stylesheet"]')]
          .map(element => element.href)
          .find(url => {
            const pathname = new URL(url).pathname;
            return pathname.startsWith("/dev/mail/css-") || pathname.startsWith("/ops/mail/css-");
          });
        if (link) return link;

        const imports = [...document.querySelectorAll("style")]
          .map(element => element.textContent || "")
          .join("\n");
        return imports.match(/@import\s+["']([^"']*\/(?:dev|ops)\/mail\/css-[^"']+)["']/)?.[1] || null;
      })
      .catch(() => null);
    if (href) return new URL(href, frame.url()).href;
  }
  throw new Error("Storybook did not load the versioned Admin stylesheet");
}

function expectRoleFamily(actual, family) {
  expect(actual.family, `computed role uses ${family}`).toContain(family);
}

test.beforeAll(() => {
  fs.mkdirSync(EVIDENCE_DIR, { recursive: true });
  fs.rmSync(FIDELITY_PATH, { force: true });
});

function quickViewFrame(page, variant) {
  return page.frameLocator(`iframe[id*="${variant}"]`);
}

async function waitForConnectedStoryHost(page) {
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
}

async function scrollStoryFrameBelowHeader(page, variant) {
  return page.locator(`iframe[id*="${variant}"]`).evaluate(frame => {
    const scrollport = frame.closest("#psb-live-container");
    if (!scrollport) throw new Error("Storybook variation scroll container is unavailable");
    const header = frame.ownerDocument.querySelector("header");
    const headerBottom = header?.getBoundingClientRect().bottom || 0;
    const targetTop = headerBottom + 12;
    scrollport.scrollTop += frame.getBoundingClientRect().top - targetTop;
    return { top: frame.getBoundingClientRect().top, headerBottom };
  });
}

async function setStoryFrameWidth(page, variant, width) {
  await page.locator(`iframe[id*="${variant}"]`).evaluate((frame, value) => {
    frame.style.setProperty("width", `${value}px`, "important");
    frame.style.setProperty("min-width", `${value}px`, "important");
    frame.style.setProperty("max-width", "none", "important");
  }, width);
}

async function themeState(frame) {
  return frame.locator(OWNER).evaluate(root => {
    const style = getComputedStyle(root);
    return {
      owner: root.dataset.themeOwner,
      preference: root.dataset.themePreference,
      resolved: root.dataset.themeResolved,
      osPreference: root.dataset.themeOs,
      dataTheme: root.dataset.theme,
      background: style.backgroundColor,
      text: style.color,
      base100: style.getPropertyValue("--color-base-100").trim(),
      baseContent: style.getPropertyValue("--color-base-content").trim()
    };
  });
}

async function setProductionTheme(page, theme) {
  const listPath = "/ops/mail?tenant_id=northstar&view=deliveries";
  await page.goto(`/demo/login?return_to=${encodeURIComponent(listPath)}`);
  await page.locator("[data-phx-main].phx-connected").waitFor();
  await page.goto(
    `/ops/mail/theme/${theme}?return_to=${encodeURIComponent(listPath)}`
  );
  await page.locator("[data-phx-main].phx-connected").waitFor();

  return page.evaluate(() => {
    const root = document.documentElement;
    const style = getComputedStyle(root);
    return {
      dataTheme: root.dataset.theme,
      base100: style.getPropertyValue("--color-base-100").trim(),
      baseContent: style.getPropertyValue("--color-base-content").trim()
    };
  });
}

test.describe("Phase174 themes", () => {
  for (const story of STORY_CASES) {
    test(`${story.area} story owns Light, Dark, and live System review themes`, async ({
      page
    }) => {
      await page.setViewportSize({ width: 1280, height: 900 });
      await page.emulateMedia({ colorScheme: "light" });

      const storyResponse = await page.goto(story.path);
      expect(storyResponse?.ok(), `${story.area} Storybook story loads`).toBe(true);
      await waitForConnectedStoryHost(page);

      const frame = quickViewFrame(page, story.variant);
      const root = frame.locator(OWNER);
      const light = frame.getByRole("radio", { name: "Light", exact: true });
      const dark = frame.getByRole("radio", { name: "Dark", exact: true });
      const system = frame.getByRole("radio", { name: "System", exact: true });
      await expect(root).toBeVisible();
      await expect(light).toBeVisible();
      await expect(dark).toBeVisible();
      await expect(system).toBeVisible();

      const pageURL = page.url();
      const storyIframeUrl = await frame.locator("body").evaluate(body => body.ownerDocument.URL);
      const initialText = await frame.locator("body").innerText();
      const initial = await themeState(frame);
      expect(initial).toMatchObject({
        owner: "quick-view-story",
        preference: "system",
        resolved: "light",
        osPreference: "light",
        dataTheme: "mailglass-light"
      });
      expect(initial.background).not.toBe("rgba(0, 0, 0, 0)");
      expect(initial.text).not.toBe("");
      expect(initial.base100).not.toBe("");
      expect(initial.baseContent).not.toBe("");
      expect(await frame.locator("body").getAttribute("data-theme")).toBeNull();
      expect(await frame.locator("#psb-iframe-container").getAttribute("data-theme")).toBeNull();
      expect(await frame.locator("[data-theme]").count()).toBe(1);

      await expect(system).toBeChecked();
      await page.emulateMedia({ colorScheme: "dark" });
      await expect.poll(async () => (await themeState(frame)).dataTheme).toBe("mailglass-dark");
      const systemDark = await themeState(frame);
      expect(systemDark).toMatchObject({
        preference: "system",
        resolved: "dark",
        osPreference: "dark",
        dataTheme: "mailglass-dark"
      });
      expect(systemDark.background).not.toBe(initial.background);
      expect(systemDark.text).not.toBe(initial.text);

      await page.emulateMedia({ colorScheme: "light" });
      await expect.poll(async () => (await themeState(frame)).dataTheme).toBe("mailglass-light");
      await light.check();
      await expect(light).toBeChecked();
      await page.emulateMedia({ colorScheme: "dark" });
      await expect.poll(async () => (await themeState(frame)).osPreference).toBe("dark");
      expect(await themeState(frame)).toMatchObject({
        preference: "light",
        resolved: "light",
        osPreference: "dark",
        dataTheme: "mailglass-light"
      });

      await dark.check();
      await expect(dark).toBeChecked();
      await expect.poll(async () => (await themeState(frame)).dataTheme).toBe("mailglass-dark");
      await page.emulateMedia({ colorScheme: "light" });
      await expect.poll(async () => (await themeState(frame)).osPreference).toBe("light");
      expect(await themeState(frame)).toMatchObject({
        preference: "dark",
        resolved: "dark",
        osPreference: "light",
        dataTheme: "mailglass-dark"
      });

      await system.check();
      await expect(system).toBeChecked();
      await expect.poll(async () => (await themeState(frame)).dataTheme).toBe("mailglass-light");
      const systemLight = await themeState(frame);
      expect(systemLight).toMatchObject({
        preference: "system",
        resolved: "light",
        osPreference: "light",
        dataTheme: "mailglass-light"
      });
      expect(await page.url()).toBe(pageURL);
      const selectedFrameId = await page.locator(`iframe[id*="${story.variant}"]`).getAttribute("id");
      expect(selectedFrameId).toContain(`variation-${story.variant}`);
      expect(await frame.locator("body").innerText()).toBe(initialText);

      const detachedTheme = await root.evaluate(node => {
        window.__phase174DetachedReviewRoot = node;
        const theme = node.dataset.theme;
        node.remove();
        return theme;
      });
      await page.emulateMedia({ colorScheme: "dark" });
      await expect.poll(() => frame.locator("body").evaluate(() =>
        window.__phase174DetachedReviewRoot?.dataset.theme
      )).toBe(detachedTheme);
      await frame.locator("body").evaluate(() => {
        const remounted = window.__phase174DetachedReviewRoot.cloneNode(true);
        document.body.append(remounted);
        window.__phase174RemountedReviewRoot = remounted;
      });
      await expect.poll(() => frame.locator("body").evaluate(() =>
        window.__phase174RemountedReviewRoot?.dataset.theme
      )).toBe("mailglass-dark");

      expect(
        (await page.context().cookies(new URL(page.url()).origin)).some(cookie =>
          cookie.name.includes("theme")
        ),
        "review selection does not persist a host preference"
      ).toBe(false);

      const productionLight = await setProductionTheme(page, "light");
      expect(productionLight.dataTheme).toBe("mailglass-light");
      expect(systemLight.base100).toBe(productionLight.base100);
      expect(systemLight.baseContent).toBe(productionLight.baseContent);

      await page.emulateMedia({ colorScheme: "light" });
      await page.goto(story.path);
      await waitForConnectedStoryHost(page);
      const restoredFrame = quickViewFrame(page, story.variant);
      await expect(restoredFrame.locator(OWNER)).toBeVisible();
      await expect.poll(async () => (await themeState(restoredFrame)).dataTheme).toBe("mailglass-light");
      await page.emulateMedia({ colorScheme: "dark" });
      await expect.poll(async () => (await themeState(restoredFrame)).dataTheme).toBe("mailglass-dark");
      const flippedSystemDark = await themeState(restoredFrame);

      const productionDark = await setProductionTheme(page, "dark");
      expect(productionDark.dataTheme).toBe("mailglass-dark");
      expect(flippedSystemDark.base100).toBe(productionDark.base100);
      expect(flippedSystemDark.baseContent).toBe(productionDark.baseContent);

      const themeReceipt = {
        caseId: `theme:${story.area}:${story.variant}`,
        storyUrl: pageURL,
        iframeUrl: storyIframeUrl,
        owner: initial.owner,
        systemLight: {
          selectedPreference: systemLight.preference,
          resolvedScheme: systemLight.resolved,
          osPreference: systemLight.osPreference,
          dataTheme: systemLight.dataTheme,
          base100: systemLight.base100,
          baseContent: systemLight.baseContent
        },
        systemDark: {
          selectedPreference: flippedSystemDark.preference,
          resolvedScheme: flippedSystemDark.resolved,
          osPreference: flippedSystemDark.osPreference,
          dataTheme: flippedSystemDark.dataTheme,
          base100: flippedSystemDark.base100,
          baseContent: flippedSystemDark.baseContent
        },
        production: {
          light: productionLight.dataTheme,
          dark: productionDark.dataTheme
        },
        explicitThemeStability: true,
        selectionPreserved: true,
        hostPreferencePersisted: false
      };
      appendFidelityEvidence("themes", themeReceipt);

      console.log(
        "PHASE174_THEME_RECEIPT " +
          JSON.stringify({ story: story.area, ...themeReceipt })
      );
    });
  }
});

async function openProductionDeliveryQuickView(page) {
  const listPath = "/ops/mail?tenant_id=northstar&view=deliveries";
  await page.goto(`${BASE_URL}/demo/login?return_to=${encodeURIComponent(listPath)}`);
  await page.locator("[data-phx-main].phx-connected").waitFor();
  const row = page.getByTestId("operator-delivery-row").filter({ visible: true }).first();
  await expect(row).toBeVisible();
  const opener = row.getByRole("button", { name: /Open delivery/ });
  const focusReturnId = await opener.getAttribute("id");
  await opener.click();
  const panel = page.getByTestId("operator-quick-view");
  await expect(panel).toBeVisible();
  return { panel, opener, focusReturnId };
}

async function readComputedRoles(root) {
  return root.evaluate(root => {
    const view = root.ownerDocument.defaultView;
    const style = element => ({
      family: view.getComputedStyle(element).fontFamily,
      weight: view.getComputedStyle(element).fontWeight
    });
    return {
      ui: style(root),
      display: style(root.querySelector('[role="dialog"] h3')),
      code: style(root.querySelector('[role="dialog"] .mono'))
    };
  });
}

test.describe("Phase174 fonts", () => {
  for (const story of STORY_CASES) {
    test(`${story.area} loads production CSS, all font bytes, and computed roles`, async ({
      browser
    }) => {
      const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
      const page = await context.newPage();
      const fontResponses = new Map();
      page.on("response", response => {
        const filename = FONT_FILES.find(file =>
          new URL(response.url()).pathname.endsWith(`/fonts/${file}`)
        );
        if (filename && !fontResponses.has(filename)) {
          fontResponses.set(filename, {
            url: response.url(),
            status: response.status(),
            contentType: response.headers()["content-type"] || "",
            body: response.body()
          });
        }
      });

      try {
        await page.emulateMedia({ colorScheme: "light" });
        const storyResponse = await page.goto(new URL(story.path, BASE_URL).href);
        expect(storyResponse?.ok(), `${story.area} Storybook story loads`).toBe(true);
        await waitForConnectedStoryHost(page);
        const frame = page.frameLocator(`iframe[id*="${story.variant}"]`);
        const root = frame.locator(OWNER);
        await expect(root).toBeVisible();
        const storyIframeUrl = await root.evaluate(element => element.ownerDocument.URL);

        const fontProbe = await root.evaluate(async root => {
          const document = root.ownerDocument;
          const definitions = [
            { role: "ui", family: "Inter", weight: 400, tag: "p" },
            { role: "ui", family: "Inter", weight: 700, tag: "p" },
            { role: "display", family: "Inter Tight", weight: 400, tag: "h3" },
            { role: "display", family: "Inter Tight", weight: 700, tag: "h3" },
            { role: "code", family: "IBM Plex Mono", weight: 400, tag: "code" },
            { role: "code", family: "IBM Plex Mono", weight: 700, tag: "code" }
          ];
          const probe = document.createElement("div");
          probe.dataset.fidelityFontProbe = "true";
          probe.style.cssText = "position:fixed;left:-10000px;top:0;display:block;visibility:visible";
          const elements = definitions.map((definition, index) => {
            const element = document.createElement(definition.tag);
            element.dataset.fidelityFontRole = `${definition.role}-${definition.weight}`;
            element.textContent = `Receipt sample ${index} 0123456789`;
            element.style.fontWeight = String(definition.weight);
            probe.append(element);
            return element;
          });
          root.append(probe);
          await Promise.all(
            definitions.map((definition, index) =>
              document.fonts.load(
                `${definition.weight} 16px "${definition.family}"`,
                elements[index].textContent
              )
            )
          );
          const faceStatus = definitions.map(definition => {
            const face = [...document.fonts].find(candidate =>
              candidate.family.replace(/["']/g, "") === definition.family &&
              candidate.weight === String(definition.weight) &&
              candidate.style === "normal"
            );
            return {
              family: definition.family,
              weight: definition.weight,
              status: face?.status || "missing"
            };
          });
          const roleStyle = element => {
            const style = document.defaultView.getComputedStyle(element);
            return { family: style.fontFamily, weight: style.fontWeight };
          };
          const roles = {
            ui: roleStyle(root),
            display: roleStyle(root.querySelector('[role="dialog"] h3')),
            code: roleStyle(root.querySelector('[role="dialog"] .mono'))
          };
          const theme = {
            owner: root.dataset.themeOwner,
            selectedPreference: root.dataset.themePreference,
            resolvedScheme: root.dataset.themeResolved,
            osPreference: root.dataset.themeOs,
            dataTheme: root.dataset.theme
          };
          const sandboxReset = document.createElement("style");
          sandboxReset.dataset.phase174SandboxReset = "true";
          sandboxReset.textContent = "@layer app { body, h1, h2, h3, code, pre, .mono { font-family: Georgia, serif; } }";
          document.head.append(sandboxReset);
          const sandboxRoles = {
            ui: roleStyle(root),
            display: roleStyle(root.querySelector('[role="dialog"] h3')),
            code: roleStyle(root.querySelector('[role="dialog"] .mono'))
          };
          sandboxReset.remove();
          probe.remove();
          return { faceStatus, roles, theme, sandboxRoles };
        });

        for (const [role, family] of [
          ["ui", "Inter"],
          ["display", "Inter Tight"],
          ["code", "IBM Plex Mono"]
        ]) {
          expectRoleFamily(fontProbe.roles[role], family);
          expectRoleFamily(fontProbe.sandboxRoles[role], family);
        }
        expect(fontProbe.roles.ui.weight).toBe("400");
        expect(fontProbe.roles.display.weight).toBe("700");
        expect(fontProbe.roles.code.weight).toBe("400");
        expect(fontProbe.faceStatus).toHaveLength(6);
        for (const face of fontProbe.faceStatus) {
          expect(face.status, `${face.family} ${face.weight} face loaded`).toBe("loaded");
        }

        const cssUrl = await adminCssUrl(page);
        const cssResponse = await page.request.get(cssUrl);
        expect(cssResponse.status(), "Storybook Admin CSS returns 200").toBe(200);
        const servedCss = await cssResponse.body();
        const sourceCss = fs.readFileSync(path.join(REPO_ROOT, "mailglass_admin/assets/css/app.css"));
        const builtCss = fs.readFileSync(path.join(REPO_ROOT, "mailglass_admin/priv/static/app.css"));
        const servedCssSha256 = sha256(servedCss);
        expect(servedCssSha256, "served bytes match the committed production bundle").toBe(
          sha256(builtCss)
        );
        const routeMd5 = new URL(cssUrl).pathname.match(/css-([a-f0-9]{32})$/)?.[1];
        expect(routeMd5, "versioned CSS URL identifies the served bytes").toBe(md5(servedCss));

        const fontReceipts = [];
        for (const filename of FONT_FILES) {
          const response = fontResponses.get(filename);
          expect(response, `${filename} was fetched by the browser`).toBeTruthy();
          expect(response.status, `${filename} returns 200`).toBe(200);
          expect(response.contentType, `${filename} uses WOFF2 content type`).toContain("font/woff2");
          const servedBytes = await response.body;
          const committedBytes = fs.readFileSync(
            path.join(REPO_ROOT, "mailglass_admin/priv/static/fonts", filename)
          );
          expect(sha256(servedBytes), `${filename} bytes match production asset`).toBe(
            sha256(committedBytes)
          );
          fontReceipts.push({
            path: filename,
            url: response.url,
            status: response.status,
            contentType: response.contentType,
            bytes: servedBytes.byteLength,
            sha256: sha256(servedBytes),
            loadedFace: fontProbe.faceStatus.find(face => {
              const family = filename.startsWith("inter-tight")
                ? "Inter Tight"
                : filename.startsWith("ibm-plex-mono")
                  ? "IBM Plex Mono"
                  : "Inter";
              const weight = Number(filename.match(/-(400|700)\.woff2$/)?.[1]);
              return face.family === family && face.weight === weight;
            })?.status
          });
        }

        const { panel, opener, focusReturnId } = await openProductionDeliveryQuickView(page);
        expect(focusReturnId).toBeTruthy();
        const productionRoles = await readComputedRoles(page.locator(".mg-admin-root").filter({ has: panel }));
        for (const role of ["ui", "display", "code"]) {
          expect(fontProbe.roles[role].family).toBe(productionRoles[role].family);
          expect(fontProbe.roles[role].weight).toBe(productionRoles[role].weight);
        }
        const productionCssUrl = await adminCssUrl(page);
        expect(new URL(productionCssUrl).pathname).toMatch(/^\/ops\/mail\/css-/);
        const productionCssResponse = await page.request.get(productionCssUrl);
        expect(productionCssResponse.status()).toBe(200);
        const productionCssBytes = await productionCssResponse.body();
        expect(sha256(productionCssBytes)).toBe(sha256(builtCss));

        const caseId = `fonts:${story.area}:${story.variant}`;
        const stylesheetReceipt = {
          caseId,
          storyUrl: new URL(story.path, BASE_URL).href,
          productionQuickViewUrl: page.url(),
          source: {
            path: "mailglass_admin/assets/css/app.css",
            sha256: sha256(sourceCss)
          },
          built: {
            path: "mailglass_admin/priv/static/app.css",
            sha256: sha256(builtCss),
            bytes: builtCss.byteLength
          },
          served: {
            storyUrl: cssUrl,
            productionUrl: productionCssUrl,
            sha256: servedCssSha256,
            md5: md5(servedCss),
            bytes: servedCss.byteLength,
            matchesBuilt: servedCssSha256 === sha256(builtCss)
          }
        };
        const rolesReceipt = {
          caseId,
          story: fontProbe.roles,
          production: productionRoles
        };
        appendFidelityEvidence("stylesheets", stylesheetReceipt);
        appendFidelityEvidence("fonts", { caseId, assets: fontReceipts });
        appendFidelityEvidence("computedRoles", {
          ...rolesReceipt,
          owner: fontProbe.theme.owner,
          selectedPreference: fontProbe.theme.selectedPreference,
          resolvedScheme: fontProbe.theme.resolvedScheme,
          osPreference: fontProbe.theme.osPreference,
          dataTheme: fontProbe.theme.dataTheme,
          adversarialSandboxReset: fontProbe.sandboxRoles,
          storyUrl: new URL(story.path, BASE_URL).href,
          iframeUrl: storyIframeUrl,
          productionConnected: await page.locator("[data-phx-main]").getAttribute("class")
        });
      } finally {
        await context.close();
      }
    });
  }
});

test.describe("Phase174 widths", () => {
  for (const story of STORY_CASES) {
    test(`${story.area} normal and boundary quick views fit bounded responsive widths`, async ({
      page
    }) => {
      const narrowCases = [];
      for (const width of VIEWPORT_WIDTHS) {
        for (const theme of ["light", "dark"]) {
          const boundary = (VIEWPORT_WIDTHS.indexOf(width) + (theme === "dark" ? 1 : 0)) % 2 === 1;
          narrowCases.push({
            width,
            theme,
            variant: boundary ? "northstar_first" : "northstar_normal",
            selection: boundary ? "boundary" : "normal"
          });
        }
      }

      const receipts = [];
      const panelSelector = story.area === "delivery" ? "#operator-quick-view" : "#inbound-quick-view";
      const technicalSelector = story.area === "delivery" ? "#operator-quick-technical" : "#inbound-quick-technical";
      const screenshotWidths = new Set([320, 768, 1440]);

      for (const scenario of narrowCases) {
        await page.setViewportSize({ width: scenario.width, height: 900 });
        await page.emulateMedia({ colorScheme: scenario.theme });
        const storyPath = `/dev/storybook/quick_views/${story.area}?variation_id=${scenario.variant}`;
        await page.goto(new URL(storyPath, BASE_URL).href);
        await waitForConnectedStoryHost(page);
        const frame = page.frameLocator(`iframe[id*="${scenario.variant}"]`);
        const root = frame.locator(OWNER);
        await expect(root).toBeVisible();
        await expect(root).toHaveAttribute("data-theme-preference", "system");
        await expect(root).toHaveAttribute("data-theme-os", scenario.theme);
        await expect(root).toHaveAttribute("data-theme", scenario.theme === "dark" ? "mailglass-dark" : "mailglass-light");
        const expectedBase100 = scenario.theme === "dark" ? "#0d1b2a" : "#f8fbfd";
        await expect.poll(() =>
          root.evaluate(element => getComputedStyle(element).getPropertyValue("--color-base-100").trim())
        ).toBe(expectedBase100);
        const panel = frame.locator(panelSelector);
        await expect(panel).toBeVisible();
        const position = panel.locator("[aria-live=polite]");
        await expect(position).toBeVisible();
        const expectedPosition = scenario.selection === "boundary"
          ? "1"
          : story.area === "delivery"
            ? "2"
            : "3";
        expect((await position.innerText()).trim()).toMatch(
          new RegExp(`^${expectedPosition} of \\d+$`)
        );
        const close = panel.getByRole("link", { name: "Close quick view" });
        await expect(close).toBeVisible();
        await expect.poll(() =>
          panel.evaluate(element =>
            element.getAnimations().every(animation => animation.playState === "finished")
          )
        ).toBe(true);

        const geometry = await panel.evaluate((panel, technicalSelector) => {
          const view = panel.ownerDocument.defaultView;
          const bounds = element => {
            const rect = element.getBoundingClientRect();
            return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom, width: rect.width, height: rect.height };
          };
          const panelRect = bounds(panel);
          const position = panel.querySelector("[aria-live=polite]");
          const close = panel.querySelector('[aria-label="Close quick view"]');
          const targetElements = [...panel.querySelectorAll("a[href], button")].filter(element => {
            const rect = element.getBoundingClientRect();
            return rect.width > 0 && rect.height > 0 && element.getAttribute("aria-hidden") !== "true";
          });
          const targets = targetElements.map(element => ({
            label: element.getAttribute("aria-label") || element.textContent.trim().slice(0, 40),
            ...bounds(element)
          }));
          const technical = panel.querySelector(`${technicalSelector} [data-copy-value]`);
          return {
            viewport: { width: view.innerWidth, height: view.innerHeight },
            panel: panelRect,
            reviewTheme: bounds(panel.ownerDocument.querySelector('[data-testid="quick-view-review-theme"]')),
            position: bounds(position),
            close: bounds(close),
            targets,
            technical: {
              text: technical.textContent.trim(),
              value: technical.dataset.copyValue,
              width: technical.clientWidth,
              scrollWidth: technical.scrollWidth,
              height: technical.clientHeight,
              overflowWrap: view.getComputedStyle(technical).overflowWrap,
              wordBreak: view.getComputedStyle(technical).wordBreak
            }
          };
        }, technicalSelector);
        expect(geometry.viewport.width).toBeGreaterThan(0);
        expect(geometry.reviewTheme.bottom, "theme controls do not obscure the quick view").toBeLessThanOrEqual(geometry.panel.top);
        expect(geometry.reviewTheme.left).toBeGreaterThanOrEqual(0);
        expect(geometry.reviewTheme.right).toBeLessThanOrEqual(geometry.viewport.width);
        expect(geometry.panel.left).toBeGreaterThanOrEqual(0);
        expect(geometry.panel.right).toBeLessThanOrEqual(geometry.viewport.width);
        expect(geometry.close.left).toBeGreaterThanOrEqual(geometry.panel.left);
        expect(geometry.close.right).toBeLessThanOrEqual(geometry.panel.right);
        expect(geometry.position.left).toBeGreaterThanOrEqual(geometry.panel.left);
        expect(geometry.position.right).toBeLessThanOrEqual(geometry.panel.right);
        for (const target of geometry.targets) {
          expect(target.width, `${target.label} target width at ${scenario.width}px`).toBeGreaterThanOrEqual(44);
          expect(target.height, `${target.label} target height at ${scenario.width}px`).toBeGreaterThanOrEqual(44);
          expect(target.left, `${target.label} left edge at ${scenario.width}px`).toBeGreaterThanOrEqual(geometry.panel.left);
          expect(target.right, `${target.label} right edge at ${scenario.width}px`).toBeLessThanOrEqual(geometry.panel.right);
        }
        expect(geometry.technical.text).toBe(geometry.technical.value);
        expect(geometry.technical.width).toBeGreaterThan(0);
        expect(geometry.technical.scrollWidth).toBeLessThanOrEqual(geometry.technical.width);
        expect(geometry.technical.overflowWrap).toBe("anywhere");

        const caseId = `width:${story.area}:${scenario.variant}:${scenario.width}:${scenario.theme}`;
        const receipt = {
          caseId,
          storyUrl: new URL(storyPath, BASE_URL).href,
          paneWidth: geometry.panel.width,
          viewportWidth: scenario.width,
          iframeViewportWidth: geometry.viewport.width,
          viewportHeight: geometry.viewport.height,
          scenario: scenario.selection,
          theme: scenario.theme,
          position: await position.innerText(),
          closeWithinPane: geometry.close.left >= geometry.panel.left && geometry.close.right <= geometry.panel.right,
          technicalWrapping: geometry.technical,
          controls: geometry.targets,
          reviewTheme: geometry.reviewTheme
        };
        receipts.push(receipt);

        if (screenshotWidths.has(scenario.width) && scenario.theme === "dark") {
          fs.mkdirSync(EVIDENCE_DIR, { recursive: true });
          const screenshot = path.join(EVIDENCE_DIR, `${story.area}-${scenario.width}-${scenario.selection}-dark.png`);
          await frame.locator("body").screenshot({ path: screenshot });
          receipt.screenshot = path.relative(REPO_ROOT, screenshot);
        }
      }

      appendFidelityEvidence("widths", {
        caseId: `widths:${story.area}:responsive-matrix`,
        cases: receipts
      });

      await page.emulateMedia({ reducedMotion: "reduce" });
      await page.setViewportSize({ width: 1280, height: 900 });
      const { panel, opener, focusReturnId } = await openProductionDeliveryQuickView(page);
      const next = panel.getByRole("link", { name: /Next delivery/ });
      const close = panel.getByRole("link", { name: "Close quick view" });
      await close.focus();
      await page.keyboard.press("Shift+Tab");
      await expect.poll(() => page.evaluate(() => document.activeElement?.getAttribute("aria-label")))
        .toBe("Next delivery");
      expect(await next.evaluate(element => element.matches(":focus-visible"))).toBe(true);
      const reducedMotionSeconds = await panel.evaluate(element => {
        const duration = getComputedStyle(element).animationDuration.split(",")[0].trim();
        return duration.endsWith("ms") ? parseFloat(duration) / 1000 : parseFloat(duration);
      });
      expect(reducedMotionSeconds).toBeLessThanOrEqual(0.00002);
      await page.keyboard.press("Escape");
      await expect(panel).toHaveCount(0);
      await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe(focusReturnId);
      await expect(opener).toBeFocused();
    });
  }
});

test("Phase 175 fidelity: current Delivery story, connected focus, assets, themes and actual zoom", async ({ browser }) => {
  test.setTimeout(90_000);
  const source = phase175SourceIdentity();
  const storyPath = "/dev/storybook/delivery_investigation?variation_id=fjordline_long_unicode";
  const storyUrl = new URL(storyPath, BASE_URL).href;
  const owner = '[data-theme-owner="delivery-investigation-story"]';
  const variant = "fjordline_long_unicode";
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await context.newPage();
  const fontResponses = new Map();
  page.on("response", response => {
    const filename = FONT_FILES.find(file => new URL(response.url()).pathname.endsWith(`/fonts/${file}`));
    if (filename && !fontResponses.has(filename)) {
      fontResponses.set(filename, {
        url: response.url(), status: response.status(),
        contentType: response.headers()["content-type"] || "", body: response.body()
      });
    }
  });

  const receipt = {
    caseId: "fidelity:delivery-investigation:long-unicode",
    source,
    selectedCaseCount: 10,
    expectedCaseCount: 10,
    executedCaseIds: [],
    themes: [],
    widths: [],
    screenshots: [],
    assets: {},
    hooks: {}
  };
  try {
    await page.emulateMedia({ colorScheme: "light" });
    const storyResponse = await page.goto(storyUrl, { waitUntil: "load" });
    expect(storyResponse?.status(), "the current-source Delivery investigation story returns 200").toBe(200);
    await waitForConnectedStoryHost(page);
    await scrollStoryFrameBelowHeader(page, variant);
    const frame = page.frameLocator(`iframe[id*="${variant}"]`);
    const root = frame.locator(owner);
    const main = frame.getByTestId("delivery-investigation-story");
    const picker = frame.getByTestId("delivery-investigation-review-theme");
    await expect(main).toHaveAttribute("data-scenario-id", "delivery-investigation-fjordline-long-unicode");
    await expect(root).toBeVisible();
    await expect(frame.getByTestId("operator-replay-reviewed-target")).toContainText(
      "wh_evt_fjordline_01JXW9ZQKB3V1N4P2RMT7FHCG"
    );
    const storyIframeUrl = await root.evaluate(element => element.ownerDocument.URL);
    receipt.executedCaseIds.push("story:delivery-investigation-fjordline-long-unicode");

    const light = frame.getByRole("radio", { name: "Light", exact: true });
    const dark = frame.getByRole("radio", { name: "Dark", exact: true });
    const system = frame.getByRole("radio", { name: "System", exact: true });
    await expect(system).toBeChecked();
    await expect.poll(() => root.getAttribute("data-theme")).toBe("mailglass-light");
    await page.emulateMedia({ colorScheme: "dark" });
    await expect.poll(() => root.getAttribute("data-theme")).toBe("mailglass-dark");
    const systemDark = await root.evaluate(element => ({
      preference: element.dataset.themePreference,
      resolved: element.dataset.themeResolved,
      os: element.dataset.themeOs,
      dataTheme: element.dataset.theme
    }));
    expect(systemDark).toEqual({ preference: "system", resolved: "dark", os: "dark", dataTheme: "mailglass-dark" });
    await light.click({ timeout: 5_000 });
    await expect(light).toBeChecked();
    await page.emulateMedia({ colorScheme: "light" });
    await dark.click({ timeout: 5_000 });
    await expect(dark).toBeChecked();
    await page.emulateMedia({ colorScheme: "light" });
    await expect.poll(() => root.getAttribute("data-theme")).toBe("mailglass-dark");
    await system.click({ timeout: 5_000 });
    await expect(system).toBeChecked();
    await expect.poll(() => root.getAttribute("data-theme")).toBe("mailglass-light");
    await page.emulateMedia({ colorScheme: "dark" });
    await expect.poll(() => root.getAttribute("data-theme")).toBe("mailglass-dark");
    receipt.themes.push({
      caseId: "theme:delivery-investigation:system-light-dark-and-explicit-stability",
      owner: "delivery-investigation-story",
      systemLight: { preference: "system", resolved: "light", os: "light", dataTheme: "mailglass-light" },
      systemDark,
      explicitDarkStableOnLightOS: true,
      restoredSystemDark: true
    });
    receipt.executedCaseIds.push("theme:delivery-investigation:system-light-dark-and-explicit-stability");

    const widthCases = [];
    for (const [index, width] of [320, 375, 768, 1280, 1440].entries()) {
      const theme = index % 2 === 0 ? "dark" : "light";
      await setStoryFrameWidth(page, variant, width);
      await expect.poll(() => root.evaluate(element => element.ownerDocument.defaultView.innerWidth)).toBe(width);
      await system.check();
      await page.emulateMedia({ colorScheme: theme });
      await expect.poll(() => root.getAttribute("data-theme")).toBe(`mailglass-${theme}`);
      const geometry = await root.evaluate(element => {
        const bounds = node => {
          const rect = node.getBoundingClientRect();
          return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom, width: rect.width, height: rect.height };
        };
        const document = element.ownerDocument;
        const picker = element.querySelector('[data-testid="delivery-investigation-review-theme"]');
        const main = element.querySelector('[data-testid="delivery-investigation-story"]');
          const storyHeader = main?.querySelector("header");
        const dialog = element.querySelector('[role="dialog"]');
          const targetId = dialog?.querySelector('[data-testid="operator-replay-target-id"]');
          const providerEventLabel = [...(dialog?.querySelectorAll("dt") || [])]
            .find(node => node.textContent.trim() === "Provider event");
          const technical = providerEventLabel?.nextElementSibling;
        return {
          viewportWidth: document.defaultView.innerWidth,
          documentWidth: document.documentElement.scrollWidth,
          picker: bounds(picker), main: bounds(main), storyHeader: bounds(storyHeader), dialog: bounds(dialog),
          technical: technical?.textContent.trim() || null,
          technicalWidth: technical?.clientWidth || 0,
          technicalScrollWidth: technical?.scrollWidth || 0,
          targetId: targetId?.textContent.trim() || null,
          targetIdWidth: targetId?.clientWidth || 0,
          targetIdScrollWidth: targetId?.scrollWidth || 0,
          technicalWrap: technical && document.defaultView.getComputedStyle(technical).overflowWrap,
          technicalWordBreak: technical && document.defaultView.getComputedStyle(technical).wordBreak,
          targets: [...picker.querySelectorAll("label")].map(bounds)
        };
      });
      expect(geometry.viewportWidth).toBe(width);
      expect(geometry.documentWidth, `Delivery investigation has no horizontal page overflow at ${width}px`).toBeLessThanOrEqual(width);
      expect(geometry.picker.bottom, `theme picker does not overlap story content at ${width}px`).toBeLessThanOrEqual(geometry.storyHeader.top);
      expect(geometry.picker.bottom, `theme picker does not overlap the dialog at ${width}px`).toBeLessThanOrEqual(geometry.dialog.top);
      expect(geometry.technical).toContain("provider_evt_fjordline_long_identifier_01JXW9ZQKB3V1N4P2RMT7FHCG");
      expect(geometry.technicalWidth).toBeGreaterThan(0);
      expect(geometry.technicalScrollWidth).toBeLessThanOrEqual(geometry.technicalWidth);
      expect(geometry.targetId).toBe("wh_evt_fjordline_01JXW9ZQKB3V1N4P2RMT7FHCG");
      expect(geometry.targetIdWidth).toBeGreaterThan(0);
      expect(geometry.targetIdScrollWidth).toBeLessThanOrEqual(geometry.targetIdWidth);
      for (const target of geometry.targets) {
        expect(target.width).toBeGreaterThanOrEqual(44);
        expect(target.height).toBeGreaterThanOrEqual(44);
        expect(target.left).toBeGreaterThanOrEqual(geometry.picker.left);
        expect(target.right).toBeLessThanOrEqual(geometry.picker.right);
      }
      const item = {
        caseId: `fidelity:delivery-investigation:${width}:${theme}`,
        storyUrl: page.url(), iframeUrl: storyIframeUrl, viewportWidth: width,
        theme, themeOwner: "delivery-investigation-story", geometry
      };
      widthCases.push(item);
      receipt.executedCaseIds.push(item.caseId);
      if ([320, 1440].includes(width)) {
        const screenshot = path.join(PHASE175_EVIDENCE_DIR, `delivery-investigation-${width}-${theme}.png`);
        fs.mkdirSync(PHASE175_EVIDENCE_DIR, { recursive: true });
        await frame.locator("body").screenshot({ path: screenshot });
        expect(fs.statSync(screenshot).size).toBeGreaterThan(0);
        const relative = path.relative(REPO_ROOT, screenshot);
        item.screenshot = relative;
        receipt.screenshots.push(relative);
      }
    }
    receipt.widths = widthCases;

    const cssUrl = await adminCssUrl(page);
    const cssResponse = await page.request.get(cssUrl);
    expect(cssResponse.status(), "Storybook production CSS request succeeds").toBe(200);
    const servedCss = await cssResponse.body();
    const builtCss = fs.readFileSync(path.join(REPO_ROOT, "mailglass_admin/priv/static/app.css"));
    expect(sha256(servedCss), "Storybook CSS bytes match the current production bundle").toBe(sha256(builtCss));
    expect(new URL(cssUrl).pathname.match(/css-([a-f0-9]{32})$/)?.[1], "versioned CSS URL names served bytes")
      .toBe(md5(servedCss));

    const fontProbe = await root.evaluate(async element => {
      const document = element.ownerDocument;
      const definitions = [
        ["Inter", 400], ["Inter", 700], ["Inter Tight", 400],
        ["Inter Tight", 700], ["IBM Plex Mono", 400], ["IBM Plex Mono", 700]
      ];
      await Promise.all(definitions.map(([family, weight]) => document.fonts.load(`${weight} 16px "${family}"`, "Mailglass 012345")));
      const faces = definitions.map(([family, weight]) => {
        const face = [...document.fonts].find(item => item.family.replace(/["']/g, "") === family && item.weight === String(weight));
        return { family, weight, status: face?.status || "missing" };
      });
      const style = node => {
        const computed = document.defaultView.getComputedStyle(node);
        return { family: computed.fontFamily, weight: computed.fontWeight };
      };
      const title = element.querySelector('[role="dialog"] h2');
      const code = element.querySelector('[role="dialog"] .mono');
      const roles = { ui: style(element), display: style(title), code: style(code) };
      return {
        faces, roles, fontStatus: document.fonts.status,
        theme: {
          owner: element.dataset.themeOwner,
          preference: element.dataset.themePreference,
          resolved: element.dataset.themeResolved,
          os: element.dataset.themeOs,
          dataTheme: element.dataset.theme
        }
      };
    });
    for (const face of fontProbe.faces) expect(face.status, `${face.family} ${face.weight} face loads`).toBe("loaded");
    for (const [role, family] of [["ui", "Inter"], ["display", "Inter Tight"], ["code", "IBM Plex Mono"]]) {
      expectRoleFamily(fontProbe.roles[role], family);
    }
    expect(fontProbe.roles.ui.weight).toBe("400");
    expect(fontProbe.roles.display.weight).toBe("700");
    expect(fontProbe.roles.code.weight).toBe("400");
    const fontReceipts = [];
    for (const filename of FONT_FILES) {
      const response = fontResponses.get(filename);
      expect(response, `${filename} is fetched by the current story`).toBeTruthy();
      expect(response.status).toBe(200);
      expect(response.contentType).toContain("font/woff2");
      const served = await response.body;
      const committed = fs.readFileSync(path.join(REPO_ROOT, "mailglass_admin/priv/static/fonts", filename));
      expect(sha256(served)).toBe(sha256(committed));
      fontReceipts.push({ path: filename, url: response.url, status: response.status,
        contentType: response.contentType, bytes: served.byteLength, sha256: sha256(served) });
    }
    receipt.assets = {
      stylesheet: { url: cssUrl, status: cssResponse.status(), bytes: servedCss.byteLength,
        sha256: sha256(servedCss), md5: md5(servedCss), matchesBuilt: true },
      fonts: fontReceipts,
      loadedFaces: fontProbe.faces,
      computedRoles: fontProbe.roles,
      theme: fontProbe.theme
    };
    receipt.executedCaseIds.push("assets:storybook-css-and-six-font-faces");

    const zoomExtension = path.resolve(REPO_ROOT, "mailglass_admin/e2e/support/browser-zoom-extension");
    const zoomContext = await chromium.launchPersistentContext("", {
      channel: "chromium", headless: true,
      viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2,
      args: [`--disable-extensions-except=${zoomExtension}`, `--load-extension=${zoomExtension}`]
    });
    let zoomEvidence;
    try {
      const zoomPage = zoomContext.pages()[0] || await zoomContext.newPage();
      await zoomPage.emulateMedia({ colorScheme: "dark" });
      await zoomPage.goto(storyUrl, { waitUntil: "load" });
      await waitForConnectedStoryHost(zoomPage);
      await scrollStoryFrameBelowHeader(zoomPage, variant);
      const zoomFrame = zoomPage.frameLocator(`iframe[id*="${variant}"]`);
      const zoomRoot = zoomFrame.locator(owner);
      const initial = await zoomPage.evaluate(() => ({
        viewportWidth: window.innerWidth, viewportHeight: window.innerHeight,
        devicePixelRatio: window.devicePixelRatio
      }));
      const serviceWorker = zoomContext.serviceWorkers()[0] || await zoomContext.waitForEvent("serviceworker");
      const tabZoom = await serviceWorker.evaluate(async () => {
        const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
        if (!tab?.id) throw new Error("Active Chromium tab is unavailable");
        await chrome.tabs.setZoom(tab.id, 2);
        return { tabId: tab.id, factor: await chrome.tabs.getZoom(tab.id) };
      });
      expect(tabZoom.factor, "actual Chromium tab zoom is 200 percent").toBe(2);
      await expect.poll(() => zoomPage.evaluate(() => window.innerWidth)).toBe(720);
      await zoomPage.setViewportSize({ width: 640, height: 900 });
      await expect.poll(() => zoomPage.evaluate(() => window.innerWidth)).toBe(320);
      await setStoryFrameWidth(zoomPage, variant, 320);
      const effective = await zoomRoot.evaluate(element => ({
        viewportWidth: element.ownerDocument.defaultView.innerWidth,
        viewportHeight: element.ownerDocument.defaultView.innerHeight,
        documentWidth: element.ownerDocument.documentElement.scrollWidth,
        devicePixelRatio: element.ownerDocument.defaultView.devicePixelRatio,
        owner: element.dataset.themeOwner,
        theme: element.dataset.theme
      }));
      expect(effective.viewportWidth).toBe(320);
      expect(effective.documentWidth).toBeLessThanOrEqual(320);
      expect(effective.devicePixelRatio / initial.devicePixelRatio).toBe(2);
      expect(effective.owner).toBe("delivery-investigation-story");
      const screenshot = path.join(PHASE175_EVIDENCE_DIR, "delivery-investigation-200-browser-zoom.png");
      fs.mkdirSync(PHASE175_EVIDENCE_DIR, { recursive: true });
      await zoomFrame.locator("body").screenshot({ path: screenshot });
      expect(fs.statSync(screenshot).size).toBeGreaterThan(0);
      zoomEvidence = {
        caseId: "fidelity:delivery-investigation:real-200-percent-zoom",
        url: zoomPage.url(), iframeUrl: await zoomRoot.evaluate(element => element.ownerDocument.URL),
        tabZoom, initial, effective, screenshot: path.relative(REPO_ROOT, screenshot)
      };
      receipt.screenshots.push(zoomEvidence.screenshot);
      receipt.executedCaseIds.push(zoomEvidence.caseId);
    } finally {
      await zoomContext.close();
    }

    const { panel, opener, focusReturnId } = await openProductionDeliveryQuickView(page);
    const connectedUrl = page.url();
    expect(await page.locator("[data-phx-main]").getAttribute("class")).toMatch(/phx-connected/);
    await panel.getByRole("link", { name: "Close quick view" }).click();
    await expect(panel).toHaveCount(0);
    await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe(focusReturnId);
    await expect(opener).toBeFocused();
    receipt.hooks = {
      caseId: "hook:storybook-host-connected-and-production-quick-view-focus-return",
      storyHostConnected: true,
      connectedUrl,
      connectedThemeOwner: await page.locator(".mg-admin-root").first().getAttribute("data-theme-owner"),
      quickViewClosed: true,
      exactFocusReturnId: focusReturnId
    };
    receipt.executedCaseIds.push(receipt.hooks.caseId);
    receipt.urls = { storyUrl, storyIframeUrl, connectedUrl };
    receipt.zoom = zoomEvidence;
    expect(receipt.executedCaseIds).toHaveLength(receipt.expectedCaseCount);
    receipt.completedCaseCount = receipt.executedCaseIds.length;
    appendPhase175FidelityEvidence(receipt);
    const persistedReceipt = JSON.parse(fs.readFileSync(PHASE175_FIDELITY_PATH, "utf8"));
    expect(persistedReceipt.source, "the persisted Phase 175 receipt names this run's current source").toEqual(source);
    expect([...persistedReceipt.executedCaseIds].sort(), "the persisted Phase 175 receipt contains the current run's cases")
      .toEqual([...receipt.executedCaseIds].sort());
    console.log(`PHASE175_FIDELITY_RECEIPT ${JSON.stringify(receipt)}`);
  } finally {
    await context.close();
  }
});
