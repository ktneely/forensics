#!/bin/bash

# This script should extract, compile, and install libbde onto a DEFT
# Linux system and mount the bitlocker-encrypted drive.

# DEFT Zero logs in a user with root access and no password.  You may
# need to alter this for other Debian or Ubuntu-based systems.
# Additionally, this script makes certain assumptions regarding device
# names.  For example, at boot, there should only be the target
# system's drive and your USB bootmedia attached.  Once the system
# boots, if you are imaging, attach your target drive, and it should
# be /dev/sdc.

# USAGE
# This file and the libbde source code should be copied to ~/bitlocker/


# Gather information
echo "Enter the recovery key for this device"
read KEY        # save the key as a variable
echo "What is the device name of the bitlocker-encrypted partition? (e.g. /dev/sdb2)"
read PARTITION
echo -e "Would you like to mount a target drive?"
echo -e "You may insert it now."
echo -e "(y/n)"
read ANSWER
if [ "$ANSWER" eq "y" ]
	then 
	echo -e "What is the device name for the target partition? (e.g. /dev/sdc1)"
	read TARGET
else
	ANSWER = n
fi

# Retrieve necessary packages
apt-get -y update  # update package cache
apt-get -y install build-essential fuse libfuse-dev wget # install packages

# Download and decompress libbde source code
cd /tmp
#wget -O libbde-20150204.tar.gz https://github.com/libyal/libbde/releases/download/20150204/libbde-alpha-20150204.tar.gz
wget -O libbde.tar.gz https://github.com/libyal/libbde/releases/download/20160110/libbde-alpha-20160110.tar.gz
tar xzvf /tmp/libbde.tar.gz

# Install libbde 
cd libbde-20160110
./configure     # prepare for compilation
make            # compile
make install    # install for easier pathing
ldconfig        # cache the library

# Mount the bitlocker-encrypted drive to /mnt/raw1, which exists by
# default in DEFT Zero
bdemount -r $KEY $PARTITION /mnt/raw1
if [ -f "/mnt/raw1/bde1" ]
    then
    echo -e "bitlocker-encrypted drive successfully mounted\n"
else
    exit
fi

# Verify that this is the system drive by checking for WINDOWS dir
mount -o ro /mnt/raw1/bde1 /mnt/c
if [ -d "/mnt/c/Windows" ]
    then
    echo -e "Windows system drive successfully mounted\n"
else
    umount /mnt/raw1/bde1
    exit
fi


if [ "$ANSWER" eq "n" ]
    then
    echo -e "Shutting Down...\n"
    echo -e "Any devices mounted during execution remain mounted\n"
    exit
elif [ "$ANSWER" eq "y" ]
    mkdir -p /tmp/target
    wrtblk-disable $TARGET   # disable write-blocking for imaging
    mount $TARGET /mnt/target
    echo -e "Target drive mounted at /mnt/target \n"
else 
    echo -e "Invalid input, must be y or n.  Exiting\n"
    echo -e "segfault\n"
    exit
fi

