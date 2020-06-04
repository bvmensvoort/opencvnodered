# OpenCV with Node-RED docker

This Docker has compiled OpenCV from source (currently 4.3.0).
In addition it has Node-RED (1.10) with the OpenCV node installed.

Example command to start the docker (see [nodered.org](https://nodered.org/docs/getting-started/docker)):
`docker run -it -p 1880:1880 --name mynodered nodered/node-red`

It should also be possible to connect to OpenCV gui. [How-To](https://hub.docker.com/r/miimiymew/ubuntu18-opencv).