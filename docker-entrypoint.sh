#!/bin/sh

################################################################################
# INIT
################################################################################

mkdir -p /root/.ssh
> /root/.ssh/authorized_keys
chmod go-rwx /root/.ssh/authorized_keys
sed -i "s/.*PasswordAuthentication .*/PasswordAuthentication no/g" /etc/ssh/sshd_config
sed -i 's/root:!/root:*/' /etc/shadow

if [ "$RSYNC_UID" != "" ] && [ "$RSYNC_GID" != "" ]; then
    # UID and GID provided, create user
    echo "UID and GID provided: $RSYNC_UID and $RSYNC_GID. Creating the user"
    echo "rsyncuser:x:$RSYNC_UID:$RSYNC_GID::/home/rsyncuser:/bin/sh" >> /etc/passwd
    echo "users:x:$RSYNC_GID:rsyncuser" >> /etc/group
    RSYNC_USER=rsyncuser
    RSYNC_GROUP=users
else
    # UID and GID not provided
    echo "UID and GID are NOT provided. Proceeding as the root user."
    RSYNC_USER=root
    RSYNC_GROUP=root
fi

# Provide SSH_AUTH_KEY_* via environment variable
for item in `env`; do
   case "$item" in
       SSH_AUTH_KEY*)
            ENVVAR=`echo $item | cut -d \= -f 1`
            printenv $ENVVAR >> /root/.ssh/authorized_keys
            ;;
   esac
done

# Provide CRON_TASK_* via environment variable
> /etc/crontabs/root
for item in `env`; do
   case "$item" in
       CRON_TASK*)
            ENVVAR=`echo $item | cut -d \= -f 1`
            printenv $ENVVAR >> /etc/crontabs/root
            echo "root" > /etc/crontabs/cron.update
            ;;
   esac
done

# Generate host SSH keys
if [ ! -e /etc/ssh/ssh_host_rsa_key.pub ]; then
  ssh-keygen -A
fi

# Generate root SSH key
if [ ! -e /root/.ssh/id_rsa.pub ]; then
  ssh-keygen -q -N "" -f /root/.ssh/id_rsa
fi

################################################################################
# START as SERVER
################################################################################

if [ "$1" == "server" ]; then
  AUTH=`cat /root/.ssh/authorized_keys`
  if [ -z "$AUTH" ]; then
    echo "=================================================================================="
    echo "ERROR: No SSH_AUTH_KEY provided, you'll not be able to connect to this container. "
    echo "=================================================================================="
    exit 1
  fi

  SSH_PARAMS="-D -e -p ${SSH_PORT:-22} $SSH_PARAMS"
  echo "================================================================================"
  echo "Running: /usr/sbin/sshd $SSH_PARAMS                                             "
  echo "================================================================================"

  su-exec $RSYNC_USER:$RSYNC_GROUP  /usr/sbin/sshd -D $SSH_PARAMS
fi

echo "Please add this ssh key to your server /home/user/.ssh/authorized_keys        "
echo "================================================================================"
echo "`cat /root/.ssh/id_rsa.pub`"
echo "================================================================================"

################################################################################
# START as CLIENT via crontab
################################################################################

if [ "$1" == "client" ]; then
  su-exec $RSYNC_USER:$RSYNC_GROUP  /usr/sbin/crond -f
fi

################################################################################
# Anything else
################################################################################
su-exec $RSYNC_USER:$RSYNC_GROUP "$@"
