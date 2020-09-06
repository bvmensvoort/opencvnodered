#!/bin/bash
echo "-- Resetting environment"
rm -f *.tgz

echo "-- Generate SHA256 checksums"
shasum --algorithm 256 Dockerfile README.md > SHA256SUMS

# If you have npm production dependencies, uncomment the following line
find -exec shasum --algorithm 256 {} \; >> SHA256SUMS

echo "-- Pack to tar archive"
TARFILE="docker-opencv-nodered-${RELEASE_VERSION}.tgz"
tar --create --gzip --file=${TARFILE} Dockerfile README.md

echo "-- Show SHA265 checksum of package"
shasum --algorithm 256 ${TARFILE} > ${TARFILE}.sha256sums

rm -rf SHA256SUMS package