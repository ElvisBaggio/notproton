"""Synthetic native harness for the Sikarugir Wine 11 flag transition."""
import pathlib
import shutil
import subprocess
import tempfile
import unittest


class DetourFlags(unittest.TestCase):
    @unittest.skipUnless(shutil.which("cc"), "C compiler unavailable")
    def test_flags_only_clear_after_trampolines(self):
        source = pathlib.Path(__file__).resolve().parents[1] / "detour.c"
        harness = r'''#include <assert.h>
#include <string.h>
#define NP_SIKARUGIR_WINE11
#include "SOURCE"
static u8 image[1024], bridge[1024], wm[128];
static int fail_protect;
static u32 get(void *p, void *x, void *n, void **out) { *out=bridge; return 0; }
static u32 protect(void *p, void **b, u64 *s, u32 n, u32 *o) { return fail_protect; }
int main(void) {
    struct ctx c={get,get,protect};
    struct nt_headers *nt=(void *)image;
    u16 name[]={'s','t','e','a','m','c','l','i','e','n','t','6','4','.','d','l','l',0};
    *(void **)(wm+0x30)=image; *(void **)(wm+0x60)=name;
    *WM_FLAGS(wm)=0xc0000002;
    fail_protect=1; detour_build_module(&c,wm,0);
    assert(*WM_FLAGS(wm)==0xc0000002);
    fail_protect=0; detour_build_module(&c,wm,0);
    assert(*WM_FLAGS(wm)==0xc0000002);
    nt->opt.dir[0].rva=256; nt->opt.entry_point=512;
    detour_build_module(&c,wm,0);
    assert(*WM_FLAGS(wm)==0x80000002);
    assert(image[512]==0xb8 && image[517]==0xc3);
    return 0;
}
'''.replace("SOURCE", str(source))
        with tempfile.TemporaryDirectory() as tmp:
            src=pathlib.Path(tmp)/"test.c"; src.write_text(harness)
            exe=pathlib.Path(tmp)/"test"
            subprocess.run(["cc", "-w", str(src), "-o", str(exe)], check=True)
            subprocess.run([str(exe)], check=True)
