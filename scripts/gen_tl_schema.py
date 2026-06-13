#!/usr/bin/env python3
"""Build a compact constructor-id -> definition map from Telegram TL schema (.tl) files.

Output JSON (scripts/tl_schema.json) is consumed by mtproto_decode.py to turn the raw
MTProto logger output into a readable view. The .tl format is:

    ---types---
    name#crchex {gen:Type} field:Type field2:flags.N?Type ... = ResultType;
    ---functions---
    method#crchex ... = ResultType;

Canonical source is the official Telegram Desktop schema (the most current layer). Refresh with:

    cd scripts
    B=https://raw.githubusercontent.com/telegramdesktop/tdesktop/<commit>/Telegram/SourceFiles/mtproto/scheme
    curl -sO "$B/api.tl"; curl -sO "$B/mtproto.tl"
    PG_TL_SOURCE="tdesktop@<commit> api.tl+mtproto.tl" ./gen_tl_schema.py api.tl mtproto.tl > tl_schema.json

Current tl_schema.json: tdesktop@3887c78 (LAYER 227). A few transport constructors are commented
out in mtproto.tl ("parsed manually" — rpc_result / msg_container / gzip_packed); they're folded
in from MTPROTO_CORE below so they still decode.

Usage: scripts/gen_tl_schema.py <schema.tl> [more.tl ...] > scripts/tl_schema.json
"""
import json, os, re, sys

# Core MTProto transport layer (mtproto.tl) — not in the API .tl but seen in the stream.
MTPROTO_CORE = {
    "5bb8e511": ("message", [["msg_id", "long"], ["seqno", "int"], ["bytes", "int"], ["body", "Object"]], "Message", "types"),
    "73f1f8dc": ("msg_container", [["messages", "vector<%Message>"]], "MessageContainer", "types"),
    "f35c6d01": ("rpc_result", [["req_msg_id", "long"], ["result", "Object"]], "RpcResult", "types"),
    "2144ca19": ("rpc_error", [["error_code", "int"], ["error_message", "string"]], "RpcError", "types"),
    "62d6b459": ("msgs_ack", [["msg_ids", "Vector<long>"]], "MsgsAck", "types"),
    "347773c5": ("pong", [["msg_id", "long"], ["ping_id", "long"]], "Pong", "types"),
    "a7eff811": ("bad_msg_notification", [["bad_msg_id", "long"], ["bad_msg_seqno", "int"], ["error_code", "int"]], "BadMsgNotification", "types"),
    "edab447b": ("bad_server_salt", [["bad_msg_id", "long"], ["bad_msg_seqno", "int"], ["error_code", "int"], ["new_server_salt", "long"]], "BadMsgNotification", "types"),
    "3072cfa1": ("gzip_packed", [["packed_data", "bytes"]], "Object", "types"),
    "9ec20908": ("new_session_created", [["first_msg_id", "long"], ["unique_id", "long"], ["server_salt", "long"]], "NewSession", "types"),
    "276d3ec6": ("msg_detailed_info", [["msg_id", "long"], ["answer_msg_id", "long"], ["bytes", "int"], ["status", "int"]], "MsgDetailedInfo", "types"),
    "809db6df": ("msg_new_detailed_info", [["answer_msg_id", "long"], ["bytes", "int"], ["status", "int"]], "MsgDetailedInfo", "types"),
}

def parse(paths):
    by_id = {}
    layer = None
    section = "types"
    layer_re = re.compile(r'//\s*LAYER\s+(\d+)')
    # Result type is lenient (`.+?`) so generic results like `Vector t` parse too.
    line_re = re.compile(r'^([A-Za-z0-9_.]+)#([0-9a-fA-F]+)\s*(.*?)\s*=\s*(.+?)\s*;')
    for path in paths:
        for raw in open(path, encoding="utf-8", errors="replace"):
            line = raw.strip()
            lm = layer_re.search(line)
            if lm:
                layer = int(lm.group(1))
            if line == "---functions---":
                section = "functions"; continue
            if line == "---types---":
                section = "types"; continue
            if not line or line.startswith("//"):
                continue
            m = line_re.match(line)
            if not m:
                continue
            name, cid, args, restype = m.groups()
            cid = cid.lower().rjust(8, "0")
            # Strip generic decls {x:Type} and split remaining "pname:ptype" tokens.
            args = re.sub(r'\{[^}]*\}', ' ', args)
            params = []
            for tok in args.split():
                if ":" not in tok:
                    continue
                pname, ptype = tok.split(":", 1)
                params.append([pname, ptype])
            by_id[cid] = (name, params, restype, section)
    return by_id, layer

def main():
    if len(sys.argv) < 2:
        sys.exit("usage: gen_tl_schema.py <schema.tl> [more.tl ...]  (set PG_TL_SOURCE for provenance)")
    parsed, layer = parse(sys.argv[1:])
    by_id = dict(MTPROTO_CORE)
    by_id.update(parsed)  # API schema wins over any core overlap
    out = {
        "layer": layer,
        "source": os.environ.get("PG_TL_SOURCE", ""),
        "by_id": {cid: {"name": n, "params": p, "type": t, "section": s}
                  for cid, (n, p, t, s) in by_id.items()},
    }
    sys.stdout.write(json.dumps(out, ensure_ascii=False, sort_keys=True))
    sys.stderr.write(f"layer {layer}, constructors: {len(by_id)}\n")

if __name__ == "__main__":
    main()
