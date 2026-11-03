#!/usr/bin/env python3
"""Move this tree from Analog Rytm MKII OS 1.73 to OS 1.74, mechanically.

    python3 tools/port_os.py STOCK_1.73.syx STOCK_1.74.syx [--dry-run]

Needs vendor/elekloader (make setup): its .syx reader and ColdFire decoder.
Rewrites, in place, every firmware address in the mods' sources and manifests
(mods/*/{*.s,*.c,*.h,*.inc,*.py,mod.toml}), re/symbols.toml,
registry/allocations.toml and the tools (tools/**/*.py and *.sh, the
emulator suites among them, where a view's vtable is also written as a
quoted hex string, "40234cfc"), and re-pins each registry claim's stock bytes
(expect_sha256) from 1.74; a patch's `replace` bytes have their image
addresses moved too. The stubs generated from C (the mods with a
build.sh) are then regenerated from the moved C by their build.sh.

How an address moves. 1.74's main OS is 1.73's with code changed in four
places, all about routing and Outbox 8 outputs, and data moved after them
(the Knowledge Base's 1.73 -> 1.74 table, REGIONS below). Each address gets
its region's shift, and the move is accepted only if the images agree:

- code: the next instructions there decode to 1.73's (opcodes and operands
  equal, but for 32-bit addresses into the image, which may move forward);
- data: the 40 bytes around it are 1.73's at the moved place (but for such
  addresses);
- and wherever 1.73 code names the address with a 32-bit operand, the
  moved instruction in 1.74 names the moved address.

Two regions are not a plain shift: the RTTI names (0x4025b15e..0x40271b30,
+0x300..+0x364, each address found by its bytes) and the end of the code
section, where 1.73's zero run 0x402cc91c..0x402cd001 (the registry's pool
`cave`) is 864 bytes shorter in 1.74 (0x402ccc7c..0x402cd001): before it
+0x360, from its end on unmoved, and inside it a claim keeps its address if
the shorter run still holds it.

Where an address is code (operands, values, table entries), a move that is
not confirmed is an error, and nothing is written. In comments and notes an
address is moved when it can be; one that cannot (a round number naming a
range, an address in code 1.74 changed) is left and listed.

Only addresses are written, and the hashes of 1.74's stock bytes: no
firmware bytes.
"""
import argparse
import bisect
import collections
import hashlib
import re
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ELEK = ROOT / "vendor" / "elekloader"

B = 0x40000400                 # MAIN OS load address, both releases
SIZE = 3005432                 # MAIN OS length, both releases
END = B + SIZE
BSS = 0x402CE000               # the SRAM load images and past: unmoved
MAIN = {"1.73": "28d9ef40c895e03f17dfce096543109adaf708947392db72818fc2a412d685d6",
        "1.74": "34cd0c4da8e4b810d1b25284475a99ea53821e2ab7d30a978bf15dc578251f3b"}

# 1.73 start -> shift to 1.74 (to the next start). None: code 1.74 changed.
REGIONS = [(0x40000400, 0), (0x40057418, None), (0x40057A30, 0x6C), (0x40123E24, None),
           (0x40123F2E, 0xB4), (0x40128F56, None), (0x4012A620, 0x148), (0x4012D46E, None),
           (0x4012D59C, 0x26), (0x4012E78C, 0x1CC), (0x401B5F8C, None), (0x401B61A8, 0x2A4),
           (0x401BEA90, 0x2B0), (0x40231CE6, None), (0x40232130, 0x330), (0x4025B15E, "rtti"),
           (0x40271B30, 0x360), (0x402C7F44, "tail")]
STARTS = [r[0] for r in REGIONS]
CODE_SCAN_END = 0x401B5F8C     # 1.73 code scanned for operands that name an address
RUN73 = (0x402CC91C, 0x402CD001)   # the zero run before the static constructor table
RUN74 = (0x402CCC7C, 0x402CD001)

