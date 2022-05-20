#!/bin/sh

################################################################################
# INIT
################################################################################

sed -i "s/#\s*PasswordAuthentication .*/PasswordAuthentication no/g" /etc/ssh/sshd_config
sed -i 's/root:!/root:*/' /etc/shadow

# Create list of authorized keys
mkdir -p /root/.ssh
if [ -e /ssh_keys/authorized_keys ]; then
  echo "Starting with existing authorized keys"
  cp /ssh_keys/authorized_keys /root/.ssh/.
else
  echo "No existing authorized keys, starting with empty file"
  > /root/.ssh/authorized_keys
fi
chmod go-rwx /root/.ssh/authorized_keys

# Provide SSH_AUTH_KEY_* via environment variable
for item in `env`; do
   case "$item" in
       SSH_AUTH_KEY*)
            ENVVAR=`echo $item | cut -d \= -f 1`
            echo "Adding key $ENVVAR"
            printenv $ENVVAR >> /root/.ssh/authorized_keys
            ;;
   esac
done

# Store the keys if possible
if [ -d /ssh_keys/ ] ; then
  # Using updated authorization keys
  echo "Saving keys for the future"
  cp -u /root/.ssh/authorized_keys /ssh_keys/
else
  echo "Keys not saved for the future"
fi

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
if [ -e /ssh_keys/ssh_host_rsa_key.pub ]; then
  # Copy persistent host keys
  echo "Using existing SSH host keys"
  cp -u /ssh_keys/ssh_host* /etc/ssh/
else
  # Generate host SSH keys
  echo "Generating SSH host keys"
  ssh-keygen -A
  if [ -d /ssh_keys ]; then
    # Store generated keys on persistent volume
    echo "Persisting SSH host keys"
    cp -u /etc/ssh/ssh_host_* /ssh_keys/
  fi
fi

# Generate root SSH key
if [ -e /ssh_keys/id_ed25519.pub ] ; then
  # Copy persistent host keys
  echo "Using existing SSH root keys"
  cp -u /ssh_keys/id* /root/.ssh/.
else
  # Generate host SSH keys
  echo "Generating SSH root keys"
  ssh-keygen -a 100 -t ed25519 -q -N "" -f /root/.ssh/id_ed25519
  if [ -d /ssh_keys ]; then
    # Store generated keys on persistent volume
    echo "Persisting SSH root keys"
    cp -u /root/.ssh/id_ed25519* /ssh_keys/.
  fi
fi

##############################################################################
# Display ssh key if not in server mode
##############################################################################

if [ "$1" != "server" ] ; then
  echo "Please add this ssh key to your server /home/user/.ssh/authorized_keys        "
  echo "================================================================================"
  echo "`cat /root/.ssh/id_*.pub`"
  echo "================================================================================"
fi

################################################################################
# START as SERVER
################################################################################

if [ "$1" == "server" ] ; then
  AUTH=`cat /root/.ssh/authorized_keys`
  if [ -z "$AUTH" ] ; then
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

################################################################################
# START as CLIENT via crontab
################################################################################

if [ "$1" == "client" ] ; then
  exec /usr/sbin/crond -f
fi

################################################################################
# Anything else
################################################################################

if [[ "$1" != "client" && "$1" != "server" ]] ; then
  exec "$1"
fi
