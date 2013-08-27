#! /bin/bash

# A script to create an image of a drive, stolen from the review_drive script
# 
# TODO
# - create handling for plain, bitlocker, and filevault drives
# 0.1
# Simply a cut and paste from the previous do-everthing script. Probably doesn't work


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
