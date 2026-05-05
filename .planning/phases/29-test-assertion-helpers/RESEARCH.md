# Phase 29: Test Assertion Helpers (Research & Architecture)

## Context
Phase 29 aims to provide developers with richer test assertion helpers for both outbound delivery verification (TEST-01) and webhook payload/idempotency verification (TEST-02). 

Currently, `Mailglass.TestAssertions` provides a good baseline (`assert_mail_sent/1` with keyword matching on `subject`, `to`, `mailable`, etc.) and `Mailglass.WebhookCase` provides `assert_webhook_ingested/1`. However, to achieve a DX on par with best-in-class frameworks (like Laravel's `Mail::fake()` or Rails' `ActionMailer::TestHelper`), we need to close a few specific ergonomic gaps.

---

## 1. Outbound Delivery Assertions (TEST-01)

### The Gap
Currently, `assert_mail_sent/1` matches on the resulting `%Message{}` attributes (`subject`, `to`, `stream`, etc.). However, developers often want to assert:
1. **Content Matching:** Did the rendered HTML/Text contain a specific string or regex?
2. **Assigns/Data Binding:** Was the mailable built with the correct domain data? (e.g., `assert_mail_sent(OrderMailable, order_id: 123)`). Currently, `%Mailglass.Message{}` does not retain the arguments/assigns used to invoke the mailable.

### Lessons Learned from the Ecosystem
- **Laravel (`Mail::assertSent`)**: Laravel allows you to assert against the Mailable object itself and its properties before it renders. This is incredible for DX because tests don't become brittle regex matches against HTML strings.
- **Rails (`assert_emails 1 do ...`)**: Rails counts deliveries in a block, and provides `assert_enqueued_email_with` to check the arguments passed to the job.
- **Swoosh (`assert_email_sent`)**: Swoosh allows matching on `html_body: ~r/Welcome/`, but it lacks semantic understanding of the data that generated the email.

### Recommendation
**A. Add `assigns` to `%Mailglass.Message{}`**
To achieve the "gold standard" of Mailable testing, we should add an `assigns: %{}` or `args: []` field to `%Mailglass.Message{}` that is populated when `MyApp.Mailer.welcome(user)` is called. 
* **Pros:** Tests become resilient. Instead of asserting `html_body: ~r/Jon/`, you assert `assert_mail_sent(mailable_function: :welcome, assigns: %{user: %{name: "Jon"}})`. This separates business logic testing from UI/view testing.
* **Cons:** Requires a minor structural change to `%Message{}` and the Mailable macro to capture arguments.

**B. Content Matchers**
We should also provide helpers for view testing:
- `assert_mail_html_matches(msg, ~r/invoice_1234/)`
- `assert_mail_text_matches(msg, "total: $10.00")`

---

## 2. Webhook & Idempotency Assertions (TEST-02)

### The Gap
`Mailglass.WebhookCase` provides `assert_webhook_ingested/1` to verify the PubSub broadcast. However, it requires the developer to manually construct `%Plug.Conn{}` using `mailglass_webhook_conn/3` and pipe it. Furthermore, testing idempotency (what happens if the same payload hits twice?) is manual.

### Lessons Learned from the Ecosystem
- **Stripe & Svix**: Provide local CLI endpoints or test helpers that simulate the exact HTTP POSTs, tracking not just the 200 OK, but the resulting state changes.

### Recommendation
**A. High-Level Webhook Simulation**
Introduce a helper that abstracts the Plug layer for integration tests:
```elixir
# Simulates receiving the webhook and blocks until the Projector updates the DB.
assert_webhook_processed(:sendgrid, "delivered", delivery_id: id)
```

**B. Idempotency Testing Helpers**
Introduce a helper specifically designed to fire a webhook payload twice and assert that the secondary processing is short-circuited (e.g., verifying `event_count` or asserting no duplicate Oban jobs are enqueued/no duplicate DB errors).
```elixir
assert_webhook_idempotent(:sendgrid, "delivered", delivery_id: id)
```

**C. Delivery State Assertions**
Introduce a direct DB state assertion to verify the final resting state of a delivery after webhooks are processed:
```elixir
assert_delivery_state(delivery.id, :delivered)
assert_delivery_event_count(delivery.id, 1)
```

---

## Conclusion & Next Steps
By treating the Mailable *data bindings* as testable artifacts (via an `assigns` field on the Message) rather than just the rendered output, and by providing one-liner webhook simulation/idempotency helpers, Mailglass will offer an operator DX that surpasses even Rails/Laravel, strictly tailored to the Elixir/Ecto ecosystem's strengths (pattern matching, PubSub verification).

**Proposed Action:** If aligned, we will proceed to `$gsd-plan-phase 29` using these architectural guidelines.