# Phase 153 Release Proof

This ledger is deliberately bounded and PII-free. It records release evidence only
after a command has been observed; it never contains credentials, recipient data,
or message content.

| Candidate SHA | Derived packages | Target versions | Gate | Observed at (UTC) | Result | Protected workflow URL |
| --- | --- | --- | --- | --- | --- | --- |
| _pending immutable candidate_ | _pending resolver run_ | _pending Release Please output_ | all required gates | _pending_ | _not yet observed_ | _not yet pushed_ |

## Ledger data (authoritative JSON)

```release-proof
{
  "candidate": {"sha": null, "tag": null},
  "publication": {
    "workflow_path": ".github/workflows/publish-hex.yml",
    "workflow_name": "publish-hex",
    "environment": "hex-publish",
    "run_id": null,
    "run_url": null
  },
  "release_packages": [],
  "target_versions": {},
  "archive_checksums": {}
}
```

## Required candidate evidence

Before publication, record the exact candidate SHA, resolver output, target versions,
UTC timestamps, and green results for `DEP_MODE=local bash
scripts/generated_host_proof.sh --stage all`, `mix ci`, every resolver-selected
`mix mailglass.publish.check --package <package>`, and protected CI. The protected
workflow URL must refer to the same immutable SHA. No live publication has been
performed by this plan.
