#!/bin/sh
# shellcheck disable=SC2034,SC2154
set -e
SRC="${1:-$(dirname "$0")/../feats/compat_run.sh}"
[ -f "$SRC" ] || { echo "buildcheck: $SRC not present, skipped"; exit 0; }

extract() { sed -n "/^$1() {\$/,/^}\$/p" "$SRC"; }
functions=""
for name in alert_safe last_wine_build refuse_other_build claim_prefix; do
	body=$(extract "$name")
	[ -n "$body" ] || { echo "FAIL: $name not found in $SRC"; exit 1; }
	functions="$functions
$body"
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

np_support="$work/support"
clone() {
	inf="$np_support/runners/$1/wine/share/wine/wine.inf"
	mkdir -p "$(dirname "$inf")"
	: > "$inf"
	touch -t "$2" "$inf"
}
clone sikarugir-11.0-r0 202607151200
clone sikarugir-10.0-r3 202608211200
mtime() { stat -f %m "$np_support/runners/$1/wine/share/wine/wine.inf"; }

fails=0
ok() { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n         want [%s]\n         got  [%s]\n' "$1" "$2" "$3"; fails=$((fails + 1)); }
is() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "$2" "$3"; fi; }

launch() {
	build=$1 updated=$2 record=$3
	data=$(mktemp -d "$work/compatdata.XXXXXX")
	mkdir -p "$data/pfx"
	[ -z "$updated" ] || printf '%s\r\n' "$updated" > "$data/pfx/.update-timestamp"
	[ -z "$record" ] || printf '%s' "$record" > "$data/notproton-build"
	(
		STEAM_COMPAT_DATA_PATH=$data
		np_build=$build
		np_display="display of $build"
		np_runner="$np_support/runners/$build/wine"
		log=/dev/null
		# shellcheck disable=SC2329 # called by the extracted refusal
		show_alert() { printf 'alert: %s\n' "$2"; }
		eval "$functions"
		refuse_other_build
		claim_prefix
	) > "$data/out" 2>&1 && status=0 || status=$?
	echo "status=$status"
	grep -o 'last run by [^,]*' "$data/out" || true
	[ ! -f "$data/notproton-build" ] || head -1 "$data/notproton-build"
}

echo "== prefixes from before the record =="
is "a fresh prefix is claimed" "status=0
sikarugir-11.0-r0" "$(launch sikarugir-11.0-r0 "" "")"
is "a prefix this build last updated is claimed" "status=0
sikarugir-11.0-r0" "$(launch sikarugir-11.0-r0 "$(mtime sikarugir-11.0-r0)" "")"
is "a prefix any other Wine updated is refused" "status=1
last run by another Wine build" "$(launch sikarugir-11.0-r0 "$(mtime sikarugir-10.0-r3)" "")"
is "a prefix no clone updated is refused" "status=1
last run by another Wine build" "$(launch sikarugir-11.0-r0 1 "")"
is "updates the user disabled say nothing, so the prefix is claimed" "status=0
sikarugir-11.0-r0" "$(launch sikarugir-11.0-r0 disable "")"

echo "== prefixes with a record =="
is "the record wins over the Wine that updated the prefix" "status=0
sikarugir-10.0-r3" "$(launch sikarugir-10.0-r3 "$(mtime sikarugir-11.0-r0)" "sikarugir-10.0-r3
Sikarugir 10.0
")"
is "a record for another build is refused" "status=1
last run by Sikarugir 10.0
sikarugir-10.0-r3" "$(launch sikarugir-11.0-r0 "" "sikarugir-10.0-r3
Sikarugir 10.0
")"

if [ "$fails" -eq 0 ]; then
	echo "==> buildcheck: all assertions hold"
else
	echo "==> buildcheck: $fails failed"
	exit 1
fi
