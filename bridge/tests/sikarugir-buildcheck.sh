#!/bin/sh
# Gate estático T03; nenhuma compilação ou gravação na árvore Wine.
set -eu
cd "$(dirname "$0")/../.."
python3 - "${1:---artifacts}" <<'CHECK'
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
    assert tag == "wine-11.0", "base deve ser wine-11.0"
    assert commit == "db11d0fe6a169c457e23d007e20404643d067aa8", "base 11.0 não verificada"
    scratch = (root / "scratch").resolve()
    for path in (src, Path(os.environ.get("WINE_BUILD", root / "scratch/sikarugir/wine-build"))):
        assert path.resolve().is_relative_to(scratch), "build exige cópia privada em scratch deste worktree"
    assert (src / ".git").is_dir(), "fonte deve ter metadados git próprios"
    assert (src / ".git").resolve().is_relative_to(scratch), "metadados git devem ser privados"
    changes = subprocess.check_output(["git", "-C", str(src), "diff", "--name-only", "HEAD"], text=True).splitlines()
    assert set(changes) <= {"configure", "configure.ac"}, "fonte Wine alterada além do registro"
    assert "WINE_CONFIG_MAKEFILE(programs/steam.exe)" not in (src / "configure.ac").read_text(), "shim não pode ser registrado no Wine"
    recipe = subprocess.check_output(["make", "-n", "bridge-sikarugir"], text=True)
    assert "build-sikarugir.sh" in recipe, "receita Sikarugir ausente"
    assert "arm64" not in recipe and "FEX" not in recipe, "Rosetta não pode construir FEX"
    assert sys.argv[1] in ("--gate", "--artifacts"), "use --gate ou --artifacts"
    if sys.argv[1] == "--artifacts":
        assert os.environ.get("LLVM_MINGW"), "defina LLVM_MINGW com a toolchain local do T01"
        tc = Path(os.environ["LLVM_MINGW"]) / "bin"
        bridge = root / "scratch/sikarugir/bridge"
        pe_paths = [bridge / "steam.exe", bridge / "x86_64-windows/lsteamclient.dll"]
        for pe in pe_paths:
            output = subprocess.check_output([str(tc / "llvm-objdump"), "-p", str(pe)], text=True)
            assert "file format coff-x86-64" in output, f"PE não x86_64: {pe}"
            imports = re.findall(r"DLL Name: (\S+)", output)
            assert imports, f"imports ausentes: {pe}"
            if pe.name == "steam.exe":
                allowed = {"kernel32.dll", "ntdll.dll", "user32.dll", "advapi32.dll", "shlwapi.dll", "shell32.dll", "msi.dll"}
                assert all(dll.lower() in allowed or dll.lower().startswith("api-ms-win-crt-") for dll in imports), f"import não Win32/runtime C++ dinâmica: {imports}"
                assert not re.search(r"^\s+\d+\s+(?:__wine|wine_)", output, re.M), "símbolo Wine exclusivo nos imports"
            print(f"{pe.name} imports: {', '.join(imports)}")
        so = bridge / "x86_64-unix/lsteamclient.so"
        assert subprocess.check_output(["lipo", "-archs", str(so)], text=True).strip() == "x86_64", "Unix não x86_64"
        deps = subprocess.check_output(["otool", "-L", str(so)], text=True)
        rpaths = subprocess.check_output(["otool", "-l", str(so)], text=True)
        assert "@rpath/ntdll.so" in deps and "path @loader_path/ " in rpaths, "ntdll deve resolver ao lado da ponte na cópia da engine"
        libraries = "\n".join(deps.splitlines()[1:])
        assert "CrossOver" not in libraries and "/scratch/" not in libraries, "dependência de build/CrossOver"
        assert not list(bridge.rglob("ntdll.*")), "não distribuir ntdll upstream"
        symbols = subprocess.check_output(["nm", "-gU", str(so)], text=True)
        assert "___wine_unix_call_funcs" in symbols, "tabela Unix ausente"
        assert (bridge / "lsteamclient.dll").read_bytes() == pe_paths[1].read_bytes(), "cópia PE flat diverge"
        pe32 = bridge / "i386-windows/lsteamclient.dll"
        output = subprocess.check_output([str(tc / "llvm-objdump"), "-p", str(pe32)], text=True)
        assert "file format coff-i386" in output, f"PE não i386: {pe32}"
        imports32 = sorted(re.findall(r"DLL Name: (\S+)", output))
        imports64 = sorted(re.findall(r"DLL Name: (\S+)", subprocess.check_output([str(tc / "llvm-objdump"), "-p", str(pe_paths[1])], text=True)))
        assert imports32 == imports64, f"imports i386 divergem do x86_64: {imports32}"
        assert "___wine_unix_call_wow64_funcs" in symbols, "lsteamclient.so sem thunks wow64 para o PE i386"
        print(f"{pe32.name} (i386) imports: {', '.join(imports32)}")
    print("sikarugir-buildcheck: PASS")
except (AssertionError, KeyError, OSError, ValueError, subprocess.CalledProcessError) as exc:
    sys.exit(f"sikarugir-buildcheck: {exc}")
CHECK
