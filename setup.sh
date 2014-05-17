#!/bin/sh

set -e

RANDMIXD="/usr/local/bin/randmixd.py"
RANDMIXD_URL="https://raw.github.com/mbr/crypto-for-nerds/master/randmixd.py"
RANDMIXD_SHA256="94b3a8e958b7b37b0c3943d521ef8cf8129530f2773e042d5aaa31a0ebace300"
RANDMIXD_INIT="/etc/init.d/randmixd"
RANDMIXD_PIDFILE="/var/run/randmixd.pid"

# update system
sudo apt-get -y update
sudo apt-get -y dist-upgrade
sudo apt-get install -y python-daemon

# download randmix
sudo wget "$RANDMIXD_URL" -O "$RANDMIXD"
sudo chmod +x "$RANDMIXD"

# check if the SHA256 hash of RANDMIXD is correct.
if [ "$(sha256sum $RANDMIXD)" != "$RANDMIXD_SHA256  $RANDMIXD" ]; then
  echo "Checksum mismatch on $RANDMIXD, abandon ship."
  exit 1
fi;

# activate hardware rng module and load it
echo 'bcm2708_rng' | sudo tee -a /etc/modules
sudo modprobe bcm2708_rng

# install init script
sudo tee "$RANDMIXD_INIT" <<EOF
#! /bin/sh

set -e
umask 022

. /lib/lsb/init-functions

case "\$1" in
  start)
  log_daemon_msg "Starting randmixd" "randmixd" || true
  if start-stop-daemon --start --quiet --oknodo --pidfile $RANDMIXD_PIDFILE --exec $RANDMIXD; then
      log_end_msg 0 || true
  else
      log_end_msg 1 || true
  fi
  ;;
  stop)
  log_daemon_msg "Stopping randmixd" "randmixd" || true
  if start-stop-daemon --stop --quiet --oknodo --pidfile $RANDMIXD_PIDFILE; then
      log_end_msg 0 || true
  else
      log_end_msg 1 || true
  fi
  ;;

  *)
  log_action_msg "Usage: $RANDMIXD_INIT {start|stop}" || true
  exit 1
esac

exit 0
EOF

sudo chmod +x "$RANDMIXD_INIT"

# output the randmix daemon to review
cat "$RANDMIXD"

# run the randmix daemon
echo "$RANDMIX"

echo 'All good, you can now remove the network cable'
