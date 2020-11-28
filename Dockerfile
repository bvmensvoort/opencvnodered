FROM bvmensvoort/opencvnodered:opencv4.5.0

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
    npm run install

RUN cd /data && \
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