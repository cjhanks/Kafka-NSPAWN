#!/bin/bash
set -e
#set -x

# ---------------------------------------------------------------------------- #
# If the `machinectl` does not already have a copy of the Jammy tar image, 
# fetch it.
#
# We will call the image "UbuntuJammy", it can be seen in 
# `machinectl list-images`.
#
# https://hub.nspawn.org is a repository of basic base images and is not
# necessarily required.  It *is* possible to create these `chroot`'s from 
# tools like `pacstrap` or `debootstrap`.  However, an exported Docker 
# container is unlikely to work - as it likely has an `init` stub that is not
# `systemd`.
#
# ---------------------------------------------------------------------------- #
if [[ $(machinectl list-images | grep -c UbuntuJammy) -eq 0 ]]
then
  machinectl pull-tar \
    --verify=no \
    https://hub.nspawn.org/storage/ubuntu/jammy/tar/image.tar.xz \
    UbuntuJammy
fi

# In case this is being re-ran, remove old remnants for convenience.
machinectl stop   kafka-base || true
sleep 1
machinectl remove kafka-base || true
sleep 1

# ---------------------------------------------------------------------------- #
# Initialize a Kafka base image.  Please note that the `sleep` commands are 
# required for a few reason:
# 1. `machinectl start` fully boots a SystemD init within the container.
# 2. Until we have placed the proper '.nspawn' files with
#        [Exec]
#        NotifyReady=yes
#    The child container has no way of notifying the calling process of 
#    completion.
# ---------------------------------------------------------------------------- #
machinectl clone UbuntuJammy kafka-base
machinectl start kafka-base

sleep 5

# The `kafka-base` is a booted machine.  `systemd-run` allows us to get a ptty
# inside the container and execute commands, not unlikely `docker exec`.
#
# In this case, we will cat the installation file into the stdin of a bash 
# shell that will then execute installation.
cat files/init-kafka.sh | \
  systemd-run --pipe --working-directory=/root -M kafka-base \
    /bin/bash -

# We need to clone this machine, so it must be stopped.
machinectl stop kafka-base
sleep 1

# ---------------------------------------------------------------------------- #
# At this point, we will set up the directory structure on the HOST which will
# be bind mounted inside the containers.
#
# Obviously this could be made more secure by have a uid/gid mapping inside the
# container.  But for demonstration purposes, this is sufficient.
# ---------------------------------------------------------------------------- #
rm -rf /data/kafka
mkdir -p /data/kafka/node1/config/kraft
mkdir -p /data/kafka/node2/config/kraft
mkdir -p /data/kafka/node3/config/kraft

chmod -R 0777 /data/kafka/  # Don't do this in production.

# ---------------------------------------------------------------------------- #
#  We are going to clone the kafka-base a few times.  For node1-node3, those
#  are required.  They are needed for the cluster.  Additionally, I clone a 
#  `kafka-tester` which allows me to use the CLI tools in a container that is 
#  not ALSO a cluster node.
# ---------------------------------------------------------------------------- #
machinectl clone kafka-base kafka-node1
machinectl clone kafka-base kafka-node2
machinectl clone kafka-base kafka-node3
machinectl clone kafka-base kafka-tester

# We don't need the base anymore.
machinectl remove kafka-base

# ---------------------------------------------------------------------------- #
# This is an important step.  The `.nspawn` files are read as an override by
# `machinectl`.  They do important things, so I will document them here...
#
# [Exec]
# Boot=yes                            # Container should boot init?  
# NotifyReady=yes                     # Notify calling process when booted.
# LinkJournal=host                    # Try to journalctl to host.
# [Files]
# Bind=/data/kafka/node1:/data/kafka  # Bind mount
# [Network]
# VirtualEthernet=yes 	              # Create a virtual ethernet device.
# Bridge=br0                          # Attach the virtual ethernet to the br0 network.
# ---------------------------------------------------------------------------- #
mkdir -p /etc/systemd-nspawn
cp files/*.nspawn /etc/systemd/nspawn

machinectl start kafka-node1
machinectl start kafka-node2
machinectl start kafka-node3
machinectl start kafka-tester

# ---------------------------------------------------------------------------- #
# Each one of the nodes has a unique `node.id=` value to distinguish them.  
# This block could be templated, but I did not want to obfuscate the very 
# basic logic.
# ---------------------------------------------------------------------------- #
cp \
  config/node1.properties \
  /data/kafka/node1/config/kraft/server.properties
cp \
  config/node2.properties \
  /data/kafka/node2/config/kraft/server.properties
cp \
  config/node3.properties \
  /data/kafka/node3/config/kraft/server.properties

# ---------------------------------------------------------------------------- #
# Here we are going to:
# 1. Create a UUID for the cluster. 
# 2. Run the installation script through each one of the kafka-node's passing 
#    in a unique HOSTNAME and the common CLUSTER_ID.
# ---------------------------------------------------------------------------- #
CLUSTER_ID=$(systemd-run --pipe -M kafka-node1 /opt/kafka/bin/kafka-storage.sh random-uuid)

cat files/init-server.sh | \
  systemd-run --pipe -E HOSTNAME=kafka-node1 -E CLUSTER_ID=${CLUSTER_ID} -M kafka-node1 \
    /bin/bash -

cat files/init-server.sh | \
  systemd-run --pipe -E HOSTNAME=kafka-node2 -E CLUSTER_ID=${CLUSTER_ID} -M kafka-node2 \
    /bin/bash -

cat files/init-server.sh | \
  systemd-run --pipe -E HOSTNAME=kafka-node3 -E CLUSTER_ID=${CLUSTER_ID} -M kafka-node3 \
    /bin/bash -

