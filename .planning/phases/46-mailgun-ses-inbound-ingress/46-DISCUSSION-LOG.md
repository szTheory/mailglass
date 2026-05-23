# Phase 46: Mailgun + SES Inbound Ingress - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in 46-CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-23
**Phase:** 46-mailgun-ses-inbound-ingress
**Mode:** assumptions
**Areas analyzed:** Cross-package verifier reuse; Provider dispatch + result contract;
Mailgun multipart/MIME/dedupe; SES delivery modes/S3Fetcher/OptionalDeps/error; New
inbound errors + scope/dependency boundary.

## Pre-flight: roadmap state repair

`init.phase-op 46` initially returned `phase_found:false`. Root cause: Phase-45 planning
had overwritten `.planning/ROADMAP.md` with Phase 45's plan list, dropping the v1.2
milestone roadmap. Restored the pristine milestone roadmap from commit `a5143d1`
(pre-execution) — deliberately NOT from the abandoned `preserve-local-main-20260508`
timeline that erroneously marked Phases 46/47/48 complete. Verified no Phase 46 code
(Mailgun/SES/S3Fetcher modules) survives in the working tree. Corrected status to
authoritative STATE.md reality (44.5 + 45 complete, 46 next). Committed as
`docs(roadmap): restore v1.2 milestone roadmap`. `init.phase-op 46` then resolved.

The provider-scope decision SYNTHESIS flagged as "VERY impactful" (Mailgun + SES yes;
defer Cloudflare + gen_smtp) was already locked in REQUIREMENTS.md — not re-asked.

## Assumptions Presented

### A1 · Cross-package verifier reuse
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extract shape-agnostic verifier primitives (Mailgun HMAC+replay; SES X.509→payload) into shared fns both packages call; reuse running core caches (no 2nd singleton); leave outbound JSON-decode + `%Event{}` untouched | Likely | `mailgun.ex:20-45` (conn-free but `Jason.decode`s body), `ses.ex` X.509 envelope-identical, caches `application.ex:32-37`, inbound `{:mailglass, path:".."}` |

### A2 · Provider dispatch unification + result contract
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Allowlist→4 providers as one switch; widen result contract to `{:ok,facts}` / `{:control_plane,status}` / `{:replay}` (200 no-ops); one `case` in `do_call/2` | Confident | `plug.ex:36-39` two-provider allowlist, `plug.ex:54-82` persist-always, `plug.ex:241-247` discards `verify!` return |

### A3 · Mailgun multipart normalization + MIME routing + dedupe
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Signature triple = top-level form fields; raw-MIME via `…/mime` URL suffix → `MailglassInbound.MIME.parse/1`; parsed-mode fallback; dedupe via `Message-Id` from `message-headers`; MD5(raw) fallback; `token` ≠ identity | Confident (post-research) | Mailgun docs (field placement, URL-suffix raw-MIME, `message-headers`); `mime.ex:60-61` first-consumer; `persist.ex:81-101` fingerprint precedent |

### A4 · SES delivery modes / S3Fetcher / OptionalDeps / error
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| S3 action primary (`bucketName`/`objectKey==messageId`); SNS-inline ≤150KB secondary; `S3Fetcher` behaviour + `Fake` core + `ExAwsS3` behind inbound-local `MailglassInbound.OptionalDeps.ExAwsS3` (SESI-04 wording erratum); SESI-05 = idempotency+SNS-redelivery + small bounded retry; new inbound-local `S3FetchError`; KMS scope-out | Likely | `optional_deps.ex:6` inbound-local contract + `.Oban`; AWS SES docs; S3 strong-consistency since 2020; `ex_aws_s3` API + `sweet_xml` runtime req |

### A5 · New inbound errors, scope boundary, dependency departure
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `MailglassInbound.SignatureError` net-new (no-recovery, mirrors outbound); docs MGUN-05/SESI-06 deferred to Phase 50; `ex_aws*` = first new optional dep since v1.0 STACK lock | Confident | grep: no inbound SignatureError (only `mime_error.ex`); REQUIREMENTS.md phase mapping; STACK.md "add none" |

## Corrections Made

No corrections — user selected "Yes, proceed (Recommended)"; all five assumptions
locked with their recommended defaults. The two Likely items retain documented override
options in 46-CONTEXT.md (A1 reuse-caches+reimplement-HMAC; A4 core gateway placement).

## External Research

Spawned a research agent (research-first per `workflow.research_before_questions: true`).

- **Mailgun inbound payload:** signature triple = top-level multipart form fields
  `timestamp`/`token`/`signature` (not nested JSON); HMAC-SHA256 of `timestamp<>token`
  identical to outbound; raw MIME (`body-mime`) opt-in by **route URL suffix `…/mime`**
  (not action type); no flat `Message-Id` → parse from `message-headers` JSON field;
  attachments via `attachment-count`/`attachment-N`/`content-id-map`.
  Source: Mailgun receive-http + securing-webhooks docs. → A3 to Confident.
- **SES inbound + S3 race:** `receipt.action.type=="S3"` carries `bucketName`+`objectKey`
  (`objectKey==messageId`; `objectKeyPrefix` config-only); SNS-inline `content` ≤150KB
  (UTF-8/Base64) else bounce → S3 is primary. S3 strongly consistent since Dec 2020;
  SES notifies after PutObject → real driver is idempotency-on-objectKey + SNS
  at-least-once redelivery, only small bounded retry warranted. New risk: SES
  client-side KMS encryption breaks plain GetObject → scope out.
  Source: AWS SES receiving-email docs. → reframed SESI-05, added D-46-18.
- **ex_aws_s3:** `ex_aws ~> 2.7` / `ex_aws_s3 ~> 2.5`; `get_object |> ExAws.request →
  {:ok,%{body:binary}}`; runtime deps incl. **`sweet_xml`** (non-obvious), HTTP client
  (hackney/req), jason; standard credential chain, no mailglass config. STACK.md does
  not pin these (records "add none") → noted as deliberate departure (D-46-20).
  Source: hex.pm/hexdocs ex_aws + ex_aws_s3.
