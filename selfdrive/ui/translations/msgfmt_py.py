#!/usr/bin/env python3
import sys
sys.path.insert(0, "/data/py_extra")
import polib
args = sys.argv[1:]
out = None
src = None
i = 0
while i < len(args):
    if args[i] == '-o':
        out = args[i+1]
        i += 2
    else:
        src = args[i]
        i += 1
po = polib.pofile(src)
po.save_as_mofile(out)
