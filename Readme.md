# Simple rsync container based on alpine

A simple rsync server/client Docker image to easily rsync data within Docker volumes

## Simple Usage

Get files from remote server within a `docker volume`:

    $ docker run --rm -v blobstorage:/data/ eeacms/rsync \
             rsync -avzx --numeric-ids user@remote.server.domain.or.ip:/var/local/blobs/ /data/

Get files from `remote server` to a `data container`:

    $ docker run -d --name data -v /data busybox
    $ docker run --rm --volumes-from=data eeacms/rsync \
             rsync -avz user@remote.server.domain.or.ip:/var/local/blobs/ /data/

## Advanced Usage

### Client setup

Start client to pack and sync every night:

    $ docker run --name=rsync_client -v client_vol_to_sync:/data \
                 -e CRON_TASK_1="0 1 * * * /data/pack-db.sh" \
                 -e CRON_TASK_2="0 3 * * * rsync -e 'ssh -p 2222' -aqx --numeric-ids root@foo.bar.com:/data/ /data/" \
             eeacms/rsync client

Copy the client SSH public key printed found in console

or use a second volume to store client ssh keys between restarts, not re-created evvery time

    $ docker run --name=rsync_client -v client_vol_to_sync:/data \
                 -v storage_of_client_ssh_keys:/ssh_keys \
                 -e CRON_TASK_1="0 1 * * * /data/pack-db.sh" \
                 -e CRON_TASK_2="0 3 * * * rsync -e 'ssh -p 2222' -aqx --numeric-ids root@foo.bar.com:/data/ /data/" \
             eeacms/rsync client


### Server setup

Start server on `foo.bar.com`

    # docker run --name=rsync_server -d -p 2222:22 -v server_vol_to_sync:/data \
                 -e SSH_AUTH_KEY_1="<SSH KEY FROM rsync_client>" \
                 -e SSH_AUTH_KEY_n="<SSH KEY FROM rsync_client_n>" \
             eeacms/rsync server

or use a second volume to store client ssh keys between restarts, no need to upload keys every time

    # docker run --name=rsync_server -d -p 2222:22 -v server_vol_to_sync:/data \
                 -v storage_of_client_ssh_keys:/ssh_keys \
                 -e SSH_AUTH_KEY_1="<SSH KEY FROM rsync_client>" \
                 -e SSH_AUTH_KEY_n="<SSH KEY FROM rsync_client_n>" \
             eeacms/rsync server

The keys in the "SSH_AUTH_KEY_n" is appended to the keys in the file "authrozed_keys" in the volume. The resulting file is then used in the container.

### Verify that it works

Add `test` file on server:

    $ docker exec -it rsync_server sh
      $ touch /data/test

Bring the `file` on client:

    $ docker exec -it rsync_client sh
      $ rsync -e 'ssh -p 2222' -avz root@foo.bar.com:/data/ /data/
      $ ls -l /data/
      
### Rsync data between containers in Rancher

0. Request TCP access to port 2222 to an accessible server of environment of the new installation from the source container host server.

1. Start **rsync client** on host from where do you want to migrate data (ex. production). 

    Infrastructures -> Hosts ->  Add Container
    * Select image: eeacms/rsync
    * Command: sh
    * Volumes -> Volumes from: Select source container

2. Open logs from container, copy the ssh key from the message

2. Start **rsync server** on host from where do you want to migrate data (ex. devel). The destination container should be temporarily moved to an accessible server ( if it's not on one ) .

    Infrastructures -> Hosts ->  Add Container
    * Select image: eeacms/rsync
    * Port map -> +(add) : 2222:22
    * Command: server
    * Add environment variable: SSH_AUTH_KEY="<SSH-KEY-FROM-R-CLIENT-ABOVE>"
    * Volumes -> Volumes from: Select destination container


3. Within **rsync client** container from step 1 run:

  ```
    $ rsync -e 'ssh -p 2222' -avz <SOURCE_DUMP_LOCATION> root@<TARGET_HOST_IP_ON_DEVEL>:<DESTINATION_LOCATION>
  ```
  
4. The rsync servers can be deleted, and the destination container can be moved back ( if needed )
