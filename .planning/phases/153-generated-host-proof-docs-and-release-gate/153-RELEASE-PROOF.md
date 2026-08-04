# Phase 153 Release Proof

This ledger is deliberately bounded and PII-free. It records release evidence only
after a command has been observed; it never contains credentials, recipient data,
or message content.

| Candidate SHA | Derived packages | Target versions | Gate | Observed at (UTC) | Result | Protected workflow URL |
| --- | --- | --- | --- | --- | --- | --- |
| `587c9d1a09944de02220b3fa121ce937677a8c3a` (`mailglass-v2.4.1`, environment-aligned cold-fixture/native-build release-CI replacement candidate) | `mailglass`, `mailglass_admin`, `mailglass_inbound` | `2.4.1`, `2.4.1`, `2.1.2` | isolated Linux/Elixir 1.18 fast-lane reproduction, cold fixture precompilation, inherited-test/dev endpoint smoke reproduction, three package checks, reproducible archives, protected publish environment, exact-SHA CI and advisory matrix | 2026-08-04T15:03:56Z | pass; corrected publication pending | [CI](https://github.com/szTheory/mailglass/actions/runs/30920859359), [advisory](https://github.com/szTheory/mailglass/actions/runs/30920861820) |

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

Before publication, record the exact candidate SHA, resolver output, target versions,
UTC timestamps, and green results for `DEP_MODE=local bash
scripts/generated_host_proof.sh --stage all`, `mix ci`, every resolver-selected
`mix mailglass.publish.check --package <package>`, and protected CI. The protected
workflow URL must refer to the same immutable SHA. No live publication has been
performed by this plan.

At 2026-08-03T19:54:02Z, the GitHub environment API reported that `hex-publish`
requires reviewer `szTheory`, permits that sole reviewer to approve their own
deployment, and does not permit administrator bypass.
