---
phase: 177-readable-health-and-coherent-account-navigation
reviewed: 2026-10-28T00:00:00Z
depth: standard
files_reviewed: 17
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/preview/return_context.ex
  - mailglass_admin/lib/mailglass_admin/controllers/theme_controller.ex
  - mailglass_admin/lib/mailglass_admin/preview_live.ex
  - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
  - mailglass_admin/lib/mailglass_admin/surface_nav.ex
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/lib/mailglass_admin/operator/health_overview.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/router.ex
  - mailglass_admin/assets/css/app.css
  - reference/demo_app/lib/mailglass_demo_web/admin_auth.ex
  - reference/demo_app/lib/mailglass_demo_web/router.ex
  - reference/persona_spec/quick_view_scenarios.ex
  - mailglass_admin/test/support/endpoint_case.ex
  - mailglass_admin/e2e/support/account.cjs
findings:
  critical: 0
  warning: 1
  info: 4
  total: 5
status: issues_found
---

# Phase 177: Code Review Report

**Reviewed:** 2026-10-28
**Depth:** standard
**Files Reviewed:** 16 (the 17 required-reading entries, minus CLAUDE.md and CONTEXT.md, plus `inbound_live.ex`/`router.ex` diffs)
**Status:** issues_found

## Summary

The security-sensitive parts hold up. I traced each attack surface against the code.

- **Open redirect (UXF-10).** The Back destination is built only from host `navigation` plus a percent-encoded `tenant_id`. The `return_surface` value is matched as a string against a closed set, so no atom is created from request input. `local_path?/1` rejects scheme, host, `//` prefix, backslash and control characters. The request never supplies a URL.
- **Tenant scoping and authorization.** The Back link grants no authority. Arrival re-runs `Operator.Mount` and `Auth.authorize(:operator_access, %{params: ...})`, and the demo `AdminAuth` and `TestOperatorAuth` deny clauses are consistent with that.
- **Session maps.** `router.ex` changes docs only. The session whitelists are untouched.
- **Theme redirect (D-08).** The segment-boundary check, `//` and backslash rejection, and dot-segment rejection (including `%2e` spellings) are correct.
- **HTML escaping and PII.** All interpolated values go through HEEx attribute or text escaping. No telemetry was added and no Account identity is rendered on Preview.
- **Demo login redirect.** `AdminAuth.return_path/1` feeds the demo login's `safe_return_to/1`, which still restricts redirects to `/ops/mail*`.

The defects I found are all in the Account control's no-choice logic. They are one WARNING item and four INFO items. None is a security issue.

## Warnings

### WR-01: Single-option Account control renders a fake "selected" identity and removes the only way to switch

**File:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex:381-391`
**Issue:** `account_variant([only], _state, selected)` returns `{:static, selected || only.label, :named}` regardless of `tenant_state`. This breaks two cases.

1. **`:select_required` with exactly one option.** `OperatorLive.tenant_state(nil, [_tenant], true)` and the Inbound equivalent return `:select_required` when `?tenant_id=` is present but blank. No Account is selected and the body shows the tenant selector. The header still renders the sole Account's name in bold, as if it were the active scope. The scoped Health, Deliveries and Inbound links carry no `tenant_id`. The header therefore claims a scope that does not exist.
2. **Selected Account differs from the sole listed option.** `tenant_options` is activity-derived (D-05 note). A host-authorized operator can deep-link to `?tenant_id=quiet-account` while the list holds only `[busy-account]`. The header shows "quiet-account" with no picker, so the operator cannot reach `busy-account` from the control. The previous implementation offered a one-item menu in this case. D-10 removes the picker only when there is no choice, and here there is one.

**Fix:** Collapse to the static variant only when the single option is the selected Account or auto-select is pending. Otherwise keep the picker.

```elixir
defp account_variant([only], state, selected)
     when state in [:auto_select, :selected, nil] and (is_nil(selected) or selected == only.id),
     do: {:static, only.label, :named}

# one option that is not the selection, or select_required: a real choice remains
defp account_variant([_only], _state, _selected), do: :picker
```

For the `:select_required` + `[only]` case, also render the static text with `:prompt` tone ("Choose an Account") rather than the Account's name. Add a connected test for both shapes.

## Info

### IN-01: Invalid HTML content model in the observation group

**File:** `mailglass_admin/lib/mailglass_admin/operator/health_overview.ex:~252-262`
**Issue:** `<span class="inline-flex ...">` wraps a `<p data-testid="operator-health-last-checked">`. A `<p>` is flow content and is invalid inside a `<span>`. Browsers tolerate it, but HTML validators and some axe configurations flag it.
**Fix:** Change the wrapper `<span>` to a `<div>`, or change the `<p>` to a `<span>`. Keep the `data-testid`.

### IN-02: Scope group accessible name absorbs the sr-only Account id

**File:** `mailglass_admin/lib/mailglass_admin/surface_nav.ex:67-80` with `operator/shell.ex:362-364`
**Issue:** The group uses `aria-labelledby={@header_id}`, and that header element contains the whole `account_context`. This includes the `sr-only` `operator-account-id` span, which holds the raw `tenant_id`. The computed group name becomes something like "Account Northstar northstar". D-13 intends the header label to name the group.
**Fix:** Point `aria-labelledby` at a smaller element, for example the label span, or move the sr-only id span outside the header region.

### IN-03: Header `aria-describedby` can reference an empty description

**File:** `mailglass_admin/lib/mailglass_admin/surface_nav.ex:156-167`
**Issue:** When the host configures no scoped paths, `description([])` returns `""`. The group still carries `aria-describedby` pointing at an empty `sr-only` span. This is harmless but not clean.
**Fix:** Render `aria-describedby` only when `@description != ""`.

### IN-04: Operator Account control does not trim whitespace-only Account ids

**File:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex:385-388`
**Issue:** The shell's `blank_to_nil/1` guards only `nil` and `""`. A whitespace-only `selected_tenant_id` (if the LiveView passes one through) would render as a named bold label with blank text. Not confirmed reachable end to end; the LiveView-side handling was not traced.

The same gap applies to `selected_label` in `account_context/1`, where `blank_to_nil(Accounts.label(...))` does not trim. `ReturnContext.valid_tenant_id?/1` correctly rejects blank ids (`String.trim(id) != ""`), but the operator-side control does not apply the same standard.

**Fix:** Trim in the shell's `blank_to_nil/1`, or reuse `ReturnContext.valid_tenant_id?/1` before treating a value as a named Account.

```elixir
defp blank_to_nil(value) when is_binary(value) do
  if String.trim(value) == "", do: nil, else: value
end
defp blank_to_nil(nil), do: nil
defp blank_to_nil(value), do: value
```

---

_Reviewed: 2026-10-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
