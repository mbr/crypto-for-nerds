#!/bin/sh

set -e

RANDMIXD="/usr/local/bin/randmixd.py"
RANDMIXD_URL="https://raw.github.com/mbr/crypto-for-nerds/master/randmixd.py"
RANDMIXD_SHA256="e45a65aa3f43af185165cd759b28a39c04e1818486b81b9aea3955f28648e4f7"

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

sudo tee /etc/rc.local <<EOF
#!/bin/sh -e
"$RANDMIXD"
EOF

# run the randmix daemon
sudo "$RANDMIXD"

echo 'All good, you can now remove the network cable'
