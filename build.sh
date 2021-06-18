#!/usr/bin/env bash

set -ex
DIR=$(cd "$(dirname "$0")"; pwd)
cd $DIR

source .init.sh

vpdir=docs/.vuepress
pubdir=$vpdir/pub

if [ ! -d "$pubdir" ] ; then
git clone --depth=1 git@github.com:rmw-link/rmw-link.git $pubdir
else
cd $pubdir
git pull -f
cd $DIR
fi

yarn build

rsync -av  --delete --exclude='CNAME' $vpdir/dist/ $pubdir/docs

cd $pubdir
git add .
git commit -m"u"
git push -f
