#!/bin/sh
###
# This script expects to be run as root
#
# Usage: examine.sh <device> <custodian> <system_type> <FTP password>
# Example: examine.sh /dev/sdd1 john t43 
###
# Requirements
#
# plenty of disk space at /data/images and /data/tmp
# --------------------
# required programs:
# --------------------
# dc3dd program installed; should default to dd if not found
# ssdeep
# md5sum
# sha1sum
# clamAV installed
# 
###

# initialize variables
DEVICE=$1
VICTIM=$2
SYSTEM_TYPE=$3
SYSTEM=$2-$3
IMAGE_DIR=/data/images
IMAGE=$SYSTEM.dd
TEMP=/data/tmp/$VICTIM
EXAMINE_DIR=/mnt/examine

# Functions
dd_type () {
    echo "check for dc3dd"
    type "$1" &> /dev/null
}

eventLogs () {
echo "make temp dir"
mkdir -P /tmp/$VICTIM
echo "copy logs"
cp $EXAMINE_DIR/WINDOWS/system32/config/SecEvent.Evt $TEMP/$SYSTEM-SecEvent.Evt
cp $EXAMINE_DIR/WINDOWS/system32/config/SysEvent.Evt $TEMP/$SYSTEM-SysEvent.Evt
cp $EXAMINE_DIR/WINDOWS/system32/config/AppEvent.Evt $TEMP/$SYSTEM-AppEvent.Evt
echo "compress logs"
7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/*.Evt
#echo "ftp logs"
#ncftpput -u infosec -p $4 ir-splunk . $TEMP/*.Evt
    }

archive () {      
    echo "compress the image and associated files"
    7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/$SYSTEM.log $TEMP/$SYSTEM.hlog $IMAGE_DIR/$IMAGE
    }

scanimage () {
    echo "retrieve latest clam defs"
    freshclam
    echo "scan the mounted image"
    clamscan -r --infected --log=$TEMP/$SYSTEM-clam.log $EXAMINE_DIR
    echo "compress the image"
    7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/$SYSTEM-clam.log
    }

hash_files () {
    echo "md5 sum"
    md5deep -r -i 4M  $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/* $EXAMINE_DIR/WINDOWS/system32/* > $TEMP/$VICTIM.md5sums
    echo "sha1 sum"
    sha1deep  -r -i 4M  $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/* $EXAMINE_DIR/WINDOWS/system32/* > $TEMP/$VICTIM.sha1sums
    echo "ssdeep sums"
    ssdeep -r $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/Local\ Settings/Temporary\ Internet\ Files/ $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/Local\ Settings/Temp/   $EXAMINE_DIR/WINDOWS/system32/ > $TEMP/$VICTIM.ssdeep
    7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/$VICTIM.ssdeep $TEMP/$VICTIM.md5sums  $TEMP/$VICTIM.sha1sums
    }

# execute functions
mkdir -p $TEMP
if dd_type dc3dd; then
    echo "capture image using dc3dd"
    dc3dd hash=md5 if=$DEVICE hof=$IMAGE_DIR/$IMAGE log=$TEMP/$SYSTEM.log hlog=$TEMP/$SYSTEM.hlog;
else 
    dd if=$DEVICE of=$IMAGE_DIR/$IMAGE;
fi
echo "mount image"
mount -o ro $IMAGE_DIR/$IMAGE $EXAMINE_DIR
eventLogs  # copy the event logs to ir-splunk
hash_files # create hash of temp and sys32 files
scanimage  # scan the image with ClamAV
umount $EXAMINE_DIR
archive

# echo "clean up"
#
# this section could be a cleanup step, but for now
# I use tmpreaper to keep the temp spaces clean
# 
# rm -rf $TEMP
