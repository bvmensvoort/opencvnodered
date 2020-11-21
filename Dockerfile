FROM bvmensvoort/opencvnodered:test

#ENV OPENCV4NODEJS_DISABLE_AUTOBUILD=1
ENV OPENCV_LIB_DIR=/opencv/build/lib
ENV OPENCV_INCLUDE_DIR=/opencv/build/include
ENV OPENCV_BIN_DIR=/opencv/build/bin
ENV OPENCV4NODES_DEBUG_REQUIRE=1
ENV OPENCV4NODEJS_DISABLE_AUTOBUILD=1
RUN ln -s /usr/local/include/opencv4/opencv2/ /usr/local/include/opencv2

RUN echo \
    OPENCV_LIB_DIR=$OPENCV_LIB_DIR \
    OPENCV_INCLUDE_DIR=$OPENCV_INCLUDE_DIR \
    OPENCV_BIN_DIR=$OPENCV_BIN_DIR \
    OPENCV4NODES_DEBUG_REQUIRE=$OPENCV4NODES_DEBUG_REQUIRE \
    OPENCV4NODEJS_DISABLE_AUTOBUILD=$OPENCV4NODEJS_DISABLE_AUTOBUILD

RUN export OPENCV_LIB_DIR=/opencv/build/lib && \
    export OPENCV_INCLUDE_DIR=/opencv/build/include && \
    export OPENCV_BIN_DIR=/opencv/build/bin && \
    export OPENCV4NODES_DEBUG_REQUIRE=1 && \
    export OPENCV4NODEJS_DISABLE_AUTOBUILD=1 && \
    cd /data && \
    npm install npmlog && \
    npm install --save opencv4nodejs && \
    cd node_modules/opencv4nodejs && \
    npm run build

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
