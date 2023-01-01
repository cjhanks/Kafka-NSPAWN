#!/bin/bash
set -e

# This is a convenience which puts the kafka scripts into our PATH variable.
export PATH=${PATH}:/opt/kafka/bin

#
# Create a systemd service file for kafka.  When the container is booted, this 
# service is launched.  Exactly how it's done in a regular HOST system.
#
# This of course deviates from Docker.
#
cat > /etc/systemd/system/kafka.service <<EOF
[Unit]
Description=Apache Kafka Server
Documentation=http://kafka.apache.org/documentation.html

[Service]
Type=simple
Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
ExecStart=/opt/kafka/bin/kafka-server-start.sh /data/kafka/config/kraft/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

#
# Enable the service.
#
systemctl daemon-reload
systemctl enable kafka.service 

# In the calling script `${HOSTNAME}` is environmentally passed.
echo ${HOSTNAME} > /etc/hostname

# Set up the kafka storage.  This is required for the KRaft.  The CLUSTER_ID was
# generated in the calling script and passed in via environment variable.
kafka-storage.sh format -t ${CLUSTER_ID} -c /data/kafka/config/kraft/server.properties

# Reboot the container machine.
reboot now
