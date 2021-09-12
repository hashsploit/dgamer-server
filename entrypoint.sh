#!/bin/bash

# Replace the "HOST_IP" with the ip provided in the environment

set -e

#if [ "${HOST_IP}" == "" ]; then
#	echo -e "Error: -e HOST_IP env var is required and must be a valid IPv4 address!"
#	exit 1
#fi

#echo -e "Hosting on ${HOST_IP} ..."

# Add FQDNs to hosts file
echo "127.0.0.1    conntest.nintendowifi.net" >> /etc/hosts
echo "127.0.0.1    nas.nintendowifi.net" >> /etc/hosts
echo "127.0.0.1    home.disney.go.com" >> /etc/hosts

#sed -i "s/HOST_IP/${HOST_IP}/g" /etc/bind/dgamer.db

#/etc/init.d/bind9 start
#/usr/sbin/named -u bind -c /etc/bind/named.conf -g & 

/usr/local/apache/bin/httpd -k stop
exec /usr/local/apache/bin/httpd -D FOREGROUND

