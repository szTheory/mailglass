# Phase 153 Release Proof

This ledger is deliberately bounded and PII-free. It records release evidence only
after a command has been observed; it never contains credentials, recipient data,
or message content.

| Candidate SHA | Derived packages | Target versions | Gate | Observed at (UTC) | Result | Protected workflow URL |
| --- | --- | --- | --- | --- | --- | --- |
| `587c9d1a09944de02220b3fa121ce937677a8c3a` (`mailglass-v2.4.1`, environment-aligned cold-fixture/native-build release-CI replacement candidate) | `mailglass`, `mailglass_admin`, `mailglass_inbound` | `2.4.1`, `2.4.1`, `2.1.2` | exact-SHA CI/advisory matrix, protected publication, exact-Hex generated-host journey, published reference-host trust journey, Hex/HexDocs/not-retracted checks | 2026-08-04T16:21:38Z | pass; published and post-publication verified | [CI](https://github.com/szTheory/mailglass/actions/runs/30920859359), [advisory](https://github.com/szTheory/mailglass/actions/runs/30920861820), [publish](https://github.com/szTheory/mailglass/actions/runs/30922262406), [post-publish](https://github.com/szTheory/mailglass/actions/runs/30927455604) |

## Ledger data (authoritative JSON)

```release-proof
{
  "candidate": {
    "sha": "587c9d1a09944de02220b3fa121ce937677a8c3a",
    "tag": "mailglass-v2.4.1"
  },
  "prepublication": {
    "ci": {
      "run_id": 30920859359,
      "run_url": "https://github.com/szTheory/mailglass/actions/runs/30920859359"
    },
    "advisory": {
      "run_id": 30920861820,
      "run_url": "https://github.com/szTheory/mailglass/actions/runs/30920861820"
    }
  },
  "publication": {
    "workflow_path": ".github/workflows/publish-hex.yml",
    "workflow_name": "publish-hex",
    "environment": "hex-publish",
    "environment_protection": {
      "observed_at": "2026-08-03T19:54:02Z",
      "required_reviewer": "szTheory",
      "prevent_self_review": false,
      "can_admins_bypass": false
    },
    "run_id": 30922262406,
    "run_url": "https://github.com/szTheory/mailglass/actions/runs/30922262406"
  },
  "postpublication": {
    "workflow_path": ".github/workflows/post-publish-smoke.yml",
    "workflow_name": "post-publish-smoke",
    "run_id": 30927455604,
    "run_url": "https://github.com/szTheory/mailglass/actions/runs/30927455604",
    "workflow_sha": "cca6b0619120de0b0f53d4d335adb7ca304813d7",
    "release_ref": "mailglass-v2.4.1",
    "release_sha": "587c9d1a09944de02220b3fa121ce937677a8c3a",
    "observed_at": "2026-08-04T16:21:38Z",
    "conclusion": "success",
    "exact_hex_journey": {
      "job_id": 92053541965,
      "conclusion": "success"
    },
    "published_trust_journey": {
      "job_id": 92056645363,
      "conclusion": "success",
      "artifact_id": 8900195536,
      "artifact_sha256": "646f4ccfec9c7cfc56ffd7fbb219a5ae959b502a840c1295a1f06e8d75d38459"
    },
    "not_retracted": {
      "job_id": 92056645569,
      "conclusion": "success"
    }
  },
  "release_packages": ["mailglass", "mailglass_admin", "mailglass_inbound"],
  "target_versions": {
    "mailglass": "2.4.1",
    "mailglass_admin": "2.4.1",
    "mailglass_inbound": "2.1.2"
  },
  "archive_checksums": {
    "mailglass": "364bd0b97955dd021a71b685c44d9748e51bc01d6350fb6a475beaac95767268",
    "mailglass_admin": "50944118e771bceefc31a6ebcd097339fa2212f092eab49fa0903603d27f2589",
    "mailglass_inbound": "1c98e323d7cb65bf20a624893604b2f2e8314e462913027c80ac47a3e734d730"
  }
}
```

## Required candidate evidence

Before publication, the exact candidate SHA, resolver output, target versions,
UTC timestamps, local generated-host proof, package checks, and protected CI were
recorded. Protected run `30922262406` then published the exact three-package set.
Post-publication run `30927455604` checked out `mailglass-v2.4.1` at
`587c9d1a09944de02220b3fa121ce937677a8c3a`, resolved and installed exact Hex
versions `2.4.1`, `2.4.1`, and `2.1.2`, completed the full generated-host journey,
completed the published reference-host trust journey, and confirmed the releases
and HexDocs remained available and unretracted. Its workflow implementation ran
from follow-up SHA `cca6b0619120de0b0f53d4d335adb7ca304813d7`; this did not move or replace
the immutable published tag.

At 2026-08-03T19:54:02Z, the GitHub environment API reported that `hex-publish`
requires reviewer `szTheory`, permits that sole reviewer to approve their own
deployment, and does not permit administrator bypass.
