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

Rationale
---------

*(Or: Why not systemd?)*

The short of it comes down to three reasons:

- I use hardware far more broken than many other people will tolerate. My old
  Dell Latitude, with the primordial (and now-lost) first runit configuration I
  wrote, from which this is derived, had a bad battery, which the charge
  controller would report dropping from 99% capacity to 0.02% in a single
  poll--yet it would continue running for up to half an hour at 0.02%. The
  Lenovo Thinkpad I use, to this day, has a hardware bug that causes it to go
  into a coma when Linux attempts to suspend to memory. In both cases,
  "reasonable" upstreams generally assume that users want the "bells and
  whistles" of, say, automatically shutting down at low battery, or sleeping
  when the lid is closed by default, both of which I've lost quite a bit of
  work to on these deranged systems. In fact, though I am probably in the
  minority, I prefer to configure these features myself, if ever I have to
  depend on them--not to be surprised by such misfeatures being the default.

- I believe one should know their personal service manager well; it constitutes
  an attack surface, a troubleshooting tool, and something which can (and
  should) be easy to modify to accomodate the idiosyncracies of a platform. In
  places like production-grade servers, I admit that I use systemd units and do
  not mind the platform normalization I can expect there, but it is quite nice
  to be able to turn my laptop into a router or an access point with only one
  shell script (which consists mostly of `sv` calls), or to be confident in the
  list of possibly-running services with a simple `ls`. I don't expect this
  variable and admittedly-fragile level of configurability on those production
  servers, but I can and do use it personally.

- I want these scripts to be educational. An enormous amount of complexity in
  the boot system of moddern systemd services is hidden from the casual and
  curious Linux user, and it can be hard to figure out what _minimal_
  configuration or algorithm is needed to boot up a reasonable userspace (at
  least, compatible with the software they want to use). It took me a long time
  to understand this machinery and distill it into these scripts (and I don't
  claim this is "minimal"), but it serves as a distinct reminder that init need
  not be hard for the sufficiently-motivated student who is willing to learn
  basic shell sysadmin.

In the end, of course, my reasons are my own; I am not here to "proselytize
runit to the wayward systemd heathens" or any such dogma, but I welcome you to
try it if you'd like, and if you don't like it, that's fine too.

License
-------

Public domain. See COPYING for details.

[runit]: http://smarden.org/runit/
