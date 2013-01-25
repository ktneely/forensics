#!/bin/sh
###
# This is the InfoSec automated drive examination script v 0.2
# created by Kevin T. Neely - Junipers Network InfoSec
#
# -= Version History =-
# 0.2 Revisions
#  - added info collection questionnaire
#  - added case name collection
#  - creates an inventory entry in the image repository
#  - added AVG virus scanning
# 0.1 Initial Version
#  - makes image with dc3dd to temp location (if available, else dd)
#  - mounts the image read-only
#  - extracts event logs & FTPs to Splunk server
#  - creates hash values of interesting files
#  - scans drive with clamscan
#  - compresses image and logs into a single file on storage location
#
# Usage: examine.sh <device> <username> <system_type> <destination> <examine_loc>
# Example: examine.sh /dev/sdd1 ktneely t43 /mnt/images examine1
#
# Requirements:
# To run the script, create the following setup on your system:
# Directory structure
# /Data  - minimum 2TB if you will perform multiple acquisitions or
#large drives
# /Data/hashes  - location of your good and bad hash databases
# 
###

# initialize variables
#DEVICE=$1
#VICTIM=$2
#SYSTEM_TYPE=$3
#SYSTEM=$2-$3
#IMAGE_DIR=$4          -replaced by collect_info
#IMAGE=$SYSTEM.dd
#TEMP=/tmp/$VICTIM
# EXAMINE_DIR=/mnt/$5  -replaced by collect_info

# Functions
collect_info () {
#    echo "What is the original drive device (e.g. /dev/sdc1)"
#    read DEVICE
    echo "What is the victim's name?"
    read VICTIM
    echo "What type of system did the drive come from? (e.g. t400)"
    read SYSTEM_TYPE
    SYSTEM=$VICTIM-$SYSTEM_TYPE
    IMAGE=$SYSTEM.dd
    TEMP=/Data/tmp/$SYSTEM
    echo "Enter the case identifier def: [2011-04-07a-crypto]"
    read input_case
    CASE_NAME=${input_case:=2011-04-07a-crypto}
    EXAMINE_DIR=$TEMP/examine
    mkdir -p $EXAMINE_DIR
    echo "Enter the image repository def: [/mnt/stor/Images]"
    read input_image
    IMAGE_REPOSITORY=${input_image:=/mnt/stor/Images/}
    IMAGE_DIR=$IMAGE_REPOSITORY/$CASE_NAME
    mkdir -p $IMAGE_DIR
    }
    
# create_examine is not used at present; the directory is created in temp
create_examine () {
    if [ -d $EXAMINE_DIR ]; then
	echo Examination dir is $EXAMINE_DIR;
	else
	mkdir -p $EXAMINE_DIR;
	echo Examination dir $EXAMINE_DIR has been created;
    fi
}

check_program () {
    echo "check for existence of $1"
    type "$1" &> /dev/null
}

eventLogs () {
#echo "make temp dir"
#mkdir -P /Data/tmp/$SYSTEM
echo "copy logs"
cp $EXAMINE_DIR/WINDOWS/SYSTEM32/CONFIG/SecEvent.Evt $TEMP/$SYSTEM-SecEvent.Evt
cp $EXAMINE_DIR/WINDOWS/SYSTEM32/CONFIG/SysEvent.Evt $TEMP/$SYSTEM-SysEvent.Evt
cp $EXAMINE_DIR/WINDOWS/SYSTEM32/CONFIG/AppEvent.Evt $TEMP/$SYSTEM-AppEvent.Evt
echo "compress logs"
7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/*.Evt
echo "ftp logs"
ncftpput -u infosec -p 's3cur!ty' ir-splunk . $TEMP/*.Evt
    }

create_manifest () {
    echo -e "============================================\n" > $TEMP/Manifest.lst
    echo -e "InfoSec automated examination script\n" >> $TEMP/Manifest.lst
    echo -e "$SYSTEM \t $CASE_NAME \t $(date +%Y%m%d-%T)"  >> $IMAGE_REPOSITORY/inventory.txt
    }

scanimage () {
#    echo "retrieve latest clam defs"
#    freshclam
    echo "scan the mounted image"
    clamscan -r --infected --log=$TEMP/$SYSTEM-clam.log $EXAMINE_DIR
    avgscan -Hac --report=$TEMP/$SYSTEM-avg.log $EXAMINE_DIR
    echo "compress the logs"
    7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/$SYSTEM-clam.log $TEMP/$SYSTEM-avg.log
    }

hash_files () {
    echo "md5 sums"
    md5deep -r -i 4M  $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/* $EXAMINE_DIR/WINDOWS/system32/* > $TEMP/$SYSTEM.md5sums
    echo "sha1 sums"
    sha1deep  -r -i 4M  $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/* $EXAMINE_DIR/WINDOWS/system32/* > $TEMP/$SYSTEM.sha1sums
    echo "ssdeep sums"
    ssdeep -r $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/Local\ Settings/Temporary\ Internet\ Files/ $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/Local\ Settings/Temp/   $EXAMINE_DIR/WINDOWS/system32/ > $TEMP/$SYSTEM.ssdeep
    7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/$SYSTEM.ssdeep $TEMP/$SYSTEM.md5sums  $TEMP/$SYSTEM.sha1sums
    cp $TEMP/$SYSTEM.sha1sums /Data/hashes/endpoints
    cp $TEMP/$SYSTEM.md5sums /Data/hashes/endpoints
    cp $TEMP/$SYSTEM.ssdeep /Data/hashes/endpoints
    }

compare_hash () {
    # compare MD5
    echo -e "MD5sum matches: \n" > $TEMP/hash_match.log
    md5deep -r -i 4M -M ~/malware/analysis/malware.md5sums $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/* $EXAMINE_DIR/WINDOWS/system32/* >> $TEMP/hash_match.log
    # compare SHA1
    # compare SSDEEP
    # if hash_match <> 0 bytes, then
    echo -e "--===HASH MATCH LOG===-- \n"
    cat $TEMP/hash_match.log
    7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/hash_match.log
    }

archive () {      
    echo "compress the image and associated files"
    7z a $IMAGE_DIR/$SYSTEM -mx=9 -w$TEMP $TEMP/Manifest.lst $TEMP/$SYSTEM.log $TEMP/$SYSTEM.hlog $TEMP/$IMAGE
    }

# execute functions
collect_info
# mkdir -p $TEMP
create_manifest
echo "mount image"
mount -o ro $TEMP/$IMAGE $EXAMINE_DIR
eventLogs  # copy the event logs to ir-splunk
hash_files # create hash of temp and sys32 files
compare_hash # check generated hashes against known bad files
scanimage  # scan the image with ClamAV
umount $EXAMINE_DIR
archive

echo "clean up"

# rm -rf $TEMP
