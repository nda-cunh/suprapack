#!/bin/sh

REPO_LIST=$HOME/.suprapack/repo.list
if [ -f "$REPO_LIST" ]; then
	echo "already existing repo.list skipping..."
else
	touch $REPO_LIST
	echo "Cosmos https://gitlab.com/supraproject/suprastore_repository/-/raw/master/" | cat >> $REPO_LIST
	# echo "Elixir https://raw.githubusercontent.com/Strong214356/suprapack-list/master/" | cat >> $REPO_LIST
fi

CONFIG=$HOME/.suprapack/user.conf
if [ -f "$CONFIG" ]; then
	echo "already existing user.conf skipping..."
else
	touch $CONFIG
	echo "is_cached:false" | cat > $CONFIG
fi

# generate PATH in .profile
if ! grep -q 'export PATH=$PATH:$HOME/.local/bin' $HOME/.profile 2>/dev/null; then
	echo 'export PATH=$PATH:$HOME/.local/bin' >> $HOME/.profile
fi
if ! grep -q 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/.local/lib' $HOME/.profile 2>/dev/null; then
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/.local/lib' >> $HOME/.profile
fi
if ! grep -q 'export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$HOME/.local/share/pkgconfig' $HOME/.profile 2>/dev/null; then
	echo 'export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$HOME/.local/share/pkgconfig' >> $HOME/.profile 2>/dev/null   
fi