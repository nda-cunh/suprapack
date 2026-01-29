#!/bin/sh

# check if is root
if [ "$(id -u)" -eq 0 ]; then
	echo "Please do not run this script as root."
	mkdir -p /usr/.suprapack
	REPO_LIST=/usr/.suprapack/repo.list
else
	if ! grep -q 'fpath+=($HOME/.local/share/zsh/site-functions)' ~/.zshrc; then
		sed -i '1i\fpath+=($HOME/.local/share/zsh/site-functions)' ~/.zshrc
	fi
	mkdir -p $HOME/.local/.suprapack
	REPO_LIST=$HOME/.local/.suprapack/repo.list
fi

if ! grep -q "Cosmos https://gitlab.com/supraproject/suprastore_repository/-/raw/master/cosmos" $REPO_LIST; then
	rm -rf "/tmp/Cosmos_${USER}_list"
	rm -rf "/tmp/Supravim_${USER}_list"
	echo 'Migration to new repo list system'
	echo "Cosmos https://gitlab.com/supraproject/suprastore_repository/-/raw/master/cosmos/" > $REPO_LIST
	echo "Supravim https://gitlab.com/supraproject/suprastore_repository/-/raw/master/supravim/" >> $REPO_LIST
fi

if ! command -v suprapack >/dev/null 2>&1; then
    zenity --info --text='first installation of suprapack.\nfor best results, restart your session or use `source ~/.profile`. ' --title=Suprapack 2>/dev/null &
fi
true
