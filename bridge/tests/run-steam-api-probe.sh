#!/bin/sh
# T05 runner for the Steam API probe.
#
#   run-steam-api-probe.sh --engine <copy> --prefix <scratch dir> --bridge <T03 artifacts> --appid <n> --steam-client <installed Steam Contents/MacOS>
#                          [--probe <exe>] [--loader <rel path>] [--manifest <json>] [--check-only]
#   run-steam-api-probe.sh --verify-output <file> --appid <n>     (parser only, no Wine)
#
# All validation happens before anything is executed. Refuses: missing/duplicate
# arguments, no default AppID, prefix or engine outside <repo>/scratch, an engine
# that is (inside) the original Sikarugir wrapper, bridge files whose hashes differ
# from manifest.json. Output is filtered so only STEAM_INIT/APP_ID/AUTHENTICATED
# lines survive; any SteamID-looking number aborts. Exit 0 only when the probe
# proved init ok, APP_ID == --appid and AUTHENTICATED=yes.
# --steam-client is read-only; exports STEAM_COMPAT_CLIENT_INSTALL_PATH, as the real launcher does.
# --check-only validates and stops (exit 0 = arguments valid, NOT a probe result).
set -eu

if [ "${1:-}" = "--negatives" ]; then # executable negative cases that need no Wine/Steam
    self=$0; n=0; bad=0
    t=$(mktemp -d "${TMPDIR:-/tmp}/t05neg.XXXXXX"); trap 'rm -rf "$t"' EXIT
    d=$(cd "$(dirname "$0")/../.." && pwd -P)/scratch; mkdir -p "$d/t05"
    mkdir -p "$d/t05/neg/engine" "$d/t05/neg/bridge"
    expect_fail() { # name want-rc-nonzero stderr-substring cmd...
        name=$1; sub=$2; shift 2; n=$((n+1)); rc=0
        "$@" >"$t/out" 2>"$t/err" || rc=$?
        if [ "$rc" != 0 ] && grep -q -- "$sub" "$t/err"; then echo "PASS $name (exit $rc)"; else echo "FAIL $name (exit $rc)"; bad=$((bad+1)); fi; }
    E=$d/t05/neg/engine; B=$d/t05/neg/bridge; P=$d/t05/neg/prefix
    expect_fail "prefixo fora de scratch" "fora de scratch" sh "$self" --engine "$E" --prefix "$t/prefix" --bridge "$B" --appid 2316660
    expect_fail "engine = wrapper original" "wrapper original" sh "$self" --engine "$HOME/Applications/Sikarugir/x.app" --prefix "$P" --bridge "$B" --appid 2316660
    expect_fail "AppID ausente" "appid" sh "$self" --engine "$E" --prefix "$P" --bridge "$B"
    expect_fail "AppID zero/invalido" "appid" sh "$self" --engine "$E" --prefix "$P" --bridge "$B" --appid abc
    expect_fail "argumento obrigatorio ausente" "obrigat" sh "$self" --engine "$E" --appid 2316660
    expect_fail "cliente Steam ausente" "--steam-client obrigatório" sh "$self" --engine "$E" --prefix "$P" --bridge "$B" --appid 3527290
    expect_fail "cliente Steam fora da instalação" "Steam instalado" sh "$self" --engine "$E" --prefix "$P" --bridge "$B" --appid 3527290 --steam-client "$B"
    mkdir -p "$P"
    ln -s "$t/outside.log" "$P/probe-raw.log"
    expect_fail "log via symlink fora de scratch" "log fora de scratch" sh "$self" --engine "$E" --prefix "$P" --bridge "$B" --appid 3527290
    printf 'STEAM_INIT=fail\nAPP_ID=0\nAUTHENTICATED=no\n' >"$t/a"
    expect_fail "saida sem Steam (init fail)" "STEAM_INIT" sh "$self" --verify-output "$t/a" --appid 2316660
    printf 'STEAM_INIT=ok\nAPP_ID=480\nAUTHENTICATED=yes\n' >"$t/b"
    expect_fail "AppID diferente" "APP_ID" sh "$self" --verify-output "$t/b" --appid 2316660
    printf 'STEAM_INIT=ok\nAPP_ID=2316660\nAUTHENTICATED=no\n' >"$t/c"
    expect_fail "nao autenticado" "AUTHENTICATED" sh "$self" --verify-output "$t/c" --appid 2316660
    printf 'STEAM_INIT=ok\nAPP_ID=2316660\nAUTHENTICATED=yes\nSTEAMID=76561190000000000\n' >"$t/d"
    expect_fail "identificador de usuario na saida" "identificador" sh "$self" --verify-output "$t/d" --appid 2316660
    printf '' >"$t/e"
    expect_fail "saida vazia" "esperado" sh "$self" --verify-output "$t/e" --appid 2316660
    printf 'STEAM_INIT=ok\nAPP_ID=2316660\nAUTHENTICATED=yes\n' >"$t/ok"
    n=$((n+1)); if sh "$self" --verify-output "$t/ok" --appid 2316660 >/dev/null 2>&1; then echo "PASS controle positivo do parser"; else echo "FAIL controle positivo do parser"; bad=$((bad+1)); fi
    rm -rf "$d/t05/neg"; echo "negativos: $((n-bad))/$n"; [ "$bad" = 0 ]; exit $?
