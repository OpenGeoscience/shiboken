#!/usr/bin/env python
import sys

fi = open(sys.argv[1], 'rt')
fo = open(sys.argv[2], 'wt')

in_rst = False
for line in fi:
    if line == '#[[.rst:\n':
        line = '#.rst\n'
        in_rst = True
    elif line == '#]]\n':
        in_rst = False
        continue
    elif in_rst:
        line = '#\n' if line == '\n' else '# ' + line
    fo.write(line)
