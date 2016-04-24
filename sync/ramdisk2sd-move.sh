#!/bin/sh

RAMDISK_PATH="`realpath ${1:-~/capture_ramdisk}`"
SD_PATH="`realpath ${2:-~/capture}`"

cd "$RAMDISK_PATH"
find . -mmin +3 ! -name latest.jpg | 
while read file
do
    destdir="$SD_PATH"/$(dirname "$file")
    mkdir -p "$destdir"
    mv "$file" "$destdir"
done
