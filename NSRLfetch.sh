#!/bin/sh

echo "This script downloads and prepares the latest version of the NSRL"
echo "USAGE: This script takes two mandatory parameters, the"
echo "major version and minor version of the NSRL."
echo " "
echo "For example, if the version you want to download is 2.35, then the command is"
echo "NSRLfetch.sh 2 35"
echo " "
echo "YOU SHOULD NOT USE THE NSRL WHILE THIS PROCEDURE IS IN PROGRESS"
echo " "

echo "rename the old file"

echo "fetch disk sums"
wget http://www.nsrl.nist.gov/RDS/rds_2.37/RDS_237.iso.txt


echo "fetch DVD image"
# download the file
wget http://www.nsrl.nist.gov/RDS/rds_$1.$2/RDS_$1$2.iso

# verify the integrity of the downloaded file


echo "Extract the new file"
# mount the image

# decompress the file

# unmount the image


echo "indexing the new NSRL database for Autopsy"
hfind -i nsrl-md5 /Data/hashes/NSRL/NSRLFile.txt

# clean up