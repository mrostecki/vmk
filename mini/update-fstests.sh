#!/bin/sh

# - copy local sources of fstests into the VM root
# - copy the run script
# - set the run script for autorun
#
# usage: $0 [dir]

function die(){ echo "ERROR: $@"; exit 1; }

if [ -z "$1" ]; then
    if [ -f 'runme-config' ]; then
	source ./runme-config
	echo "Update from config path: $gitdir_fstests"
	dir=$gitdir_fstests
    else
	die "no path given and config not found"
    fi
else
    dir="$1"
    echo "Update from path: $dir"
fi


./root-mount || { echo "ERROR: no mount"; exit 1; }

echo "Rsync fstests sources"
sudo rsync -vaxAXPH "$dir/" mnt/root/fstests || die "cannot rsync"
echo "Copy fstests script"
sudo cp run-fstests.sh mnt
echo "Set fstests as autorun"
sudo ln -sf /run-fstests.sh mnt/autorun.sh

./root-umount
