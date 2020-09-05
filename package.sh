#!/bin/bash
echo "-- Resetting environment"
rm -f *.tgz

echo "-- Generate SHA256 checksums"
shasum --algorithm 256 Dockerfile README.md > SHA256SUMS

# If you have npm production dependencies, uncomment the following line
find -exec shasum --algorithm 256 {} \; >> SHA256SUMS

echo "-- Pack to tar archive"
#TARFILE=`npm pack`
TARFILE='docker-opencv-nodered-${RELEASE_VERSION}.tgz'

echo "-- Add dependent node_modules to archive"
# If you have npm production dependencies, uncomment the following 3 lines
tar --extract --ungzip --file=${TARFILE}
cp -r node_modules ./package
tar --create --gzip --file=${TARFILE} ./package

echo "-- Show SHA265 checksum of package"
shasum --algorithm 256 ${TARFILE} > ${TARFILE}.sha256sums

rm -rf SHA256SUMS package