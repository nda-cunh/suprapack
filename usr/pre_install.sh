#!/bin/sh
#
which suprapack 2>/dev/null 1>/dev/null
if test $? -eq 0 
then
	echo suprapack is installed
else
	zenity --info --text='first installation of suprapack.\nfor best results, restart your session or use `source ~/.profile`. ' --title=Suprapack 2>/dev/null&
fi
true
