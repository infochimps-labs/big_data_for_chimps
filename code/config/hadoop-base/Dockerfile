FROM ubuntu-bd4c
MAINTAINER Flip Kromer <flip@infochimps.com>
MAINTAINER Russell Jurney
WORKDIR /root

#
# Stabilize user IDs for hadoop daemons
#

# daemon users
RUN adduser hadoop      --uid 901 --group --system ; \
    adduser hdfs        --uid 902 --group --system ; \
    adduser mapred      --uid 903 --group --system ; \
    adduser yarn        --uid 904 --group --system ; \
    adduser hive        --uid 905 --group --system ; \
    adduser zookeeper   --uid 906 --group --system ; \
    usermod -a -G hdfs,mapred,yarn hadoop

# users in this group have root-ish rights on the hdfs
RUN addgroup supergroup --gid 900

# ---------------------------------------------------------------------------
#
# Install Hadoop
#

RUN apt-get --force-yes -y install hadoop zookeeper hadoop-hdfs hadoop-yarn \
  hadoop-0.20-mapreduce hadoop-mapreduce hadoop-lzo

# ---------------------------------------------------------------------------
#
# Configure Hadoop
#

# Hadoop config stored here, and linked as the standard /etc/hadoop/conf
ENV HADOOP_CONF /etc/hadoop/cluster

# Conf files
RUN cp -rp  /etc/hadoop/conf.empty $HADOOP_CONF
RUN ln -snf $HADOOP_CONF /etc/hadoop/conf
RUN ln -snf $HADOOP_CONF /etc/alternatives/hadoop-conf
ADD core-site.xml   $HADOOP_CONF/core-site.xml

# Hadoop directories
RUN mkdir -p /data/hadoop ; cd /data/hadoop ; \
  mkdir -p            tmp log local ; \
  chown hadoop:hadoop tmp log ; \
  chmod 0577          tmp log

# Figure out the IP address of docker host
RUN route -n | awk '/^0.0.0.0/ {print $2}' > /etc/docker_host_ip

# Point the HDFS at the port exposed via the host
RUN perl -p -i -e 's/HOSTNAMEGOESHERE/'`cat /etc/docker_host_ip`'/g' $HADOOP_CONF/core-site.xml


# ---------------------------------------------------------------------------
#
# Cleanup
#

RUN aptitude search hadoop
RUN updatedb