fi

repo=$(cd "$(dirname "$0")/../.." && pwd -P)
scratch_root=${SCRATCH_ROOT:-$repo/scratch}

die() { echo "recusado: $*" >&2; exit 2; }

steam_client= engine= prefix= bridge= appid= probe= loader= manifest= verify= check_only=0
while [ $# -gt 0 ]; do
    case $1 in
        --check-only) check_only=1; shift; continue ;;
        --steam-client|--engine|--prefix|--bridge|--appid|--probe|--loader|--manifest|--verify-output) ;;
        *) die "argumento desconhecido: $1" ;;
    esac
    [ $# -ge 2 ] || die "$1 exige valor"
    case $1 in
        --steam-client) steam_client=$2 ;; --engine) engine=$2 ;; --prefix) prefix=$2 ;; --bridge) bridge=$2 ;;
        --appid) appid=$2 ;; --probe) probe=$2 ;; --loader) loader=$2 ;;
        --manifest) manifest=$2 ;; --verify-output) verify=$2 ;;
    esac
    shift 2
done

case $appid in ''|*[!0-9]*|0*) die "--appid obrigatório (inteiro positivo, sem default)" ;; esac

# Accept exactly the three lines the probe prints; fail on anything else.
verify_output() { # $1 = file
    python3 - "$1" "$appid" <<'PY'
import re, sys
lines = [l.rstrip("\n") for l in open(sys.argv[1], errors="replace") if l.strip()]
want = {"STEAM_INIT": "ok", "APP_ID": sys.argv[2], "AUTHENTICATED": "yes"}
seen = {}
for l in lines:
    if re.search(r"7656119\d{10}", l):
        print("recusado: saída contém identificador de usuário", file=sys.stderr); sys.exit(3)
    m = re.fullmatch(r"(STEAM_INIT|APP_ID|AUTHENTICATED)=(\S+)", l)
    if not m or m.group(1) in seen:
        print("falha: linha inesperada ou repetida na saída do probe", file=sys.stderr); sys.exit(1)
    seen[m.group(1)] = m.group(2)
for k, v in want.items():
    if seen.get(k) != v:
        print(f"falha: {k}={seen.get(k)!r}, esperado {v!r}", file=sys.stderr); sys.exit(1)
print("probe: todas as provas conferem")
PY
}

if [ -n "$verify" ]; then
    [ -f "$verify" ] || die "arquivo de saída inexistente"
    verify_output "$verify"
    exit $?
fi

[ -n "$engine" ] && [ -n "$prefix" ] && [ -n "$bridge" ] || die "--engine, --prefix e --bridge são obrigatórios"

