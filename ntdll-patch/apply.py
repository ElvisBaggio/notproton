#!/usr/bin/env python3
# Development tool. The real patcher lives in the app (NtdllPatcher.swift).
# This is the original Python version, kept for validating patches against
# new CrossOver builds.
import hashlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from resolve import PE, SECTION_FLAGS, SECTION_NAME, SECTION_SIZE, resolve, shell_vars  # noqa: E402

# A new build needs its ntdll hash added here and in build-ntdll.sh.
PAYLOAD_BY_CLEAN_SHA = {
    "04c7200b6645decb7c2d1ba6b0195abc9af83257072558d11aa72cc067ac3377": "detour2.bin",
    "94cc7c14c1e9dcf58ef501015c115f8405c73b2a65cefe31faa5d9e47f36e58b": "detour32.bin",
    "f4fa556a3dc20f6e966a803f5de554359227a61a24cd5b5a2ad88a427ceeec58": "detour2-fex.bin",
    "09474795d6f306163cebab6429819999fcff50e07dbc4b067a90ec4f74a3a7d7": "detour32-fex.bin",
    "7823d71fbce6c9947163bf8b96beb299eabb02878245bcaf6759f2a22e81f071": "detour64-fex.bin",
    "6dff64c00793ce92124f1316985c63783f539f26b392975c70f57637458d2387": "detour2-cx26.bin",
    "2c60ee6b00dd13b7f6cb11017778a041ba6a321eaea194f1fa0dca7eab8403e2": "detour32-cx26.bin",
    "5b388fd48823e905616432fba627eb48f68dc14383963bb213d55db3f691b1b9": "detour2-41069.bin",
    "e7da2a712870222942ef27a80b3bf4fa70fc8545dd1a64bdc7f2fa24a38debc3": "detour32-41069.bin",
    "1b02dcf6ad9d9490870f1127a421c4c0d1471c65ec1574e1e84c05d69801ac7e": "detour2-fex-41069.bin",
    "66b1a244a611795c59a93a9491d17f36c98cd8db9be495004a37864e0e5ed4a5": "detour32-fex-41069.bin",
    "77ca83b2e1a3a1242f9d2d8868328262b2bcfc3f59bacf8b9389ea7e797ea852": "detour64-fex-41069.bin",
}

KNOWN_MACHINES = (0x8664, 0x14c, 0xaa64)


def default_payload(src):
    with open(src, "rb") as f:
        digest = hashlib.sha256(f.read()).hexdigest()
    if digest in PAYLOAD_BY_CLEAN_SHA:
        return PAYLOAD_BY_CLEAN_SHA[digest]
    raise SystemExit(f"{src}: sha256 {digest} matches no known clean ntdll, "
                     f"pass payload.bin as the third argument")


def append_section(pe, d, r):
    """Grows the image by one executable section and returns its file offset."""
    import struct
    raw = r['rawOffset']
    e = struct.unpack_from('<I', d, 0x3c)[0]
    d[pe.table_end:pe.table_end + 40] = struct.pack(
        '<8sIIIIIIHHI', SECTION_NAME, SECTION_SIZE, r['caveRVA'], SECTION_SIZE, raw,
        0, 0, 0, 0, SECTION_FLAGS)
    struct.pack_into('<H', d, e + 6, struct.unpack_from('<H', d, e + 6)[0] + 1)
    struct.pack_into('<I', d, pe.opt + 56, r['caveRVA'] + SECTION_SIZE)
    d.extend(b"\0" * (raw + SECTION_SIZE - len(d)))
    return raw


ARCH_MACHINE = {'x86_64-windows': 0x8664, 'i386-windows': 0x14c}


def _raw_span(pe, rva, size, what):
    """File offset of [rva, rva+size) when a section's raw data backs all of it."""
    for _, vrva, _, roff, rsize in pe.secs:
        if vrva <= rva and rva + size <= vrva + rsize and roff + (rva - vrva) + size <= len(pe.d):
            return roff + (rva - vrva)
    raise SystemExit(f"{what} rva {rva:#x}+{size} out of bounds of the file's section data")


