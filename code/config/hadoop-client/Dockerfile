FROM hadoop-base
MAINTAINER Flip Kromer <flip@infochimps.com>
MAINTAINER Russell Jurney
WORKDIR /root

# ---------------------------------------------------------------------------
# 
# Configure Hadoop client
#

RUN cd /data/hadoop ; \
  mkdir -p            mapred local/mapred mapred/jobstatus ; \
  chown mapred:mapred mapred local/mapred mapred/jobstatus

# Basics
RUN apt-get --force-yes -y install hadoop-doc hadoop-client hadoop-lzo

# Hadoop Applications
RUN apt-get --force-yes -y install pig hive
  
# ---------------------------------------------------------------------------
# 
# Make a user account named 'chimpy'
#

# home directory /home/chimpy, password 'chimpy'
RUN adduser chimpy --uid 2000 --disabled-password --gecos "Hadoop Programmer"
RUN echo chimpy:chimpy | chpasswd

# a superuser on the HDFS
RUN usermod -a -G supergroup chimpy

# The standard BSD words file
RUN $minimal_apt_get_install --force-yes wamerican-huge
 
# # Setup chimpy environment
# ADD bashrc /home/chimpy/.bashrc

# ENTRYPOINT ["/usr/bin/runsvdir", "-P", "/etc/service"]
