#!/bin/bash

MANIFEST=${MANIFEST:-MANIFEST}
PREFIX=${1:-$PREFIX}


if [ ! -f "MANIFEST" ]; then
	echo "Missing MANIFEST"
	exit 1
fi

if [ ! -d "$PREFIX" ]; then
	mkdir $PREFIX
fi

for file in $(cat $MANIFEST); do
	if [ -d "$file" ]; then
		mkdir -p $PREFIX/$file
	fi
done
