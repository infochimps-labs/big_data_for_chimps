FROM ubuntu:trusty
# precise
MAINTAINER Flip Kromer <flip@infochimps.com>
MAINTAINER Russell Jurney
WORKDIR /root

# Using the `code/` directory in the big_data_for_chimps git repo as working directory:
#
#   Build  image     with `docker build -t ubuntu-bd4c config/ubuntu-bd4c/`
#   Test   container with `docker run --name u_bd4c_scratch -i -t ubuntu-bd4c`
#   Delete container with `docker rm    u_bd4c_scratch`

# ---------------------------------------------------------------------------
#
# Initial Tasks
#

ENV minimal_apt_get_install apt-get install -y --no-install-recommends

# Fix some issues with APT packages -- https://github.com/dotcloud/docker/issues/1024
RUN echo force-unsafe-io > /etc/dpkg/dpkg.cfg.d/02apt-speedup
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Modernize the OS
RUN apt-get --force-yes -y update
RUN apt-get --force-yes -y upgrade

# Basics so we can use the deb-proxy cache
RUN $minimal_apt_get_install squid-deb-proxy-client net-tools

# Figure out the IP address of docker host
RUN route -n | awk '/^0.0.0.0/ {print $2}' > /tmp/host_ip.txt

# Use the deb-proxy cacher if available. It's not worth doing earlier because the apt-update stuff isn't cached.
RUN rm /etc/apt/apt.conf.d/30autoproxy
RUN echo "Acquire::http::Proxy \"http://`cat /tmp/host_ip.txt`:8000\";" > /etc/apt/apt.conf.d/40squid-deb-proxy

# ---------------------------------------------------------------------------
#
# Add apt repositories
#

# apt tools
RUN $minimal_apt_get_install curl apt-utils software-properties-common python-software-properties

# Cloudera
RUN echo "deb [arch=amd64] http://archive.cloudera.com/cdh5/ubuntu/precise/amd64/cdh precise-cdh5 contrib" >  /etc/apt/sources.list.d/cloudera.list
RUN echo "deb-src http://archive.cloudera.com/cdh5/ubuntu/precise/amd64/cdh precise-cdh5 contrib"          >> /etc/apt/sources.list.d/cloudera.list
RUN echo "deb [arch=amd64] http://archive.cloudera.com/gplextras5/ubuntu/precise/amd64/gplextras precise-gplextras5 contrib" >  /etc/apt/sources.list.d/cloudera-gplextras.list
RUN echo "deb-src http://archive.cloudera.com/gplextras5/ubuntu/precise/amd64/gplextras precise-gplextras5 contrib"                    >> /etc/apt/sources.list.d/cloudera-gplextras.list
RUN curl -s http://archive.cloudera.com/cdh5/ubuntu/precise/amd64/cdh/archive.key | apt-key add -
# Java
RUN add-apt-repository    -y ppa:webupd8team/java
# Ubuntu  Universe and Multiverse.
RUN sed -i 's/^#\s*\(deb.*universe\)$/\1/g'   /etc/apt/sources.list
RUN sed -i 's/^#\s*\(deb.*multiverse\)$/\1/g' /etc/apt/sources.list

# ## Chris Lea's Node.js PPA
# apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C7917B12
# echo deb http://ppa.launchpad.net/chris-lea/node.js/ubuntu trusty main > /etc/apt/sources.list.d/nodejs.list

# ## Brightbox Ruby 1.9.3, 2.0 and 2.1
# apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C3173AA6
# echo deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu trusty main > /etc/apt/sources.list.d/brightbox.list

# Adopt the new repos
RUN apt-get --force-yes -y update

# Locale
RUN $minimal_apt_get_install language-pack-en
RUN locale-gen en_US

# ---------------------------------------------------------------------------
#
# Developer Conveniences
#

# libs

RUN $minimal_apt_get_install						       \
  build-essential manpages-dev gcc autoconf automake1.9 libtool doc-base

