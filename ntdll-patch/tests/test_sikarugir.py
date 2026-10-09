"""T04: the pin-driven ntdll patcher refuses anything that is not the exact pinned build.

Fixtures are synthetic PE images built here, so this runs without capstone and without any
third-party binary. Each refusal must leave the source file untouched and write no output.
"""
import hashlib
import os
import struct
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import apply  # noqa: E402

TEXT_RVA, TEXT_RAW, TEXT_VSIZE, TEXT_RSIZE = 0x1000, 0x200, 0x100, 0x200
HOOK_RVA = 0x1010
PAYLOAD_RVA = 0x1100
HOOK64 = bytes.fromhex('488b8590000000')     # mov rax, [rbp+0x90]
HOOK32 = bytes.fromhex('8b4514a801')         # mov eax, [ebp+0x14] ; test al, 1
PAYLOAD = bytes(range(0x40, 0x80))


def sha(b):
    return hashlib.sha256(b).hexdigest()


def make_pe(machine, hook, fill=0xcc):
    """One .text section; its raw tail past VirtualSize is the padding cave."""
    wide = machine == 0x8664
    optsz = 0xf0 if wide else 0xe0
    d = bytearray(0x400)
    d[0:2] = b'MZ'
    struct.pack_into('<I', d, 0x3c, 0x40)
    d[0x40:0x44] = b'PE\0\0'
    struct.pack_into('<HHIIIHH', d, 0x44, machine, 1, 0, 0, 0, optsz, 0x2022)
    opt = 0x58
    struct.pack_into('<H', d, opt, 0x20b if wide else 0x10b)
    if wide:
        struct.pack_into('<Q', d, opt + 24, 0x170000000)
    else:
        struct.pack_into('<I', d, opt + 28, 0x7bc00000)
    struct.pack_into('<II', d, opt + 32, 0x1000, 0x200)
    struct.pack_into('<II', d, opt + 56, 0x2000, 0x200)
    struct.pack_into('<I', d, opt + (108 if wide else 92), 16)
    sec = opt + optsz
    struct.pack_into('<8sIIIIIIHHI', d, sec, b'.text', TEXT_VSIZE, TEXT_RVA, TEXT_RSIZE,
                     TEXT_RAW, 0, 0, 0, 0, 0x60000020)
    d[TEXT_RAW:TEXT_RAW + TEXT_VSIZE] = bytes((i * 7 + 3) & 0xff for i in range(TEXT_VSIZE))
    d[TEXT_RAW + TEXT_VSIZE:TEXT_RAW + TEXT_RSIZE] = bytes([fill]) * (TEXT_RSIZE - TEXT_VSIZE)
    off = TEXT_RAW + HOOK_RVA - TEXT_RVA
    d[off:off + len(hook)] = hook
    return bytes(d)


def entry_for(data, arch, hook, placement='padding', fill=0xcc, payload=PAYLOAD):
    e = {'architecture': arch, 'cleanHash': sha(data), 'hookRVA': HOOK_RVA,
         'expectedBytes': hook.hex(), 'payloadHash': sha(payload), 'patchedHash': None,
         'cave': {'placement': placement, 'fill': fill, 'payloadRVA': PAYLOAD_RVA}}
    if placement == 'section':
        raw = (len(data) + 0x1ff) & ~0x1ff
        e['cave'] = {'placement': 'section', 'fill': 0, 'rva': 0x2000, 'payloadRVA': 0x2000,
                     'rawOffset': raw}
    return e


class Fixture(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)

    def write(self, data, name='ntdll.dll'):
        p = os.path.join(self.tmp.name, name)
        with open(p, 'wb') as f:
            f.write(data)
        return p

    def assert_refused(self, data, entry, payload=PAYLOAD, why=None):
        src = self.write(data)
        pay = self.write(payload, 'payload.bin')
        dst = os.path.join(self.tmp.name, 'ntdll.dll.patched')
        with self.assertRaises(SystemExit) as cm:
            apply.patch_file(src, dst, entry, pay)
        self.assertNotIn(cm.exception.code, (None, 0))
        if why:
            self.assertIn(why, str(cm.exception.code))
        with open(src, 'rb') as f:
            self.assertEqual(sha(f.read()), sha(data), 'source changed by a refused patch')
        self.assertFalse(os.path.exists(dst), 'output written by a refused patch')
        self.assertFalse(os.path.exists(dst + '.tmp'))


