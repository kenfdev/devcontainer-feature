#!/bin/sh
set -e

# The 'install.sh' entrypoint script is always executed as the root user.
#
# These following environment variables are passed in by the dev container CLI.
# These may be useful in instances where the context of the final 
# remoteUser or containerUser is useful.
# For more details, see https://containers.dev/implementors/features#user-env-var
echo "The effective dev container remoteUser is '$_REMOTE_USER'"
echo "The effective dev container remoteUser's home directory is '$_REMOTE_USER_HOME'"

echo "The effective dev container containerUser is '$_CONTAINER_USER'"
echo "The effective dev container containerUser's home directory is '$_CONTAINER_USER_HOME'"

VERSION="2.5.8"

echo "update apt"
apt update

echo "install dependencies"
apt-get install -y make gcc libncursesw5 libncursesw5-dev


echo "Download tig source code"
curl -LO https://github.com/jonas/tig/releases/download/tig-$VERSION/tig-$VERSION.tar.gz
tar -xf tig-$VERSION.tar.gz
cd tig-$VERSION

echo "make tig"
make prefix=$CUSTOMPREFIX
echo "install tig"
make install prefix=$CUSTOMPREFIX
