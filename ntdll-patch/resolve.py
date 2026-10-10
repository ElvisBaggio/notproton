#!/usr/bin/env python3
# Reads every per-build constant the ntdll detours need out of the binary, for
# all archs. Internal development tool, ugly
import hashlib, json, pathlib, struct, sys, re, bisect
try:
    import capstone
    from capstone import x86 as X86
except ImportError:  # PE parsing and the pin-driven patcher in apply.py work without it
    capstone = X86 = None

ARCH = {0x8664: 'x86_64-windows', 0x14c: 'i386-windows'}

PAYLOAD = {0x8664: 864, 0x14c: 1376}  # detour2.bin, detour32.bin size ceilings

# Keyed by input sha256 so the comparison only runs against a build the tree pins; an unpinned
# build reports derived values rather than a wall of expected mismatches.
PINNED = {}

EXPORTS = ['LdrGetDllHandle', 'LdrLoadDll', 'NtProtectVirtualMemory',
           'NtOpenFile', 'NtReadFile', 'NtClose']
SECTION_NAME, SECTION_SIZE, SECTION_FLAGS = b'.npdet', 0x1000, 0x60000020
PROLOGUES = [rb'\x55\x89\xe5', rb'\x55\x8b\xec']
NOP64 = bytes.fromhex('1f2003d5')

# A byte test on a register has to be traced back to the dword that loaded it, so the two
# names have to compare equal.
SUBREG = {'al': 'eax', 'ah': 'eax', 'ax': 'eax', 'bl': 'ebx', 'bh': 'ebx', 'bx': 'ebx',
          'cl': 'ecx', 'ch': 'ecx', 'cx': 'ecx', 'dl': 'edx', 'dh': 'edx', 'dx': 'edx',
          'si': 'esi', 'di': 'edi', 'bp': 'ebp', 'sp': 'esp'}