HEX = re.compile(r"\b0([xX])([0-9a-fA-F]{8})(?=[uUlL]*\b)")
QHEX = re.compile(r"""(["'])(4[0-9a-fA-F]{7})\1""")   # Python: an address as a quoted hex string ("40234cfc")


class Mapper:
    def __init__(self, a, b, cf):
        self.a, self.b, self.cf = a, b, cf
        self.ra, self.rb = cf.reader(a, B), cf.reader(b, B)
        self._refs = None
        self.memo = {}

    @staticmethod
    def inimg(v):
        return B <= v < END

    @staticmethod
    def region(v):
        return REGIONS[bisect.bisect_right(STARTS, v) - 1][1]

    def insns(self, img, rd, at, n):
        out = []
        for _ in range(n):
            if not (B <= at < END - 6):
                break
            i = self.cf.decode(rd(at), at)
            out.append(bytes(img[at - B:at - B + i.length]))
            if i.flags & self.cf.ILLEGAL or i.op in ("rts", "rte"):
                break
            at += i.length
        return out

    def same(self, x, y, lo=0, hi=None):
        """x and y equal at lo..hi, but for 32-bit words that are image addresses in
        both and move forward by at most 0x400 (a word may start before lo)."""
        if len(x) != len(y):
            return False
        hi = len(x) if hi is None else hi
        p = lo
        while p < hi:
            if x[p] == y[p]:
                p += 1
                continue
            for k in range(max(0, p - 3), p + 1):
                if k + 4 > len(x):
                    continue
                u, w = int.from_bytes(x[k:k + 4], "big"), int.from_bytes(y[k:k + 4], "big")
                if self.inimg(u) and self.inimg(w) and 0 <= w - u <= 0x400:
                    p = k + 4
                    break
            else:
                return False
        return True

    def code_ok(self, v, nv, n=8):
        p = self.insns(self.a, self.ra, v, n)
        q = self.insns(self.b, self.rb, nv, n)
        return len(p) >= 3 and len(p) == len(q) and all(
            x[:2] == y[:2] and self.same(x, y) for x, y in zip(p, q))

    def data_ok(self, v, nv, before=16, after=24):
        lo = max(B, v - before - 4)
        d = nv - v
        x = self.a[lo - B:v + after + 4 - B]
        y = self.b[lo - B + d:v + after + 4 - B + d]
        return self.same(x, y, max(0, v - before - lo), len(x) - 4)

    def refs(self, v):
        """-> Counter of what the 1.74 code names where 1.73 code names v."""
        if self._refs is None:
            self._refs = collections.defaultdict(list)
            pc = B
            while pc < CODE_SCAN_END:
                i = self.cf.decode(self.ra(pc), pc)
                if not i.flags & self.cf.ILLEGAL and i.length >= 6:
                    for k in range(2, i.length - 3, 2):
                        self._refs[int.from_bytes(self.a[pc - B + k:pc - B + k + 4], "big")].append((pc, k))
                pc += i.length or 2
        got = collections.Counter()
        for pc, k in self._refs.get(v, []):
            d = self.region(pc)
            if isinstance(d, int) and self.code_ok(pc, pc + d, 3):
                got[int.from_bytes(self.b[pc + d - B + k:pc + d - B + k + 4], "big")] += 1
        return got

    def __call__(self, v):
        """-> (1.74 address, how); KeyError says why not."""
        if v not in self.memo:
            try:
                self.memo[v] = self._move(v)
            except KeyError as e:
                self.memo[v] = e
        r = self.memo[v]
        if isinstance(r, KeyError):
            raise r
        return r

    def _move(self, v):
        if not self.inimg(v) or v >= BSS:
            return v, "unmoved"
        d = self.region(v)
        if d == "tail":
            if v < RUN73[0]:
                d = 0x360
            elif v >= RUN73[1] - 1:
                d = 0
            elif v >= RUN74[0]:
                return v, "free"           # free space the shorter run still holds
            elif v in (RUN73[0], RUN73[0] + 4):
                return v - RUN73[0] + RUN74[0], "run"   # the run's start, and the pool's 4 B in
            else:
                raise KeyError("0x%08x: in 1.73's end cave, past what 1.74 has of it "
                               "(0x%08x..0x%08x)" % (v, RUN74[0], RUN74[1]))
        elif d == "rtti":
            d = next((s for s in range(0x300, 0x368, 2) if self.data_ok(v, v + s, 24, 24)), None)
            if d is None:
                raise KeyError("0x%08x: among the RTTI names, no shift confirms it" % v)
        elif d is None:
            raise KeyError("0x%08x: in code 1.74 changed" % v)
        nv = v + d
        how = [w for w, ok in (("code", self.code_ok(v, nv)), ("bytes", self.data_ok(v, nv))) if ok]
        r = self.refs(v)
        if r:
            if set(r) != {nv}:
                raise KeyError("0x%08x: the shift gives 0x%08x, 1.74's code names %s"
                               % (v, nv, ", ".join("0x%08x" % k for k in r)))
            how.append("refs")
        if not how:
            raise KeyError("0x%08x -> 0x%08x: neither the code nor the bytes there agree" % (v, nv))
        return nv, "+".join(how)


