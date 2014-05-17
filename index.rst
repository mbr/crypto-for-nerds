Crypto for nerds
================

This documents is supposed to be an easy to follow guide for best-practices
when using GPG_. The first part is a concise recipe that is easy to follow,
the second part explains why these steps were chosen, allowing any reader to
dig in as deep as he wants to.

Any feedback and comments or suggestions for improvement are *very* welcome.
Source for this document is available at
https://github.com/mbr/crypto-for-nerds.

Steps to prepare a Raspberry Pi
-------------------------------

This section is optional, see the explanation below (_`Why a Raspberry Pi? Why
Raspbian?`).

1. Download a raspbian image from http://www.raspberrypi.org/downloads.
   Check the SHA-1 checksum::

     9d0afbf932ec22e3c29d793693f58b0406bcab86  2014-01-07-wheezy-raspbian.zip

2. Unzip and write to an sdcard::

     cd /tmp
     unzip 2014-01-07-wheezy-raspbian.zip
     sudo dd if=2014-01-07-wheezy-raspbian.img of=/dev/sdX bs=4M

3. Boot the SD-card in the Raspberry Pi, with a network cable plugged in.

4. Configure raspbian as usual, remember to set a secure password for the
   ``pi`` user. Disable SSH.

5. Download, verify and run the setup script::

     wget 'http://mbr.github.io/crypto-for-nerds/setup.sh'
     sha1sum setup.sh
     cat setup.sh
     sh -x setup.sh

5. **Unplug** the network cable (or remove the WiFi module).

Reasoning behind advice above
=============================

On using a master key
---------------------

There is always a chance that a machine can be compromised and hostile software
be installed. At that point, any security provided by encryption is essentially
void: GPG cannot use a `key-agreement protocol <https://en.wikipedia.org/wiki
/Key-agreement_protocol>`_ and therefore cannot use `perfect forward secrecy
<https://en.wikipedia.org/wiki/Key-agreement_protocol>`_ either. As a result,
if an attacker gains access to the private key once, all previous messages
encrypted using the public key are decryptable for him and he can forge
signatures at will.

This also means that any signatures on the public key -- the Web of Trust --
would also be worthless, even harmful; a new key would have to be generated and
signed all over and the old one speedily revoked.

A solution is to use a key without expiration as a master key and creating
subkeys with limited time validity for every day use. This limits the amount
of damage a key compromization can cause, provided the master key is stored
securely [6]_.

Why a Raspberry Pi? Why Raspbian?
---------------------------------

The section above describes the structure of the setup, a master key is only
used to generate subkeys for every day use, while collecting signatures from
others. Security is greatly enhanced by storing the master key on a seperate
device without direct internet access that is only used for key generation (see
`air gap <http://en.wikipedia.org/wiki/Air_gap_(networking)>`_). While it is
not impossible for a determined attacker to gain access to these, it is much
harder than "just" compromising a machine with network access.

The Raspberry Pi is chosen here as a pragmatic choice - it is small, cheap,
readily available and should provide a good increase in security [7]_.
Raspbian is chosen mainly because it is a wide-spread distro for the Pi.
A custom made distro just for this document would make things easier, but also
require more trust on the users side. When downloading raspbian, be sure to
check the official download site to see if the SHA1-Checksum for the image
matches.

Any enhancements made to the setup are made through a shell script that can be
reviewed before running on the Pi.

Note that it is possible to eschew the Pi and simply store the master key on
your everyday computer. This is still a decent setup and a more pragmatic
choice. Just ignore all steps from the _`Steps to prepare a Raspberry Pi`
section.

A reasonably random RNG on the Pi
---------------------------------

The LRNG (Linux random number generator) isn't perfect (see [1]_ and the newer
[5]_), nor is the hardware random number generator supplied by Broadcom, as
there aren't enough technical specifications published. The best no-effort bet
currently available seems to be using a combination of both and hoping that at
least one lives up to its security promises [2]_.

rng-tools includes the rngd_, which is sparse on documentation. It will add
entropy to the kernel's own entropy pool, 512 bits every 60 seconds with the
default configuration (which will use /dev/hwrng as the input device) unless
there are already at least 2048 bits available. Since the kernel will itself
generate entropy from events like installing the necessary software, running
GPG_ or entering the passphrase, there should be randomness from both sources
used to generate the gpg-key.

There is one drawback by using rngd_: It increases the entropy counter whenever
it feeds entropy from the hardware random number generator into the kernel by
calling ``ioctl(fd, RNDADDENTROPY, ...)``. This makes sense if the hardware
random number generator is somewhat trustworthy trustworthy and increases the
entropy output quite a bit. Since we only want to generate one or two gpg-keys,
we can err on the side of caution and use the supplied script, which will do
the same (feed entropy) without increasing the entropy estimate. According to
[5]_, section 2.3.1 and 3.1, this will guarantee that we are no worse off than
having never used the hardware random number generator at all.

Keep in mind that less entropy is available on a Raspberry Pi. Normally, the
LRNG uses [1]_ events like keyboard input, mouse events, interrupts, network
traffic and disk I/O times from physical harddrives. On the Pi, usually there's
no mouse connected, there are fewer interrupts and we're not operating with a
network connection. The disk I/O part is far less useful when no moving parts
are involved (as is the case with SD-cards), leaving on the keyboard as a
reasonable entropy source. All this makes the process a lot slower.

Saving the random state between reboots
---------------------------------------

Another issue is that the raspberry hardware, especially with almost no
interaction with the outside world (like networking) has very little ways to
gain entropy after booting. For this reason, the state of the LRNG should be
saved and loaded between reboots, at least foiling an attacker that has no
access to the SD card (this is described in the ``Configuration``-section of
the `random(4) <http://man7.org/linux/man-pages/man4/random.4.html>`_
manpage.)

Offline use
-----------

Not connecting the machine with the "master" key to the internet has numerous
advantages, mainly it's much harder to access the private key from the outside
[3]_. This still means that great care must be taken that the installed
software is not compromised, otherwise there are many ways to `smuggle out
<http://blog.cr.yp.to/20140205-entropy.html>`_ information about the secret key
- or generate bad keys altogether.


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
.. [5] http://eprint.iacr.org/2012/251.pdf
.. [6] This is essentially creating a private `certificate authority
       <https://en.wikipedia.org/wiki/Certificate_Authority>`_.
.. [7]  If your actual needs for security are even higher than those presented
        here, you should not be reading this document, but know everything in
        it and more.
