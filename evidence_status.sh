#! /bin/bash

MONTHS=(nul Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
YEAR=2014

echo "This calculates the amount of data collected on a per month basis"
echo ""
echo "For which month would you like to collect information? (format: MM, e.g. 05 for May"
read MON
MON_END=$((MON+1))

# calculations
DATA_TOTAL=`find $1 -newermt $YEAR-$MON-01 ! -newermt $YEAR-$MON_END-01 -ls | awk '{total += $7} END {print total/1024 / 1024 / 1024}'`

echo $1

#CASES=`find $1 -maxdepth 1 -type d -newermt  $YEAR-$MON-01 ! -newermt $YEAR-$MON_END-01 -ls |awk -F"/" '{print $NF}'`



# output

echo "The total data collected for ${MONTHS[$MON]} is $DATA_TOTAL GB"
#echo $CASES
#
# find still isn't finding the directories if they are newer than the month being searched
#

find $1 -maxdepth 1 -type d -newermt  $YEAR-$MON-01 ! -newermt $YEAR-$MON_END-01 -ls |awk -F"/" '{print $NF}'
