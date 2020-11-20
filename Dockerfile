FROM armindocachada/tensorflow2-raspberrypi4:2.3.0-cp35-none-linux_armv7l

# Set opencv version, default currently latest (explicitly numbered)
ARG OPENCV_VERSION=4.5.0
# Set NodeJS source URL
ARG NODEJS_URL=https://deb.nodesource.com/setup_15.x
# Set Node-RED version
ARG NODERED_VERSION=latest
# Version specific opencv build flags, https://github.com/opencv/opencv/blob/4.4.0/CMakeLists.txt & module disables
# Optionally set them as "-D BUILD_OPTION=ON -D BUILD_opencv_module=OFF"
ARG ADDITIONAL_BUILD_FLAGS
# Used for Python dependencies.
RUN export LANG=C.UTF-8

RUN echo \
    OPENCV_VERSION=${OPENCV_VERSION} -- \
    NODEJS_URL=${NODEJS_URL} -- \
    NODERED_VERSION=${NODERED_VERSION} -- \
    ADDITIONAL_BUILD_FLAGS=${ADDITIONAL_BUILD_FLAGS}

# Install dependencies for opencv
RUN apt-get update && \
    apt-get -y upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install unzip build-essential && \
    apt-get -y install libjpeg-dev libpng-dev libtiff-dev && \
    apt-get -y install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev && \
    apt-get -y install libxvidcore-dev libx264-dev && \
    apt-get -y install python3-dev && \
    apt-get -y install libgtk2.0-dev && \
    apt-get -y install cmake

# Build OpenCV
RUN mkdir /opencv && \
    cd /opencv && \
    wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
    wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip && \
    unzip opencv.zip && \
    unzip opencv_contrib.zip && \
    mv opencv_contrib-${OPENCV_VERSION} opencv_contrib && \
    mkdir build && \
    cd build && \    
    cmake \
      -D OPENCV_GENERATE_PKGCONFIG=ON \
      -D ENABLE_NEON=ON \
      -D ENABLE_VFPV3=ON \
      -D OPENCV_ENABLE_NONFREE=ON \
      -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D OPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules \
      -D WITH_FFMPEG=ON \
      -D WITH_TBB=ON \
      -D WITH_GTK=ON \
      -D WITH_V4L=ON \
      -D WITH_OPENGL=ON \
      -D WITH_CUBLAS=ON \
      -DWITH_QT=OFF \
      -DCUDA_NVCC_FLAGS="-D_FORCE_INLINES" \
        --prefix=/usr \
        --extra-version='1~16.04.york0' \
        --toolchain=hardened \
        --libdir=/usr/lib/x86_64-linux-gnu \
        --incdir=/usr/include/x86_64-linux-gnu \
        --arch=amd64 \
        --enable-gpl \
        --disable-stripping \
        --enable-avresample \
        --disable-filter=resample \
        --enable-avisynth \
        --enable-gnutls \
        --enable-ladspa \
        --enable-libaom \
        --enable-libass \
        --enable-libbluray \
        --enable-libbs2b \
        --enable-libcaca \
        --enable-libcdio \
        --enable-libcodec2 \
        --enable-libflite \
        --enable-libfontconfig \
        --enable-libfreetype \
        --enable-libfribidi \
        --enable-libgme \
        --enable-libgsm \
        --enable-libjack \
        --enable-libmp3lame \
        --enable-libmysofa \
        --enable-libopenjpeg \
        --enable-libopenmpt \
        --enable-libopus \
        --enable-libpulse \
        --enable-librsvg \
        --enable-librubberband \
        --enable-libshine \
        --enable-libsnappy \
        --enable-libsoxr \
        --enable-libspeex \
        --enable-libssh \
        --enable-libtheora \
        --enable-libtwolame \
        --enable-libvidstab \
        --enable-libvorbis \
        --enable-libvpx \
        --enable-libwavpack \
        --enable-libwebp \
        --enable-libx265 \
        --enable-libxml2 \
        --enable-libxvid \
        --enable-libzmq \
        --enable-libzvbi \
        --enable-lv2 \
        --enable-omx \
        --enable-openal \
        --enable-opengl \
        --enable-sdl2 \
        --enable-libdc1394 \
        --enable-libdrm \
        --enable-libiec61883 \
        --enable-chromaprint \
        --enable-frei0r \
        --enable-libopencv \
        --enable-libx264 \
        --enable-shared \
      ${ADDITIONAL_BUILD_FLAGS} \
      ../opencv-${OPENCV_VERSION} && \
    make -j4 && \
    make install && \
    ldconfig
    #rm -fr /opencv/opencv* && \
    #rm -fr /opencv/${OPENCV_VERSION}.zip

RUN export READTHEDOCS=True && pip3 install picamera[array]
RUN pip3 install matplotlib && apt-get -y install python3-tk

# Setup Node-Red
RUN export PKG_CONFIG_OPENCV4=1 && \
    apt-get install -y curl && \
    curl -sL ${NODEJS_URL} | bash - && \
    apt-get install -y nodejs && \
    node -v && \
    npm -v && \
    # /usr/src/node-red: Home directory for Node-RED application source code.
    # /data: User data directory, contains flows, config and nodes.
    mkdir -p /usr/src/node-red /data && \
    cd /usr/src/node-red && \
    npm install node-red@${NODERED_VERSION} && \
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