realp() { python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"; }
root=$(realp "$scratch_root")
under_scratch() { case $1 in "$root"/*) return 0 ;; *) return 1 ;; esac; }

prefix_r=$(realp "$prefix"); engine_r=$(realp "$engine"); bridge_r=$(realp "$bridge")
home_r=$(realp "$HOME")
case $engine_r in
    "$home_r"/Applications/Sikarugir*|/Applications/Sikarugir*|*.app|*.app/*) die "engine é (ou está dentro de) o wrapper original: $engine" ;;
esac
under_scratch "$prefix_r" || die "prefixo fora de scratch/: $prefix"
under_scratch "$engine_r" || die "engine deve ser uma cópia em scratch/: $engine"
under_scratch "$bridge_r" || die "bridge deve estar em scratch/: $bridge"

[ -d "$engine_r" ] || die "engine inexistente"
[ -d "$bridge_r" ] || die "bridge inexistente"

for log in probe-raw.log probe-filtered.txt; do
    under_scratch "$(realp "$prefix_r/$log")" || die "log fora de scratch/: $log"
done

[ -n "$steam_client" ] || die "--steam-client obrigatório (Steam instalado, somente leitura)"
steam_client_r=$(realp "$steam_client")
[ "$steam_client_r" = "$(realp "$HOME/Library/Application Support/Steam/Steam.AppBundle/Steam/Contents/MacOS")" ] || die "--steam-client deve apontar ao Steam instalado"
[ -r "$steam_client_r/steamclient.dylib" ] || die "steamclient.dylib inexistente ou ilegível"

# Bridge hashes against the T03 manifest ({"files": {relpath: sha256}}).
[ -n "$manifest" ] || { [ -f "$bridge_r/manifest.json" ] && manifest=$bridge_r/manifest.json; } || true
if [ -n "$manifest" ]; then
    [ -f "$manifest" ] || die "manifesto inexistente: $manifest"
    python3 - "$bridge_r" "$manifest" <<'PY' || die "hash da bridge diverge do manifesto"
import hashlib, json, sys, pathlib
root = pathlib.Path(sys.argv[1]); files = json.load(open(sys.argv[2]))["files"]
bad = [n for n, h in files.items() if not (root / n).is_file() or hashlib.sha256((root / n).read_bytes()).hexdigest() != h]
if bad or not files:
    print("divergem/ausentes:", ", ".join(bad) or "manifesto vazio", file=sys.stderr); sys.exit(1)
PY
else
    echo "aviso: sem manifest.json; hashes da bridge NÃO conferidos" >&2
fi

if [ -z "$loader" ]; then
    lock=$scratch_root/sikarugir/engine-lock.json
    [ -f "$lock" ] && loader=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["loaderRelativePath"])' "$lock") || true
fi
[ -n "$loader" ] || die "--loader ausente e engine-lock.json sem loaderRelativePath"
[ -x "$engine_r/$loader" ] || die "loader não executável na cópia da engine: $loader"
[ -n "$probe" ] || probe=$scratch_root/t05/steam-api-probe.exe
[ -f "$probe" ] || die "probe não compilado: $probe"

if [ "$check_only" = 1 ]; then echo "check-only: argumentos válidos (não é resultado do probe)"; exit 0; fi

mkdir -p "$prefix_r"
unset WINESERVER WINELOADER WINELOADERNOEXEC
raw=$prefix_r/probe-raw.log     # raw log stays in scratch, never printed
out=$prefix_r/probe-filtered.txt
rc=0
# Clear launcher paths inherited from the caller; all runtime lookup uses the copy.
for name in $(env | sed -En 's/^(DYLD_[A-Za-z0-9_]*|WINEDLLPATH[A-Za-z0-9_]*|CX_[A-Za-z0-9_]*)=.*/\1/p'); do unset "$name"; done
WINEPREFIX=$prefix_r WINEARCH=win64 WINEDEBUG=${WINEDEBUG:--all} SteamAppId=$appid SteamGameId=$appid \
    STEAM_COMPAT_CLIENT_INSTALL_PATH="$steam_client_r" \
    WINEPATH="C:\\Program Files (x86)\\Steam" WINEDLLOVERRIDES="steamclient64=n;lsteamclient=b" \
    arch -x86_64 /usr/bin/env DYLD_FALLBACK_LIBRARY_PATH="$engine_r/Frameworks:/usr/lib" SikarugirAppWine11=1 "$engine_r/$loader" "$probe" --appid "$appid" >"$raw" 2>&1 || rc=$?
tr -d '\r' <"$raw" | grep -E '^(STEAM_INIT|APP_ID|AUTHENTICATED)=[A-Za-z0-9]{1,10}$' >"$out" || true
cat "$out"
verify_output "$out" || exit 1
[ "$rc" = 0 ] || { echo "falha: probe saiu com $rc" >&2; exit 1; }