class PE:
    def __init__(self, path, data=None):
        self.path = path
        self.d = open(path, 'rb').read() if data is None else data
        e = struct.unpack_from('<I', self.d, 0x3c)[0]
        self.machine = struct.unpack_from('<H', self.d, e + 4)[0]
        nsec = struct.unpack_from('<H', self.d, e + 6)[0]
        optsz = struct.unpack_from('<H', self.d, e + 20)[0]
        self.opt = e + 24
        self.magic = struct.unpack_from('<H', self.d, self.opt)[0]
        wide = self.magic == 0x20b
        self.imagebase = (struct.unpack_from('<Q', self.d, self.opt + 24)[0] if wide
                          else struct.unpack_from('<I', self.d, self.opt + 28)[0])
        self.secs = []
        for i in range(nsec):
            o = e + 24 + optsz + i * 40
            name = self.d[o:o + 8].rstrip(b'\0').decode('latin1')
            vsize, vrva, rsize, roff = struct.unpack_from('<IIII', self.d, o + 8)
            if roff:
                self.secs.append((name, vrva, vsize, roff, rsize))
        self.dirs = self.opt + (112 if wide else 96)
        self.table_end = e + 24 + optsz + nsec * 40
        self.sect_align, self.file_align = struct.unpack_from('<II', self.d, self.opt + 32)
        self.size_of_image, self.size_of_headers = struct.unpack_from('<II', self.d, self.opt + 56)

    def sec(self, prefix):
        for s in self.secs:
            if s[0].startswith(prefix):
                return s
        raise SystemExit(f"{self.path}: no {prefix} section")

    def off(self, rva):
        for _, vrva, vsize, roff, rsize in self.secs:
            if vrva <= rva < vrva + max(vsize, rsize):
                return roff + (rva - vrva)
        raise SystemExit(f"{self.path}: rva {rva:#x} not mapped")

    def text(self):
        _, vrva, _, roff, rsize = self.sec('.text')
        return vrva, self.d[roff:roff + rsize]

    def cs(self):
        if capstone is None:
            raise SystemExit("resolving hooks needs capstone (pip install capstone in a venv)")
        md = capstone.Cs(capstone.CS_ARCH_X86,
                         capstone.CS_MODE_64 if self.machine == 0x8664 else capstone.CS_MODE_32)
        md.detail = True
        return md

    def pdata_starts(self):
        """Function entry RVAs from the exception directory, ascending."""
        _, _, _, proff, prsize = self.sec('.pdata')
        stride = 12
        out = {struct.unpack_from('<I', self.d, o)[0] for o in range(proff, proff + prsize, stride)}
        return sorted(out - {0})

    def exports(self):
        edir = struct.unpack_from('<I', self.d, self.dirs)[0]
        o = self.off(edir)
        nnames = struct.unpack_from('<I', self.d, o + 0x18)[0]
        afun, anam, aord = struct.unpack_from('<III', self.d, o + 0x1c)
        fo, no, oo = self.off(afun), self.off(anam), self.off(aord)
        out = {}
        for i in range(nnames):
            nrva = struct.unpack_from('<I', self.d, no + 4 * i)[0]
            ordn = struct.unpack_from('<H', self.d, oo + 2 * i)[0]
            frva = struct.unpack_from('<I', self.d, fo + 4 * ordn)[0]
            s = self.off(nrva)
            out[self.d[s:self.d.index(b'\0', s)].decode('latin1')] = frva
        return out

    def cave(self):
        # PE sections are padded out to the file alignment, so there's dead space
        # at the end that the loader maps but nothing touches. Detour goes there.
        _, vrva, vsize, roff, rsize = self.sec('.text')
        end = vrva + vsize
        return {'caveRVA': end, 'caveSize': (vrva + rsize) - end, 'fill': self.d[roff + vsize],
                'placement': 'padding'}

    def appended(self):
        # The section is mapped at SizeOfImage, and its raw data goes after everything else in
        # the file, the certificate included.
        if self.table_end + 40 > self.size_of_headers or any(self.d[self.table_end:self.table_end + 40]):
            raise SystemExit(f"{self.path}: no free section header slot after the table")
        raw = (len(self.d) + self.file_align - 1) & ~(self.file_align - 1)
        return {'caveRVA': self.size_of_image, 'caveSize': SECTION_SIZE, 'fill': 0,
                'placement': 'section', 'rawOffset': raw}

    def string_refs(self, name):
        """RVAs of instructions referencing a .rdata C string, however the arch addresses it."""
        _, rvrva, _, rroff, rrsize = self.sec('.rdata')
        k = self.d[rroff:rroff + rrsize].find(name.encode() + b'\0')
        if k == -1:
            raise SystemExit(f"{self.path}: no {name} string; not a traced wine build")
        srva = rvrva + k
        tvrva, text = self.text()
        if self.machine == 0x14c:
            # No EIP-relative addressing, so the absolute VA appears as a literal.
            pat = re.escape(struct.pack('<I', self.imagebase + srva))
            return srva, [tvrva + m.start() for m in re.finditer(pat, text)]
        hits = []
        for i in self.cs().disasm(text, tvrva):
            for op in i.operands:
                if op.type == X86.X86_OP_MEM and op.mem.base == X86.X86_REG_RIP:
                    if i.address + i.size + op.mem.disp == srva:
                        hits.append(i.address)
        return srva, hits

    def func_start(self, before):
        """Nearest frame-pointer prologue at or before an address."""
        tvrva, text = self.text()
        best = None
        for pat in PROLOGUES:
            for m in re.finditer(pat, text[:before - tvrva]):
                if best is None or m.start() > best:
                    best = m.start()
        if best is None:
            raise SystemExit(f"{self.path}: no prologue before {before:#x}")
        return tvrva + best


def steal(insns, k, need=5):
    """Whole instructions from insns[k] totalling at least `need` bytes."""
    taken, total = [], 0
    while total < need:
        taken.append(insns[k + len(taken)])
        total += taken[-1].size
    return taken, total


