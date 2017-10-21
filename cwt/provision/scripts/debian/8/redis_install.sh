#!/bin/bash

##
# Redis setup.
#
# WIP unfinished 2017/07/02 - TODO
#
# Run as root or sudo.
#

cat > /etc/apt/sources.list.d/dotdeb.list <<'EOF'
deb http://ftp.utexas.edu/dotdeb/ jessie all
deb-src http://ftp.utexas.edu/dotdeb/ jessie all
EOF

wget https://www.dotdeb.org/dotdeb.gpg
apt-key add dotdeb.gpg

apt-get update
apt-get install redis-server -y

# Redis configuration (NB: creates a backup).
sed -e 's,appendonly no,appendonly yes,g' -i.bak /etc/redis/redis.conf

service redis-server restart

# Adjust Linux system settings
sysctl vm.overcommit_memory=1
echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
