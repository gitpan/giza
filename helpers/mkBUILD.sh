#!/bin/bash

MANIFEST=${MANIFEST:-MANIFEST}

if [ ! -f "MANIFEST" ]; then
	echo "Missing MANIFEST"
	exit 1
fi

if [ ! -d "BUILD" ]; then
	mkdir BUILD
fi

for file in $(cat $MANIFEST); do
	if [ -d "$file" ]; then
		mkdir -p BUILD/$file
	fi
done
