#!/usr/bin/env python3
"""Compare the ABI surfaces of two ntdll sets that the bridge, shim and patches consume.

    abi_compare.py A_ROOT B_ROOT [--justify FILE] [--report OUT.md] [--json OUT.json]
                   [--objdump llvm-objdump] [--nm nm]

Each root uses the engine layout: lib/wine/x86_64-unix/ntdll.so,
lib/wine/x86_64-windows/ntdll.dll and lib/wine/i386-windows/ntdll.dll.

Surfaces: (a) PE exports and Unix exports/linkage; (b) Nt*/Zw* syscall numbers;
(c) unix call tables and their PE call sites; (d) the functions the T04 hooks touch,
disassembled with addresses masked; (e) string diff (informational only).

Exit 0 when every divergence in (a)-(d) has an "irrelevante" entry (exact id) in the
justification file, 1 otherwise, 2 on input/tool errors or when the justification
file's "files" hashes do not match the pair being compared. stdlib only, plus
nm (Xcode) and llvm-objdump (llvm-mingw).
"""
import argparse, hashlib, json, os, re, struct, subprocess, sys

DLLS = {'x86_64': 'lib/wine/x86_64-windows/ntdll.dll', 'i386': 'lib/wine/i386-windows/ntdll.dll'}
UNIX = 'lib/wine/x86_64-unix/ntdll.so'
# What the detour payload links against (ntdll-patch/link*.ld) and resolve.py's EXPORTS.
HOOK_EXPORTS = ['LdrGetDllHandle', 'LdrLoadDll', 'NtProtectVirtualMemory',
                'NtOpenFile', 'NtReadFile', 'NtClose']
# Internal functions resolve.py locates through their TRACE string: the hook site.
HOOK_INTERNAL = ['build_module', 'alloc_module']
# PE wrappers whose immediate selects an entry of ntdll's unix call table.
UNIXCALL_SITES = ['wine_server_call', 'wine_server_fd_to_handle', 'wine_server_handle_to_fd',
                  '__wine_dbg_write']
UNIX_LOOKUP_NAMES = [b'__wine_unix_call_funcs', b'__wine_unix_call_wow64_funcs',
                     b'__wine_unixlib_handle', b'__wine_unix_call_dispatcher']


def die(msg):
    print(f'abi_compare: {msg}', file=sys.stderr)
    sys.exit(2)


class PE:
    def __init__(self, path):
        self.path = path
        self.d = d = open(path, 'rb').read()
        e = struct.unpack_from('<I', d, 0x3c)[0]
        if d[e:e + 4] != b'PE\0\0':
            die(f'{path}: not a PE')
        self.machine, nsec = struct.unpack_from('<HH', d, e + 4)
        optsz = struct.unpack_from('<H', d, e + 20)[0]
        o = e + 24
        magic = struct.unpack_from('<H', d, o)[0]
        self.pe64 = magic == 0x20b
        self.base = struct.unpack_from('<Q', d, o + 24)[0] if self.pe64 else struct.unpack_from('<I', d, o + 28)[0]
        self.imgsize = struct.unpack_from('<I', d, o + 56)[0]
        dd = o + (112 if self.pe64 else 96)
        self.dirs = [struct.unpack_from('<II', d, dd + 8 * i) for i in range(16)]
        self.secs = []
        for i in range(nsec):
            s = o + optsz + 40 * i
            name = d[s:s + 8].rstrip(b'\0').decode('latin1')
            vsz, va, rsz, roff = struct.unpack_from('<IIII', d, s + 8)
            self.secs.append((name, va, max(vsz, rsz), roff, rsz))

    def off(self, rva):
        for _, va, sz, roff, rsz in self.secs:
            if va <= rva < va + sz and rva - va < rsz:
                return roff + rva - va
        return None

    def sec(self, name):
        return next((s for s in self.secs if s[0] == name), None)

    def exports(self):
        rva, size = self.dirs[0]
        o = self.off(rva)
        _, _, _, _, _, obase, nfun, nnames, af, an, ao = struct.unpack_from('<IIHHIIIIIII', self.d, o)
        funcs = struct.unpack_from(f'<{nfun}I', self.d, self.off(af))
        names = struct.unpack_from(f'<{nnames}I', self.d, self.off(an))
        ords = struct.unpack_from(f'<{nnames}H', self.d, self.off(ao))
        out = {}
        for n, i in zip(names, ords):
            s = self.off(n)
            name = self.d[s:self.d.index(b'\0', s)].decode('latin1')
            f = funcs[i]
            fwd = None
            if rva <= f < rva + size:
                fo = self.off(f)
                fwd = self.d[fo:self.d.index(b'\0', fo)].decode('latin1')
            out[name] = {'ordinal': obase + i, 'rva': f, 'forward': fwd}
        return out

    def text_range(self):
        _, va, sz, _, _ = self.sec('.text')
        return va, va + sz


