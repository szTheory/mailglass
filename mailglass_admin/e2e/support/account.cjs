// Visible-only locators for the Account control.
//
// The sidebar copy and the mobile-band copy of the scope group are both in the
// DOM at every width (only CSS hides one), so a bare getByTestId() matches two
// elements and Playwright strict mode rejects it. These helpers filter to the
// copy the viewport actually shows.

function visibleByTestId(page, testId) {
  return page.getByTestId(testId).filter({ visible: true });
}

function accountSwitcher(page) {
  return visibleByTestId(page, "operator-account-switcher");
}

function accountOption(page, id) {
  return page
    .locator(`[data-testid="operator-account-option"][data-account-id="${id}"]`)
    .filter({ visible: true });
}

function accountLabel(page) {
  return visibleByTestId(page, "operator-account-label");
}

module.exports = { visibleByTestId, accountSwitcher, accountOption, accountLabel };
