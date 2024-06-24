#!/bin/sh

SUPRAVIM_REPO='Supravim https://gitlab.com/supraproject/suprastore_repository/-/raw/plugin-supravim/'
COSMOS_x86_64='Cosmos https://gitlab.com/supraproject/suprastore_repository/-/raw/master/'

if test $UID -eq 0 ; then
	REPO_LIST=/.suprapack/repo.list
	CONFIG=/.suprapack/user.conf
else
	REPO_LIST=$HOME/.local/.suprapack/repo.list
	CONFIG=$HOME/.local/.suprapack/user.conf
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

mkdir -p $HOME/.etc


# generate PROFILE Files 

echo generate PATH in .profile

if ! grep -q 'source $HOME/.suprapack_profile' $HOME/.profile 2>/dev/null; then
	echo 'source $HOME/.suprapack_profile' >> $HOME/.profile
fi

[ -d $HOME/.suprapack ] && mv $HOME/.suprapack $HOME/.local/ 2> /dev/null; true
