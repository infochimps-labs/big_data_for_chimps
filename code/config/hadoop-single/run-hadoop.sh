#!/bin/bash

set -x

# append ssh public key to authorized_keys file
echo $AUTHORIZED_SSH_PUBLIC_KEY >> /home/hduser/.ssh/authorized_keys

# format the namenode if it's not already done
su -l -c 'mkdir -p /home/hduser/hdfs-data/namenode /home/hduser/hdfs-data/datanode && hdfs namenode -format -nonInteractive' hduser

# start ssh daemon
service ssh start

# start zookeeper used for HDFS
service zookeeper start

# clear hadoop logs
rm -fr /opt/hadoop/logs/*

# start YARN
su -l -c 'start-yarn.sh' hduser

# start HDFS
su -l -c 'start-dfs.sh' hduser


su -l -c '$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh start historyserver --config $HADOOP_CONF_DIR' hduser

sleep 1

# tail log directory
tail -n 1000 -f /opt/hadoop/logs/*.log
