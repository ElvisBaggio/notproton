/*
 * T05 probe: proves a Windows process under Wine can reach the NATIVE Steam
 * client through the project's bridge (steamclient64.dll = lsteamclient).
 *
 * No Valve SDK headers or DLLs are used: steamclient64.dll is loaded at run
 * time (it comes from the bridge) and the three interfaces are called through
 * raw vtable slots. Slot numbers follow the public Steamworks layout for
 * SteamClient021 / SteamUtils010 / SteamUser023 and are confirmed only by the
 * real T05 run.
 *
 * Output (stdout, nothing else): STEAM_INIT=ok|fail, APP_ID=<n>,
 * AUTHENTICATED=yes|no. Never prints SteamID, names or tokens.
 * Exit 0 only if init ok, APP_ID == --appid and BLoggedOn.
 *
 *   steam-api-probe.exe --appid <n>     real probe
 *   steam-api-probe.exe --selftest      decision-table check, no Steam needed
 *
 * Build PE:   x86_64-w64-mingw32-clang -O2 -o steam-api-probe.exe steam-api-probe.c
 * Build i386: i686-w64-mingw32-clang -O2 -o steam-api-probe32.exe steam-api-probe.c (loads steamclient.dll)
 * Build host: cc -DPROBE_NATIVE -o probe-native steam-api-probe.c  (no Steam => fail)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef PROBE_NATIVE
#include <windows.h>
#endif

#define CLIENT_VERSION "SteamClient021"
#define UTILS_VERSION  "SteamUtils010"
#define USER_VERSION   "SteamUser023"

/* i386 Steam interfaces are MSVC C++ virtuals: thiscall, self in ecx. */
#if defined(_WIN32) && !defined(_WIN64)
#define CALLCONV __thiscall
#define CLIENT_DLL "steamclient.dll"
#elif defined(_WIN32)
#define CALLCONV __cdecl
#define CLIENT_DLL "steamclient64.dll"
#else
#define CALLCONV
#endif

typedef void *(*create_interface_fn)(const char *name, int *err);
typedef int      (CALLCONV *pipe_fn)(void *self);
typedef int      (CALLCONV *user_fn)(void *self, int pipe);
typedef void *   (CALLCONV *getiface_fn)(void *self, int user, int pipe, const char *ver);
typedef void *   (CALLCONV *getutils_fn)(void *self, int pipe, const char *ver);
typedef unsigned (CALLCONV *appid_fn)(void *self);
typedef int      (CALLCONV *bool_fn)(void *self);

/* First word of an interface object is its vtable. */
#define VT(obj, slot) ((*(void ***)(obj))[slot])

struct result { int init_ok; unsigned app_id; int authenticated; };

/* Pure decision: exit 0 only when all three proofs hold. */
static int decide(const struct result *r, unsigned expected)
{
    return r->init_ok && expected != 0 && r->app_id == expected && r->authenticated ? 0 : 1;
}

static void print_result(const struct result *r)
{
    printf("STEAM_INIT=%s\nAPP_ID=%u\nAUTHENTICATED=%s\n",
           r->init_ok ? "ok" : "fail", r->app_id, r->authenticated ? "yes" : "no");
    fflush(stdout);
}

static void run_probe(struct result *r)
{
    memset(r, 0, sizeof(*r));
#ifndef PROBE_NATIVE /* outside Wine there is no steamclient64.dll: init stays fail */
    {
        create_interface_fn create;
        void *client, *utils, *user;
        int pipe, huser;
        HMODULE mod = LoadLibraryA(CLIENT_DLL);

        if (!mod) return;
        create = (create_interface_fn)GetProcAddress(mod, "CreateInterface");
        if (!create) return;
        client = create(CLIENT_VERSION, NULL);
        if (!client) return;
        pipe = ((pipe_fn)VT(client, 0))(client);                          /* CreateSteamPipe */
        if (!pipe) return;
        huser = ((user_fn)VT(client, 2))(client, pipe);                   /* ConnectToGlobalUser */
        if (!huser) return;
        user  = ((getiface_fn)VT(client, 5))(client, huser, pipe, USER_VERSION); /* GetISteamUser */
        utils = ((getutils_fn)VT(client, 9))(client, pipe, UTILS_VERSION);       /* GetISteamUtils */
        if (!utils || !user) return;
        r->init_ok = 1;
        r->app_id = ((appid_fn)VT(utils, 9))(utils);                      /* GetAppID */
        r->authenticated = ((bool_fn)VT(user, 1))(user) ? 1 : 0;          /* BLoggedOn */
    }
#endif
}

static int selftest(void)
{
    static const struct { struct result r; unsigned exp; int want; const char *name; } t[] = {
        { {1, 2316660, 1}, 2316660, 0, "all proofs" },
        { {0, 0, 0},       2316660, 1, "no init" },
        { {1, 480, 1},     2316660, 1, "appid mismatch" },
        { {1, 2316660, 0}, 2316660, 1, "not logged on" },
        { {1, 0, 1},       0,       1, "expected appid zero" },
    };
    int bad = 0;
    for (size_t i = 0; i < sizeof(t) / sizeof(t[0]); i++) {
        int got = decide(&t[i].r, t[i].exp);
        printf("SELFTEST %s: %s\n", t[i].name, got == t[i].want ? "PASS" : "FAIL");
        if (got != t[i].want) bad = 1;
    }
    return bad;
}

int main(int argc, char **argv)
{
    unsigned expected = 0;
    struct result r;

    if (argc == 2 && !strcmp(argv[1], "--selftest")) return selftest();
    if (argc == 3 && !strcmp(argv[1], "--appid")) expected = (unsigned)strtoul(argv[2], NULL, 10);
    if (!expected) { fprintf(stderr, "usage: steam-api-probe --appid <n> | --selftest\n"); return 2; }

    run_probe(&r);
    print_result(&r);
    return decide(&r, expected);
}
