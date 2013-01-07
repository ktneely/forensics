#!/bin/sh
###
# Usage: examine.sh <device> <custodian> <system_type> <destination>
# Example: examine.sh /dev/sdd1 ktneely t43 /mnt/images
###

# initialize variables
DEVICE=$1
VICTIM=$2
SYSTEM_TYPE=$3
SYSTEM=$2-$3
IMAGE_DIR=$4
IMAGE=$SYSTEM.dd
TEMP=/tmp/$VICTIM
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
echo "ftp logs"
ncftpput -u infosec -p 's3cur!ty' ir-splunk . $TEMP/*.Evt
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
hash_files # create hash of temp and ys32 files
scanimage  # scan the image with ClamAV
umount $EXAMINE_DIR
archive

echo "clean up"

# rm -rf $TEMP
