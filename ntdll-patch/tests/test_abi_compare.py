"""Surface (b): a side with 0 extracted syscalls, or uneven counts, must diverge (never pass empty)."""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import abi_compare  # noqa: E402


def side(syscalls):
    pe = {'exports': {}, 'syscalls': syscalls, 'funcs': {}, 'strings': set()}
    return {'pe': {a: dict(pe) for a in abi_compare.DLLS},
            'unix': {'exports': {}, 'linkage': {'id': 'x', 'deps': [], 'rpaths': []},
                     'lookupNames': {}, 'tables': [], 'strings': set()}}


def ids(a, b):
    return {d['id'] for d in abi_compare.compare(a, b)[0] if d['surface'] == 'b'}


class SyscallCount(unittest.TestCase):
    def test_zero_both_sides_fails(self):
        self.assertTrue(any(i.startswith('b:syscall-count:') for i in ids(side({}), side({}))))

    def test_zero_one_side_fails(self):
        self.assertTrue(any(i.startswith('b:syscall-count:') for i in ids(side({'NtA': 1}), side({}))))

    def test_uneven_counts_fail(self):
        self.assertTrue(any(i.startswith('b:syscall-count:')
                            for i in ids(side({'NtA': 1}), side({'NtA': 1, 'NtB': 2}))))

    def test_equal_nonzero_passes(self):
        self.assertEqual(ids(side({'NtA': 1}), side({'NtA': 1})), set())


if __name__ == '__main__':
    unittest.main()
