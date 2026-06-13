#!/usr/bin/env python3
"""Decode a Patchgram MTProto logger file into a human-readable view.

The dylib logs raw lines:
    [time] -> REQUEST  reqId=12 constructor=b60f5918 name=... words=10 body=b60f5918f7c1b13f
This tool resolves every TL constructor to its schema name and recursively decodes the body
(flags, Vector, boxed types, strings, gzip_packed), e.g.:
    [time] -> REQUEST  reqId=12 users.getFullUser#b60f5918 { id=inputUserSelf }

It never crashes on malformed/partial data: anything it cannot parse is shown as raw hex, so a
truncated response body (the dylib caps body= at 48 words) still decodes as far as it goes.

Usage:
    scripts/mtproto_decode.py <log> [--schema scripts/tl_schema.json] [--requests] [--out FILE]
Writes <log>.decoded.txt (or --out) and prints the first lines. --requests = only -> REQUEST.
"""
import argparse, json, os, re, sys, zlib

BUILTIN_SCHEMA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tl_schema.json")
LINE_RE = re.compile(
    r'^\[(?P<time>[^\]]+)\]\s+(?P<dir>\S+(?:\s\S+)?)\s+reqId=(?P<rid>-?\d+)\s+'
    r'constructor=(?P<ctor>[0-9a-f]+)\s+name=\S+\s+words=(?P<words>\d+)\s+body=(?P<body>[0-9a-f]*)(?P<trunc>\.\.\.\(\+\d+\))?\s*$'
)
MAX_DEPTH = 40

class Reader:
    def __init__(self, data):
        self.d = data
        self.p = 0
    def left(self):
        return len(self.d) - self.p
    def take(self, n):
        if self.p + n > len(self.d):
            raise EOFError(f"need {n}, have {self.left()}")
        b = self.d[self.p:self.p + n]
        self.p += n
        return b
    def u32(self):
        return int.from_bytes(self.take(4), "little")
    def i32(self):
        return int.from_bytes(self.take(4), "little", signed=True)
    def i64(self):
        return int.from_bytes(self.take(8), "little", signed=True)
    def f64(self):
        import struct
        return struct.unpack("<d", self.take(8))[0]
    def raw(self, n):
        return self.take(n).hex()
    def tlbytes(self):
        first = self.take(1)[0]
        if first < 254:
            ln = first
            head = 1
        else:
            ln = int.from_bytes(self.take(3), "little")
            head = 4
        body = self.take(ln)
        pad = (-(head + ln)) % 4
        if pad:
            self.take(pad)
        return body

def words_to_bytes(hexbody):
    # body= is a run of %08x uint32 VALUES; the wire bytes are each value little-endian packed.
    out = bytearray()
    for i in range(0, len(hexbody), 8):
        chunk = hexbody[i:i + 8]
        if len(chunk) < 8:
            break
        out += int(chunk, 16).to_bytes(4, "little")
    return bytes(out)