def resolve_amd64(pe):
    md = pe.cs()
    tvrva, text = pe.text()
    insns = list(md.disasm(text, tvrva))

    _, pvrva, pvsize, proff, _ = pe.sec('.pdata')
    funcs = []
    for o in range(proff, proff + pvsize, 12):
        begin, end, _ = struct.unpack_from('<III', pe.d, o)
        if begin:
            funcs.append((begin, end))

    owner = {}
    for name in ('build_module', 'alloc_module'):
        _, refs = pe.string_refs(name)
        for r in refs:
            for begin, end in funcs:
                if begin <= r < end:
                    owner.setdefault(name, (begin, end))
    bm = owner['build_module']
    am = owner['alloc_module'][0]

    body = [i for i in insns if bm[0] <= i.address < bm[1]]
    calls = [k for k, i in enumerate(body) if i.mnemonic == 'call' and i.op_str == hex(am)]
    if len(calls) != 1:
        raise SystemExit(f"{pe.path}: {len(calls)} alloc_module calls in build_module, want 1")

    k, wm = calls[0] + 1, None
    while True:
        i = body[k]
        if i.mnemonic == 'test' and i.op_str == 'rax, rax':
            k += 1
        elif i.mnemonic == 'mov' and i.op_str.endswith(', rax'):
            wm = i.op_str.split(',')[0].strip()
            k += 1
        elif i.mnemonic in ('je', 'jz'):
            k += 1
        else:
            break
    hook = body[k]
    # The jmp replacing it is 5 bytes and the instruction is replayed from the cave, so it has
    # to be long enough, not rip-relative, and nothing may branch into the middle of it.
    if hook.size < 5:
        raise SystemExit(f"{pe.path}: hook insn at {hook.address:#x} is {hook.size} bytes, need 5")
    if any(o.type == X86.X86_OP_MEM and o.mem.base == X86.X86_REG_RIP for o in hook.operands):
        raise SystemExit(f"{pe.path}: hook insn at {hook.address:#x} is rip-relative")
    for i in body:
        if i.group(capstone.CS_GRP_JUMP) and i.operands and i.operands[0].type == X86.X86_OP_IMM \
                and hook.address < i.operands[0].imm < hook.address + hook.size:
            raise SystemExit(f"{pe.path}: {i.address:#x} branches into the hook insn")
    if wm is None:
        raise SystemExit(f"{pe.path}: alloc_module result never kept in a register before the hook")
    slot = amd64_load_path(pe, body, hook.address)
    return {'build_module': bm, 'alloc_module': am, 'wm': wm, 'load_path': slot,
            'hookRVA': hook.address, 'stolen': hook.bytes.hex(), 'insn': f"{hook.mnemonic} {hook.op_str}"}


def amd64_load_path(pe, body, hook):
    """Frame slot holding the load_path argument, read as [rsp+N] at the hook."""
    # Neither build keeps the argument in rcx. One spills it to the stack right away,
    # the other stashes it in a callee-saved register and reuses that a few instructions
    # later.
    # A third build (Wine 11.0 as Sikarugir and upstream ship it) sets up rbp = rsp + K right
    # after the prologue and spills the argument to [rbp - N]; that is still the rsp slot K - N.
    src, slot, stored_at = 'rcx', None, None
    frame, frame_at, rbp_form, spill_at = None, None, None, None
    for i in body:
        if i.address >= hook:
            break
        m = re.fullmatch(r'rbp, \[rsp(?: \+ (0x[0-9a-f]+))?\]', i.op_str)
        if i.mnemonic == 'lea' and m and frame is None:
            frame, frame_at = int(m.group(1) or '0', 16), i.address
            continue
        if i.mnemonic != 'mov' or ',' not in i.op_str:
            continue
        dst, rhs = (x.strip() for x in i.op_str.split(',', 1))
        if rhs != src:
            continue
        if dst.startswith('qword ptr [rsp'):
            slot = 0 if '+' not in dst else int(dst.split('+')[1].strip().rstrip(']'), 16)
            stored_at = i.address
            break
        m = re.fullmatch(r'qword ptr \[rbp(?: ([-+]) (0x[0-9a-f]+))?\]', dst)
        if m and frame is not None:
            disp = int(m.group(2) or '0', 16) * (-1 if m.group(1) == '-' else 1)
            slot, stored_at, rbp_form, spill_at = frame + disp, frame_at, dst, i.address
            if slot < 0:
                raise SystemExit(f"{pe.path}: load_path spilled below rsp at {i.address:#x}")
            break
        if re.fullmatch(r'r[a-z0-9]+', dst):
            src = dst
    if slot is None:
        raise SystemExit(f"{pe.path}: load_path never reaches the frame in build_module")

    # The shim reads the slot off rsp, so anything moving rsp in between would shift it, and
    # a second write to it would mean the slot is reused for something else. With a frame
    # pointer the window starts where rbp was pinned to rsp, and rbp itself must not move.
    forms = [f'qword ptr [rsp + {slot:#x}],'] + ([rbp_form + ','] if rbp_form else [])
    for i in body:
        if not stored_at < i.address < hook:
            continue
        if i.mnemonic in ('push', 'pop') or (i.mnemonic in ('sub', 'add') and i.op_str.startswith('rsp,')):
            raise SystemExit(f"{pe.path}: rsp moves at {i.address:#x}, load_path slot not rsp-stable")
        if rbp_form and i.op_str.startswith('rbp,') and i.mnemonic not in ('cmp', 'test'):
            raise SystemExit(f"{pe.path}: rbp rewritten at {i.address:#x}, load_path slot lost")
        if i.mnemonic == 'mov' and i.address != spill_at and any(i.op_str.startswith(f) for f in forms):
            raise SystemExit(f"{pe.path}: load_path slot rewritten at {i.address:#x}")
    return slot


