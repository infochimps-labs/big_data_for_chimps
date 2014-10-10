FROM ubuntu:precise
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

# Modernize the OS
RUN apt-get --force-yes -y update
RUN apt-get --force-yes -y upgrade

# Basics so we can use the deb-proxy cache
RUN apt-get -y install squid-deb-proxy-client net-tools

# Figure out the IP address of docker host
RUN route -n | awk '/^0.0.0.0/ {print $2}' > /etc/docker_host_ip

# Use the deb-proxy cacher if available. It's not worth doing earlier because the apt-update stuff isn't cached.
RUN rm /etc/apt/apt.conf.d/30autoproxy
RUN echo "Acquire::http::Proxy \"http://`cat /etc/docker_host_ip`:8000\";" > /etc/apt/apt.conf.d/40squid-deb-proxy

# ---------------------------------------------------------------------------
#
# Add apt repositories
#

# apt tools
RUN apt-get --force-yes -y install curl apt-utils software-properties-common python-software-properties

# Cloudera
RUN echo "deb [arch=amd64] http://archive.cloudera.com/cdh5/ubuntu/precise/amd64/cdh precise-cdh5 contrib" >  /etc/apt/sources.list.d/cloudera.list
RUN echo "deb-src http://archive.cloudera.com/cdh5/ubuntu/precise/amd64/cdh precise-cdh5 contrib"          >> /etc/apt/sources.list.d/cloudera.list
RUN echo "deb [arch=amd64] http://archive.cloudera.com/gplextras5/ubuntu/precise/amd64/gplextras precise-gplextras5 contrib" >  /etc/apt/sources.list.d/cloudera-gplextras.list
RUN echo "deb-src http://archive.cloudera.com/gplextras5/ubuntu/precise/amd64/gplextras precise-gplextras5 contrib"                    >> /etc/apt/sources.list.d/cloudera-gplextras.list
RUN curl -s                http://archive.cloudera.com/cdh5/ubuntu/precise/amd64/cdh/archive.key | apt-key add -
# Java
RUN add-apt-repository    -y ppa:webupd8team/java
# Ubuntu universe
# RUN add-apt-repository -y multiverse && add-apt-repository -y restricted

# Adopt the new repos
RUN apt-get --force-yes -y update

# ---------------------------------------------------------------------------
#
# Developer Conveniences
#

# libs
RUN apt-get --force-yes -y install libcurl4-openssl-dev libidn11-dev \
  libreadline6 libreadline6-dev libssl-dev libxml2-dev libxml2-dev \
  libxml2-utils libxslt-dev libxslt1-dev libxslt1-dev libyaml-dev \
  libyaml-dev zlib1g-dev build-essential
# commandline
RUN apt-get --force-yes -y install \
  aptitude chkconfig colordiff dstat elinks git htop ifstat make nano \
  netcat-openbsd nmap openssl psmisc runit sysstat tree wget zip unzip \
  tar sudo openssh-server openssh-client rsync \
  man host traceroute locate
# python
RUN apt-get --force-yes -y install python-dev python-setuptools python-simplejson
# emacs
RUN apt-get --force-yes -y install emacs23-nox python-mode org-mode
# # AWS (TODO: need to find apt source)
# RUN apt-get --force-yes -y install ec2-ami-tools ec2-api-tools s3cmd
