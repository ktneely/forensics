#! /bin/bash

# A script to create an image of a drive, stolen from the review_drive script
# Version 0.2-beta
# TODO
# - create handling for plain, bitlocker, and filevault drives
# 0.2
# - handles unencrypted drives
# - handles bitlocker drives
# - creates hashes of the image and saves it to <IMAGENAME>-hash.log
# 0.1
# Simply a cut and paste from the previous do-everthing script. Probably doesn't work


# Functions
collect_info () {
    echo "What is the original drive device (e.g. /dev/sdc1)"
    read DEVICE
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
    echo "Enter the case identifier. (def: [new_case]"
    read input_case
    CASE_NAME=${input_case:=new_case}
    EXAMINE_DIR=$TEMP/examine
    mkdir -p $EXAMINE_DIR
    echo "Enter the image repository. def: [/Data/Forensics/$CASE_NAME/images]"
    read input_image
    IMAGE_DIR=${input_image:=/Data/Forensics/$CASE_NAME/images}
    echo "What is the decryption key? (enter 'none' for no encryption"
    read DECRYPTION_KEY
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
	echo "$IMAGE";
	if [[ "$DECRYPTION_KEY" == "none" ]];
	    then
	    if check_program dc3dd; then
		dc3dd if=$DEVICE of=$IMAGE_DIR/$IMAGE hash=md5 hash=sha1 hlog=/$IMAGE_DIR/$IMAGE-hash.log 
		else dd if=$DEVICE of=$IMAGE_DIR/$IMAGE
	    fi
	    else
	    bdemount -r $DECRYPTION_KEY $DEVICE $EXAMINE_DIR
	    if check_program dc3dd; then
		dc3dd if=$EXAMINE_DIR/bde1 of=$IMAGE_DIR/$IMAGE hash=md5 hash=sha1 hlog=/$IMAGE_DIR/$IMAGE-hash.log 
		else dd if=$EXAMINE_DIR/bde1 of=$IMAGE_DIR/$IMAGE
	    fi
	fi
	echo "Mounted $IMAGE at /mnt/examine$i" >> $TEMP/Manifest.lst
	i=200;   # set i arbitrarily high to break the loop
    else 
	echo "Mounting $IMAGE at /mnt/examine$i failed" 
    fi
done
    }


# begin main program
collect_info
mount_image
umount /mnt/examine$i
# umount $EXAMINE_DIR
