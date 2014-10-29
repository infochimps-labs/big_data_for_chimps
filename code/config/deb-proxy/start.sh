#!/bin/sh
mkdir /deb-proxy/cache /deb-proxy/log
chown -R proxy.proxy /deb-proxy
. /usr/share/squid-deb-proxy/init-common.sh
pre_start
/usr/sbin/squid3 -N -f /etc/squid-deb-proxy/squid-deb-proxy.conf
