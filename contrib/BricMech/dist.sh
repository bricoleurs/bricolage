#!/bin/sh
# script to build a new distribution

CHANGES='./Changes'
MODULE='./lib/Bric/Mech.pm'

if [[ -f Build ]]; then
    perl Build realclean
fi

# exit unless Changes is the newest file
NEWER=''
for f in `find . -type f`; do
    if [[ $f -nt ./Changes ]]; then
        if [[ -n $NEWER ]]; then NEWER="$NEWER,"; fi
        NEWER="$NEWER $f"
    fi
done
if [[ -n $NEWER ]]; then
    echo Newer than $CHANGES: $NEWER
    echo Update $CHANGES now
    exit
fi

# update $VERSION from Changes
VER=`head -c4 $CHANGES` && \
  perl -i~ -pe "s/VERSION = '([^']+)'/VERSION = '$VER'/" $MODULE

# create a tarball after doing checks
perl Build.PL           \
&& perl Build testpod   \
&& perl Build distmeta  \
&& perl Build distcheck \
&& perl Build disttest  \
&& perl Build dist

# ./Build test verbose=1
