# Hello world docker action

This Docker has compiled OpenCV from source (currently 4.3.0).
In addition it has Node-RED with the OpenCV node installed.

## Inputs

### `who-to-greet`



## Outputs

### `time`

The time we greeted you.

## Example usage

uses: actions/hello-world-docker-action@v1
with:
  who-to-greet: 'Mona the Octocat'