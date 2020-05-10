ceres-runit
===========

The live config of [runit][runit] on **ceres**, and (to a lesser extent) also
on **selene**.

These scripts weren't necessarily intended to be portable, but they have proven
surprisingly so, as with aforementioned **selene** and also some other more
obscure systems (**arvarnelios**, **io**, ...). Do note that these scripts are
based on *my* needs; that is, I run very lightweight systems, with few services
at all (I only added dbus when BlueZ depended on it, for example). If you need
to run a lot of services, because you want the newest, modern IPC for the most
convoluted desktop environment you can find, because you are looking to port
most of the functionality of systemd, or because you are running
enterprise-grade services, you may need more than what this repository
provides--but don't despair, and feel free to use this as a base.

Use
---

This repository is meant to be rooted at `/etc/runit`. The file paths
`/etc/runit/{1,2,3}` are hard-coded into `runit-init` and need to be present at
precisely that location. The services are under this directory as a matter of
preference, though note that other distributions have different preferred
locations (e.g., `/var/service`).

You will need to adapt the services toward what you need; for example, you will
probably have different network adapter names. Don't worry about moving the
directories; those are symlinks anyway. Just remove the link and use the
`./instantiate.sh` script from inside the `sv` directory, passing it the
desired directory name ("SERVICE-PARAM", where the PARAM is an argument to the
service--e.g., the name of a network device for wpa_supplicant and dhcpcd). To
list all the available templates, run `./instantiate.sh` without arguments. To
make one, just add a hidden directory; the `./run` script (which should import
`functions.bash` can make use of the `param` bash function to retrieve the
value after the dash.

Service Directories
-------------------

The default service directory, for better or worse, is under `sv` in this
repository. Other distributions sometimes like to put it elsewhere (e.g.,
`/var/service`). You can definitely do that if you want, but make sure to
change `2` to reflect that change.

`2` presently also contains some code for changing the service directory;
passing `svdir=foo` on the kernel command line (from the bootloader) will cause
this to start `runsvdir` in `/etc/runit/$svdir`. For an example, see the
`paranoid` directory (send `svdir=paranoid` to your kernel), which starts an
absolutely minimal set of services. Support for this isn't very complete at the
moment.

Hacking
-------

Most of the core functionality is in functions.bash, which is included in all
phases as well as all services so far written. (The file could stand to be
split, but is trivial in size anyway.) It has been carefully documented for
this release; feel free to peruse it.

License
-------

Public domain. See COPYING for details.

[runit]: http://smarden.org/runit/
