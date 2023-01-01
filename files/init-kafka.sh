#!/bin/bash
set -e

#
# Feel free to change the version as you see fit, so long as it support KRaft.
#
VERSION=3.2.3
KAFKA_TGZ=kafka_2.12-${VERSION}.tgz
KAFKA_DIR=kafka_2.12-${VERSION}
INSTALL_PATH=/opt/kafka

apt update
apt upgrade -y

# This is due to a bug in the base container image which is missing a
# directory.
mkdir -p /usr/share/man/man1/

# Curl is needed to download the Kafka Tar ball.
apt install -y curl

# The JDK is needed to run it.
apt install -y default-jdk

# Allows for mDNS on the containers.  While this is not strictly necessary, it
# makes life much easier.
apt install -y avahi-daemon 

# Download the source code.
if [ ! -e ${KAFKA_TGZ} ]
then
  curl https://downloads.apache.org/kafka/${VERSION}/kafka_2.12-${VERSION}.tgz \
       > ${KAFKA_TGZ}
fi

# Unpack the tar data.
if [ ! -e ${KAFKA_DIR} ]
then
  tar xzvf ${KAFKA_TGZ}
fi

# Remove any remnants from where we are about to install it.
rm -rf ${INSTALL_PATH}

# Instsall the packages.
mkdir -p ${INSTALL_PATH}
mv ${KAFKA_DIR}/* ${INSTALL_PATH}

rm -rf ${KAFKA_DIR} ${KAFKA_TGZ}

# We do a poweroff inside the container.
poweroff