def patch_bytes(data, entry, payload):
    """Patch one ntdll image from a patches.json entry (pins only, no disassembly).

    Refuses anything that is not exactly the pinned clean build: architecture, whole-file hash,
    payload hash, hook bytes and cave contents are all checked before a byte is written.
    """
    data = bytes(data)
    pe = PE('<image>', data)
    want = ARCH_MACHINE.get(entry.get('architecture'))
    if want is None or pe.machine != want:
        raise SystemExit(f"architecture: image is machine {pe.machine:#x}, entry is "
                         f"{entry.get('architecture')!r} (supported: {sorted(ARCH_MACHINE)})")
    got = hashlib.sha256(data).hexdigest()
    if got != entry.get('cleanHash'):
        state = 'already patched' if got == entry.get('patchedHash') else 'unknown'
        raise SystemExit(f"hash {got} is {state}, entry pins clean {entry.get('cleanHash')}")
    if not entry.get('payloadHash'):
        raise SystemExit("payload hash not pinned for this entry, refusing to patch")
    if hashlib.sha256(payload).hexdigest() != entry['payloadHash']:
        raise SystemExit(f"payload sha256 {hashlib.sha256(payload).hexdigest()} "
                         f"is not the pinned {entry['payloadHash']}")

    hook = entry['hookRVA']
    stolen = bytes.fromhex(entry['expectedBytes'])
    if len(stolen) < 5:
        raise SystemExit(f"hook at {hook:#x} steals {len(stolen)} bytes, a jmp needs 5")
    hook_off = _raw_span(pe, hook, len(stolen), 'hook')
    if data[hook_off:hook_off + len(stolen)] != stolen:
        raise SystemExit(f"hook bytes at {hook:#x} are {data[hook_off:hook_off + len(stolen)].hex()}, "
                         f"pinned {stolen.hex()}")

    cave = entry['cave']
    d = bytearray(data)
    if cave['placement'] == 'section':
        fresh = pe.appended()
        if (cave['rva'], cave['rawOffset']) != (fresh['caveRVA'], fresh['rawOffset']) \
                or cave['payloadRVA'] != cave['rva'] or len(payload) > SECTION_SIZE:
            raise SystemExit("cave section pins do not match the image layout")
        cave_off = append_section(pe, d, {'rawOffset': cave['rawOffset'], 'caveRVA': cave['rva']})
    elif cave['placement'] == 'padding':
        cave_off = _raw_span(pe, cave['payloadRVA'], len(payload), 'cave')
    else:
        raise SystemExit(f"cave placement {cave['placement']!r} unknown")
    if any(b != cave['fill'] for b in d[cave_off:cave_off + len(payload)]):
        raise SystemExit(f"cave at {cave_off:#x} is not {cave['fill']:#04x} fill "
                         f"for {len(payload)} bytes")
    d[cave_off:cave_off + len(payload)] = payload

    rel = cave['payloadRVA'] - (hook + 5)
    d[hook_off:hook_off + len(stolen)] = \
        b"\xE9" + rel.to_bytes(4, 'little', signed=True) + b"\xCC" * (len(stolen) - 5)

    out = bytes(d)
    if entry.get('patchedHash') and hashlib.sha256(out).hexdigest() != entry['patchedHash']:
        raise SystemExit(f"patched image is {hashlib.sha256(out).hexdigest()}, "
                         f"pinned {entry['patchedHash']}")
    return out


def patch_file(src, dst, entry, payload_path):
    """patch_bytes on files; never writes over the source, output appears only when complete."""
    if os.path.exists(dst) and os.path.samefile(src, dst):
        raise SystemExit(f"{dst}: refusing to patch in place")
    with open(src, 'rb') as f:
        data = f.read()
    with open(payload_path, 'rb') as f:
        payload = f.read()
    out = patch_bytes(data, entry, payload)
    tmp = dst + ".tmp"
    with open(tmp, "wb") as f:
        f.write(out)
    os.replace(tmp, dst)
    return hashlib.sha256(out).hexdigest()


