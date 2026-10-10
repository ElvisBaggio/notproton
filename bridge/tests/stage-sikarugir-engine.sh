#!/bin/sh
# T05: fixed local inputs, APFS clones only; never execute the installed engine.
set -eu
cd "$(dirname "$0")/../.."
exec python3 - <<'PYTHON'
import hashlib, json, os, pathlib, subprocess
repo = pathlib.Path.cwd().resolve()
work = repo / 'scratch/t05'
engine = work / 'engine'
prefix = work / 'pfx'
source = pathlib.Path('/Users/elvisoliveira/Applications/Sikarugir/wrapper-steam.app/Contents/SharedSupport/wine')
frameworks = source.parents[1] / 'Frameworks'
t04 = pathlib.Path('/Users/elvisoliveira/_dev/notproton/scratch/worktrees/t04-close/scratch/sikarugir')
t03 = pathlib.Path('/Users/elvisoliveira/_dev/notproton/scratch/worktrees/t03-bridge/scratch/sikarugir/bridge')
trigger = pathlib.Path('/Users/elvisoliveira/Library/Application Support/NotProton/bridge/steamclient64.dll')
probe = pathlib.Path('/Users/elvisoliveira/_dev/notproton/.claude/worktrees/agent-ac600443865a90b9e/scratch/t05/steam-api-probe.exe')
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def clone(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['cp', '-c', '-R', str(src), str(dst)], check=True)
    assert digest(src) == digest(dst), str(dst)
    assert (src.stat().st_dev, src.stat().st_ino) != (dst.stat().st_dev, dst.stat().st_ino), 'hard link: '+str(dst)
assert not engine.exists() and not prefix.exists() and not (work/'bridge').exists(), 'refusing existing engine/prefix/bridge'
assert work.resolve() == repo/'scratch/t05', 'scratch path must not traverse symlinks'
work.mkdir(parents=True, exist_ok=True)
keys = ['bin/wine', 'bin/wineserver', 'lib/wine/x86_64-unix/ntdll.so', 'lib/wine/x86_64-windows/ntdll.dll', 'lib/wine/i386-windows/ntdll.dll']
def tree(root):
    result = {}
    for p in sorted(root.rglob('*')):
        if p.is_symlink():
            assert p.resolve().is_relative_to(root.resolve()), 'external Frameworks symlink: '+str(p)
            result[str(p.relative_to(root))] = {'symlink': os.readlink(p)}
        elif p.is_file(): result[str(p.relative_to(root))] = digest(p)
    return result
before = {n: digest(source/n) for n in keys}
frameworks_before = tree(frameworks)
(work/'wrapper-before.json').write_text(json.dumps(before, indent=2)+'\n')
patches = json.loads((t04/'patches.json').read_text())
assert patches['status'] == 'COMPLETE'
assert {e['architecture'] for e in patches['entries']} == {'x86_64-windows','i386-windows'}
assert len(patches['entries']) == 2
bridge = json.loads((t03/'manifest.json').read_text())
assert set(bridge['files']) == {'steam.exe','x86_64-windows/lsteamclient.dll','x86_64-unix/lsteamclient.so'}
for n, h in bridge['files'].items(): assert digest(t03/n) == h, n
assert digest(trigger) == 'caba4826aa3501039d095aee1843a6bfb270fb43a3ab4455b2d6733223579fee'
assert digest(probe) == 'fd956173ccfb93c2bd2d656895b73f15e0bcaab708ce7f7cb8120a571f8657bc'
subprocess.run(['cp', '-c', '-R', str(source), str(engine)], check=True)
subprocess.run(['cp', '-c', '-R', str(frameworks), str(engine/'Frameworks')], check=True)
assert tree(engine/'Frameworks') == frameworks_before
for p in frameworks.rglob('*'):
    if p.is_file() and not p.is_symlink():
        q = engine/'Frameworks'/p.relative_to(frameworks)
        assert (p.stat().st_dev,p.stat().st_ino) != (q.stat().st_dev,q.stat().st_ino), 'hard link: '+str(q)
placed = {}
for e in patches['entries']:
    n = 'lib/wine/'+e['architecture']+'/ntdll.dll'
    dst = engine/n
    assert digest(dst) == e['cleanHash']
    src = t04/'patched'/e['architecture']/'ntdll.dll'
    assert digest(src) == e['patchedHash']
    clone(src, dst)
    placed[str(dst.relative_to(work))] = digest(dst)
for n in bridge['files']:
    clone(t03/n, work/'bridge'/n)
    placed['bridge/'+n] = digest(work/'bridge'/n)
    if n != 'steam.exe':
        dst = engine/'lib/wine'/n
        clone(t03/n, dst)
        placed[str(dst.relative_to(work))] = digest(dst)
clone(t03/'manifest.json', work/'bridge/manifest.json')
placed['bridge/manifest.json'] = digest(work/'bridge/manifest.json')
clone(probe, work/'steam-api-probe.exe')
assert digest(engine/keys[2]) == before[keys[2]], 'Unix ntdll must stay original'
manifest = {'client':'codex', 'model':'gpt-6.1-sol', 'wrapperBefore':before, 'frameworksBefore':frameworks_before, 'files':placed, 'status':'ENGINE_STAGED'}
def save():
    after = {n:digest(source/n) for n in keys}
    assert after == before, 'wrapper changed'
    manifest['wrapperAfter'] = after
    manifest['frameworksAfter'] = tree(frameworks)
    assert manifest['frameworksAfter'] == frameworks_before, 'original Frameworks changed'
    assert tree(engine/'Frameworks') == frameworks_before, 'copied Frameworks changed'
    (work/'stage-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
save()
steam = prefix/'drive_c/Program Files (x86)/Steam'
for src, name in [(t03/'steam.exe','steam.exe'), (t03/'x86_64-windows/lsteamclient.dll','lsteamclient.dll'), (t03/'x86_64-unix/lsteamclient.so','lsteamclient.so'), (trigger,'steamclient64.dll')]:
    dst = steam/name
    clone(src,dst)
    placed[str(dst.relative_to(work))] = digest(dst)
placed['steam-api-probe.exe'] = digest(work/'steam-api-probe.exe')
env = {k:v for k,v in os.environ.items() if not k.startswith(('DYLD_', 'WINEDLLPATH', 'WINE', 'CX_'))}
env.update(WINEPREFIX=str(prefix), WINEDEBUG='-all,+module', WINEARCH='win64', SikarugirAppWine11='1', DYLD_FALLBACK_LIBRARY_PATH=str(engine/'Frameworks')+':/usr/lib')
manifest['runtimeEnvironment'] = {k:env[k] for k in ('WINEPREFIX','WINEDEBUG','WINEARCH','SikarugirAppWine11','DYLD_FALLBACK_LIBRARY_PATH')}
with (work/'wineboot-raw.log').open('w') as log:
    rc = subprocess.run(['arch','-x86_64','/usr/bin/env','DYLD_FALLBACK_LIBRARY_PATH='+env['DYLD_FALLBACK_LIBRARY_PATH'],'SikarugirAppWine11=1',str(engine/'bin/wine'),'wineboot','-u'],env=env,stdout=log,stderr=subprocess.STDOUT).returncode
manifest['winebootExit'] = rc
save()
manifest['status'] = 'PREFIX_STAGED' if rc == 0 else 'BLOCKED_WINEBOOT'
save()
assert rc == 0, 'BLOCKED: wineboot failed; inspect scratch/t05/wineboot-raw.log'
print('stage PASS; hashes and wineboot exit in scratch/t05/stage-manifest.json')
PYTHON
