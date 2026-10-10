#!/bin/sh
# T03 builds only; never install or run Wine here.
set -eu
repo="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo"
export SIKARUGIR=1
export WINE_SRC="${WINE_SRC:-$repo/scratch/sikarugir/wine}"
export WINE_BUILD="${WINE_BUILD:-$repo/scratch/sikarugir/wine-build}"
export BRIDGE_DIR="$repo/scratch/sikarugir/bridge"
export TREE="$repo/scratch/sikarugir/lsteamclient"
export SHIM_HEADERS="$repo/scratch/sikarugir/shim-headers"
export LLVM_MINGW="${LLVM_MINGW:?Set LLVM_MINGW to the local T01 toolchain}"
export PATH="$LLVM_MINGW/bin:$PATH"
export MACOSX_DEPLOYMENT_TARGET=14.0
export SOURCE_DATE_EPOCH=1767916800
export WINE_TAG="${WINE_TAG:-wine-11.0}"
export WINE_COMMIT="${WINE_COMMIT:-db11d0fe6a169c457e23d007e20404643d067aa8}"
export HOST="${HOST:-x86_64-apple-darwin}" UNIX_ARCH="${UNIX_ARCH:-x86_64}"
export HOST_CC='/usr/bin/clang -arch x86_64' HOST_CXX='/usr/bin/clang++ -arch x86_64'
export CFLAGS=-O2
export CONFIGURE_OPTS="--disable-tests --disable-winebth_sys --enable-archs=x86_64 --with-mingw=$LLVM_MINGW/bin/clang --without-x --without-freetype --without-wayland --without-fontconfig --without-dbus --without-gstreamer --without-sdl --without-pulse --without-alsa --without-oss --without-usb --without-v4l2 --without-krb5 --without-gssapi --without-netapi --without-capi --without-cups --without-pcap --without-pcsclite --without-gphoto --without-sane --without-inotify --without-udev --without-gettextpo --without-gnutls --without-opencl --without-vulkan --without-opengl --without-ffmpeg"
sh bridge/tests/sikarugir-buildcheck.sh --gate
# Source must already be the private, pinned copy verified by the gate.
bridge/setup-wine-tree.sh
export WINE_SRC_REL="$WINE_SRC"
lsteamclient/build.sh
mkdir -p "$BRIDGE_DIR/x86_64-unix" "$BRIDGE_DIR/x86_64-windows"
cp "$WINE_BUILD/dlls/lsteamclient/lsteamclient.so" "$BRIDGE_DIR/x86_64-unix/"
cp "$WINE_BUILD/dlls/lsteamclient/x86_64-windows/lsteamclient.dll" "$BRIDGE_DIR/x86_64-windows/"
"$LLVM_MINGW/bin/llvm-strip" --strip-all "$BRIDGE_DIR/x86_64-windows/lsteamclient.dll"
cp "$BRIDGE_DIR/x86_64-windows/lsteamclient.dll" "$BRIDGE_DIR/lsteamclient.dll"
steam-shim/build.sh
sh bridge/tests/sikarugir-buildcheck.sh --artifacts
python3 - <<'MANIFEST'
import hashlib, json, os
from pathlib import Path
root = Path(os.environ["BRIDGE_DIR"])
files = ["steam.exe", "x86_64-windows/lsteamclient.dll", "x86_64-unix/lsteamclient.so"]
manifest = {"wineCommit": os.environ["WINE_COMMIT"],
    "architecture": "x86_64", "files": {name: hashlib.sha256((root / name).read_bytes()).hexdigest() for name in files}}
(root / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(json.dumps(manifest, indent=2))
MANIFEST
