#!/bin/sh

SUPRAVIM_REPO='Supravim https://gitlab.com/supraproject/suprastore_repository/-/raw/plugin-supravim/'
COSMOS_x86_64='Cosmos https://gitlab.com/supraproject/suprastore_repository/-/raw/master/'

REPO_LIST=$HOME/.local/.suprapack/repo.list
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
	echo $COSMOS_x86_64 >> $REPO_LIST
	echo $SUPRAVIM_REPO >> $REPO_LIST
fi

CONFIG=$HOME/.local/.suprapack/user.conf
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
if ! grep -q 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/.local/lib"' $HOME/.profile 2>/dev/null; then
	echo 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/.local/lib"' >> $HOME/.profile
fi
if ! grep -q 'export LIBRARY_PATH="$LIBRARY_PATH:$HOME/.local/lib"' $HOME/.profile 2>/dev/null; then
	echo 'export LIBRARY_PATH="$LIBRARY_PATH:$HOME/.local/lib"' >> $HOME/.profile
fi
if ! grep -q 'export C_INCLUDE_PATH="$C_INCLUDE_PATH:$HOME/.local/include"' $HOME/.profile 2>/dev/null; then
	echo 'export C_INCLUDE_PATH="$C_INCLUDE_PATH:$HOME/.local/include"' >> $HOME/.profile
fi
if ! grep -q 'export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:$HOME/.local/include"' $HOME/.profile 2>/dev/null; then
	echo 'export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:$HOME/.local/include"' >> $HOME/.profile
fi
if ! grep -q 'export GSETTINGS_SCHEMA_DIR=$HOME/.local/share/glib-2.0/schemas/' $HOME/.profile 2>/dev/null; then
	echo 'export GSETTINGS_SCHEMA_DIR=$HOME/.local/share/glib-2.0/schemas/' >> $HOME/.profile
fi


if ! grep -q "export fpath=($HOME/.local/bin \$fpath)" $HOME/.profile 2>/dev/null; then
	echo "export fpath=($HOME/.local/bin \$fpath)" >> $HOME/.profile
fi

[ -d $HOME/.suprapack ] && mv $HOME/.suprapack $HOME/.local/ 2> /dev/null; true
