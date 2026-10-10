// Static signature check. Resolves every signature of a database against Mach-O files
// on disk by the same resolver path the dylib uses, without dlopen: the arm64 slice
// is laid out in anonymous memory and its classic rebase opcodes applied. No code from
// the image runs, so it is safe on a copy of a Steam library.
// Limits: no chained fixups (rejected); selector slots hold the image's own strings,
// which is what the resolver finds first at runtime too.
// Usage: sigstatic [--emit out.tsv] <sigdb.json> <module>=<path> [...] [rtti:<mangled type> ...]
// --emit writes name, anchor address and byte pattern per signature for sigprofile.py. A pattern
// that already matches only at the anchor site is kept; otherwise it is rebuilt from the bytes
// there, wildcarding position-dependent instructions, and grown until it is unique.
// Per signature, in unslid addresses: anchor result, byte pattern result, recorded address.
// Exit 0 only if every signature resolves by anchor, the pattern (when present) agrees,
// and the recorded address (when present) matches.

#include "../resolver/sigdb.h"
#include "../resolver/resolver.h"
#include "../resolver/anchor.h"
#include "../resolver/aob.h"
#include "../core/macho.h"

#include <mach-o/fat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <libkern/OSByteOrder.h>

typedef struct {
    char module[64];
    const struct mach_header_64 *mh;
    intptr_t slide;
    uintptr_t text;
    size_t text_sz;
} image_t;

static uint64_t uleb(const uint8_t **p, const uint8_t *end) {
    uint64_t v = 0;
    unsigned sh = 0;
    while (*p < end) {
        uint8_t b = *(*p)++;
        v |= (uint64_t)(b & 0x7F) << sh;
        sh += 7;
        if (!(b & 0x80)) break;
    }
    return v;
}