def resolve_i386(pe):
    md = pe.cs()
    tvrva, _ = pe.text()
    _, refs = pe.string_refs('build_module')
    start = pe.func_start(min(refs))
    body = list(md.disasm(pe.d[pe.off(start):pe.off(start) + 0x1400], start))

    # LDR_DATA_TABLE_ENTRY.Flags is at +0x34, so byte 3 of that field is at +0x37.
    # The fixup_imports gate tests bit 0 of that byte, and the register being
    # dereferenced is the MODREF.
    anchor = None
    for k, i in enumerate(body):
        if i.mnemonic == 'test' and re.match(r'^byte ptr \[e\w\w \+ 0x37\], 1$', i.op_str):
            anchor = k
            break
    if anchor is None:
        raise SystemExit(f"{pe.path}: no MODREF flag test in build_module")
    wm = re.search(r'\[(e\w\w) \+ 0x37\]', body[anchor].op_str).group(1)

    # The module flags are tested just above, with bit 2 in Wine 11.15 and bit 1 in 11.0.
    # Either the value is still in memory or the compiler loaded it first, in which case that
    # load starts the hook.
    gate = None
    for k in range(anchor - 1, max(anchor - 24, 0), -1):
        i = body[k]
        if i.mnemonic == 'test' and i.operands and i.operands[-1].type == X86.X86_OP_IMM \
                and i.operands[-1].imm in (1, 2):
            gate = k
            break
    if gate is None:
        raise SystemExit(f"{pe.path}: no module-flags gate above the MODREF flag test")
    # If the test uses a register, the flags were already loaded before the hook site.
    # Stealing just the test wouldn't work, the detour would replay a read from a
    # register it never set up....
    hook_k = gate
    tested = body[gate].operands[0]
    if tested.type == X86.X86_OP_REG:
        want = SUBREG.get(body[gate].reg_name(tested.reg), body[gate].reg_name(tested.reg))
        for k in range(gate - 1, max(gate - 8, -1), -1):
            i = body[k]
            if i.mnemonic != 'mov' or i.operands[0].type != X86.X86_OP_REG:
                continue
            if SUBREG.get(i.reg_name(i.operands[0].reg), i.reg_name(i.operands[0].reg)) == want:
                hook_k = k
                break
        else:
            raise SystemExit(f"{pe.path}: {want} tested at {body[gate].address:#x} with no load above")
    # build_module's flags live in a frame slot. The gate either reads the slot
    # directly or loads it into a register first. Whichever instruction has the
    # memory operand tells us which slot it is.
    holder = body[gate] if tested.type != X86.X86_OP_REG else body[hook_k]
    mem = [o for o in holder.operands if o.type == X86.X86_OP_MEM]
    if len(mem) != 1:
        raise SystemExit(f"{pe.path}: {holder.address:#x} does not read the flags from memory")
    flags_slot = mem[0].mem.disp

    taken, total = steal(body, hook_k)

    jk = None
    for k in range(gate + 1, min(gate + 8, len(body))):
        if body[k].mnemonic in ('jne', 'jnz'):
            jk = k
            break
        if X86.X86_REG_EFLAGS in body[k].regs_access()[1]:
            break
    if jk is None:
        raise SystemExit(f"{pe.path}: no branch on the module-flags gate at {body[gate].address:#x}")
    skip = body[jk].operands[0].imm
    stole_branch = taken[-1].address == body[jk].address

    load_path = None
    for i in body[anchor:anchor + 12]:
        if i.mnemonic == 'mov' and i.op_str.startswith('edx, dword ptr [ebp'):
            m = re.search(r'ebp ([-+]) (0x[0-9a-f]+)', i.op_str)
            load_path = int(m.group(2), 16) * (-1 if m.group(1) == '-' else 1)
        if i.mnemonic == 'call':
            break
    return {'build_module': (start, None), 'wm': wm, 'hookRVA': taken[0].address,
            'stolen': b''.join(i.bytes for i in taken).hex(), 'stolen_len': total,
            'insn': ' ; '.join(f"{i.mnemonic} {i.op_str}" for i in taken),
            'load_path': load_path, 'skip': skip, 'stole_branch': stole_branch,
            'stolen_head': b''.join(i.bytes for i in (taken[:-1] if stole_branch else taken)).hex(),
            'flags_slot': flags_slot, 'flags_bit': body[gate].operands[-1].imm}


