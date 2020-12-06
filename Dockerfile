FROM bvmensvoort/opencvnodered:opencv4.5.0

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
    npm install --save node-red@${NODERED_VERSION} && \
    cd /data
    # npm install --save node-red-contrib-opencv

# Setup opencv4nodejs
RUN export OPENCV_LIB_DIR=/opencv/build/lib && \
    export OPENCV_INCLUDE_DIR=/opencv/build/include && \
    export OPENCV_BIN_DIR=/opencv/build/bin && \
    export OPENCV4NODES_DEBUG_REQUIRE=1 && \
    export OPENCV4NODEJS_DISABLE_AUTOBUILD=1 && \
    ln -s /usr/local/include/opencv4/opencv2/ /usr/local/include/opencv2 && \
    apt-get -y install git && \
    mkdir /opencv4nodejs && cd /opencv4nodejs && \
    git clone https://github.com/justadudewhohacks/opencv4nodejs.git && \
    cd /opencv4nodejs/opencv4nodejs && \
    git fetch origin pull/762/head:pr762 && \
    git checkout pr762 && \
    npm install && \
    npm run build && \
    npm run install && \
    cd /data && \
    npm install --save opencv4nodejs
    
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