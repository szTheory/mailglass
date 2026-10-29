# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: storybook-fidelity.spec.js >> Phase174 widths >> inbound normal and boundary quick views fit bounded responsive widths
- Location: e2e/storybook-fidelity.spec.js:694:5

# Error details

```
Error: expect(received).toBe(expected) // Object.is equality

Expected: "Next delivery"
Received: "Close quick view"

Call Log:
- Timeout 5000ms exceeded while waiting on the predicate
```

# Page snapshot

```yaml
- generic [ref=e3]:
  - banner [ref=e4]:
    - img "mailglass" [ref=e6]
    - generic [ref=e28]:
      - generic "Account context" [ref=e29]:
        - group [ref=e30]:
          - 'generic "Change Account: Northstar Logistics" [ref=e31] [cursor=pointer]':
            - generic [ref=e32]:
              - generic [ref=e33]: Account
              - generic [ref=e34]: Northstar Logistics
        - generic [ref=e36]: northstar
      - group "Appearance" [ref=e37]:
        - generic "System" [ref=e38] [cursor=pointer]:
          - radio "System" [checked] [ref=e39]
          - generic: System
        - generic "Light" [ref=e40] [cursor=pointer]:
          - radio "Light" [ref=e41]
          - generic: Light
        - generic "Dark" [ref=e42] [cursor=pointer]:
          - radio "Dark" [ref=e43]
          - generic: Dark
  - generic [ref=e44]:
    - complementary [ref=e45]:
      - navigation "Mailglass sections" [ref=e47]:
        - link "Health" [ref=e48] [cursor=pointer]:
          - /url: /ops/mail?tenant_id=northstar
          - generic [ref=e50]: Health
        - link "Preview" [ref=e51] [cursor=pointer]:
          - /url: /dev/mail
          - generic [ref=e53]: Preview
        - link "Deliveries" [ref=e54] [cursor=pointer]:
          - /url: /ops/mail?tenant_id=northstar&view=deliveries
          - generic [ref=e56]: Deliveries
        - link "Inbound" [ref=e57] [cursor=pointer]:
          - /url: /ops/mail/inbound?tenant_id=northstar
          - generic [ref=e59]: Inbound
    - main [ref=e61]:
      - generic [ref=e62]:
        - generic [ref=e63]:
          - heading "Deliveries" [level=1] [ref=e64]
          - paragraph [ref=e65]: Trace each delivery through its event history.
        - generic [ref=e68]:
          - group "Filters" [ref=e69]:
            - generic [ref=e70]: Filters
            - generic [ref=e72]:
              - generic [ref=e73]:
                - generic [ref=e74]:
                  - generic [ref=e75]: Search
                  - generic [ref=e76]:
                    - button "Help for Search" [ref=e77]
                    - generic [ref=e79]: Find deliveries by recipient email address or subject.
                - textbox "Search" [ref=e80]:
                  - /placeholder: Subject or recipient
              - generic [ref=e81]:
                - generic [ref=e82]:
                  - generic [ref=e83]: Time window
                  - generic [ref=e84]:
                    - button "Help for Time window" [ref=e85]
                    - generic [ref=e87]: Show deliveries with activity during this period.
                - combobox "Time window" [ref=e88]:
                  - option "Last 24 hours"
                  - option "Last 7 days" [selected]
                  - option "Last 30 days"
              - generic [ref=e89]:
                - generic [ref=e90]:
                  - generic [ref=e91]: Latest recorded event
                  - generic [ref=e92]:
                    - button "Help for Latest recorded event" [ref=e93]
                    - generic [ref=e95]: Filter by the latest event recorded for each delivery.
                - combobox "Latest recorded event" [ref=e96]:
                  - option "Any status" [selected]
                  - option "Queued"
                  - option "Sent"
                  - option "Rejected"
                  - option "Failed"
                  - option "Bounced"
                  - option "Deferred"
                  - option "Delivered"
                  - option "Autoresponded"
                  - option "Opened"
                  - option "Clicked"
                  - option "Complained"
                  - option "Unsubscribed"
                  - option "Subscribed"
                  - option "Unknown"
                  - option "Dispatched"
                  - option "Suppressed"
              - generic [ref=e97]:
                - generic [ref=e98]:
                  - generic [ref=e99]: Provider
                  - generic [ref=e100]:
                    - button "Help for Provider" [ref=e101]
                    - generic [ref=e103]: Filter by the sending provider recorded for this account.
                - combobox "Provider" [ref=e104]:
                  - option "Any provider" [selected]
                  - option "Postmark"
                  - option "SendGrid"
          - generic [ref=e105]:
            - button "Apply filters" [ref=e106] [cursor=pointer]
            - button "Clear filters" [ref=e107] [cursor=pointer]
        - generic [ref=e109]:
          - article [ref=e110]:
            - paragraph [ref=e112]:
              - generic [ref=e113]: Delivered
              - generic [ref=e115]:
                - button "Help for Delivered" [ref=e116]
                - generic [ref=e118]: Messages with delivery confirmation or an open or click event, unless a later delivery problem was recorded. Counts include all results for the applied provider, time window, and search.
            - paragraph [ref=e119]: "7"
            - paragraph [ref=e120]:
              - generic [ref=e122]: Tracked
          - article [ref=e123]:
            - paragraph [ref=e125]:
              - generic [ref=e126]: Needs attention
              - generic [ref=e128]:
                - button "Help for Needs attention" [ref=e129]
                - generic [ref=e131]: Failed, bounced, rejected, deferred, suppressed, complained, or unsubscribed deliveries. Open a delivery to inspect what happened. Counts include all matching results.
            - paragraph [ref=e132]: "7"
            - paragraph [ref=e133]:
              - generic [ref=e135]: Needs attention
          - article [ref=e136]:
            - paragraph [ref=e138]:
              - generic [ref=e139]: Awaiting confirmation
              - generic [ref=e141]:
                - button "Help for Awaiting confirmation" [ref=e142]
                - generic [ref=e144]: Messages are queued or have been sent to the provider, but no delivery result has been recorded. A missing result does not mean delivery failed. Counts include all matching results.
            - paragraph [ref=e145]: "2"
            - paragraph [ref=e146]:
              - generic [ref=e148]: Tracked
        - complementary [ref=e150]:
          - heading "Deliveries 16 deliveries" [level=2] [ref=e152]: Deliveries (16)
          - region "Delivery records" [ref=e155]:
            - table [ref=e156]:
              - rowgroup [ref=e157]:
                - row "Recipient / Subject Outcome Provider Updated" [ref=e158]:
                  - columnheader "Recipient / Subject" [ref=e159]
                  - columnheader "Outcome" [ref=e160]
                  - columnheader "Provider" [ref=e161]
                  - columnheader "Updated" [ref=e162]
              - rowgroup [ref=e163]:
                - 'row "Open delivery for ops@northstar.example Suppressed Sending to this recipient was blocked by a suppression rule. SENDGRID Copy timestamp as UTC: 2026-10-27 21:19:53.000000 UTC" [ref=e164]':
                  - cell "Open delivery for ops@northstar.example" [ref=e165]:
                    - button "Open delivery for ops@northstar.example" [ref=e166]:
                      - generic [ref=e167]: ops@northstar.example
                      - generic "INC-4421 is monitoring" [ref=e168]
                  - cell "Suppressed Sending to this recipient was blocked by a suppression rule." [ref=e169]:
                    - generic [ref=e170]:
                      - button "Suppressed" [ref=e171]:
                        - generic [ref=e172]: Suppressed
                      - generic [ref=e174]: Sending to this recipient was blocked by a suppression rule.
                  - cell "SENDGRID" [ref=e175]:
                    - generic "sendgrid" [ref=e176]: SENDGRID
                  - 'cell "Copy timestamp as UTC: 2026-10-27 21:19:53.000000 UTC" [ref=e177]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 21:19:53.000000 UTC" [ref=e179]':
                      - time [ref=e180]: Oct 27, 2026, 9:19 PM
                - 'row "Open delivery for ops@northstar.example Bounced The provider reported that this message could not be delivered. Open the delivery to inspect the bounce reason. SENDGRID Copy timestamp as UTC: 2026-10-27 21:16:53.000000 UTC" [ref=e181]':
                  - cell "Open delivery for ops@northstar.example" [ref=e182]:
                    - button "Open delivery for ops@northstar.example" [ref=e183]:
                      - generic [ref=e184]: ops@northstar.example
                      - generic "Northstar Logistics email usage reached 85%" [ref=e185]
                  - cell "Bounced The provider reported that this message could not be delivered. Open the delivery to inspect the bounce reason." [ref=e186]:
                    - generic [ref=e187]:
                      - button "Bounced" [ref=e188]:
                        - generic [ref=e189]: Bounced
                      - generic [ref=e191]: The provider reported that this message could not be delivered. Open the delivery to inspect the bounce reason.
                  - cell "SENDGRID" [ref=e192]:
                    - generic "sendgrid" [ref=e193]: SENDGRID
                  - 'cell "Copy timestamp as UTC: 2026-10-27 21:16:53.000000 UTC" [ref=e194]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 21:16:53.000000 UTC" [ref=e196]':
                      - time [ref=e197]: Oct 27, 2026, 9:16 PM
                - 'row "Open delivery for alex.rivera@northstar.example Delivered The provider reported that the recipient''s mail server accepted this message. This does not confirm it reached the inbox or was read. POSTMARK Copy timestamp as UTC: 2026-10-27 21:08:53.000000 UTC" [ref=e198]':
                  - cell "Open delivery for alex.rivera@northstar.example" [ref=e199]:
                    - button "Open delivery for alex.rivera@northstar.example" [ref=e200]:
                      - generic [ref=e201]: alex.rivera@northstar.example
                      - generic "Your Northstar Logistics sign-in link" [ref=e202]
                  - cell "Delivered The provider reported that the recipient's mail server accepted this message. This does not confirm it reached the inbox or was read." [ref=e203]:
                    - generic [ref=e204]:
                      - button "Delivered" [ref=e205]:
                        - generic [ref=e206]: Delivered
                      - generic [ref=e208]: The provider reported that the recipient's mail server accepted this message. This does not confirm it reached the inbox or was read.
                  - cell "POSTMARK" [ref=e209]:
                    - generic "postmark" [ref=e210]: POSTMARK
                  - 'cell "Copy timestamp as UTC: 2026-10-27 21:08:53.000000 UTC" [ref=e211]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 21:08:53.000000 UTC" [ref=e213]':
                      - time [ref=e214]: Oct 27, 2026, 9:08 PM
                - 'row "Open delivery for mira.chen@northstar.example Delivered The provider reported that the recipient''s mail server accepted this message. This does not confirm it reached the inbox or was read. POSTMARK Copy timestamp as UTC: 2026-10-27 21:06:53.000000 UTC" [ref=e215]':
                  - cell "Open delivery for mira.chen@northstar.example" [ref=e216]:
                    - button "Open delivery for mira.chen@northstar.example" [ref=e217]:
                      - generic [ref=e218]: mira.chen@northstar.example
                      - generic "Sam Rivera invited you to Northstar Logistics" [ref=e219]
                  - cell "Delivered The provider reported that the recipient's mail server accepted this message. This does not confirm it reached the inbox or was read." [ref=e220]:
                    - generic [ref=e221]:
                      - button "Delivered" [ref=e222]:
                        - generic [ref=e223]: Delivered
                      - generic [ref=e225]: The provider reported that the recipient's mail server accepted this message. This does not confirm it reached the inbox or was read.
                  - cell "POSTMARK" [ref=e226]:
                    - generic "postmark" [ref=e227]: POSTMARK
                  - 'cell "Copy timestamp as UTC: 2026-10-27 21:06:53.000000 UTC" [ref=e228]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 21:06:53.000000 UTC" [ref=e230]':
                      - time [ref=e231]: Oct 27, 2026, 9:06 PM
                - 'row "Open delivery for billing@northstar.example Bounced The provider reported that this message could not be delivered. Open the delivery to inspect the bounce reason. POSTMARK Copy timestamp as UTC: 2026-10-27 21:04:53.000000 UTC" [ref=e232]':
                  - cell "Open delivery for billing@northstar.example" [ref=e233]:
                    - button "Open delivery for billing@northstar.example" [ref=e234]:
                      - generic [ref=e235]: billing@northstar.example
                      - generic "Payment action needed for Northstar Logistics" [ref=e236]
                  - cell "Bounced The provider reported that this message could not be delivered. Open the delivery to inspect the bounce reason." [ref=e237]:
                    - generic [ref=e238]:
                      - button "Bounced" [ref=e239]:
                        - generic [ref=e240]: Bounced
                      - generic [ref=e242]: The provider reported that this message could not be delivered. Open the delivery to inspect the bounce reason.
                  - cell "POSTMARK" [ref=e243]:
                    - generic "postmark" [ref=e244]: POSTMARK
                  - 'cell "Copy timestamp as UTC: 2026-10-27 21:04:53.000000 UTC" [ref=e245]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 21:04:53.000000 UTC" [ref=e247]':
                      - time [ref=e248]: Oct 27, 2026, 9:04 PM
                - 'row "Open delivery for billing@northstar.example Delivered The provider reported that the recipient''s mail server accepted this message. This does not confirm it reached the inbox or was read. POSTMARK Copy timestamp as UTC: 2026-10-27 20:40:53.000000 UTC" [ref=e249]':
                  - cell "Open delivery for billing@northstar.example" [ref=e250]:
                    - button "Open delivery for billing@northstar.example" [ref=e251]:
                      - generic [ref=e252]: billing@northstar.example
                      - generic "Receipt INV-2026-0601 for Northstar Logistics" [ref=e253]
                  - cell "Delivered The provider reported that the recipient's mail server accepted this message. This does not confirm it reached the inbox or was read." [ref=e254]:
                    - generic [ref=e255]:
                      - button "Delivered" [ref=e256]:
                        - generic [ref=e257]: Delivered
                      - generic [ref=e259]: The provider reported that the recipient's mail server accepted this message. This does not confirm it reached the inbox or was read.
                  - cell "POSTMARK" [ref=e260]:
                    - generic "postmark" [ref=e261]: POSTMARK
                  - 'cell "Copy timestamp as UTC: 2026-10-27 20:40:53.000000 UTC" [ref=e262]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 20:40:53.000000 UTC" [ref=e264]':
                      - time [ref=e265]: Oct 27, 2026, 8:40 PM
                - 'row "Open delivery for queued@northstar.example Queued This message is waiting to be sent to the provider. POSTMARK Copy timestamp as UTC: 2026-10-27 19:11:53.000000 UTC" [ref=e266]':
                  - cell "Open delivery for queued@northstar.example" [ref=e267]:
                    - button "Open delivery for queued@northstar.example" [ref=e268]:
                      - generic [ref=e269]: queued@northstar.example
                      - generic "Sam Rivera invited you to Northstar Logistics" [ref=e270]
                  - cell "Queued This message is waiting to be sent to the provider." [ref=e271]:
                    - generic [ref=e272]:
                      - button "Queued" [ref=e273]:
                        - generic [ref=e274]: Queued
                      - generic [ref=e276]: This message is waiting to be sent to the provider.
                  - cell "POSTMARK" [ref=e277]:
                    - generic "postmark" [ref=e278]: POSTMARK
                  - 'cell "Copy timestamp as UTC: 2026-10-27 19:11:53.000000 UTC" [ref=e279]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 19:11:53.000000 UTC" [ref=e281]':
                      - time [ref=e282]: Oct 27, 2026, 7:11 PM
                - 'row "Open delivery for rejected@northstar.example Rejected The provider rejected this message. Open the delivery to inspect the recorded reason. POSTMARK Copy timestamp as UTC: 2026-10-27 19:10:53.000000 UTC" [ref=e283]':
                  - cell "Open delivery for rejected@northstar.example" [ref=e284]:
                    - button "Open delivery for rejected@northstar.example" [ref=e285]:
                      - generic [ref=e286]: rejected@northstar.example
                      - generic "Sam Rivera invited you to Northstar Logistics" [ref=e287]
                  - cell "Rejected The provider rejected this message. Open the delivery to inspect the recorded reason." [ref=e288]:
                    - generic [ref=e289]:
                      - button "Rejected" [ref=e290]:
                        - generic [ref=e291]: Rejected
                      - generic [ref=e293]: The provider rejected this message. Open the delivery to inspect the recorded reason.
                  - cell "POSTMARK" [ref=e294]:
                    - generic "postmark" [ref=e295]: POSTMARK
                  - 'cell "Copy timestamp as UTC: 2026-10-27 19:10:53.000000 UTC" [ref=e296]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 19:10:53.000000 UTC" [ref=e298]':
                      - time [ref=e299]: Oct 27, 2026, 7:10 PM
                - 'row "Open delivery for deferred@northstar.example Deferred The provider reported a temporary delivery delay. Delivery has not been confirmed. SENDGRID Copy timestamp as UTC: 2026-10-27 19:08:53.000000 UTC" [ref=e300]':
                  - cell "Open delivery for deferred@northstar.example" [ref=e301]:
                    - button "Open delivery for deferred@northstar.example" [ref=e302]:
                      - generic [ref=e303]: deferred@northstar.example
                      - generic "Sam Rivera invited you to Northstar Logistics" [ref=e304]
                  - cell "Deferred The provider reported a temporary delivery delay. Delivery has not been confirmed." [ref=e305]:
                    - generic [ref=e306]:
                      - button "Deferred" [ref=e307]:
                        - generic [ref=e308]: Deferred
                      - generic [ref=e310]: The provider reported a temporary delivery delay. Delivery has not been confirmed.
                  - cell "SENDGRID" [ref=e311]:
                    - generic "sendgrid" [ref=e312]: SENDGRID
                  - 'cell "Copy timestamp as UTC: 2026-10-27 19:08:53.000000 UTC" [ref=e313]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 19:08:53.000000 UTC" [ref=e315]':
                      - time [ref=e316]: Oct 27, 2026, 7:08 PM
                - 'row "Open delivery for opened@northstar.example Opened The provider recorded an open. Image loading, privacy features, or automated activity can trigger this signal. POSTMARK Copy timestamp as UTC: 2026-10-27 19:06:53.000000 UTC" [ref=e317]':
                  - cell "Open delivery for opened@northstar.example" [ref=e318]:
                    - button "Open delivery for opened@northstar.example" [ref=e319]:
                      - generic [ref=e320]: opened@northstar.example
                      - generic "Receipt INV-2026-0601 for Northstar Logistics" [ref=e321]
                  - cell "Opened The provider recorded an open. Image loading, privacy features, or automated activity can trigger this signal." [ref=e322]:
                    - generic [ref=e323]:
                      - button "Opened" [ref=e324]:
                        - generic [ref=e325]: Opened
                      - generic [ref=e327]: The provider recorded an open. Image loading, privacy features, or automated activity can trigger this signal.
                  - cell "POSTMARK" [ref=e328]:
                    - generic "postmark" [ref=e329]: POSTMARK
                  - 'cell "Copy timestamp as UTC: 2026-10-27 19:06:53.000000 UTC" [ref=e330]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 19:06:53.000000 UTC" [ref=e332]':
                      - time [ref=e333]: Oct 27, 2026, 7:06 PM
                - 'row "Open delivery for clicked@northstar.example Clicked The provider recorded a link click. Security scanners or other automated activity can trigger this signal. POSTMARK Copy timestamp as UTC: 2026-10-27 19:04:53.000000 UTC" [ref=e334]':
                  - cell "Open delivery for clicked@northstar.example" [ref=e335]:
                    - button "Open delivery for clicked@northstar.example" [ref=e336]:
                      - generic [ref=e337]: clicked@northstar.example
                      - generic "Receipt INV-2026-0601 for Northstar Logistics" [ref=e338]
                  - cell "Clicked The provider recorded a link click. Security scanners or other automated activity can trigger this signal." [ref=e339]:
                    - generic [ref=e340]:
                      - button "Clicked" [ref=e341]:
                        - generic [ref=e342]: Clicked
                      - generic [ref=e344]: The provider recorded a link click. Security scanners or other automated activity can trigger this signal.
                  - cell "POSTMARK" [ref=e345]:
                    - generic "postmark" [ref=e346]: POSTMARK
                  - 'cell "Copy timestamp as UTC: 2026-10-27 19:04:53.000000 UTC" [ref=e347]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 19:04:53.000000 UTC" [ref=e349]':
                      - time [ref=e350]: Oct 27, 2026, 7:04 PM
                - 'row "Open delivery for complained@northstar.example Complained The provider reported a spam complaint for this message. SENDGRID Copy timestamp as UTC: 2026-10-27 19:02:53.000000 UTC" [ref=e351]':
                  - cell "Open delivery for complained@northstar.example" [ref=e352]:
                    - button "Open delivery for complained@northstar.example" [ref=e353]:
                      - generic [ref=e354]: complained@northstar.example
                      - generic "Northstar Logistics email usage reached 85%" [ref=e355]
                  - cell "Complained The provider reported a spam complaint for this message." [ref=e356]:
                    - generic [ref=e357]:
                      - button "Complained" [ref=e358]:
                        - generic [ref=e359]: Complained
                      - generic [ref=e361]: The provider reported a spam complaint for this message.
                  - cell "SENDGRID" [ref=e362]:
                    - generic "sendgrid" [ref=e363]: SENDGRID
                  - 'cell "Copy timestamp as UTC: 2026-10-27 19:02:53.000000 UTC" [ref=e364]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 19:02:53.000000 UTC" [ref=e366]':
                      - time [ref=e367]: Oct 27, 2026, 7:02 PM
                - 'row "Open delivery for unsubscribed@northstar.example Unsubscribed The provider recorded an unsubscribe for this recipient. SENDGRID Copy timestamp as UTC: 2026-10-27 19:00:53.000000 UTC" [ref=e368]':
                  - cell "Open delivery for unsubscribed@northstar.example" [ref=e369]:
                    - button "Open delivery for unsubscribed@northstar.example" [ref=e370]:
                      - generic [ref=e371]: unsubscribed@northstar.example
                      - generic "Northstar Logistics email usage reached 85%" [ref=e372]
                  - cell "Unsubscribed The provider recorded an unsubscribe for this recipient." [ref=e373]:
                    - generic [ref=e374]:
                      - button "Unsubscribed" [ref=e375]:
                        - generic [ref=e376]: Unsubscribed
                      - generic [ref=e378]: The provider recorded an unsubscribe for this recipient.
                  - cell "SENDGRID" [ref=e379]:
                    - generic "sendgrid" [ref=e380]: SENDGRID
                  - 'cell "Copy timestamp as UTC: 2026-10-27 19:00:53.000000 UTC" [ref=e381]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 19:00:53.000000 UTC" [ref=e383]':
                      - time [ref=e384]: Oct 27, 2026, 7:00 PM
                - 'row "Open delivery for subscribed@northstar.example Delivered The provider reported that the recipient''s mail server accepted this message. This does not confirm it reached the inbox or was read. Latest: Subscribed SENDGRID Copy timestamp as UTC: 2026-10-27 18:58:53.000000 UTC" [ref=e385]':
                  - cell "Open delivery for subscribed@northstar.example" [ref=e386]:
                    - button "Open delivery for subscribed@northstar.example" [ref=e387]:
                      - generic [ref=e388]: subscribed@northstar.example
                      - generic "Northstar Logistics email usage reached 85%" [ref=e389]
                  - 'cell "Delivered The provider reported that the recipient''s mail server accepted this message. This does not confirm it reached the inbox or was read. Latest: Subscribed" [ref=e390]':
                    - generic [ref=e391]:
                      - button "Delivered" [ref=e392]:
                        - generic [ref=e393]: Delivered
                      - generic [ref=e395]: The provider reported that the recipient's mail server accepted this message. This does not confirm it reached the inbox or was read.
                    - paragraph [ref=e396]: "Latest: Subscribed"
                  - cell "SENDGRID" [ref=e397]:
                    - generic "sendgrid" [ref=e398]: SENDGRID
                  - 'cell "Copy timestamp as UTC: 2026-10-27 18:58:53.000000 UTC" [ref=e399]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 18:58:53.000000 UTC" [ref=e401]':
                      - time [ref=e402]: Oct 27, 2026, 6:58 PM
                - 'row "Open delivery for unknown@northstar.example Dispatched This message was handed to the provider. Delivery to the recipient has not been confirmed. Latest: Unknown POSTMARK Copy timestamp as UTC: 2026-10-27 18:56:53.000000 UTC" [ref=e403]':
                  - cell "Open delivery for unknown@northstar.example" [ref=e404]:
                    - button "Open delivery for unknown@northstar.example" [ref=e405]:
                      - generic [ref=e406]: unknown@northstar.example
                      - generic "Sam Rivera invited you to Northstar Logistics" [ref=e407]
                  - 'cell "Dispatched This message was handed to the provider. Delivery to the recipient has not been confirmed. Latest: Unknown" [ref=e408]':
                    - generic [ref=e409]:
                      - button "Dispatched" [ref=e410]:
                        - generic [ref=e411]: Dispatched
                      - generic [ref=e413]: This message was handed to the provider. Delivery to the recipient has not been confirmed.
                    - paragraph [ref=e414]: "Latest: Unknown"
                  - cell "POSTMARK" [ref=e415]:
                    - generic "postmark" [ref=e416]: POSTMARK
                  - 'cell "Copy timestamp as UTC: 2026-10-27 18:56:53.000000 UTC" [ref=e417]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 18:56:53.000000 UTC" [ref=e419]':
                      - time [ref=e420]: Oct 27, 2026, 6:56 PM
                - 'row "Open delivery for operations.billing.notifications.enterprise.accounts@northstar-stress.example Delivered The provider reported that the recipient''s mail server accepted this message. This does not confirm it reached the inbox or was read. POSTMARK Copy timestamp as UTC: 2026-10-27 18:54:53.000000 UTC" [ref=e421]':
                  - cell "Open delivery for operations.billing.notifications.enterprise.accounts@northstar-stress.example" [ref=e422]:
                    - button "Open delivery for operations.billing.notifications.enterprise.accounts@northstar-stress.example" [ref=e423]:
                      - generic [ref=e424]: operations.billing.notifications.enterprise.accounts@northstar-stress.example
                      - generic "Sam Rivera invited you to Northstar Logistics" [ref=e425]
                  - cell "Delivered The provider reported that the recipient's mail server accepted this message. This does not confirm it reached the inbox or was read." [ref=e426]:
                    - generic [ref=e427]:
                      - button "Delivered" [ref=e428]:
                        - generic [ref=e429]: Delivered
                      - generic [ref=e431]: The provider reported that the recipient's mail server accepted this message. This does not confirm it reached the inbox or was read.
                  - cell "POSTMARK" [ref=e432]:
                    - generic "postmark" [ref=e433]: POSTMARK
                  - 'cell "Copy timestamp as UTC: 2026-10-27 18:54:53.000000 UTC" [ref=e434]':
                    - 'button "Copy timestamp as UTC: 2026-10-27 18:54:53.000000 UTC" [ref=e436]':
                      - time [ref=e437]: Oct 27, 2026, 6:54 PM
        - generic:
          - link [ref=e438] [cursor=pointer]:
            - /url: /ops/mail?tenant_id=northstar&view=deliveries&window_hours=168
          - dialog "Quick view" [ref=e439]:
            - generic [ref=e440]:
              - heading "Quick view" [level=2] [ref=e441]
              - generic [ref=e442]:
                - generic "Previous delivery" [ref=e443]:
                  - generic [ref=e444]: Previous delivery unavailable
                - generic [ref=e446]: 1 of 16
                - link "Next delivery" [ref=e447] [cursor=pointer]:
                  - /url: /ops/mail?delivery_id=01a17f40-7806-76ff-a072-cf5fb3589809&tenant_id=northstar&window_hours=168
                - link "Close quick view" [active] [ref=e449] [cursor=pointer]:
                  - /url: /ops/mail?tenant_id=northstar&view=deliveries&window_hours=168
            - generic [ref=e451]:
              - generic [ref=e452]:
                - paragraph [ref=e453]: Subject
                - generic [ref=e454]:
                  - heading "INC-4421 is monitoring" [level=3] [ref=e455]
                  - generic [ref=e456]:
                    - button "Suppressed" [ref=e457]:
                      - generic [ref=e458]: Suppressed
                    - generic [ref=e460]: Sending to this recipient was blocked by a suppression rule.
                - paragraph [ref=e461]: To ops@northstar.example
              - paragraph [ref=e462]:
                - text: Updated
                - 'button "Copy timestamp as UTC: 2026-10-27 21:19:53.000000 UTC" [ref=e464]':
                  - time [ref=e465]: Oct 27, 2026, 9:19 PM
              - generic [ref=e466]:
                - generic [ref=e467]:
                  - term [ref=e468]: Account
                  - definition [ref=e469]: Northstar Logistics
                - generic [ref=e470]:
                  - term [ref=e471]: Provider
                  - definition [ref=e472]: SENDGRID
              - generic [ref=e475]:
                - term [ref=e476]: Delivery ID
                - definition [ref=e477]:
                  - button "Copy Delivery ID" [ref=e478]: 01a17f40-7807-75b7-9ff7-ba68444b25b0
              - generic [ref=e481]:
                - heading "Webhook replay" [level=2] [ref=e482]
                - paragraph [ref=e483]: Replay is unavailable. Historical rows without exact webhook linkage cannot be replayed safely.
            - link "Open full detail" [ref=e485] [cursor=pointer]:
              - /url: /ops/mail?delivery_id=01a17f40-7807-75b7-9ff7-ba68444b25b0&full=1&tenant_id=northstar&window_hours=168
              - text: Open full detail
              - generic [ref=e486]: →
```

