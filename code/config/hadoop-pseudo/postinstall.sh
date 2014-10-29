#!/usr/bin/sh


service zookeeper-server start &&  service hadoop-hdfs-namenode start && sleep 2

sudo -u hdfs hadoop fs -mkdir -p /user/chimpy /tmp/hadoop-yarn/staging/history/done_intermediate /var/log/hadoop-yarn /var/log/hadoop-mapreduce && \
sudo -u hdfs hadoop fs -chown    chimpy        /user/chimpy && \
sudo -u hdfs hadoop fs -chown -R mapred:mapred /tmp/hadoop-yarn/staging /var/log/hadoop-mapreduce  && \
sudo -u hdfs hadoop fs -chown    yarn:mapred   /var/log/hadoop-yarn && \
sudo -u hdfs hadoop fs -chmod -R 1777 /tmp 

cd /etc/init.d ; for svc in hadoop-hdfs-secondarynamenode hadoop-hdfs-datanode hadoop-yarn-resourcemanager hadoop-yarn-nodemanager hadoop-mapreduce-historyserver ; do echo "====== $svc" ; service $svc start ; done

sudo -u chimpy hadoop fs -mkdir input
sudo -u chimpy hadoop fs -put /etc/hadoop/conf/*.xml input
sudo -u chimpy hadoop fs -ls input

# Found 3 items:
# -rw-r--r-- 1 joe supergroup 1348 2012-02-13 12:21 input/core-site.xml
# -rw-r--r-- 1 joe supergroup 1913 2012-02-13 12:21 input/hdfs-site.xml
# -rw-r--r-- 1 joe supergroup 1001 2012-02-13 12:21 input/mapred-site.xml

export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce
hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar grep input output23 'dfs[a-z.]+'

# After the job completes, you can find the output in the HDFS directory named output23 because you specified that output directory to Hadoop.
# $ hadoop fs -ls 
# Found 2 items
# drwxr-xr-x - joe supergroup 0 2009-08-18 18:36 /user/joe/input
# drwxr-xr-x - joe supergroup 0 2009-08-18 18:38 /user/joe/output23
# You can see that there is a new directory called output23.
# 
# List the output files.
# $ hadoop fs -ls output23 
# Found 2 items
# drwxr-xr-x - joe supergroup 0 2009-02-25 10:33 /user/joe/output23/_SUCCESS
# -rw-r--r-- 1 joe supergroup 1068 2009-02-25 10:33 /user/joe/output23/part-r-00000
# Read the results in the output file.
# $ hadoop fs -cat output23/part-r-00000 | head
# 1 dfs.safemode.min.datanodes
# 1 dfs.safemode.extension
# 1 dfs.replication
# 1 dfs.permissions.enabled
# 1 dfs.namenode.name.dir
# 1 dfs.namenode.checkpoint.dir
# 1 dfs.datanode.data.dir
