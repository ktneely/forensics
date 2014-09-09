#!/bin/bash

# litholds.sh ver 0.1
#
# This quick command takes a list of custodians in various CSV files[*] and 
# then sorts and de-duplicates them, outputting to a file called 'custodians.txt' 
#
# Usage: litholds.sh /path/to/*.CSV files

if [ -f "$1/custodians.txt" ]; then
    rm "$1/custodians.txt"
fi

for f in $1/*.csv; do
    tail -n +2 $f >> custodians.txt
    echo "" >> custodians.txt
done

sort custodians.txt | uniq | awk -F',' '{print $2 " " $4 ", " $8}'


# [*] The CSV file should take the format for a RedmineCRM Contacts plugin import
# (see http://redminecrm.com/projects/crm/pages/1)
#
# The first eight fields -which is all that is relevant here- take the form of:
# Is company,First Name,Middle Name,Last Name,Job title,Company,Phone,Email
# only fields 2, 4, and 8 are used.
