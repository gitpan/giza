#!/bin/bash
#ask@unixmonks.net

what=-l

if [ "$1" = "-c" ]; then
	what=-c
fi

dirs=$(find . -type d \! -name "*CVS*" | grep -v /gfx)
dirs=$(echo $dirs | sed 's%\n% %g')

for dir in $dirs; do
	echo $dir >/dev/stderr
	count=$(wc $what $dir/* 2>/dev/null 		\
		| perl -ne'chomp;print if s/total$//' 	\
		| awk '{print $1" +"}'					\
	)
	count=$(echo $count | sed 's%\n% %g')
	total="$total $count"
done

total=$(echo $total | sed 's/\+$/ /')
total=$(expr $total)
echo $total

