#! /bin/bash

# A script to create an image of a drive, stolen from the review_drive script
# Version 0.3-beta
# TODO
# - create handling for filevault drives
# - make archival optional
# - rename the mount_image function to 
# 0.3
# - Added an archive destination
#     This stores a compressed copy of the image in a specified
#     archive location
# - Archives default to 7zip but fall-back to gzip
# - Inventory file created & updated on archive location
# - Physical drive and logical partition info added to log file
# - Considerably lowered 7z compression level
# - modified many defaults for more streamlined workflow
# 0.2
# - handles unencrypted drives
# - handles bitlocker drives
# - creates hashes of the image and saves it to <IMAGENAME>-hash.log
# 0.1
# Simply a cut and paste of the image creation routines from the previous 
#    do-everthing script. Probably doesn't work


# Functions
collect_info () {
    echo "What is the original drive device (e.g. /dev/sdc1)"
    read DEVICE
    PARTITION=`echo $DEVICE | awk -F'/' '{print $3}'`
    DATE=`date +%Y%m%d-%T`
    echo "What is the name of the custodian? (def: corpuser)"
    read custodian_name
    CUSTODIAN=${custodian_name:=corpuser}
    echo "What is the system model? (def: laptop)"
    read system_model
    SYSTEM_TYPE=${system_model:=laptop}
    SYSTEM=$CUSTODIAN-$SYSTEM_TYPE
    echo "What path should be used for temp space? (def: /Data/tmp)"
    read temp_space
    TEMP=${temp_space:=/Data/tmp/$SYSTEM}
    IMAGE=$SYSTEM.dd
    echo "Enter the case identifier. (def: `date +%Y-%m-%da`)"
    read input_case
    CASE_NAME=${input_case:=`date +%Y-%m-%da`}
    EXAMINE_DIR=$TEMP/examine
    echo "Enter the image repository. (def: [/Data/Forensics/$CASE_NAME/images])"
    read input_image
    IMAGE_DIR=${input_image:=/Data/Forensics/$CASE_NAME/images}
    echo "Enter the location for archives. (def: [/Data/archive/$CASE_NAME])"
    read input_archive
    ARCHIVE_DIR=${input_archive:=/Data/archive/$CASE_NAME}
    echo "What is the decryption key? (def: 'none' for no encryption)"
    read input_key
    DECRYPTION_KEY=${input_key:=none}
    mkdir -p $TEMP
    mkdir -p $IMAGE_DIR
    }


check_program () {  # checks is a program exists on the system
    echo "check for existence of $1"
    type "$1" &> /dev/null
}

# create destination 
create_examine () {
    if [ -d $EXAMINE_DIR ]; then
	echo Examination dir is $EXAMINE_DIR;
	else
	mkdir -p $EXAMINE_DIR;
	echo Examination dir $EXAMINE_DIR has been created;
    fi
}

create_image () {
# look for empty 'examine' dir under /mnt
echo "Attempting to mount device $1" >> $TEMP/Manifest.lst
blkid $IMAGE >> $TEMP/Manifest.lst
for (( i = 1 ; i <= 8; i++ ))
do
    EXAMINE_DIR="/mnt/examine$i";
    if find $EXAMINE_DIR -maxdepth 0 -empty | read v;  # find an unused mount point
    then 
	echo "empty examination directory found at /mnt/examine$i";
	echo "$IMAGE";
	if [[ "$DECRYPTION_KEY" == "none" ]];
	    then
	    if check_program dc3dd; then
		dc3dd if=$DEVICE of=$IMAGE_DIR/$IMAGE hash=md5 hash=sha1 hlog=/$IMAGE_DIR/$IMAGE-info.log 
		else dd if=$DEVICE of=$IMAGE_DIR/$IMAGE
	    fi
	    else
	    bdemount -r $DECRYPTION_KEY $DEVICE $EXAMINE_DIR
	    echo "Mounted $IMAGE at /mnt/examine$i" >> $TEMP/Manifest.lst
	    if check_program dc3dd; then
		dc3dd if=$EXAMINE_DIR/bde1 of=$IMAGE_DIR/$IMAGE hash=md5 hash=sha1 hlog=/$IMAGE_DIR/$IMAGE-info.log 
		else dd if=$EXAMINE_DIR/bde1 of=$IMAGE_DIR/$IMAGE
	    fi
	fi
	i=200;   # set i arbitrarily high to break the loop
    else 
	echo "Mounting $IMAGE at /mnt/examine$i failed" 
    fi
done
    }

archive () {
# creates a compressed copy of the image for archival purposes
# uses defined $TEMP for temp space then copies to $ARCHIVE_DIR/$SYSTEM.7z
if check_program 7z; then
    7z a -w$TEMP -mx=4 -m0=lzma2 $ARCHIVE_DIR/$SYSTEM.7z $IMAGE_DIR/$IMAGE $IMAGE_DIR/$IMAGE-info.log
    else
    gzip -c $IMAGE_DIR/$IMAGE > $ARCHIVE_DIR/$SYSTEM.gz
fi
}

drive_info () {   # adds physical drive information to the log
echo -e "Logical drive information\n" >> $IMAGE_DIR/$IMAGE-info.log
cat /proc/partitions |egrep "major | $PARTITION" >> $IMAGE_DIR/$IMAGE-info.log
echo -e "\n Physical drive information\n"  >>$IMAGE_DIR/$IMAGE-info.log
hdparm -I $DEVICE >> $IMAGE_DIR/$IMAGE-info.log
}


inventory () {   # adds a line to the inventory file on the archive destination
if [ -f "$ARCHIVE_DIR/../inventory.txt" ]
    then
    echo -e "`date +%Y/%m/%d`,$CASE_NAME,$CUSTODIAN,$SYSTEM_TYPE,$CASE_NAME/$SYSTEM.7z" >> $ARCHIVE_DIR/../inventory.txt
else
    echo -e "Date,Case Number,Custodian,System,File Location" > $ARCHIVE_DIR/../inventory.txt
    echo -e "`date +%Y/%m/%d`,$CASE_NAME,$CUSTODIAN,$SYSTEM_TYPE,$CASE_NAME/$SYSTEM.7z" >> $ARCHIVE_DIR/../inventory.txt
fi
}


# begin main program
collect_info
create_image
drive_info
umount /mnt/examine$i
archive
inventory
