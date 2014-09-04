#!/bin/bash

yesorno() {
	echo "Press Enter to continue or write \"no\" to skip $1"
	printf "> "
	read -r what

	case $what in
		no) return 1 ;;
		''| yes) return 0 ;;
		*) yesorno $@ ;;
	esac
}

	
dstdir=`sed -n '/export CLOSEBRACKET_DIR/ {s/"//g; s/^[^=]*=//p}' ~/.bashrc`

if [ -z "$dstdir" ]; then 
	dstdir="`echo ~/.closebracket`"
fi

SHELL_LIST_FILE="$CLOSEBRACKET_DIR/shells"
biglist=`grep -v "^#\|^$" $SHELL_LIST_FILE`
for d in $biglist
do
	echo Installing on $d
	yesorno
	if [ $? == 1 ]; then continue; fi
	
	ssh $d "mkdir /tmp/closebracket/; mkdir $dstdir/"
	scp -r install.sh install-rshells.sh cb scripts/ shells \
		closebracket.conf file_extensions $d:/tmp/closebracket
	
	ssh $d "cd /tmp/closebracket/; ./install.sh donotask $dstdir &> install.log"

	scp -r $dstdir/shells $d:$dstdir/
done

echo "All done"
