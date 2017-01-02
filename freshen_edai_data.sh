#!/bin/bash
set -eu                 # Die on errors and unbound variables
set -o pipefail         # capture fail exit codes in piped commands
IFS=$(printf '\n\t')    # IFS is newline or tab

#Where to save files we create
outputdir="."
tempdir="temp"

# The name of our spatialite database
dbfile="edai.sqlite"

# Associative array of data set GUIDs and their descriptions
declare -A data_sets
data_sets["4d8fa46181aa470d809776c57a8ab1f6_0"]="#01 Runways"
data_sets["0c6899de28af447c801231ed7ba7baa6_0"]="#02 MTR Segment"
data_sets["d5c81ec19e0d43748d5bb0a1e36b6341_0"]="#03 Changeover Point"
data_sets["f02750503edb4a69875cb1f744219370_0"]="#04 Route Portion Table"
data_sets["c6a62360338e408cb1512366ad61559e_0"]="#05 Class Airspace"
data_sets["8bf861bb9b414f4ea9f0ff2ca0f1a851_0"]="#06 Route Airspace"
data_sets["3f42ed70dba34ef09a3c03c68ea78d80_0"]="#07 Frequency Table"
data_sets["c9254c171b6741d3a5e494860761443a_0"]="#08 NAVAID Components"
data_sets["3a379be9c3504403907ef6cabd20ea34_0"]="#09 ILS Component"
data_sets["990e238991b44dd08af27d7b43e70b92_0"]="#10 NAVAID System"
data_sets["9dcdee16e66b47d59c17f4dae53f6721_0"]="#11 Instrument Landing System (ILS)"
data_sets["861043a88ff4486c97c3789e7dcdccc6_0"]="#12 Designated Points"
data_sets["ba57404f70184b858d2c929f99f7b40c_0"]="#13 Holding Pattern"
data_sets["6e89f7409c2f486894f5393859232cc9_0"]="#14 Services"
data_sets["8458b1e305ff47ee9e4b840b63990da2_0"]="#15 Radials and Bearings"
data_sets["e747ab91a11045e8b3f8a3efd093d3b5_0"]="#16 Airports"
data_sets["67885972e4e940b2aa6d74024901c561_0"]="#17 Airspace Boundary"
data_sets["826bda9e0b324006a2da8f20ff334190_0"]="#18 EnRoute Information Table"
data_sets["5344a67700d543b582874b2da9c20559_0"]="#19 Notes"
data_sets["dd0d1b726e504137ab3c41b21835d05b_0"]="#20 Special Use Airspace (SUA)"
data_sets["acf64966af5f48a1a40fdbcb31238ba7_0"]="#21 ATS Route"

# Data is also available as .zip, .csv, .kml, .shp, .geojson
# You can add/change extensions to fetch the different types

# For each extension we're interested in
for EXTENSION in zip; do

    # For each GUID in the array
    for GUID in "${!data_sets[@]}"; do

        DESCRIPTION="${data_sets[$GUID]}"
        echo "${GUID} --- ${DESCRIPTION}"
        
        # Update the local file if necessary and make a more readable link to 
        # it if the download succeeds
        wget --timestamping http://ais.faa.opendata.arcgis.com/datasets/${GUID}.${EXTENSION} &&
            ln --force "${GUID}.${EXTENSION}" "${DESCRIPTION}.${EXTENSION}"
    done

done

# This section is specific to shapefile data from the .zip files
# Delete existing data, make a temp directory and unzip data files to it
rm \
    --preserve-root \
    --recursive \
    --force \
    $tempdir
    
mkdir -p $tempdir
unzip -j -u "*.zip" -d $tempdir

#delete any existing database
rm --force $outputdir/eadi.sqlite

# Lump the data into spatialite database
echo "---------- Convert EADI shapefile data into spatialite database"

#GML related environment variables for the conversion
export GML_FETCH_ALL_GEOMETRIES=YES
export GML_SKIP_RESOLVE_ELEMS=NONE

find $tempdir \
  -iname "*.shp" \
  -type f \
  -print \
  -exec ogr2ogr \
    -f SQLite \
    $outputdir/$dbfile \
    {} \
    -explodecollections \
    -update \
    -append \
    -wrapdateline \
    -dsco SPATIALITE=YES \
    -lco SPATIAL_INDEX=YES \
    -lco LAUNDER=NO \
    --config OGR_SQLITE_SYNCHRONOUS OFF \
    --config OGR_SQLITE_CACHE 128 \
    -gt 65536 \
  \;

ogrinfo $dbfile -sql "VACUUM"