def resolve(path):
    pe = PE(path)
    r = resolve_amd64(pe) if pe.machine == 0x8664 else resolve_i386(pe)
    r.update(pe.cave())
    if r['caveSize'] < PAYLOAD[pe.machine]:
        r.update(pe.appended())
    r['machine'], r['magic'], r['imageBase'] = pe.machine, pe.magic, pe.imagebase
    ex = pe.exports()
    r['exports'] = {n: pe.imagebase + ex[n] for n in EXPORTS if n in ex}
    r['resume'] = r['hookRVA'] + len(r['stolen']) // 2
    r['sha256'] = hashlib.sha256(pe.d).hexdigest()
    return r


def report(path):
    machine = PE(path).machine
    if machine not in ARCH:
        print(f"{path}\n  machine {machine:#x} carries no detour, skipped\n")
        return True
    r = resolve(path)
    pin = PINNED.get(r['sha256'], {})
    arch = ARCH[machine]
    print(f"{path}\n  arch {arch}  machine {r['machine']:#x}  magic {r['magic']:#x}"
          f"  imageBase {r['imageBase']:#x}\n  sha256 {r['sha256']}"
          f"{'  (the pinned build, self-testing)' if pin else '  (not a pinned build)'}")
    ok = True

    def line(label, got, key=None, fmt=lambda v: f"{v:#x}", want=pin):
        nonlocal ok
        tag = ""
        if key and key in want:
            match = want[key] == got
            ok = ok and match
            tag = "  MATCH" if match else f"  MISMATCH (pinned {fmt(want[key])})"
        print(f"  {label:13} {fmt(got)}{tag}")

    sites = r.get('sites')
    pinned_sites = pin.get('sites') or []
    for n, s in enumerate(sites or [r], 1):
        want = pin
        if sites:
            want = pinned_sites[n - 1] if n <= len(pinned_sites) else {}
            print(f"  hook {n} of {len(sites)}, build_module at {s['build_module']:#x}")
        line('hookRVA', s['hookRVA'], 'hookRVA', want=want)
        print(f"  {'insn':13} {s['insn']}")
        line('stolen', s['stolen'], 'stolen', fmt=str, want=want)
        line('resume', s['resume'], 'resume', want=want)
        line('wm', s['wm'], 'wm', fmt=str, want=want)
        if s.get('load_path') is not None:
            frame = {0x8664: 'rsp', 0x14c: 'ebp'}[machine]
            slot = ((lambda v: f"{frame}+{v:#x}") if machine == 0x8664
                    else (lambda v: f"{frame}{v:+#x}"))
            line('load_path', s['load_path'], 'load_path', fmt=slot, want=want)
    line('caveRVA', r['caveRVA'], 'caveRVA')
    line('caveSize', r['caveSize'], 'caveSize', fmt=str)
    need = PAYLOAD[r['machine']]
    print(f"  {'placement':13} {r['placement']}")
    print(f"  {'cave fill':13} {r['fill']:#02x}   room {r['caveSize']} bytes, payload {need}"
          f" -> {'fits' if r['caveSize'] >= need else 'TOO SMALL'}")
    def table(items, want):
        nonlocal ok
        for n, va in items.items():
            pinned_va = want.get(n)
            tag = ""
            if pinned_va:
                match = pinned_va == va
                ok = ok and match
                tag = "  MATCH" if match else f"  MISMATCH (pinned {pinned_va:#x})"
            print(f"    {n:24} {va:#x}{tag}")

    table(r['exports'], pin.get('exports', {}))
    if r.get('guest'):
        print("  guest loader, which is what link64.ld resolves instead")
        table(r['guest'], pin.get('guest', {}))
    if pin:
        print(f"  self-test: {'all pinned values reproduced' if ok else 'FAILED'}")
    print()
    return ok if pin else True


