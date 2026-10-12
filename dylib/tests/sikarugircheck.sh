#!/bin/sh
set -eu
SRC="${1:-$(dirname "$0")/../feats/compat_run.sh}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/tool" "$tmp/home"
printf '%s\n' sikarugir-11.0-r0 > "$tmp/tool/build"
# Execute the actual launcher setup without launching Wine.
# shellcheck disable=SC2016 # the $ in the sed script matches a literal $ in compat_run.sh
sed -n '/^np_support=/,/^if \[ -n "$STEAM_COMPAT_DATA_PATH" \]; then/{ /^if \[ -n "$STEAM_COMPAT_DATA_PATH" \]; then/d; p; }' "$SRC" > "$tmp/setup"
cp "$tmp/setup" "$tmp/tool/run"
HOME="$tmp/home"; STEAM_COMPAT_DATA_PATH="$tmp/prefix"; export HOME STEAM_COMPAT_DATA_PATH
CX_ROOT=/foreign CX_HOME=/foreign CX_BAD=bad DYLD_LIBRARY_PATH=/foreign WINEDLLPATH=/foreign WINEDLLPATH_PREPEND=/foreign WINELOADER=/foreign WINESERVER=/foreign WINEPATH=/foreign WINEDLLOVERRIDES=bad; export CX_ROOT CX_HOME CX_BAD DYLD_LIBRARY_PATH WINEDLLPATH WINEDLLPATH_PREPEND WINELOADER WINESERVER WINEPATH WINEDLLOVERRIDES
# $0 must refer to the tool, as it does under Steam.
cat >> "$tmp/tool/run" <<'CHECK'
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

# verify_runner: a Sikarugir clone is patched in place, so there is no bridge/wine/<build> notice.
sed -n '/^verify_runner() {/,/^}/p' "$SRC" > "$tmp/verify.sh"
[ -s "$tmp/verify.sh" ] || { echo 'FAIL: verify_runner not found'; exit 1; }
mkdir -p "$tmp/vr/bridge" "$tmp/vr/runner/lib/wine/x86_64-windows" "$tmp/vr/runner/lib/wine/x86_64-unix" "$tmp/vr/runner/lib/wine/i386-windows"
: > "$tmp/vr/log"
# shellcheck disable=SC1091,SC2034 # verify.sh is generated above and reads these variables
(
  . "$tmp/verify.sh"
  bridge_src="$tmp/vr/bridge" np_build=test np_runner="$tmp/vr/runner"
  wine_unix="$tmp/vr/runner/lib/wine/x86_64-unix" log="$tmp/vr/log"
  verify_runner
)
if grep -q 'no patched ntdll' "$tmp/vr/log"; then echo 'FAIL: the bridge ntdll notice came back'; exit 1; fi
grep -q 'missing x86_64-windows/lsteamclient.dll' "$tmp/vr/log" || { echo 'FAIL: the builtin check is gone'; exit 1; }
grep -q 'missing i386-windows/lsteamclient.dll' "$tmp/vr/log" || { echo 'FAIL: the i386 builtin check is gone'; exit 1; }
echo 'sikarugircheck: verify_runner PASS'

# place_wow64_lsteamclient: a prefix older than the i386 builtin gets its syswow64 file.
sed -n '/^replace_file() {/,/^}/p; /^place_wow64_lsteamclient() {/,/^}/p' "$SRC" > "$tmp/wow.sh"
[ -s "$tmp/wow.sh" ] || { echo 'FAIL: place_wow64_lsteamclient not found'; exit 1; }
mkdir -p "$tmp/wow/runner/lib/wine/i386-windows" "$tmp/wow/pfx/drive_c/windows/syswow64"
printf 'i386 builtin\n' > "$tmp/wow/runner/lib/wine/i386-windows/lsteamclient.dll"
: > "$tmp/wow/log"
# shellcheck disable=SC1091,SC2034 # wow.sh is generated above and reads these variables
(
  . "$tmp/wow.sh"
  np_runner="$tmp/wow/runner" WINEPREFIX="$tmp/wow/pfx" log="$tmp/wow/log"
  place_wow64_lsteamclient
  place_wow64_lsteamclient
)
cmp -s "$tmp/wow/runner/lib/wine/i386-windows/lsteamclient.dll" "$tmp/wow/pfx/drive_c/windows/syswow64/lsteamclient.dll" \
  || { echo 'FAIL: syswow64/lsteamclient.dll was not placed'; exit 1; }
[ "$(grep -c 'placed syswow64' "$tmp/wow/log")" = 1 ] || { echo 'FAIL: syswow64 copy is not idempotent'; exit 1; }
echo 'sikarugircheck: wow64 lsteamclient PASS'

# install_legacycompat: the Mac client folder gets the evaluator Steam runs installscript.vdf with.
sed -n '/^replace_file() {/,/^}/p; /^install_legacycompat() {/,/^}/p' "$SRC" > "$tmp/lc.sh"
[ -s "$tmp/lc.sh" ] || { echo 'FAIL: install_legacycompat not found'; exit 1; }
mkdir -p "$tmp/lc/bridge/legacycompat" "$tmp/lc/client"
printf 'evaluator\n' > "$tmp/lc/bridge/legacycompat/iscriptevaluator.exe"
: > "$tmp/lc/log"
# shellcheck disable=SC1091,SC2034 # lc.sh is generated above and reads these variables
(
  . "$tmp/lc.sh"
  bridge_src="$tmp/lc/bridge" STEAM_COMPAT_CLIENT_INSTALL_PATH="$tmp/lc/client" log="$tmp/lc/log"
  install_legacycompat
  install_legacycompat
)
cmp -s "$tmp/lc/bridge/legacycompat/iscriptevaluator.exe" "$tmp/lc/client/legacycompat/iscriptevaluator.exe" \
  || { echo 'FAIL: iscriptevaluator.exe was not installed'; exit 1; }
[ "$(grep -c 'installed legacycompat' "$tmp/lc/log")" = 1 ] || { echo 'FAIL: legacycompat copy is not idempotent'; exit 1; }
(
  . "$tmp/lc.sh"
  bridge_src="$tmp/lc/bridge" STEAM_COMPAT_CLIENT_INSTALL_PATH="$tmp/lc/missing" log="$tmp/lc/log"
  install_legacycompat
)
[ ! -e "$tmp/lc/missing" ] || { echo 'FAIL: legacycompat made up a client folder'; exit 1; }
echo 'sikarugircheck: legacycompat PASS'