# ------------------------------------------------------------------ the files' code and prose

def spans_asm(text):
    """(is_code, text) pieces of a gas m68k source: `|` comments, `#` lines, /* */."""
    out = []
    i, n = 0, len(text)
    while i < n:
        j = text.find("\n", i)
        j = n if j < 0 else j + 1
        line = text[i:j]
        if line.lstrip().startswith("#"):
            out.append((False, line))
        else:
            q, k = False, 0
            while k < len(line):
                c = line[k]
                if c == '"' and (k == 0 or line[k - 1] != "\\"):
                    q = not q
                elif not q and (c == "|" or line.startswith("/*", k)):
                    break
                k += 1
            if k < len(line) and line.startswith("/*", k):
                e = text.find("*/", i + k)
                e = n if e < 0 else e + 2
                out += [(True, line[:k]), (False, text[i + k:e])]
                j = max(j, e)
            else:
                out += [(True, line[:k]), (False, line[k:])]
        i = j
    return out


def spans_c(text):
    out, i, n, start = [], 0, len(text), 0
    while i < n:
        if text.startswith("//", i) or text.startswith("/*", i):
            out.append((True, text[start:i]))
            e = (text.find("\n", i) if text[i + 1] == "/" else text.find("*/", i) + 2)
            e = n if e < 1 else e
            out.append((False, text[i:e]))
            i = start = e
        elif text[i] in "\"'":
            e = i + 1
            while e < n and text[e] != text[i]:
                e += 2 if text[e] == "\\" else 1
            i = e + 1
        else:
            i += 1
    out.append((True, text[start:]))
    return out


def spans_toml(text):
    out, i, n, start = [], 0, len(text), 0
    while i < n:
        if text.startswith('"""', i):
            e = text.find('"""', i + 3) + 3
        elif text[i] == '"':
            e = i + 1
            while e < n and text[e] not in '"\n':
                e += 2 if text[e] == "\\" else 1
            e += 1
        elif text[i] == "#":
            e = text.find("\n", i)
            e = n if e < 0 else e
        else:
            i += 1
            continue
        out += [(True, text[start:i]), (False, text[i:e])]
        i = start = e
    out.append((True, text[start:]))
    return out


def spans_py(text):
    """Python: comments and triple-quoted strings (docstrings) are prose."""
    import io
    import tokenize
    lines = text.splitlines(keepends=True)
    starts = [0]
    for ln in lines:
        starts.append(starts[-1] + len(ln))
    out, pos = [], 0
    for t in tokenize.generate_tokens(io.StringIO(text).readline):
        prose = t.type == tokenize.COMMENT or (t.type == tokenize.STRING and t.string.lstrip("rRbBuUfF")[:3] in ('"""', "'''"))
        if prose:
            a = starts[t.start[0] - 1] + t.start[1]
            e = starts[t.end[0] - 1] + t.end[1]
            out += [(True, text[pos:a]), (False, text[a:e])]
            pos = e
    out.append((True, text[pos:]))
    return out


