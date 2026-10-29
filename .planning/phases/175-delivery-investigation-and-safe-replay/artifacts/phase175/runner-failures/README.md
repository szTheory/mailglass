# Phase 175 Runner Failure History

These directories retain failed attempts and their run-owned receipts. The current passing proof is the separate `mailglass-evidence-20261027221513-96275-31939` cold/warm evidence under `../phase174/` and `../phase175/`, with full stdout at `../runner-success-mailglass-evidence-20261027221513-96275-31939.log`.

| Run ID | Retained failure | Record |
| --- | --- | --- |
| `mailglass-evidence-20261027211900-29536-25124` | Warm Phase 174 responsive layout test flake. | `.../phase174/failure.json` and `.../phase174/failed/` |
| `mailglass-evidence-20261027212751-43201-18481` | Baseline preparation helper waited for stdin EOF. Only the run-owned runner was interrupted after diagnosis; its EXIT cleanup removed its Compose resources. | `.../phase174/failure.json` and `.../phase174/failed/` |
| `mailglass-evidence-20261027213840-55935-13202` | Combined run did not pass its final source recheck. | `.../phase174/failure.json` and `.../phase174/failed/` |
| `mailglass-evidence-20261027215211-71763-23440` | Combined run exited 1 with `ERROR: Phase 175 selected-source digest is stale`. The bind-mounted lock diff shows `boundary` 0.11.0 → 0.12.0 and `websock_adapter` 0.6.0 → 0.7.0. | `.../phase174/failure.json`, `.../phase175/run.json`, and `mix-lock-diff.txt` |

The full raw stdout for the 21:52 run was not retained after the temporary monitor log path was reused. The exact error above was captured and reported during the run; the failure marker, Phase 175 receipts, and full lock diff remain available. A file previously named `runner-output.log` beside the 21:52 marker was found to belong to a separate successful 22:03 run, so it was moved to `../historical-success/mailglass-evidence-20261027220352-88369-29369/` and is not presented as failure output.

The 22:15 run is the source-bound passing proof. Failed markers and reports above remain historical and do not qualify the latest result as failed or incomplete.
