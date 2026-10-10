import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("stage_sikarugir", Path(__file__).parents[1] / "stage-sikarugir-payload.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class StageTests(unittest.TestCase):
    def test_all_inputs_checked_before_write(self):
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            source, target = root / "source", root / "target"
            source.mkdir()
            target.mkdir()
            (source / "first").write_bytes(b"good")
            (source / "second").write_bytes(b"wrong")
            (target / "first").write_bytes(b"previous")
            hashes = {name: hashlib.sha256(b"good").hexdigest() for name in ["first", "second"]}
            with patch.object(module, "FILES", hashes):
                with self.assertRaises(ValueError):
                    module.stage(source, target)
                self.assertEqual((target / "first").read_bytes(), b"previous")
                self.assertFalse((target / "second").exists())
                (source / "second").write_bytes(b"good")
                module.stage(source, target)
                self.assertEqual((target / "first").read_bytes(), b"good")
                self.assertEqual((target / "second").read_bytes(), b"good")