RUN $minimal_apt_get_install						       \
  libcurl4-openssl-dev libidn11-dev libreadline6 libreadline6-dev libssl-dev   \
  libxml2-dev libxml2-dev libxml2-utils libxslt-dev libxslt1-dev libxslt1-dev  \
  libyaml-dev libyaml-dev zlib1g-dev

# commandline
RUN $minimal_apt_get_install							\
  aptitude colordiff ctags dstat elinks flex git gdb git-doc host htop \
  ifstat locate less logrotate make man nano netcat-openbsd nmap openssl \
  openssh-server openssh-client rsync runit ssh-client ssh-import-id strace \
  sudo sysstat tar tcpd traceroute tree unzip wget vim zip dictionaries-common

# # no yuo on trusty
# chkconfig

# python, node
RUN $minimal_apt_get_install \
  python python-dev python-setuptools python-simplejson \
  python2.7 python3 nodejs
# emacs
RUN $minimal_apt_get_install emacs23-nox python-mode org-mode
# # AWS (TODO: need to find apt source)
# RUN $minimal_apt_get_install ec2-ami-tools ec2-api-tools s3cmd

# ruby1.9.3 ruby1.9.3-dev
# RUN gem2.1 install rake bundler --no-rdoc --no-ri
# echo "gem: --no-ri --no-rdoc" > /etc/gemrc
# ## Fix shebang lines in rake and bundler so that they're run with the currently
# ## configured default Ruby instead of the Ruby they're installed with.
# sed -i 's|/usr/bin/env ruby.*$|/usr/bin/env ruby|; s|/usr/bin/ruby.*$|/usr/bin/env ruby|' \
# 	/usr/local/bin/rake /usr/local/bin/bundle /usr/local/bin/bundler


# ---------------------------------------------------------------------------
#
# Java
#

RUN echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
  $minimal_apt_get_install oracle-java7-installer oracle-java7-set-default

ENV JAVA_HOME /usr/lib/jvm/java-7-oracle
ENV PATH $PATH:$JAVA_HOME/bin

# ---------------------------------------------------------------------------
#
# SSH
#

## Install init process.
ADD my_init /sbin/my_init
RUN \
  mkdir -p /etc/my_init.d ; \
  mkdir -p /etc/container_environment ; \
  touch /etc/container_environment.sh ; \
  touch /etc/container_environment.json ; \
  chmod 700 /etc/container_environment ; \
  groupadd -g 8377 docker_env ; \
  chown :docker_env /etc/container_environment.sh /etc/container_environment.json ; \
  chmod 640 /etc/container_environment.sh /etc/container_environment.json ; \
  ln -s /etc/container_environment.sh /etc/profile.d/

RUN mkdir /etc/sv/cron
ADD runit/cron /etc/sv/cron/run
RUN ln -snf /etc/sv/cron /etc/service/cron
# Remove useless cron entries.
RUN rm -f /etc/cron.daily/standard

# ## Install a syslog daemon.
# $minimal_apt_get_install syslog-ng-core
# mkdir /etc/service/syslog-ng
# cp /build/runit/syslog-ng /etc/service/syslog-ng/run
# mkdir -p /var/lib/syslog-ng
# cp /build/config/syslog_ng_default /etc/default/syslog-ng
# # Replace the system() source because inside Docker we
# # can't access /proc/kmsg.
# sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf

# ## Install the SSH server.
# $minimal_apt_get_install openssh-server
# mkdir /var/run/sshd
# mkdir /etc/service/sshd
# cp /build/runit/sshd /etc/service/sshd/run
# cp /build/config/sshd_config /etc/ssh/sshd_config
# cp /build/00_regen_ssh_host_keys.sh /etc/my_init.d/
#
# ## Install default SSH key for root and app.
# mkdir -p /root/.ssh
# chmod 700 /root/.ssh
# chown root:root /root/.ssh
# cp /build/insecure_key.pub /etc/insecure_key.pub
# cp /build/insecure_key /etc/insecure_key
# chmod 644 /etc/insecure_key*
# chown root:root /etc/insecure_key*
# cp /build/bin/enable_insecure_key /usr/sbin/

# export LC_ALL=C
# export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
#
# Fixup
#
RUN rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup
RUN apt-get clean
RUN updatedb
