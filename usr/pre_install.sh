#!/bin/sh

REPO_LIST=$HOME/.local/.suprapack/repo.list

if grep -q "Cosmos https://gitlab.com/supraproject/suprastore_repository/-/raw/master/cosmos" $REPO_LIST;
then
	echo ''
else
	rm -rf "/tmp/Cosmos_${USER}_list"
	rm -rf "/tmp/Supravim_${USER}_list"
	echo 'Migration to new repo list system'
	echo "Cosmos https://gitlab.com/supraproject/suprastore_repository/-/raw/master/cosmos/" > $REPO_LIST
	echo "Supravim https://gitlab.com/supraproject/suprastore_repository/-/raw/master/supravim/" >> $REPO_LIST
fi

if grep -q 'fpath+=($HOME/.local/share/zsh/site-functions)' ~/.zshrc;
then
	echo ''
else
	sed -i '1i\fpath+=($HOME/.local/share/zsh/site-functions)' ~/.zshrc
fi


which suprapack 2>/dev/null 1>/dev/null
if test $? -eq 0 
then
	echo suprapack is installed
else
	zenity --info --text='first installation of suprapack.\nfor best results, restart your session or use `source ~/.profile`. ' --title=Suprapack 2>/dev/null&
fi
true