def main_manifest(argv):
    """apply.py --manifest patches.json <src ntdll.dll> <dst> <payload.bin>"""
    import json
    if len(argv) != 4:
        raise SystemExit("usage: apply.py --manifest <patches.json> <src ntdll.dll> <dst> <payload.bin>")
    manifest, src, dst, payload = argv
    with open(manifest) as f:
        entries = json.load(f)['entries']
    machine = PE(src).machine
    match = [e for e in entries if ARCH_MACHINE.get(e.get('architecture')) == machine]
    if len(match) != 1:
        raise SystemExit(f"{src}: {len(match)} manifest entries for machine {machine:#x}, want 1")
    got = patch_file(src, dst, match[0], payload)
    print(f"patched {src} -> {dst} ({match[0]['architecture']}), sha256 {got}")


def main():
    if len(sys.argv) > 1 and sys.argv[1] == '--manifest':
        return main_manifest(sys.argv[2:])
    if len(sys.argv) < 2:
        raise SystemExit(f"usage: {sys.argv[0]} <src ntdll.dll> [dst] [payload.bin]")
    src = sys.argv[1]
    dst = sys.argv[2] if len(sys.argv) > 2 else "ntdll.dll.patched"
    here = os.path.dirname(os.path.abspath(__file__))

    r = resolve(src)
    v = shell_vars(src)
    if r['machine'] not in KNOWN_MACHINES:
        raise SystemExit(f"{src}: machine {r['machine']:#x} carries no detour")
    payload_path = sys.argv[3] if len(sys.argv) > 3 \
        else os.path.join(here, default_payload(src))
    detour = open(payload_path, "rb").read()
    payload_rva = int(v['NP_PAYLOAD_RVA'], 16)
    fill = r['fill']
    sites = r.get('sites') or [r]

    pe = PE(src)
    d = bytearray(pe.d)
    if r['placement'] == 'section':
        cave_off = append_section(pe, d, r)
    else:
        cave_off = pe.off(payload_rva)

    if any(b != fill for b in d[cave_off:cave_off + len(detour)]):
        raise SystemExit(f"cave at {cave_off:#x} is not {fill:#02x} pad for {len(detour)} bytes")
    d[cave_off:cave_off + len(detour)] = detour

    hooks = []
    for site in sites:
        bm_off = pe.off(site['hookRVA'])
        stolen = bytes.fromhex(site['stolen'])
        if d[bm_off:bm_off + len(stolen)] != stolen:
            raise SystemExit(f"unexpected hook site at {site['hookRVA']:#x}: "
                             f"{d[bm_off:bm_off + len(stolen)].hex()}")
        if r['machine'] == 0xaa64:
            rel = payload_rva - site['hookRVA']
            if rel % 4 or not -(1 << 27) <= rel < (1 << 27):
                raise SystemExit(f"cave is {rel:#x} from the hook, out of bl range")
            patch = (0x94000000 | ((rel >> 2) & 0x03ffffff)).to_bytes(4, 'little')
        else:
            # E9 rel32 to the shim at the payload start
            rel = payload_rva - (site['hookRVA'] + 5)
            patch = b"\xE9" + rel.to_bytes(4, 'little', signed=True) + b"\xCC" * (len(stolen) - 5)
        assert len(patch) == len(stolen)
        d[bm_off:bm_off + len(patch)] = patch
        hooks.append((site, bm_off, rel, stolen))

    # patch in memory and write once, like a pro
    tmp = dst + ".tmp"
    with open(tmp, "wb") as f:
        f.write(d)
    os.replace(tmp, dst)

    print(f"patched {src} -> {dst}")
    print(f"  payload {os.path.basename(payload_path)}, {len(detour)} bytes at rva "
          f"{payload_rva:#x} (off {cave_off:#x}), cave pad {fill:#02x}")
    for site, bm_off, rel, stolen in hooks:
        print(f"  hook {site['hookRVA']:#x} (off {bm_off:#x}) branch rel {rel:#x} to cave "
              f"entry, stolen {stolen.hex()}")


if __name__ == "__main__":
    main()
