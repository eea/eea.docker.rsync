# Simple rsync container based on alpine

A simple rsync Docker image to easily rsync data within Docker volumes

## Usage

    $ docker run -it --rm -v blobstorage:/data/ eeacms/rsync \
             rsync user@remote.server.domain.or.ip:/var/local/blobs/ /data/