def spans_sh(text):
    out = []
    for line in text.splitlines(keepends=True):
        k = line.find("#")
        k = len(line) if k < 0 or line.startswith("#!") and False else k
        out += [(True, line[:k]), (False, line[k:])]
    return out


SPANS = {".s": spans_asm, ".inc": spans_asm, ".c": spans_c, ".h": spans_c, ".toml": spans_toml,
         ".py": spans_py, ".sh": spans_sh}


def port_text(text, spans, M, where, errors, left):
    out = []
    for code, piece in spans(text):
        def sub(m):
            v = int(m.group(2), 16)
            if not M.inimg(v):
                return m.group(0)
            try:
                nv, _ = M(v)
            except KeyError as e:
                if code:
                    errors.append("%s: %s" % (where, e.args[0]))
                else:
                    left[where].add(m.group(0))
                return m.group(0)
            if not code and v & 0xFFF == 0:
                left[where].add(m.group(0))   # a round number in prose names a range
                return m.group(0)
            digits = "%08x" % nv
            return "0" + m.group(1) + (digits.upper() if m.group(2).isupper() else digits)
        piece = HEX.sub(sub, piece)
        if code and spans is spans_py:
            def qsub(m):
                r = sub(m)
                return m.group(0) if r == m.group(0) else m.group(1) + r[2:] + m.group(1)
            piece = QHEX.sub(qsub, piece)
        out.append(piece)
    return "".join(out)


# ------------------------------------------------------------------ the registry's stock bytes

def moved_only(x, y, M):
    """y is x but for 32-bit image addresses, each moved as M moves it: every differing byte
    lies in a word of x that M moves to the word of y at the same place."""
    if len(x) != len(y):
        return False

    def moves(k):
        if k < 0 or k + 4 > len(x):
            return False
        u, w = int.from_bytes(x[k:k + 4], "big"), int.from_bytes(y[k:k + 4], "big")
        if not M.inimg(u):
            return False
        try:
            return M(u)[0] == w
        except KeyError:
            return False
    p = 0
    while p < len(x):
        if x[p] == y[p]:
            p += 1
            continue
        k = next((k for k in range(p - 3, p + 1) if moves(k)), None)
        if k is None:
            return False
        p = k + 4
    return True


def move_replace(blk, c, M, errors):
    """A patch's `replace` bytes (hex): each 32-bit image address at an even address moves."""
    m = re.search(r'(?m)^(replace\s*=\s*")([0-9a-fA-F]+)"', blk)
    if not m:
        return blk
    r = bytearray.fromhex(m.group(2))
    k = (c["addr"] & 1)
    while k + 4 <= len(r):
        u = int.from_bytes(r[k:k + 4], "big")
        if M.inimg(u) and u < BSS:
            try:
                r[k:k + 4] = M(u)[0].to_bytes(4, "big")
            except KeyError as e:
                errors.append("patch %s 0x%08x: replace +%d: %s" % (c["owner"], c["addr"], k, e.args[0]))
            k += 4
        else:
            k += 2
    h = r.hex()
    if m.group(2).isupper():
        h = h.upper()
    return blk[:m.start(2)] + h + blk[m.end(2):]


