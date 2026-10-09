const { test, expect } = require("@playwright/test");

test.describe("mailglass demo evidence", () => {
  test.beforeEach(async ({ request }) => {
    const response = await request.post("/demo/evidence/reset", {
      headers: {
        "x-mailglass-demo-reset-token": process.env.DEMO_EVIDENCE_RESET_TOKEN || "",
      },
    });
    expect(response.ok()).toBeTruthy();
  });

  test("built-in unsubscribe pages keep their copy within narrow viewports", async ({ page }) => {
    const states = [
      {
        name: "valid",
        heading: "Unsubscribe",
        copy: "You have not been unsubscribed. Visiting this page does not change your subscription.",
        nextStep: "To unsubscribe, use your mail app's unsubscribe control when available, or contact the sender using the details in the message.",
      },
      {
        name: "invalid",
        heading: "This unsubscribe link is not valid.",
        copy: "Check the message for a current link, or contact the sender using the details in the message.",
      },
      {
        name: "expired",
        heading: "This unsubscribe link has expired.",
        copy: "Use your mail app's unsubscribe control when available, or contact the sender using the details in the message.",
      },
    ];

    for (const state of states) {
      for (const width of [320, 160]) {
        await page.setViewportSize({ width, height: 900 });
        await page.goto(`/dev/unsubscribe/${state.name}`);
        await expect(page.getByRole("heading", { name: state.heading, exact: true })).toBeVisible();
        await expect(page.getByText(state.copy, { exact: true })).toBeVisible();
        if (state.nextStep) {
          await expect(page.getByText(state.nextStep, { exact: true })).toBeVisible();
        }

        const geometry = await page.evaluate(() => {
          const documentElement = document.documentElement;
          const main = document.querySelector("main");
          const paragraphs = Array.from(document.querySelectorAll("main p"));

          return {
            scrollWidth: documentElement.scrollWidth,
            viewportWidth: documentElement.clientWidth,
            mainLeft: main.getBoundingClientRect().left,
            mainRight: main.getBoundingClientRect().right,
            clippedParagraphs: paragraphs.filter(
              (paragraph) => paragraph.scrollWidth > paragraph.clientWidth + 1,
            ).length,
          };
        });

        expect(geometry.scrollWidth).toBeLessThanOrEqual(geometry.viewportWidth);
        expect(geometry.mainLeft).toBeGreaterThanOrEqual(0);
        expect(geometry.mainRight).toBeLessThanOrEqual(geometry.viewportWidth + 1);
        expect(geometry.clippedParagraphs).toBe(0);
      }
    }
  });

  test("dashboard links to preview and operator surfaces", async ({ page }) => {
    await page.goto("/");
    await expect(
      page.getByRole("heading", { name: "Explore Mailglass in a working app", exact: true }),
    ).toBeVisible();
    await expect(page.getByText("AtlasDesk", { exact: false }).first()).toBeVisible();
    await expect(page.getByText("Email deliveries", { exact: true })).toBeVisible();

    const headingBox = await page
      .getByRole("heading", { name: "Explore Mailglass in a working app", exact: true })
      .boundingBox();
    const introBox = await page.getByTestId("dashboard-intro").boundingBox();
    const statsBox = await page.locator('[aria-label="Seeded demo data"]').boundingBox();

    expect(headingBox).not.toBeNull();
    expect(introBox).not.toBeNull();
    expect(statsBox).not.toBeNull();
    expect(introBox.y).toBeGreaterThan(headingBox.y + headingBox.height - 1);
    expect(statsBox.y).toBeGreaterThan(introBox.y + introBox.height - 1);

    await page.getByRole("link", { name: /preview emails/i }).click();
    await expect(page).toHaveURL(/\/dev\/mail\/MailglassDemoWeb\.Mailers\.AccountMailer\/invite_admin/);
    await expect(page.getByTestId("admin-shell-page-header")).toBeVisible();
    await expect(page.getByTestId("preview-email-menu-trigger")).toBeVisible();
    await expect(page.getByTestId("preview-email-menu-trigger")).toContainText("AccountMailer");
  });

  test("preview distinguishes the public component and AtlasDesk HTML authoring paths", async ({ page }) => {
    await page.setViewportSize({ width: 1024, height: 900 });
    await page.goto(
      "/dev/mail/MailglassDemoWeb.Mailers.AccountMailer/invite_admin?width=375",
    );

    await expect(page.getByTestId("preview-email-menu-active-identity")).toContainText("AccountMailer");
    const frameSelector = 'iframe[title="Email HTML preview — browser rendering only"]';
    let emailFrame = page.frameLocator(frameSelector);
    await expect(emailFrame.locator('[data-brand="AtlasDesk"]')).toBeVisible();
    await expect(emailFrame.locator("h1")).toContainText("Join Northstar Logistics");

    const invoiceOption = page
      .getByTestId("preview-email-menu-panel")
      .getByTestId("preview-email-menu-option")
      .filter({ hasText: "invoice_ready" });
    await expect(invoiceOption).toHaveAttribute(
      "href",
      "/dev/mail/MailglassDemoWeb.Mailers.ComponentMailer/invoice_ready?width=375",
    );
    await page.goto(
      "/dev/mail/MailglassDemoWeb.Mailers.ComponentMailer/invoice_ready?width=375",
    );

    await expect(page).toHaveURL(/\/MailglassDemoWeb\.Mailers\.ComponentMailer\/invoice_ready\?width=375$/);
    await expect(page.getByTestId("preview-email-menu-active-identity")).toContainText("ComponentMailer");
    await expect(page.getByTestId("preview-email-menu-active-identity")).toContainText("invoice_ready");

    await expect(emailFrame.locator("h1")).toContainText("Invoice INV-2026-0601 is ready");
    await expect(emailFrame.locator("body")).toContainText("Élodie Fernández-Sørensen");
    await expect(emailFrame.locator("body")).toContainText("AtlasDesk");
    await expect(emailFrame.getByRole("link", { name: /Review invoice INV-2026-0601/ })).toBeVisible();
    await expect(
      emailFrame.getByRole("link", { name: "Download the itemized invoice" }),
    ).toHaveAttribute(
      "href",
      "https://app.atlasdesk.example/invoices/INV-2026-0601/download",
    );
    await expect(emailFrame.locator("img")).toHaveAttribute(
      "alt",
      "Illustration of the May 2026 invoice summary for Northstar Logistics",
    );

    await page.setViewportSize({ width: 320, height: 900 });
    await page.locator(frameSelector).evaluate((iframe) => {
      iframe.style.width = "320px";
    });
    emailFrame = page.frameLocator(frameSelector);
    await expect(page.locator(frameSelector)).toBeAttached();
    await expect(emailFrame.locator("h1")).toContainText("Invoice INV-2026-0601 is ready");

    const publicOutput = await page.locator(frameSelector).evaluate((iframe) => {
      const document = iframe.contentDocument;
      const body = document.body;

      return {
        html: body.innerHTML,
        scrollWidth: document.documentElement.scrollWidth,
        viewportWidth: document.documentElement.clientWidth,
        overflowingElements: Array.from(document.querySelectorAll("body *"))
        .map((element) => {
          const rect = element.getBoundingClientRect();
          return {
            tag: element.tagName,
            width: rect.width,
            right: rect.right,
            attrWidth: element.getAttribute("width"),
            style: element.getAttribute("style"),
            text: element.textContent.trim().slice(0, 40),
          };
        })
          .filter((element) => element.right > document.documentElement.clientWidth + 1)
          .slice(0, 8),
      };
    });
    expect(publicOutput.html).toContain('table role="presentation" width="100%"');
    expect(publicOutput.html).toContain("max-width:600px;width:100%");
    expect(publicOutput.html).toContain("v:roundrect");
    expect(publicOutput.html).not.toContain('data-brand="AtlasDesk"');
    expect(
      publicOutput.scrollWidth,
      JSON.stringify({ viewportWidth: publicOutput.viewportWidth, overflowingElements: publicOutput.overflowingElements }),
    ).toBeLessThanOrEqual(publicOutput.viewportWidth);

    const pageOverflow = await page.evaluate(
      () => document.documentElement.scrollWidth - document.documentElement.clientWidth,
    );
    expect(pageOverflow).toBeLessThanOrEqual(0);

    // A 2× zoom on the rendered email keeps the same live text and link available.
    await emailFrame.locator("html").evaluate((html) => {
      html.style.zoom = "2";
    });
    await expect(emailFrame.locator("h1")).toContainText("Invoice INV-2026-0601 is ready");
    await expect(emailFrame.getByRole("link", { name: "Download the itemized invoice" })).toBeVisible();

    await page.setViewportSize({ width: 1024, height: 900 });
    const existingOption = page
      .getByTestId("preview-email-menu-panel")
      .getByTestId("preview-email-menu-option")
      .filter({ hasText: "invite_admin" });
    await expect(existingOption).toHaveAttribute(
      "href",
      "/dev/mail/MailglassDemoWeb.Mailers.AccountMailer/invite_admin?width=375",
    );
    await page.goto(
      "/dev/mail/MailglassDemoWeb.Mailers.AccountMailer/invite_admin?width=375",
    );
    await expect(page).toHaveURL(/\/MailglassDemoWeb\.Mailers\.AccountMailer\/invite_admin\?width=375$/);
    await page.setViewportSize({ width: 320, height: 900 });
    await page.locator(frameSelector).evaluate((iframe) => {
      iframe.style.width = "320px";
    });
    await expect(
      page.frameLocator(frameSelector).locator('[data-brand="AtlasDesk"]'),
    ).toBeVisible();
    const bespokeWidth = await page
      .frameLocator(frameSelector)
      .locator("body")
      .evaluate(() => document.documentElement.scrollWidth);
    expect(bespokeWidth).toBeLessThanOrEqual(320);
  });

  test("outbound operator opens with seeded delivery evidence", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("link", { name: /trace a sent email/i }).click();
    await expect(page).toHaveURL(/\/ops\/mail\?tenant_id=northstar/);
    await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
    // Navigate to Deliveries view to assert the list
    await page.goto("/ops/mail?tenant_id=northstar&view=deliveries");
    // Phase 113 (DATA-01) made operator-deliveries-list the mobile-only (md:hidden)
    // <ul>; assert the viewport-agnostic operator-deliveries-list-card <aside> wrapper.
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

    const deliveryId = await page.getByTestId("operator-delivery-row").first().getAttribute("phx-value-id");
    const returnTo = encodeURIComponent(
      `/ops/mail?tenant_id=northstar&delivery_id=${deliveryId}&full=1`,
    );
    await page.goto(`/demo/login?return_to=${returnTo}`);

    await expect(page.getByTestId("operator-detail-header")).toBeVisible();
    await expect(page.getByTestId("operator-timeline")).toBeVisible();
  });

  test("inbound operator opens with seeded support mailbox evidence", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("link", { name: /follow an inbound message/i }).click();
    await expect(page).toHaveURL(/\/ops\/mail\/inbound\?tenant_id=northstar/);
    await expect(page.getByRole("heading", { name: "Inbound records", exact: true })).toBeVisible();
    // Phase 113 (DATA-01): inbound-records-list is the mobile-only <ul>; assert the
    // viewport-agnostic inbound-records-list-card <aside> wrapper instead.
    await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();

    const inboundId = await page.getByTestId("inbound-record-row").first().getAttribute("phx-value-id");
    const returnTo = encodeURIComponent(
      `/ops/mail/inbound?tenant_id=northstar&inbound_id=${inboundId}&full=1`,
    );
    await page.goto(`/demo/login?return_to=${returnTo}`);
    await expect(page.getByTestId("inbound-detail-header")).toBeVisible();
  });
});
