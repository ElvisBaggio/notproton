#!/bin/sh
# Seven T03 gates must reject before any build.
set -eu
cd "$(dirname "$0")/../.."
python3 - <<'CHECK'
from pathlib import Path
import json, os, subprocess, tempfile
lock = json.loads(Path(os.environ.get("ENGINE_LOCK", "scratch/sikarugir/engine-lock.json")).read_text())
variants = [
    ("schemaVersion 1", {"schemaVersion": 1}, {}, "schemaVersion"),
    ("ABI BLOCKED", {"abiCheck": {"status": "BLOCKED"}}, {}, "abiCheck.status"),
    ("commit env divergente", {}, {"WINE_COMMIT": "0" * 40}, "WINE_COMMIT"),
    ("commit árvore divergente", {"baseSource": dict(lock["baseSource"], commit="0" * 40)}, {}, "árvore Wine"),
    ("arm64", {}, {"UNIX_ARCH": "arm64"}, "Rosetta"),
    ("FEX", {}, {"HOST": "aarch64-apple-darwin"}, "HOST"),
    ("Wine 11.15", {}, {"WINE_TAG": "wine-11.15"}, "WINE_TAG"),
]
with tempfile.TemporaryDirectory() as tmp:
    path = Path(tmp) / "engine-lock.json"
    clean = {k: v for k, v in os.environ.items() if k not in ("WINE_COMMIT", "WINE_TAG", "HOST", "UNIX_ARCH")}
    for name, edit, env, want in variants:
        path.write_text(json.dumps(dict(lock, **edit)))
        result = subprocess.run(["sh", "bridge/tests/sikarugir-buildcheck.sh", "--gate"],
            env=dict(clean, ENGINE_LOCK=str(path), **env), text=True, capture_output=True)
        assert result.returncode != 0 and want in result.stderr, (name, result)
        print(name + ": PASS - " + result.stderr.strip())
CHECK
