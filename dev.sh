#!/usr/bin/env bash

set -ex
DIR=$(cd "$(dirname "$0")"; pwd)
cd $DIR

source .init.sh

yarn dev

