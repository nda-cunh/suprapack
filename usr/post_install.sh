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

mkdir -p $HOME/.etc

# generate PATH in .profile
echo generate PATH in .profile
if ! grep -q 'export PATH=$PATH:$HOME/.local/bin' $HOME/.profile 2>/dev/null; then
	echo 'export PATH=$PATH:$HOME/.local/bin' >> $HOME/.profile
fi
if ! grep -q 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/.local/lib' $HOME/.profile 2>/dev/null; then
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/.local/lib' >> $HOME/.profile
fi
if ! grep -q 'export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$HOME/.local/share/pkgconfig:$HOME/.local/lib/pkgconfig' $HOME/.profile 2>/dev/null; then
	echo 'export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$HOME/.local/share/pkgconfig:$HOME/.local/lib/pkgconfig' >> $HOME/.profile 2>/dev/null   
fi
if ! grep -q 'export XDG_DATA_DIRS=$XDG_DATA_DIRS:$HOME/.local/share' $HOME/.profile 2>/dev/null; then
	echo 'export XDG_DATA_DIRS=$XDG_DATA_DIRS:$HOME/.local/share' >> $HOME/.profile
fi
if ! grep -q 'export XDG_CONFIG_DIRS=$XDG_CONFIG_DIRS:$HOME/.local/etc' $HOME/.profile 2>/dev/null; then
	echo 'export XDG_CONFIG_DIRS=$XDG_CONFIG_DIRS:$HOME/.local/etc' >> $HOME/.profile
fi
