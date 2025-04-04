#!/usr/bin/env python3
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.

from sys import argv

DESYNC_FRAME = [0x00, 0x10, 0x00, 0x00]

binfile = argv[1]
nbytes = int(argv[2])
outfile = argv[3]

with open(binfile, "rb") as f:
    bindata = f.read()

assert len(bindata) <= nbytes

with open(outfile, "w") as f:
    for i in range(nbytes):
        if i < len(bindata):
            print(f"{bindata[i]:02x}", file=f)
        else:
            if i < len(bindata) + len(DESYNC_FRAME):
                byte_counter = i - len(bindata)
                print(f"{DESYNC_FRAME[byte_counter]:02x}", file=f)
            else:
                print("0", file=f)
