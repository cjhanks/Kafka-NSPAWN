#!/bin/bash
set -e

rm -rf /data/kafka/config
cp -r  /opt/kafka/config /data/kafka/config

cat >/etc/systemd/system/zookeeper.service<<EOF
[Unit]
Description=Apache Zookeeper server
Documentation=http://zookeeper.apache.org
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /data/kafka/config/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh

Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable zookeeper.service --now

echo HOSTNAME > /etc/hostname
reboot now
