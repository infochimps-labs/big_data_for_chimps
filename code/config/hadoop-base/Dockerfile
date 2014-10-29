FROM ubuntu-bd4c
MAINTAINER Flip Kromer <flip@infochimps.com>
MAINTAINER Russell Jurney
WORKDIR /root

#
# Directories
#

# Centralize the interesting directories their lifecycle can be managed
# separately. 

# Directory where durable data -- HDFS, databases, etc -- should live
ENV     DATA_DIR /data
# Directory for journals -- node-local scratch space for transaction journals
ENV     JRNL_DIR /data/local
# Directory for logs
ENV     LOG_DIR  /data/log

ENV     HADOOP_DATA_DIR  $DATA_DIR/hadoop
ENV     HADOOP_JRNL_DIR  $JRNL_DIR/hadoop
ENV     HADOOP_TMP_DIR   $JRNL_DIR/hadoop/tmp
ENV     HADOOP_LOG_DIR   $LOG_DIR/hadoop

ENV     ZK_DATA_DIR      $DATA_DIR/zookeeper/db
ENV     ZK_JRNL_DIR      $JRNL_DIR/zookeeper/txlog
ENV     ZK_LOG_DIR       $LOG_DIR/zookeeper

# Figure out the IP address of docker host
RUN route -n | awk '/^0.0.0.0/ {print $2}' > /etc/docker_host_ip


# ---------------------------------------------------------------------------
#
# Daemon Users
#

# add daemon users -- stabilize user IDs so that we can persist data dirs
RUN adduser hadoop      --uid 901 --group --system && \
    adduser hdfs        --uid 902 --group --system && usermod -a -G hadoop hdfs   && \
    adduser mapred      --uid 903 --group --system && usermod -a -G hadoop mapred && \
    adduser yarn        --uid 904 --group --system && usermod -a -G hadoop yarn   && \
    adduser hive        --uid 905 --group --system && usermod -a -G hadoop hive   && \
    adduser zookeeper   --uid 906 --group --system && usermod -a -G hadoop zookeeper

# users in this group have root-ish rights on the hdfs
RUN addgroup supergroup --gid 900

# ---------------------------------------------------------------------------
#
# Install Hadoop
#
RUN apt-get --force-yes -y install -t precise-cdh5  hadoop zookeeper

# ---------------------------------------------------------------------------
#
# Configure Hadoop
#

# Hadoop config stored here, and linked as the standard /etc/hadoop/conf
ENV HADOOP_CONF /etc/hadoop/conf.pseudo

# Conf files
RUN cp -rp  /etc/hadoop/conf.empty $HADOOP_CONF

RUN update-alternatives --install /etc/hadoop/conf hadoop-conf $HADOOP_CONF 50 && \
    update-alternatives --set                      hadoop-conf $HADOOP_CONF

ADD core-site.xml   $HADOOP_CONF/core-site.xml

# Hadoop directories
RUN mkdir -p            $HADOOP_DATA_DIR $HADOOP_JRNL_DIR && \
    mkdir -p            $HADOOP_LOG_DIR  $HADOOP_TMP_DIR && \
    chown hadoop:hadoop $HADOOP_LOG_DIR  $HADOOP_TMP_DIR && \
    chmod 0775          $HADOOP_LOG_DIR  $HADOOP_TMP_DIR

# ---------------------------------------------------------------------------
#
# Cleanup
#

RUN aptitude search hadoop | sort ; echo $DATA_DIR $JRNL_DIR $LOG_DIR $HADOOP_DATA_DIR $HADOOP_LOG_DIR $HADOOP_TMP_DIR
