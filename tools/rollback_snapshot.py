"""Rollback snapshot (T10): hash/mode/link of every deploy target, optional APFS-clone backup.

usage: python3 -I tools/rollback_snapshot.py <out.json> [--backup <dir>] [--games]

--games also covers steamapps/compatdata/* and appmanifest_*.acf (recovery.md, step 3a).
"""
import glob, hashlib, json, os, subprocess, sys, time

HOME = os.path.expanduser("~")
AS = f"{HOME}/Library/Application Support"
INNER = f"{AS}/Steam/Steam.AppBundle/Steam"
TARGETS = [
    "/Applications/Steam.app",
    f"{INNER}/Contents/Info.plist",
    f"{INNER}/Contents/MacOS/steam.cfg",
    f"{AS}/Steam/steam.cfg",
    f"{AS}/Steam/compatibilitytools.d/notproton-sikarugir-11.0-r0",
    f"{AS}/Steam/config/config.vdf",
    f"{AS}/notproton/install-build.json",
    f"{AS}/notproton/dylib.version",
    f"{AS}/notproton/tools",
    f"{AS}/notproton/backups/Info.plist.before-notproton",
]


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def entry(path):
    if not os.path.lexists(path):
        return {"path": path, "existed": False}
    st = os.lstat(path)
    e = {"path": path, "existed": True, "mode": oct(st.st_mode & 0o7777)}
    if os.path.islink(path):
        e["symlinkTarget"] = os.readlink(path)
    elif os.path.isdir(path):
        # Directory digest: sorted (relpath, kind, sha/link) of every entry.
        h = hashlib.sha256()
        n = 0
        for root, dirs, files in os.walk(path):
            dirs.sort()
            for name in sorted(files) + [d for d in dirs if os.path.islink(os.path.join(root, d))]:
                p = os.path.join(root, name)
                rel = os.path.relpath(p, path)
                v = "L:" + os.readlink(p) if os.path.islink(p) else sha(p)
                h.update(f"{rel}\0{v}\n".encode())
                n += 1
        e.update(kind="dir", treeSha256=h.hexdigest(), files=n)
    else:
        e.update(kind="file", sha256=sha(path))
    return e


def main():
    out = sys.argv[1]
    backup = sys.argv[sys.argv.index("--backup") + 1] if "--backup" in sys.argv else None
    targets = list(TARGETS)
    if "--games" in sys.argv:
        # ponytail: default library only; add other libraryfolders.vdf paths if games live elsewhere.
        apps = f"{AS}/Steam/steamapps"
        targets += sorted(glob.glob(f"{apps}/compatdata/*")) + sorted(glob.glob(f"{apps}/appmanifest_*.acf"))
    files = []
    for t in targets:
        e = entry(t)
        if backup and e["existed"]:
            dst = os.path.join(backup, t.lstrip("/"))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            # -c: APFS clone (independent copy-on-write, not a hard link); -P: keep symlinks.
            subprocess.run(["/bin/cp", "-Rc", "-P", "-p", t, dst], check=True)
            b = entry(dst)
            same = b.get("sha256") == e.get("sha256") and b.get("treeSha256") == e.get("treeSha256")
            if not same or (e.get("kind") == "file" and os.stat(dst).st_ino == os.stat(t).st_ino):
                sys.exit(f"backup mismatch: {t}")
            e["backupPath"] = dst
        files.append(e)
    steam = subprocess.run(["/usr/bin/codesign", "-dvv", "/Applications/Steam.app"], capture_output=True, text=True).stderr
    manifest = {
        "schemaVersion": 1,
        "takenAt": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "steamClientBuild": next((l.split('"')[3] for l in open(f"{INNER}/Contents/MacOS/package/steam_client_publicbeta_signed-2_osx.manifest") if '"version"' in l), None),
        "outerSignature": [l for l in steam.splitlines() if l.startswith(("Signature", "TeamIdentifier", "Identifier", "Authority"))],
        "diskFreeBytes": os.statvfs(HOME).f_bavail * os.statvfs(HOME).f_frsize,
        "touchedFiles": files,
    }
    with open(out, "w") as f:
        json.dump(manifest, f, indent=1)
    os.chmod(out, 0o600)
    for e in files:
        print(("OK " if e["existed"] else "-- ") + e["path"].replace(HOME, "~"), e.get("sha256", e.get("treeSha256", ""))[:12])


if __name__ == "__main__":
    main()