def check_claims(path, text, a, b, M, errors):
    """Each patch's and detour's stock bytes: 1.73's at the old address are 1.74's at the
    new one but for moved addresses; return the text with expect_sha256 from 1.74."""
    old = tomllib.loads(path.read_text())
    new = tomllib.loads(text)
    subs = {}
    for table in ("patch", "detour"):
        for i, (c0, c1) in enumerate(zip(old.get(table, []), new.get(table, []))):
            if "expect_sha256" not in c0:
                continue
            n = c0["expect_len"]
            x = a[c0["addr"] - B:c0["addr"] - B + n]
            y = b[c1["addr"] - B:c1["addr"] - B + n]
            what = "%s %s 0x%08x" % (table, c0["owner"], c0["addr"])
            if hashlib.sha256(x).hexdigest() != c0["expect_sha256"]:
                errors.append("%s: 1.73's bytes are not its expect" % what)
                continue
            if not moved_only(x, y, M):
                errors.append("%s -> 0x%08x: 1.74 has %s where 1.73 has %s" % (what, c1["addr"], y.hex(), x.hex()))
                continue
            subs[table, i] = hashlib.sha256(y).hexdigest()
    # a dead-code pool (stock = "code") names the routine's bytes by hash: the same check
    for i, (p0, p1) in enumerate(zip(old.get("pool", []), new.get("pool", []))):
        if "expect_sha256" not in p0:
            continue
        x = a[p0["start"] - B:p0["end"] - B]
        y = b[p1["start"] - B:p1["end"] - B]
        what = "pool %s 0x%08x..0x%08x" % (p0["name"], p0["start"], p0["end"])
        if hashlib.sha256(x).hexdigest() != p0["expect_sha256"]:
            errors.append("%s: 1.73's bytes are not its expect" % what)
        elif not moved_only(x, y, M):
            errors.append("%s: 1.74's bytes there are not 1.73's but for moved addresses" % what)
        else:
            subs["pool", i] = hashlib.sha256(y).hexdigest()
    # rewrite each claim's hash in place: the text's [[patch]] / [[detour]] / [[pool]] blocks
    # are the tables' entries in order
    blocks = re.split(r"(?m)^(?=\[\[)", text)
    seen = collections.Counter()
    out = []
    for blk in blocks:
        m = re.match(r"\[\[(\w+)\]\]", blk)
        t = m.group(1) if m else None
        if t in ("patch", "detour", "pool"):
            i = seen[t]
            seen[t] += 1
            if t == "patch":
                blk = move_replace(blk, old[t][i], M, errors)
            h = subs.get((t, i))
            if h is not None:
                blk = re.sub(r'(?m)^(expect_sha256\s*=\s*")[0-9a-f]{64}"', lambda mm: mm.group(1) + h + '"', blk, count=1)
        out.append(blk)
    return "".join(out)


def drop_lost_caves(text, dropped):
    """Comment out each [[cave]] that 1.74's shorter end cave cannot hold, saying why."""
    out = []
    for blk in re.split(r"(?m)^(?=\[\[)", text):
        m = re.match(r"\[\[cave\]\]\n(?:[^\n]*\n)*?addr\s*=\s*0x([0-9a-fA-F]{8})", blk)
        if m and RUN73[0] + 4 <= int(m.group(1), 16) < RUN74[0] + 4:
            c = tomllib.loads(blk)["cave"][0]
            if int(m.group(1), 16) + c["size"] > RUN74[0] + 4 or int(m.group(1), 16) != RUN73[0] + 4:
                body = blk.rstrip("\n").split("\n")
                tail = len(blk) - len(blk.rstrip("\n"))
                blk = ("# OS 1.74 (tools/port_os.py): 1.73's end cave is 864 B shorter; this claim (%d B at "
                       "0x%08x) does not fit in what is left\n# (0x%08x..0x%08x), so it is kept only as a record.\n"
                       % (c["size"], c["addr"], RUN74[0] + 4, RUN73[1] - 1)
                       + "\n".join("# " + ln if ln else "#" for ln in body) + "\n" * tail)
                dropped.append("%s %d B at 0x%08x" % (c["owner"], c["size"], c["addr"]))
        out.append(blk)
    return "".join(out)


def check_pools(text, b, M, errors):
    """Each pool in 1.74: unclaimed by 1.74's own code as it was in 1.73 (the same bytes but for
    moved addresses, or zeros)."""
    reg = tomllib.loads(text)
    for p in reg.get("pool", []):
        s, e = p["start"], p["end"]
        if e <= s or b[s - B:e - B] == bytes(e - s):
            continue
        if not (B <= s < e <= END):
            errors.append("pool %s: 0x%08x..0x%08x outside the image" % (p["name"], s, e))