static int load_static(const char *path, image_t *im) {
    FILE *f = fopen(path, "rb");
    if (!f) { perror(path); return -1; }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    uint8_t *file = malloc((size_t)n);
    if (!file || fread(file, 1, (size_t)n, f) != (size_t)n) { fclose(f); return -1; }
    fclose(f);

    uint8_t *slice = file;
    if (OSSwapBigToHostInt32(*(uint32_t *)file) == FAT_MAGIC) {
        struct fat_header *fh = (void *)file;
        struct fat_arch *fa = (void *)(fh + 1);
        slice = NULL;
        for (uint32_t i = 0; i < OSSwapBigToHostInt32(fh->nfat_arch); i++)
            if ((int)OSSwapBigToHostInt32(fa[i].cputype) == CPU_TYPE_ARM64)
                slice = file + OSSwapBigToHostInt32(fa[i].offset);
        if (!slice) { fprintf(stderr, "%s: no arm64 slice\n", path); return -1; }
    }
    const struct mach_header_64 *h = (void *)slice;
    if (h->magic != MH_MAGIC_64 || h->cputype != CPU_TYPE_ARM64) return -1;

    const struct segment_command_64 *segs[16];
    int nseg = 0;
    uint64_t lo = UINT64_MAX, hi = 0;
    const struct dyld_info_command *di = NULL;
    const uint8_t *c = (const uint8_t *)(h + 1);
    for (uint32_t i = 0; i < h->ncmds; i++) {
        const struct load_command *lc = (const void *)c;
        if (lc->cmd == LC_SEGMENT_64 && nseg < 16) {
            const struct segment_command_64 *s = (const void *)c;
            segs[nseg++] = s;
            if (strcmp(s->segname, "__PAGEZERO")) {
                if (s->vmaddr < lo) lo = s->vmaddr;
                if (s->vmaddr + s->vmsize > hi) hi = s->vmaddr + s->vmsize;
            }
        } else if (lc->cmd == LC_DYLD_INFO_ONLY || lc->cmd == LC_DYLD_INFO) {
            di = (const void *)c;
        } else if (lc->cmd == LC_DYLD_CHAINED_FIXUPS) {
            fprintf(stderr, "%s: chained fixups are not supported\n", path);
            return -1;
        }
        c += lc->cmdsize;
    }
    if (lo != 0 || !di) { fprintf(stderr, "%s: unexpected layout\n", path); return -1; }

    uint8_t *mem = mmap(NULL, hi, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
    if (mem == MAP_FAILED) return -1;
    for (int i = 0; i < nseg; i++)
        if (segs[i]->filesize)
            memcpy(mem + segs[i]->vmaddr, slice + segs[i]->fileoff, segs[i]->filesize);

    // Rebase: on-disk pointers are unslid addresses.
    intptr_t slide = (intptr_t)mem;
    const uint8_t *p = slice + di->rebase_off, *end = p + di->rebase_size;
    uint64_t seg = 0, off = 0;
    while (p < end) {
        uint8_t op = *p & 0xF0, imm = *p & 0x0F;
        p++;
        uint64_t cnt = 0, skip = 0;
        int doit = 0;
        switch (op) {
        case 0x00: p = end; break;
        case 0x10: break;                                   // type: pointer only
        case 0x20: seg = imm; off = uleb(&p, end); break;
        case 0x30: off += uleb(&p, end); break;
        case 0x40: off += (uint64_t)imm * 8; break;
        case 0x50: cnt = imm; doit = 1; break;
        case 0x60: cnt = uleb(&p, end); doit = 1; break;
        case 0x70: cnt = 1; skip = uleb(&p, end); doit = 1; break;
        case 0x80: cnt = uleb(&p, end); skip = uleb(&p, end); doit = 1; break;
        default: fprintf(stderr, "%s: bad rebase opcode\n", path); return -1;
        }
        if (!doit) continue;
        if (seg >= (uint64_t)nseg) return -1;
        for (uint64_t k = 0; k < cnt; k++) {
            *(uint64_t *)(mem + segs[seg]->vmaddr + off) += (uint64_t)slide;
            off += 8 + skip;
        }
    }

    im->mh = (const struct mach_header_64 *)mem;
    im->slide = slide;
    return np_find_segment(im->mh, im->slide, "__TEXT", &im->text, &im->text_sz);
}

static int is_wild(uint32_t w, uint32_t prev) {
    if ((w & 0x9F000000) == 0x90000000 || (w & 0x9F000000) == 0x10000000) return 1;   // ADRP, ADR
    if ((w & 0x7C000000) == 0x14000000 || (w & 0xFF000010) == 0x54000000) return 1;   // B, BL, B.cond
    if ((w & 0x7E000000) == 0x34000000 || (w & 0x7E000000) == 0x36000000) return 1;   // CBZ, TBZ
    if ((w & 0x3B000000) == 0x18000000) return 1;                                     // LDR literal
    if ((prev & 0x9F000000) == 0x90000000 && ((w >> 5) & 0x1F) == (prev & 0x1F) &&
        ((w & 0x7F800000) == 0x11000000 || (w & 0x3B000000) == 0x39000000))
        return 1;                                                                     // page offset
    return 0;
}

// Bytes at the site with position-dependent instructions wildcarded, grown one
// instruction at a time until it matches nowhere else in __TEXT. out needs 4096 bytes.
static int rebuild_pattern(const np_sig_entry_t *s, uintptr_t site, const image_t *im,
                           int min_insns, char *out) {
    const uint32_t *w = (const uint32_t *)(site + s->match_offset);
    uintptr_t avail = im->text + im->text_sz - (uintptr_t)w;   // never read past __TEXT
    int max_insns = (uintptr_t)w < im->text || (uintptr_t)w >= im->text + im->text_sz ? 0 : (int)(avail / 4);
    if (max_insns > 32) max_insns = 32;
    for (int n = min_insns; n <= max_insns; n++) {
        char *o = out;
        for (int i = 0; i < n; i++) {
            int wild = is_wild(w[i], i ? w[i - 1] : 0);
            for (int k = 0; k < 4; k++) {
                if (wild) o += sprintf(o, "%s??", o == out ? "" : " ");
                else o += sprintf(o, "%s%02X", o == out ? "" : " ", ((const uint8_t *)&w[i])[k]);
            }
        }
        np_byte_pattern_t pat;
        if (np_compile_pattern(out, &pat) != 0) return -1;
        uintptr_t hit = np_scan_sole_match(im->text, im->text_sz, &pat);
        np_release_pattern(&pat);
        if (hit == site + s->match_offset) return 0;
    }
    return -1;
}

static const char *kind_name(np_match_kind_t k) {
    static const char *n[] = {"none", "string", "vtable_slot", "insn_after_string",
                              "insn_pair", "aob", "call_target", "calls"};
    return (unsigned)k < 8 ? n[k] : "?";
}

int main(int argc, char **argv) {
    FILE *emit = NULL;
    if (argc > 3 && !strcmp(argv[1], "--emit")) {
        emit = fopen(argv[2], "w");
        if (!emit) return 3;
        argc -= 2;
        argv += 2;
    }
    if (argc < 3) { fprintf(stderr, "usage: sigstatic [--emit out.tsv] sigdb.json module=path...\n"); return 3; }
    image_t ims[4];
    int nim = 0;
    const char *rtti[16];
    int nrtti = 0;
    for (int i = 2; i < argc && nim < 4; i++) {
        if (!strncmp(argv[i], "rtti:", 5) && nrtti < 16) { rtti[nrtti++] = argv[i] + 5; continue; }
        char *eq = strchr(argv[i], '=');
        if (!eq) return 3;
        *eq = 0;
        snprintf(ims[nim].module, sizeof ims[nim].module, "%s", argv[i]);
        if (load_static(eq + 1, &ims[nim]) != 0) return 3;
        nim++;
    }
    np_sigdb_t db;
    if (np_load_profile(argv[1], &db) != 0) return 2;
    printf("%s build %llu, %d signatures\n", argv[1],
           (unsigned long long)db.steam_build, db.sig_count);

    int bad = 0;
    for (int i = 0; i < db.sig_count; i++) {
        np_sig_entry_t *s = &db.signatures[i];
        const image_t *im = NULL;
        for (int k = 0; k < nim; k++)
            if (!strcmp(ims[k].module, s->module)) im = &ims[k];
        if (!im) { printf("  %-56s NO IMAGE for %s\n", s->name, s->module); bad++; continue; }

        uintptr_t anc = s->anchor.kind == NP_MATCH_NONE ? 0
            : np_locate_anchor(im->mh, im->slide, im->text, im->text_sz, &s->anchor);
        uintptr_t aob = np_aob_site(s, im->text, im->text_sz);
        unsigned long a = anc ? anc - im->slide : 0, b = aob ? aob - im->slide : 0;
        const char *v = "OK";
        if (!anc) v = "ANCHOR FAILED";
        else if (s->aob_hex[0] && b != a) v = b ? "AOB DISAGREES" : "AOB DID NOT MATCH";
        else if (s->func_addr_this_build && s->func_addr_this_build != a) v = "RECORDED WRONG";
        if (emit && anc) {
            char fresh[4096] = "";
            int insns = (int)((strlen(s->aob_hex) + 1) / 12);   // "XX " per byte, 4 per insn
            int ok = rebuild_pattern(s, anc, im, insns ? insns : 8, fresh) == 0;
            if (aob == anc && ok && strcmp(fresh, s->aob_hex))
                printf("  note: rebuilt pattern differs from the old one that matched\n    old %s\n    new %s\n",
                       s->aob_hex, fresh);
            fprintf(emit, "%s\t0x%lx\t%s\n", s->name, a, aob == anc ? s->aob_hex : fresh);
            if (aob != anc && !ok) { v = "NO UNIQUE PATTERN"; }
        }
        if (strcmp(v, "OK")) bad++;
        printf("  %-56s %-17s %-16s anchor=0x%-8lx aob=0x%-8lx recorded=0x%-8lx %s\n",
               s->name, s->module, kind_name(s->anchor.kind), a, b,
               (unsigned long)s->func_addr_this_build, v);
    }
    // Class vptrs (data addresses, not signatures) of the first module, for anchorcheck's table.
    for (int k = 0; k < nrtti; k++) {
        const image_t *im = &ims[0];
        uintptr_t v = np_rtti_vptr(im->mh, im->slide, im->text, im->text_sz, rtti[k]);
        printf("  vptr %-46s 0x%lx\n", rtti[k], v ? (unsigned long)(v - im->slide) : 0ul);
        if (!v) bad++;
    }
    printf("%d problems\n", bad);
    return bad ? 1 : 0;
}
