#! /bin/bash

# A stupid script so that files copied to an archive for 
# evidence are logged into the common inventory, along with
# inventory for the create_image.sh and review_drive.sh scripts
#
# -= Usage =-
# Usage: copy_evidence <source> <destination>
#
# NOTE:  Destination should be the root of your archive mount
#
# TODO: 
#   - more elegant failure of a match
#   - deletion of source material (make it an option?)
#   - not such an ugly multi-nested if statement?


# Functions
collect_info () {
    echo "Enter the case identifier. (def: `date +%Y-%m-%da`)"
    read input_case
    CASE_NAME=${input_case:=`date +%Y-%m-%da`}
    echo "Enter the type of evidence. (def: Email)"
    read evidence_type
    EVIDENCE_TYPE=${evidence_type:=Email}
    echo "Enter the location for archives. (def: [/Data/archive/$CASE_NAME/$EVIDENCE_TYPE])"
    read input_archive
    ARCHIVE_DIR=${input_archive:=/Data/archive/$CASE_NAME/$EVIDENCE_TYPE}
    mkdir -p $ARCHIVE_DIR
    }

copy_and_log () {
    for f in $1/* ; do
    if [ -f "$f" ]; then  # progress through all files in the dir
	F_MD5SUM=`md5deep -b $f |awk '{print $1}'`    # calc md5 of original
	cp "$f" $ARCHIVE_DIR          # copy each file
	C_MD5SUM=`md5deep -b $ARCHIVE_DIR/"${f##*/}" |awk '{print $1}'` # calc md5 of copy
	if [ "$F_MD5SUM" == "$C_MD5SUM" ]; then
	    if [ -f "$ARCHIVE_DIR/../../inventory.txt" ]; then
		echo -e "`date +%Y/%m/%d`,$CASE_NAME,"",$EVIDENCE_TYPE,$CASE_NAME/$EVIDENCE_TYPE/${f##*/},$F_MD5SUM" >> $ARCHIVE_DIR/../../inventory.txt
	    else
		echo -e "Date,Case Number,Custodian,System,File Location,Checksum" > $ARCHIVE_DIR/../../inventory.txt
		echo -e "`date +%Y/%m/%d`,$CASE_NAME,"",$EVIDENCE_TYPE,$CASE_NAME/$EVIDENCE_TYPE/${f##*/},$F_MD5SUM" >> $ARCHIVE_DIR/../../inventory.txt
	    fi
	fi	
    else
	echo "Failed on '$f'"
	exit 1
    fi
    done
}

###
# begin
#
if [ -z "$1" ]
    then
    echo " "
    echo "Welcome to the stupid copy script"
    echo " "
    echo "USAGE"
    echo "copy_evidence.sh </path/to/files>"
    echo "You must specify source directory on the command line"
    echo" "
    exit
fi

collect_info
copy_and_log $1
