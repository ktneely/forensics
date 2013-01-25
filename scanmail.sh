#!/bin/bash

###
# This is the InfoSec automated Outlook PST examination script v 0.1
# created by Kevin T. Neely - Junipers Network InfoSec
#
# -= Version History =-
#
# 0.2 
#   - now takes a directory as argument and analyzes all PSTs in the dir.
#
# 0.1 Initial Version
#   - must specify one PST
#   - extracts PST to a temporary space
#   - scans the PST with ClamAV

# Test for the arguments
function testargs {
    if [ $1 ] && [ $2 ]
    then
	echo "Extracting PST..."
    else
	echo "This script takes two arguments:"
	echo "1) The directory containing the PST"
	echo "2) The destination for the extracted data"
	echo " "
	echo "Usage: scanmail.sh /path/to/pst /tmp/maildata"
	echo " "
	exit
    fi
    }

FILES=$2/*.pst
function extractmail {
    /usr/bin/readpst -SDq -o $2 $f
    }

function scandata {
    clamscan -r --infected $2
    }

for f in ${FILES}
do
    extractmail



#testargs
extractmail
scandata

