#!/bin/bash

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo"
    echo "Usage: sudo $0 $*"
    exit 1
fi

ln -sf $(dirname $(readlink -f $0))/src/pkg-creator.sh /usr/local/bin/pkg-creator
