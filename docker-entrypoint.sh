#!/bin/sh

################################################################################
# INIT
################################################################################

# Provide SSH AUTHORIZED KEY via environment variable
if [ ! -z "$SSH_AUTH_KEY" ]; then
  mkdir -p /root/.ssh
  echo "$SSH_AUTH_KEY" > /root/.ssh/authorized_keys
  chmod go-rwx /root/.ssh/authorized_keys
  sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
fi

# Provide CRON_TASK via environment variable
echo '' > /etc/crontabs/root
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

  exec /usr/sbin/sshd -D $SSH_PARAMS
fi

echo "Please add this ssh key to your server /home/user/.ssh/authorized_keys        "
echo "================================================================================"
echo "`cat /root/.ssh/id_rsa.pub`"
echo "================================================================================"

################################################################################
# START as CLIENT via crontab
################################################################################

if [ "$1" == "client" ]; then
  exec /usr/sbin/crond -f
fi

################################################################################
# Anything else
################################################################################
exec "$@"
