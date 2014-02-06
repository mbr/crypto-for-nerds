Crypto for nerds
================

This documents is supposed to be an easy to follow guide for best-practices
when using GPG_. The first part is a concise recipe that is easy to follow,
the second part explains why these steps were chosen, allowing any reader to
dig in as deep as he wants to.

Any feedback and comments or suggestions for improvement are *very* welcome.

Steps to prepare a Raspberry Pi
-------------------------------

1. Download a raspbian image from http://www.raspberrypi.org/downloads.
   Possible SHA-1 checksum::

     9d0afbf932ec22e3c29d793693f58b0406bcab86  2014-01-07-wheezy-raspbian.zip

2. Unzip and write to sdcard::

     cd /tmp
     unzip 2014-01-07-wheezy-raspbian.zip
     sudo dd if=2014-01-07-wheezy-raspbian.img of=/dev/sdX bs=4M

3. Boot the SD-card in the Raspberry Pi, **without any network cable plugged
   in.**

4. Login as ``pi``, password ``raspberry``. Set a new password for ``pi``::

     passwd

Reasoning behind advice above
=============================

Why a Raspberry Pi?
-------------------

TBW

A reasonably random RNG on the Pi
---------------------------------

The LRNG (Linux random number generator) isn't perfect[1]_, nor is the hardware
random number generator supplied by Broadcom, as there aren't enough technical
specifications published. The best no-effort bet currently available seems to
be using a combination of both and hoping that at least one lives up to its
security promises[2]_.

rng-tools includes the rngd_, which is sparse on documentation. It will add
entropy to the kernel's own entropy pool, 512 bits every 60 seconds with the
default configuration (which will use /dev/hwrng as the input device) unless
there are already at least 2048 bits available. Since the kernel will itself
generate entropy from events like installing the necessary software, running
GPG_ or entering the passphrase, there should be randomness from both sources
used to generate the gpg-key.

Keep in mind that less entropy is available on a Raspberry Pi. Normally, the
LRNG uses[1]_ events like keyboard input, mouse events, interrupts, network
traffic and disk I/O times from physical harddrives. On the Pi, usually there's
no mouse connected, there are fewer interrupts and we're not operating with a
network connection. The disk I/O part is far less useful when no moving parts
are involved (as is the case with SD-cards), leaving on the keyboard as a
reasonable entropy source.

Offline use
-----------

Not connecting the machine with the "master" key to the internet has numerous
advantages, mainly it's much harder to access the private key from the outside
[3]_. This still means that great
care must be taken that the installed software is not compromised, otherwise
there are many ways to `smuggle out
<http://blog.cr.yp.to/20140205-entropy.html>`_ information about the secret key
- or generate bad keys altogether.


Measured: 2 Minutes with HWRNG, 5+ Minutes without

* Install raspbian
* update, dist-upgrade

echo 'bcm2708_rng' | sudo tee -a /etc/modules
sudo modprobe bcm2708_rng
sudo apt-get install rng-tools
echo HRNGDEVICE=/dev/hwrng | sudo tee -a /etc/default/rng-tools
sudo /etc/init.d/rng-tools restart


test asdasd
-----------

.. _GPG: https://en.wikipedia.org/wiki/GNU_Privacy_Guard
.. _rngd: http://man.he.net/man8/rngd

.. [1] http://www.cs.utk.edu/~dunigan/cns05/AnalysisOfLinuxRNG.pdf -- although
       this paper is fairly old and the kernel has been improved since.
.. [2] Original description for turning on the hwrng:
       http://vk5tu.livejournal.com/43059.html
.. [3] Assuming you're trusting your hardware not to spy on you:
       http://www.spiegel.de/international/world/the-nsa-uses-powerful-toolbox
       -in-effort-to-spy-on-global-networks-a-940969.html
.. [4] OpenBSD is interesting, but `unlikely to be ported <http://marc.
       info/?l=openbsd-misc&m=132788027403910&w=2>`_. FreeBSD seems to be more
       focussed on the speed of random number generation.
