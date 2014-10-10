squid-deb-proxy Docker container
================================

squid-deb-proxy provides an easy wrapper over squid3 to enable package proxy caching for your organisation/LAN.

This Docker container image allows most (if not all) non-routeable LAN subnets and caches from sources found under `extra-sources.acl`

Usage:

* On Server / Host:

`docker run --name proxy --rm -v /path/to/cachedir:/cachedir -p PORT:8000 pmoust/squid-deb-proxy &`

* On a node

```
apt-get install -y squid-deb-proxy-client net-tools
```

```
route -n | awk '/^0.0.0.0/ {print $2}' > /tmp/host_ip.txt
curl -s -I `cat /tmp/host_ip.txt`:8000 | grep -q squid-deb-proxy \
  && (echo "Acquire::http::Proxy \"http://$(cat /tmp/host_ip.txt):8000\";" > /etc/apt/apt.conf.d/30autoproxy) \
  && (echo "Acquire::http::Proxy \"http://$(cat /tmp/host_ip.txt):8000\";" > /etc/apt/apt.conf.d/30proxy) \
  && echo 'Using deb-proxy!' || echo "No deb-proxy detected on docker host"
apt-get install -y mysql-common

```


```
 && (echo "Acquire::http::Proxy::ppa.launchpad.net DIRECT;" >> /etc/apt/apt.conf.d/30proxy) \ -->
```

Thanks to @pmoust: https://github.com/pmoust/squid-deb-proxy

