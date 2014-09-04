#!/bin/bash

festival_lib="/usr/lib/festival/"
if [ ! -z $1 ]
then
	festival_lib=$1
fi

for xyz in `cat required`
do
	if ! whereis -b $xyz | cut -d ":" -f 2 | grep $xyz > /dev/null
	then
		echo "Devi avere il programma \"$xyz\"! Installalo!"
		echo "Non posso installare nulla senza quel programma."
		echo "Leggi il README"
		exit 1
	fi
done

if [ ! -d $festival_lib ]
then 
	echo "Cazzone, controlla che hai festival installato!"
	echo "Se e' tutto in regola allora devi modificare la variabile"
	echo "\$festival_lib che trovi dentro di me,"
	echo "ora come ora e' settata ad: $festival_lib"
	echo "Se vuoi puoi passare il path della root di festival direttamente"
	echo "da linea di comando, ad esempio:"
	echo "\# ./install.sh /usr/lib/festival"
	echo "suca"
	exit 1
fi

if ( test $(id -u) != 0) then
	echo "Devi essere r00t frocione!"
	exit 1
fi


if [ ! -f $festival_lib/voices/italian/lp_mbrola/it4/it4.txt ]
then
	echo "E' la prima volta che stai installando xchestival."
	echo "Vedrai che figata!"
	if [ ! -f festival-it.tar.bz2 ] 
	then
		echo "Ora mi prendo le voci italiane di festival."
		wget http://www.freaknet.org/alpt/src/xchestival/files/festival-it.tar.bz2
		echo ""
	fi

	if [ ! -d festival-it/ ] 
	then
		echo "Scompatto il malloppone"
		tar jxvf festival-it.tar.bz2
	fi

	echo "k, ora incomincio a copiare il tutto in $festival_lib"
	echo "5"; sleep 1; echo 4; sleep 1; echo 3; sleep 1; echo 2; sleep 1; echo 1; sleep 1
	echo "Sto copiando!"

	cp -r festival-it/* $festival_lib
fi

echo ""
echo "Ora testo le voci mbrola, se il test da' qualche errore allora devi"
echo "controllare l'installzione  di mbrola e di festival"

printf "(voice_lp_mbrola)\n(SayText \"Ora sto' testando la mia voce sensuale\")\n" | festival --pipe
echo ""

echo "Ora copio gli script in /usr/share/xchestival/"
if [ ! -d /usr/share/xchestival/ ]; then mkdir /usr/share/xchestival/; fi
cp xchestival.sub xchat_speak.pl irssi_speak.pl /usr/share/xchestival/
echo "****** ATTENZIONE ********"
echo "Dal tuo utente fai: "
echo $ cp xchestival.sub '~/.xchat2/'
echo ""
echo "Dal tuo utente fai: "
echo $ cp xchestival.sub ' ~/.irssi/'
echo "****** ATTENZIONE ********"

echo ""

echo "Tutto fatto, ora apri xchat ed usa lo script."
echo "Leggiti il README se non sai cosa fare ^_^"
echo "Enjoy!"
