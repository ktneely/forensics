#!/bin/sh

# v 0.1
#
# This is meant to prep your environment for the other scripts in this
# repository

check_program () {  # checks is a program exists on the system
    echo "check for existence of $1"
    type "$1" &> /dev/null
}

# create the necessary directories under /Data

echo "This script assumes you have write access to / or /Data"
mkdir -p /Data/Archive
mkdir -p /Data/Forensics
mkdir -p /Data/Hashes/NSRL
mkdir -p /Data/Hashes/Malware
mkdir -p /Data/Malware
mkdir -p /Data/Wordlists


# install some dependencies
if check_program apt-get; then
    sudo apt-get install dc3dd clamav md5deep
elif check_program yum; then
    yum install dc3dd md5deep
fi
