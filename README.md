# Kafka (KRaft) Cluster on Systemd-NSPAWN

This is a tutorial and set of scripts/configurations which will allows you to 
create a three node Kafka cluster using the KRaft (ie: no Zookeeper) protocol
using Systemd-NSPAWN.

It is for development purposes or for use in highly trusted environments. There
are ways to secure this, but discussion of them would obfuscate this document.

## Host Machine

I am running Gentoo (default/linux/amd64/17.1/systemd).  Any modern system with
SystemD should be capable of all of the functionality shown here.  All 
containers will run on this host.

### Host Networking

There are numerous ways to set up networking.  I am using a bridge network that
utilizes the `systemd-networkd` interface.  

I have two files placed into my `/etc/systemd/network/`

**20-br0.netdev**
```
[NetDev]
Name=br0
Kind=bridge
```

**21-br0.network**
```
[Match]
Name=eno1 eno2 eno3 eno4

[Network]
Bridge=br0
DHCP=ipv4
```

This bridges my 4 network card interfaces into a single network device using 
IPv4 DHCP.

You can set up the bridge however you like.  Though, doing it this way allows
your container VETH's to get an IP address from the gateway DHCP server.  Since
this code installs `avahi-daemon` in the containers, mDNS allows for DNS 
addressing of all the containers.

### Host Disk

On my server I have a fairly large partition mounted at `/data`.  I set the 
system up to `--bind` mount the log files out to a directory structure which
is created at `/data/kafka`.

If you want to change this mount point, you will need to change:
- References to it in `initialize.sh`
- References to it in the `files/*.nspawn` files.

## Guest

We will be using Ubuntu 22.04.1LTS (Jammy) in the guests, they will be acquired from:
[NSPAWN Hub](https://hub.nspawn.org).

## Scripts

### `initialize.sh`

All you need to run is `sudo ./initialize.sh`.  Explanation of the different 
steps is done in-line.

### `deinitialize.sh`

If you want to tear everything down (except the `br0` bridge), you can run this 
script.
