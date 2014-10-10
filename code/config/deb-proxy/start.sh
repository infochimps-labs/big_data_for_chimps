#!/bin/sh
chown -R proxy.proxy /cachedir
. /usr/share/squid-deb-proxy/init-common.sh
pre_start
/usr/sbin/squid3 -N -f /etc/squid-deb-proxy/squid-deb-proxy.conf
