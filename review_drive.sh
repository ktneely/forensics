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
#  - re-worked the directory structure
#  - added some supporting documentation created at run-time
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

# ingest the command line
IMAGE=$1


# Functions    

archive () {      
    echo -e "\n \n Compress the image and associated files and copy to archival system"
    echo -e "-----------------------------------------\n"
    7z a $IMAGE_DIR/$SYSTEM -mx=9 -w$TEMP $ANALYSIS_DIR/Manifest.lst $ANALYSIS_DIR/$SYSTEM.log $ANALYSIS_DIR/$SYSTEM.hlog $ANALYSIS_DIR/$IMAGE
    echo 
    }

check_program () {  # checks is a program exists on the system
    echo "check for existence of $1"
    type "$1" &> /dev/null
}

collect_info () {
    echo "Enter the case identifier. (def: [new_case]"
    read input_case
    CASE_NAME=${input_case:=new_case}
    echo "What is the name of the custodian? (def: corpuser)"
    read custodian_name
    CUSTODIAN=${custodian_name:=corpuser}
    echo "What is the system model? (def: laptop)"
    read system_model
    SYSTEM_TYPE=${system_model:=laptop}
    SYSTEM=$CUSTODIAN-$SYSTEM_TYPE
    TEMP=/Data/tmp/$SYSTEM
    echo "What directory should be used for storing the forensics ouput? (def: /Data/Forensics/$CASE_NAME)"
    read root_dir
    FORENSICS_DIR=${root_dir:=/Data/Forensics/$CASE_NAME}
    ANALYSIS_DIR=$FORENSICS_DIR/analysis
    echo "What is the approximate date/time of interest?  YYYY-MM-DD HH:MM:SS"
    read event_time
    }

