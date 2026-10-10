#!/bin/sh
set -eu
SRC="${1:-$(dirname "$0")/../feats/compat_run.sh}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/tool" "$tmp/home"
printf '%s\n' sikarugir-11.0-r0 > "$tmp/tool/build"
# Execute the actual launcher setup without launching Wine.
sed -n '/^np_support=/,/^if \[ -n "$STEAM_COMPAT_DATA_PATH" \]; then/{ /^if \[ -n "$STEAM_COMPAT_DATA_PATH" \]; then/d; p; }' "$SRC" > "$tmp/setup"
cp "$tmp/setup" "$tmp/tool/run"
HOME="$tmp/home"; STEAM_COMPAT_DATA_PATH="$tmp/prefix"; export HOME STEAM_COMPAT_DATA_PATH
CX_ROOT=/foreign CX_HOME=/foreign CX_BAD=bad DYLD_LIBRARY_PATH=/foreign WINEDLLPATH=/foreign WINEDLLPATH_PREPEND=/foreign WINELOADER=/foreign WINESERVER=/foreign WINEPATH=/foreign WINEDLLOVERRIDES=bad; export CX_ROOT CX_HOME CX_BAD DYLD_LIBRARY_PATH WINEDLLPATH WINEDLLPATH_PREPEND WINELOADER WINESERVER WINEPATH WINEDLLOVERRIDES
# $0 must refer to the tool, as it does under Steam.
cat >> "$tmp/tool/run" <<'CHECK'
[ "${np_origin:-}" = sikarugir ]
[ -z "${CX_ROOT:-}${CX_HOME:-}${CX_BAD:-}${DYLD_LIBRARY_PATH:-}${WINEDLLPATH_PREPEND:-}" ]
[ "$WINELOADER" = "$HOME/Library/Application Support/notproton/runners/sikarugir-11.0-r0/wine/bin/wine" ]
[ "$WINESERVER" = "${WINELOADER%/wine}/wineserver" ]
[ "$WINEARCH" = win64 ]
[ "$SikarugirAppWine11" = 1 ]
[ "$WINEDLLPATH" = "$np_runner/Frameworks/renderer/d3dmetal/wine" ]
[ "$CX_APPLEGPTK_LIBD3DSHARED_PATH" = "$np_runner/Frameworks/renderer/d3dmetal/external/libd3dshared.dylib" ]
[ -z "${WINEPATH:-}${WINEDLLOVERRIDES:-}" ]
CHECK
sh "$tmp/tool/run"
echo 'sikarugircheck: launcher isolation/layout PASS'

# verify_runner: the missing-bridge ntdll notice is CrossOver noise, not a Sikarugir one.
sed -n '/^verify_runner() {/,/^}/p' "$SRC" > "$tmp/verify.sh"
[ -s "$tmp/verify.sh" ] || { echo 'FAIL: verify_runner not found'; exit 1; }
mkdir -p "$tmp/vr/bridge" "$tmp/vr/runner/lib/wine/x86_64-windows" "$tmp/vr/runner/lib/wine/x86_64-unix"
for origin in sikarugir crossover; do
  : > "$tmp/vr/log-$origin"
  (
    . "$tmp/verify.sh"
    bridge_src="$tmp/vr/bridge" np_build=test np_origin=$origin np_runner="$tmp/vr/runner"
    wine_unix="$tmp/vr/runner/lib/wine/x86_64-unix" log="$tmp/vr/log-$origin"
    verify_runner
  )
done
if grep -q 'no patched ntdll' "$tmp/vr/log-sikarugir"; then echo 'FAIL: Sikarugir logged the bridge ntdll notice'; exit 1; fi
grep -q 'no patched ntdll' "$tmp/vr/log-crossover" || { echo 'FAIL: CrossOver lost the bridge ntdll notice'; exit 1; }
grep -q 'missing x86_64-windows/lsteamclient.dll' "$tmp/vr/log-sikarugir" || { echo 'FAIL: Sikarugir builtin check is gone'; exit 1; }
if grep -q 'i386-windows' "$tmp/vr/log-sikarugir"; then echo 'FAIL: Sikarugir expects an i386 bridge'; exit 1; fi
echo 'sikarugircheck: verify_runner origin notice PASS'
