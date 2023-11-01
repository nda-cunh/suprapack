#!/bin/sh

REPO_LIST=$HOME/suprapack/repo.list

if [ -f "$REPO_LIST" ]; then
	echo "already existing repo.list skipping..."
else
	touch $REPO_LIST
	echo "Cosmos https://gitlab.com/supraproject/suprastore_repository/-/raw/master/" | cat >> $REPO_LIST
	echo "Elixir https://raw.githubusercontent.com/Strong214356/suprapack-list/master/" | cat >> $REPO_LIST
fi
