#!/bin/bash
###
# This is the InfoSec automated drive examination script v 0.3-beta
# created by Kevin Neely
#
# -= Functionality =-
# Generally, this script performs the following:
# 1) mount the provided disk image at $EXAMINE_DIR, 
# 2) perform some automated analysis, 
# 3) extract potentially relevant data from the image, and
# 4) package everything up in an archive for preservation
#
# -= Version History =-
# 0.3 Change of strategy -- IN PROGRESS
#  - changed from 'sh' to 'bash' for processing
#  - remove the image section to a different script
#  - added log2timeline/plaso
#  - added checks for AVG, f-prot, & Clam (current Clam options require 0.98
#  - Manifest collects more information about tasks
#  - Archive the results to a central location: ARCHIVE_DIR  (IMAGE_DIR)
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
# -= Usage=-
# Usage: review_drive.sh </path/to/mount>
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
    echo -e "\n \n Compress the image and associated files and copy to archival system"
    echo -e "-----------------------------------------\n"
    7z a $IMAGE_DIR/$SYSTEM -mx=9 -w$TEMP $TEMP/Manifest.lst $TEMP/$SYSTEM.log $TEMP/$SYSTEM.hlog $TEMP/$IMAGE
    echo 
    }

check_program () {  # checks is a program exists on the system
    echo "check for existence of $1"
    type "$1" &> /dev/null
}

collect_info () {
    echo "What is the name of the custodian? (def: corpuser)"
    read custodian_name
    CUSTODIAN=${custodian_name:=corpuser}
    echo "What is the system model? (def: laptop)"
    read system_model
    SYSTEM_TYPE=${system_model:=laptop}
    SYSTEM=$CUSTODIAN-$SYSTEM_TYPE
    TEMP=/Data/tmp/$SYSTEM
    }

