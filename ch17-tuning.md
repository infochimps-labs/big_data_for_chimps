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







        # Other hadoop settings

        # Make sure you define a cluster_size in roles/WHATEVER_cluster.rb
        default[:cluster_size] = 5

        # You may wish to set the following to the same as your HDFS block size, esp if
        # you're seeing issues with s3:// turning 1TB files into 30_000+ map tasks
        #
        default[:hadoop][:min_split_size]  = (128 * 1024 * 1024)
        default[:hadoop][:s3_block_size]   = (128 * 1024 * 1024)
        default[:hadoop][:hdfs_block_size] = (128 * 1024 * 1024)
        default[:hadoop][:dfs_replication] =  3

        default[:hadoop][:namenode   ][:handler_count]       = 40
        default[:hadoop][:jobtracker ][:handler_count]       = 40
        default[:hadoop][:datanode   ][:handler_count]       =  8
        default[:hadoop][:tasktracker][:http_threads ]       = 32

        # Number of files the reducer will read in parallel during the copy (shuffle)
        # phase, and the threshold triggering the last stage of the shuffle
        # (`mapred.reduce.parallel.copies`). This is an important setting but one you
        # should not mess with until you have tuned the hell out of everything else.
        #
        # A reducer gets one file from every mapper, which it must merge sort in passes
        # until there are fewer than `:reducer_parallel_copies` merged files. At that
        # point, it does not need to perform the final merge-sort pass: it can stream
        # directly from each file lickety-split and do the merge on the fly. A higher
        # number costs more memory but can lead to fewer merge passes.
        #
        # The hadoop default is 5; we have increased it to 10.
        default[:hadoop][:reducer_parallel_copies    ]       = 10

        # `mapred.compress.map.output`: If true, compresses the data during transport
        # from mapper to reducer. It is decompressed for you, so this is completely
        # transparent to your jobs. (Also note that ifd there are no reducers, this
        # setting is not applied.) There's a modest CPU cost, but as midflight data
        # often sees compression ratios of 5:1 or better, the typical result is
        # dramatically faster transfer. Leave this `'true'` and override on a per-job
        # basis in the rare case it's unhelpful.
        default[:hadoop][:compress_mapout      ]             = 'true'

        # `mapred.map.output.compression.codec`: We've left `compress_mapout_codec` at
        # the default `'org.apache.hadoop.io.compress.DefaultCodec'`, but almost all
        # jobs are improved by `'org.apache.hadoop.io.compress.SnappyCodec'`
        default[:hadoop][:compress_mapout_codec]             = 'org.apache.hadoop.io.compress.DefaultCodec'

        # Compress the job output (`mapred.output.compress`). The same benefits as
        # `:compress_mapout`, but also saves significant disk space. The downside is
        # that the compression is not transparent: `hadoop fs -cat` outputs the
        # compressed data, which is a minor pain when doing exploratory analysis. You'd
        # like best to use `snappy` compression, but the toolset for working with it is
        # not mature.
        #
        # In practice, we leave this set at `'false'` in the site configuration, and
        # have production jobs explicitly request gzip- or snappy-compressed output. (We
        # find those are always superior to `.bz2`, `lzo` or `default` codecs.)
        default[:hadoop][:compress_output      ]             = 'false'
        # Leave this set to `'BLOCK'` (`mapred.output.compression.type`)
        default[:hadoop][:compress_output_type ]             = 'BLOCK'
        # Codec to use for job output (`mapred.output.compression.codec`). If you're
        # going to flip this on, I wouldn't use anything but
        # `'org.apache.hadoop.io.compress.SnappyCodec'`
        default[:hadoop][:compress_output_codec]             = 'org.apache.hadoop.io.compress.DefaultCodec'

        # uses /etc/default/hadoop-0.20 to set the hadoop daemon's java_heap_size_max
        default[:hadoop][:java_heap_size_max]                = 1000

        # Namenode Java Heap size. Increase this if you have a lot of
        # objects on your HDFS.
        default[:hadoop][:namenode    ][:java_heap_size_max] = nil
        # Secondary Namenode Java Heap size. Set to the exact same value as the Namenode.
        default[:hadoop][:secondarynn ][:java_heap_size_max] = nil
        # Jobtracker Java Heap Size.
        default[:hadoop][:jobtracker  ][:java_heap_size_max] = nil
        # Datanode Java Heap Size. Increase if each node manages a large number of blocks.
        # Set this by observation: its value is fairly stable and 1GB will take you fairly far.
        default[:hadoop][:datanode    ][:java_heap_size_max] = nil
        # Tasktracker Java Heap Size. Set this by observation: its value is fairly
        # stable.  Note: this is *not* the amount of RAM given to the mapper and reducer
        # child processes -- see :java_child_opts (and :java_child_ulimit) below.
        default[:hadoop][:tasktracker ][:java_heap_size_max] = nil

        # Rate at which datanodes exchange blocks in a rebalancing operation. If you run
        # an elastic cluster, increase this value to more like 50_000_000 -- jobs will
        # run more slowly while the cluster rebalances, but your usage will be more
        # efficient overall. In bytes per second -- 1MB/s by default
        default[:hadoop][:balancer][:max_bandwidth]          = 1_048_576

        # how long to keep jobtracker logs around
        default[:hadoop][:log_retention_hours ]              = 24

        # define a rack topology? if false (default), all nodes are in the same 'rack'.
        default[:hadoop][:define_topology]                   = false
        default[:hadoop][:fake_rack_size]                    = 4

        #
        # Tune cluster settings for size of instance
        #
        # These settings are mostly taken from the cloudera hadoop-ec2 scripts,
        # informed by the
        #
        #   numMappers  M := numCores * 1.5
        #   numReducers R := numCores max 4
        #   java_Xmx       := 0.75 * (TotalRam / (numCores * 1.5) )
        #   ulimit         := 3 * java_Xmx
        #
        # With 1.5*cores tasks taking up max heap, 75% of memory is occupied.  If your
        # job is memory-bound on both map and reduce side, you *must* reduce the number
        # of map and reduce tasks for that job to less than 1.5*cores together.  using
        # mapred.max.maps.per.node and mapred.max.reduces.per.node, or by setting
        # java_child_opts.
        #
        # It assumes EC2 instances with EBS-backed volumes
        # If your cluster is heavily used and has many cores/machine (almost always running a full # of maps and reducers) turn down the number of mappers.
        # If you typically run from S3 (fully I/O bound) increase the number of maps + reducers moderately.
        # In both cases, adjust the memory settings accordingly.
        #
        #
        # FIXME: The below parameters are calculated for each node.
        #   The max_map_tasks and max_reduce_tasks settings apply per-node, no problem here
        #   The remaining ones (java_child_opts, io_sort_mb, etc) are applied *per-job*:
        #   if you launch your job from an m2.xlarge on a heterogeneous cluster, all of
        #   the tasks will kick off with -Xmx4531m and so forth, regardless of the RAM
        #   on that machine.
        #
        # Also, make sure you're
        #
        hadoop_performance_settings =
          case node[:ec2] && node[:ec2][:instance_type]
          when 't1.micro'   then { :max_map_tasks =>  1, :max_reduce_tasks => 1, :java_child_opts =>  '-Xmx256m -Xss128k',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 10, :io_sort_mb =>  64, }
          when 'm1.small'   then { :max_map_tasks =>  2, :max_reduce_tasks => 1, :java_child_opts =>  '-Xmx870m -Xss128k',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 10, :io_sort_mb => 100, }
          when 'c1.medium'  then { :max_map_tasks =>  3, :max_reduce_tasks => 2, :java_child_opts =>  '-Xmx870m -Xss128k',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 10, :io_sort_mb => 100, }
          when 'm1.large'   then { :max_map_tasks =>  3, :max_reduce_tasks => 2, :java_child_opts => '-Xmx2432m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit =>  7471104, :io_sort_factor => 25, :io_sort_mb => 250, }
          when 'c1.xlarge'  then { :max_map_tasks => 10, :max_reduce_tasks => 4, :java_child_opts =>  '-Xmx870m -Xss128k',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 20, :io_sort_mb => 200, }
          when 'm1.xlarge'  then { :max_map_tasks =>  6, :max_reduce_tasks => 4, :java_child_opts => '-Xmx1920m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit =>  5898240, :io_sort_factor => 25, :io_sort_mb => 250, }
          when 'm2.xlarge'  then { :max_map_tasks =>  4, :max_reduce_tasks => 2, :java_child_opts => '-Xmx4531m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit => 13447987, :io_sort_factor => 32, :io_sort_mb => 250, }
          when 'm2.2xlarge' then { :max_map_tasks =>  6, :max_reduce_tasks => 4, :java_child_opts => '-Xmx4378m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit => 13447987, :io_sort_factor => 32, :io_sort_mb => 256, }
          when 'm2.4xlarge' then { :max_map_tasks => 12, :max_reduce_tasks => 4, :java_child_opts => '-Xmx4378m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit => 13447987, :io_sort_factor => 40, :io_sort_mb => 256, }
          else
            if node[:memory] && node[:cores]
              cores        = node[:cpu   ][:total].to_i
              ram          = node[:memory][:total].to_i
              if node[:memory][:swap] && node[:memory][:swap][:total]
                ram -= node[:memory][:swap][:total].to_i
              end
            else
              Chef::Log.warn("No access to system info, using cores=1 memory=1024m")
              cores = 1
              ram   = 1024
            end
            Chef::Log.warn("Couldn't set performance parameters from instance type, estimating from #{cores} cores and #{ram} ram")
            n_mappers      = (cores >= 6 ? (cores * 1.25) : (cores * 2)).to_i
            n_reducers     = cores
            heap_size      = 0.75 * (ram.to_f / 1000) / (n_mappers + n_reducers)
            heap_size      = [256, heap_size.to_i].max
            child_ulimit   = 2 * heap_size * 1024
            io_sort_factor = 10
            io_sort_mb     = 100
            { :max_map_tasks => n_mappers, :max_reduce_tasks => n_reducers, :java_child_opts => "-Xmx#{heap_size}m", :java_child_ulimit => child_ulimit, :io_sort_factor => io_sort_factor, :io_sort_mb => io_sort_mb, }
          end

        Chef::Log.debug("Hadoop tunables: #{hadoop_performance_settings.inspect}")

        # (Mappers+Reducers)*ChildTaskHeap + DNheap + TTheap + 3GB + RSheap + OtherServices'

        hadoop_performance_settings.each{|k,v| default[:hadoop][k] = v }
