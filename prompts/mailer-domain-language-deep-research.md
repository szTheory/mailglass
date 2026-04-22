Below is markdown you can save as-is.

Phoenix Email Domain Language

A reference vocabulary for an Elixir email framework focused on transactional send, inbound/inbox, deliverability, suppression, and admin tooling — not campaigns, subscriber lists, or multi-channel notifications.

This guide assumes a few anchor decisions: keep Swoosh as the transport/testing substrate; treat Action Mailbox as the best precedent for inbound routing into controller-like mailboxes; borrow Anymail’s normalized webhook event vocabulary almost verbatim; make unsubscribe and suppression first-class because Gmail’s sender rules require one-click unsubscribe for high-volume subscribed/promotional mail; and normalize provider-specific inbound payloads behind a common ingress boundary because Postmark, SendGrid, and SES all expose inbound mail in provider-shaped webhook/notification forms.  ￼

⸻

1) Scope

In scope

* transactional send
* previewing and rendering
* delivery tracking
* suppression and unsubscribe
* inbound email
* inbox/thread concepts
* webhook normalization
* admin and replay tooling
* multi-tenant/provider routing

Out of scope by default

* campaigns
* subscriber lists
* segments
* automations/drips
* “unified notifications”
* channel fanout (email + sms + push)

Those can live in later companion packages. Do not let them infect the core vocabulary.

⸻

2) The model in one sentence

A Mailable renders a Message.
A Message creates one or more Deliveries.
Events describe what happened to each delivery.
Inbound traffic becomes an InboundMessage.
A Route hands it to a Mailbox.
A Suppression can block future deliveries.

That is the backbone.

Mailable -> Message -> Delivery -> Event
                     \
                      \-> Delivery -> Event
Ingress -> InboundMessage -> Route -> Mailbox -> App action
Recipient + Stream -> Preference / Suppression

⸻

3) The seven irreducible nouns

These are the nouns that should stay stable across the whole library.

1. Mailable

The source-level definition of an email kind.

Examples:

* welcome email
* password reset email
* magic link email
* invoice ready email

A Mailable is code, not data.

Think:

* module
* schema for inputs
* subject/body/layout logic
* preview fixtures

2. Message

A concrete rendered email.

It has:

* subject
* from/reply-to
* headers
* html/text bodies
* attachments
* message-id
* metadata

A Message is the thing you intend to send or have received.

3. Delivery

A recipient/provider-specific send record for a message.

One message can fan out to many deliveries.

Examples:

* same message sent to 3 recipients = 3 deliveries
* same recipient retried via failover provider = 1 delivery, multiple attempts
* same message sent in two tenants = separate deliveries per tenant boundary

Delivery is transport-level. It is not the authored content.

4. Event

An observed fact about a delivery or inbound lifecycle.

Examples:

* queued
* delivered
* bounced
* complained
* routed
* processed

Events are facts in the past tense.
They are not intentions.

5. InboundMessage

A received email before your app-specific logic decides what it means.

It should preserve:

* raw source
* parsed headers
* parsed bodies
* attachments
* envelope info
* provider payload
* spam/auth hints when available

6. Mailbox

A handler for inbound mail.

A mailbox is code that answers:

* does this inbound message belong here?
* how should it be processed?
* should we accept, reject, bounce, or ignore it?

Important: Mailbox is a handler concept, not the UI inbox.

7. Suppression

A policy record that blocks future sending.

Common reasons:

* hard bounce
* complaint
* explicit unsubscribe
* manual admin action
* tenant/domain policy

A suppression is about future send eligibility, not past events.

⸻

4) Secondary nouns that make the system readable

Addressing and identity

Address

A normalized email address.

Use it for:

* from
* to
* cc
* bcc
* reply_to
* return_path

Prefer:

* parsed local part
* parsed domain
* normalized string
* optional display name

Recipient

An address in relation to a message.

A recipient is not just an address; it also has a role:

* :to
* :cc
* :bcc

If you later add preferences or suppression lookups, they usually attach to recipients or identities derived from them.

SendingIdentity

The verified identity used to send mail.

It usually bundles:

* from domain
* default from address
* reply-to policy
* DKIM/SPF/DMARC context
* provider account or server binding

Use this instead of overloading from.

Tenant

The application/customer boundary.

Useful when the same library serves:

* many customer workspaces
* many branded domains
* many provider credentials

Stream

A policy bucket for outbound mail.

Examples:

* :transactional
* :bulk
* :system

Stream is about send policy and infrastructure behavior.
It is not a folder, thread, or UI label.

