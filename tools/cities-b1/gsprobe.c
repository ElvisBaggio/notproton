/* gsprobe: does %gs:[0x68] (TEB LastErrorValue, what Mono's JIT reads inline) match GetLastError()? */
#include <windows.h>
#include <stdio.h>
static unsigned gs32(unsigned off) { unsigned v; __asm__ volatile("movl %%gs:(%1), %0" : "=r"(v) : "r"((unsigned long long)off)); return v; }
static void *gs64(unsigned off) { void *v; __asm__ volatile("movq %%gs:(%1), %0" : "=r"(v) : "r"((unsigned long long)off)); return v; }
int main(void) {
    char *teb = (char *)NtCurrentTeb();
    printf("NtCurrentTeb=%p gs:[0x30]=%p (Self)\n", teb, gs64(0x30));
    printf("TEB->LastErrorValue offset 0x68 = %lu\n", *(DWORD *)(teb + 0x68));
    int fail = 0;
    for (DWORD want = 18; want <= 20; want++) {
        SetLastError(want);
        DWORD gle = GetLastError(); unsigned gs = gs32(0x68);
        printf("SetLastError(%lu): GetLastError=%lu gs:[0x68]=%u (0x%x) %s\n", want, gle, gs, gs, gs == want ? "OK" : "MISMATCH");
        fail |= gs != want;
    }
    printf(fail ? "RESULT: FAIL gs:[0x68] != LastError\n" : "RESULT: OK\n");
    return fail;
}
