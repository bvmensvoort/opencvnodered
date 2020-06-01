FROM ubuntu:18.04

# Set opencv version, default currently latest (explicitly numbered)
ARG OPENCV_RELEASE=4.3.0
# Version specific opencv build flags, https://github.com/opencv/opencv/blob/4.3.0/CMakeLists.txt & module disables
# Optionally set them as "-D BUILD_OPTION=ON -D BUILD_opencv_module=OFF"
ARG ADDITIONAL_BUILD_FLAGS
# Optionally set to any value (1, "true", anything but emptystring) to enable GUI features
ARG ENABLE_IMSHOW_AND_WAITKEY
# Set nodered version, at the moment it is 1.0.6.
ARG NODERED_RELEASE=latest
# Set NodeJS version, at the moment it is 8.10.0~dfsg-2ubuntu0.4
ARG NODEJS_RELEASE=8.10.\*

# Install build tools
RUN apt-get update && \
    apt-get install -y wget unzip build-essential cmake

# Used for Python dependencies.
RUN export LANG=C.UTF-8

# Install dependencies for opencv
RUN apt-get update && \
    apt-get install -y \
        gfortran git \
        libjpeg-dev libtiff-dev libgif-dev \
        libavcodec-dev libavformat-dev libswscale-dev \
        libgtk2.0-dev libcanberra-gtk* \
        libxvidcore-dev libx264-dev libgtk-3-dev \
        libtbb2 libtbb-dev libdc1394-22-dev libv4l-dev \
        libopenblas-dev libatlas-base-dev libblas-dev \
        liblapack-dev libhdf5-dev \
        gcc-arm* protobuf-compiler \
        python3-dev python3-pip \
        python3-setuptools python3-wheel cython python3-numpy python3-scipy python3-matplotlib python3-pywt python3-sklearn python3-sklearn-lib python3-skimage ipython \
        qtbase5-dev qtdeclarative5-dev \
        libaec-dev libblosc-dev libffi-dev libbrotli-dev libboost-all-dev libbz2-dev \
        libgif-dev libopenjp2-7-dev liblcms2-dev libjpeg-dev libjxr-dev liblz4-dev liblzma-dev libpng-dev libsnappy-dev libwebp-dev libzopfli-dev libzstd-dev

# Optional dependencies for GUI features
# Using cv.imshow() or cv.waitkey() requires sharing xserver with docker:
#> running `xhost local:root` on host machine (before docker run); later remove with `xhost -local:root`
#> using following docker run flags: --network=host -e DISPLAY=$DISPLAY
RUN if [ -n "${ENABLE_IMSHOW_AND_WAITKEY}" ]; then apt-get install -y libgtk2.0-dev pkg-config; fi;

# Build latest version of tiff from source
RUN mkdir /tmp/tiff && cd /tmp/tiff && \
    wget -qO- http://download.osgeo.org/libtiff/tiff-4.1.0.tar.gz | tar -xvz -C /tmp/tiff && \
    cd tiff-4.1.0 && \
    ./configure && \
    make && \
    make install && \
    rm -rf /tmp/tiff

# Build OpenCV
RUN mkdir /opencv && \
    cd /opencv && \
    wget https://github.com/opencv/opencv/archive/${OPENCV_RELEASE}.zip -O opencv.zip && \
    wget https://github.com/opencv/opencv_contrib/archive/${OPENCV_RELEASE}.zip -O contrib.zip && \
    unzip opencv.zip && \
    unzip contrib.zip && \
    mkdir build && \
    cd build && \
    cmake \
        -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D OPENCV_EXTRA_MODULES_PATH=../opencv_contrib-${OPENCV_RELEASE}/modules \
        -D BUILD_JAVA=OFF \
        -D WITH_OPENMP=ON \
        -D BUILD_TIFF=ON \
        -D WITH_FFMPEG=ON \
        -D WITH_GSTREAMER=ON \
        -D WITH_TBB=ON \
        -D BUILD_TBB=ON \
        -D BUILD_TESTS=OFF \
        -D WITH_EIGEN=OFF \
        -D WITH_V4L=ON \
        -D WITH_LIBV4L=ON \
        -D WITH_VTK=OFF \
        -D OPENCV_EXTRA_EXE_LINKER_FLAGS=-latomic \
        -D OPENCV_ENABLE_NONFREE=ON \
        -D BUILD_NEW_PYTHON_SUPPORT=ON \
        -D BUILD_opencv_python3=TRUE \
        -D OPENCV_GENERATE_PKGCONFIG=ON \
        -D INSTALL_C_EXAMPLES=OFF \
        -D INSTALL_PYTHON_EXAMPLES=OFF \
        -D BUILD_EXAMPLES=OFF \
        ${ADDITIONAL_BUILD_FLAGS} \
        ../opencv-${OPENCV_RELEASE} && \
    make -j2 && \
    make install && \
    ldconfig

# Setup Node-Red
RUN export PKG_CONFIG_OPENCV4=1 && \
    apt-get install -y nodejs=${NODEJS_RELEASE} npm && \
    # /usr/src/node-red: Home directory for Node-RED application source code.
    # /data: User data directory, contains flows, config and nodes.
    mkdir -p /usr/src/node-red /data && \
    cd /usr/src/node-red && \
    npm install node-red@${NODERED_RELEASE} && \
    cd /data && \
    npm install node-red-contrib-opencv

# Set work directory
WORKDIR /usr/src/node-red

# Env variables of Node-Red
ENV NODE_PATH=/usr/src/node-red/node_modules:/data/node_modules \
    FLOWS=flows.json

# User configuration directory volume
VOLUME ["/data"]

# Expose the listening port of node-red
EXPOSE 1880

ENTRYPOINT ["npm", "start", "--cache", "/data/.npm", "--", "--userDir", "/data"]