⸻

5) Authoring nouns

Scenario

The semantic use-case a mailable represents.

Examples:

* :welcome
* :password_reset
* :magic_link
* :receipt_ready

A scenario is often the most human-readable name for “which email is this?”

Template

A reusable presentation unit.

Use Template for:

* layouts
* partials
* reusable blocks

Do not use Template when you mean a semantic email kind.
That is Scenario or Mailable.

Layout

The outer shell:

* brand chrome
* footer
* legal text
* shared wrapper
* preheader placement

Part

A MIME part.

Examples:

* html part
* text part
* attachment part
* inline image part

Attachment

A file attached to a message.

InlineAsset

A resource referenced inside the body:

* CID image
* embedded logo
* inline file

Preheader

The preview text shown by many clients next to the subject.

Treat this as a first-class content field, not an accidental snippet.

Preview

A named developer-facing rendering example.

Examples:

* default
* fr
* edge_case_long_name
* dark_mode_smoke

A preview is a rendering fixture, not a production message.

⸻

6) Delivery nouns

Attempt

A single try to dispatch a delivery.

A delivery may have many attempts because of:

* retries
* failover
* provider outage
* transient timeout

Provider

The external mail transport or ESP.

Examples:

* Postmark
* SES
* SendGrid
* Mailgun
* SMTP relay
* Resend

ProviderRef

The provider’s identifier for a sent or received item.

Examples:

* provider message id
* webhook event id
* inbound token/reference

Never leak provider IDs into your core naming. Store them as provider refs.

Envelope

The SMTP transport addressing.

This is not the same as visible headers.

Envelope fields answer:

* who is the SMTP sender?
* who are the SMTP recipients?

Headers answer:

* what does the user see in From/To/Reply-To?

This distinction matters for bounces, VERP, inbound routing, and provider normalization.

Header

A message metadata field.

Examples:

* Message-ID
* In-Reply-To
* References
* List-Unsubscribe
* Auto-Submitted

Metadata

Application-defined structured data carried with a message or delivery.

Examples:

* user id
* tenant id
* feature flag version
* billing id

Tag

A small classification label for a message or delivery.

Examples:

* welcome
* password_reset
* billing
* security

Use tags for grouping and analytics.
Use metadata for exact application joins.

⸻

7) Inbound and inbox nouns

Ingress

The boundary where inbound mail enters your system.

Examples:

* provider webhook
* SMTP relay
* SES -> S3/SNS pipeline

This should be provider-shaped at the edge and normalized immediately after.

Action Mailbox is the right mental model here: inbound mail arrives through configured ingresses, is persisted as an inbound record, then routed asynchronously to mailbox handlers. Provider docs reinforce the same shape even though each provider’s payload differs.  ￼

Route

A matcher that maps an inbound message to a mailbox.

Routes may match on:

* recipient address
* plus-address token
* subject
* headers
* tenant/domain
* custom predicate

MailboxHash

The token embedded in plus-addressed mail.

Example:

* reply+abc123@example.com
* hash/token = abc123

Useful for reply routing and inbox correlation.

Thread

A conversation grouping of related messages.

Usually derived from:

* Message-ID
* In-Reply-To
* References

A thread is a projection, not the raw source of truth.

Inbox

A user-facing collection view of inbound or threaded messages.

Keep this distinct from Mailbox.

* Mailbox = handler/module/boundary
* Inbox = UI/read model

Participant

An actor in a thread or message exchange.

Examples:

* sender
* recipient
* cc participant
* internal agent
* external customer

RawSource

The original MIME or provider payload stored for replay/debugging.

This should be preserved whenever possible.

Replay

A developer/admin action that re-runs routing or processing on stored inbound mail.

Replay is invaluable for debugging and safe recovery.

⸻

8) Policy nouns

Preference

A recipient’s preference for a class of mail.

Examples:

* accepts billing emails
* opted out of product updates
* wants plain text only

Consent

The record that explains why sending is allowed.

Useful when legal or audit posture matters.

UnsubscribeToken

A signed opaque token that lets a recipient opt out without exposing raw identifiers.

SuppressionScope

Where a suppression applies.

Examples:

* address
* domain
* tenant + address
* tenant + stream + address

SuppressionReason

Why sending is blocked.

Good canonical set:

* :hard_bounce
* :complaint
* :unsubscribe
* :manual
* :policy
* :invalid_recipient

For subscribed/promotional mail, Gmail’s sender guidance makes one-click unsubscribe a real domain concept, not a nice-to-have: the headers matter, the POST matters, and honoring the action matters. That means UnsubscribeToken, Preference, and Suppression deserve first-class names even in a transactional-first library.  ￼