# Test source

```ts
  747 |             element.getAnimations().every(animation => animation.playState === "finished")
  748 |           )
  749 |         ).toBe(true);
  750 | 
  751 |         const geometry = await panel.evaluate((panel, technicalSelector) => {
  752 |           const view = panel.ownerDocument.defaultView;
  753 |           const bounds = element => {
  754 |             const rect = element.getBoundingClientRect();
  755 |             return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom, width: rect.width, height: rect.height };
  756 |           };
  757 |           const panelRect = bounds(panel);
  758 |           const position = panel.querySelector("[aria-live=polite]");
  759 |           const close = panel.querySelector('[aria-label="Close quick view"]');
  760 |           const targetElements = [...panel.querySelectorAll("a[href], button")].filter(element => {
  761 |             const rect = element.getBoundingClientRect();
  762 |             return rect.width > 0 && rect.height > 0 && element.getAttribute("aria-hidden") !== "true";
  763 |           });
  764 |           const targets = targetElements.map(element => ({
  765 |             label: element.getAttribute("aria-label") || element.textContent.trim().slice(0, 40),
  766 |             ...bounds(element)
  767 |           }));
  768 |           const technical = panel.querySelector(`${technicalSelector} [data-copy-value]`);
  769 |           return {
  770 |             viewport: { width: view.innerWidth, height: view.innerHeight },
  771 |             panel: panelRect,
  772 |             reviewTheme: bounds(panel.ownerDocument.querySelector('[data-testid="quick-view-review-theme"]')),
  773 |             position: bounds(position),
  774 |             close: bounds(close),
  775 |             targets,
  776 |             technical: {
  777 |               text: technical.textContent.trim(),
  778 |               value: technical.dataset.copyValue,
  779 |               width: technical.clientWidth,
  780 |               scrollWidth: technical.scrollWidth,
  781 |               height: technical.clientHeight,
  782 |               overflowWrap: view.getComputedStyle(technical).overflowWrap,
  783 |               wordBreak: view.getComputedStyle(technical).wordBreak
  784 |             }
  785 |           };
  786 |         }, technicalSelector);
  787 |         expect(geometry.viewport.width).toBeGreaterThan(0);
  788 |         expect(geometry.reviewTheme.bottom, "theme controls do not obscure the quick view").toBeLessThanOrEqual(geometry.panel.top);
  789 |         expect(geometry.reviewTheme.left).toBeGreaterThanOrEqual(0);
  790 |         expect(geometry.reviewTheme.right).toBeLessThanOrEqual(geometry.viewport.width);
  791 |         expect(geometry.panel.left).toBeGreaterThanOrEqual(0);
  792 |         expect(geometry.panel.right).toBeLessThanOrEqual(geometry.viewport.width);
  793 |         expect(geometry.close.left).toBeGreaterThanOrEqual(geometry.panel.left);
  794 |         expect(geometry.close.right).toBeLessThanOrEqual(geometry.panel.right);
  795 |         expect(geometry.position.left).toBeGreaterThanOrEqual(geometry.panel.left);
  796 |         expect(geometry.position.right).toBeLessThanOrEqual(geometry.panel.right);
  797 |         for (const target of geometry.targets) {
  798 |           expect(target.width, `${target.label} target width at ${scenario.width}px`).toBeGreaterThanOrEqual(44);
  799 |           expect(target.height, `${target.label} target height at ${scenario.width}px`).toBeGreaterThanOrEqual(44);
  800 |           expect(target.left, `${target.label} left edge at ${scenario.width}px`).toBeGreaterThanOrEqual(geometry.panel.left);
  801 |           expect(target.right, `${target.label} right edge at ${scenario.width}px`).toBeLessThanOrEqual(geometry.panel.right);
  802 |         }
  803 |         expect(geometry.technical.text).toBe(geometry.technical.value);
  804 |         expect(geometry.technical.width).toBeGreaterThan(0);
  805 |         expect(geometry.technical.scrollWidth).toBeLessThanOrEqual(geometry.technical.width);
  806 |         expect(geometry.technical.overflowWrap).toBe("anywhere");
  807 | 
  808 |         const caseId = `width:${story.area}:${scenario.variant}:${scenario.width}:${scenario.theme}`;
  809 |         const receipt = {
  810 |           caseId,
  811 |           storyUrl: new URL(storyPath, BASE_URL).href,
  812 |           paneWidth: geometry.panel.width,
  813 |           viewportWidth: scenario.width,
  814 |           iframeViewportWidth: geometry.viewport.width,
  815 |           viewportHeight: geometry.viewport.height,
  816 |           scenario: scenario.selection,
  817 |           theme: scenario.theme,
  818 |           position: await position.innerText(),
  819 |           closeWithinPane: geometry.close.left >= geometry.panel.left && geometry.close.right <= geometry.panel.right,
  820 |           technicalWrapping: geometry.technical,
  821 |           controls: geometry.targets,
  822 |           reviewTheme: geometry.reviewTheme
  823 |         };
  824 |         receipts.push(receipt);
  825 | 
  826 |         if (screenshotWidths.has(scenario.width) && scenario.theme === "dark") {
  827 |           fs.mkdirSync(EVIDENCE_DIR, { recursive: true });
  828 |           const screenshot = path.join(EVIDENCE_DIR, `${story.area}-${scenario.width}-${scenario.selection}-dark.png`);
  829 |           await frame.locator("body").screenshot({ path: screenshot });
  830 |           receipt.screenshot = path.relative(REPO_ROOT, screenshot);
  831 |         }
  832 |       }
  833 | 
  834 |       appendFidelityEvidence("widths", {
  835 |         caseId: `widths:${story.area}:responsive-matrix`,
  836 |         cases: receipts
  837 |       });
  838 | 
  839 |       await page.emulateMedia({ reducedMotion: "reduce" });
  840 |       await page.setViewportSize({ width: 1280, height: 900 });
  841 |       const { panel, opener, focusReturnId } = await openProductionDeliveryQuickView(page);
  842 |       const next = panel.getByRole("link", { name: /Next delivery/ });
  843 |       const close = panel.getByRole("link", { name: "Close quick view" });
  844 |       await close.focus();
  845 |       await page.keyboard.press("Shift+Tab");
  846 |       await expect.poll(() => page.evaluate(() => document.activeElement?.getAttribute("aria-label")))
> 847 |         .toBe("Next delivery");
      |          ^ Error: expect(received).toBe(expected) // Object.is equality
  848 |       expect(await next.evaluate(element => element.matches(":focus-visible"))).toBe(true);
  849 |       const reducedMotionSeconds = await panel.evaluate(element => {
  850 |         const duration = getComputedStyle(element).animationDuration.split(",")[0].trim();
  851 |         return duration.endsWith("ms") ? parseFloat(duration) / 1000 : parseFloat(duration);
  852 |       });
  853 |       expect(reducedMotionSeconds).toBeLessThanOrEqual(0.00002);
  854 |       await page.keyboard.press("Escape");
  855 |       await expect(panel).toHaveCount(0);
  856 |       await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe(focusReturnId);
  857 |       await expect(opener).toBeFocused();
  858 |     });
  859 |   }
  860 | });
  861 | 
  862 | test("Phase 175 fidelity: current Delivery story, connected focus, assets, themes and actual zoom", async ({ browser }) => {
  863 |   test.setTimeout(90_000);
  864 |   const source = phase175SourceIdentity();
  865 |   const storyPath = "/dev/storybook/delivery_investigation?variation_id=fjordline_long_unicode";
  866 |   const storyUrl = new URL(storyPath, BASE_URL).href;
  867 |   const owner = '[data-theme-owner="delivery-investigation-story"]';
  868 |   const variant = "fjordline_long_unicode";
  869 |   const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  870 |   const page = await context.newPage();
  871 |   const fontResponses = new Map();
  872 |   page.on("response", response => {
  873 |     const filename = FONT_FILES.find(file => new URL(response.url()).pathname.endsWith(`/fonts/${file}`));
  874 |     if (filename && !fontResponses.has(filename)) {
  875 |       fontResponses.set(filename, {
  876 |         url: response.url(), status: response.status(),
  877 |         contentType: response.headers()["content-type"] || "", body: response.body()
  878 |       });
  879 |     }
  880 |   });
  881 | 
  882 |   const receipt = {
  883 |     caseId: "fidelity:delivery-investigation:long-unicode",
  884 |     source,
  885 |     selectedCaseCount: 10,
  886 |     expectedCaseCount: 10,
  887 |     executedCaseIds: [],
  888 |     themes: [],
  889 |     widths: [],
  890 |     screenshots: [],
  891 |     assets: {},
  892 |     hooks: {}
  893 |   };
  894 |   try {
  895 |     await page.emulateMedia({ colorScheme: "light" });
  896 |     const storyResponse = await page.goto(storyUrl, { waitUntil: "load" });
  897 |     expect(storyResponse?.status(), "the current-source Delivery investigation story returns 200").toBe(200);
  898 |     await waitForConnectedStoryHost(page);
  899 |     await scrollStoryFrameBelowHeader(page, variant);
  900 |     const frame = page.frameLocator(`iframe[id*="${variant}"]`);
  901 |     const root = frame.locator(owner);
  902 |     const main = frame.getByTestId("delivery-investigation-story");
  903 |     const picker = frame.getByTestId("delivery-investigation-review-theme");
  904 |     await expect(main).toHaveAttribute("data-scenario-id", "delivery-investigation-fjordline-long-unicode");
  905 |     await expect(root).toBeVisible();
  906 |     expect(await picker.evaluate(element => element.style.boxShadow)).toBe("var(--shadow-overlay)");
  907 |     expect(await picker.evaluate(element => getComputedStyle(element).boxShadow)).not.toBe("none");
  908 |     await expect(frame.getByTestId("operator-replay-reviewed-target")).toContainText(
  909 |       "wh_evt_fjordline_01JXW9ZQKB3V1N4P2RMT7FHCG"
  910 |     );
  911 |     const storyIframeUrl = await root.evaluate(element => element.ownerDocument.URL);
  912 |     const storyIframeSource = await page.locator(`iframe[id*="${variant}"]`).evaluate(iframe => ({
  913 |       hasSrcAttribute: iframe.hasAttribute("src"),
  914 |       srcdoc: iframe.getAttribute("srcdoc"),
  915 |       documentOrigin: iframe.contentWindow.location.origin,
  916 |       ownerOrigin: iframe.ownerDocument.defaultView.location.origin,
  917 |       parentAccessOrigin: iframe.contentWindow.eval("parent.location.origin")
  918 |     }));
  919 |     const storyIframeMode = storyIframeSource.srcdoc === null ? "url" : "srcdoc";
  920 |     receipt.executedCaseIds.push("story:delivery-investigation-fjordline-long-unicode");
  921 | 
  922 |     const light = frame.getByRole("radio", { name: "Light", exact: true });
  923 |     const dark = frame.getByRole("radio", { name: "Dark", exact: true });
  924 |     const system = frame.getByRole("radio", { name: "System", exact: true });
  925 |     await expect(system).toBeChecked();
  926 |     await expect.poll(() => root.getAttribute("data-theme")).toBe("mailglass-light");
  927 |     await page.emulateMedia({ colorScheme: "dark" });
  928 |     await expect.poll(() => root.getAttribute("data-theme")).toBe("mailglass-dark");
  929 |     const systemDark = await root.evaluate(element => ({
  930 |       preference: element.dataset.themePreference,
  931 |       resolved: element.dataset.themeResolved,
  932 |       os: element.dataset.themeOs,
  933 |       dataTheme: element.dataset.theme
  934 |     }));
  935 |     expect(systemDark).toEqual({ preference: "system", resolved: "dark", os: "dark", dataTheme: "mailglass-dark" });
  936 |     await light.click({ timeout: 5_000 });
  937 |     await expect(light).toBeChecked();
  938 |     await page.emulateMedia({ colorScheme: "light" });
  939 |     await dark.click({ timeout: 5_000 });
  940 |     await expect(dark).toBeChecked();
  941 |     await page.emulateMedia({ colorScheme: "light" });
  942 |     await expect.poll(() => root.getAttribute("data-theme")).toBe("mailglass-dark");
  943 |     await system.click({ timeout: 5_000 });
  944 |     await expect(system).toBeChecked();
  945 |     await expect.poll(() => root.getAttribute("data-theme")).toBe("mailglass-light");
  946 |     await page.emulateMedia({ colorScheme: "dark" });
  947 |     await expect.poll(() => root.getAttribute("data-theme")).toBe("mailglass-dark");
```