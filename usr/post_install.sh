#!/bin/sh

SUPRAVIM_REPO='Supravim https://gitlab.com/supraproject/suprastore_repository/-/raw/master/supravim/'
COSMOS_x86_64='Cosmos https://gitlab.com/supraproject/suprastore_repository/-/raw/master/cosmos/'

if [ "$(id -u)" -eq 0 ]; then
	echo "Please do not run this script as root."
	REPO_LIST=/usr/.suprapack/repo.list
	CONFIG=/usr/.suprapack/user.conf
else
	REPO_LIST=$HOME/.local/.suprapack/repo.list
	CONFIG=$HOME/.local/.suprapack/user.conf
	ln -s $HOME/.local/.suprapack $HOME/.config/suprapack 2> /dev/null; true
fi

if [ -f "$REPO_LIST" ]; then
	echo "already existing repo.list skipping..."
	if ! grep -q $SUPRAVIM_REPO $REPO_LIST 2>/dev/null; then
		echo $SUPRAVIM_REPO >> $REPO_LIST
	fi
	if ! grep -q $COSMOS_x86_64 $REPO_LIST 2>/dev/null; then
		echo $COSMOS_x86_64 >> $REPO_LIST
	fi
else
	touch $REPO_LIST
	echo "$COSMOS_x86_64" >> $REPO_LIST
	echo "$SUPRAVIM_REPO" >> $REPO_LIST
fi

if [ -f "$CONFIG" ]; then
	echo "already existing user.conf skipping..."
else
	touch $CONFIG
	echo "is_cached:false" | cat > $CONFIG
fi


# generate PROFILE Files 
if [ "$(id -u)" -eq 0 ]; then
	echo "prefix:/usr" | cat > $CONFIG
else
	if ! grep -q 'source $HOME/.suprapack_profile' $HOME/.profile 2>/dev/null; then
		echo 'source $HOME/.suprapack_profile' >> $HOME/.profile
	fi
	[ -d $HOME/.suprapack ] && mv $HOME/.suprapack $HOME/.local/ 2> /dev/null; true
fi
