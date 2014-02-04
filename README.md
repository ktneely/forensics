Description of the scripts in this directory

General
=======

For the scipts in this directory, where it makes sense (and as I update them), I have devised the following common directory path for the output 

/Data  	       	       		<---- the parent of all your collected data
 |---Forensics			<---- parent of forensics activities
     |---Case Identifier	<---- some number or name for the case
     	 |---images		<---- disk images and raw evidence data
	 |---analysis		<---- output of tools and notes
	 |---malware		<---- discovered malicious code samples
	 |---logs		<---- other supporting logs (e.g. network traffic)
 |---Hashes			<---- various hash databases
     |---NSRL			<---- NSRL data files storage
     |---Malware		<---- malware hash files
 |---Wordlists			<---- dictionaries and password wordlists
 |---Malware			<---- malware samples repository

create_image 
============ 

Create image is a shell script to prompt for
some relevant categorical metadata regarding a physical storage
device.  It takes this information to add to an disk inventory and
create a forensic image of the device to be used for further analysis.

Currently, the script is tailored for Windows bitlocker drives only and requires libbde:  https://code.google.com/p/libbde

Your examination system should be configured to NOT automatically mount devices connected to it.


disk_examine
============

Disk examine is a shell script to create an image and perform initial examination on a disk image.  This is intended to be run against a previously captured drive image in raw (dd) format.

Setup
-----
The script makes certain assumptions about the operating system layout upon which it is run.  If you do not want to conform, you can simply change the relevant parts of the script.  Otherwise, you can make changes so you have the following:

 - multiple 'examine' directories under mnt numbered sequentially (e.g. /mnt/examine1, /mnet/examine2...)
 - a /Data directory  (with a symlink from /data for typos)
 - a /Data/hashes directory that contains white and black list hash files, and also acts as a repository for collected hashes for later analysis

Requirements:
-------------
 - bash
 - plaso (log2timeline)
 - libc 2.15+ (on Debian, you need to use testing repo)
   - add 'deb http://ftp.debian.org/debian testing main' to apt sources
   - run 'apt-get -t testing install libc6-amd64 libc6-dev libc6-dbg'
 - md5deep
 - ssdeep
 - disable automount of connected devices

Optional
--------
These are not strictly required, but highly recommended
 - ClamAV
 - AVG (http://free.avg.com/us-en/download-free-all-product)
 - f-prot (installed under /opt/f-prot)


How it works
------------
This script simply automates a number of tasks you would perform anyway in order to examine a disk image or preserve data for later review or outside consultants at such a time you realize that system you ignored became interesting due to new information.

The functions are in alphabetical order.

Enviro-prep
===========
A laughable script that helps to prepare your environment.

NSRL fetch
==========
