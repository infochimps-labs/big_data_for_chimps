# Chapter 17: Tuning

* Lots of files:
  - Namenode and 2NN heap size
* Lots of data:
  - Datanode heap size.
* Lots of map tasks per job:
  - Jobtracker heap size
  - tasktracker.http.threads
  - mapred.reduce.parallel.copies


### Tuning the Cluster to the Job

Our usual work pattern is

* Get the job working locally on a reduced dataset
  - for a wukong job, you don't even need hadoop; use `cat` and pipes.
* Profile its run time on a small cluster

### Conclusions

For data that will be read much more often than it's written, 

* Produce output files of 1-4 GB with a block size of 128MB
  - if there's an obvious join key, do a total sort



### Happy Mappers



#### A Happy Mapper is **well-fed**, **finishes with its friends**, **uses local data**, **doesn't have extra spills**, and has a **justifiable data rate**.
#### A Really Happy Mapper has no Reducer

##### Well-fed

The amount of data each mapper sees is governed by

* File size
* HDFS block size
* `mapred.min.split.size`

* Map tasks should take longer to run than to start. If mappers finish in less than a minute or two, and you have control over how the input data is allocated, try to feed each more data. In general, 128MB is sufficient; we set our HDFS block size to that value.

### finishes with its friends

Assuming well-fed mappers, you would like every mapper to finish at roughly the same time. The reduce cannot start until all mappers have finished. Why would different mappers take different amounts of time?

* large variation in file size
* large variation in load -- for example, if the distribution of reducers is uneven, the machines with multiple reducers will run more slowly in general
* on a large cluster, long-running map tasks will expose which machines are slowest.

### Busy

Assuming mappers are well fed and prompt, you would like to have nearly every mapper running a job.


* Assuming every mapper is well fed and every mapper is running a job, 


Pig can use the combine splits setting to make this intelligently faster. Watch out for weirdness with newer versions of pig and older versions of HBase.

If you're reading from S3, dial up the min split size as large as 1-2 GB (but not 


### Match the reducer heap size to the data it processes
  
#### A Happy Reducer is **well-balanced**, has **few merge passes**, has **good RAM/data ratio**, and a **justifiable data rate**

* **well-balanced**: 