compare_hash () {
    # compare the hashes against known files.  This needs a re-write and not currently called by the main program
    # compare MD5
    echo -e "MD5sum matches: \n" > $TEMP/hash_match.log >> $TEMP/Manifest.lst
    md5deep -r -i 4M -M ~/malware/analysis/malware.md5sums $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/* $EXAMINE_DIR/WINDOWS/system32/* >> $TEMP/hash_match.log
    # compare SHA1
    # compare SSDEEP
    # if hash_match <> 0 bytes, then
    echo -e "--===HASH MATCH LOG===-- \n"
    cat $TEMP/hash_match.log >> $TEMP/Manifest.lst
#    7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/hash_match.log
    }

create_manifest () {
    echo -e "============================================\n" > $TEMP/Manifest.lst
    echo -e "InfoSec automated examination script\n" >> $TEMP/Manifest.lst
    echo -e "$SYSTEM \t $CASE_NAME \t $(date +%Y%m%d-%T)"  >> $IMAGE_REPOSITORY/inventory.txt
    }

create_timeline () {
    echo -e "\n \n Examine system with plaso to create a timeline"
    echo -e "-------------------------------------------------\n"
    if check_program log2timeline; then
	log2timeline -p $TEMP/$SYSTEM-timeline.zip $EXAMINE_DIR
	echo -e "$SYSTEM-timeline.zip\n" >> $TEMP/Manifest.lst
    else echo "!!log2timeline not found. Please install plaso and log2timeline!!"
# perform some extracts
psort $TEMP/$SYSTEM-timeline.zip "parser is 'FirefoxHistoryParser' and message contains 'url: http' and message contains not 'bookmark'" -w $TEMP/$SYSTEM-firefox_urls.txt
    fi
}

eventLogs_WinXP () {
echo "copy Windows XP event logs"
cp $EXAMINE_DIR/WINDOWS/SYSTEM32/CONFIG/SecEvent.Evt $TEMP/$SYSTEM-SecEvent.Evt
cp $EXAMINE_DIR/WINDOWS/SYSTEM32/CONFIG/SysEvent.Evt $TEMP/$SYSTEM-SysEvent.Evt
cp $EXAMINE_DIR/WINDOWS/SYSTEM32/CONFIG/AppEvent.Evt $TEMP/$SYSTEM-AppEvent.Evt
echo "compress logs"
#7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/*.Evt
# copy logs to an FTP location 
# echo "ftp logs"
# ncftpput -u infosec -p 'password' hostname . $TEMP/*.Evt
    }

eventlogs_Win7 () {   # should consolodate these into one
    echo "Win7"
}


hash_files () {
# This section needs some work.  
# TODO:
  # identify system type
  # create hashes according to OS location (XP, Win7, 8, etc.)
  # compare against known-good (and ignore those)
  # compare against known-bad (and generate an alert)
  # look into some sleuthkit integration for above two
  # place results in a common data storage location
    echo "Record hash values of interesting file system areas" >> $TEMP/Manifest.lst
    if check_program md5deep; then
	echo "create md5 sums"  >> $TEMP/Manifest.lst
	echo "---------------" >> $TEMP/Manifest.lst
	md5deep -r -i 4M $EXAMINE_DIR/Windows/System32/* > $TEMP/$SYSTEM.md5sums
    else echo "!!md5deep not found, please install!!"
#   md5deep -r -i 4M  $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/* $EXAMINE_DIR/WINDOWS/system32/* > $TEMP/$SYSTEM.md5sums
    echo "md5 sums written to $SYSTEM.MD5SUMS"  >> $TEMP/Manifest.lst
    echo "sha1 sums" >> $TEMP/Manifest.lst
#    sha1deep  -r -i 4M  $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/* $EXAMINE_DIR/WINDOWS/system32/* > $TEMP/$SYSTEM.sha1sums
#    echo "ssdeep sums" >> $TEMP/Manifest.lst
#    ssdeep -r $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/Local\ Settings/Temporary\ Internet\ Files/ $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/Local\ Settings/Temp/   $EXAMINE_DIR/WINDOWS/system32/ > $TEMP/$SYSTEM.ssdeep
#    7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/$SYSTEM.ssdeep $TEMP/$SYSTEM.md5sums  $TEMP/$SYSTEM.sha1sums
#    cp $TEMP/$SYSTEM.sha1sums /Data/hashes/endpoints
#    cp $TEMP/$SYSTEM.md5sums /Data/hashes/endpoints
#    cp $TEMP/$SYSTEM.ssdeep /Data/hashes/endpoints
    }


mount_image () {
# look for empty 'examine' dir under /mnt
echo "Attempting to mount device $1" >> $TEMP/Manifest.lst
blkid $IMAGE >> $TEMP/Manifest.lst
for (( i = 1 ; i <= 8; i++ ))
do
    EXAMINE_DIR="/mnt/examine$i";
    if find $EXAMINE_DIR -maxdepth 0 -empty | read v;  # find an unused mount point
    then 
	echo "empty examination directory found at /mnt/examine$i";
	echo "$IMAGE"
	mount -o ro,loop $IMAGE /mnt/examine$i; # mount the image read-only
	i=200;   # set i arbitrarily high to break the loop
	echo "Mounted $IMAGE at /mnt/examine$i" >> $TEMP/Manifest.lst
    else 
	echo "Mounting $IMAGE at /mnt/examine$i failed" 
    fi
done
    }


scanimage () {
    echo -e "\n \n Scan the mounted image with available AV scanners" >> $TEMP/Manifest.lst
    echo -e "----------------------------------------------------\n"
    if check_program clamscan; then
	clamscan -r --infected --log=$TEMP/$SYSTEM-clam.log $EXAMINE_DIR
	echo "clamAV scan complete" >> $TEMP/Manifest.lst
    elif check_program avgscan; then
	echo "starting AVG scan" >> $TEMP/Manifest.lst
	avgscan -Hac --report=$TEMP/$SYSTEM-avg.log $EXAMINE_DIR
	echo "AVG scan complete"  >> $TEMP/Manifest.lst
    elif check_program fpscan; then
	echo "starting F-prot scan" >> $TEMP/Manifest.lst
	fpscan --report --adware --applications --output=$TEMP/$SYSTEM-fp.log $EXAMINE_DIR;
	echo "F-prot scan complete"  >> $TEMP/Manifest.lst;
#    echo "compress the logs" >> $TEMP/Manifest.lst
#    7z a $IMAGE_DIR/$SYSTEM -mx=9 $TEMP/$SYSTEM-clam.log $TEMP/$SYSTEM-avg.log $TEMP/$SYSTEM-fp.log
   fi
    }

timeline_review () {
# TODO
# extract common "interesting" information
# ask the examiner for the date & time of interest 
  # extract events around the time of interest
    echo " "
}

###
# begin script
# 
if [ -z "$1" ]
    then
    echo " "
    echo "Welcome to -insert clever acronym here-"
    echo " "
    echo "Generally, this script performs the following:"
    echo "1) mounts the device specified on the command line"
    echo "2) perform some automated analysis, "
    echo "3) extract potentially relevant data from the image, and"
    echo "4) package everything up in an archive for preservation"
    echo " "
    echo -e "Please provide a disk image for analysis.\n"
    echo -e "Usage: review_drive.sh /path/to/raw_image.dd\n"
    exit
fi
# execute functions
IMAGE=$1
echo "collect info"
collect_info 
echo "make temp"
mkdir -p $TEMP
echo "make manifest"
create_manifest
echo "mount image"
mount_image
# eventLogs  # copy the event logs to 
hash_files # create hash of temp and sys32 files
# compare_hash # check generated hashes against known bad files
scanimage  # scan the image with AV scanners
create_timeline # generate timeline of events on system
#timeline_review 
umount $EXAMINE_DIR
#archive

echo "clean up!" 
# currently, this is just a manual imperative; will eventually clean up extraneous files leftover