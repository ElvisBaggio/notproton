#ifndef STEAM_SHIM_MINGW_COMPAT_H
#define STEAM_SHIM_MINGW_COMPAT_H

#include <stdarg.h>
#include "posix_compat.h"

#undef PATH_MAX
#define PATH_MAX 4096
#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))
#define CP_UNIXCP 65010
#define WINELIB_NAME_AW(name) name##W
#define WINE_DEFAULT_DEBUG_CHANNEL(name)

static inline void shim_log(const char *format, ...)
{
    va_list args;
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
}
#define WINE_ERR(...) shim_log(__VA_ARGS__)
#define ERR(...) WINE_ERR(__VA_ARGS__)
#define WINE_WARN(...) shim_log(__VA_ARGS__)
#define WINE_FIXME(...) shim_log(__VA_ARGS__)
#define WINE_TRACE(...) do { if (getenv("STEAM_SHIM_TRACE")) shim_log(__VA_ARGS__); } while (0)
#define TRACE(...) WINE_TRACE(__VA_ARGS__)
#define WARN(...) WINE_WARN(__VA_ARGS__)
static inline const char *wine_dbgstr_a(const char *s) { return s ? s : "(null)"; }
static inline const char *wine_dbgstr_w(const WCHAR *s)
{
    static thread_local char buffers[4][1024];
    static thread_local unsigned index;
    char *buffer = buffers[index++ % ARRAY_SIZE(buffers)];
    if (!s) return "(null)";
    if (!WideCharToMultiByte(CP_UTF8, 0, s, -1, buffer, 1024, NULL, NULL))
        return "(unprintable)";
    return buffer;
}

/* Public Wine kernel32 extension; resolve it without a Wine-only PE import. */
static inline WCHAR *wine_get_dos_file_name(const char *path)
{
    using convert = WCHAR * (__cdecl *)(const char *);
    static convert fn = reinterpret_cast<convert>(GetProcAddress(GetModuleHandleW(L"kernel32.dll"), "wine_get_dos_file_name"));
    if (fn) return fn(path);
    SetLastError(ERROR_PROC_NOT_FOUND);
    WINE_ERR("kernel32 wine_get_dos_file_name is unavailable\n");
    return NULL;
}

typedef struct { UNICODE_STRING ObjectName, ObjectTypeName; } DIRECTORY_BASIC_INFORMATION;
extern "C" NTSTATUS NTAPI NtOpenDirectoryObject(PHANDLE, ACCESS_MASK, POBJECT_ATTRIBUTES);
extern "C" NTSTATUS NTAPI NtQueryDirectoryObject(HANDLE, PVOID, ULONG, BOOLEAN, BOOLEAN, PULONG, PULONG);

#endif
