FROM ubuntu:trusty
MAINTAINER Panagiotis Moustafellos <pmoust@gmail.com>

# update and install squid-deb-proxy
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y squid-deb-proxy squid-deb-proxy-client nano

# Extra locations to cache from
ADD extra-sources.acl  /etc/squid-deb-proxy/mirror-dstdomain.acl.d/20-extra-sources.acl

RUN echo 0.0.0.0/32 >> /etc/squid-deb-proxy/allowed-networks-src.acl.d/10-default
RUN echo skype      >> /etc/squid-deb-proxy/pkg-blacklist.d/10-default

RUN cp /etc/squid-deb-proxy/squid-deb-proxy.conf  /etc/squid-deb-proxy/squid-deb-proxy.conf.orig
ADD squid-deb-proxy.conf /etc/squid-deb-proxy/squid-deb-proxy.conf
RUN diff -uw /etc/squid-deb-proxy/squid-deb-proxy.conf.orig /etc/squid-deb-proxy/squid-deb-proxy.conf ; true

ADD start.sh /start.sh
RUN chmod +x /start.sh

VOLUME ["/deb-proxy"]

EXPOSE 8000

ENTRYPOINT ["/start.sh"]