def write_table(path, M, files):
    """The map as CSV, from M.memo (filled by the port): one row per distinct image address."""
    import csv
    names = collections.defaultdict(set)
    sym = tomllib.loads((ROOT / "re/symbols.toml").read_text())
    for kind, tab in sym.items():
        if isinstance(tab, dict):
            for name, e in tab.items():
                if isinstance(e, dict) and isinstance(e.get("addr"), int):
                    names[e["addr"]].add("%s.%s" % (kind, name))
    used = collections.defaultdict(set)
    for f in files:
        for m in HEX.finditer(f.read_text()):
            used[int(m.group(2), 16)].add(str(f.relative_to(ROOT)))
    with open(path, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["addr_1.73", "addr_1.74", "shift", "checked_by", "symbols", "files"])
        for v in sorted(M.memo):
            r = M.memo[v]
            if isinstance(r, KeyError):
                w.writerow(["0x%08x" % v, "", "", "not moved: %s" % r, " ".join(sorted(names[v])),
                            " ".join(sorted(used[v]))])
                continue
            nv, how = r[0], r[1]
            w.writerow(["0x%08x" % v, "0x%08x" % nv, "%+#x" % (nv - v), how, " ".join(sorted(names[v])),
                        " ".join(sorted(used[v]))])
    print("wrote the address map: %s (%d rows)" % (path, len(M.memo)))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("stock173")
    ap.add_argument("stock174")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--table", type=Path, help="also write the address map as CSV: every image "
                    "address the tree names, 1.73 -> 1.74, how it was checked, its symbol and files")
    args = ap.parse_args()
    sys.path.insert(0, str(ELEK))
    from elekloader import formats, syx
    from elekloader.isa import coldfire as cf
    imgs = {}
    for p in (args.stock173, args.stock174):
        st, dev, rel = formats.load(p)
        img = bytes(formats.main_image(st, dev))
        if dev.key != "analog-rytm-mk2" or MAIN.get(rel.version) != syx.sha(img):
            sys.exit("%s: not stock Analog Rytm MKII 1.73 or 1.74" % p)
        imgs[rel.version] = img
    a, b = imgs["1.73"], imgs["1.74"]
    M = Mapper(a, b, cf)

    files = sorted(set(ROOT.glob("mods/*/*.s")) | set(ROOT.glob("mods/*/*.c")) | set(ROOT.glob("mods/*/*.h"))
                   | set(ROOT.glob("mods/*/*.inc")) | set(ROOT.glob("mods/*/*.toml"))
                   | {ROOT / "re/symbols.toml", ROOT / "registry/allocations.toml"}
                   | {f for f in ROOT.glob("tools/**/*.py") if f.name != "port_os.py"}
                   | set(ROOT.glob("tools/**/*.sh")) | set(ROOT.glob("mods/*/*.py")))
    errors, left, writes, dropped = [], collections.defaultdict(set), {}, []
    for f in files:
        where = str(f.relative_to(ROOT))
        text = f.read_text()
        src = drop_lost_caves(text, dropped) if f.name == "allocations.toml" else text
        new = port_text(src, SPANS[f.suffix], M, where, errors, left)
        if f.name == "allocations.toml":
            new = check_claims(f, new, a, b, M, errors)
            check_pools(new, b, M, errors)
        if new != text:
            writes[f] = new
    for where, toks in sorted(left.items()):
        print("left in prose, %s: %s" % (where, " ".join(sorted(toks))))
    for d in dropped:
        print("cave claim kept only as a comment (no room on 1.74): %s" % d)
    if errors:
        sys.exit("\n".join(errors) + "\n%d errors; nothing written" % len(errors))
    hows = collections.Counter(h for r in M.memo.values() if not isinstance(r, KeyError) for h in [r[1]])
    print("moved %d distinct addresses (%s)" % (sum(hows.values()),
          ", ".join("%s %d" % kv for kv in hows.most_common())))
    if args.table:
        write_table(args.table, M, files)
    if args.dry_run:
        print("dry run: %d files would change" % len(writes))
        return
    for f, t in writes.items():
        f.write_text(t)
    print("wrote %d files" % len(writes))


if __name__ == "__main__":
    main()
