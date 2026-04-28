# DKIM Setup

This guide covers the Mailglass-specific DKIM checks that matter for RFC 8058 unsubscribe. The core rule is simple: if you ship one-click unsubscribe, both unsubscribe headers must be covered by the DKIM `h=` list.

## 1) Required headers for RFC 8058

For Mailglass unsubscribe flows, verify that your ESP signs both of these headers:

- `List-Unsubscribe`
- `List-Unsubscribe-Post`

Signing only `List-Unsubscribe` is not enough for RFC 8058 one-click behavior. Mailbox-provider UI may ignore the POST contract if `List-Unsubscribe-Post` is missing from the DKIM-covered header set.

## 2) What to check in a delivered message

Inspect the raw delivered message or your ESP diagnostics and confirm the DKIM signature's `h=` list contains both header names.

Example shape:

```text
h=from:to:subject:date:list-unsubscribe:list-unsubscribe-post:mime-version;
```

Case does not matter, but both header names must be present.

## 3) ESP notes

### Postmark

Postmark is the expected happy path. After Mailglass injects both unsubscribe headers, verify in Postmark's delivered-message diagnostics that both headers appear in the DKIM `h=` list before calling rollout complete.

### SendGrid

SendGrid has a known historical gap around `List-Unsubscribe-Post` coverage. Do not assume RFC 8058 compliance from code alone. Check the Event Webhook or message diagnostics for a delivered message and confirm `List-Unsubscribe-Post` is actually signed before rollout.

If SendGrid signs only `List-Unsubscribe`, treat that as a rollout blocker for one-click unsubscribe.

## 4) Rollout checklist

1. Send a real bulk message through the target ESP.
2. Open the provider's raw-message or diagnostics view.
3. Find the DKIM `h=` list.
4. Verify `list-unsubscribe` is present.
5. Verify `list-unsubscribe-post` is present.
6. Keep evidence of the check with your release notes or UAT record.

## 5) Common failure modes

### Headers exist but mailbox UI still hides one-click unsubscribe

- Confirm both headers are present on the message.
- Confirm both headers are DKIM-signed, not just emitted.
- Confirm you are testing a `:bulk` message or an opted-in `:operational` message.

### ESP documentation says it supports List-Unsubscribe

That is not enough. Mailglass requires verification against a delivered message because RFC 8058 rollout depends on the signed `List-Unsubscribe-Post` header, not marketing copy in provider docs.
