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
ARG NODEJS_RELEASE=\=10.19.\*

# Install build tools
ENV TZ=Europe/Amsterdam

# Used for Python dependencies.
ENV LANG=C.UTF-8

# Install OpenCV
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libopencv-dev python3-opencv

RUN python3 -c "import cv2; print(cv2.__version__)"

# Setup Node-Red
RUN export PKG_CONFIG_OPENCV4=1 && \
    apt-get install -y nodejs${NODEJS_RELEASE} npm && \
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