compare_hash () {
    # compare the hashes against known files.  This needs a re-write and not currently called by the main program
    # compare MD5
    echo "checking for md5deep matches"
    echo -e "MD5sum matches: \n" > $ANALYSIS_DIR/hash_match.log >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
    md5deep -r -i 4M -M ~/malware/analysis/malware.md5sums $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/* $EXAMINE_DIR/WINDOWS/system32/* >> $ANALYSIS_DIR/hash_match.log
    # compare SHA1
    # compare SSDEEP
    # if hash_match <> 0 bytes, then
    echo -e "--===HASH MATCH LOG===-- \n"
    cat $ANALYSIS_DIR/hash_match.log >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
#    7z a $IMAGE_DIR/$SYSTEM -mx=9 $ANALYSIS_DIR/hash_match.log
    }

create_docs () {
    echo -e "============================================\n" > $ANALYSIS_DIR/$SYSTEM-Manifest.lst
    echo -e "InfoSec automated examination script\n" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
    echo -e "$SYSTEM \t $CASE_NAME \t $(date +%Y%m%d-%T)" >> $FORENSICS_DIR/../inventory.txt
    echo -e "Disk examination directory structure: \n"  > $FORENSICS_DIR/Readme.txt
    echo -e " |---./			<---- parent dir" >> $FORENSICS_DIR/Readme.txt
    echo -e "     |---$CASE_NAME	<---- case/incident identifier" >> $FORENSICS_DIR/Readme.txt
    echo -e "     	 |---images		<---- disk images and raw evidence data" >> $FORENSICS_DIR/Readme.txt
    echo -e "	 |---analysis		<---- output of tools and notes" >> $FORENSICS_DIR/Readme.txt
    echo -e "	 |---malware		<---- discovered malicious code samples" >> $FORENSICS_DIR/Readme.txt
    echo -e "	 |---logs		<---- other supporting logs (e.g. network traffic)" >> $FORENSICS_DIR/Readme.txt
    }

create_timeline () {
    echo -e "\n \n Examine system with plaso to create a timeline"
    echo -e "-------------------------------------------------\n"
    if check_program log2timeline; then
	log2timeline -i $ANALYSIS_DIR/$SYSTEM-timeline.zip $IMAGE
	echo -e "$SYSTEM-timeline.zip\n" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
	pinfo $ANALYSIS_DIR/$SYSTEM-timeline.zip >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
	echo -e "\n \n \n" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
    else echo "!!log2timeline not found. Please install plaso and log2timeline!!"
    fi
}

eventLogs_WinXP () {
echo "copy Windows XP event logs"
cp $EXAMINE_DIR/WINDOWS/SYSTEM32/CONFIG/SecEvent.Evt $ANALYSIS_DIR/$SYSTEM-SecEvent.Evt
cp $EXAMINE_DIR/WINDOWS/SYSTEM32/CONFIG/SysEvent.Evt $ANALYSIS_DIR/$SYSTEM-SysEvent.Evt
cp $EXAMINE_DIR/WINDOWS/SYSTEM32/CONFIG/AppEvent.Evt $ANALYSIS_DIR/$SYSTEM-AppEvent.Evt
echo "compress logs"
#7z a $IMAGE_DIR/$SYSTEM -mx=9 $ANALYSIS_DIR/*.Evt
# copy logs to an FTP location 
# echo "ftp logs"
# ncftpput -u infosec -p 'password' hostname . $ANALYSIS_DIR/*.Evt
    }

eventlogs_Win7 () {   # should consolodate these into one
    echo "Win7"
}


hash_files () {
# This section needs some work.  
    echo "Record hash values of interesting file system areas" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
    if check_program md5deep; then
	echo "running md5deep"
	echo -e "\n create md5 sums"  >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
	echo "---------------" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
	md5deep -r -i 4M $EXAMINE_DIR/Windows/System32/* > $ANALYSIS_DIR/$SYSTEM.md5sums
	echo "md5 sums written to $SYSTEM.MD5SUMS"  >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
    else echo "!!md5deep not found, please install!!"
    fi
#   md5deep -r -i 4M  $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/* $EXAMINE_DIR/WINDOWS/system32/* > $ANALYSIS_DIR/$SYSTEM.md5sums
#    echo "sha1 sums" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
#    sha1deep  -r -i 4M  $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/* $EXAMINE_DIR/WINDOWS/system32/* > $ANALYSIS_DIR/$SYSTEM.sha1sums
#    echo "ssdeep sums" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
#    ssdeep -r $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/Local\ Settings/Temporary\ Internet\ Files/ $EXAMINE_DIR/Documents\ and\ Settings/$VICTIM/Local\ Settings/Temp/   $EXAMINE_DIR/WINDOWS/system32/ > $ANALYSIS_DIR/$SYSTEM.ssdeep
#    7z a $IMAGE_DIR/$SYSTEM -mx=9 $ANALYSIS_DIR/$SYSTEM.ssdeep $ANALYSIS_DIR/$SYSTEM.md5sums  $ANALYSIS_DIR/$SYSTEM.sha1sums
#    cp $ANALYSIS_DIR/$SYSTEM.sha1sums /Data/hashes/endpoints
#    cp $ANALYSIS_DIR/$SYSTEM.md5sums /Data/hashes/endpoints
#    cp $ANALYSIS_DIR/$SYSTEM.ssdeep /Data/hashes/endpoints
    }


mount_image () {
# look for empty 'examine' dir under /mnt
echo "Attempting to mount device $1" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
blkid $IMAGE >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
for (( i = 1 ; i <= 8; i++ ))
do
    EXAMINE_DIR="/mnt/examine$i";
    if find $EXAMINE_DIR -maxdepth 0 -empty | read v;  # find an unused mount point
    then 
	echo "empty examination directory found at /mnt/examine$i";
	echo "$IMAGE"
	mount -o ro,loop $IMAGE /mnt/examine$i; # mount the image read-only
	echo "Mounted $IMAGE at /mnt/examine$i" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
	i=200;   # set i arbitrarily high to break the loop
    else 
	echo "Mounting $IMAGE at /mnt/examine$i failed" 
    fi
done
    }


scanimage () {
    echo -e "\n \n Scan the mounted image with available AV scanners" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
    echo -e "----------------------------------------------------\n" >>  $ANALYSIS_DIR/$SYSTEM-Manifest.lst
    echo -e "Creating $ANALYSIS_DIR/malware for storage of infected files\n" >>  $ANALYSIS_DIR/$SYSTEM-Manifest.lst
	mkdir -p $ANALYSIS_DIR/malware
    if check_program clamscan; then
	echo "starting ClamAV scan" >>  $ANALYSIS_DIR/$SYSTEM-Manifest.lst
	clamscan -r --infected --copy=$ANALYSIS_DIR/malware --log=$ANALYSIS_DIR/$SYSTEM-clam.log $EXAMINE_DIR
	cat $ANALYSIS_DIR/$SYSTEM-clam.log >>  $ANALYSIS_DIR/$SYSTEM-Manifest.lst
	echo "clamAV scan complete" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
    elif check_program avgscan; then
	echo "starting AVG scan" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
	avgscan -Hac --report=$ANALYSIS_DIR/$SYSTEM-avg.log $EXAMINE_DIR
	echo "AVG scan complete"  >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
    elif check_program fpscan; then
	echo "starting F-prot scan" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
	/opt/f-prot/fpscan --report --adware --applications -u 3 -s 3 --output=$ANALYSIS_DIR/$SYSTEM-fp.log $EXAMINE_DIR;
	echo "F-prot scan complete"  >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst;
#    echo "compress the logs" >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
#    7z a $IMAGE_DIR/$SYSTEM -mx=9 $ANALYSIS_DIR/$SYSTEM-clam.log $ANALYSIS_DIR/$SYSTEM-avg.log $ANALYSIS_DIR/$SYSTEM-fp.log
   fi
    }

timeline_review () {
# TODO
# extract common "interesting" information
# ask the examiner for the date & time of interest 
  # extract events around the time of interest
    echo " "
    psort --slice "$event_time" --slice_size 10 -o L2tcsv -w $ANALYSIS_DIR/$SYSTEM-timeline_hits.csv $ANALYSIS_DIR/$SYSTEM-timeline.zip >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
    psort -o L2tcsv -w $ANALYSIS_DIR/$SYSTEM-timeline_hits.csv $ANALYSIS_DIR/$SYSTEM-timeline.zip "parser is 'WinJobParser'" |grep -v Google >> $ANALYSIS_DIR/$SYSTEM-Manifest.lst
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
collect_info 
mkdir -p $ANALYSIS_DIR
create_docs # create supporting & descriptive documentation
mount_image
# eventLogs 
# eventLogs_WinXP
hash_files # create hash of temp and sys32 files
# compare_hash # check generated hashes against known bad files
scanimage  # scan the image with AV scanners
create_timeline # generate timeline of events on system
timeline_review 
umount $EXAMINE_DIR
#archive

echo "clean up!" 
# currently, this is just a manual imperative; will eventually clean up extraneous files leftover
