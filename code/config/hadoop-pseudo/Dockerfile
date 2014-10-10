FROM ubuntu-bd4c
MAINTAINER Flip Kromer <flip@infochimps.com>
MAINTAINER Russell Jurney
WORKDIR /root

#
# Stabilize user IDs for hadoop daemons
#

RUN addgroup supergroup --gid 900
#
RUN adduser hadoop      --uid 901 --group --system
RUN adduser hdfs        --uid 902 --group --system
RUN adduser mapred      --uid 903 --group --system
RUN adduser yarn        --uid 904 --group --system
RUN adduser hive        --uid 905 --group --system
RUN adduser zookeeper   --uid 906 --group --system
#
RUN usermod -a -G hdfs,mapred,yarn hadoop

# ---------------------------------------------------------------------------
#
# Hadoop
#

# Basics
RUN \
  apt-get --force-yes -y install hadoop hadoop-hdfs hadoop-mapreduce hadoop-yarn hadoop-doc hadoop-client hadoop-lzo

# All them daemons
RUN \
  apt-get --force-yes -y install hadoop-yarn-resourcemanager hadoop-hdfs-namenode hadoop-hdfs-secondarynamenode \
    hadoop-yarn-nodemanager hadoop-hdfs-datanode hadoop-mapreduce-historyserver hadoop-yarn-proxyserver

# Hadoop Applications
RUN \
  apt-get --force-yes -y install pig hive

# ---------------------------------------------------------------------------
# 
# Make a user account named 'chimpy'
#

# home directory /home/chimpy, password 'chimpy'
RUN adduser chimpy --uid 2000 --disabled-password --gecos "Hadoop Programmer"
RUN echo chimpy:chimpy | chpasswd

# a superuser on the HDFS
RUN usermod -a -G supergroup chimpy

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

# ---------------------------------------------------------------------------
#
# Configure Hadoop
#

ENV HADOOP_CONF /etc/hadoop/pseudo

RUN cp -rp    /etc/hadoop/conf.empty $HADOOP_CONF
RUN ln -snf         $HADOOP_CONF /etc/hadoop/conf
RUN ln -snf         $HADOOP_CONF /etc/alternatives/hadoop-conf

RUN mkdir -p /data/hadoop ; cd /data/hadoop ; \
  mkdir -p hdfs name nn2 mapred local/mapred mapred/jobstatus yarn local/yarn yarn/staging tmp log ; \
  chown hdfs:hdfs     hdfs name nn2 ; \
  chown mapred:mapred mapred local/mapred mapred/jobstatus ; \
  chown yarn:yarn     yarn   local/yarn   yarn/staging; \
  chown hadoop:hadoop tmp log ; \
  chmod 0577 tmp log

ADD core-site.xml   $HADOOP_CONF/core-site.xml
ADD hdfs-site.xml   $HADOOP_CONF/hdfs-site.xml
ADD mapred-site.xml $HADOOP_CONF/mapred-site.xml
ADD yarn-site.xml   $HADOOP_CONF/yarn-site.xml
RUN perl -p -i -e 's/HOSTNAMEGOESHERE/'`hostname`'/g' $HADOOP_CONF/core-site.xml
#
# RUN colordiff -rwu /etc/hadoop/conf.empty $HADOOP_CONF ; true

ENV JAVA_HOME /usr/lib/jvm/java-7-oracle
ENV PATH $PATH:$JAVA_HOME/bin

RUN hdfs namenode -format

# CMD ["/usr/sbin/runsvdir-start"]


# Hadoop Server Daemons

# RUN apt-get --force-yes -y install --download-only \
#   zookeeper-server hadoop-yarn-resourcemanager hadoop-hdfs-namenode hadoop-hdfs-secondarynamenode \
#   hadoop-yarn-nodemanager hadoop-hdfs-datanode hadoop-mapreduce-historyserver hadoop-yarn-proxyserver

# # *** hadoop-zk
# RUN apt-get --force-yes -y install zookeeper-server

# # *** hadoop-yarn
# RUN apt-get --force-yes -y install hadoop-yarn-resourcemanager
# RUN apt-get --force-yes -y install hadoop-mapreduce-historyserver

# # *** hadoop-nn
# RUN apt-get --force-yes -y install hadoop-hdfs-namenode

# # *** hadoop-nn2
# RUN apt-get --force-yes -y install hadoop-hdfs-secondarynamenode

# # *** hadoop-worker
# RUN apt-get --force-yes -y install hadoop-yarn-nodemanager
# RUN apt-get --force-yes -y install hadoop-hdfs-datanode

# # *** hadoop-client
# RUN apt-get --force-yes -y install hadoop-client hadoop-doc

# ADD hdfs-site.xml   $HADOOP_CONF/hdfs-site.xml
# ADD mapred-site.xml $HADOOP_CONF/mapred-site.xml
# ADD yarn-site.xml   $HADOOP_CONF/yarn-site.xml
#
# # TODO this needs to be the host actually
# RUN perl -p -i -e 's/HOSTNAMEGOESHERE/'`hostname`'/g' $HADOOP_CONF/core-site.xml

RUN aptitude search hadoop

RUN updatedb 
