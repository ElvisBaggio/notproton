/* b1probe: Cities II B1 — FindNextFile last-error, raw Win32 vs game's Mono + Colossal.IO.
 * usage: b1probe.exe <game dir (Windows path)> <dir to enumerate (Windows path)> */
#include <windows.h>
#include <stdio.h>

typedef void *P;
static FARPROC need(HMODULE m, const char *n) {
    FARPROC p = GetProcAddress(m, n);
    if (!p) printf("!! missing export %s\n", n);
    return p;
}

static void raw(const char *dir) {
    WCHAR w[1024]; WIN32_FIND_DATAW fd; int n = 0;
    char pat[1024]; snprintf(pat, sizeof pat, "\\\\?\\%s\\*", dir);
    MultiByteToWideChar(CP_UTF8, 0, pat, -1, w, 1024);
    HANDLE h = FindFirstFileW(w, &fd);
    if (h == INVALID_HANDLE_VALUE) { printf("raw: FindFirstFileW failed GLE=%lu\n", GetLastError()); return; }
    do n++; while (FindNextFileW(h, &fd));
    printf("raw: %d entries, GLE after FindNextFileW=FALSE: %lu (want 18)\n", n, GetLastError());
    FindClose(h);
}

int main(int argc, char **argv) {
    if (argc < 3) { printf("usage: b1probe <gamedir> <dir>\n"); return 1; }
    const char *game = argv[1], *dir = argv[2];
    char embed[1024], dll[1024], managed[1024], mbe[1024], etc[1024], cio[1024];
    snprintf(mbe, sizeof mbe, "%s\\MonoBleedingEdge", game);
    snprintf(embed, sizeof embed, "%s\\EmbedRuntime", mbe);
    snprintf(dll, sizeof dll, "%s\\mono-2.0-bdwgc.dll", embed);
    snprintf(etc, sizeof etc, "%s\\etc", mbe);
    snprintf(managed, sizeof managed, "%s\\Cities2_Data\\Managed", game);
    snprintf(cio, sizeof cio, "%s\\Colossal.IO.dll", managed);

    raw(dir);

    SetDllDirectoryA(embed);
    HMODULE m = LoadLibraryA(dll);
    if (!m) { printf("!! LoadLibrary %s GLE=%lu\n", dll, GetLastError()); return 2; }
    void (*set_asm)(const char *) = (void *)need(m, "mono_set_assemblies_path");
    void (*set_dirs)(const char *, const char *) = (void *)need(m, "mono_set_dirs");
    void (*cfg)(const char *) = (void *)need(m, "mono_config_parse");
    P (*jit_init)(const char *, const char *) = (void *)need(m, "mono_jit_init_version");
    P (*asm_open)(P, const char *) = (void *)need(m, "mono_domain_assembly_open");
    P (*asm_image)(P) = (void *)need(m, "mono_assembly_get_image");
    P (*cls_from)(P, const char *, const char *) = (void *)need(m, "mono_class_from_name");
    P (*meth)(P, const char *, int) = (void *)need(m, "mono_class_get_method_from_name");
    P (*newstr)(P, const char *) = (void *)need(m, "mono_string_new");
    P (*invoke)(P, P, void **, P *) = (void *)need(m, "mono_runtime_invoke");
    size_t (*alen)(P) = (void *)need(m, "mono_array_length");
    void (*pexc)(P) = (void *)need(m, "mono_print_unhandled_exception");
    if (!set_asm || !jit_init || !asm_open || !cls_from || !meth || !invoke) return 3;

    set_asm(managed); set_dirs(mbe, etc); if (cfg) cfg(NULL);
    P dom = jit_init("b1probe", "v4.0.30319");
    P a = dom ? asm_open(dom, cio) : NULL;
    if (!a) { printf("!! could not open %s\n", cio); return 4; }
    P k = cls_from(asm_image(a), "System.IO", "LongDirectory");
    P gf = k ? meth(k, "GetFiles", 3) : NULL;
    if (!gf) { printf("!! LongDirectory.GetFiles(3) not found\n"); return 5; }

    for (int i = 0; i < 5; i++) {
        int opt = 0; P exc = NULL;
        void *args[3] = { newstr(dom, dir), newstr(dom, "*"), &opt };
        P r = invoke(gf, NULL, args, &exc);
        if (exc) { printf("mono[%d]: LongDirectory.GetFiles THREW:\n", i); pexc(exc); }
        else printf("mono[%d]: LongDirectory.GetFiles OK, %zu files\n", i, alen(r));
    }
    return 0;
}
