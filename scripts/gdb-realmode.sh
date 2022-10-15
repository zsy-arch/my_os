#!/bin/sh
gdb -ix "./scripts/gdb_init_real_mode.txt" -ex "set tdesc filename ./scripts/target.xml" -ex "target remote localhost:1234" -ex "br *0x7c00" -ex "c"

