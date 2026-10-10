#!/usr/bin/env python3
"""Stage the verified T03 bridge into the ignored app payload."""
import hashlib
import pathlib
import shutil
import sys

FILES = {
    "steam.exe": "56979db411cb12b48610c09b8fc01db3c34bb3c7e31ea53f1b17dafaf7f98b70",
    "x86_64-windows/lsteamclient.dll": "2933ac86d886f1264fabfbb97f21f53967452fca2397f29ecdbd29f83616c7ac",
    "x86_64-unix/lsteamclient.so": "d71f954cf1c1a2355e9dfd7e8de593d8a4d1274117d42626394d4e95c7379a9c",
}

def stage(source, destination):
    # Verify every input before writing any app resource.
    for name, expected in FILES.items():
        if hashlib.sha256((source / name).read_bytes()).hexdigest() != expected:
            raise ValueError(f"unknown Sikarugir bridge: {name}")
    for name in FILES:
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source / name, target)

if __name__ == "__main__":
    stage(pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]))
