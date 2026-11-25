// Theme helpers for browser specs that exercise the root-only theme owner.
//
// The admin theme is a cookie (`mailglass_admin_theme_v2`: "light" | "dark";
// absent means System) read by the root layout, which writes it onto `<html>`.
// A System page follows the emulated OS `prefers-color-scheme`.
//
// `applyThemeEmulation` is copied verbatim from structural.spec.js so the two
// stay interchangeable; per-file duplication in that spec is intentional, new
// specs import this module instead.

const THEME_COOKIE = "mailglass_admin_theme_v2";

const baseURL =
  process.env.OPERATOR_BASE_URL ||
  `http://127.0.0.1:${process.env.BROWSER_SERVER_PORT || "4101"}`;

// For the `system` theme, the OS prefers-color-scheme media query must be set to
// dark BEFORE navigation so the system branch resolves to dark (A16-system).
// emulateMedia MUST precede navigation (the FACT-4 pattern already used in structural.spec.js).
async function applyThemeEmulation(page, theme) {
  if (theme === "system") {
    await page.emulateMedia({ colorScheme: "dark" });
  } else {
    await page.emulateMedia({ colorScheme: null });
  }
}

// Adds (or, with a null value, clears) only the theme cookie. A login helper that
// calls `clearCookies()` removes it, so set the cookie AFTER login.
async function setThemeCookie(page, value) {
  const context = page.context();
  if (value === null || value === undefined) {
    await context.clearCookies({ name: THEME_COOKIE });
    return;
  }
  await context.addCookies([{ name: THEME_COOKIE, value, url: baseURL }]);
}

// Navigates to `url` with the OS colour scheme emulated first, then the theme
// cookie set (null = System), and waits for the LiveView to connect.
//
//   cookie: "light" | "dark" | null
//   os:     "light" | "dark"
async function openInTheme(page, url, { cookie = null, os = "light", waitForLiveView = true } = {}) {
  await page.emulateMedia({ colorScheme: os });
  await setThemeCookie(page, cookie);
  await page.goto(url);
  if (waitForLiveView) {
    await page.locator("[data-phx-main].phx-connected").waitFor({ state: "visible" });
  }
}

module.exports = { applyThemeEmulation, setThemeCookie, openInTheme, THEME_COOKIE };
