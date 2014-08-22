#!/bin/bash

# Version 0.3
#
# Recursively computes total size of files modified in a 
# specified month on a per-directory basis
#
# caveat: kinda does the above.  Needs some tweaking to
# handle cumulative calculations
# Projects can be totaled separately, if needed.
# 
YEAR=$1
MON=$2
MON_END=$((MON + 1))

echo $MON_END

# create test files for bounding the relevant files
touch -d $YEAR-$MON-01 /tmp/dir_compute.begin
touch -d $YEAR-$MON_END-01 /tmp/dir_compute.end


MONTHS=(nul Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
DEPTH=0

# functions
dirwalk() {
    for i in "$1"/*; do
	TOTAL=0
	if [ -d "$i" ]; then     # identify directories
	    DEPTH=$((DEPTH + 1))
	    if [ $DEPTH -eq 1 ]; then
#		echo "Project ${i##*/}" >> ./data_output.csv
		PROJECT=$i
	    fi
	    if [ $DEPTH -gt 2 ]; then
		:
	    fi
	    #         echo -e "\e[32m$i \e[0mat depth \e[33m$DEPTH\e[0m."   # prints the active directory, for debugging
	    for f in "$i"/*; do
		if [ -f "$f" ]; then   # identify files
		    filetime "$f" $TOTAL
		fi
#		if [ -d "$f" ]; then #identify nested directories
#		    dirwalk "$i"
#		fi
	    done
	    if [ $TOTAL -gt 0 ]; then		
		echo -e "${PROJECT##*/},${i##*/},$MON,$YEAR,$TOTAL" >> ./data_output.csv
	    fi
	    dirwalk "$i"
	fi
    done
    DEPTH=$((DEPTH - 1))
}


filetime() {
    if [ "$1" -nt "/tmp/dir_compute.begin" ] && [ "$1" -ot "/tmp/dir_compute.end" ]; then
	SIZE=`stat -c%s "$1"`
	TOTAL=$(($TOTAL + $SIZE))
	return $TOTAL
    fi
}


data_template() {
    if [ ! -f "./data_output.csv" ]; then
	echo -e "Project,Directory,Month,Year,Size (in bytes)" > ./data_output.csv
    fi
}

if [ $# != 3 ]; then    #check that the command line was correct
    echo "Incorrect number of arguments!" >&2
    echo ""
    echo -e "\t usage: monthly_collection.sh YYYY MM /path/to/examine"
    echo -e "\t \t where YYYY is a 4 digit year and MM is a 1 or 2 digit month"
else
    data_template
    echo -e "Calculating size of collected data for ${MONTHS[$MON]}, $YEAR\n"
    dirwalk $3
    rm /tmp/dir_compute.begin /tmp/dir_compute.end     # cleanup
    echo "done."
fi
