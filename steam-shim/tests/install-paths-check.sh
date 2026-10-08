#!/bin/sh
set -eu
src=${1:-$(dirname "$0")/../steam.cpp}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
sed -n '/^static void set_install_paths(void)$/,/^}$/p' "$src" > "$work/function.cpp"
[ -s "$work/function.cpp" ] || { echo 'FAIL: Steam install registry setup missing'; exit 1; }
cat > "$work/check.cpp" <<'EOF'
#include <cassert>
#include <cstring>
using DWORD = unsigned long;
constexpr int HKEY_LOCAL_MACHINE = 1, HKEY_CURRENT_USER = 2, REG_SZ = 1;
struct Value { int hive; const char *key; const char *name; const char *data; };
static const Value expected[] = {
    {HKEY_LOCAL_MACHINE, "Software\\Wow6432Node\\Valve\\Steam", "InstallPath", "C:\\Program Files (x86)\\Steam"},
    {HKEY_LOCAL_MACHINE, "Software\\Valve\\Steam", "InstallPath", "C:\\Program Files (x86)\\Steam"},
    {HKEY_CURRENT_USER, "Software\\Valve\\Steam", "SteamExe", "C:\\Program Files (x86)\\Steam\\steam.exe"},
    {HKEY_CURRENT_USER, "Software\\Valve\\Steam\\ActiveProcess", "SteamPath", "C:\\Program Files (x86)\\Steam"},
};
static unsigned calls;
static int RegSetKeyValueA(int hive, const char *key, const char *name, int type, const void *data, DWORD bytes)
{
    assert(calls < 4);
    const auto &value = expected[calls++];
    assert(hive == value.hive && !strcmp(key, value.key) && !strcmp(name, value.name));
    assert(type == REG_SZ && bytes == strlen(value.data) + 1);
    assert(!memcmp(data, value.data, bytes));
    return 0;
}
#include "function.cpp"
int main() { set_install_paths(); assert(calls == 4); }
EOF
${CXX:-clang++} -std=c++11 -Wall -Wextra -Werror "$work/check.cpp" -o "$work/check"
"$work/check"
# Setup must run on the game path before attempting the native Steam API.
sed -n '/^    if (getenv("SteamGameId"))$/,/^        if (steam_client_init())$/p' "$src" > "$work/game-path"
[ "$(tail -n 1 "$work/game-path")" = '        if (steam_client_init())' ]
[ "$(grep -c '^[[:space:]]*set_install_paths();$' "$src")" -eq 1 ]
grep -q '^[[:space:]]*set_install_paths();$' "$work/game-path"
echo 'PASS: Ubisoft Steam discovery registry values and game setup ordering'