def run(cmd):
    try:
        return subprocess.run(cmd, check=True, capture_output=True, text=True).stdout
    except (OSError, subprocess.CalledProcessError) as e:
        die(f'{" ".join(cmd)}: {e}')


def func_ranges(pe, exports):
    """Function [start, end) RVAs. x86_64: .pdata. i386 has no .pdata and its .eh_frame only
    covers the assembly thunks, so starts are exports plus 16-byte aligned targets of
    call rel32 and frame-pointer prologues; a function ends where the next one starts
    (trailing int3/nop padding trimmed)."""
    out = {}
    if pe.pe64:
        rva, size = pe.dirs[3]
        o = pe.off(rva)
        for i in range(size // 12):
            b, e, _ = struct.unpack_from('<III', pe.d, o + 12 * i)
            out.setdefault(b, e)
        return out
    tstart, tend = pe.text_range()
    to = pe.off(tstart)
    text = pe.d[to:to + tend - tstart]
    starts = {e['rva'] for e in exports.values() if not e['forward'] and tstart <= e['rva'] < tend}
    for m in re.finditer(rb'\xe8', text):
        p = m.start()
        if p + 5 <= len(text):
            t = tstart + p + 5 + struct.unpack_from('<i', text, p + 1)[0]
            if tstart <= t < tend and not t % 16:
                starts.add(t)
    for m in re.finditer(rb'\x55\x89\xe5|\x55\x8b\xec', text):
        if not (tstart + m.start()) % 16:
            starts.add(tstart + m.start())
    starts = sorted(starts)
    for b, nxt in zip(starts, starts[1:] + [tend]):
        e = nxt
        while e > b and text[e - tstart - 1] in (0xcc, 0x90):
            e -= 1
        out[b] = e
    return out


def bounds(pe, ranges, starts, rva):
    """Range of the function at rva; leaf functions without unwind data end at the next start."""
    if rva in ranges:
        return rva, ranges[rva]
    nxt = [s for s in starts if s > rva]
    end = min(nxt) if nxt else pe.text_range()[1]
    o = pe.off(rva)
    while end > rva and pe.d[o + end - rva - 1] in (0xcc, 0x90):
        end -= 1
    return rva, end


HEX = re.compile(r'0x[0-9a-f]+')


def norm_disasm(pe, objdump, start, end):
    """Instruction text with image addresses masked: relocations, rip-relative operands and
    branch targets become symbolic so layout shifts do not count, opcodes and constants do."""
    lo, hi = pe.base, pe.base + pe.imgsize
    txt = run([objdump, '-d', '--no-show-raw-insn', f'--start-address={pe.base + start:#x}',
               f'--stop-address={pe.base + end:#x}', pe.path])
    out = []
    for line in txt.splitlines():
        m = re.match(r'\s*([0-9a-f]+):\s+(.*)$', line)
        if not m:
            continue
        ins = re.sub(r'\s*(#.*|<[^>]*>)', '', m[2]).strip()
        ins = re.sub(r'-?0x[0-9a-f]+\(%rip\)', 'REL(%rip)', ins)

        def mask(h):
            v = int(h[0], 16)
            if lo <= v < hi:
                return f'L+{v - pe.base - start:#x}' if start <= v - pe.base < end else 'ADDR'
            return h[0]
        out.append(re.sub(r'\s+', ' ', HEX.sub(mask, ins)))
    while out and out[-1] in ('int3', 'nop'):
        out.pop()
    return out


def string_refs(pe, ranges, name):
    """Functions that reference the C string name: rip-relative lea/mov on x86_64,
    the absolute address (relocated) on i386."""
    rs = pe.sec('.rdata')
    if not rs:
        return []
    _, va, _, roff, rsz = rs
    k = pe.d[roff:roff + rsz].find(b'\0' + name.encode() + b'\0')
    if k < 0:
        return []
    srva = va + k + 1
    tstart, tend = pe.text_range()
    to = pe.off(tstart)
    text = pe.d[to:to + tend - tstart]
    hits = []
    if pe.pe64:
        for m in re.finditer(rb'[\x48\x4c][\x8d\x8b][\x05\x0d\x15\x1d\x25\x2d\x35\x3d]', text):
            p = m.start()
            disp = struct.unpack_from('<i', text, p + 3)[0]
            if tstart + p + 7 + disp == srva:
                hits.append(tstart + p)
    else:
        needle = struct.pack('<I', pe.base + srva)
        hits = [tstart + m.start() for m in re.finditer(re.escape(needle), text)]
    return sorted({b for h in hits for b, e in ranges.items() if b <= h < e})


def syscalls(pe, exports):
    out = {}
    for name, e in exports.items():
        if not name.startswith(('Nt', 'Zw')) or e['forward']:
            continue
        o = pe.off(e['rva'])
        head = pe.d[o:o + 8]
        if pe.pe64 and head[:4] == b'\x4c\x8b\xd1\xb8':
            out[name] = struct.unpack_from('<I', head, 4)[0]
        elif not pe.pe64 and head[:1] == b'\xb8':
            out[name] = struct.unpack_from('<I', head, 1)[0]
    return out


class MachO:
    def __init__(self, path):
        self.path = path
        self.d = d = open(path, 'rb').read()
        if struct.unpack_from('<I', d, 0)[0] != 0xfeedfacf:
            die(f'{path}: not a thin 64-bit Mach-O')
        ncmds = struct.unpack_from('<I', d, 16)[0]
        o = 32
        self.sects, self.fstarts, self.deps, self.rpaths, self.idname = [], set(), [], [], None
        for _ in range(ncmds):
            cmd, size = struct.unpack_from('<II', d, o)
            if cmd == 0x19:
                nsect = struct.unpack_from('<I', d, o + 64)[0]
                for i in range(nsect):
                    s = o + 72 + 80 * i
                    sect = d[s:s + 16].rstrip(b'\0').decode()
                    seg = d[s + 16:s + 32].rstrip(b'\0').decode()
                    addr, sz, off = struct.unpack_from('<QQI', d, s + 32)
                    self.sects.append((seg, sect, addr, sz, off))
            elif cmd == 0x26:
                doff, dsz = struct.unpack_from('<II', d, o + 8)
                addr, i = 0, doff
                while i < doff + dsz:
                    v, shift = 0, 0
                    while True:
                        b = d[i]; i += 1
                        v |= (b & 0x7f) << shift; shift += 7
                        if b < 0x80:
                            break
                    if v == 0:
                        break
                    addr += v
                    self.fstarts.add(addr)
            elif cmd in (0xc, 0xd, 0x8000001c, 0x80000018):
                so = struct.unpack_from('<I', d, o + 8)[0]
                s = d[o + so:o + size].split(b'\0')[0].decode()
                if cmd == 0xd:
                    self.idname = s
                elif cmd == 0x8000001c:
                    self.rpaths.append(s)
                else:
                    self.deps.append(s)
            o += size

    def unixcall_tables(self):
        """ntdll's unix_call_wow64_funcs and unix_call_funcs: two function pointer arrays of
        equal length N sharing exactly one entry at the same index (system_time_precise) and
        otherwise distinct. Each array ends at a non-pointer slot or where the other begins;
        the largest such N wins. Pointers are rebase targets (chained fixups or raw vmaddr)."""
        found = []
        for seg, sect, addr, sz, off in self.sects:
            if sect != '__const' or seg not in ('__DATA_CONST', '__DATA'):
                continue
            slots = []
            for i in range(0, sz - 7, 8):
                v = struct.unpack_from('<Q', self.d, off + i)[0]
                t = v & 0xFFFFFFFFF if not v >> 63 else None
                slots.append(t if t in self.fstarts else None)
            pos = {}
            for i, t in enumerate(slots):
                if t is not None:
                    pos.setdefault(t, []).append(i)
            for t, ps in pos.items():
                for x, i in enumerate(ps):
                    for j in ps[x + 1:]:
                        best = None
                        for n in range(4, min(j - i, 32) + 1):
                            for k in range(n):
                                a0, b0 = i - k, j - k
                                if a0 < 0 or b0 + n > len(slots):
                                    continue
                                a, b = slots[a0:a0 + n], slots[b0:b0 + n]
                                if None in a or None in b or len(set(a + b)) != 2 * n - 1:
                                    continue
                                after_a = a0 + n
                                if not (after_a == b0 or slots[after_a] is None):
                                    continue
                                if b0 + n < len(slots) and slots[b0 + n] is not None:
                                    continue
                                best = {'addr': addr + 8 * a0, 'n': n, 'shared': k, 'tables': [a, b]}
                        if best:
                            found.append(best)
        return found

    def fsize(self, start):
        nxt = [s for s in self.fstarts if s > start]
        return (min(nxt) if nxt else 0) - start


def unix_exports(nm, path):
    out = {}
    for line in run([nm, '-gU', path]).splitlines():
        p = line.split()
        if len(p) == 3:
            out[p[2]] = p[1]
    return out


def strings(data, n=6):
    return {m.decode() for m in re.findall(rb'[\x20-\x7e]{%d,}' % n, data)}


def collect(root, objdump, nm):
    r = {'root': root, 'files': {}, 'pe': {}}
    for arch, rel in [('x86_64-unix', UNIX)] + [(a, p) for a, p in DLLS.items()]:
        path = os.path.join(root, rel)
        if not os.path.isfile(path):
            die(f'missing {path}')
        r['files'][rel] = hashlib.sha256(open(path, 'rb').read()).hexdigest()
    for arch, rel in DLLS.items():
        pe = PE(os.path.join(root, rel))
        ex = pe.exports()
        ranges = func_ranges(pe, ex)
        starts = sorted(set(ranges) | {e['rva'] for e in ex.values() if not e['forward']})
        hooks = {}
        for name in HOOK_EXPORTS + UNIXCALL_SITES:
            if name in ex and not ex[name]['forward']:
                b, e = bounds(pe, ranges, starts, ex[name]['rva'])
                hooks[name] = {'rva': b, 'size': e - b, 'insns': norm_disasm(pe, objdump, b, e)}
        for name in HOOK_INTERNAL:
            owners = string_refs(pe, ranges, name)
            hooks[name] = {'owners': len(owners)}
            if len(owners) == 1:
                b, e = owners[0], ranges[owners[0]]
                hooks[name].update(rva=b, size=e - b, insns=norm_disasm(pe, objdump, b, e))
        r['pe'][arch] = {'exports': {k: {'ordinal': v['ordinal'], 'forward': v['forward']} for k, v in ex.items()},
                         'syscalls': syscalls(pe, ex), 'funcs': hooks, 'strings': strings(pe.d)}
    mo = MachO(os.path.join(root, UNIX))
    tabs = mo.unixcall_tables()
    r['unix'] = {'exports': unix_exports(nm, os.path.join(root, UNIX)),
                 'linkage': {'id': mo.idname, 'deps': mo.deps, 'rpaths': mo.rpaths},
                 'lookupNames': {n.decode(): (b'\0' + n + b'\0') in mo.d for n in UNIX_LOOKUP_NAMES},
                 'tables': [{'n': t['n'], 'shared': t['shared'],
                             'entrySizes': [[mo.fsize(p) for p in tab] for tab in t['tables']]}
                            for t in tabs],
                 'strings': strings(mo.d)}
    return r


def compare(A, B):
    div = []  # (surface, id, detail)

    def add(surface, ident, detail):
        div.append({'surface': surface, 'id': ident, 'detail': detail})
    stats = {}
    for arch in DLLS:
        ea, eb = A['pe'][arch]['exports'], B['pe'][arch]['exports']
        for n in sorted(set(ea) - set(eb)):
            add('a', f'a:pe-export:{arch}:-{n}', 'only in A')
        for n in sorted(set(eb) - set(ea)):
            add('a', f'a:pe-export:{arch}:+{n}', 'only in B')
        for n in sorted(set(ea) & set(eb)):
            if ea[n] != eb[n]:
                add('a', f'a:pe-export-attr:{arch}:{n}', f'{ea[n]} != {eb[n]}')
        sa, sb = A['pe'][arch]['syscalls'], B['pe'][arch]['syscalls']
        # An empty or uneven extraction means the stub format was not recognised on one side.
        if not sa or not sb or len(sa) != len(sb):
            add('b', f'b:syscall-count:{arch}', f'extracted syscalls A={len(sa)} B={len(sb)}')
        for n in sorted(set(sa) | set(sb)):
            if sa.get(n) != sb.get(n):
                add('b', f'b:syscall:{arch}:{n}', f'{sa.get(n)} != {sb.get(n)}')
        fa, fb = A['pe'][arch]['funcs'], B['pe'][arch]['funcs']
        for n in HOOK_EXPORTS + HOOK_INTERNAL + UNIXCALL_SITES:
            surface = 'c' if n in UNIXCALL_SITES else 'd'
            x, y = fa.get(n), fb.get(n)
            if x is None and y is None:
                continue
            if x is None or y is None or 'insns' not in x or 'insns' not in y:
                add(surface, f'{surface}:func:{arch}:{n}', f'not located: A={x and x.get("owners")} B={y and y.get("owners")}')
            elif x['insns'] != y['insns'] or x['size'] != y['size']:
                k = next((i for i, (p, q) in enumerate(zip(x['insns'], y['insns'])) if p != q),
                         min(len(x['insns']), len(y['insns'])))
                add(surface, f'{surface}:func:{arch}:{n}',
                    f'size {x["size"]} vs {y["size"]}, insns {len(x["insns"])} vs {len(y["insns"])}, '
                    f'first diff #{k}: {x["insns"][k:k+1]} vs {y["insns"][k:k+1]}')
        stats[arch] = {'exportsA': len(ea), 'exportsB': len(eb), 'syscallsA': len(sa), 'syscallsB': len(sb)}
    ua, ub = A['unix']['exports'], B['unix']['exports']
    for n in sorted(set(ua) - set(ub)):
        add('a', f'a:unix-export:-{n}', 'only in A')
    for n in sorted(set(ub) - set(ua)):
        add('a', f'a:unix-export:+{n}', 'only in B')
    for k in ('id', 'deps', 'rpaths'):
        if A['unix']['linkage'][k] != B['unix']['linkage'][k]:
            add('a', f'a:unix-linkage:{k}', f'{A["unix"]["linkage"][k]} != {B["unix"]["linkage"][k]}')
    if A['unix']['lookupNames'] != B['unix']['lookupNames']:
        add('c', 'c:unix-lookup-names', f'{A["unix"]["lookupNames"]} != {B["unix"]["lookupNames"]}')
    ta, tb = A['unix']['tables'], B['unix']['tables']
    if len(ta) != 1 or len(tb) != 1:
        add('c', 'c:unix-table:located', f'pairs found A={len(ta)} B={len(tb)}')
    else:
        if ta[0]['n'] != tb[0]['n']:
            add('c', 'c:unix-table:count', f'{ta[0]["n"]} != {tb[0]["n"]}')
        if ta[0]['shared'] != tb[0]['shared']:
            add('c', 'c:unix-table:shared-index', f'{ta[0]["shared"]} != {tb[0]["shared"]}')
    stats['unix'] = {'exportsA': len(ua), 'exportsB': len(ub), 'tablesA': ta, 'tablesB': tb}
    strdiff = {}
    for key, sa, sb in [('x86_64-unix', A['unix']['strings'], B['unix']['strings'])] + \
            [(a, A['pe'][a]['strings'], B['pe'][a]['strings']) for a in DLLS]:
        strdiff[key] = {'onlyA': sorted(sa - sb), 'onlyB': sorted(sb - sa)}
    return div, stats, strdiff


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('a'); ap.add_argument('b')
    ap.add_argument('--justify'); ap.add_argument('--report'); ap.add_argument('--json')
    ap.add_argument('--objdump', default='llvm-objdump'); ap.add_argument('--nm', default='nm')
    o = ap.parse_args()
    A, B = collect(o.a, o.objdump, o.nm), collect(o.b, o.objdump, o.nm)
    div, stats, strdiff = compare(A, B)
    just = []
    if o.justify:
        jf = json.load(open(o.justify))
        # Justifications hold for the exact binaries they were written against.
        for side, R in (('A', A), ('B', B)):
            for rel, h in jf.get('files', {}).get(side, {}).items():
                if R['files'].get(rel) != h:
                    die(f'{o.justify} was written for {side} {rel} sha256 {h}, '
                        f'got {R["files"].get(rel)}; justifications do not apply to this pair')
        just = jf['entries']
    failing = []
    for d in div:
        j = next((j for j in just if j['id'] == d['id']), None)
        d['classification'] = j['classification'] if j else 'NAO JUSTIFICADA'
        d['reason'] = j['reason'] if j else None
        if d['classification'] != 'irrelevante':
            failing.append(d)
    status = 'PASS' if not failing else 'FAIL'
    surfaces = {s: sum(1 for d in div if d['surface'] == s) for s in 'abcd'}
    lines = [f'# ABI compare: {status}', '', f'- A: `{o.a}`', f'- B: `{o.b}`', '']
    for side, R in (('A', A), ('B', B)):
        for rel, h in R['files'].items():
            lines.append(f'- {side} `{rel}` sha256 `{h}`')
    lines += ['', '## Contagens', '', '```', json.dumps(stats, indent=1), '```', '',
              '## Divergencias (a)-(d)', '',
              f'Total {len(div)} (a={surfaces["a"]} b={surfaces["b"]} c={surfaces["c"]} d={surfaces["d"]}); '
              f'falhando {len(failing)}.', '']
    for d in div:
        lines.append(f'- [{d["classification"]}] `{d["id"]}`: {d["detail"]}' +
                     (f' — {d["reason"]}' if d['reason'] else ''))
    lines += ['', '## (e) Strings (informativo, nao bloqueia)', '']
    for k, v in strdiff.items():
        lines.append(f'### {k}: {len(v["onlyA"])} so em A, {len(v["onlyB"])} so em B')
        for side in ('onlyA', 'onlyB'):
            sample = [s for s in v[side] if re.search(r'[A-Za-z_]{5}', s) and not s.startswith(('.L', '$'))][:80]
            home = os.path.expanduser('~')
            lines.append(f'- {side}: ' + ', '.join(
                f'`{s.replace(home, "~")[:80].replace("`", "")}`' for s in sample))
        lines.append('')
    text = '\n'.join(lines) + '\n'
    if o.report:
        open(o.report, 'w').write(text)
    if o.json:
        def clean(R):
            R = json.loads(json.dumps(R, default=sorted))
            for a in R['pe'].values():
                a.pop('strings', None)
            R['unix'].pop('strings', None)
            return R
        json.dump({'status': status, 'divergences': div, 'stats': stats, 'strings': strdiff,
                   'A': clean(A), 'B': clean(B)}, open(o.json, 'w'), indent=1)
    print(f'{status}: {len(div)} divergences in (a)-(d), {len(failing)} failing '
          f'(a={surfaces["a"]} b={surfaces["b"]} c={surfaces["c"]} d={surfaces["d"]})')
    for d in failing[:40]:
        print(f'  {d["id"]}: {d["detail"]}')
    sys.exit(0 if not failing else 1)


if __name__ == '__main__':
    main()