class Refusals(Fixture):
    def test_rejects_unknown_hash(self):
        data = make_pe(0x8664, HOOK64)
        entry = entry_for(data, 'x86_64-windows', HOOK64)
        entry['cleanHash'] = '0' * 64
        self.assert_refused(data, entry, why='hash')

    def test_rejects_changed_hook_bytes(self):
        data = make_pe(0x8664, HOOK64)
        entry = entry_for(data, 'x86_64-windows', HOOK64)
        entry['expectedBytes'] = '4883bc24f000000000'
        self.assert_refused(data, entry, why='hook')
        # same pins, same length, one byte off at the site
        other = bytes.fromhex('488b8598000000')
        data2 = make_pe(0x8664, other)
        entry2 = entry_for(data2, 'x86_64-windows', HOOK64)
        self.assert_refused(data2, entry2, why='hook')

    def test_rejects_out_of_bounds_rva(self):
        data = make_pe(0x8664, HOOK64)
        for rva in (0x10000,                          # not mapped at all
                    0x1f00,                           # inside SizeOfImage, no raw data
                    TEXT_RVA + TEXT_RSIZE - 3,        # starts in .text, runs off its raw end
                    0x10):                            # headers, not a section
            with self.subTest(rva=hex(rva)):
                entry = entry_for(data, 'x86_64-windows', HOOK64)
                entry['hookRVA'] = rva
                self.assert_refused(data, entry, why='bounds')
        entry = entry_for(data, 'x86_64-windows', HOOK64)
        entry['cave']['payloadRVA'] = TEXT_RVA + TEXT_RSIZE - 8   # payload spills off the file
        self.assert_refused(data, entry)

    def test_rejects_wrong_architecture(self):
        data = make_pe(0x14c, HOOK32)
        entry = entry_for(data, 'x86_64-windows', HOOK32)     # hash is right, arch is not
        self.assert_refused(data, entry, why='architecture')
        data64 = make_pe(0x8664, HOOK64)
        entry64 = entry_for(data64, 'i386-windows', HOOK64)
        self.assert_refused(data64, entry64, why='architecture')
        arm = bytearray(data64)
        struct.pack_into('<H', arm, 0x44, 0xaa64)
        self.assert_refused(bytes(arm), entry_for(bytes(arm), 'aarch64-windows', HOOK64),
                            why='architecture')

    def test_rejects_unpinned_or_wrong_payload(self):
        data = make_pe(0x8664, HOOK64)
        entry = entry_for(data, 'x86_64-windows', HOOK64)
        entry['payloadHash'] = None
        self.assert_refused(data, entry, why='payload')
        entry = entry_for(data, 'x86_64-windows', HOOK64)
        self.assert_refused(data, entry, payload=PAYLOAD + b'\0', why='payload')

    def test_rejects_dirty_cave(self):
        data = bytearray(make_pe(0x8664, HOOK64))
        data[TEXT_RAW + PAYLOAD_RVA - TEXT_RVA + 5] = 0x90
        data = bytes(data)
        self.assert_refused(data, entry_for(data, 'x86_64-windows', HOOK64), why='cave')

    def test_refuses_reapplication(self):
        data = make_pe(0x8664, HOOK64)
        entry = entry_for(data, 'x86_64-windows', HOOK64)
        patched = apply.patch_bytes(data, entry, PAYLOAD)
        self.assert_refused(patched, entry, why='hash')

    def test_refuses_in_place(self):
        data = make_pe(0x8664, HOOK64)
        src = self.write(data)
        pay = self.write(PAYLOAD, 'payload.bin')
        with self.assertRaises(SystemExit):
            apply.patch_file(src, src, entry_for(data, 'x86_64-windows', HOOK64), pay)
        with open(src, 'rb') as f:
            self.assertEqual(f.read(), data)


class Preserves(Fixture):
    def diff(self, a, b):
        return {i for i in range(min(len(a), len(b))) if a[i] != b[i]}

    def test_patch_preserves_unrelated_bytes(self):
        data = make_pe(0x8664, HOOK64)
        entry = entry_for(data, 'x86_64-windows', HOOK64)
        out = apply.patch_bytes(data, entry, PAYLOAD)
        self.assertEqual(len(out), len(data))
        hook_off = TEXT_RAW + HOOK_RVA - TEXT_RVA
        pay_off = TEXT_RAW + PAYLOAD_RVA - TEXT_RVA
        allowed = set(range(hook_off, hook_off + len(HOOK64))) | \
            set(range(pay_off, pay_off + len(PAYLOAD)))
        self.assertLessEqual(self.diff(data, out), allowed)
        rel = PAYLOAD_RVA - (HOOK_RVA + 5)
        self.assertEqual(out[hook_off:hook_off + 7],
                         b'\xe9' + struct.pack('<i', rel) + b'\xcc\xcc')
        self.assertEqual(out[pay_off:pay_off + len(PAYLOAD)], PAYLOAD)

        # patchedHash, once pinned, is enforced
        entry['patchedHash'] = sha(out)
        self.assertEqual(apply.patch_bytes(data, entry, PAYLOAD), out)
        entry['patchedHash'] = '1' * 64
        with self.assertRaises(SystemExit):
            apply.patch_bytes(data, entry, PAYLOAD)

    def test_patch_preserves_unrelated_bytes_appended_section(self):
        data = make_pe(0x14c, HOOK32, fill=0)
        entry = entry_for(data, 'i386-windows', HOOK32, placement='section')
        src = self.write(data)
        pay = self.write(PAYLOAD, 'payload.bin')
        dst = os.path.join(self.tmp.name, 'out.dll')
        apply.patch_file(src, dst, entry, pay)
        with open(dst, 'rb') as f:
            out = f.read()
        with open(src, 'rb') as f:
            self.assertEqual(f.read(), data)
        opt, table_end = 0x58, 0x58 + 0xe0 + 40
        hook_off = TEXT_RAW + HOOK_RVA - TEXT_RVA
        allowed = set(range(hook_off, hook_off + len(HOOK32))) \
            | set(range(table_end, table_end + 40)) \
            | set(range(0x46, 0x48)) | set(range(opt + 56, opt + 60))
        self.assertLessEqual(self.diff(data, out), allowed)
        raw = entry['cave']['rawOffset']
        self.assertEqual(out[raw:raw + len(PAYLOAD)], PAYLOAD)
        self.assertEqual(struct.unpack_from('<H', out, 0x46)[0], 2)


if __name__ == '__main__':
    unittest.main()
