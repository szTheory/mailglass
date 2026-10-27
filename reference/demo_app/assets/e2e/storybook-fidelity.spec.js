const { test, expect } = require("@playwright/test");
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
