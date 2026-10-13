#!/bin/sh
# run.sh <runner wine dir> <prefix> <exe args...>
R="$1"; W="$2"; shift 2
exec /usr/bin/arch -x86_64 /usr/bin/env WINEPREFIX="$W" WINEARCH=win64 WINEDEBUG=-all WINEDLLOVERRIDES="mscoree,mshtml="   SikarugirAppWine11=1 DYLD_FALLBACK_LIBRARY_PATH="${FW:-$R/Frameworks}:/usr/lib" "$R/bin/wine" "$@"
