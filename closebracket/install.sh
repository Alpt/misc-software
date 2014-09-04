#!/bin/bash

install_alias() {
    if grep -q CLOSEBRACKET_DIR $1; then
        echo "* $1 seems to be already configured. It won't be touched."
        return 0
    fi

    echo "* I'm going to append new aliases in your $1 file."
    {   echo 
        echo "#### CLOSEBRACKET ####" 
        echo "export CLOSEBRACKET_DIR=\"$dstdir/\"" 
        echo "alias ]=\"source $dstdir/cb I\"" 
        echo "alias ][=\"source $dstdir/cb II\"" 
        echo "#### CLOSEBRACKET ####" 
    } >> $1
}


if [ "$1" == "donotask" ]
then
	donotask=1
fi

if [ -z "$donotask" ]
then
	while [ -z $dstdir ]
	do
		echo "Insert the installation directory. If you leave the default, everything"
		echo "will be installed under ~/.closebracket/. "
		echo "(just press enter for the default)"
		printf "[$HOME/.closebracket] "

		read -r dstdir
		if [ -z "$dstdir" ]; then 
			dstdir=~/.closebracket
			break
		fi
		if [ ! -d "$dstdir" ]; then
			echo $dstdir isn\'t a valid directory
			dstdir=
			continue
		fi
	done
fi

if [ -z "$dstdir" ]; then 
	dstdir=~/.closebracket
fi

if [ ! -z "$2" ]; then
	dstdir="$2"
fi

echo "* Creating $dstdir"
if [ ! -d "$dstdir" ]; then 
    mkdir "$dstdir"
    mkdir "$dstdir/scripts"
else
    if [ ! -d "$dstdir/scripts" ]; then 
	    mkdir "$dstdir/scripts"
    fi
fi

echo "* Copying files in $dstdir"
cp  cb closebracket.conf file_extensions $dstdir/
cp scripts/* $dstdir/scripts
if [ ! -f $dstdir/shells ]; then
	cp shells $dstdir/
fi

if [ -e ~/.bashrc ]; then
    echo ""
    echo "* You have a ~/.bashrc file."
    if grep -q "alias \]\[=.*/\]\[" ~/.bashrc; then
        echo ""
        echo "*WARNING*"
        echo ""
        echo "You have an old version of closebracket."
        echo "Please, remove the old aliases to have a clean .bashrc."
        echo "Then, rerun the install script or add the following lines"
        echo "manually:"
        echo 
        echo "#### CLOSEBRACKET ####" 
        echo "export CLOSEBRACKET_DIR=\"$dstdir/\"" 
        echo "alias ]=\"source $dstdir/cb I\"" 
        echo "alias ][=\"source $dstdir/cb II\"" 
        echo "#### CLOSEBRACKET ####" 
        echo 
        echo "*WARNING"
        echo ""
    else
	install_alias ~/.bashrc 
    fi
fi

if [ -e ~/.zshrc ]; then
    echo 
    echo "* You have a ~/.zshrc file."
    install_alias ~/.zshrc 
fi

if [ -z "$donotask" ]
then
	echo ""
	echo "Ok, now you should put the list of your remote shells in \"$dstdir/shells\""
	echo "The format is one hostname per line, or if you want user@hostname per line"
	echo "Hit Return when you've finished"
	read -r nothing
	echo ""
	echo ""
	echo "The installation is now complete, restart your shell and"
	echo "Enjoy the speed ^_^"
	echo ""
	echo "PS: If you want to install closebracket in all your remote shells with a"
	echo "single command, use ./install-rshells.sh"
	echo "PPS: If you aren't using an US keyboard, you may find difficult"
	echo "to use the ']' and '][' keys, therefore define two alias in"
	echo "your ~/.bashrc"
fi
