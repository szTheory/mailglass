# mailglass microcopy

UX strings for the seven domain nouns, four states each. The strings are
keyed to the normalized event taxonomy (queued, sent, rejected, failed,
bounced, deferred, delivered, autoresponded, opened, clicked, complained,
unsubscribed, subscribed, unknown) and they respect the load-bearing
distinction: **dispatched** means handed to the provider; **delivered**
means the destination accepted it. Errors name the cause and stay composed.
Empty states say what will appear and how to cause it. Success states
confirm the observed fact, in past tense — an Event is a fact, not a hope.

## Mailable

| State | Copy |
|---|---|
| Error | Mailable failed to render: the template raised before a Message could be built. The error and stack trace are in your logs. |
| Empty | No mailables discovered yet. Define one with `mix mailglass.gen.mailable` and it will appear here, ready to preview. |
| Success | Mailable rendered. The Message preview below is exactly what a recipient would receive. |
| Warning | This mailable has no text body. Many clients and most spam filters expect a text part alongside the HTML. |

## Message

| State | Copy |
|---|---|
| Error | Message rejected: the provider refused it before handoff, with reject_reason: invalid — the recipient address did not parse. Nothing was dispatched. |
| Empty | No messages rendered yet. Render a mailable — in the preview, or by sending it — and the resulting message appears here. |
| Success | Message rendered with both HTML and text parts. |
| Warning | This message's HTML is close to 102 KB. Gmail clips messages that large; trim it before sending. |

## Delivery

| State | Copy |
|---|---|
| Error | Delivery blocked: recipient is on the suppression list. Remove the Suppression first if this send is genuinely wanted. |
| Empty | No deliveries yet for this message. Send it, and each recipient gets its own delivery record here. |
| Success | Delivery dispatched: the provider accepted the message. Dispatched is not delivered — watch for the delivered event to confirm the destination accepted it. |
| Warning | Delivery deferred: the destination asked the provider to retry. No action needed yet; a delivered or bounced event will settle it. |

## Event

| State | Copy |
|---|---|
| Error | Event could not be mapped: the payload matched no known provider shape. It was recorded as unknown with the raw payload attached, so nothing is lost. |
| Empty | No events yet. Events arrive when your provider reports back — queued, sent, delivered, bounced — usually within seconds of dispatch. |
| Success | Event recorded: delivered. The downstream mail system accepted the message. |
| Warning | Event recorded: complained. The recipient marked this mail as spam, and a suppression was added so they will not be emailed again. |

## InboundMessage

| State | Copy |
|---|---|
| Error | InboundMessage rejected: the webhook signature did not verify. Unverified payloads are never processed. |
| Empty | No inbound messages yet. Point your provider's inbound webhook at this endpoint and received mail will appear here. |
| Success | InboundMessage routed: a mailbox matched its address and processed it. |
| Warning | InboundMessage received, but no mailbox matched its address. It was kept; add a route if it should be processed. |

## Mailbox

| State | Copy |
|---|---|
| Error | Mailbox raised while processing. The inbound message is preserved, so you can fix the handler and process it again. |
| Empty | No mailboxes defined. Generate one with `mix mailglass.gen.mailbox` to start routing inbound mail. |
| Success | Mailbox processed the inbound message. |
| Warning | Mailbox took unusually long to process the last inbound message. Long work belongs in a background job; the webhook should return quickly. |

## Suppression

| State | Copy |
|---|---|
| Error | Suppression resync failed: the provider could not be reached, so the local suppression list was left unchanged. Retry with `mix mailglass.suppressions.resync` once the provider responds. |
| Empty | No suppressions. Addresses land here automatically when mail hard-bounces or a recipient complains or unsubscribes — and sends to them stop. |
| Success | Suppression added: unsubscribed. Future sends to this address will be blocked before dispatch. |
| Warning | This suppression was added manually rather than by an event. It is honored like any other, but record the reason somewhere durable — the ledger only explains what providers reported. |