def ntdlls(arg):
    """Every ntdll.dll under an app bundle, a wine root, or a wine directory."""
    p = pathlib.Path(arg)
    if p.is_file():
        return [str(p)]
    for root in (p / 'Contents/SharedSupport/wine/lib/wine', p / 'lib/wine', p):
        archs = sorted(d for d in root.glob('*-windows') if d.is_dir())
        if not archs:
            continue
        found = []
        for d in archs:
            for name in ('ntdll.dll.notproton-orig', 'ntdll.dll'):
                if (d / name).is_file():
                    found.append(str(d / name))
                    break
        if found:
            return found
    raise SystemExit(f"{arg}: no <arch>-windows/ntdll.dll under it")


def shell_vars(path):
    """Everything build.sh and apply.py need for one ntdll, as shell assignments."""
    r = resolve(path)
    payload = (r['caveRVA'] + 15) & ~15
    room = r['caveSize'] - (payload - r['caveRVA'])
    need = PAYLOAD[r['machine']]
    if room < need:
        raise SystemExit(f"{path}: cave has {room} bytes at {payload:#x}, payload needs {need}")
    scratch = 'rsi' if r['wm'] == 'rbx' else 'rbx'
    out = {
        'NP_ARCH': ARCH[r['machine']], 'NP_MACHINE': f"{r['machine']:#x}",
        'NP_MAGIC': f"{r['magic']:#x}", 'NP_IMAGEBASE': f"{r['imageBase']:#x}",
        'NP_SHA256': r['sha256'],
        'NP_HOOK_RVA': f"{r['hookRVA']:#x}", 'NP_STOLEN': r['stolen'],
        'NP_STOLEN_BYTES': ','.join(f"0x{b:02x}" for b in bytes.fromhex(r['stolen'])),
        'NP_STOLEN_LEN': str(len(r['stolen']) // 2),
        'NP_RESUME_VA': f"{r['imageBase'] + r['resume']:#x}",
        'NP_WM': r['wm'], 'NP_SCRATCH': scratch,
        'NP_LOAD_PATH': f"{r['load_path']:#x}" if r.get('load_path') is not None else '',
        'NP_CAVE_RVA': f"{r['caveRVA']:#x}", 'NP_CAVE_SIZE': str(r['caveSize']),
        'NP_PAYLOAD_RVA': f"{payload:#x}", 'NP_PAYLOAD_VA': f"{r['imageBase'] + payload:#x}",
        'NP_CAVE_ROOM': str(room), 'NP_FILL': f"{r['fill']:#04x}",
        'NP_PLACEMENT': r['placement'],
    }
    if r['sha256'] in ('da7e1ea5d7e6bca3192ff5aa4a603302a9572233a1dbe02c9c8d85505101f676',
                       'e1ce5ae37f57cee3c4fea80b681fbf64e3f0611b36d5c9125851c03dea985589'):
        out['NP_SIKARUGIR_WINE11'] = '1'
    if PINNED.get(r['sha256'], {}).get('payload'):
        out['NP_PAYLOAD_SHA256'] = PINNED[r['sha256']]['payload']
    if r.get('skip') is not None:
        out['NP_SKIP_VA'] = f"{r['imageBase'] + r['skip']:#x}"
        out['NP_STOLE_BRANCH'] = '1' if r['stole_branch'] else ''
        out['NP_STOLEN_HEAD_BYTES'] = ','.join(
            f"0x{b:02x}" for b in bytes.fromhex(r['stolen_head']))
        out['NP_FLAGS_SLOT'] = ('%#x' if r['flags_slot'] >= 0 else '-%#x') % abs(r['flags_slot'])
        out['NP_FLAGS_BIT'] = f"{r['flags_bit']:#x}"

    for n, s in enumerate(r.get('sites') or [], 1):
        out[f'NP_HOOK_RVA_{n}'] = f"{s['hookRVA']:#x}"
        out[f'NP_STOLEN_{n}'] = s['stolen']
        out[f'NP_RESUME_VA_{n}'] = f"{r['imageBase'] + s['resume']:#x}"
        out[f'NP_LOAD_PATH_{n}'] = f"{s['load_path']:#x}"
    if r.get('sites'):
        out['NP_SITES'] = str(len(r['sites']))

    for n, va in r['exports'].items():
        out['NP_' + re.sub(r'(?<!^)(?=[A-Z])', '_', n).upper()] = f"{va:#x}"
    for n, rva in (r.get('guest') or {}).items():
        out['NP_' + re.sub(r'(?<!^)(?=[A-Z])', '_', n).upper()] = f"{r['imageBase'] + rva:#x}"
    return out


def manifest_entry(path):
    """One patches.json entry, every pin read from this exact file. The payload and the patched
    image do not exist yet at this point, so their hashes start out null."""
    r, v = resolve(path), shell_vars(path)
    if r.get('sites'):
        raise SystemExit(f"{path}: multi-site images are not described by a manifest entry")
    cave = {'rva': r['caveRVA'], 'size': r['caveSize'], 'payloadRVA': int(v['NP_PAYLOAD_RVA'], 16),
            'room': int(v['NP_CAVE_ROOM']), 'placement': r['placement'], 'fill': r['fill']}
    if r['placement'] == 'section':
        cave['rawOffset'] = r['rawOffset']
    return {'architecture': ARCH[r['machine']], 'machine': r['machine'], 'imageBase': r['imageBase'],
            'cleanHash': r['sha256'], 'hookRVA': r['hookRVA'], 'expectedBytes': r['stolen'],
            'resumeRVA': r['resume'], 'wm': r['wm'], 'loadPath': r['load_path'], 'cave': cave,
            'exports': r['exports'], 'payloadHash': None, 'patchedHash': None,
            'evidence': {'tool': 'ntdll-patch/resolve.py --json', 'insn': r['insn'],
                         'buildModuleRVA': r['build_module'][0], 'shellVars': v}}


if __name__ == '__main__':
    if len(sys.argv) < 2:
        raise SystemExit(f"usage: {sys.argv[0]} [--sh | --json] <Sikarugir app | wine dir | ntdll.dll> ...")
    if sys.argv[1] == '--json':
        entries = [manifest_entry(p) for arg in sys.argv[2:] for p in ntdlls(arg)]
        print(json.dumps({'schemaVersion': 1, 'entries': entries}, indent=2))
        sys.exit(0)
    if sys.argv[1] == '--sh':
        if len(sys.argv) != 3:
            raise SystemExit("--sh takes one ntdll.dll")
        for k, v in shell_vars(sys.argv[2]).items():
            print(f"{k}='{v}'")
        sys.exit(0)
    paths = [p for arg in sys.argv[1:] for p in ntdlls(arg)]
    sys.exit(0 if all([report(p) for p in paths]) else 1)