class Decoder:
    def __init__(self, schema):
        self.by_id = schema["by_id"]

    def name(self, cid):
        e = self.by_id.get(cid)
        return e["name"] if e else None

    def fmt_str(self, b):
        try:
            s = b.decode("utf-8")
            if all(31 < ord(c) < 0x110000 and c not in "\x7f" for c in s):
                return '"' + (s if len(s) <= 80 else s[:80] + "…") + '"'
        except Exception:
            pass
        h = b.hex()
        return "0x" + (h if len(h) <= 80 else h[:80] + "…")

    def decode_type(self, t, r, depth):
        if depth > MAX_DEPTH:
            return "<maxdepth>"
        t = t.strip()
        low = t.lower()
        if low in ("int", "#"):
            return r.i32()
        if low == "long":
            return r.i64()
        if low == "double":
            return r.f64()
        if low == "string":
            return self.fmt_str(r.tlbytes())
        if low == "bytes":
            return "0x" + r.tlbytes().hex()[:80]
        if low == "int128":
            return "0x" + r.raw(16)
        if low == "int256":
            return "0x" + r.raw(32)
        if low == "true":
            return True
        if low == "bool":
            return self.decode_boxed(r, depth)
        m = re.match(r'[Vv]ector<(.+)>$', t)
        if m:
            inner = m.group(1)
            if t[0] == "V":  # boxed Vector carries the 0x1cb5c415 vector ctor on the wire
                cid = format(r.u32(), "08x")
                if cid != "1cb5c415":
                    return f"<expected vector got #{cid}>"
            n = r.i32()
            items = []
            for _ in range(n):
                if r.left() <= 0:
                    items.append("…")
                    break
                items.append(self.decode_type(inner, r, depth + 1))
            return items
        # Otherwise a boxed type (e.g. InputUser, MessageMedia, Object, !X, %Type, generic).
        return self.decode_boxed(r, depth)

    def decode_boxed(self, r, depth):
        cid = format(r.u32(), "08x")
        return self.decode_ctor(cid, r, depth)

    def decode_ctor(self, cid, r, depth):
        if cid == "3072cfa1":  # gzip_packed: gunzip then decode the inner boxed object
            packed = r.tlbytes()
            try:
                inner = zlib.decompress(packed, 16 + zlib.MAX_WBITS)
                return {"gzip_packed": self.decode_boxed(Reader(inner), depth + 1)}
            except Exception:
                return {"gzip_packed": "0x" + packed.hex()[:60]}
        e = self.by_id.get(cid)
        if not e:
            return f"unknown#{cid}"
        if not e["params"]:
            return e["name"]
        flags = {}
        out = {}
        for pname, ptype in e["params"]:
            if ptype == "#":
                v = r.u32()
                flags[pname] = v
                out[pname] = f"0x{v:x}"
                continue
            cond = re.match(r'(\w+)\.(\d+)\?(.+)$', ptype)
            if cond:
                fvar, bit, sub = cond.group(1), int(cond.group(2)), cond.group(3)
                if not (flags.get(fvar, 0) >> bit) & 1:
                    continue
                if sub == "true":
                    out[pname] = True
                    continue
                ptype = sub
            out[pname] = self.decode_type(ptype, r, depth + 1)
        return {e["name"]: out}

    def decode_message(self, cid, hexbody, truncated):
        r = Reader(words_to_bytes(hexbody))
        try:
            top = format(r.u32(), "08x")
        except EOFError:
            return f"unknown#{cid} <empty>"
        try:
            val = self.decode_ctor(top, r, 0)
        except EOFError:
            val = {self.name(top) or f"unknown#{top}": "…(truncated)" if truncated else "…(short)"}
        except Exception as e:  # never let a decode bug stop the run
            val = {self.name(top) or f"unknown#{top}": f"<decode error: {e}>"}
        tail = ""
        if not truncated and r.left() >= 4:
            tail = f"  +unparsed[{r.left()}B]=0x{r.d[r.p:r.p+32].hex()}"
        return self.render(top, val) + (" …(body truncated)" if truncated else "") + tail

    def render(self, top, val):
        nm = self.name(top) or "unknown"
        if isinstance(val, dict) and len(val) == 1 and (nm in val or list(val)[0] == nm):
            args = list(val.values())[0]
            return f"{nm}#{top} " + self.render_val(args)
        return f"{nm}#{top} " + self.render_val(val)

    def render_val(self, v):
        if isinstance(v, dict):
            if len(v) == 1 and isinstance(list(v.values())[0], dict):
                k = list(v)[0]
                return f"{k} {self.render_val(v[k])}"
            inner = ", ".join(f"{k}={self.render_val(val)}" for k, val in v.items())
            return "{ " + inner + " }"
        if isinstance(v, list):
            shown = [self.render_val(x) for x in v[:8]]
            more = "" if len(v) <= 8 else f", …(+{len(v)-8})"
            return "[" + ", ".join(shown) + more + "]"
        return str(v)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("log")
    ap.add_argument("--schema", default=BUILTIN_SCHEMA)
    ap.add_argument("--requests", action="store_true", help="decode only -> REQUEST lines")
    ap.add_argument("--out")
    ap.add_argument("--print", type=int, default=40, help="lines to echo to stdout (0=none)")
    a = ap.parse_args()

    schema = json.load(open(a.schema, encoding="utf-8"))
    dec = Decoder(schema)
    out_path = a.out or (a.log + ".decoded.txt")
    n_total = n_decoded = n_unknown = 0
    echoed = 0
    with open(a.log, encoding="utf-8", errors="replace") as fin, open(out_path, "w", encoding="utf-8") as fout:
        for line in fin:
            line = line.rstrip("\n")
            m = LINE_RE.match(line)
            if not m:
                fout.write(line + "\n")  # keep header/comment lines verbatim
                continue
            if a.requests and "REQUEST" not in m.group("dir"):
                continue
            n_total += 1
            cid = m.group("ctor").rjust(8, "0")
            decoded = dec.decode_message(cid, m.group("body"), bool(m.group("trunc")))
            if decoded.startswith("unknown"):
                n_unknown += 1
            else:
                n_decoded += 1
            out = f'[{m.group("time")}] {m.group("dir"):<10} reqId={m.group("rid"):<4} {decoded}'
            fout.write(out + "\n")
            if echoed < a.print:
                print(out)
                echoed += 1
    sys.stderr.write(f"\ndecoded {n_decoded}/{n_total} messages ({n_unknown} unknown top ctor) -> {out_path}\n")

if __name__ == "__main__":
    main()
