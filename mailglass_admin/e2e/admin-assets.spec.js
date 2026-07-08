const { test, expect } = require("@playwright/test");

const tenantId = "browser-tenant";
const baseURL =
  process.env.OPERATOR_BASE_URL ||
  `http://127.0.0.1:${process.env.BROWSER_SERVER_PORT || "4101"}`;

const routeCases = [
  {
    name: "preview index",
    path: "/dev/mail",
    mountRoot: "/dev/mail",
    access: "public",
    ready: async page => {
      await expect(page.getByTestId("preview-shell")).toBeVisible();
    }
  },
  {
    name: "preview query",
    path: "/dev/mail?theme=dark",
    mountRoot: "/dev/mail",
    access: "public",
    ready: async page => {
      await expect(page.getByTestId("preview-shell")).toBeVisible();
    }
  },
  {
    name: "preview scenario",
    path: "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=375&theme=dark",
    mountRoot: "/dev/mail",
    access: "public",
    ready: async page => {
      await expect(page.getByTestId("preview-shell")).toBeVisible();
      await expect(page.getByTestId("preview-header-controls")).toBeVisible();
    }
  },
  {
    name: "preview error",
    path: "/dev/mail/MailglassAdmin.Fixtures.BrokenMailer/__error__?theme=light",
    mountRoot: "/dev/mail",
    access: "public",
    ready: async page => {
      await expect(page.getByTestId("preview-shell")).toBeVisible();
      await expect(page.getByTestId("preview-render-error")).toBeVisible();
    }
  },
  {
    name: "gallery",
    path: "/dev/mail/gallery",
    mountRoot: "/dev/mail",
    access: "public",
    ready: async page => {
      await expect(page.getByRole("heading", { name: "Component Gallery", level: 1 })).toBeVisible();
    }
  },
  {
    name: "bare operator",
    path: "/ops/mail",
    mountRoot: "/ops/mail",
    access: "operator",
    ready: async page => {
      await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();
    }
  },
  {
    name: "operator query",
    path: `/ops/mail?tenant_id=${tenantId}&view=deliveries&status=failed`,
    mountRoot: "/ops/mail",
    access: "operator",
    ready: async page => {
      await expect(
        page.getByRole("heading", { name: "Deliveries", exact: true, level: 1 })
      ).toBeVisible();
    }
  },
  {
    name: "bare inbound",
    path: "/ops/mail/inbound",
    mountRoot: "/ops/mail",
    access: "operator",
    ready: async page => {
      await expect(page.getByRole("heading", { name: "Inbound records", level: 1 })).toBeVisible();
    }
  },
  {
    name: "inbound query",
    path: `/ops/mail/inbound?tenant_id=${tenantId}&provider=ses`,
    mountRoot: "/ops/mail",
    access: "operator",
    ready: async page => {
      await expect(page.getByRole("heading", { name: "Inbound records", level: 1 })).toBeVisible();
    }
  },
  {
    name: "alternate preview",
    path: "/alt/dev/console/MailglassAdmin.Fixtures.HappyMailer/welcome_default?theme=dark",
    mountRoot: "/alt/dev/console",
    access: "public",
    ready: async page => {
      await expect(page.getByTestId("preview-shell")).toBeVisible();
      await expect(page.getByTestId("preview-header-controls")).toBeVisible();
    }
  },
  {
    name: "alternate operator",
    path: `/secure/console?tenant_id=${tenantId}&view=deliveries`,
    mountRoot: "/secure/console",
    access: "operator",
    ready: async page => {
      await expect(
        page.getByRole("heading", { name: "Deliveries", exact: true, level: 1 })
      ).toBeVisible();
    }
  },
  {
    name: "alternate inbound",
    path: `/secure/console/inbound?tenant_id=${tenantId}&provider=ses`,
    mountRoot: "/secure/console",
    access: "operator",
    ready: async page => {
      await expect(page.getByRole("heading", { name: "Inbound records", level: 1 })).toBeVisible();
    }
  }
];

function absoluteURL(path) {
  return new URL(path, baseURL).toString();
}

