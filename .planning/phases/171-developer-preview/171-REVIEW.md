---
phase: 171-developer-preview
reviewed: 2026-10-09T15:26:06Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - brandbook/copy/microcopy.md
  - guides/preview.md
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/lib/mailglass_admin/controllers/assets.ex
  - mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex
  - mailglass_admin/lib/mailglass_admin/preview/device_frame.ex
  - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
  - mailglass_admin/lib/mailglass_admin/preview/tabs.ex
  - mailglass_admin/lib/mailglass_admin/preview_live.ex
  - mailglass_admin/priv/static/app.css
  - mailglass_admin/test/mailglass_admin/discovery_test.exs
  - mailglass_admin/test/mailglass_admin/preview_live_test.exs
  - mailglass_admin/test/mailglass_admin/voice_test.exs
  - mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs
  - mailglass_admin/test/support/fixtures/mailables.ex
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 171: Code Review Report

**Reviewed:** 2026-10-09T15:26:06Z  
**Depth:** standard  
**Files Reviewed:** 15  
**Status:** issues_found

## Summary

Reviewed the 15-file phase scope, including the preview LiveView, its components, assets, docs, and focused tests. The phase evaluation-scope resolver returned `degraded` (`no-task-commit-rows`); its file list matched the supplied scope and summary extraction. Three defects make generated preview header/MIME output misleading for some valid messages.

## Warnings

### WR-01: Header existence checks are case-sensitive

**Classification:** WARNING  
**File:** `mailglass_admin/lib/mailglass_admin/preview_live.ex:1114`  
**Issue:** RFC header names are case-insensitive, but `ensure_header/3` compares with exact string equality. A message that supplies `message-id` or `date` in lowercase is treated as missing that header, so the Headers and Raw tabs show a duplicate semantic header alongside the supplied value.  
**Fix:** Compare normalized names, for example `String.downcase(to_string(k)) == String.downcase(name)`, and preserve the scenario's original header entry when a match exists.

### WR-02: Generated Date value is not an RFC mail date

**Classification:** WARNING  
**File:** `mailglass_admin/lib/mailglass_admin/preview_live.ex:1127-1132`  
**Issue:** `DateTime.to_string/1` emits an ISO-style value such as `2026-10-09 12:00:00Z`, which is not the RFC 5322 `Date` header format. The Headers tab and illustrative envelope therefore show an invalid representative mail header.  
**Fix:** Format the value with an RFC 5322 date formatter, including weekday and numeric zone, such as `Calendar.strftime(dt, "%a, %d %b %Y %H:%M:%S +0000")` after converting to UTC.

### WR-03: Raw preview invents MIME parts for absent bodies

**Classification:** WARNING  
**File:** `mailglass_admin/lib/mailglass_admin/preview_live.ex:1058-1073`  
**Issue:** The Raw tab always declares `multipart/alternative` and emits both text and HTML parts, even when either body is absent. For a valid HTML-only or text-only message, this displays an empty part that the source message does not contain and can conceal the missing-body condition the preview is meant to expose.  
**Fix:** Build the part list from the bodies actually present and select the matching `Content-Type`; if this panel intentionally remains schematic, show an explicit placeholder for each absent body instead of presenting it as an emitted MIME part.

---

_Reviewed: 2026-10-09T15:26:06Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
