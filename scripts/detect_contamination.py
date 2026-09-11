#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
from pathlib import Path

def is_bad(o):
    return (0x3040 <= o <= 0x30FF) or (0x3400 <= o <= 0x4DBF) or \
           (0x4E00 <= o <= 0x9FFF) or (0xF900 <= o <= 0xFAFF) or \
           (0x0E00 <= o <= 0x0E7F)

roots = [Path("roles"), Path("plays"), Path("group_vars"), Path("scripts"),
         Path("callbacks")]
extras = [Path("ansible.cfg"), Path("README.md")]
hits = []
files = []
for r in roots:
    if r.is_dir():
        files += [f for f in sorted(r.rglob("*")) if f.is_file()]
files += [f for f in extras if f.exists()]

for f in files:
    if f.suffix not in (".yml", ".yaml", ".py", ".ini", ".cfg", ".sh", ".md"):
        continue
    try:
        lines = f.read_text(encoding="utf-8", errors="replace").split("\n")
    except OSError:
        continue
    for idx, line in enumerate(lines, 1):
        toks = sorted({chr(o) for ch in line for o in (ord(ch),) if is_bad(o)})
        if toks:
            hits.append((str(f), idx, "".join(toks), line.strip()))

fmt = "--" if len(sys.argv) > 1 and sys.argv[1] == "--" else "plain"
for f, idx, toks, line in hits:
    print("%s:%d [%s] :: %s" % (f, idx, toks, line[:120]))
print("TOTAL_LINES: %d" % len(hits))
