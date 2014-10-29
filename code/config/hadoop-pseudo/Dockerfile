FROM hadoop-client
MAINTAINER Flip Kromer <flip@infochimps.com>
MAINTAINER Russell Jurney

# ---------------------------------------------------------------------------
#
# Hadoop
#

# Basics
RUN \
  apt-get --force-yes -y install -t precise-cdh5 hadoop hadoop-doc hadoop-client \
    hadoop-hdfs hadoop-lzo  \
    hadoop-yarn hadoop-mapreduce hadoop-0.20-mapreduce

# All them daemons
RUN \
  apt-get --force-yes -y install -t precise-cdh5 \
    hadoop-yarn-resourcemanager hadoop-yarn-nodemanager hadoop-mapreduce-historyserver hadoop-yarn-proxyserver \
    hadoop-hdfs-datanode hadoop-hdfs-namenode hadoop-hdfs-secondarynamenode parquet hadoop-hdfs-nfs3

# Hadoop Applications
RUN \
  apt-get --force-yes -y install pig hive

# ---------------------------------------------------------------------------
#
# Configure Hadoop
#

RUN mkdir -p            $HADOOP_DATA_DIR/hdfs      $HADOOP_DATA_DIR/name   $HADOOP_DATA_DIR/nn2 && \
    chown hdfs:hdfs     $HADOOP_DATA_DIR/hdfs      $HADOOP_DATA_DIR/name   $HADOOP_DATA_DIR/nn2 && \
    mkdir -p            $HADOOP_DATA_DIR/jobstatus $HADOOP_JRNL_DIR/mapred                      && \
    chown mapred:mapred $HADOOP_DATA_DIR/jobstatus $HADOOP_JRNL_DIR/mapred                      && \
    mkdir -p            $HADOOP_JRNL_DIR/yarn-jobs $HADOOP_JRNL_DIR/yarn-staging                && \
    chown yarn:yarn     $HADOOP_JRNL_DIR/yarn-jobs $HADOOP_JRNL_DIR/yarn-staging
  
ADD core-site.xml   $HADOOP_CONF/core-site.xml
ADD hdfs-site.xml   $HADOOP_CONF/hdfs-site.xml
ADD mapred-site.xml $HADOOP_CONF/mapred-site.xml
ADD yarn-site.xml   $HADOOP_CONF/yarn-site.xml

# TODO: figure out hostnames across containers

# Point the HDFS at the port exposed via the host
RUN perl -p -i -e 's~%HADOOP_DATA_DIR~'$HADOOP_DATA_DIR'~g' $HADOOP_CONF/*-site.xml && \
    perl -p -i -e 's~%HADOOP_JRNL_DIR~'$HADOOP_JRNL_DIR'~g' $HADOOP_CONF/*-site.xml && \
    perl -p -i -e 's~%HADOOP_TMP_DIR~'$HADOOP_TMP_DIR'~g'   $HADOOP_CONF/*-site.xml && \
    perl -p -i -e 's~%HADOOP_LOG_DIR~'$HADOOP_LOG_DIR'~g'   $HADOOP_CONF/*-site.xml && \
    perl -p -i -e 's~%HADOOP_NN_IP~localhost~g'             $HADOOP_CONF/*-site.xml && \
    perl -p -i -e 's~%HADOOP_YARN_IP~localhost~g'           $HADOOP_CONF/*-site.xml && \
    perl -p -i -e 's~%HADOOP_JT_IP~localhost~g'             $HADOOP_CONF/*-site.xml && \
    perl -p -i -e 's~%HADOOP_HIST_IP~localhost~g'           $HADOOP_CONF/*-site.xml

perl -p -i -e 's~/var/log~/data/log/hadoop~g'           /etc/default/hadoop*    

# ---------------------------------------------------------------------------
#
# Zookeeper
#

ENV ZK_CONF /etc/zookeeper/conf.pseudo

RUN apt-get --force-yes -y install -t precise-cdh5 zookeeper zookeeper-server zookeeper-native

RUN mkdir -p           $ZK_DATA_DIR  $ZK_JRNL_DIR $ZK_LOG_DIR && \
    chown -R zookeeper $ZK_DATA_DIR  $ZK_JRNL_DIR $ZK_LOG_DIR

RUN cp -rp /etc/zookeeper/conf.dist $ZK_CONF
RUN update-alternatives --install /etc/zookeeper/conf zookeeper-conf $ZK_CONF 50 && \
    update-alternatives --set                         zookeeper-conf $ZK_CONF

ADD zoo.cfg  $ZK_CONF/zoo.cfg
RUN perl -p -i -e 's~^dataDir=.*~dataDir='$ZK_DATA_DIR'~g'       $ZK_CONF/zoo.cfg && \
    perl -p -i -e 's~^dataLogDir=.*~dataLogDir='$ZK_JRNL_DIR'~g' $ZK_CONF/zoo.cfg

# Be server 1 of 1 in standalone mode
RUN service zookeeper-server init --myid=1

# ---------------------------------------------------------------------------
#
# Configure Hadoop Namenode
#

RUN sudo -u hdfs hdfs namenode -format

# https://www.cloudera.com/content/cloudera/en/documentation/cdh5/latest/CDH5-Quick-Start/cdh5qs_yarn_pseudo.html

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

# ---------------------------------------------------------------------------
#
# Launch Services
#

# Cleanup

RUN aptitude search hadoop | sort
RUN updatedb
