
### The rules of scaling

* Storage (Disk)                    is free, and infinite in size 
* Processing (CPU)                  is free, except when it isn't
* Flash Storage (SSD)               is pricey, and cruelly limited in size 
* Memory (RAM)                      is expensive, and cruelly limited in size 

* Memory                            is infinitely fast.
* Streaming data across the network is ever-so-slightly faster than streaming from disk
* Streaming data from disk          is the limiting factor in speed if you're doing things right...
* ... unless processing (CPU)       is the limiting factor in speed
* Reading data in pieces from SSD   is adequate if you plan ahead and can fit
* Reading data in pieces from disk  is infinitely slow
* Reading data in pieces from across the network is even slower

### Prices

Here are prices in 

To store 10 Billion records with an average size of 1 kB costs

* $200,000 /month to store it all on ram       ($1315/mo for 150 68.4 GB machines)
* $ 20,000 /month to have it 10% backed by ram ($1315/mo for  15 68.4 GB machines)
* $  1,000 /month to store it on disk (EBS volumes)

Compare witih

* $  1,600 /month salary of a part-time intern
* $  5,500 /month salary of a full-time junior engineer 
* $ 10,000 /month salary of a full-time senior engineer 

For a 10-hour working day, 

* $ 270 /day  for a 30-machine cluster having a total of 1TB ram, 120 cores
* $ 650 /day  for that same cluster if it runs for the full 24-hour day
* $  64 /day  for a 10-machine cluster having a total of 150 GB ram, 40 cores
* $ 180 /day  for an intern         to operate it
* $ 300 /day  for a junior engineer to operate it
* $ 600 /day  for a senior engineer to operate it


Suppose you have a job that runs daily, taking 3 hours on a 10-machine cluster of 15 GB machines. That job costs you $600/month.

If you tasked a junior engineer to spend three days optimizing that job, with a 10-machine cluster running the whole time, it would cost you about $1100. If she made the job run three times faster -- so it ran in 1 hour instead of 3 -- the job would now cost about $200. However, it will take three months to reach break-even.

Takeaways:

* Engineers are more expensive than compute. 
* Use elastic clusters for your data science team


### Steps

    (read and label the data)
    (send the data across the network)
    (sort each batch)
    (process the data in each batch and output it)


## How to size your cluster

* If you are IO-bound, use the cheapest machines available, as many of them as you care to get
* If you are CPU-bound, use the fastest machines available, as many of them as you care to get
* If the shuffle is the slowest step, use a cluster that is 50% to 100% as large as the mid-flight data.


##### Transfer

cp                | A.1     => A.1
cp                | A.1     => A.2
scp               | A.1     => A.2
scp               | A.1     => B.1
hdp-put           | A.1     => hdfs
hdp-put           | all.1   => hdfs

hdp-cp            | hdfs-X  => hdfs-X
distcp            | hdfs-X  => hdfs-Y

db read           | hbase-T => hdfs-X
db read/write     | hbase-T => hbase-U

db write          | hdfs-X  => hbase-T

##### Map-only

null              | s3      => hdfs
null              | hdfs    => s3
null              | s3      => s3

identity (stream) | s3      => hdfs
identity (stream) | hdfs    => s3
identity (stream) | s3      => s3

reverse           | s3      => hdfs
reverse           | hdfs    => s3
reverse           | s3      => s3

pig_latin         | s3      => hdfs
pig_latin         | hdfs    => s3
pig_latin         | s3      => s3

##### Reduce

partitioned sort  | hdfs    => hdfs
partitioned sort  | s3      => hdfs
partitioned sort  | hdfs    => s3
partitioned sort  | s3      => s3

total sort        | hdfs    => hdfs

##### Big Midflight Output


##### Big Reduce Output

cross | hdfs => hdfs

##### High CPU

bcrypt line       | hdfs => hdfs