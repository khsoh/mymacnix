#!/usr/bin/env zsh

SCRIPTNAME=$(readlink -f $0)
pushd "$(dirname $SCRIPTNAME)" > /dev/null

# Copy local startup files
echo Copying local startup scripts
sudo cp -f $(dirname $SCRIPTNAME)/bash.local /etc/bash.local
sudo cp -f $(dirname $SCRIPTNAME)/zshrc.local /etc/zshrc.local
sudo chown root:wheel /etc/bash.local
sudo chown root:wheel /etc/zshrc.local

popd >/dev/null