function isTrackedAssetRequest(request) {
  const type = request.resourceType();
  return type === "stylesheet" || type === "font";
}

async function loginOperatorForAssetRoute(page, targetPath) {
  await page.context().clearCookies();

  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok(), "operator browser fixture reset").toBeTruthy();

  const loginParams = new URLSearchParams({
    tenant_id: tenantId,
    return_to: "/ops/browser-ready",
    subject_id: "operator-1"
  });

  await page.goto(absoluteURL(`/ops/browser-login?${loginParams.toString()}`));
  await expect(page.locator("body")).toHaveText("ok");

  expect(targetPath, "operator target path is supplied after login").toBeTruthy();
}

function collectAssetResponses(page, expectedMountRoot) {
  const failures = [];
  const responses = [];
  const responseTasks = [];

  const onRequestFailed = request => {
    if (!isTrackedAssetRequest(request)) return;

    failures.push({
      type: request.resourceType(),
      url: request.url(),
      error: request.failure()?.errorText || "unknown request failure"
    });
  };

  const onResponse = response => {
    const request = response.request();
    if (!isTrackedAssetRequest(request)) return;

    responseTasks.push(
      response.headerValue("content-type").then(contentType => {
        responses.push({
          type: request.resourceType(),
          url: response.url(),
          status: response.status(),
          contentType: contentType || ""
        });
      })
    );
  };

  page.on("requestfailed", onRequestFailed);
  page.on("response", onResponse);

  return {
    async assert(routeCase) {
      await Promise.all(responseTasks);

      expect(failures, `${routeCase.name} stylesheet/font request failures`).toEqual([]);

      const stylesheetResponses = responses.filter(response => response.type === "stylesheet");
      const fontResponses = responses.filter(response => response.type === "font");

      expect(
        stylesheetResponses.length,
        `${routeCase.name} observed stylesheet responses`
      ).toBeGreaterThan(0);
      expect(fontResponses.length, `${routeCase.name} observed font responses`).toBeGreaterThan(0);

      const expectedOrigin = new URL(page.url()).origin;

      for (const response of responses) {
        const url = new URL(response.url);

        expect(url.origin, `${routeCase.name} ${response.type} origin ${response.url}`).toBe(
          expectedOrigin
        );
        expect(response.status, `${routeCase.name} ${response.type} status ${response.url}`).toBe(
          200
        );

        if (response.type === "stylesheet") {
          expect(
            response.contentType,
            `${routeCase.name} stylesheet content-type ${response.url}`
          ).toContain("text/css");
          expect(
            url.pathname.startsWith(`${expectedMountRoot}/css-`),
            `${routeCase.name} stylesheet path ${url.pathname} must be under ${expectedMountRoot}/css-`
          ).toBeTruthy();
        } else {
          expect(response.contentType, `${routeCase.name} font content-type ${response.url}`).toContain(
            "font/woff2"
          );
          expect(
            url.pathname.startsWith(`${expectedMountRoot}/fonts/`),
            `${routeCase.name} font path ${url.pathname} must be under ${expectedMountRoot}/fonts/`
          ).toBeTruthy();
        }
      }
    },

    dispose() {
      page.off("requestfailed", onRequestFailed);
      page.off("response", onResponse);
    }
  };
}

async function assertDirectAssetLoad(page, routeCase) {
  if (routeCase.access === "operator") {
    await loginOperatorForAssetRoute(page, routeCase.path);
  } else {
    await page.context().clearCookies();
  }

  const assets = collectAssetResponses(page, routeCase.mountRoot);

  try {
    await page.goto(absoluteURL(routeCase.path));
    await routeCase.ready(page);
    await page.evaluate(() => document.fonts.ready.then(() => true));
    await assets.assert(routeCase);
  } finally {
    assets.dispose();
  }
}

test.describe("admin asset hard loads", () => {
  for (const routeCase of routeCases) {
    test(`admin asset hard load: ${routeCase.name}`, async ({ page }) => {
      await assertDirectAssetLoad(page, routeCase);
    });
  }
});
