FROM ubuntu:20.04

# Set opencv version, default currently latest (explicitly numbered)
ARG OPENCV_RELEASE=4.4.0
# Version specific opencv build flags, https://github.com/opencv/opencv/blob/4.4.0/CMakeLists.txt & module disables
# Optionally set them as "-D BUILD_OPTION=ON -D BUILD_opencv_module=OFF"
ARG ADDITIONAL_BUILD_FLAGS
# Optionally set to any value (1, "true", anything but emptystring) to enable GUI features
ARG ENABLE_IMSHOW_AND_WAITKEY
# Set nodered version, at the moment it is 1.1.3.
ARG NODERED_RELEASE=latest
# Set NodeJS version, at the moment it is 10.19.0~dfsg-3ubuntu1
ARG NODEJS_RELEASE=10.19.\*

# Install build tools
ENV TZ=Europe/Amsterdam
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential cmake pkg-config \
    gfortran git \
    libjpeg-dev libpng-dev libtiff-dev \
    libavcodec-dev libavformat-dev libswscale-dev \
    # libgtk2.0-dev 
    libcanberra-gtk* \
    libxvidcore-dev libx264-dev libgtk-3-dev \
    libtbb2 libtbb-dev libdc1394-22-dev libv4l-dev \
    # Hopefully prevent error: Could NOT find BLAS (missing: BLAS_LIBRARIES)
    libopenblas-dev libblas-dev \
    libatlas-base-dev \
    liblapack-dev libhdf5-dev \
    # Hopefully fix error: The C compiler identification is unknown
    gcc-arm* protobuf-compiler \
    # Hopefully fix error: Could NOT find ZLIB (missing: ZLIB_LIBRARY)
    zlib1g-dev \
    python3-dev python3-pip python3-numpy \
    python3-setuptools python3-wheel cython python3-scipy python3-matplotlib python3-pywt python3-sklearn python3-sklearn-lib python3-skimage ipython \
    qtbase5-dev qtdeclarative5-dev \
    libaec-dev libblosc-dev libffi-dev libbrotli-dev libboost-all-dev libbz2-dev \
    libgif-dev libopenjp2-7-dev liblcms2-dev libjpeg-dev libjxr-dev liblz4-dev liblzma-dev libpng-dev libsnappy-dev libwebp-dev libzopfli-dev libzstd-dev \
    libopenexr-dev \    
    openexr \
    libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev

# Download and build OpenCV
RUN mkdir /tmp/opencv_build && cd /tmp/opencv_build && \
    git clone https://github.com/opencv/opencv && \
    git clone https://github.com/opencv/opencv_contrib && \
    if [ -n "${OPENCV_RELEASE}" ]; \
        then \
            cd opencv && \
            git checkout tags/${OPENCV_RELEASE} && \
            cd ../opencv_contrib && \
            git checkout tags/${OPENCV_RELEASE} && \
            cd ..;  \
    fi && \
    cd /tmp/opencv_build/opencv && \
    mkdir -p build && cd build && \
    cmake \
    -D OPENCV_EXTRA_MODULES_PATH=/tmp/opencv_build/opencv_contrib/modules \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D BUILD_EXAMPLES=OFF \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D BUILD_JAVA=OFF \
    -D WITH_OPENMP=ON \
    -D BUILD_TIFF=ON \
    -D WITH_FFMPEG=ON \
    -D WITH_GSTREAMER=ON \
    -D WITH_TBB=ON \
    -D BUILD_TBB=ON \
    -D BUILD_TESTS=OFF \
    -D WITH_EIGEN=ON \
    -D WITH_V4L=ON \
    -D WITH_LIBV4L=ON \
    -D WITH_VTK=OFF \
    -D OPENCV_EXTRA_EXE_LINKER_FLAGS=-latomic \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D INSTALL_C_EXAMPLES=OFF \
    -D INSTALL_PYTHON_EXAMPLES=OFF \
    ${ADDITIONAL_BUILD_FLAGS} \
    .. && \
    make -j2 && \
    make install && \
    pkg-config --modversion opencv4 && \
    python3 -c "import cv2; print(cv2.__version__)"

# Setup Node-Red
RUN export PKG_CONFIG_OPENCV4=1 && \
    if [ -n "${NODEJS_RELEASE}" ]; \
        then apt-get install -y nodejs=${NODEJS_RELEASE} npm; \
        else apt-get install -y nodejs npm; \
    fi && \
    # /usr/src/node-red: Home directory for Node-RED application source code.
    # /data: User data directory, contains flows, config and nodes.
    mkdir -p /usr/src/node-red /data && \
    cd /usr/src/node-red && \
    npm install node-red@${NODERED_RELEASE} && \
    cd /data && \
    npm install --save node-red-contrib-opencv

# Set work directory
WORKDIR /usr/src/node-red/node_modules/node-red

# Env variables of Node-Red
ENV NODE_PATH=/usr/src/node-red/node_modules:/data/node_modules \
    FLOWS=flows.json

# User configuration directory volume
VOLUME ["/data"]

# Expose the listening port of node-red
EXPOSE 1880

ENTRYPOINT ["npm", "start", "--cache", "/data/.npm", "--", "--userDir", "/data"]
