#!/bin/sh
###
# This is the InfoSec automated drive examination script v 0.2
# created by Kevin T. Neely - Junipers Network InfoSec
#
# -= Version History =-
# 0.3 Change of strategy -- IN PROGRESS
#  - remove the image section to a different script
#  - add log2timeline/plaso
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
# Plaso (log2timeline) $git clone https://code.google.com/p/plaso/
# 
###

# Functions
    

archive () {      
    echo "compress the image and associated files"
    7z a $IMAGE_DIR/$SYSTEM -mx=9 -w$TEMP $TEMP/Manifest.lst $TEMP/$SYSTEM.log $TEMP/$SYSTEM.hlog $TEMP/$IMAGE
    }

check_program () {  # checks is a program exists on the system
    echo "check for existence of $1"
    type "$1" &> /dev/null
}

collect_info () {
    echo "What is the name of the custodian?"
    read CUSTODIAN
    echo "What was the system type? (e.g. t420)"
    read SYSTEM_TYPE
    SYSTEM=$CUSTODIAN-$SYSTEM_TYPE
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

create_manifest () {
    echo -e "============================================\n" > $TEMP/Manifest.lst
    echo -e "InfoSec automated examination script\n" >> $TEMP/Manifest.lst
    echo -e "$SYSTEM \t $CASE_NAME \t $(date +%Y%m%d-%T)"  >> $IMAGE_REPOSITORY/inventory.txt
    }

create_timeline () {
    }

eventLogs_WinXP () {
echo "copy Windows XP event logs"
cp $EXAMINE_DIR/WINDOWS/SYSTEM32/CONFIG/SecEvent.Evt $TEMP/$SYSTEM-SecEvent.Evt
cp $EXAMINE_DIR/WINDOWS/SYSTEM32/CONFIG/SysEvent.Evt $TEMP/$SYSTEM-SysEvent.Evt
cp $EXAMINE_DIR/WINDOWS/SYSTEM32/CONFIG/AppEvent.Evt $TEMP/$SYSTEM-AppEvent.Evt
echo "compress logs"
7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/*.Evt
# copy logs to an FTP location 
# echo "ftp logs"
# ncftpput -u infosec -p 'password' hostname . $TEMP/*.Evt
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


scanimage () {
#    echo "retrieve latest clam defs"
#    freshclam
    echo "scan the mounted image with available AV scanners"
    if checkprogram clamscan; then
	clamscan -r --infected --log=$TEMP/$SYSTEM-clam.log $EXAMINE_DIR
    elif check program avgscan; then
	avgscan -Hac --report=$TEMP/$SYSTEM-avg.log $EXAMINE_DIR
    echo "compress the logs"
    7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/$SYSTEM-clam.log $TEMP/$SYSTEM-avg.log
    }


# usage notice
echo "Usage: review_drive.sh /path/to/raw_image.dd"
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
