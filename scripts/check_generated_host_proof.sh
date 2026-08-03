#!/usr/bin/env bash
set -euo pipefail

CHECKPOINT="tmp/generated-host-proof/checkpoint.json"
[[ "${1:-}" == "--checkpoint" ]] && { CHECKPOINT="${2:-}"; shift 2; }
[[ $# -eq 0 && -f "$CHECKPOINT" ]] || { echo "generated-host checkpoint blocked: missing --checkpoint file" >&2; exit 1; }

python3 - "$CHECKPOINT" <<'PY'
import json, re, sys
p=json.load(open(sys.argv[1]))
bad=[]
if set(p)-{"schema_version","dependency_mode","source_sha256","packages","stages","overall_status","checkpoint_sha256"}: bad.append("unallowlisted top-level key")
if p.get("schema_version")!="generated_host_proof.v1": bad.append("schema version")
stages=p.get("stages",[]); names=[s.get("name") for s in stages]
if not stages or len(names)!=len(set(names)): bad.append("missing or duplicate stages")
if any(s.get("status") not in ("passed","failed") for s in stages): bad.append("invalid stage status")
if p.get("overall_status")=="passed" and any(s.get("status")!="passed" for s in stages): bad.append("successful proof contains failed stage")
for stage in stages:
    if stage.get("name") == "async_parity":
        required={"name","status","job_inserted","job_terminal","delivery_sent","payload_scrubbed","event_count","capture_count","transition_order_sha256","parity_sha256"}
        if set(stage) != required: bad.append("async parity stage shape")
        if not all(stage.get(key) is True for key in ("job_inserted","job_terminal","delivery_sent","payload_scrubbed")): bad.append("async parity durable settlement")
        if not isinstance(stage.get("event_count"), int) or stage.get("event_count", 0) < 2: bad.append("async parity event count")
        if not isinstance(stage.get("capture_count"), int) or stage.get("capture_count", 0) < 2: bad.append("async parity capture count")
        if not all(re.fullmatch(r"[0-9a-f]{64}", str(stage.get(key, ""))) for key in ("transition_order_sha256","parity_sha256")): bad.append("async parity hashes")
raw=json.dumps(p).lower()
if any(word in raw for word in ("recipient","password","secret","token","database_url","postgres://","body","webhook")): bad.append("forbidden privacy material")
if p.get("dependency_mode")=="hex" and any("path" in str(x).lower() or "git" in str(x).lower() for x in p.get("packages",[])): bad.append("hex dependency identity")
if bad: print("generated-host checkpoint blocked: "+", ".join(bad), file=sys.stderr); sys.exit(1)
print("generated-host checkpoint OK")
PY
