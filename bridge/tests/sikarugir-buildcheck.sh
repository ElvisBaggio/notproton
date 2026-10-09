#!/bin/sh
# Gate estático T03; nenhuma compilação ou gravação na árvore Wine.
set -eu
cd "$(dirname "$0")/../.."
python3 - <<'CHECK'
import json
import os
from pathlib import Path
import re
import subprocess
import sys

try:
    root = Path.cwd()
    lock = json.loads(Path(os.environ.get("ENGINE_LOCK", root / "scratch/sikarugir/engine-lock.json")).read_text())
    assert lock["schemaVersion"] == 2, "schemaVersion deve ser 2"
    assert lock["abiCheck"]["status"] == "PASS", "abiCheck.status deve ser PASS"
    mode = lock["provenanceMode"]
    assert mode in ("binary-abi-verified", "maintainer-source"), "proveniência inválida"
    commit = lock["baseSource"]["commit"] if mode == "binary-abi-verified" else lock["sourceCommit"]
    assert re.fullmatch(r"[0-9a-f]{40}", commit), "commit não fixado"
    assert os.environ.get("WINE_COMMIT", commit) == commit, "WINE_COMMIT diverge do lock"
    assert os.environ.get("UNIX_ARCH", "x86_64") == "x86_64", "Rosetta exige x86_64"
    assert os.environ.get("HOST", "x86_64-apple-darwin") == "x86_64-apple-darwin", "HOST diverge de Rosetta"
    src = Path(os.environ.get("WINE_SRC", root / "scratch/sikarugir/wine"))
    head = subprocess.check_output(["git", "-C", str(src), "rev-parse", "HEAD"], text=True).strip()
    assert head == commit, "árvore Wine em commit divergente"
    tag = lock["baseSource"]["tag"] if mode == "binary-abi-verified" else lock.get("sourceTag", commit)
    assert os.environ.get("WINE_TAG", tag) == tag, "WINE_TAG diverge do lock"
    # O shim existente depende destas interfaces; não substituir a base por 11.15.
    assert "AC_DEFUN([WINE_EXTERNAL]" in (src / "aclocal.m4").read_text(), "BLOCKED: Wine fixado não oferece WINE_EXTERNAL exigido pelo shim"
    assert (src / "libs/c++").is_dir(), "BLOCKED: Wine fixado não oferece libc++ PE exigida pelo shim"
    recipe = subprocess.check_output(["make", "-n", "bridge-sikarugir"], text=True)
    assert "arm64" not in recipe and "FEX" not in recipe, "Rosetta não pode construir FEX"
    print("sikarugir-buildcheck: PASS")
except (AssertionError, KeyError, OSError, ValueError, subprocess.CalledProcessError) as exc:
    sys.exit(f"sikarugir-buildcheck: {exc}")
CHECK