⸻

9) Canonical verbs

Use verbs for commands and operations.
Use past-tense nouns for events.

Authoring verbs

* compose — build a message from a mailable and inputs
* render — turn components/templates into html/text
* preview — render in a developer-facing context
* personalize — inject recipient-specific content
* localize — render in a locale
* sign — apply DKIM or signed action tokens

Send verbs

* enqueue — place a send in background work
* dispatch — hand the delivery to a provider/adapter
* retry — try again after transient failure
* resend — create a new delivery based on an earlier message
* cancel — stop an unsent delivery
* suppress — block future sending
* unsuppress — remove a suppression

Inbound verbs

* receive — accept inbound traffic at the edge
* ingest — persist raw + normalized inbound representations
* parse — extract headers, bodies, attachments, tokens
* route — choose a mailbox
* process — run application logic
* reply — send a response tied to an inbound thread
* replay — re-run processing against stored inbound data
* expire — remove or incinerate old inbound artifacts

Observability verbs

* emit — publish a domain event
* normalize — translate provider payloads into core structs
* reconcile — match provider events back to deliveries/messages
* summarize — derive status/read models from append-only facts

⸻

10) A crucial naming rule: dispatch vs delivered

This one prevents years of confusion.

Prefer this distinction

* dispatch = your app handed the delivery to a provider/adapter
* delivered = the receiving side accepted the message downstream

Why: a local adapter call can succeed while the email is still later bounced, deferred, or complained about.

If you keep deliver/2 in the public API for Phoenix/Swoosh familiarity, that is fine.
But internally, name the domain fact dispatched, not delivered.

⸻

11) Canonical event language

A. Internal lifecycle events

These are your library’s own facts.

Recommended:

* message_composed
* message_rendered
* delivery_enqueued
* delivery_dispatched
* delivery_retry_scheduled
* delivery_suppressed
* inbound_received
* inbound_ingested
* inbound_routed
* inbound_processed
* inbound_replayed
* suppression_added
* suppression_removed
* preference_updated

These are framework-domain events, not provider events.

B. Provider-normalized tracking events

For provider tracking, copy Anymail’s vocabulary almost verbatim. It already normalizes webhook tracking events across ESPs and is the cleanest shared language to adopt.  ￼

Use these canonical event types:

* queued — provider accepted it for its queue
* sent — provider handed off to the next mail system
* rejected — provider refused it before downstream handoff
* failed — provider or processing failure prevented send
* bounced — downstream mail system rejected it
* deferred — temporary delay; retry expected
* delivered — downstream recipient system accepted it
* autoresponded — auto-reply/vacation responder
* opened — tracking pixel fired
* clicked — tracked link clicked
* complained — spam complaint / feedback loop
* unsubscribed — recipient opted out
* subscribed — recipient opted in
* unknown — provider event not yet mapped

Recommended companion field:

* reject_reason
    * :invalid
    * :bounced
    * :timed_out
    * :blocked
    * :spam
    * :unsubscribed
    * :other

Keep raw provider payloads too:

* provider
* provider_ref
* provider_payload

Do not force every provider nuance into the canonical struct.

C. Inbound lifecycle events

Recommended inbound event language:

* received — edge accepted payload
* ingested — raw source persisted
* parsed — normalized fields extracted
* routed — mailbox chosen
* processed — mailbox completed successfully
* rejected — inbound rejected by policy
* bounced — bounce response generated
* failed — processing failed unexpectedly
* replayed — previously stored inbound reprocessed
* expired — old inbound artifact removed/incinerated

⸻

12) State design: prefer facts first, summaries second

Do not make status your only truth.

Better model

* store append-only events
* derive a summary status
* keep timestamps for first/last significant events

Delivery summary fields

Good summary fields:

* last_event_type
* last_event_at
* terminal?
* delivered_at
* bounced_at
* complained_at
* suppressed_at

Inbound summary fields

Good summary fields:

* received_at
* routed_at
* processed_at
* failed_at
* expired_at

This keeps history intact while giving the UI cheap read fields.

⸻

13) Aggregate boundaries

These boundaries keep schemas sane.

Mailable

Owns:

* scenario definition
* input contract
* preview fixtures
* rendering rules

Does not own:

* provider ids
* webhook events
* suppression

Message

Owns:

* content
* visible headers
* attachments
* references
* metadata/tags

Does not own:

* retry history
* webhook event history

Delivery

Owns:

* recipient
* provider/account choice
* dispatch attempts
* tracking summary
* provider refs

Does not own:

* shared message body as mutable source of truth

InboundMessage

Owns:

* raw source
* parsed source
* envelope
* attachments
* inbound provider refs
* processing summary

Does not own:

* business-domain outcome forever

Suppression

Owns:

* scope
* reason
* source
* created/expires timestamps

Does not own:

* preference semantics
* consent provenance beyond the suppression cause

⸻

14) The distinctions that save you

Message vs Delivery

A message is the content.
A delivery is the send instance.

Mailbox vs Inbox

A mailbox handles inbound logic.
An inbox is a UI/read model.

Rejected vs Bounced

Rejected = provider refused before downstream delivery.
Bounced = downstream mail system rejected after send attempt.

Suppression vs Unsubscribe

Unsubscribe is a recipient action or event.
Suppression is the policy consequence that blocks future sending.

Envelope vs Headers

Envelope is SMTP transport metadata.
Headers are user-visible or message-visible metadata.

Thread vs Stream

Thread = conversation grouping.
Stream = send policy bucket.

Template vs Scenario

Template = reusable presentation.
Scenario = semantic email use-case.

⸻

15) Suggested Elixir module names

A clean module map could look like this:

Mail.Address
Mail.Recipient
Mail.SendingIdentity
Mail.Tenant
Mail.Stream
Mail.Mailable
Mail.Message
Mail.Template
Mail.Layout
Mail.Attachment
Mail.Preview
Mail.Delivery
Mail.Attempt
Mail.Event
Mail.ProviderRef
Mail.Ingress
Mail.InboundMessage
Mail.Route
Mail.Mailbox
Mail.Thread
Mail.Inbox
Mail.Preference
Mail.Consent
Mail.Suppression
Mail.UnsubscribeToken

If you want one namespace rule:

Put stable domain objects under Mail.*.
Put provider adapters under Mail.Providers.*.
Put Phoenix integration under MailWeb.* or Mail.Phoenix.*.

⸻

16) Terms to avoid

Avoid these ambiguous names in the core.

Email

Too vague on its own.

It might mean:

* source module
* rendered message
* outbound delivery
* inbound raw MIME
* UI inbox row

Use a more specific noun.

Status

Too lossy if used alone.

Prefer:

* events as facts
* summary status as projection

Template for everything

It erases the distinction between “semantic email kind” and “presentational fragment.”

Mailbox when you mean Inbox

They are different concepts and should stay different in code.

Notification

That term drags you toward multi-channel abstractions too early.

Use Message, Delivery, and Event in the email package.
Add Notifier later only if you build a separate cross-channel package.

⸻

17) Recommended one-screen cheatsheet

Mailable   = source-level definition of an email kind
Message    = rendered email content
Delivery   = recipient/provider-specific send record
Attempt    = one dispatch try for a delivery
Event      = observed fact about send/inbound lifecycle
Ingress    = inbound boundary
InboundMessage = received email before app-specific meaning
Route      = matcher that chooses a mailbox
Mailbox    = inbound handler
Inbox      = user-facing message/thread view
Thread     = conversation grouping
Stream     = outbound policy bucket
Suppression = block on future sending
Preference = recipient choice
Consent    = why sending is allowed

⸻

18) Final opinionated rules

1. Model outbound and inbound explicitly.
    Do not fake inbound as “just another webhook.”
2. Keep provider names at the edges.
    Normalize quickly.
3. Use Message for content and Delivery for transport.
    This is the most important naming decision.
4. Use append-only events, not magical status flips.
5. Treat suppression as first-class policy.
    Not an afterthought.
6. Keep Mailbox and Inbox separate.
7. Do not let campaign vocabulary leak into the core.
8. Preserve raw inbound and raw provider payloads.
    Future replay/debugging will pay for it.
9. Prefer semantic scenario names over provider-centric names.
10. Build the API so the nouns read naturally out loud.
    Example:
    Mailable -> Message -> Delivery -> Event
    Ingress -> InboundMessage -> Route -> Mailbox

⸻

19) The shortest possible doctrine

If you only remember one paragraph, remember this:

A mail framework is not a mailer.
A mailer only dispatches.
A framework must also name the content, the delivery, the observed facts, the inbound boundary, the routing target, and the future-send policy.
Those nouns are: Mailable, Message, Delivery, Event, InboundMessage, Mailbox, Suppression.

If you want, I can turn this into a second pass that is even more implementation-oriented: Ecto schemas, suggested fields, enums/atoms, and event payload structs.