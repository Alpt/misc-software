#!/bin/bash
die() { echo aborting: $@; exit 1; }
echo Downloading dwm-4.5
[ -f dwm-4.5.tar.gz  ] || wget -nv -nc http://www.suckless.org/download/dwm-4.5.tar.gz || die
echo Extracting 
[ ! -d rwm ] || die please remove the rwm/ directory
tar xfz dwm-4.5.tar.gz || die 
mv  dwm-4.5  rwm
cd rwm
echo Downloading dwm-4.5-rwm.patch
[ -f dwm-4.5-rwm.patch ] || wget -nv -nc http://www.freaknet.org/alpt/src/patches/rwm/dwm-4.5-rwm.patch || die
echo Applying patch
patch -p1 < dwm-4.5-rwm.patch || die
echo Compiling
make || die
echo Done, you can use ./run.sh now
