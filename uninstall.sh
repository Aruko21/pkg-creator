#!/bin/bash

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo"
    echo "Usage: sudo $0 $*"
    exit 1
fi

rm /usr/local/bin/pkg-creator
