#!/bin/bash
# Fri Sep 28 13:31:04 CEST 2007
# by (alpt | efphe | eriol | mancausoft)@freaknet.org
# thanks to crash for the projector
#

#### CONFIGURE HERE ####
#HOSTNAME="10.0.0.x"
PORT=8080
INCOMING=~/pkg/mov
PLAYER_CMD="mplayer -nosound"
#### CONFIGURE HERE ####

cd $INCOMING

while [ 0 ]; do
	rm -f $FIFO1 $FIFO2
	if [ ! -z "$tfile" ]; then rm $tfile; fi
	tfile=$(tempfile)
cat <<FOE | nc -n -v -l -p $PORT -q 1 2>> $tfile >> $tfile
<html>
	<head> <title>Sucast v1</title> </head>
	<body>
	<h1>Sucast <a href="http://freaknet.org/alpt/src/misc/sucast/">v1</a></h1>
	<p>Clicca su uno dei link seguenti oppure <br/>
	vai su http://$HOSTNAME:$PORT/http://hostname/path/to/your/streaming.ogg
	<br/>
	Usa ftp su $HOSTNAME per uploadare un file.<br/>
	--
	<br/>
	Click on one of the following links or go to <br/>
	http://$HOSTNAME:$PORT/http://hostname/path/to/your/streaming.ogg<br/>
	Use ftp on $HOSTNAME to upload a file.<br/>
	</p>
$(find ./ | sed -e 's#^.##' | awk '{print $0"__DIVISOR__" $0}'  | sed -e 's/^/<a href="/' -e 's/__DIVISOR__/">/' -e 's#$#</a><br>#')
	</body>
</html>
FOE
	addr=$(cat $tfile | grep 'connect to' | cut -d ' ' -f 6 | sed -e 's/\[//' -e 's/\]//' -e 's/\.//g')
	url=$(cat $tfile | grep GET | cut -d ' ' -f 2 | sed -e 's#^/##' -e 's/%20/ /g')
	if [ -z "$url" ]; then continue; fi

	if [ ! -f "$url" ] && echo $url | grep -vq '://'; then continue; fi

	echo --
	echo addr: $addr url: $url
	echo --

	varpid="PID$addr"
	if [ ! -z "${!varpid}" ]
	then
		kill -9 ${!varpid}
	fi

	$PLAYER_CMD "$url" &> /dev/null &
	sleep 0.1
	eval "$varpid=`pidof mplayer | cut -d ' ' -f 1`"
done
