#!/bin/sh

REPO_LIST=$HOME/suprapack/repo.list
#generate REPO_LIST if not exist

if [ -f "$REPO_LIST" ]; then
	echo "already existing repo.list skipping..."
else
	touch $REPO_LIST
	echo "Cosmos https://gitlab.com/supraproject/suprastore_repository/-/raw/master/" | cat >> $REPO_LIST
	# echo "Elixir https://raw.githubusercontent.com/Strong214356/suprapack-list/master/" | cat >> $REPO_LIST
fi

# generate PATH in .profile
if ! grep -q 'export PATH=$PATH:$HOME/.local/bin' $HOME/.profile; then
	echo 'export PATH=$PATH:$HOME/.local/bin' >> $HOME/.profile
fi
if ! grep -q 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/.local/lib' $HOME/.profile; then
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/.local/lib' >> $HOME/.profile
fi
if ! grep -q 'export C_INCLUDE_PATH=$C_INCLUDE_PATH:$HOME/.local/include' $HOME/.profile; then
	echo 'export C_INCLUDE_PATH=$C_INCLUDE_PATH:$HOME/.local/include' >> $HOME/.profile
fi
if ! grep -q 'export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:$HOME/.local/include' $HOME/.profile; then
	echo 'export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:$HOME/.local/include' >> $HOME/.profile
fi
if ! grep -q 'export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$HOME/.local/share/pkgconfig' $HOME/.profile; then
	echo 'export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$HOME/.local/share/pkgconfig' >> $HOME/.profile
fi
