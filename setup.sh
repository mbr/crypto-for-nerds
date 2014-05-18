#!/bin/sh

set -e

RANDMIXD="/usr/local/bin/randmixd.py"
RANDMIXD_URL="https://raw.github.com/mbr/crypto-for-nerds/master/randmixd.py"
RANDMIXD_SHA256="e45a65aa3f43af185165cd759b28a39c04e1818486b81b9aea3955f28648e4f7"
RANDOM_STATE_SERVICE="random"
RANDOM_STATE_INIT="/etc/init.d/$RANDOM_STATE_SERVICE"

# update system
sudo apt-get -y update
sudo apt-get -y dist-upgrade

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

# output the randmix daemon to review
cat "$RANDMIXD"

sudo tee /etc/rc.local << EOF
#!/bin/sh -e
"$RANDMIXD"
EOF

# run the randmix daemon
sudo "$RANDMIXD"

# install random state saving script, taken from
# http://www.comptechdoc.org/os/linux/startupman/linux_surandom.html

sudo tee "$RANDOM_STATE_INIT" <<EOF
# random  Script to snapshot random state and reload it at boot time.
#
# Author:       Theodore Ts'o <tytso@mit.edu>
#
# chkconfig: 2345 20 80
# description: Saves and restores system entropy pool for higher quality \
#              random number generation.

# Source function library.
. /lib/lsb/init-functions

random_seed=/var/run/random-seed

# See how we were called.
case "\$1" in
  start)
  # Carry a random seed from start-up to start-up
  # Load and then save 512 bytes, which is the size of the entropy pool
  if [ -f \$random_seed ]; then
    cat \$random_seed >/dev/urandom
  else
    touch \$random_seed
  fi
  action "Initializing random number generator" /bin/true
  chmod 600 \$random_seed
  dd if=/dev/urandom of=\$random_seed count=1 bs=512 2>/dev/null
  touch /var/lock/subsys/random

  ;;
  stop)
  # Carry a random seed from shut-down to start-up
  # Save 512 bytes, which is the size of the entropy pool
  touch \$random_seed
  chmod 600 \$random_seed
  action "Saving random seed" dd if=/dev/urandom of=\$random_seed count=1 bs=512 2>/dev/null

  rm -f /var/lock/subsys/random
  ;;
  status)
  # this is way overkill, but at least we have some status output...
  if [ -c /dev/random ] ; then
    echo "The random data source exists"
  else
    echo "The random data source is missing"
  fi
  ;;
  restart|reload)
  # do not do anything; this is unreasonable
  :
  ;;
  *)
  # do not advertise unreasonable commands that there is no reason
  # to use with this device
  echo "Usage: random {start|stop|status|restart|reload}"
  exit 1
esac

exit 0
EOF
sudo chmod +x "$RANDOM_STATE_INIT"
sudo update-rc.d "$RANDOM_STATE_SERVICE" defaults

echo 'All good, you can now remove the network cable'
