#!/bin/sh

set -e

RANDMIXD="/usr/local/bin/randmixd.py"
RANDMIXD_URL="https://raw.github.com/mbr/crypto-for-nerds/master/randmixd.py"
RANDMIXD_SHA256="94b3a8e958b7b37b0c3943d521ef8cf8129530f2773e042d5aaa31a0ebace300"

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

if grep "$RANDMIXD" /etc/rc.local; then
  # add randmixd to rc.local, because sysv5 init is a nightmare
  echo '$RANDMIXD' | sudo tee -a /etc/rc.local
fi;

# run the randmix daemon
echo "$RANDMIX"

echo 'All good, you can now remove the network cable'
