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
    if stage.get("name") == "negative_controls":
        if set(stage) != {"name","status","controls"} or not stage.get("controls"): bad.append("negative controls stage shape")
        effect_keys={"jobs","deliveries","events","payloads","captures","renders","tasks"}
        for control in stage.get("controls",[]):
            if set(control) != {"name","reason_class","result","before","after"}: bad.append("negative control shape"); continue
            if not isinstance(control.get("name"),str) or not isinstance(control.get("reason_class"),str) or control.get("result") != "rejected": bad.append("negative control bounded rejection")
            before=control.get("before"); after=control.get("after")
            if set(before or {}) != effect_keys or set(after or {}) != effect_keys: bad.append("negative control effect vector")
            elif not all(isinstance(v,int) and v >= 0 for v in before.values()) or before != after: bad.append("negative control all zero delta")
    if stage.get("name") == "feedback":
        required={"name","status","valid_status","valid_body_bytes","forged_status","forged_body_bytes","ingress_event_count","ledger_event_count","forged_effects_zero"}
        if set(stage) != required: bad.append("feedback stage shape")
        elif stage.get("valid_status") != 200 or stage.get("valid_body_bytes") != 0 or stage.get("forged_status") != 401 or stage.get("forged_body_bytes") != 0 or not stage.get("forged_effects_zero") or not all(isinstance(stage.get(key),int) and stage[key] >= 1 for key in ("ingress_event_count","ledger_event_count")): bad.append("feedback HTTP durable proof")
    if stage.get("name") == "one_click":
        required={"name","status","first_status","first_body_bytes","replay_status","replay_body_bytes","canonical_event_count","canonical_suppression_count","matching_send","transactional_send","unrelated_stream_send","matching_capture_growth","control_capture_growth"}
        if set(stage) != required: bad.append("one-click stage shape")
        elif (stage.get("first_status"), stage.get("first_body_bytes"), stage.get("replay_status"), stage.get("replay_body_bytes"), stage.get("canonical_event_count"), stage.get("canonical_suppression_count"), stage.get("matching_send"), stage.get("transactional_send"), stage.get("unrelated_stream_send"), stage.get("matching_capture_growth"), stage.get("control_capture_growth")) != (200,0,200,0,1,1,"suppressed","sent","sent",0,2): bad.append("one-click convergence and scope")
    if stage.get("name") == "operator_readiness":
        required={"name","status","preflight_ready","anonymous_status","authenticated_status"}
        if set(stage) != required: bad.append("operator readiness stage shape")
        elif stage.get("preflight_ready") is not True or (stage.get("anonymous_status"), stage.get("authenticated_status")) != (401,200): bad.append("operator readiness authentication")
raw=json.dumps(p).lower()
if re.search(r"[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9.-]+\.[a-z]{2,}", raw) or any(word in raw for word in ("password","secret","token","database_url","postgres://")): bad.append("forbidden privacy material")
if p.get("dependency_mode")=="hex" and any("path" in str(x).lower() or "git" in str(x).lower() for x in p.get("packages",[])): bad.append("hex dependency identity")
if bad: print("generated-host checkpoint blocked: "+", ".join(bad), file=sys.stderr); sys.exit(1)
print("generated-host checkpoint OK")
PY
