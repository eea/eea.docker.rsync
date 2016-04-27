# Simple rsync container based on alpine

A simple rsync server/client Docker image to easily rsync data within Docker volumes

## Simple Usage

Get files from remote server within a `docker volume`:

    $ docker run --rm -v blobstorage:/data/ eeacms/rsync \
                 rsync -avz user@remote.server.domain.or.ip:/var/local/blobs/ /data/

Get files from `remote server` to a `data container`:

    $ docker run -d --name data -v /data busybox
    $ docker run --rm --volumes-from=data eeacms/rsync \
             rsync -avz user@remote.server.domain.or.ip:/var/local/blobs/ /data/

## Advanced Usage

### Client setup

Start client to pack and sync every night:

    $ docker run --name=rsync_client -v client_vol_to_sync:/data \
                 -e CRON_TASK_1="0 1 * * * /data/pack-db.sh" \
                 -e CRON_TASK_2="0 3 * * * rsync -e 'ssh -p 2222 -o StrictHostKeyChecking=no' -avz root@foo.bar.com:/data/ /data/" \
             eeacms/rsync client

Copy the client SSH public key printed found in console

### Server setup

Start server on `foo.bar.com`

    # docker run --name=rsync_server -d -p 2222:22 -v server_vol_to_sync:/data \
                 -e SSH_AUTH_KEY="<SSH KEY FROM rsync_client>" \
             eeacms/rsync server

### Verify that it works

Add `test` file on server:

    $ docker exec -it rsync_server sh
      $ touch /data/test

Bring the `file` on client:

    $ docker exec -it rsync_client sh
      $ rsync -e 'ssh -p 2222 -o StrictHostKeyChecking=no' -avz root@foo.bar.com:/data/ /data/
      $ ls -l /data/
