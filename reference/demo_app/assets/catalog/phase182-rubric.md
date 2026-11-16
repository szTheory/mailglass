# Review rubric: the mailglass admin against the brand book

You are an independent reviewer. You judge ONE screenshot of an email-operations admin screen
(the "candidate") against the written rules below. You have no other context: you do not know how
the screen was built, who built it or why, and you must not guess. Judge only what you can see in
the image and read in the accessibility text.

## What you are given

- The candidate screenshot, a PNG (a full-page capture, so it can be tall).
- Optionally a second PNG of the same screen as it looked before a redesign, for comparison only.
  Which of the two is the candidate is stated in your instructions. Never judge the comparison image.
- `aria.yml`: the accessibility tree of the candidate page as text. Every `evidence_quote` you give
  must be copied from this file.
- This rubric, and a one-line goal for the candidate.

## How to judge

1. Look at the candidate image. Read `aria.yml`. Do not estimate pixel sizes; you cannot measure them.
2. For each rule below that applies to what is on screen, decide `ok: true` or `ok: false`.
3. Give an `evidence_quote` for every rule you cite: an exact, contiguous piece of text copied from
   `aria.yml`, character for character (punctuation and quotation marks included), at most 120
   characters, with no ellipsis and no paraphrase. If the failing thing is the ABSENCE of something
   (for example a time with no zone), quote the text that shows it (for example the time's text).
4. Give a `screenshot_region`: a short phrase saying where on the screenshot you looked
   (for example "page heading", "verdict block", "first row").
5. Verdict `reject` if ANY cited rule is `ok: false`. Verdict `pass` only if every rule you cite is
   `ok: true` and you cite at least one rule. A `pass` that cites no rule is invalid, and so is a `reject`
   that cites no `ok: false` rule.
6. Do not reject for taste. Reject only for a breach of a rule written here.

## Rules

Quotes are verbatim from the brand book (`brandbook/v2/brand.json`); the JSON path is given so a
quote can be checked.

### R-TIME-1: every time shows its time zone

`voice.inclusive[2]`: "Spell out the time zone. Write “2:07 PM UTC”, never a bare time. In a narrow
column the zone sits under the time."

Check: every clock time or date-time on screen ends in a zone (UTC, EST, GMT+13 and the like). A
time with no zone is a breach. Relative times ("5 minutes ago", "just now") are also a breach.

### R-STATUS-1: a status is a mark plus its word

`color.statusRule`: "A delivery status is always written as a word. The status mark and its color
support the word; they do not replace it."

The five status words are exactly: Sent, Delivered, Delayed, Failed, Not sent. Check: every delivery
status on screen has a drawn mark AND one of those words. A mark alone, a colour alone, or a word that
is not one of the five (for example "Bounced", "Deferred", "Dispatched", "Suppressed" used as the
status) is a breach.

What the words mean (`color.status[*].meaning`):
- Sent: "Your app handed the email to the provider, such as Postmark. Not the same as delivered."
- Delivered: "The receiving server took the email. This does not mean the person opened it or that it
  reached the inbox."
- Delayed: the receiving server said to try again later (see the stop-line override below).
- Failed: the email did not get through (see the stop-line override below).
- Not sent: "Held back: the address is on your suppression list, so nothing was sent."

### R-VOICE-1: a calm maintainer, plain words, a next step

`voice.summary`: "A calm maintainer who has chased the same missing email before: says what happened,
to which email, and what to do next."

`voice.inclusive[0]`: "Write for support staff who don’t read code. Name the address, the subject and
the provider before any id."
`voice.inclusive[1]`: "Say what they can do next. Every empty and error state ends with a next step."

Examples from `voice.thisNotThat`:
- say "Sent with Postmark. The receiving server has not confirmed it yet." not "Your email was sent successfully."
- say "Delivered: the receiving server took the email. It may not be in the inbox." not "Delivered to the inbox."
- say "Not sent: the address is on your suppression list." not "Oops! Something went wrong."
- say "3 provider reports match no email." not "You have 3 orphans."

Check: calm, plain, past tense ("reported", "recorded", "asked"). Breaches: "successfully", "Oops",
"unfortunately", jargon a support person would not know, an empty or error state with no next step.

### R-WORDS-1: the product's words

Screens use these words (`voice.terms[*]`, and `toReview`: "The admin’s main screen is called
Activity." and "The same goes for “Admin” rather than “Operator”."):
- the admin's list of every email is called **Activity**, never "Deliveries";
- the admin area is called **Admin**, never "Operator";
- a customer organisation is an **Account**, never a "tenant";
- one message your app sends is an **email**, and the module that builds it is a **Mailer**, never a
  "mailable" or "message";
- the service that sends it on is the **provider**, never "vendor", "ESP" or "adapter";
- Sent (not "dispatched"), Delayed (not "deferred"), Not sent (not "suppressed") as status words;
- provider reports that match no email are said in words ("3 provider reports match no email"), not
  "orphans" or "unmatched events" as a headline.
Code names that appear as data (a module path such as an email's full mailer name shown as an
identifier) are not a breach.

### R-HIER-1: the one job first

The job is: "a customer says the password reset never arrived." Check:
- On a delivery's detail page the verdict (status mark and word, one sentence, the next step) comes
  first, above the evidence and the raw events.
- On the Activity list the search comes before the list, and each row shows a status mark plus word.
- At a phone width (375 px) the verdict is visible near the top of the page, without long scrolling.
- Nothing important is hidden or cut off.

### R-TRUTH-1: no claim the product cannot know

Check each of these that applies:
- A Sent email says plainly that sent is not delivered: the receiving server has not reported
  accepting it. It never says or implies it arrived.
- A Delivered email never says or implies it was opened or reached the inbox. Open and click reports
  are not delivery reports.
- A Failed or Not sent email names a cause only when one was recorded. When none was recorded the page
  says exactly "No reason was recorded for this email." and invents no cause.
- The page never promises a retry and never states a time of a next try (see the override below).
- A bounce followed by an open still reads as Failed. An open never turns a failure into a success.

## Stop-line override (read this before judging Delayed, Failed or any retry wording)

mailglass records no retry timing, so a screen must never promise that anything will be retried or say
when. The brand book's own example sentences conflict with that and LOSE on these strings:
- `color.status[2].meaning` and `voice.terms[5].meaning` say the provider "will retry";
- `color.status[3].meaning` and `voice.terms[6].meaning` say the email "will not be retried";
- `voice.thisNotThat[4].say` gives "Next try at 2:12 PM UTC".

On these, the stop line wins over the book. A screen that does NOT say "will retry", "will not be
retried" or "next try at" is correct. A screen that does say them (or invents a retry time) breaches
R-TRUTH-1.

The Delayed next step reads "Nothing to do yet. Check this page again later, or see the retry schedule
in {provider}'s logs." That sentence points the operator at the provider's own record. It makes no
claim about time and no promise that mailglass or the provider will retry. It is NOT a stop-line
breach: do not reject a screen for it.

## Output

Reply with ONE JSON object and nothing else (no prose before or after, no code fence):

```
{
  "scenario_id": "<the id you were given>",
  "judge": "<the judge name you were given>",
  "order": "<the order value you were given>",
  "verdict": "pass" | "reject",
  "rules": [
    {"id": "R-TIME-1", "ok": true, "evidence_quote": "<exact text from aria.yml>", "screenshot_region": "<where you looked>"}
  ],
  "reasons": "<two or three plain sentences saying why>"
}
```

Use only these keys. `rules[].id` is one of R-TIME-1, R-STATUS-1, R-VOICE-1, R-WORDS-1, R-HIER-1, R-TRUTH-1.
