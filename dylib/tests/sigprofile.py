#!/usr/bin/env python3
# Cuts a signature profile for a new Steam build from the TSV that `sigstatic --emit` wrote.
# The template supplies only names, modules and anchor definitions; every address and byte
# pattern comes from the TSV, which sigstatic produced from the new binaries. Re-run
# sigstatic on the result: it must report 0 problems before the profile is trusted.
# Usage: sigprofile.py <template.json> <emit.tsv> <steam_build> <out.json>
import json
import sys

template, tsv, build, out = sys.argv[1:5]
db = json.load(open(template))
rows = {}
for line in open(tsv):
    name, addr, aob = line.rstrip("\n").split("\t")
    rows[name] = (addr, aob)

missing = [s["name"] for s in db["signatures"] if s["name"] not in rows]
if missing:
    sys.exit("sigprofile: no result for %s" % ", ".join(missing))

db["steam_build"] = int(build)
db["steam_build_date"] = ""
for s in db["signatures"]:
    s["func_addr_this_build"], s["aob_hex"] = rows[s["name"]]

with open(out, "w") as f:
    f.write(json.dumps(db, indent=2) + "\n")
