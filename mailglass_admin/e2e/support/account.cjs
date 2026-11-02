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

// Options live inside a closed <details> until the switcher opens, so they are
// scoped through the visible scope group instead of being visibility-filtered
// themselves; that keeps attribute reads (href) working on a closed menu.
function accountOption(page, id) {
  return visibleByTestId(page, "surface-nav-scope-group").locator(
    `[data-testid="operator-account-option"][data-account-id="${id}"]`
  );
}

function accountLabel(page) {
  return visibleByTestId(page, "operator-account-label");
}

// The Account control block (label, switcher or static text, switch status) of
// the copy the viewport shows.
function accountContext(page) {
  return visibleByTestId(page, "operator-account-context");
}

// The sr-only selected-Account id. It is scoped through the visible scope
// group, because an sr-only element has a 1px box and the hidden copy must
// not be matched.
function accountId(page) {
  return visibleByTestId(page, "surface-nav-scope-group").getByTestId("operator-account-id");
}

// The pending "Switching to {name}" status elements of the visible copy. They
// are `hidden` until a click reveals one, so they are scoped through the
// visible scope group instead of being visibility-filtered themselves.
function accountSwitchStatus(page) {
  return visibleByTestId(page, "surface-nav-scope-group").getByTestId(
    "operator-account-switch-status"
  );
}

// Ids of the switch-status elements: `operator-account-switch-status-<layout>-<n>`,
// with a safe numeric token independent of the Account id.
const switchStatusIdPattern = /^operator-account-switch-status-(sidebar|mobile)-\d+$/;

module.exports = {
  visibleByTestId,
  accountSwitcher,
  accountOption,
  accountLabel,
  accountContext,
  accountId,
  accountSwitchStatus,
  switchStatusIdPattern
};
