#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: backup.sh <volume_name>"
    exit 1
fi
if [[ $1 == --help || $1 == -h ]]; then
    echo "Usage: backup.sh <volume_name>"
    exit 0
fi

backup_file=$(date "+backup_$1_%Y%m%d_%H%M%S.tar")
(
    set -x
    docker run -itv "$1:/source_volume" -v "$(pwd):/backup" ubuntu tar -cvf "/backup/${backup_file}" /source_volume
)
echo "$(tput bold)Compressing backup$(tput sgr0)"
xz -v "$backup_file"

