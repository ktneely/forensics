#!/usr/bin/env python

# From Python Cookbook
# http://my.safaribooksonline.com/book/programming/python/0596001673/files/pythoncook-chp-4-sect-24

# v 1.1 modified the original to fix the sizing bug.  The script linked above
# would calculate size in bytes, regardless of the parameter passed to it.
# essentially does the same thing as 'du --max-depth=X -h <path>'


import os
from os.path import *

class DirSizeError(Exception): pass

def dir_size(start, follow_links=0, start_depth=0, max_depth=0, skip_errs=0):

    # Get a list of all names of files and subdirectories in directory start
    try: dir_list = os.listdir(start)
    except:
        # If start is a directory, we probably have permission problems
        if os.path.isdir(start):
            raise DirSizeError('Cannot list directory %s'%start)
        else:  # otherwise, just re-raise the error so that it propagates
            raise

    total = 0L
    for item in dir_list:
        # Get statistics on each item--file and subdirectory--of start
        path = join(start, item)
        try: stats = os.stat(path)
        except: 
            if not skip_errs:
                raise DirSizeError('Cannot stat %s'%path)
        # The size in bytes is in the seventh item of the stats tuple, so:
        total += stats[6]
        # recursive descent if warranted
        if isdir(path) and (follow_links or not islink(path)):
            bytes = dir_size(path, follow_links, start_depth+1, max_depth)
            total += bytes
            if max_depth and (start_depth < max_depth):
                print_path(path, bytes, units)
    return total

def print_path(path, bytes, units):
    if units == 'k':
        print '%-8ld%s' % (bytes / 1024, path)
    elif units == 'm':
        print '%-5ld%s' % (bytes / 1024 / 1024, path)
    else:
        print '%-11ld%s' % (bytes, path)

def usage (name):
    print "usage: %s [-bkLm] [-d depth] directory [directory...]" % name
    print '\t-b\t\tDisplay in Bytes (default)'
    print '\t-k\t\tDisplay in Kilobytes'
    print '\t-m\t\tDisplay in Megabytes'
    print '\t-L\t\tFollow symbolic links (meaningful on Unix only)'
    print '\t-d, --depth\t# of directories down to print (default = 0)'

if __name__=='__main__':
    # When used as a script:
    import string, sys, getopt

    units = 'b'
    follow_links = 0
    depth = 0

    try:
        opts, args = getopt.getopt(sys.argv[1:], "bkLmd:", ["depth="])
    except getopt.GetoptError:
        usage(sys.argv[0])
        sys.exit(1)

    for o, a in opts:
        if o == '-b': units = 'b'
        elif o == '-k': units = 'k'
        elif o == '-L': follow_links = 1
        elif o == '-m': units = 'm'
        elif o in ('-d', '--depth'):
            try: depth = int(a)
            except:
                print "Not a valid integer: (%s)" % a
                usage(sys.argv[0])
                sys.exit(1)

    if len(args) < 1:
        print "No directories specified"
        usage(sys.argv[0])
        sys.exit(1)
    else:
        paths = args

    for path in paths:
        try: bytes = dir_size(path, follow_links, 0, depth)
        except DirSizeError, x: print "Error:", x
        else: print_path(path, bytes, units)
