FROM dkimg/opencv:4.5.0-ubuntu

# Set nodered version, at the moment it is 1.1.3.
ARG NODERED_RELEASE=latest
# Set NodeJS version, at the moment it is 8.10.0~dfsg-2ubuntu0.4
ARG NODEJS_RELEASE=8.10.\*

# Setup Node-Red
RUN export PKG_CONFIG_OPENCV4=1 && \
    apt-get install -y nodejs=${NODEJS_RELEASE} npm && \
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
