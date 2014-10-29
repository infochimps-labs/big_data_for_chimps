FROM hadoop-base
MAINTAINER Flip Kromer <flip@infochimps.com>
MAINTAINER Russell Jurney
WORKDIR /root

# ---------------------------------------------------------------------------
# 
# Configure Hadoop client
#

# Basics
RUN apt-get --force-yes -y install \
  hadoop-doc hadoop-client hadoop-lzo zookeeper-bin   pig hive pig-udf-datafu python-mrjob  
  
# ---------------------------------------------------------------------------
# 
# Make a user account named 'chimpy'
#

# home directory /home/chimpy, password 'chimpy', a superuser on the HDFS
RUN adduser chimpy --uid 2000 --disabled-password --gecos "Hadoop Programmer" && \
    echo chimpy:chimpy | chpasswd       && \
    usermod -a -G supergroup chimpy

# ---------------------------------------------------------------------------
# 
# Populate with data
#
    
# The standard BSD words file
RUN $minimal_apt_get_install --force-yes wamerican-huge
 
# # Setup chimpy environment
# ADD bashrc /home/chimpy/.bashrc
#
# # Setup SSH keys
# RUN su -l -c 'ssh-keygen -t rsa -f /home/chimpy/.ssh/id_rsa -P ""' chimpy && \
#   cat /home/chimpy/.ssh/id_rsa.pub | su -l -c 'tee -a /home/chimpy/.ssh/authorized_keys' chimpy
# ADD ssh-config /home/chimpy/.ssh/config
# RUN chmod 600  /home/chimpy/.ssh/config

# # Fix Ubuntu 13.10 SSH daemon problem with docker: http://docs.docker.io/en/latest/examples/running_ssh_service/
# RUN sed -ri 's/session[[:blank:]]+required[[:blank:]]+pam_loginuid.so/session optional pam_loginuid.so/g' /etc/pam.d/sshd

# ENTRYPOINT ["/usr/bin/runsvdir", "-P", "/etc/service"]
