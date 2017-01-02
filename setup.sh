#!/bin/bash
set -eu                 # Die on errors and unbound variables
set -o pipefail         # capture fail exit codes in piped commands
IFS=$(printf '\n\t')    # IFS is newline or tab

#Install necessary software
sudo apt install \
            gdal-bin    \
            sqlite3     \
            libspatialite-dev   \
            spatialite-bin      \
            libsqlite3-mod-spatialite   \
            unzip

