#!/bin/bash

set -e
set -u

_1MB=1024
_10MB=10240
_100MB=102400
_1000GB=1024000

for size in $_1MB $_10MB $_100MB $_1000GB; do
  fname=fs-0x00dcc605-ext2-$size.img
  dd if=/dev/zero of=$fname bs=1024 count=$size
  mkfs.ext2 $fname
done
