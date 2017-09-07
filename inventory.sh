#!/bin/bash

# This creates an inventory of directories, which are meant to be one
# per case or custodian in a Forensics collection

# Usage: inventory.sh /path/to/Volume


CONTENTS=`ls $1`  # Grab the contents of the target directory
OS=`uname`   # Determine the platform

# Retrieve Volume name on Mac OS X systems
if [ $OS == 'Darwin' ]
then
    VOL=`diskutil info $1 | grep "Volume Name:" | awk '{print $3}'`
fi


# iterate through directories & create the inventory
for dir in $CONTENTS
do
    [ -d "${dir}" ] || continue
    DATA=`stat -c %n,%y $dir`
    echo -e "$DATA,$VOL\n" >> inventory.csv
done

