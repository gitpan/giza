#!/bin/sh

lines=`(cd /home/ask/giza2; sh helpers/count.sh 2>/dev/null)`;
chars=`(cd /home/ask/giza2; sh helpers/count.sh -c 2>/dev/null)`;
date=`date`

echo "[$date] lines: $lines chars: $chars" >> /home/ask/giza2/devel/growth
